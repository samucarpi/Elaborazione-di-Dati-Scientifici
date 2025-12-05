function [yi,D] = polyinterp(x,y,xi,width,order,deriv)
%POLYINTERP Polynomial interpolation, smoothing, and differentiation.
%  POLYINTERP estimates (yi) which is the smoothed values of (y)
%  at the points in the vector (x). (If the points are evenly
%  spaced use the SAVGOL function instead.)
%  INPUTS:
%      y = (M by N) matrix. Note that (y) is a matrix of ROW
%          vectors to be smoothed.
%      x = (1 by N) corresponding axis vector at the points at
%          which (y) is given.
%
%  OPTIONAL INPUTS:
%     xi = a vector of points to interpolate to.
%  width = specifies the number of points in the filter {default = 15}.
%  order = the order of the polynomial {default = 2}.
%  deriv = the derivative {default = 0}.
%
% Outputs are the matrix of smoothed and differentiated ROW
%  vectors (yi) and the matrix of coefficients (D) which can
%  be used to create a new smoothed/differentiated matrix,
%  i.e. y_hat = y*D. For this usage y should not contain any NaN values.
%
%Example: if y is a 5 by 100 matrix, x is a 1 by 100 vector,
%  and xi is a 1 by 91 vector then polyinterp(x,y,xi,11,3,1)
%  gives the 5 by 91 matrix of first-derivative row vectors
%  resulting from an 11-point cubic interpolation to the 91
%  points in xi.
%
%I/O: [yi, D] = polyinterp(x,y,xi,width,order,deriv);
%I/O: polyinterp demo
%
%See also: BASELINE, LAMSEL, MSCORR, SAVGOL, STDFIR 

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%nbg 5/21/01 added tol
%nbg 8/02 fixed indexing bug for multiple row y, and rhs indexing problem
%jms 10/02 added missing data support and dataset support
%jms 12/02 fixed warning message bug (wrong variable name)
%nbg 3/07 modified the help

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear yi; evriio(mfilename,varargin{1},options); else; yi = evriio(mfilename,varargin{1},options); end
  return; 
end
 
if isa(y,'dataset');
  wasdataset = 1;
  origy      = y;
  y          = y.data;
  y(:,setdiff(1:size(y,2),origy.includ{2})) = NaN;   %deal with excluded like missing data
else
  wasdataset = 0;
end

tol       = eps*100; %5/21/01
[m,n]     = size(y);
if ~isreal(y)
  error('y must be real.')
end
if length(x)~=n
  error('Length of x must = size(y,2).')
elseif (ndims(x)>2)|(prod(size(x))>length(x))
  error('x must be a vector.')
elseif ~isreal(x)
  error('x must be real.')
else
  x       = x(:);       %make x a column vector
end
if any(diff(x)<0)
  [x,w]   = sort(x);
  y       = y(:,w);
  if any(diff(x)==0)
    error('Values in x must be distinct.')
  end
end
if (ndims(xi)>2)|(prod(size(xi))>length(xi))
  error('xi must be a vector.')
elseif min(xi)<min(x)-tol
  error('min(xi)<min(x)-tol - extrapolation not allowed.')
elseif max(xi)>max(x)+tol
  error('max(xi)>max(x)+tol - extrapolation not allowed.')
elseif ~isreal(xi)
  error('xi must be real.')
elseif isempty(xi)
  xi      = x(:);
else
  xi      = xi(:);       %make xi a column vector
  ni      = length(xi);
  if any(diff(xi)<0)
    [xj,ij]  = sort(xi);
  else
    xj    = xi;
    ij    = 1:ni;
  end
end
yi        = zeros(m,ni);

if nargin<4     %default width
  width   = min(15,floor(n/2));
  disp(sprintf('Width set to %g',width))
elseif isempty(width)
  width   = min(15,floor(n/2));
  disp(sprintf('Width set to %g',width))
end
w         = max([3, 1+2*round((width-1)/2)]);
if w~=width
  width   = w;
  disp(sprintf('Width must be >= 3 and odd. Width changed to %g',w))
