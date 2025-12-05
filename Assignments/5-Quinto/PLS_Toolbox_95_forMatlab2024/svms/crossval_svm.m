function varargout = crossval_svm(varargin)
%CROSSVAL_SVM Helper function for SVM cross-validation.

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

out = false;

%------------------------------------------------
function out = getoptions(varargin)
% get any special options needed to call calc and apply methods
%
%I/O: out = getoptions(options)

options = varargin{1};

if ~isfield(options,'norecon')  
  % Before calling reconopts, it is necessary to set all the paired options
  % for example, n->nu, p->epsilon, c->cost, g->gamma, s->svmtype
  % so that if n/p/c/g/s is present the other is set consistently.
  % Otherwise, the long name form can get set to a different (default) value
  % by reconopts.
  consistentopts = makeconsistent(options.rmoptions);
  
  out = reconopts(consistentopts,'svm',0);
else
  out = options;
end
out.display = 'off';
out.plots = 'none';
out.waitbar = 'off';

%------------------------------------------------
function [bbr,ssq] = precalcmodel(varargin)
% perform any model pre-calculation (based on entire data set and upper
% limit on ncomp) Input "opts" will be options created by getoptions call.
%
%I/O: [bbr,ssq] = precalcmodel(calx,caly,ncomp,opts)

[calx,caly,ncomp,opts] = deal(varargin{:});

switch opts.compression
  case 'pca'
    comopts = struct('display','off','plots','none','confidencelimit',0,'preprocessing',{{[] []}});
    commodel = pca(calx,opts.compressncomp,comopts);
  case 'pls'
    comopts = struct('display','off','plots','none','confidencelimit',0,'preprocessing',{{[] []}});
    if ~isclassification(opts)
      commodel = pls(calx,caly,opts.compressncomp,comopts);
    else
      commodel = plsda(calx,caly,opts.compressncomp,comopts);
    end
  otherwise
    commodel = [];
end
if ~isempty(commodel)
  scores   = commodel.loads{1};
  if strcmp(opts.compressmd,'yes')
    incl = commodel.detail.includ{1};
    eig  = std(scores(incl,:)).^2;
    commodel.detail.eig = eig;
  else
    commodel.detail.eig = ones(1,size(scores,2));
  end
end

bbr = struct('commodel',commodel);
ssq = [];

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

% May need to adjust nu to be smaller that the new nuMax specific to this
% CV sub-problem
if isNuClassification(opts)
  opts = checkNuRange(opts, caly);
end

if ~isempty(bbr.commodel)
  calx = bbr.commodel.loads{1};  %use scores for calx
  if isempty(tstx)
    %no test x? just use scores from calibration data
    tstx = bbr.commodel.loads{1};
  else
    %apply the model
    pred = feval(lower(bbr.commodel.modeltype),tstx,bbr.commodel,struct('plots','none','display','off'));
    tstx = pred.loads{1};   %scores from test data
  end
  calx = calx*diag(1./sqrt(bbr.commodel.detail.eig));
  tstx = tstx*diag(1./sqrt(bbr.commodel.detail.eig));
else
  %no compression model
  if isempty(tstx)
    %no test x? just use calx
    tstx = calx;
  end
end

%calibrate SVM model, using the possibly adjusted nu (to be a feasible nu)
model = svmengine(calx,caly,opts);
%check if we just did optimization...
if ~isa(model,'libsvm.svm_model')
  %calculate model at the optimal arguments
  model = svmengine(calx,caly,model.optimalArgs);
end
%apply model to test data
ypred = svmengine(tstx,model,opts);

%-----------------------------------------------------------------
function options = checkNuRange(options, ydata)
%CHECKNURANGE Check nu param values do not exceed the admissible range.
% nu-svc requires the nu parameter lies between 0 and a threshold value
% less than or equal to 1, which depends on the distribution of the
% sample data between the classification groups, as described in
% "A Tutorial on nu-Support Vector Machines" by Chen, Lin and Scholkopf.
% See section 8. Note that the ydata is assumed to be integer type (so 
% float values are truncated to integers).
%I/O: options = checkNuRange(options);

% Check the nu value if nu-svc
P = hist(floor(ydata), unique(floor(ydata)));
nuMax = 1;
np = length(P);
for i=1:np
  for j = (i+1):np
    nuMaxIj = 2*(min(P(i),P(j)))/(P(i)+P(j));
    if nuMaxIj < nuMax
      nuMax = nuMaxIj;
    end
  end
end

% If necessary, rescale options.nu downwards so max(options.nu) = 0.99*nuMax
if max(options.nu) > 0.99*nuMax
  rescaleFactor = 0.99*nuMax/max(options.nu);
  options.nu = options.nu*rescaleFactor;
  options.n  = options.nu;
end

%--------------------------------------------------------------------------
function options = makeconsistent(options);
% Using reconopts may have set svmtype to default even if option.s was set
% differently. Set svmtype to be consistent with s.
% Similarly, for n, c, g, and p setting nu, cost, gamma, and epsilon.
if isfield(options, 's') & ~isempty(options.s)
  switch options.s
    case 0
      options.svmtype = 'c-svc';
    case 1
      options.svmtype = 'nu-svc';
    case 2
      options.svmtype = 'one-class svm';
    case 3
      options.svmtype = 'epsilon-svr';
    case 4
      options.svmtype = 'nu-svr';
  end
end

if isfield(options, 'n') & ~isempty(options.n)
  options.nu = options.n;
end
if isfield(options, 'c') & ~isempty(options.c)
  options.cost = options.c;
end

if isfield(options, 'g') & ~isempty(options.g)
  options.gamma = options.g;
end
if isfield(options, 'p') & ~isempty(options.p)
  options.epsilon = options.p;
end

%-----------------------------------------------------------------
function [result] = isNuClassification(args)
%ISNUCLASSIFICATION Test if args invoke nu classification type SVM analysis.
% True if SVM type is nu classification, false otherwise.
%I/O: out = isNuClassification(args_struct);

result = false;

if isfield(args, 's')
  switch args.s
    case {'1', 1}
      result = true;
    otherwise
      result = false;
  end
elseif isfield(args, 'svm_type')
  switch args.svm_type
    case {'1', 1}
      result = true;
    otherwise
      result = false;
  end
elseif isfield(args, 'svmtype')
  switch lower(args.svmtype)
    case {'nu-svc'}
      result = true;
    otherwise
      result = false;
  end
end

%--------------------------------------------------------------------------
function [opts] = updateopts(opts, key, value)
% % add a key:value pair to opts struct
% if isstruct(opts) & ischar(key)
%   opts.(key) = value;
% end
