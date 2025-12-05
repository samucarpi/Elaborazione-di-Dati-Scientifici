function varargout = crossval_lda(varargin)
%CROSSVAL_LDA Helper function for LDA cross-validation.

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

out = true;

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

out = reconopts(options.rmoptions,'lda',0);

% if isfield(options, 'cvi')
%   cvi = options.cvi;
% else
%   cvi = [];
% end
% % out = reconopts(options,'ann',0);
% 
% out.cvi = cvi;
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

commodel = [];
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

opts.cvi = []; % CV not needed here
opts.ncomp = myncomp;
model = ldaimpl(calx,caly,opts.lambda,opts);

%apply model to test data
pred = ldaimpl(tstx,model,opts);
ypred = pred.detail.predprobability;

%--------------------------------------------------------------------------
function [opts] = updateopts(opts, key, value)
% % add a key:value pair to opts struct
% if isstruct(opts) & ischar(key)
%   opts.(key) = value;
% end