end
if nargin<5      %default order
  order   = 2; 
  disp('Polynomial order set to 2.')
elseif isempty(order)
  order   = 2; 
  disp('Polynomial order set to 2.')
end
w         = min([max(0,round(order)),w-1]);
if w~=order
  disp(sprintf('Order must be <= width -1. Order changed to %g',w))
  order   = w;
end
if nargin<6      %default derivative
  deriv= 0;
  disp('Derivative set to zero.')
elseif isempty(deriv)
  deriv= 0;
  disp('Derivative set to zero.')
end
if nargin<3
end
w         = min(max(0,round(deriv)),order);
if w~=deriv
  disp(sprintf('Deriviative must be <= order. Derivative changed to %g',w))
end

win2      = (width-1)/2;
powr      = ones(width,1)*[0:order];
[y_flag,y_missmap] = mdcheck(y);
nearest   = interp1(x,1:length(x),xj,'nearest');
D = zeros(n,n); % for difference matrix
for ii=1:ni
  ij = nearest(ii);
  if ij<=win2         %LHS
    ind    = 1:ij+win2;
    center = ii;
    x1     = ((x(1:ij+win2)-xj(ii))*ones(1,1+order)).^(ones(ij+win2,1)*[0:order]);
  elseif n-ij<win2    %RHS
    ind    = ij-win2:n;
    center = win2+1;
    %x1    = ((x(ij:n)-xj(ii))*ones(1,1+order)).^(ones(n-ij+1,1)*[0:order]);
    x1     = ((x(ind)-xj(ii))*ones(1,1+order)).^(ones(n-ij+win2+1,1)*[0:order]); %nbg 8/02
  else                %Middle
    ind    = ij-win2:ij+win2;
    center = win2+1;
    x1     = ((x(ind)-xj(ii))*ones(1,1+order)).^powr;
  end
  
  if any(any(y_missmap(:,ind)));     %JMS 10/02 Missing data support
    [B,I,J] = unique(y_missmap(:,ind),'rows');
    for group = 1:length(I);
      ingroup = find(J==group);
      if sum(~B(group,:))>order & ~B(group,center);   %if we have enough points to do calc & this point is not missing itself
        b(1:order+1,ingroup) = x1(~B(group,:),:)\y(ingroup,ind(~B(group,:)))';
        
        pinvx1 = zeros(order+1, length(ind));
        pinvx1s = pinv(x1(~B(group,:),:));  % needed to make correct dimension
        % leave column of zeros for missing
        pinvx1(:,~B(group,:)) = pinvx1s;
      else
        b(1:order+1,ingroup) = 0;
        pinvx1 = zeros(order+1, length(ind));
      end
    end
  else
    b     = x1\y(:,ind)';
    pinvx1 = pinv(x1);
  end

  yi(:,ii) = prod(1:deriv)*b((deriv+1),:)';
  
  % yi = prod(1:deriv)*b((deriv+1),:)'
  % and b  = pinv * y' 
  % then  yi = prod(1:deriv)* y(:,ind)*pinvx1((deriv+1),:)'
  % thus  yi = y*D    where D is:
  D(ind,ii) = prod(1:deriv)*pinvx1((deriv+1),:)'; % NB: D(ind,ii) !!
end

% Care needed if using yhat = y*D to get smoothed, differentiated y
% Any NaN values in y cause the dot product produces NaN result.
% D was built with 0 in columns where y had NaN in column.
% Assume NaN columns in y are replaced with placeholder finite values, then 
% multiplying by corresponding 0 value in D contributes 0 to dot prod, so
% the y NaN values do not contribute to the result.
% 
% [B1,I1,J1] = unique(y_missmap,'rows');
% y(:,B1) = 1.e6;  % placeholder. When applying y*D, y should not have nans
% yhat = y*D;
% rng = 1:n; ik = 1;
% figure;plot(rng, yhat(ik,:),rng,yi(ik,rng), 'r--') 
% title({sprintf('polyinterp: yi vs y*D, y*D is blue.'), sprintf('Sample %d', ik)})

if wasdataset       %replace modified data back into original dataset and return
  origy.data = yi;
  yi         = origy;
end
