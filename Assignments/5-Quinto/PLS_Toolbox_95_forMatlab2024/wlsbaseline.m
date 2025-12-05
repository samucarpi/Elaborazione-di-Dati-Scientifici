function [data,allb,a,vweights] = wlsbaseline(data,order,options)
%WLSBASELINE Weighted least squares baseline function.
%  Subtracts a baseline (or other signal) from a spectrum (row) using an
%  iterative asymmetric least squares algorithm. Points with residuals <0
%  are up-weighted at each iteration of the least squares fitting (this
%  corresponds to the default options.trbflag='bottom'). The result
%  is a robust "non-negaitve" residual fit when residuals of significant
%  amplitude are present (i.e., signal is present on a background).
%  There are several different filters are available, defined using the
%  "filter" parameter:
%     'basis' = baseline subtraction using either specified vectors, or a
%               polynomial basis. This algorithms is generally slower but
%               introduces fewer artifacts.
%     'whittaker' = baseline subtraction using the Eilers' method based on
%               a Whittaker filter.
%
%  INPUTS:
%        data = MxN data to be baselined - each ROW is baselined.
%       order = 1xN or KxN matrix of basis vectors. If filter = "basis",
%                  (order) is a set basis vectors for the baseline,
%            OR an integer scalar value (order) corresponding to the
%                  order of polynomial baseline to use,
%            OR a positive scalar value. If filter = "whittaker", lambda
%                  gives the smoothness for the whittaker filter. The smaller 
%                  the value, the more curved the baseline fit. Larger values
%                  result in a smoother baseline fit.
%
%  OPTIONAL INPUT:
%     options = an options structure with the following fields:
%          dim: [2] Dimension (mode) of data to baseline.
%        plots: [{'none'} | 'debug' | 'intermediate' | 'final'] governs plots,
%       filter: [{'basis'} | 'whittaker' ] governs baseline filter type.
%                'basis' uses the a set of basis vectors fit to each
%                        spectrum. Input (baseline) specifies either a
%                        polynomial order or the specific baselines to use.
%                'whittaker' uses the Whittaker filter. Input (lambda) specifies 
%                        the strength of the smoothness. Also see input (p).
%   weightmode: [ {1} | 2 ] flag indicating which weighting mode to use.
%                Mode 1 = Power method. Negative (<0) residuals are weighted up
%                by the power of 10.^(option.negw). All residuals are then
%                raised to the power of (option.power).
%                Mode 2 = T squared method. Negative (<0) residuals are weighted
%                up by the extent to which the surpass an estimate of the
%                noise limit and the approximate t-limit defined by
%                (option.tsqlim).
%      trbflag: [ {'bottom'} | 'top' ] Baseline to top or bottom of data.
%         negw: {1} upweighting scale of negative values (10^negw) (used only
%                for weightmode = 1),
%        power: {2} exponential amplification of residuals (used only for
%                weightmode = 1),
%          wti: [] initial weighting in range [0,1], 1xN class double.
%                For entries set to 0, this option is used to define known 
%                regions not to be used in the baseline calculation. For any
%                value >0 the region is used with the input weighting.
%       tsqlim: [0.99] t-test confidence limit for significant negative
%                residuals which need to be up-weighted. (used only for
%                weightmode = 2),
%       nonneg: [{'no'}|'yes'] flag to force non-negative baseline weighting,
%                Most often used when "real" spectra are used for baslineing
%                and they should not be "flipped" by a negative weighting.
%                Using nonneg = 'yes', WLSBASELINE an be used as a partial
%                CLS prediction to estimate the concentration of a species
%                when not all species' pure component spectra are known.
%        delta: [1e-9] change-of-fit convergence criterion,
%      maxiter: [100] maximum iterations allowed per spectrum
%      maxtime: [600] maximum time (in seconds) permitted for baselining of
%                each spectrum.
%            p: {0.001} asymmetry (used only with algorithm = 'whittaker')
%               sets a "tolerance" for points above the baseline. The smaller 
%               this value, the smaller the allowed negative portion of the 
%               baselined result. Values closer to 1 permit more negative values. 
%
%               The following 3 option fields are empty by default. If they
%               are present with non-empty values then the appropriate one is
%               used to override the value of the second parameter, 'order'.
%        vwt2z: [{false} | true] flag for vweights, if true then
%               vweights = the MxN matrix of baselines.
% waitbarthreshold: [60] waitbar only appears for longer processes (seconds)
%
%  OUTPUTS:
%      bldata = MxN baselined data.
%           b = Weights corresponding the amount of baseline removed from
%               each spectrum (i.e. bldata = data - b*baseline).
%               If (baseline == polynomial order), (b) contains the polynomial
%               coefficients. Each row of (b) can be used with output
%               (baseline) [see below] to obtain the baseline removed from the
%               corresponding row of data.
%               Note that (a) can also be used with the POLYVAL function to
%               reconstruct the baseline, however, a normalization factor
%               of 1./sqrt(n) must be used on each baseline to correct for
%               the number of variables (n).
%    baseline = Baseline basis used for each spectrum - this is the
%               input (baseline) or polynomial basis.
%    vweights = Variable weights used for each spectrum. Indicates the
%               weighting used on each variable in each spectrum.
%
%I/O: [bldata,b,baseline,vweights] = wlsbaseline(data,baseline,options);
%I/O: [bldata,b,baseline,vweights] = wlsbaseline(data,order,options);
%I/O: [bldata] = wlsbaseline(data,lambda,options);  %Whittaker
%
%See also: BASELINE, BASELINEW, MSCORR, SAVGOL

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0;  data = 'io'; end
if ischar(data)
  options = [];
  
  %display and general settings
  options.plots   = 'none';
  options.nonneg  = 'no';
  
  options.filter  = 'basis';
  options.weightmode = 1;  %EXPERIMENTAL   weightmode : [{1}| 2 ] method to handle weighting.
  options.dim     = 2;
  
  %settings for weightmode 1
  options.power   = 2;
  options.negw    = 1;
  options.wti     = [];  %if used, it should be length(N)
  
  %settings for weightmode 2
  options.tsqlim  = 0.99;
  options.trbflag = 'bottom';
  
  %settings for weightmode 3 used with Whittaker
  options.p       = 0.001;
  
  %ending criteria
  options.delta   = 1e-9; %minimum change in fit
  options.maxiter = 100; %maximum iterations
  options.maxtime = 600; %maximum time per spectrum in seconds
  
  %flag for vweights, if true then vweights = z (the baseline)
  options.vwt2z   = false;
  
  options.waitbarthreshold = 60; % waitbar will not appear for processes taking less time (seconds)
  
  options.definitions = @optiondefs;
  
  if nargout==0; evriio(mfilename,data,options); clear data; else; data = evriio(mfilename,data,options); end
  return
