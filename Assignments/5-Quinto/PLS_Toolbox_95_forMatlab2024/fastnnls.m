function [b,xi] = fastnnls(x,y,tol,b,eqconst,xi,nnconst)
%FASTNNLS Fast non-negative least squares.
%  FASTNNLS finds b that minimizes X*b-y in a constrained least squares
%  sense. It is similar to b = X\y except that b cannot contain negative
%  values.
%  INPUTS:
%    x : the matrix of predictor variables
%    y : vector or matrix of predicted variables. If (y) is a matrix, the
%        result is the solution for each column calculated independently. 
%  OPTIONAL INPUTS: 
%       tol : tolerance on the size of a regression coefficient that is
%             considered zero. Not supplied or empty matrix is implies the
%             default value (based on x and eps)
%       b0  : initial guess for the regression vectors. Default or empty
%             matrix is interpreted as no known intial guess.
%   eqconst : equality constraints matrix equal in size to b0 and
%             containing a value of NaN to indicate an value not
%             equality-constrained or any finite value to indicate an
%             equality-constrained value. An empty matrix indicates no
%             equality constraints on any elements.
%        xi : cached inverses output by a previous run of fastnnls (see
%             outputs) or 0 (zero) to disable caching. An empty matrix is
%             valid as a placeholder in the inputs.
%  OUTPUTS: 
%     b : the non-negatively constrained least squares solution 
%    xi : the cache of x inverses (unless caching was disabled)
%  
%  FASTNNLS is fastest when a good estimate of the regression vector is
%  input. This eliminates much of the computation involved in determining
%  which coefficients will be nonzero in the final regression vector. This
%  makes it very useful in alternating least squares routines. Note that
%  the input b0 must be a feasible (i.e. nonnegative) solution, unless
%  eqconst is set appropriately. If (y) is a matrix, cacheing of the inverse
%  of (x) is used  to improve speed. As a result, the NNLS solution for
%  many  columns of y will be the fastest when all columns are passed  to
%  FASTNNLS at once or when the x inverse cache (xi) is passed back to
%  FASTNNLS on each call in which X is the same.
%
%  The FASTNNLS algorithm is based on the one developed by
%  Bro and de Jong, J. Chemometrics, Vol. 11, No. 5, 393-401, 1997
%
%I/O: [b,xi] = fastnnls(x,y,tol,b0,eqconst,xi);
%I/O: fastnnls demo
%
%See also: FASTERNNLS, FASTNNLS_SEL, LSQ2TOP, LSQ2TOPB, MCR, MED2TOP, PARAFAC

%TODO: future enhancement allow nnconst flag (turn of nn on some comps)
%I/O: [b,xi] = fastnnls(x,y,tol,b0,eqconst,xi,nnconst);

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%BMW, April 1998
%JMS, March/April 2003 
%   -revised code for speed
%   -added loop to handle y matricies (not just vectors)
%   -added inverse caching to improve speed
%   -added logic to handle divide-by-zero problems in some solutions
%   -added undocumented "fixed" matrix - still in development
%JMS 4/21/03
%   -removed 'fixed', added back access to xi
%JMS 7/24/03
%   -moved caching to external function to allow use in matlab 6.1
%JMS 8/6/03 - added limit for caching only up to 10 factors/components 
%JMS 4/14/04 - added hard equality constraints
%JMS 7/9/04 - test for near infinte loops and give warning (seems to happen
%     when the scale of rows of x are very different - using a norm on x
%     prior to analysis seems to solve the problem)
%JMS 5/10/05 - added comments

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; b = evriio(mfilename,varargin{1},options); end
  return; 
end

[m,n] = size(x);
if (nargin < 3 || isempty(tol) || tol == 0 )
  tol = max(size(x))*norm(x,1)*eps;
end
if nargin < 4 || isempty(b);
  b = ones(n,size(y,2));
end
if size(b,2)==1 & size(y,2)>1;  %is b a column vector but y a matrix?
  b(:,2:size(y,2)) = b(:,1);    %copy to every column to match y.
end

if nargin<5 || isempty(eqconst);
  eqconst = zeros(size(b))*nan;  %default is no constraints
end
if size(eqconst,2)==1 & size(b,2)>1;  %is eqconst a column vector but b a matrix?
  eqconst(:,2:size(b,2)) = eqconst(:,1);    %copy to every column to match b.
end
if size(eqconst,1)==1 & size(b,1)>1;  %is eqconst a row vector but b a matrix?
  eqconst(2:size(b,1),:) = eqconst(1,:);    %copy to every row to match b.
end

if nargin<6;  
  xi = [];
  nnconst = [];
