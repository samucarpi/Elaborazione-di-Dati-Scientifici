function [b,xi] = fasternnls(x,y,tol,b,eqconst,xi,nnconst)
%FASTERNNLS Fast non-negative least squares with selective constraints.
%  FASTERNNLS finds (b) that minimizes X*b-y in a constrained least squares
%  sense. It is similar to b = X\y except that selected elements of (b)
%  cannot contain negative values.
%
%  NOTE: This function performs the same operation as fastnnls and
%  fastnnls_sel except it is optimized for matrix operations and is
%  significantly faster. It fully supports equality constraints and
%  row-wise, or element-wise, control over non-negative and equality
%  constraints (like fastnnls_sel)
%
%  INPUTS:
%         x: MxK matrix of predictor variables OR KxK matrix of x'x (see y)
%         y: MxN vector or matrix of predicted variables. If (y) is a
%            matrix, the result is the solution for each column of (y)
%            calculated independently. If x is passed as x'x (x'*x), y needs to be
%            passed as x'y (x'*y).
%
%            NOTE: x and y can be passed as either the standard matricies
%            described above OR as x'x and x'y, respectively.
%            EXCEPTION: if x is square, it MUST be passed as x'x (and y as
%            x'y).
%
%  OPTIONAL INPUTS: 
%       tol: tolerance on the size of a regression coefficient that is
%            considered zero. Not supplied or empty [ ] implies the
%            default value [based on (x) and (eps)].
%        b0: KxN initial guess for the regression vector(s). Default or
%            empty [ ] is interpreted as no known initial guess.
%   eqconst: KxN equality constraints matrix. A value of NaN indicates
%            no equality constraint for that element. Elements with finite
%            values indicates an equality-constraint.
%            If (eqconst) is empty [ ] then no equality constraints are
%            imposed.
%        xi: Cached inverses output by a previous run of FASTNNLS or
%            FASTNNLS_SEL (see outputs). If (xi) is set to 0 (zero)
%            caching is diabled. If (xi) is empty [ ] it serves as a
%            placeholder in the input argument list.
%   nnconst: KxN matrix or Kx1 vector used to indicate which elements
%            of (b) are to be non-negatively constrained. If (nnconst)
%            is Kx1 the function expands it to a matrix with N columns.
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
%I/O: [b,xi] = fasternnls(x,y,tol,b0,eqconst,xi,nnconst);
%I/O: [b,xi] = fasternnls(x,y,tol,b0,eqconst,nnconst);
%
%See also: ALS, FASTNNLS, FASTNNLS_SEL, MCR, PARAFAC

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%get sizes
k = size(x,2);
[m,n] = size(y);

%maximum number of factors we can using caching with (usually at most 24
%but usually lower. On a two-core system with 2GB, 10 was reasonable.)
maxcachedfactors = 10;  

%initialize special lookup variables used to quickly identify columns with
%similar negative-sign patterns
enc   = 2.^[0:k-1];          %matrix to encode -'s to binary  (decimal values of each position)
if k<=maxcachedfactors
  codes = char(dec2bin(1:(2^k)-1)+'a'-'0');    %string key to store inverses
  dec   = fliplr(codes=='a');   %array to block out -'s in inverses (- = 0 ; + = 1)
else
  %too many factors to use caching
  codes = [];
  dec = [];
end

%parse inputs
if (nargin < 3 || isempty(tol) || tol == 0 )
  tol = max(size(x))*norm(x,1)*eps;
end
tol = abs(tol);

if size(x,1)~=k
  %x isn't square? we don't have x'x right now - do it to make everything
  %faster
  y = x'*y;
  x = x'*x;
  [m,n] = size(y);
end

%handle equality constraints
if nargin<5 || isempty(eqconst);
  eqconst = zeros(k,n)*nan;  %default is no constraints
end
if size(eqconst,2)==1 & n>1;  %is eqconst a column vector but b a matrix?
  eqconst(:,2:n) = eqconst(:,1);    %copy to every column to match y columns.
end
if size(eqconst,1)==1 & k>1;  %is eqconst a row vector but x a matrix?
  eqconst(2:k,:) = eqconst(1,:);    %copy to every row to match x columns.
end
iseqconst = ~isnan(eqconst);  %map of elements which have ANY equality constraints
if any(iseqconst(:))
  %pre-subtract the equality constrained factors from the data (these can't be
  %changed anyway so we might as well work from the residual)
  eqc = eqconst;
  eqc(isnan(eqc)) = 0;  %zero-out NaN's
  if any(eqc(:)~=0)
    if size(eqc,1)~=k
      error('Equality constraints must have as many rows as x has columns')
    end
    if size(eqc,2)~=n
      error('Equality constraints must have as many columns as y has columns')
    end
    y = y - x*eqc;        %subtract out any equality constraints now so they have no effect on other fit
  end
end

