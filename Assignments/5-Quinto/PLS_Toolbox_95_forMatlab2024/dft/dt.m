function density = dt(x,v)
%DT Density function for Student's t(v)
%  Calculates the density function for each element of input(x)
%  (scalar or vector) with the number of degrees of freedom (v)
%  (scalar). Density values are determined by taking the derivative
%  of the output from PT.
% 
%Examples:
%    dt(1.6449,3) = 0.1016
%    dt(1.96,3)   = 0.0707
%
%I/O: density = dt(x,v);
%
%See also: DNORM, PT

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%nbg 10/00

if nargin<2
  error('2 input arguments required.')
end
if v<0
  error('Input v must be positive')
end
row     = logical(1);
if (size(x,1)>1)&(size(x,2)>1)
  error('Input x must be a vector')
elseif size(x,2)<size(x,1)
  row   = logical(0); %input x is a column vector
  x     = x';         %make x a row vector
end

h       = 0.05; %stepsize
x       = abs(x);
x1      = min(x)-3*h;
if x1<0
  x1    = 0;
end
x2      = max(x)+3*h;
xa      = x1:h:x2;
y       = pt(xa,v);
y       = savgol(y,5,3,1)/h;

density = interp1(xa',y',x');
if row
  density = density';
end

