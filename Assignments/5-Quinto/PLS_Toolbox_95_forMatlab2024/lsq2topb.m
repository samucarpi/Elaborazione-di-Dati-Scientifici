function [yi,resnorm,residual,options] = lsq2topb(x,y,order,res,options)
%LSQ2TOPB Fits a polynomial to the top/(bottom) of data.
%  INPUTS:
%        x  = independent variable Mx1 vector.
%        y  = dependent variable, Mx1 vector.
%    order  = order of polynomial [scalar] for polynomial function of
%             input (x). If (order) is empty, (options.p) must contain
%             a MxK matrix of basis vectors to fit in lieu of
%             polynomials of (x).
%      res  = approximate fit residual [scalar].
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%            p: [], If (options.p) is empty, input (order) must be >0.
%               Otherwise, options.p is a MxK matrix of basis vectors.
%       smooth: [], if >0 this adds smoothing by adding a penalty to the
%               magnitude of the 2nd derivative. (empty or <=0 means no smooth)
%      display: [ 'off' | {'on'} ]      governs level of display to command window.
%      trbflag: [ {'top'} | 'bottom' | 'middle']  flag that tells algorithm to fit
%               (yi) to the top, bottom, or middle of the data cloud.
%       tsqlim: [ 0.99 ] limit that govers whether a data point is
%               outside the fit residual defined by input (res).
%     stopcrit: [1e-4 1e-4 1000 360]    stopping criteria, iteration is continued
%               until one of the stopping criterion is met
%               [(rel tol) (abs tol) (max # iterations) (max time [seconds])].
%       initwt: []; empty or Mx1 vector of initial weights (0<=w<=1).
%
%  OUTPUTS:
%       yi  = the fit to input (y).
%  resnorm  = squared 2-norm of the residual.
%  residual = y - yi.
%   options = input (options) echoed back, the field initwt may have been modified.
%
%  For order=1 and fitting to top of data cloud, LSQ2TOPB finds (yi)
%  that minimizes   sum( (W*( y - yi )).^2 ) where W is a diagonal
%  weighting matrix given by
%   tsq      = residual/res;                    % (res) is an input
%   tsqst    = ttestp(1-options.tsqlim,5000,2); % T-test limit from table
%   ii       = find(tsq<-tsqst);                % finds residuals below the line
%   w(ii)    = 1./(0.5 + tsq(ii)/tsqst);        % de-weights pts significantly below line
%  i.e. w(ii) is smaller for residuals far below/(above) the fit line.
%
%I/O: [yi,resnorm,residual,options] = lsq2topb(x,y,order,res,options);
%
%See also: BASELINE, BASELINEW, FASTNNLS

%Copyright Eigenvector Research, Inc., 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 5/03, 4/04 modified options, changed I/O
%nbg 6/04, scaled the x-block to stabilize the inverse
%nbg 7/04, added 'middle', added x MxN
%nbg 8/11/04 added options as an output
%nbg 8/10/05 added two lines, set wts tsq<-2.5*tsqtabel == 0
%nbg 10/31/05 modified LSQ2TOP to allow options.p and order = []
%nbg 11/1/05 added smoothing

if nargin == 0; x  = 'io'; end
varargin{1}        = x;
if ischar(x);
  options          = [];
  options.name     = 'options';
  options.display  = 'on';
  options.p        = [];
  options.smooth   = [];
  options.trbflag  = 'top';
  options.tsqlim   = 0.99;
  options.stopcrit = [1e-4 1e-4 1000 360];
  options.initwt   = [];

  if nargout==0; 
    evriio(mfilename,varargin{1},options);
  else
    yi    = evriio(mfilename,varargin{1},options); 
  end
  return; 
end
warning off backtrace

if nargin<5               %set default options
  options = [];
end
options = reconopts(options,mfilename);
if nargin<4
  res     = 0;
elseif isempty(res)
  res     = 0;
end
if nargin<3
  order   = [];            %default order
end
if nargin<2 | isempty(x)
  x       = [];
  order   = [];
else
  if prod(size(y))>length(y) | prod(size(y))==1
    error('Input (y) must be a vector.')
  end
  if prod(size(x))>length(x) | prod(size(x))==1
    error('Input (x) must be a vector.')
  end
  if length(y)~=length(x)
    error('Input (x) and (y) must have the same number of elements.')
  end
end
m         = length(y);
x         = x(:);
y         = y(:);
if isempty(order)
  x       = [];
  if isempty(options.p)
    error('Both (order) and (options.p) can not both be empty.')
  end
else
  forde   = [];
  if prod(size(order))>1
    error('Input (order) must be a scalar with values >= 0.')
  elseif order<0
    error('Input (order) must be a scalar with values >= 0.')
  elseif order-floor(order)~=0
    forde = order;
    order = floor(order);
  end
  x       = mncn(x);
  if isempty(forde)
    orderm  = [order:-1:0];
    x       = x(:,ones(1,order+1)).^orderm(ones(m,1),:);
  else
    orderm  = [forde order:-1:0];
    x       = x(:,ones(1,order+2)).^orderm(ones(m,1),:); 
  end
  x       = normaliz(x')';
end
if ~isempty(options.p)
  x       = normaliz(options.p')';
end
if ~isempty(options.smooth)
  if options.smooth<=0
    options.smooth = [];
  end
end
[m,n]     = size(x);

options.stopcrit = options.stopcrit(:)';
options.stopcrit(3:4) = -options.stopcrit(3:4);
%[(relative tolerance) (absolute tolerance) (maximum number of iterations) (maximum time in seconds)],

%Initialize the LSQ problem
if isempty(options.initwt)
  w       = ones(m,1);
  options.initwt = ones(m,1);
else
  if length(options.initwt)~=m
    error('Options.initwt must be a vector with the same number of elements as rows of (x).')
  end
  w       = options.initwt(:);
end

y       = y(:);
xi      = w(:,ones(1,n)).*x;
yi      = w.*y;
if isempty(options.smooth)
  b     = xi\yi;
else
  d     = options.smooth*ones(m,1);
  d     = spdiags([d -2*d d],-1:1,m,m);
  d     = speye(m)+d'*d;
  b     = inv(xi'*d*xi)*xi'*d*yi;
end
if res==0
  res   = 0.05*rmse(y-x*b);
end
tsqst   = ttestp(1-options.tsqlim,5000,2);
switch lower(options.trbflag)
case 'top' %fit to top of cloud
  sn    = 1;
case 'bottom'
  sn    = -1;
case 'middle'
  sn    = -1;
otherwise
  error('OPTIONS.TRBFLAG not recognized.')
end
options.initwt = options.initwt(:);
switch lower(options.trbflag)
case {'top', 'bottom'}
  residual = sn*(y - x*b);
case 'middle'
  residual = sn*abs(y - x*b);
end

%Iterate until convergence satisfied
bold     = b;
t0       = clock;
err      = [inf inf -1 0]; %relative error, absolute error, number of its, iteration time
while all(err>options.stopcrit)
	switch lower(options.trbflag)
	case {'top', 'bottom'}
    residual = sn*(y - x*b);
	case 'middle'
    residual = sn*abs(y - x*b);
	end
  tsq      = residual/res;
  ii       = find(tsq<-tsqst);
  w(ii)    = min([1./(0.5 + tsq(ii)/tsqst), options.initwt(ii)],[],2);
  w(ii)    = max([w(ii) zeros(length(ii),1)],[],2);
  ii       = find(tsq<-2.5*tsqst); %nbg 8/05
  w(ii)    = 0;                    %nbg 8/05
  xi       = w(:,ones(1,n)).*x;
  yi       = w.*y;
  if isempty(options.smooth)
    b      = xi\yi;
  else
    b      = inv(xi'*d*xi)*xi'*d*yi;
  end

  err(1)   = sum( ((b-bold)./(bold+1e-10)).^2 );
  err(2)   = sum((b-bold).^2);
  err(3)   = err(3)-1;
  err(4)   = etime(clock,t0);
  bold     = b;
end
yi       = x*b;

if nargout>1
  resnorm = norm(residual);
  options.stopcrit(3:4) = -options.stopcrit(3:4);
  options.initwt        = w;
end
