function [data_i,xaxis_i,foundat_all,shiftfns,usedpeaks] = registerspec(varargin)
%REGISTERSPEC Shift spectra based on expected peak locations.
% Locates the current position of expected peaks and then uses a spline or
%  polynomial function to shift each spectrum so that the expected peaks
%  are as close as possible to the expected location. The output are the
%  spectra sampled at the same xaxis positions but shifted. The output can
%  optionally be interpolated to higher sampling rate using the
%  "interpolate" option explained below. See "registerspec help" for
%  details. 
% By omitting the list of reference peaks, this algorithm can also be used
%  to locate the most stable peaks in a given set of spectra. See usage
%  notes below.
%
%  INPUTS:
%      data = matrix or DataSet of spectra
%     xaxis = optional frequencies or energies associated with each
%              variable in data {optional; default = use DataSet values,
%              otherwise use 1:n}
%     peaks = expected locations of peaks to use for shifting. If omitted,
%              'findpeaks' mode will be invoked and stable peaks will be
%              found in the data (see below).
%
%  OPTIONAL INPUT:
%   options = optional structure array containing one or more of the
%              following fields
%       display: [ {'on'} | 'off' ] governs command-line output
%         plots: [ {'none'} | 'fit' | 'final' ] governs plotting options
%       waitbar: [ 'off' | 'on' | {'auto'} ] governs use of waitbar. If set
%                 to 'auto', waitbar will display if excessive time to
%                 process is expected.
%       nopeaks: [ 'none' | {'warning'} | 'error' ] governs behavior when
%                 none of the reference peaks can be located.
%       shiftby: [{-0.1}] minimum shifting interval. A positive value is
%                 interpreted as being in absolute xaxis units and a
%                 negative value as relative to the smallest xaxis
%                 interval.
%   interpolate: [{[]}] interpolation interval for output spectra. Empty []
%                 does no interpolation. A positive value is interpreted
%                 as being in absolute xaxis units and a negative value 
%                 as relative to the smallest xaxis interval.
%      maxshift: [in xaxis units, {4}] maximum allowed peak shift (peaks
%                 which require more shift than this will NOT be used for
%                 xaxis correction).
%        window: [in xaxis units, {[]}] size of window to search for each
%                 peak. Empty [] uses automatic window based on maxshift.
%         order: order of polynomial (only used for polynomial algorithms)
%     algorithm: xaxis correction algorithm. One of:
%                 'pchip' : constrained picewise spline (well behaved) 
%                 'poly'  : {default} standard polynomial fit to found peaks
%         'iterativepoly' : iterative polynomial fitting (order increased
%                            in each cycle - works better for badly shifted 
%                            spectra)
%             'findpeaks' : locate non-moving peaks in whole dataset.
%                            Triggered by omission of the (peaks) input.
%     smoothing: [ 'off' |{'on'}] Governs use of smoothing algorithm during
%                  peak location. If 'on' each sub-window is smoothed prior
%                  to locating maximum in window.
%     smoothinfo: [width order]  Smoothing parameters to be passed to
%                  smoothing function (savgol) if enabled by smoothing
%                  option above. Width is width of window in number of
%                  variables, order is order of polynomial. Default is
%                  width of 5 and order 2: [5 2].
%
%  OUTPUTS:
%       data_i = shifted, interpolated data
%       axaxis = interpolated xaxis (will be equal to xaxis if no
%                 interpolation is requested)
%      foundat = matrix of peak shifts found for each peak (columns) in each
%                 spectrum (rows)
%     shiftfns = matrix of corrections made to axisscale to arrive at the
%                  shifted data (each row of shiftfns corresponds to a row
%                  of data_i). Use with interp1 to adjust other data in a
%                  similar manner:
%                    data_i = interp1(xaxis,data,axaxis+shiftfns,'spline')
%        peaks = (only for 'findpeaks' mode) Locations of found peaks in
%                 xaxis units.
%
% Notes:
%  If input (peaks) is omitted, the algorithm identifies peaks in the
%  mean spectrum by setting peaks at every variable and allowing these to
%  drift to the nearest maximum. It then locates the same peaks in each of
%  the individual spectra and keeps only those peaks which could be located
%  in all spectra with less shift than specified in options.maxshift.
%
%I/O: [data_i,axaxis,foundat,shiftfns,usedpeaks] = registerspec(data,xaxis,peaks,options)
%I/O: peaks = registerspec(data,xaxis,options)     %peak find mode
%
%See also: ALIGNMAT, ALIGNPEAKS, ALIGNSPECTRA, COADD, DERESOLV, STDFIR, STDGEN