end

if nargin<3; options  = []; end
if nargin<2; order    = 2;  end

options     = reconopts(options,'wlsbaseline',0);
options.nonneg  = strcmpi(options.nonneg,'yes');  %translate string to number (makes test in loop faster)

%determine if we're fitting the top or the bottom of the data
if strcmp(options.trbflag,'top')
  st        = -1;
else
  st        = 1;
end

if ndims(data)>2
  %multiway, handle in slabs
  wasdso    = isdataset(data);
  if ~wasdso
    data    = dataset(data);
  end
  mymode    = max(setdiff(1:ndims(data),options.dim));
  bldata    = data.data;
  for i=1:size(data,mymode)
    temp    = nindex(data,i,mymode);
    temp    = squeeze(temp);
    temp    = wlsbaseline(temp,order,options);
    bldata  = nassign(bldata,temp,i,mymode);
  end
  data.data = bldata;
  allb      = [];
  a         = [];
  vweights  = [];
  return
end

if options.dim==1
  data      = data';
end

%extract if was DSO
[m,n]       = size(data);
if isempty(options.wti)
  options.wti = ones(1,n);
else
  if length(options.wti)~=n
    error('Input (options.wti) must be length(N) with entries on [0,1].')
  end
  if any(options.wti>1 | options.wti<0)
    error('Input (options.wti) must be length(N) with entries on [0,1].')
  end
  options.wti = options.wti(:)';
