function varargout = crossval_builtin(varargin)
%CROSSVAL_BUILTIN Helper function for built-in model cross-validation.

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
function out = rankdependent_methods
%list of methods which need ncomp to be limited by rank of X-block
out = {'nip' 'sim' 'pls' 'dspls' 'robustpls' 'pcr' 'correlationpcr' 'robustpcr' 'mlr' 'lwr' 'pca' 'polypls'};

%-------------------------------------------------
function out = builtin_methods
%list of methods which are supported by this code

out = {'nip' 'sim' 'pls' 'dspls' 'robustpls' 'pcr' 'correlationpcr' 'robustpcr' 'lwr' 'pca' 'polypls'};

%-------------------------------------------------
function out = methodname(varargin)
%store currently used method

persistent mymethod

if nargin>0
  mymethod = varargin{1};
  if strcmp(mymethod,'pls')
    mymethod = 'sim';   %translate PLS to SIM
  end
elseif isempty(mymethod)
  error('Method name must be set before using')
end

out = mymethod;  %return function handle

%-------------------------------------------------
function out = isregression(varargin)
% is method a regression method (true), decomposition methods should return
% FALSE indicating they do not predict y-blocks, only estimate x-blocks.
%
%I/O: out = regression

out = ~strcmp(methodname,'pca');

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

switch methodname
  case 'mlr'
    out = false;
  otherwise
    out = true;
end

%------------------------------------------------
function opts = getoptions(varargin)
% get any special options needed to call calc and apply methods
%
%I/O: out = getoptions(options)

options = varargin{1};

switch methodname
  case {'sim' 'robustpls'}
    opts = simpls('options');
    opts.display  = 'off';
    opts.plots    = 'none';
    opts.ranktest = 'auto';
    opts.norecon  = 'true';  %fast options reconcile
    opts.weights  = encodeweight(options);
  case 'dspls'
    opts = dspls('options');
    opts.display  = 'off';
    opts.plots    = 'none';
    opts.ranktest = 'auto';
    opts.norecon  = 'true';  %fast options reconcile
    opts.weights  = encodeweight(options);
  case 'polypls'
    opts = polypls('options');
    opts.display = 'off';
    opts.order = options.rmoptions.order;
  case {'pcr'  'robustpcr'}
    opts = pcrengine('options');
    opts.display = 'off';
    opts.plots = 'none';
    opts.norecon  = 'true';  %fast options reconcile
    opts.sortorder = 'x';
  case 'correlationpcr'
    opts = pcrengine('options');
    opts.display = 'off';
    opts.plots = 'none';
    opts.norecon  = 'true';  %fast options reconcile
    opts.sortorder = 'y';
  case 'nip'
    opts = nippls('options');
    opts.display = 'off';
    opts.plots = 'none';
    opts.norecon  = 'true';  %fast options reconcile
    opts.weights  = encodeweight(options);
  case {'mlr'}
    %do nothing in these cases
    opts = [];
  case {'lwr'}
    opts = options;
    
  case 'pca'
    opts = options;
    opts.pca = pcaengine('options');
    opts.pca.display = 'off';
    opts.pca.algorithm = 'auto';
    opts.pca.norecon  = 'true';  %fast options reconcile
    
    %check pcacvi option for compatibility with fastpca
    if strcmp(options.fastpca,'off')
      opts.fastpca = false;
    else
      opts.fastpca = true;
    end
    %if valid PCACVI cell OTHER than leave-one-out - force fastpca off
    if iscell(options.pcacvi) & ~isempty(options.pcacvi) & ~strcmp(options.pcacvi{1},'loo')
      opts.fastpca = false;
    end
    usefastpca(opts.fastpca);  %NOTE: this flag is used to keep us from trying fastpca if we've been blocked form using it due to memory errors
    
end

%------------------------------------------------
function [bbr,ssq] = precalcmodel(varargin)
% perform any model pre-calculation (based on entire data set and upper
% limit on ncomp) Input "opts" will be options created by getoptions call.
%
%I/O: [bbr,ssq] = precalcmodel(calx,caly,ncomp,opts)

[calx,caly,ncomp,opts] = deal(varargin{:});

%NCOMP testing
if isempty(ncomp) | ncomp > min(size(calx))
  error('Number of components (NCOMP) must be <= smallest size of x (rows or columns)')
end