%Copyright (c) Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%10/03 JMS
%10/29/03 jms - allowed input of dataset alone
%  -allow shift of excluded spectra, but don't use for findpeak
%3/2/04 jms -fixed bug if end point selected as reference point during findpeaks
%6/11/04 jms -turn off warnings during peak find
%6/15/04 jms -addition of nopeaks option defining what to do when no peaks
%   could be located

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1})
  options = [];
  options.name      = 'options';
  options.display   = 'on';
  options.waitbar   = 'auto';
  options.plots     = 'none';
  options.nopeaks   = 'warning';  % 'none', 'warning' or 'error'
  options.shiftby   = -.1;       % shift interpolation interval (>0 is in xaxis units, <0 is relative units)
  options.interpolate  = [];    % interpolation oversampling interval for output spectra
  options.maxshift  = 4;        % maximum allowed shift (in xaxis units)
  options.window    = [];        % interpolated window size (in xaxis units) [] = auto
  options.order     = 0;        % order of polynomial to use (if algorithm is poly or nestedpoly)
  options.algorithm = 'poly';  % [ 'pchip' | 'poly' | 'iterativepoly' | 'findpeaks' ]
  options.smoothing = 'on';    
  options.smoothinfo = [5 2];  
  
  if nargout==0; clear data_i; evriio(mfilename,varargin{1},options); else; data_i = evriio(mfilename,varargin{1},options); end
  return; 
end

%-------------------------------------------------------
%parse inputs

options = [];
%data,xaxis,peaks,options
switch nargin
  case 1
    % data
    data = varargin{1};
    peaks = [];
    xaxis = [];
  case 2
    % data,options
    % data,xaxis
    % data,peaks
    if isstruct(varargin{2})
      % data,options
      data  = varargin{1};
      options = varargin{2};
      peaks = [];
      xaxis = [];
    elseif length(varargin{2})==size(varargin{1},2)
      % data,xaxis
      data  = varargin{1};
      xaxis = varargin{2};
      peaks = [];
    else
      data  = varargin{1};
      peaks = varargin{2};
      xaxis = [];
    end
  case 3
    % data,xaxis,peaks
    % data,peaks,options
    % data,xaxis,options
    if ~isa(varargin{3},'struct')
      % data,xaxis,peaks
      data  = varargin{1};
      xaxis = varargin{2};
      peaks = varargin{3};
    elseif length(varargin{2})~=size(varargin{1},2)
      % data,peaks,options
      data    = varargin{1};
      peaks   = varargin{2};
      options = varargin{3};
      xaxis = [];
    else
      % data,xaxis,options
      data    = varargin{1};
      xaxis   = varargin{2};
      peaks   = [];
      options = varargin{3};
    end
  case 4
    %data,xaxis,peaks,options
    data    = varargin{1};
    xaxis   = varargin{2};
    peaks   = varargin{3};
    options = varargin{4};
    
end

options = reconopts(options,'registerspec');

%-------------------------------------------------------
% test inputs 

%Create xaxis if necessary
if isempty(xaxis)
  if isa(data,'dataset')
    xaxis = data.axisscale{2};
  end
  if isempty(xaxis) %still empty?
    xaxis = 1:size(data,2);
  end
end
xaxis = xaxis(:)';  %make a row vector

%Various bad entries
if ~any(size(xaxis)==1) | length(xaxis)~=size(data,2)
  error('Input XAXIS must be a vector equal to length to size(data,2)')
end
if options.shiftby == 0
  error('Options.shiftby can not be zero');
end
if options.shiftby<0
  options.shiftby = -min(abs(diff(xaxis)))*options.shiftby;
end
if isempty(options.window) | options.window<options.shiftby
  options.window = max(options.maxshift,min(abs(diff(xaxis))));
end
if options.window<min(abs(diff(xaxis)))
  error(['Options.window must be > minimum xaxis interval (' num2str(min(abs(diff(xaxis)))) ')']);
end