%initialize xi (and allow for swap of xi and nnconst)
if nargin<6;
  xi = [];
  nnconst = [];
elseif nargin==6 
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

%handle non-negativity control mask
if isempty(nnconst)
  nnconst = ones([k n]);
elseif any(size(nnconst)==1) & any(size(nnconst)==k)
  %if k-element vector (factor-by-factor control of nonneg)
  nnconst = nnconst(:);
  nnconst = repmat(nnconst,1,n);  %expand to match b
elseif any(size(nnconst)==1) & any(size(nnconst)==n)
  %if n-element vector (factor-by-factor control of nonneg)
  nnconst = nnconst(:)';
  nnconst = repmat(nnconst,k,1);  %expand to match b
elseif any(size(nnconst)~=[k n])
  error('Non-negativity map (nnconst) must be the same size as b or a vector equal in length to one row of x');
end

%choose version of projection to use
if k>maxcachedfactors  %too many factors to use caching - use memory-friendly encoding
  leastsquares = @proj_nocache_nodec;
elseif ~isstruct(xi) | checkmlversion('<','6.5')
  leastsquares = @proj_nocache;  %use plain (standard) projection
else
  leastsquares = @proj_cache;  %use caching projection
end

%choose which inverse type to use
if all(size(x)==k)
  %assume x'*x and x'*y and use the special inverse function needed for that  
  pinvfn = @xtxpinv;
  xtx = 1;
else
  %assume x and y are standard
  %NOTE: we will never reach this point because the beginning of the fn
  %now forces x to be x'x if it isn't already. However, we leave this here
  %in case we remove the code which forces us into x'x.
  pinvfn = @xpinv;
  xtx = 0;
end

%initialize b and control masks
if nargin<4 | isempty(b)
  %get first (unconstrained) solution
  b = zeros(k,n);
else
  %provided an input initial guess for b
  if size(b,2)==1 & n>1
    %if b is a vector but y a matrix
    b(:,2:n) = b(:,1);    %copy to every column to match y.
  end
end
%get true initial guess
negs       = (b<0 & nnconst) | iseqconst;      %note which are negative and shouldn't be OR zero-equality constrained
type       = enc*negs;   %get a unique numeric value corresponding to the type of negative pattern for each sample
[b,xi]     = feval(leastsquares,x,y,b,xi,type,codes,dec,true,pinvfn);   %solve for initial b (allowing for unconstrained projection)

negs       = (b<0 & nnconst) | iseqconst;      %note which are negative and shouldn't be OR zero-equality constrained
controlled = negs;                             %grand history of all controlled items
type       = enc*negs;   %get a unique numeric value corresponding to the type of negative pattern for each sample

%Check if there are items we need to exhert positive control over
it = 0;
while it<50 & any(type>0)
  it = it+1;
  
  [b,xi] = feval(leastsquares,x,y,b,xi,type,codes,dec,false,pinvfn);
  
  %locate NEW negative values
  oldnegs = negs;
  negs = (b<0 & nnconst);
  if sum(negs(:))==0
    %no new ones? exit now
    break
  end
  
  %if any are negative now, use those as well as holding the ones from last
  %time (for those samples)
  newnegmap         = any(negs);  %note samples with new negative values
  newnegs           = negs(:,newnegmap) | oldnegs(:,newnegmap) | iseqconst(:,newnegmap);   %keep new and old negs for those samples
  negs(:,newnegmap) = newnegs;    %insert combination with old values back into negs
  controlled(:,newnegmap) = newnegs;  %and record changes in grand "controlled" map
  type = enc*negs;                %recalculate negative pattern type
  
end