end
if isa(data,'dataset')
  origdata  = data;
  wasdso    = true;
  incl      = data.include{2};
  xaxis     = data.axisscale{2};
  if ~isempty(xaxis)
    xaxis   = xaxis(incl);
  else
    xaxis   = incl;  %no axisscale? use include itself!
  end
  data      = data.data(:,incl);
  if ~isempty(options.wti)
    options.wti = options.wti(incl);
  end
  [m,n]     = size(data);
else
  wasdso    = false;
  incl      = 1:n;
  xaxis     = 1:n;
end

% override order from options' basis, lambda, or order, if set
if numel(order)>1 & strcmpi(options.filter,'basis') & isfield(options,'basis') & ~isempty(options.basis)
  order     = options.basis;
elseif numel(order)==1
  if strcmpi(options.filter,'whittaker') & isfield(options,'lambda') & ~isempty(options.lambda)
    order   = options.lambda;
  elseif strcmpi(options.filter,'basis') & isfield(options,'order') & ~isempty(options.order)
    order   = options.order;
  end
end

if numel(order)==1  %scalar? it actually IS order or lambda
  if ~strcmpi(options.filter,'whittaker')
    %polynomial baseline
    %     a = [];
    %     for i = 0:order
    %       a(i+1,:) = xaxis.^i;
    %     end
    %     a = normaliz(a,[],2);
    a       = polybasis(xaxis,order)';
  else
    a       = [];
  end
else
  if size(order,2)>n & max(incl)<=size(order,2)  %is order TOO long but include appears to apply
    order   = order(:,incl);  %apply include to the columns
  end
  if size(order,2)~=n
    error('provided background does not match size of data');
  end
  a         = order;   %use it as the baseline
  order     = size(order,1)-1;
end

if strcmp(options.plots,'final')
  subplot(2,1,1); plot(data);
  ylabel('Original Data');
end

tsqst       = ttestp(1-options.tsqlim,5000,2);
allwts      = [];    
allb        = [];
waitbarstarttime  = now;
waitbarhandle     = [];
fcancel     = 0;
if strcmpi(options.filter,'whittaker') %Eilers Whittaker filter
  [data,allwts]   = asymcorr(data,order,options.p,options.maxtime, options.maxiter, options.waitbarthreshold);
  if ~options.vwt2z
    allwts  = [];
  end