% Initialize output variables (safety).
data_i=[];
xaxis_i=[];
foundat_all=[];
shiftfns=[];

%Extract data from dataset
wasdataset = isa(data,'dataset');
if wasdataset
  incl = data.include;       
else
  incl = {1:size(data,1) 1:size(data,2)};
end

%Create peaks if necessary
if isempty(peaks)
  options.algorithm = 'findpeaks';
  peaks = xaxis(incl{2});
  if strcmp(lower(options.display),'on')
    disp('Operating in Find-Peaks mode.')
    disp(sprintf('Maximum number of peaks: %i',length(peaks)))
    disp(sprintf('Maximum allowed shift: %0.2f',options.maxshift))
    disp(sprintf('Search window: %0.2f',options.window))
  end
end

%extract from dataset
if wasdataset
  origdata = data;
  if strcmp(options.algorithm,'findpeaks')
    data = data.data(incl{1},:);  
  else
    data = data.data;
  end
end

%findpeaks mode - add mean spectrum as additional spec at beginning (will
%contain ALL peak features)
if strcmp(options.algorithm,'findpeaks')
  if size(data,1)>1
    data = [mean(data,1); data];
  end
end

if ~any(size(peaks)==1)
  error('Input PEAKS must be a vector')
end

%-------------------------------------------------------
% Main part of the algorithm
[m,n] = size(data);

if isempty(options.interpolate) | options.interpolate == 0
  xaxis_i = xaxis;
elseif options.interpolate > 0
  xaxis_i = interp1(xaxis,xaxis,[xaxis(1):options.interpolate:xaxis(end)]);
else
  xaxis_i = interp1(xaxis,xaxis,[xaxis(1):(-min(abs(diff(xaxis)))*options.interpolate):xaxis(end)]);
end
peaks   = unique(peaks);

if ~strcmp(options.algorithm,'findpeaks')
  data_i = zeros(m,length(xaxis_i));
else
  data_i = {};
end

wbh = [];
starttime = now;

