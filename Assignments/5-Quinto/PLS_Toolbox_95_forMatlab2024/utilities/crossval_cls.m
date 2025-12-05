function varargout = crossval_cls(varargin)
%CROSSVAL_CLS Helper function for CLS cross-validation.

%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargout==0
  feval(varargin{:});
else
  [varargout{1:nargout}] = feval(varargin{:});
end

%-------------------------------------------------
function out = isregression(varargin)
% is method a regression method (true), decomposition methods should return
% FALSE indicating they do not predict y-blocks, only estimate x-blocks.
%
%I/O: out = regression

out = true;

%-------------------------------------------------
function out = forcediscrim
%defines if this method FORCES discrimiant analysis method (only a value of
%"true" when returned will actually have any impact)

out = false;

%-------------------------------------------------
function out = usefactors(varargin)
% does method allow cross-validation over # of factors?
% if "false", ncomp will be limited to 1
%
%I/O: out = usefactors

out = true;

%------------------------------------------------
function out = getoptions(varargin)
% get any special options needed to call calc and apply methods
%
%I/O: out = getoptions(options)

options = varargin{1};

% if not glsw_clsresiduals_filter
glsw_clsresiduals_filter = has_glsw_clsresiduals_filter(options);
if ~glsw_clsresiduals_filter
  %do nothing for 'cls'
  out = [];
else
  out = reconopts(options.rmoptions,'cls',0);
  out.display = 'off';
  out.plots = 'none';
  out.waitbar = 'off';
  out.preprocessing = options.preprocessing;  % needed for clsResiduals CV
end


%------------------------------------------------
function [bbr,ssq] = precalcmodel(varargin)
% perform any model pre-calculation (based on entire data set and upper
% limit on ncomp) Input "opts" will be options created by getoptions call.
%
%I/O: [bbr,ssq] = precalcmodel(calx,caly,ncomp,opts)

[calx,caly,ncomp,opts] = deal(varargin{:});

%apply weighting (if opts.weights is present
if isfield(opts,'weights');
  [calx,caly] = weight(calx,caly,opts.weights);
end

ssq = [];
bbr = pinv(caly)*calx;

%------------------------------------------------
function [ypred,bbr] = apply(varargin)
% perform an application of a model. May also include a CALIBRATION of said
% model if precalcmodel doesn't calculate a model.
% Inputs are:
%   calx    = the calibration x block
%   caly    = the calibration y block
%   tstx    = the data to which the model should be applied. If empty, the
%              model should be applied to calx
%   bbr     = the output of the precalcmodel call
%   myncomp = the number of components to apply to the given data
%   opts    = the options structure created by the getoptions call
%
%I/O: [ypred,bbr] = calapply(calx,caly,tstx,bbr,myncomp,opts)

[calx,caly,tstx,bbr, icomp, opts] = deal(varargin{:});

glsw_clsresiduals_filter = has_glsw_clsresiduals_filter(opts);

% Distinguish case of CLS with glsw-using-clsResiduals filter
if ~glsw_clsresiduals_filter
  % For 'cls' crossval_builtin::apply had:
  %  ...and icomp = 1
  icomp = 1;
  
  if isempty(tstx)
    tstx = calx;
  end
  ny = size(caly,2);
  ypred = tstx/bbr((icomp-1)*ny+1:icomp*ny,:);
  
else
  glswmod = opts.ppx(end).out{2};
  v = glswmod.detail.v;
  s = glswmod.detail.s;
  if isfieldcheck('.options.s1', glswmod.detail)
    s1 = glswmod.detail.options.s1;
  else
    s1 = 1;
  end

  alphas = opts.preprocessing{1}(end).userdata.a;
  if alphas(icomp) >= 0
    a = alphas(icomp);  % /s1;  % don't scale alpha for glsw-using-clsResiduals filter 
                        % This is to be consistent with glsw usage.
    dri  = s./( a.^2);
    di  = 1./sqrt(dri + 1);
  else
    % negative options.a = trim to given # of components
    a = abs(fix(alphas(icomp)));
    if a>size(glswmod.detail.s,1)
    %   error('When using a "trim" alpha (a) the number of components included in the model can not be greater than the number originally included');
      a = size(glswmod.detail.s,1);
    end
    di = glswmod.detail.s(1:a)+1;      % epo case already has s values = -1
    v = glswmod.detail.v(:,1:a);
  end
  
  % xcal, xtst for this split, preprocessed except not by final glsw step
  calx = opts.ppx(end).out{3};
  if length(opts.ppx(end).out)>3 & isdataset(opts.ppx(end).out{4})
    tstx = opts.ppx(end).out{4};
  else
    tstx = calx;
  end
  incl  = opts.ppx(end).out{3}.include;
  calx   = calx.data(:,incl{2});
  tstx   = tstx.data(:,incl{2});
  
  % Use the "d-1, and add calx" approach for best numerical behavior
  calx = (calx*v)*(diag(di-1)*v') + calx;
  tstx = (tstx*v)*(diag(di-1)*v') + tstx;
  bbr = pinv(caly)*calx;    % recalc after modifying preprocessed calx
  
  if isempty(tstx)
    tstx = calx;
  end
  ny = size(caly,2);
  ypred = tstx/bbr(1:ny,:);  % bbr is recalculated each icomp
end

%--------------------------------------------------------------------------
function [res] = has_glsw_clsresiduals_filter(options)
% Is the final X-block preprocessing step a clutter filter using GLSW with
% source = cls_residuals?
res    = false;

if isfieldcheck(options, '.preprocessing')
  if iscell(options.preprocessing) & isstruct(options.preprocessing{1})
    t1 = strcmpi(options.preprocessing{1}(end).keyword, 'declutter GLS Weighting');
    if t1
      t2 = strcmp(options.preprocessing{1}(end).userdata.source, 'cls_residuals');
    else
      t2 = false;
    end
    if t1 & t2
      res = true;
    end
  end
end

%--------------------------------------------------------------------------
function [opts] = updateopts(opts, key, value)
% add a key:value pair to opts struct
if isstruct(opts) & ischar(key)
  opts.(key) = value;
end

%--------------------------------------------------------------------------
function [xsub,ysub] = weight(x,y,weights,ical)

if ~isempty(weights)
  if strcmp(weights,'hist')
    %calculate histogram-based correction
    [hy,hx] = hist(y(:,1),40);
    weights = 1./interp1(hx,hy,y(:,1),'nearest','extrap')';
  end
  xsub = rescale(x',zeros(1,size(x,1)),weights)';
  ysub = rescale(y',zeros(1,size(y,1)),weights)';
else
  xsub = x;
  ysub = y;
end