else                                   %other baselining modes
  for specind=1:m
    starttime = now;
    spec    = data(specind,:);
    
    res     = ones(size(spec));
    wts     = res;
    ores    = res*inf;
    ossres  = inf;
    negs    = true(1,length(wts));
    
    %initial guess as stats for weighting
    if isempty(options.wti)
      if options.nonneg
        b   = fastnnls(a',spec',0)';
      else
        b   = spec/a;
      end
    else
      wts   = 1./(options.wti+1e-4);
      if options.nonneg
        b   = fastnnls((a./(ones(order+1,1)*wts))',(spec./wts)',0)';
      else
        b   = (spec./wts)/(a./(ones(order+1,1)*wts));
      end
    end
    res       = st*(spec-b*a);
    reslimit  = 0.05*rmse(res);
    for loop=1:options.maxiter
      switch options.weightmode
      case 1
        negs       = res<0;
        res(negs)  = real(res(negs)/(10.^options.negw));   %weight negative residuals
        res        = abs(res.^options.power);
        mres       = median(res);
        if mres==0
          mres = 1;
        end
        wts        = (1+res./mres);
      case 2
        tsq        = res/reslimit;
        negs       = tsq>tsqst;
        wts        = tsq.*0+1;
        wts(negs)  = (0.5 + tsq(negs)./tsqst); 
      end
      
      ores  = res;
      ob    = b;
      if options.nonneg
        b   = fastnnls((a./(ones(order+1,1)*wts))',(spec./wts)',0,b')';
      else
        b   = (spec./wts)/(a./(ones(order+1,1)*wts));
      end
      
      res   = st*(spec-b*a);
      ssres = rmse(res/reslimit);
      Dres  = ssres-ossres;
      ossres  = ssres;
      
      if strcmpi(options.plots,'debug')
        subplot(3,1,1);
        plot(xaxis,res);
        hline
        ylabel('Residuals');
        title(['Iterations ' num2str(loop) '  Delta Residuals: ' num2str(Dres)]);
        subplot(3,1,2);
        plot(xaxis,wts);
        ylabel('Deweighting');
        subplot(3,1,3);
        plot(xaxis,spec,1:n,b*a)
        ylabel('Orig and Baseline');
        drawnow
        pause;
      end
      
      if abs(Dres) < options.delta; break; end
      if (now-starttime)*60*60*24 > options.maxtime; break; end
    end
    
    if strcmpi(options.plots,'intermediate')
      subplot(2,1,1);
      plot(xaxis,res);
      hline
      ylabel('Residuals');
      title(['Iterations ' num2str(loop)]);
      subplot(2,1,2);
      plot(xaxis,spec,xaxis,b*a)
      ylabel('Orig and Baseline');
      title(sprintf('Neg. Weight: %g   Resid. Order: %g',options.negw,options.power))
      drawnow
      %     pause
    end
    
    if nargout>=2
      allb(specind,:)     = b;
      if options.vwt2z
        allwts(specind,:) = b*a;
      else
        allwts(specind,:) = 1./wts;
      end
    end
    data(specind,:) = spec-b*a;

  elap = (now-waitbarstarttime)*60*60*24;
    if elap>options.waitbarthreshold % only show waitbar for long processes
     complete = specind/m; 
        if isempty(waitbarhandle) 
           waitbarhandle = waitbar(complete,'Please wait...','Name', 'Peforming Baseline', 'CreateCancelBtn', 'setappdata(gcbf,''Cancel'',1)');
        end
        if getappdata(waitbarhandle, 'Cancel')
           delete(waitbarhandle)
           throw(MException('wlsbaseline:userTermination','Terminated by user'));
        end
     waitbar(complete);
    end
  end
  delete(waitbarhandle)
end


if strcmpi(options.plots,'final')
  plot(xaxis,data)
  ylabel('Baselined Data');
  title(sprintf('Neg. Weight: %g   Resid. Order: %g',options.negw,options.power))
  drawnow
end

if wasdso
  %insert baselined data back into DSO object
  origdata.data = origdata.data.*nan;
  origdata.data(:,incl) = data;
  data = origdata;
end

if nargout>=2
  vweights = allwts;
end

if options.dim==1
  data = data';
end

if fcancel | isempty(data)
  data = [];
end
   

%-----------------------------

function [ycorr,bg]=asymcorr(y,lambda,p,maxtime, maxiter, wbthreshold)
%From Eilers Anal Chem 2005
% lambda = smoothness
% p = asymmetry

if ~isa(y,'double')
  %Y needs to be double or C division won't work below. Y can be single if
  %image data is being used. 
  y = double(y);
end

[m,n]=size(y);
p = min((1-1e-10),p);  %keep p <1

D = diff(speye(n), 2);
DtD = lambda * (D' * D);

bg    = y;
w = ones(n, 1);
waitbarhandle = [];
waitbarstarttime = now;
fcancel =0;
for j=1:m
  starttime = now;
  
  y1 = y(j,:)';
  for it = 1:maxiter
    W = spdiags(w, 0, n, n);
    [C,ok] = chol(W + DtD);
    z = C \ (C' \ (w .* y1));
    w_old = w;
    w = p * (y1 > z) + (1 - p) * (y1 <= z);
    if all(w_old == w)
      break;
    end
  end
  bg(j,:)    = z';
  
  if (now-starttime)*60*60*24 > maxtime; break; end

    elap = (now-waitbarstarttime)*60*60*24;
    if elap>wbthreshold  % only show waitbar for long processes
     complete = j/m; 
        if isempty(waitbarhandle) 
           waitbarhandle = waitbar(complete,'Please wait...','Name', 'Peforming Baseline', 'CreateCancelBtn', 'setappdata(gcbf,''Cancel'',1)');
        end
        if getappdata(waitbarhandle, 'Cancel')
           delete(waitbarhandle)
           throw(MException('wlsbaseline:userTermination','Terminated by user'));
        end
     waitbar(complete);
    end
end
delete(waitbarhandle)
ycorr = y - bg;
if fcancel
  ycorr = [];
end


%--------------------------
function out = optiondefs

defs = {
  %name                    tab                datatype        valid                            userlevel       description
  'plots'                  'Display'          'select'        {'none' 'final' 'intermediate' 'debug'} 'novice'        'Governs plotting. Final returns a final plot at end of run, Intermediate returns plots after each spectrum is completed, Debug plots multiple steps during analyses, None gives no plots.'
  'filter'                 'Algorithm'        'select'        {'basis' 'whittaker'}           'novice'        'Filter to use: "basis" subtracts a weighted amount of a set of basis functions from each spectrum. "whittaker" uses the piecewise whittaker filter.'
  'dim'                    'Algorithm'        'double'        []                              'novice'        'Dimension (mode) across which to baseline. 1 = across rows (i.e. baseline each column of data), 2 = across columns (i.e. baseline rows of data)'
  'weightmode'             'Basis Filter'     'select'        {1 2}                         	'intermediate'  'Weighting mode to use: Mode 1 = Power method. Negative residuals are weighted up by the power of 10.^(option.negw). All residuals are then raised to the power of (option.power). Mode 2 = T squared method. Negative residuals are weighted up by the extent to which the surpass an estimate of the noise limit and the approximate t-limit defined by (option.tsqlim).'
  'wti'                    'Basis Filter'     'double'        []                              'intermediate'  'Initial weights in range [0,1], 1xN class double. 0, defines a region not used in the baseline calc. >0 uses the region.';
  'negw'                   'Basis Filter'     'double'        []                              'advanced'      'Upweighting scale of negative values (10^negw) (used only for weightmode = 1)';
  'power'                  'Basis Filter'     'double'        []                              'advanced'      'Exponential amplification of residuals (used only for weightmode = 1)';
  'tsqlim'                 'Basis Filter'     'double'        []                              'intermediate'  'T-test confidence limit for significant negative residuals which need to be up-weighted. (used only for weightmode = 2)';
  'trbflag'                'Basis Filter'     'select'        {'bottom' 'top'}                'intermediate'  'Baseline to: top or bottom of data.';
  'p'                      'Whittaker Filter' 'double'        []                              'novice'        'P parameter (0 < p < 1) indicating asymetry to use with Whittaker filter. The smaller this value, the smaller the allowed negative porition of the baselined result. Values closer to 1 permit more negative values.';
  'nonneg'                 'Basis Filter'     'select'        {'no' 'yes'}                    'advanced'      'Flag to force non-negative baseline weighting. Most often used when "real" spectra are used for baslineing and they should not be "flipped" by a negative weighting.';
  'delta'                  'End Criteria'     'double'        []                              'intermediate'  'Change-of-fit convergence criterion (basis filter only)';
  'maxiter'                'End Criteria'     'double'        []                              'intermediate'  'Maximum iterations allowed per spectrum.';
  'maxtime'                'End Criteria'     'double'        []                              'intermediate'  'Maximum time (in seconds) permitted for baselining of each spectrum.';
  'vwt2z'                  'Flag for vweights' 'boolean'      ''                              'intermediate'  'if vwt2z "true" then output vweights = z (the baselines)';
  'waitbarthreshold'       'Common'           'double'        'int(0:inf)'                    'advanced'      'Set a time threshold for waitbar appearance. Waitbar only appears if process takes longer than this (seconds)';
  };
out = makesubops(defs);