%apply weighting (if opts.weights is present
if isfield(opts,'weights');
  [calx,caly] = weight(calx,caly,opts.weights);
end

bbr = [];
ssq = [];
switch methodname
  case {'sim' 'robustpls'}
    [bbr,ssq] = simpls(calx,caly,ncomp,opts);
  case 'dspls'
    [bbr,ssq] = dspls(calx,caly,ncomp,opts);
  case {'pcr','correlationpcr','robustpcr'}
    [bbr,ssq] = pcrengine(calx,caly,ncomp,opts);
  case 'nip'
    [bbr,ssq] = nippls(calx,caly,ncomp,opts);
  case 'polypls'
    [p,q,w,t,u,b,ssqdif] = polypls(calx,caly,ncomp,opts.order,opts);
    bbr = struct('b',b,'p',p,'q',q,'w',w);
    ssq = [[1:size(ssqdif,1)]' ssqdif(:,1) cumsum(ssqdif(:,1)) ssqdif(:,2) cumsum(ssqdif(:,2))];
  case 'mlr'
    % bbr = (pinv(calx)*caly)'; Use mlrengine for consistency with mlr useage
    bbr = mlrengine(calx, caly, opts)';
  case 'lwr'
    %nothing
  case 'pca'
    [ssq,datarank,v,t] = pcaengine(calx,ncomp,opts.pca);        %added ,t JMS
    
    bbr = [];
    bbr.ssq = ssq;
    bbr.datarank = datarank;
    bbr.v = v;
    bbr.t = t;
    
    if size(calx,2)>1000
      usefastpca(false)
    end
    if usefastpca
      try
        nx = size(v,1);
        bbr.rpca = eye(nx)-v(:,1)*v(:,1)';
        bbr.replacemat = zeros(nx);
      catch
        usefastpca(false)     %set internal flag to not use fastpca until reset
      end
    end
    bbr.fastpca = usefastpca;  %store flag in model (used by apply)
    
end

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

[calx,caly,tstx,bbr,myncomp,opts] = deal(varargin{:});

if isempty(tstx)
  tstx = calx;
end
ny = size(caly,2);

switch methodname
  case {'sim','dspls','robustpls','pcr','correlationpcr','robustpcr','nip','mlr'}
    ypred = tstx*bbr((myncomp-1)*ny+1:myncomp*ny,:)';
  case 'polypls'
    ypred = polypred(tstx,bbr.b,bbr.p,bbr.q,bbr.w,myncomp);
  case 'lwr';
    opts.lwr.preprocessing = 0;  %ALWAYS force to be none
    ypred = lwrpred(tstx,calx,caly,min(myncomp,opts.lwr.minimumpts), ...
      min([max([opts.lwr.minimumpts myncomp*opts.lwr.ptsperterm]) size(calx,1)]),opts.lwr);
  case 'pca'
    [ypred,bbr] = pcaapply(calx,tstx,myncomp,bbr,opts);
end


%------------------------------------------------
function [ssresid,bbr] = pcaapply(calx,tstx,myncomp,bbr,opts)

v  = bbr.v;
nx = size(calx,2);

if bbr.fastpca
  %loo fast PCA replacement method
  replacemat = bbr.rpca;
 
  %The following was the old (wrong) way of doing it
  %(gives answers like projecting onto the loadings rather than using
  %least-squares on the loadings)
  %  replacemat(1:nx+1:end) = 1;   
  
  %the below code matches replace and matches when you do least-squares
  %onto the loadings
  d = diag(replacemat);
  d = max(d,eps);
  for kkk = 1:nx
    replacemat(:,kkk) = (1/d(kkk))*replacemat(:,kkk);
  end
  %and the above code can be replaced with a matrix-oriented alternative to
  %but the following is even slower and even more memory intensive:
  %  replacemat = replacemat*diag(1./d); 
  ssresid = mean(sum((tstx*replacemat).^2,1),2);

  if myncomp<size(v,2) & myncomp<bbr.datarank
    temp = bbr.rpca - v(:,myncomp+1)*v(:,myncomp+1)';
    if ~any(diag(temp)<eps*10)
      %if this didn't drop any of the diagonal elements below eps (or
      %negative) keep it
      bbr.rpca = temp;
    end
  end

else
  %Calculate using less memory intensive (but slower) approach
  %also allows other leave-out methods
  try
    varsets = encodemethod(size(calx,2),opts.pcacvi{:});
  catch
    disp(lasterr);
    error('Option PCACVI is not in the correct format or is invalid for the number of variables.');
  end
  
  usepcs = 1:min(myncomp,bbr.datarank);
  ssresid = zeros(1,nx);
  for kkk = 1:max(varsets);
    repvars = (varsets==kkk);
    temp = v(:,usepcs);
    temp(repvars,:) = 0;
    %use least-squares to get tstx's projection onto the variables that are
    %NOT left out (note: do NOT use: tstx*temp*v because that is NOT
    %correct for replacement of variables)
    residx = tstx(:,repvars) - tstx/temp'*v(repvars,usepcs)';
    ssresid(1,repvars) = sum(residx.^2);
  end
  ssresid = mean(ssresid);  %NOTE: mean here to correct for # of varsets
end

%------------------------------------------------------------
function out = usefastpca(in)
% Internal property saying if we're allowed to use fast pca

persistent local_flag
if nargin>0
  local_flag = in;
end
if isempty(local_flag)
  local_flag = true;
end
if nargout>0
  out = local_flag;
end

%--------------------------------------------------------------------------
function out = encodeweight(options)
%convert from string into vector

out = [];
if isfield(options,'weights') & ischar(options.weights)
  switch options.weights
    case 'custom'
      out = options.weightsvect;
    case 'none'
      out = [];
    otherwise
      out = options.weights;
  end
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

%--------------------------------------------------------------------------
function [opts] = updateopts(opts, key, value)
% opts.(key) = value;
% do nothing in this general builtin
