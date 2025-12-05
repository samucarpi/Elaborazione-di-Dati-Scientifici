function [i0,iw] = peakfind(x,width,tolfac,w,options)
%PEAKFIND Automated identification of peaks.
%  Given a set of measured traces (x) PEAKFIND attempts to find the
%  location of the peaks. Different algorithms are avialable, but each uses
%  the smoothed and second derivative data (see SAVGOL).
%    d0   = savgol(x,width,2,0);
%    d2   = savgol(x,width,2,2);
%  and the noise level as estimated by sqrt(mean((x-d0).^2)). Noise level
%  for d2 is estimated by scaling the noise level by the ratio of the d0
%  range (max(d0)-min(d0)) to the d2 range (max(d2)-min(d2)).
%
%  INPUTS:
%    x      = MxN matrix of measured traces containing peaks each 1xN row
%             of (x) is an individual trace {class 'double'}.
%    width  = number of points in Savitzky-Golay filter.
%
%  OPTIONAL INPUTS:
%    tolfac = tolerance on the estimated residuals, peaks heights
%             are estimated to be > tolfac*noise level {default: tolfac = 3}.
%    w      = odd scalar window width for determining local maxima
%             {default: w = 3} (see LOCALMAXIMA).
%   options = options structure containing the following fields.
%             Note that (w) and (tolfac) can be omitted and (options)
%             passed as the last input to PEAKFIND.
%    algorithm: [{'d0'}| 'd2' | 'd2r' ] selects an algorithm used to
%              identify peak location. These algorithms are complimentary
%              and may work differently in the presense of backgrounds and
%              other peak shape effects.
%              'd0' : locates a candidate set of peaks by identifying local
%                     maxima (within the specified window size) in the
%                     smoothed data (d0). Next, a threshold on d0 and the
%                     second derivative (d2) is used to select a final set
%                     of peaks from this candidate set. To be accepted, the
%                     value of d0 and d2 at the peak location must surpass
%                     the estimated noise level of both d0 and d2 by the
%                     tolerance factor (tolfac).
%              'd2' : locates candidate peaks as local maxima in the
%                     smoothed 2nd derivative data (d2) and selects a final
%                     set of peaks as those candidate peaks which surpass
%                     (by the tolerance factor, tolfac) the estimated noise
%                     level of d2. d0 position or value is not considered
%                     in any part of the selection except to estimate the
%                     noise level.
%             'd2r' : as with 'd2', 'd2r' locates peaks in d2, but selects
%                     the final set as those peaks which have a "relative"
%                     height (difference between closest d2 peak valley and
%                     d2 peak top) which surpasses (by the tolerance
%                     factor, tolfac) the estimated noise level of d2.
%    npeaks = The maximum number of peaks to find.
%              {'all'} chooses all peaks that are > tolfac.
%              1,2,3, ... integer maximum number of peaks.
%       com = [0] Center of Mass filter on peak positions. Relocates peaks
%              to their "power-weighted" center of mass. That is, the
%              intensity taken to the specified power is used to reloate
%              the peak to its center of mass. Note this may not be an even
%              interval. A value of zero (0) disables the center of mass
%              correction. A value of 1 corresponds to a standard center of
%              mass calculation. Higher values recalculate to the specified
%              power before calculating center of mass.
% peakdirection: [{'positive'}| 'negative' | 'both' ] specifies whether
%              peaks are considered as upward, downward, or both upward and
%              downward spikes in the spectrum profile.
%              'positive' : locates positive-going spikes in the profile.
%              'negative' : locates negative-going spikes in the profile.
%              'both    ' : locates positive or negative-going spikes in
%                           the profile. If npeaks value is specified then 
%                           it applies to positive peaks and negative peaks
%                           separately. 'both' with npeaks=4 will identify
%                           up to 8 peaks. 'both' with npeaks='all' will 
%                           identify all positive and all negative peaks.
%
%  OUTPUT:
%    i0     = Mx1 cell array with each cell containing the indices of the
%             location of the major peaks for each of the M traces.    
%    iw     = Mx1 cell array with each cell containing the indices of the
%             location of the windows containing each peak in (i0).
%             (If not included in the output argument list, it is not
%             calculated and the algorithm is slightly faster.)         
%
%I/O: [i0,iw] = peakfind(x,width,tolfac,w,options);
%I/O: [i0,iw] = peakfind(x,width,options);
%
%See also: LOCALMAXIMA, SAVGOL

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NBG 8/05
%NBG modified to call localmaxima 
%JMS integrated d2 algorithm, cleaned up code, added options
%NBG 2/8/07 bug in algorithm = 'd2' and 'd2r' fixed
%NBG 6/8/07 added options.npeaks

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  options.algorithm     = 'd0';
  options.npeaks        = 'all';
  options.com           = 0;
  options.peakdirection = 'positive';
  if nargout==0; evriio(mfilename,x,options); else; i0 = evriio(mfilename,x,options); end
  return;