%locate peaks nearest reference peaks
for ind = 1:m
  
  loop    = 1;
  pp      = {};
  while loop
    
    window = [-options.window:options.shiftby:options.window];
    
    shift        = zeros(1,length(peaks));
    notwindowed  = logical(ones(1,length(peaks)));   %start by calculating max for all peaks
    maxind       = [];
    while any(notwindowed)
      rng          = repmat(window',[1 sum(notwindowed)]) + repmat(peaks(notwindowed)-shift(notwindowed),[length(window) 1]);
      spec         = data(ind,:);
      if strcmp(options.smoothing,'on')
        if length(options.smoothinfo)>2
          spec         = -savgol(spec,options.smoothinfo(1),options.smoothinfo(2),options.smoothinfo(3));
        else
          spec         = savgol(spec,options.smoothinfo(1),options.smoothinfo(2));
        end
      end
      datawins     = interp1(xaxis,spec,rng,'spline');
      [what,where] = max(datawins,[],1);
      maxind(notwindowed) = where;
      
      below = (maxind == 1);
      above = (maxind == length(window));
      notwindowed = (above | below);    %figure out which are not windowed by our range

      % ==Disabled==
%         options.minslope  = .1;        % minimum slope required for peak consideration
%             %if requested, drop any windows which do not have the requsite change
%             if options.minslope>0;
%               [mnwhat,mnwhere] = min(datawins,[],1);
%               slope = (what-mnwhat)./(abs(what)+1);
% %               slope = (what-mnwhat)./abs(where-mnwhere);
%               badslope = slope<mean(slope);
% %               badslope = slope<options.minslope;
%               notwindowed(badslope) = logical(0);
%               shift(badslope) = inf;  %force to ignore
%             end
      
      if any(notwindowed)
        shift = shift + below*options.window/2 - above*options.window/2;  %and shift those windows as needed
        overshifted = (abs(shift)>options.maxshift);  %check for ones which are overshifted...
        notwindowed = notwindowed & ~overshifted;     %don't bother with those anymore
      end
    end    

    %Save list of ALL peak shifts (even if we don't use them all)
    if ~strcmp(lower(options.algorithm),'findpeaks')
      foundat_all(ind,:) = window(maxind)-shift;
    end
    
    %-----------------------------------
    %Discard peaks that were > maxshift from our exected maximum
    usedpeaks = peaks;
    good   = ~(abs(window(maxind)-shift)>options.maxshift);
    if any(~good)
      if strcmp(lower(options.display),'on') 
        disp(sprintf('Spectrum #%i: Discarded %i peak(s) due to over-shifting, %i peaks remain',ind,sum(~good),sum(good)))
      end
      usedpeaks(~good) = [];
      maxind(~good)   = [];
      shift(~good)    = [];
    end
    
    %remove duplicate peaks (ones that are within "shiftby" of each other)
    foundat = window(maxind)-shift;
    
    if ind==1;
      good = logical(usedpeaks*0);
      [what,where] = unique(usedpeaks+foundat);
      good(where) = true;
    else
      good = [true abs(diff(usedpeaks+foundat))>max(options.maxshift,options.shiftby*2)];
    end
    while ~isempty(usedpeaks) & sum(good)<(length(usedpeaks)-1)
      if strcmp(lower(options.display),'on') 
        disp(sprintf('Spectrum #%i: Discarded %i peak(s) due to duplication, %i peaks remain',ind,length(usedpeaks)-sum(good),sum(good)))
      end
      usedpeaks = usedpeaks(good);
      foundat   = foundat(good);
      good      = [true abs(diff(usedpeaks+foundat))>max(options.maxshift,options.shiftby*2)];
    end      
    
    %-----------------------------------
    %do the interpolative correction
    if isempty(usedpeaks) 
      if strcmp(options.algorithm,'findpeaks')
        error(['No reference peaks stable to within allowed shift range (' num2str(options.maxshift) ') could be identified, unable to complete peak-find']);
      else
        msg = ['None of the reference peaks were found within the allowed shift range (' num2str(options.maxshift) '), no correction can be done'];
        switch options.nopeaks
          case 'error'
            error(msg);
          case 'warning'
            warning(msg);
          otherwise
            %do nothing, just keep going
        end
      end
    end
    
    switch lower(options.algorithm)
      case 'pchip'
        %create picewise polynomial using PCHIP "minimum shift" method
        % (shift cannot exceeded the observed shift)
        if ~isempty(foundat)
          pp          = pchip([xaxis(1) usedpeaks xaxis(end)],[foundat(1) foundat foundat(end)]);
          shiftfn     = ppval(pp,xaxis_i);
        else
          shiftfn     = xaxis_i.*0;
        end
        data_i(ind,:) = interp1(xaxis,data(ind,:),xaxis_i+shiftfn,'spline',0);
        if nargout>3
        shiftfns(ind,:) = shiftfn;
        end
        loop = 0;
        
        if strcmp(options.plots,'fit')
          if ind==1; figure; end
          plot(usedpeaks,foundat,'o',xaxis,ppval(pp,xaxis));
          xlabel('Peak Position');
          ylabel('Shift from Position')
          title(['Spectrum #' num2str(ind) ' <Press any key to continue>'])
          pause;
        end
        
      case 'poly'
        %use a polynomial of requested order to relocate peaks
        if ~isempty(usedpeaks)
          [pp,cond]   = polyfit(usedpeaks,foundat,min(length(usedpeaks)-1,options.order));
          shiftfn     = polyval(pp,xaxis_i);
        else
          shiftfn     = xaxis_i.*0;
        end
        data_i(ind,:) = interp1(xaxis,data(ind,:),xaxis_i+shiftfn,'spline',0);
        if nargout>3
        shiftfns(ind,:) = shiftfn;
        end
        loop = 0;
        
        if strcmp(options.plots,'fit')
          if ind==1; figure; end
          plot(usedpeaks,foundat,'o',xaxis,polyval(pp,xaxis));
          xlabel('Peak Position');
          ylabel('Shift from Position')
          title(['Spectrum #' num2str(ind) ' <Press any key to continue>'])
          pause;
        end
        
      case 'iterativepoly'
        %iteratively repeat peak shifting using sucessively higher
        %polynomials (up to requested order)
        if loop == 1
          data_orig = data(ind,:);
        end
        if ~isempty(usedpeaks)
          pp{loop}    = polyfit(usedpeaks,foundat,min(length(usedpeaks)-1,loop-1));
          shiftfn     = polyval(pp{loop},xaxis);
        else
          pp{loop}  = 0;
          shiftfn   = xaxis.*0;
        end
        data(ind,:) = interp1(xaxis,data(ind,:),xaxis + shiftfn,'spline',0);
        if nargout>3
        shiftfns(ind,:) = shiftfn;
        end
        loop = loop + 1;
        if (loop-1) > options.order
          %got to polynomial of appropriate order, finish now
          xaxis_temp = xaxis_i;
          for j = 1:length(pp)
            shiftfn = polyval(pp{j},xaxis_temp);
            xaxis_temp = xaxis_temp + shiftfn;
          end
          data_i(ind,:) = interp1(xaxis,data_orig,xaxis_temp,'spline',0);
          if nargout>3
          shiftfns(ind,:) = shiftfns(ind,:)+shiftfn;
          end
          loop = 0;
          
          if strcmp(options.plots,'fit')
            if ind==1; figure; end
            plot(usedpeaks,foundat,'o',xaxis,polyval(pp{end},xaxis));
            xlabel('Peak Position');
            ylabel('Shift from Position')
            title(['Spectrum #' num2str(ind) ' <Press any key to continue>'])
            pause;
          end
          
        end
        
      case 'findpeaks'
        %locate peaks only (no shift)
        if ind==1
          data_i{ind} = usedpeaks+foundat;
        else
          data_i{ind} = usedpeaks;
        end
        loop        = 0;
        peaks       = usedpeaks+foundat;  %only used found peaks the next cycle through
        
        if strcmp(options.plots,'fit')
          plot(xaxis,data(ind,:));
          vline(data_i{ind},'r');
          xlabel('Unknown Spectral Units');
          ylabel('Intensity')
          title(['Peaks found for Spectrum #' num2str(ind) ' <Press any key to continue>'])
          pause;
        end
        
    end   %end of algorithm case
    
  end    %end iteration loop    

  if mod(ind,25)==0
    est = ((now-starttime)/ind)*24*60*60*(m-ind);
    if ishandle(wbh)
      waitbar(ind/m);
      set(wbh,'name',sprintf('Estimated Time: %s',besttime(est)))
    elseif isempty(wbh)
      if strcmp(options.waitbar,'on') || (strcmp(options.waitbar,'auto') && est>10)
        wbh = waitbar(ind/m,'Performing spectral alignment...');
      end
    elseif ~isempty(wbh)
      error('Alignment process (registerspec) aborted by user');
    end
  end

end  %end of spectrum loop
if ishandle(wbh)
  delete(wbh);
end

%-------------------------------------------------------
%handle outputs as necessary
switch lower(options.algorithm)
  case 'findpeaks'
    
    %make master list of peaks found in all spectra
    %     found = sort(data_i{end});
    found = [];
    warn = warning;
    warning('off');
    
    try
      if m>1
        for j=1:length(data_i)-1
          [pnts,i] = unique([min(xaxis) data_i{j} max(xaxis)]);
          pnts2 = [NaN data_i{j} NaN];
          pnts2 = pnts2(i);
          found(j,:) = interp1(pnts,pnts2,data_i{end},'nearest');
        end
        found = mean(found,1);
      else
        found = data_i{1};
      end
      
      found(~isfinite(found) | found<min(xaxis) | found>max(xaxis)) = [];  %drop invalid ones
      data_i = found;  %pass back as first output
      
      if strcmp(lower(options.display),'on')
        disp(sprintf('Located %i peak(s) stable to %0.2f axis units',length(found),options.maxshift));
      end
      
      if strcmp(lower(options.plots),'final')
        figure
        plot(xaxis,data);
        vline(found,'r');
      end
      
      clear xaxis
    catch
      le = lasterror;
      warning(warn);
      rethrow(le)
    end
    
    warning(warn);
    
  otherwise
  
    if strcmp(lower(options.plots),'final')
      figure
      plot(xaxis,data,'r',xaxis_i,data_i,'g'); 
      vline(peaks,'k');
    end
    
    if wasdataset
      if all(size(origdata)==size(data_i))  %no interp? just replace in original dataset
        origdata.data = data_i;
        data_i = origdata;
      else  %w/interp, create as new
        data_i = dataset(data_i);
        data_i.axisscale{2} = xaxis_i;
      end
    end  

end
