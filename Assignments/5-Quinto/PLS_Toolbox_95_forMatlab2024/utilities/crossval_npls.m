function varargout = crossval_npls(varargin)
%CROSSVAL_TEMPLATE Template for helper function for cross-validation.

%Copyright Eigenvector Research, Inc. 2010
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

out = reconopts(options.rmoptions,'npls');
out.display = 'off';
out.plots = 'none';

if ~isregression
  %in general, blockdetails = 'all' is required for decomposition methods
  out.blockdetails = 'all';
end

%------------------------------------------------
function [bbr,ssq] = precalcmodel(varargin)
% perform any model pre-calculation (based on entire calibration data set
% and upper limit on ncomp) Input "opts" will be options created by
% getoptions call.
%
% If models are "nested" and do not need to be recalculated for each number
% of components, this is the correct place to do that calculation and store
% the results in bbr. bbr can be in whatever variable format that is
% convenient. For the most part, it is only these functions that need to
% use bbr.
%
% The ssq output can be a standard ssq table format to be displayed at the
% end of all anayses (for self-prediction). It must be in a format that is
% interpretable by the ssqtable() function or empty [] which will squelch
% any ssq table output.
%
%I/O: [bbr,ssq] = precalcmodel(calx,caly,ncomp,opts)

[calx,caly,ncomp,opts] = deal(varargin{:});

bbr = npls(calx,caly,ncomp,opts);
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

if isempty(tstx)
  tstx = calx;
end

ypred = npls(tstx,[],myncomp,bbr, struct([]));
ypred = ypred.pred{end};

%--------------------------------------------------------------------------
function [opts] = updateopts(opts, key, value)
% % add a key:value pair to opts struct
% if isstruct(opts) & ischar(key)
%   opts.(key) = value;
% end
