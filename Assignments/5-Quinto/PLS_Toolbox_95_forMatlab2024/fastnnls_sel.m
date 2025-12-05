function [b,xi] = fastnnls_sel(x,y,tol,b,eqconst,xi,nnconst,nclose)
%FASTNNLS_SEL Fast non-negative least squares with selective constraints.
%  FASTNNLS finds (b) that minimizes X*b-y in a constrained least squares
%  sense. It is similar to b = X/y except that selected elements of (b)
%  cannot contain negative values.
%  NOTE: This version is nearly identical to the standard fastnnls function
%  except that it allows row-wise, or element-wise, control over
%  non-negative and equality constraints.
%
%  INPUTS:
%         x: MxK matrix of predictor variables.
%         y: MxN vector or matrix of predicted variables. If (y) is a
%            matrix, the result is the solution for each column of (y)
%            calculated independently.
%
%  OPTIONAL INPUTS: 
%       tol: tolerance on the size of a regression coefficient that is
%            considered zero. Not supplied or empty [ ] implies the
%            default value [based on (x) and )eps)].
%        b0: KxN initial guess for the regression vector(s). Default or
%            empty [ ] is interpreted as no known intial guess.
%   eqconst: KxN equality constraints matrix. A value of NaN indicates
%            no equality contraint for that element. Elements with finite
%            values indicates an equality-constraint.
%            If (eqconst) is empty [ ] then no equality constraints are
%            imposed.
%        xi: Cached inverses output by a previous run of FASTNNLS or
%            FASTNNLS_SEL (see outputs). If (xi) is set to 0 (zero)
%            caching is diabled. If (xi) is empty [ ] it serves as a
%            placeholder in the input argument list.
%   nnconst: KxN matrix or Kx1 vector used to indicate which elements
%            of (b) are to be non-negatively constrained. If (nnconst)
%            is Kx1 the function expands it to ==> repmat(nncont,1,N).
%            Elements in (nnconst) with a value of 1 are non-negatively 
%            constrained. A value of 0 indicates a non-constrained value 
%            (i.e., negative values are allowed).
%            If not supplied or empty [ ], the default is that all values
%            are non-negatively constrained.
%            If KxN (equal in size to b0), (nnconst) provides an element-
%            by-element control of the non-negativity of (b). If Kx1 then
%            (nnconst) provides control of the non-negativity of rows of (b).    
%
%   NOTE: (nnconst) can be passed in place of (xi). Otherwise, all intermediate
%         optional inputs must be passed, even if empty [ ].
%
%  OUTPUTS: 
%         b: KxN non-negatively constrained least squares solution.
%        xi: cached inverses of x'x (unless caching was disabled).
%
%  See FASTNNLS for additional information.
%
%I/O: [b,xi] = fastnnls_sel(x,y,tol,b0,eqconst,xi,nnconst);
%I/O: [b,xi] = fastnnls_sel(x,y,tol,b0,eqconst,nnconst);
%
%See also: FASTERNNLS, FASTNNLS, LSQ2TOP, MCR, PARAFAC

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

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
  b = x\y;                            %ones(n,size(y,2));
end
if size(b,2)==1 & size(y,2)>1;        %is b a column vector but y a matrix?
  b(:,2:size(y,2)) = b(:,1);          %copy to every column to match y.
end

if nargin<5 || isempty(eqconst);
  eqconst = zeros(size(b))*nan;       %default is no constraints
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
elseif nargin==6  %change here 2/23/08
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
else
  if size(nnconst,1)==1 && size(nnconst,2)==size(b,1)
    %if it appears to be a row vector indicating factor-by-factor controls,
    %flip it.
    nnconst = nnconst';
  end
end
nnconst = logical(nnconst);

%choose version of projection to use
if ~isstruct(xi) | checkmlversion('<','6.5') | n>10;
  fn = @proj_old;  %use plain (standard) projection
else
  fn = @fastnnls_proj;  %use caching projection
end
% fn = @proj_robust;

%loop across y columns
y_all       = y;
b_all       = b;
const_all   = eqconst;
nnconst_all = nnconst;
for col=1:size(y,2);
  y = y_all(:,col);
  b = b_all(:,col);
  
  eqconst = const_all(:,col);
  noneqconstmap = isnan(eqconst);      %map where 1=non-equality constrained factor
  noneqconstind = find(noneqconstmap); %lookup table of non-equality constrained factors
  if any(~noneqconstmap);
    %pre-subtract the equality constrained factors from the data (these can't be
    %changed anyway so we might as well work from the residual)
    y = y - x(:,~noneqconstmap)*eqconst(~noneqconstmap);
    b(~noneqconstmap) = 0;  %set their weight to be zero
  end
  if size(nnconst_all,2)>1;
    nnconstmap = nnconst_all(:,col);   %map of non-neg controlled items
  else  %only one column? assume same for all columns
    nnconstmap = nnconst_all;
  end
  nnconstind = find(nnconstmap);     %indices of non-neg controlled items
  cancontrol = nnconstmap & noneqconstmap;  %map of items which can be controlled
  cancontrolind = find(cancontrol);  %indices of can control items
  
  p    = (noneqconstmap & (~nnconstmap | b>0))';    %variables which are NOT held at zero
  %           anything unconstrained and with a positive reg coef
  r    = ~p;                    %variables which ARE held at zero
  %           constrained factor, or zero or negative reg coef
  b(r) = 0;
  
  [sp,xi] = feval(fn,x,xi,p,y);   %do one projection
  %exert positive control over any negative regression values
  b(p) = sp;   %select reg coef for those factors which were not controlled
  while min(b(nnconstind)) < 0
    %initial pass to exhert control over any reg coef with a negative value
    b(nnconstind(b(nnconstind)<0)) = 0;  %assign a zero
    p(nnconstind) = b(nnconstind)>0;  %redetermine controlled and uncontrolled vars
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
    while (min(sp(nnconstmap(p))) < 0) & any(p)   %while any are negative and uncontrolled
      tsp    = zeros(n,1);
      tsp(p) = sp;  
      fb     = (b~=0);
      nrm    = (b(fb)-tsp(fb));
      nrm(nrm<0) = inf;
      rat    = b(fb)./nrm;
      alpha  = min(rat(rat>0));
      alpha  = min([alpha 1]);      %limit to 1
      b = b + alpha*(tsp-b);
      p = (~nnconstmap | b > tol)';
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
  switch mod(col,25)
    case 0
      drawnow;
  end
  
end

b = b_all;

%----------------------------
function [sp,xi] = proj_old(x,xi,p,y)
%plain version of the function for use with Matlab6.1 or when caching is turned off

sp = x(:,p)\y;

%----------------------------
function [sp,xi] = proj_robust(x,xi,p,y)
%plain version of the function for use with Matlab6.1 or when caching is turned off

% sp = x(:,p)\y;
if any(p)
  result = ltsregres(x(:,p),y,'plots',0,'intercept',0);
  sp = result.slope;
else
  sp = [];
end

function [sp,xi] = proj_closure(x,xi,p,y)
%closure for all p
%won't work w/ equality constraints though
o    = ones(length(p),1);
sp   = [x(:,p)'*x(:,p), o; o' 0]\[x'*y; 1];
sp   = sp(1:end-1);
% (need to modify for only selected closure components)
% o  = zeros(length(p),1);
% o(selcted) = 1;
%if equality constraint is on an element z included in closure
% then it must be 0<= z <=1 and
% the last term on rhs for sp is changed from 1 to 1-z

