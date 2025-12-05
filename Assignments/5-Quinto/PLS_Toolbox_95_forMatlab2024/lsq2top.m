function [b,resnorm,residual,options] = lsq2top(x,y,order,res,options)
%LSQ2TOP Fits a polynomial to the top/(bottom) of data.
%  INPUTS:
%        x  = independent variable Mx1 vector.
%             Either (x) or (order) are input, but not both.
%             If (x) is an MxK matrix, the columns are used w/o modification
%             i.e. (order) is not used and the fit is only to the columns of
%             the input (x). This allows vectors other than P(x) to be
%             included fit.
%             If (x) is empty, then (order) cannot be empty and P(1:M) is
%             used for fitting.
%        y  = dependent variable, Mx1 vector.
%    order  = order of polynomial [scalar] for polynomial function P(x).
%      res  = approximate fit residual [scalar].
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%          display: [ 'off' | {'on'} ]      governs level of display to command window.
%          trbflag: [ {'top'} | 'bottom' | 'middle']  flag that tells algorithm to fit
%                    P(x) to the top, bottom, or middle of the data cloud. When 'middle'
%                    is used, LSQ2TOP can be considered a robust least squares method.
%           tsqlim: [ 0.99 ]                limit that govers whether a data point is
%                    outside the fit residual defined by input (res).
%         stopcrit: [1e-4 1e-4 1000 360]    stopping criteria, iteration is continued
%                    until one of the stopping criterion is met
%                    [(rel tol) (abs tol) (max # iterations) (max time [seconds])].
%           initwt: []; empty or Mx1 vector of initial weights (0<=w<=1).
%
%  OUTPUTS:
%        b  = regression coefficients [highest order term corresponds to b(1) and the
%              intercept corresponds to b(end)],
%  resnorm  = squared 2-norm of the residual, and
%  residual = y - P(x).
%   options = input (options) echoed back
%           initwt: Mx1 weights that may have been modified.
%               px: P(x)
%                   if (x) is empty and order not empty this is P(x), or
%                   if (x) is not empty and order is emtpy then this is x.
%
%EXAMPLES:
%  [b,resnorm,residual,options] = lsq2top([],y,1,0.01);
%    and fitting to top of data cloud, LSQ2TOP finds the vector (b)
%   that minimizes   sum(W*( y - mncn([1:M]')*b(1) - b(2) )).^2)
%   where W is a diagonal weighting matrix given by
%     tsq      = residual/res;                    % (res) is an input
%     tsqst    = ttestp(1-options.tsqlim,5000,2); % T-test limit from table
%     ii       = find(tsq<-tsqst);                % finds residuals below the line
%     w(ii)    = 1./(0.5 + tsq(ii)/tsqst);        % de-weights pts significantly below line
%   i.e. w(ii) is smaller for residuals far below/(above) the fit line.
%  The fit line is:
%    yfit = options.px*b;
%
%  The same fit is given by:
%  m = length(y);
%  x = normaliz([mncn([1:m]'),ones(m,1)]')';
%  b = lsq2top(x,y,1,0.01);
%  yfit = x*b;
%
%I/O: [b,resnorm,residual,options] = lsq2top(x,y,order,res,options);
%
%See also: BASELINE, BASELINEW, FASTNNLS, FASTNNLS_SEL, MED2TOP

%Copyright Eigenvector Research, Inc., 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg 5/03, 4/04 modified options, changed I/O
%nbg 6/04, scaled the x-block to stabilize the inverse
%nbg 7/04, added 'middle', added x MxN
%nbg 8/11/04 added options as an output
%nbg 8/10/05 added two lines, set wts tsq<-2.5*tsqtabel == 0
%nbg 9/08 commented out "if ~isempty(order)" (this was fixed previously!)

if nargin == 0; x  = 'io'; end
varargin{1}        = x;
if ischar(x);
  options          = [];
  options.name     = 'options';
  options.display  = 'on';
  options.trbflag  = 'top';
  options.tsqlim   = 0.99;
  options.stopcrit = [1e-4 1e-4 1000 360];
  options.initwt   = [];

  if nargout==0; 
    evriio(mfilename,varargin{1},options); 
  else
    b     = evriio(mfilename,varargin{1},options); 
  end
  return; 
end
warning off backtrace

if nargin<5               %set default options
  options = lsq2top('options');
else
  options = reconopts(options,lsq2top('options'));
end
if nargin<4
  res     = 0;
elseif isempty(res)
  res     = 0;
end
if nargin<2
  error('LSQ2TOP requires at least 2 inputs.')
end
if prod(size(y))>length(y) | prod(size(y))==1
  error('Input (y) must be a vector.')
end
if nargin<3
  order = [];
end
if ~isempty(x)
  if length(y)~=size(x,1)
    error('Input (x) and (y) must have the same number of rows.')
  end
%   if ~isempty(order) %commented out nbg 9/08
%     order = [];
%   end
end
m         = length(y);
if isempty(order)&isempty(x) %10/30/05
  error('Inputs (x) and (order) can not both be empty.')
end
if isempty(order)
  options.px = x;
else
  if prod(size(order))>1
    error('Input (order) must be a scalar with values >= 0.')
  elseif order<0
    error('Input (order) must be a scalar with values >= 0.')
  elseif order-floor(order)~=0
    order = floor(order);
  end

  options.px = mncn([1:m]')/m;
  order      = order:-1:0;
  nod        = length(order);
  options.px = options.px(:,ones(1,nod)).^order(ones(m,1),:); 
  options.px = normaliz(options.px')';
end
[m,n]     = size(options.px);

options.stopcrit = options.stopcrit(:)';
options.stopcrit(3:4) = -options.stopcrit(3:4);
%[(relative tolerance) (absolute tolerance) (maximum number of iterations) (maximum time in seconds)],

%Initialize the LSQ problem
if isempty(options.initwt)
  w     = ones(m,1);
  options.initwt = ones(m,1);
else
  if length(options.initwt)~=m
    error('Options.initwt must be a vector with the same number of elements as rows of (x).')
  end
  w     = options.initwt(:);
end

nod     = size(options.px,2);  %number of basis vectors
y       = y(:);
xi      = w(:,ones(1,nod)).*options.px;
yi      = w.*y;
b       = xi\yi;
if res==0
  res   = 0.05*rmse(y-options.px*b);
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
% options.initwt = options.initwt(:);

%Iterate until convergence satisfied
bold     = b;
t0       = clock;
err      = [inf inf -1 0]; %relative error, absolute error, number of its, iteration time
while all(err>options.stopcrit)
	switch lower(options.trbflag)
	case {'top', 'bottom'}
    residual = sn*(y - options.px*b);
	case 'middle'
    residual = sn*abs(y - options.px*b);
  end
  w0     = w;
  tsq    = residual/res;
  ii     = find(tsq<-tsqst);
  w(ii)  = min([1./(0.5 + tsq(ii)/tsqst), options.initwt(ii)],[],2);
  w(ii)  = max([w(ii) zeros(length(ii),1)],[],2);
  ii     = find(tsq<-2.5*tsqst); %nbg 8/05
  w(ii)  = 0;                    %nbg 8/05
  if length(find(w))<nod         %avoid rank deficiency
    [w0,ii] = sort(w0,'descend'); 
    w(ii(1:nod)) = w0(1:nod);    %disp(w)
    err(3)  = options.stopcrit(3);
  else
    err(3)   = err(3)-1;
  end
  
  xi     = w(:,ones(1,nod)).*options.px;
  yi     = w.*y;
  b      = xi\yi;

  err(1) = sum( ((b-bold)./bold).^2 );
  err(2) = sum((b-bold).^2);
  err(4) = etime(clock,t0);
  bold   = b;
end

if nargout>1
  resnorm = norm(residual);
  options.stopcrit(3:4) = -options.stopcrit(3:4);
  options.initwt        = w;
end