end

%parse inputs
switch nargin
  case 1
    %(x)
    width   = 5;
    tolfac  = [];
    w       = [];
    options = [];
  case 2
    %(x,width)
    tolfac  = [];
    w       = [];
    options = [];
  case 3
    %(x,width,options)
    %(x,width,tolfac)
    if isstruct(tolfac)
      options = tolfac;
      w       = [];
      tolfac  = [];
    else
      w       = [];
      options = [];
    end
    
  case 4
    %(x,width,tolfac,w)
    %(x,width,tolfac,options)
    if isstruct(w)
      options = w;
      w       = [];
    else
      options = [];
    end
    
  case 5
    %(x,width,tolfac,w,options)
    %assume all is correct...
end
options = reconopts(options,mfilename);

if options.npeaks==0
  options.npeaks = 'all';
end
switch options.peakdirection
  case 'positive'
    % positive peaks
    [i0, iw] = peakfindsub(x, width, w, tolfac, options);
  case 'negative'
    % negative peaks
    [i0, iw] = peakfindsub(-x, width, w, tolfac, options);
  case 'both'
    % positive peaks
    [i01, iw1] = peakfindsub(x, width, w, tolfac, options);
    % negative peaks
    [i02, iw2] = peakfindsub(-x, width, w, tolfac, options);
    i0 = cell(size(i01));
    iw = cell(size(iw1));
    for ii=1:size(i01,1)
      i0(ii,1)={[i01{ii,1} i02{ii,1}]};
      iw(ii,1)={[iw1{ii,1}; iw2{ii,1}]};
    end
  otherwise
    error('option peakdirection has unrecognized value: %s', options.peakdirection);
end

%--------------------------------------------------------------------------
function [i0, iw] = peakfindsub(x, width, w, tolfac, options)
[m,n] = size(x);
i0    = cell(m,1);
iw    = cell(m,1);
if isempty(tolfac)
  tolfac = 3; 
end
if isempty(w)
  w      = 3; 
end
w = ceil(w/2)*2+1;  %make SURE it is odd
if n<w*2
  %not enough points to do smoothing - exit with no peaks found
  return;
end

width = max(3,min(round((width-1)/2)*2+1,floor((size(x,2)/2))-1));  %as odd # keep >3 and < 1/2 # of vars

%handle DSO
if isdataset(x)
  %extract from DSO and mark excluded as NaN
  incl = x.include{2};
  x    = x.data;
  x(:,incl) = nan;  
end

x = x-min(x(:));

%take derivatives, this could be speeded up by making a dedicated
%function SAVGOLB, that outputs all desired derivatives
d0   = savgol(x,width,2,0);
d2   = savgol(x,width,2,2);

%take note of missing values and ignore those. NOTE: filling with zeros
%seems to work with this algorithm (even though this isn't a typically good
%practice!)
dnuse = isnan(d0) | isnan(d2);
if any(any(dnuse));
  x(dnuse)  = 0;
  d0(dnuse) = 0;
  d2(dnuse) = 0;
end

