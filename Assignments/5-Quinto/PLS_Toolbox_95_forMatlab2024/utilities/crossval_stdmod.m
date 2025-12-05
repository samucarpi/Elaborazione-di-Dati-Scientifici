function varargout = crossval_stdmod(varargin)
%CROSSVAL_STDMOD Helper function for standard model cross-validation.

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
function out = methodname(varargin)

persistent mymethod

if nargin>0
  if ~exist(varargin{1},'file');
    error('Regression method (rm) not of known type.')
  end
  mymethod = varargin{1};
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

out = true;  %default if we can't create a model to test
try
  mod = modelstruct(methodname);  %look at a standard model structure
  out = length(mod.datasource)>1;  %see how many blocks it allows
catch
  %error doing this? assume true
end

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

out = reconopts(options.rmoptions,methodname);
out.display = 'off';
out.plots = 'none';
out.waitbar = 'off';

if ~isregression
  out.blockdetails = 'all';
end

%------------------------------------------------
function [bbr,ssq] = precalcmodel(varargin)
% perform any model pre-calculation (based on entire data set and upper
% limit on ncomp) Input "opts" will be options created by getoptions call.
%
%I/O: [bbr,ssq] = precalcmodel(calx,caly,ncomp,opts)

[calx,caly,ncomp,opts] = deal(varargin{:});

bbr = [];
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

if ~isempty(caly)
  model = feval(methodname,calx,caly,myncomp,opts);
else
  model = feval(methodname,calx,myncomp,opts);
end
if isempty(tstx)
  tstx = calx;
end
ypred = feval(methodname,tstx,model,opts);
if ~isempty(caly)
  ypred = ypred.pred{end};
else
  ypred = sum(ypred.ssqresiduals{1});
end

%--------------------------------------------------------------------------
function [opts] = updateopts(opts, key, value)
% % add a key:value pair to opts struct
% if isstruct(opts) & ischar(key)
%   opts.(key) = value;
% end
