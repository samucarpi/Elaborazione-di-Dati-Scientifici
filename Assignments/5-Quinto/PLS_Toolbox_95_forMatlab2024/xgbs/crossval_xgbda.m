function varargout = crossval_xgbda(varargin)
%CROSSVAL_XGB Helper function for XGBDA cross-validation.

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

out = false;

%------------------------------------------------
function out = getoptions(varargin)
% get any special options needed to call calc and apply methods
%
%I/O: out = getoptions(options)

out = crossval_xgb('getoptions',varargin{:});

%------------------------------------------------
function [bbr,ssq] = precalcmodel(varargin)
% perform any model pre-calculation (based on entire data set and upper
% limit on ncomp) Input "opts" will be options created by getoptions call.
%
%I/O: [bbr,ssq] = precalcmodel(calx,caly,ncomp,opts)

[bbr,ssq] = crossval_xgb('precalcmodel',varargin{:});


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

[ypred,bbr] = crossval_xgb('apply',varargin{:});

%--------------------------------------------------------------------------
function [opts] = updateopts(opts, key, value)
% % add a key:value pair to opts struct
% if isstruct(opts) & ischar(key)
%   opts.(key) = value;
% end