%locate peaks
for j1=1:m 
  tol0   = tolfac*sqrt(mean((x(j1,:)-d0(j1,:)).^2));
  
  switch options.algorithm
    case 'd0'
      %peak location based on smoothed data and threshold on d0 and d2
      
      tol2   = tol0*(max(d2(j1,:))-min(d2(j1,:)))/(max(d0(j1,:))-min(d0(j1,:)))/2;
      %tol2  = sqrt(mean((diff(d0(j1,:),2,2)-d2(j1,2:end-1)).^2));
      if w==3
        pks = find(diff( sign( diff([0; d0(j1,:)'; 0]) ) ) < 0)';
      else
        pks = localmaxima(d0(j1,:),w);
        pks = pks{1};
      end

      %keep only those above threshold specified by user
      i0{j1} = pks(d0(j1,pks)>tol0 & d2(j1,pks)<-tol2);
      if isa(options.npeaks,'double')
        aa      = d0(j1,i0{j1});
        [aa,ai] = sort(aa(:)',2,'descend');
        i0{j1}  = i0{j1}(ai(1:min(options.npeaks,length(i0{j1}))));
      end
      
    case 'd2'
      %peak location based on 2nd deriv data and threshold on (d2)
      tol2   = tol0*2*(max(d2(j1,:))-min(d2(j1,:)))/(max(d0(j1,:))-min(d0(j1,:)));

      pks  = localmaxima(-d2(j1,:),w); %find maxima
      pks = pks{1};

      %keep only those above threshold specified by user
      %i0{j1} = pks((-d2(:,pks))>tol2); bug line
      i0{j1} = pks(-d2(j1,pks)>tol2); %nbg 2/8/07
      if isa(options.npeaks,'double')
        aa      = -d2(j1,i0{j1});
        [aa,ai] = sort(aa(:)',2,'descend');
        i0{j1}  = i0{j1}(ai(1:min(options.npeaks,length(i0{j1}))));
      end

    case 'd2r'
      %peak location based on 2nd deriv data and threshold on relative (d2)
      tol2   = tol0*2*(max(d2(j1,:))-min(d2(j1,:)))/(max(d0(j1,:))-min(d0(j1,:)));

      pks  = localmaxima(-d2(j1,:),w); %find maxima
      vly  = localmaxima(d2(j1,:),w);  %find minima    
      allpks = sort([vly{1} pks{1}]);
      
      %keep only those above threshold specified by user
      %i0{j1} = allpks((diff(d2(:,allpks))./diff(allpks))>tol2); bug line
      i0{j1} = allpks((diff(d2(j1,allpks))./diff(allpks))>tol2); %nbg 2/8/07
      if isa(options.npeaks,'double')
        aa      = diff(d2(j1,i0{j1})./diff(i0{j1}));
        [aa,ai] = sort(aa(:)',2,'descend');
        i0{j1}  = i0{j1}(ai(1:min(options.npeaks,length(i0{j1}))));
      end

    otherwise
        error('Unrecognized algorithm option');
  end

  if options.com>0
    %locate the center of mass within the window for each peak
    for j=1:length(i0{j1})
      pk = i0{j1}(j);
      hw = w;
      pwr = options.com;
      inds = max(1,pk-hw):min(length(x),pk+hw);
      i0{j1}(j) = sum(inds.*x(inds).^pwr)./sum(x(inds).^pwr);
    end
  end

  
end

%if user asked for second output...
if nargout>1
  for j1=1:m %Find windows around major peaks, each window may have more than one peak
    %     i1  = find(d0(j1,:)<=tol0); %channels not in peaks
    %     i1  = find(d2(j1,:)>=-tol2); %channels not in peaks
    i1  = find(d0(j1,:)<tol0 | d2(j1,:)>=-tol2);
    if ~isempty(i1)
      i2     = i0{j1};
      d01    = i2(ones(length(i1),1),:)-i1(ones(length(i0{j1}),1),:)';
      iw{j1} = zeros(length(i0{j1}),2);
      for j3=1:length(i0{j1})
        j2           = find(d01(:,j3)<0);
        if ~isempty(j2);
          iw{j1}(j3,2) = i1(j2(1));
        else
          iw{j1}(j3,2) = i0{j1}(j3);
        end
        j2           = find(d01(:,j3)>0);
        if ~isempty(j2);
          iw{j1}(j3,1) = i1(j2(end));
        else
          iw{j1}(j3,1) = i0{j1}(j3);
        end
      end
    else
      iw{j1} = zeros(length(i0{j1}),2);
      iw{j1}(:,1) = 1;
      iw{j1}(:,2) = length(d0(j1,:));
    end
  end
end

%function index = localmaxima(x)
%index = find( diff( sign( diff([0; x(:); 0]) ) ) < 0 );
% is courtesy of KVL (reference?)
    