%Check about adding controlled items back in
window = min(n,inf);
locked = controlled&false;
for win = 1:window:n
  %for one window of y-columns...
  cols = win:min(n,win+window-1);
  
  it = 0;
  while it<50
    it = it+1;
    
    %identify correlation between X columns and residuals of current fit to
    %y columns
    cols_m = cols(sum(controlled(:,cols),1)>0);   %columns with multiple controlled items
    if isempty(cols_m)
      break;
    end
    switch xtx
      case 1
        w = (y(:,cols_m)-x*b(:,cols_m));    %project x onto residuals for these columns
      case 0
        w = x'*(y(:,cols_m)-x*b(:,cols_m));    %project x onto residuals for these columns
    end
    w(w<tol | locked(:,cols_m) | ~controlled(:,cols_m) | iseqconst(:,cols_m)) = 0;  %ignore items which aren't controlled, have equality constraints, or are below tolerance
    [wmax,wmax_where] = max(w);            %locate maximum of each column
    if max(wmax)==0
      break;  %done - no more above tolerance
    end
    tomodify = wmax>0;  %which of those columns have something we can try uncontrolling?
    controlled(wmax_where(tomodify)+(cols_m(tomodify)-1)*k) = false;  %turn OFF control on the selected items
    type = zeros(1,n);   %start with type = 0 (indicating that we do not need to do any regression)
    type(cols_m(tomodify)) = enc*controlled(:,cols_m(tomodify));   %get a unique numeric value corresponding to the type of negative pattern for each sample
    [b,xi] = feval(leastsquares,x,y,b,xi,type,codes,dec,false,pinvfn);     %recalculate b's for those items
    
    %make sure we didn't accidentally make one of those negative
    negs      = (b(:,cols_m)<0 & nnconst(:,cols_m));
    newnegmap = any(negs);  %note samples with new negative values
    if any(newnegmap)
      newnegs   = negs(:,newnegmap) | locked(:,cols_m(newnegmap)) | controlled(:,cols_m(newnegmap)) | iseqconst(:,cols_m(newnegmap));   %keep new and old negs for those samples
      controlled(:,cols_m(newnegmap)) = newnegs;  %and record changes in grand "controlled" map
      locked(:,cols_m(newnegmap)) = locked(:,cols_m(newnegmap)) | negs(:,newnegmap);  %note those items are now "locked"
      type     = zeros(1,n);   %start with type = 0 (indicating that we do not need to do any regression)
      type(cols_m(newnegmap)) = enc*controlled(:,cols_m(newnegmap));   %get a unique numeric value corresponding to the type of negative pattern for each sample
      [b,xi]   = feval(leastsquares,x,y,b,xi,type,codes,dec,false,pinvfn);     %recalculate b's for those items
    end

  end
  
end

b(iseqconst) = eqconst(iseqconst);     %force b to have equality constrained values

%--------------------------------------------------------------------
function  [b,xi] = proj_cache(x,y,b,xi,type,codes,dec,allow_unconstrained,pinvfn);
%do a controlled least squares for columns based on the type code of each.
%Note that type==0 means a completely uncontrolled item and NO regression
%is done for this (it is assumed to already be resolved)

for t=unique(type)
  %for each pattern (type) of negatives that we saw
  use = type==t;  %locate items matching this pattern
  switch t
    case 0
      if allow_unconstrained
        %actually DO the unconstrained case
        b(:,use) = pinv(x)*y(:,use);
      end
      continue
  end
  try
    xi_ind = xi.(codes(t,:));   %look for existing inverse for this pattern
  catch
    %not there? create it
    xi_ind = feval(pinvfn,x,dec(t,:));
    xi.(codes(t,:)) = xi_ind;           %store it for later
  end
  b(:,use) = xi_ind*y(:,use);      %apply inverse to samples showed this negatives pattern
end


%----------------------------
function [b,xi] = proj_nocache(x,y,b,xi,type,codes,dec,allow_unconstrained,pinvfn)
%plain version of the function for use with Matlab6.1 or when caching is turned off

for t=unique(type)
  %for each pattern (type) of negatives that we saw
  use = type==t;  %locate items matching this pattern
  switch t
    case 0
      if allow_unconstrained
        %actually DO the unconstrained case
        b(:,use) = pinv(x)*y(:,use);
      end
      continue
  end

  xi_ind = feval(pinvfn,x,dec(t,:));
  b(:,use) = xi_ind*y(:,use);          %apply inverse to samples showed this negatives pattern
  
end

%----------------------------
function [b,xi] = proj_nocache_nodec(x,y,b,xi,type,codes,dec,allow_unconstrained,pinvfn)
%plain version of the function for use with Matlab6.1 or when caching is turned off

for t=unique(type)
  %for each pattern (type) of negatives that we saw
  use = type==t;  %locate items matching this pattern
  switch t
    case 0
      if allow_unconstrained
        %actually DO the unconstrained case
        b(:,use) = pinv(x)*y(:,use);
      end
      continue
  end

  %if we have lots of factors, we can't pre-calculate the binary mask
  %(because it takes too much memory) so we do it here in the more
  %time-consuming but less-memory-intensive method
  dec = fliplr(dec2bin(t));  %get binary representation of mask
  dec(2,size(x,2))=0;  %expand to include enough elements (by adding 2nd row)
  dec = (dec~='1');   %look for locations of "1"s
  dec = dec(1,:);  %and drop second row - keeping first
  
  xi_ind = feval(pinvfn,x,dec);
  b(:,use) = xi_ind*y(:,use);          %apply inverse to samples showed this negatives pattern
  
end



%----------------------------
function xi_ind = xpinv(x,use)
%standard inverse needed when x is just x

zeroing = diag(use);           %diagonal to zero out controled items
xi_ind  = zeroing*pinv(x*zeroing);  %calculate inverse with hard-zeroed components

%----------------------------
function xi_ind = xtxpinv(x,use)
%special inverse needed when x is actually x'x

zeroing = diag(use);           %diagonal to zero out controled items
xi_ind  = zeroing*pinv(zeroing*x*zeroing);  %calculate inverse with hard-zeroed components

