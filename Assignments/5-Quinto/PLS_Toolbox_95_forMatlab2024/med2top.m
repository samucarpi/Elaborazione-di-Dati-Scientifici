function [yf,residual,options] = med2top(y,options)
%MED2TOP Fits a constant to top/(bottom) of data.
%  INPUTS:
%        y  = trace to be filtered, Mx1 vector.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%          display: [ 'off' | {'on'} ]      governs level of display to command window.
%          trbflag: [ {'top'} | 'bottom' | 'middle']  flag that tells algorithm to fit
%                    to the top, bottom, or middle of the data cloud.
%           tsqlim: [ 0.99 ]                limit that govers whether a data point is
%                    outside the fit residual defined by input (res).
%           initwt: []; empty or Mx1 vector of initial weights (0<=w<=1).
%
%  OUTPUTS:
%        yf = scalar, estimate of filtered data.
%  residual = y - yf.
%   options = input (options) echoed back, the field initwt may have been modified.
%
%  MED2TOP is similar to LSQ2TOP with a 0 order polynomial, it can be
%  considered an asymmetric estimate of the mean.
%  For fitting to the bottom
%    tsq      = residual/res;                    % (res) is an input
%    tsqst    = ttestp(1-options.tsqlim,5000,2); % T-test limit from table
%    ii       = find(tsq>-tsqst);                % finds samples below the line
%  the ii samples are kept for the next estimate of (yf) i.e.
%    yf       = median(y(ii));
%
%I/O: [yf,residual,options] = med2top(y,options);
%
%See also: BASELINE, BASELINEW, FASTNNLS, LSQ2TOP

%Copyright Eigenvector Research, Inc., 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 8/12/05 modified LSQ2TOP to a median filter

if nargin == 0; y  = 'io'; end
varargin{1}        = y;
if ischar(y);
  options          = [];
  options.name     = 'options';
  options.display  = 'on';
  options.trbflag  = 'top';
  options.tsqlim   = 0.99;
  options.initwt   = [];

  if nargout==0; 
    evriio(mfilename,varargin{1},options); 
  else
    yf    = evriio(mfilename,varargin{1},options); 
  end
  return; 
end
warning off backtrace

if nargin<2               %set default options
  options = [];
end
options = reconopts(options,'med2top',{'p','smooth','stopcrit'});
m       = length(y);
if prod(size(y))>m | prod(size(y))==1
  error('Input (y) must be a vector.')
end
y         = y(:);

if isempty(options.initwt)  %Initialize the wts
  options.initwt = ones(m,1);
else
  if length(options.initwt)~=m
    error('Options.initwt must be a vector with the same number of elements as rows of (x).')
  end
  options.initwt = options.initwt(:);
end
tsqst   = ttestp(1-options.tsqlim,5000,2);
switch lower(options.trbflag)
case 'top'    %fit to top of cloud
  sn    = 1;
case 'bottom'
  sn    = -1;
case 'middle'
  sn    = -1;
otherwise
  error('OPTIONS.TRBFLAG not recognized.')
end

iiold   = m+1;
ii      = find(options.initwt);
while iiold>length(ii)  %Iterate until convergence satisfied
  yf    = median(y(ii));
	switch lower(options.trbflag)
	case {'top', 'bottom'}
    residual = sn*(y(ii) - yf);
	case 'middle'
    residual = sn*abs(y(ii) - yf);
  end
  tsq   = residual/sqrt(mean((y(ii)-yf).^2));
  iiold = length(ii);
  if ~isempty(find(tsq>=-tsqst))
    ii  = ii(tsq>=-tsqst);
  end
end
options.initwt = zeros(m,1);
options.initwt(ii) = 1;
residual  = y-yf;