else
  if isstruct(xi);
    nnconst = [];
  else
    nnconst = xi;
    xi = [];
  end
end
if isempty(xi); %initialize inverse cache
  xi = struct('Cache',[]);
end
if isempty(nnconst)
  nnconst = ones(size(b));
  %NOTE!!! nnconst is NOT currently used in this version. It will be
  %ignored currently...
end

%choose version of projection to use
if ~isstruct(xi) | checkmlversion('<','6.5') | n>10;
  fn = @proj_old;  %use plain (standard) projection
else
  fn = @fastnnls_proj;  %use caching projection
end
% fn = @proj_robust;

%loop across y columns
y_all = y;
b_all = b;
const_all = eqconst;
for col = 1:size(y,2);
  
  y = y_all(:,col);
  b = b_all(:,col);
  
  eqconst = const_all(:,col);
  noneqconstmap = isnan(eqconst);   %map where 1=non-equality constrained factor
  noneqconstind = find(noneqconstmap);  %lookup table of non-equality constrained factors
  if any(~noneqconstmap);
    %pre-subtract the equality constrained factors from the data (these can't be
    %changed anyway so we might as well work from the residual)
    y = y - x(:,~noneqconstmap)*eqconst(~noneqconstmap);
    b(~noneqconstmap) = 0;  %set their weight to be zero
  end
  
  p    = (noneqconstmap & b>0)';    %variables which are NOT held at zero
  %           anything unconstrained and with a positive reg coef
  r    = ~p;                    %variables which ARE held at zero
  %           constrained factor, or zero or negative reg coef
  b(r) = 0;
  
  [sp,xi] = feval(fn,x,xi,p,y);   %do one projection
  %exert positive control over any negative regression values
  b(p) = sp;   %select reg coef for those factors which were not controlled
  while min(sp) < 0
    %initial pass to exhert control over any reg coef with a negative value
    b(b<0) = 0;  %assign a zero
    p = (noneqconstmap & b>0)';    %redetermine controlled and uncontrolled vars
    r = ~p;
    [sp,xi] = feval(fn,x,xi,p,y);
    b(p) = sp;
  end
  
  w = x'*(y-x*b);   %correlation beteween x and residuals
  [wmax,ind] = max(w(noneqconstmap));
  ind = noneqconstind(ind);  %locate actual index in unconstrained index list
  flag = 0;
  inloop = 0;
  while (wmax > tol & any(r(noneqconstmap)))
    p(ind) = 1;     %allow that given index to be free
    r(ind) = 0;
    [sp,xi] = feval(fn,x,xi,p,y);
    while (min(sp) < 0) & any(p)   %while any are negative and uncontrolled
      tsp    = zeros(n,1);
      tsp(p) = sp;  
      fb     = (b~=0);
      nrm    = (b(fb)-tsp(fb));
      nrm(nrm<0) = inf;
      rat    = b(fb)./nrm;
      alpha  = min(rat(rat>0));
      alpha  = min([alpha 1]);      %limit to 1
      b = b + alpha*(tsp-b);
      p = (b > tol)';
      r = ~p;
      b(r) = 0;
      [sp,xi] = feval(fn,x,xi,p,y);
    end
    b(p) = sp;
    w = x'*(y-x*b);   %correlation beteween x and residuals
    [wmax,ind] = max(w(noneqconstmap));
    ind = noneqconstind(ind);  %locate actual index in unconstrained index list
    inloop = inloop+1;
    if inloop>100;
      warning('EVRI:FastnnlsDegenerate','Degenerate Non-Negative Least Squares solution (poorly defined scale?) Skipping');
      break
    end
    if p(ind)    %already free or stuck in iterations? just leave
      wmax = 0;
    end
  end
  
  %replace constrained items with constrained values
  if any(~noneqconstmap);
    b(~noneqconstmap) = eqconst(~noneqconstmap);
  end
  
  b_all(:,col) = b;  %store this column's result

  %every n'th point, do a drawnow to allow control-c
  switch mod(col,200)
    case 0
      drawnow;
  end
  
end

b = b_all;

%----------------------------
function [sp,xi] = proj_old(x,xi,p,y);
%plain version of the function for use with Matlab6.1 or when caching is turned off

sp = x(:,p)\y;


%----------------------------
function [sp,xi] = proj_robust(x,xi,p,y);
%plain version of the function for use with Matlab6.1 or when caching is turned off

% sp = x(:,p)\y;
if any(p)
  result = ltsregres(x(:,p),y,'plots',0,'intercept',0);
  sp = result.slope;
else
  sp = [];
end


