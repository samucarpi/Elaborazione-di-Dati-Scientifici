function [basis,t] = smoothbasis(x,t,o)
%SMOOTHBASIS provides a set of smooth basis functions
%  SMOOTHBASIS provides a basis = [B3, P]; based on the 1xN scale (x) where
%  B3 is a NxK set of B3Splines defined by the knot positions (t) and
%  P  is a NxJ set of polynomial functions defined by (order) J = order+1.
%  
%  INPUTS:
%    x = (1xN vector) of independent variable values (e.g., an axis scale) or
%        (integer scalar) defining N the number of elements in the basis
%          function(s), then x := 1:N .
%    t = defines the number of knots or knot positions (for B3Splines).
%       t: 1x1 scalar integer defining the number of uniformly distributed
%          INTERIOR knots and K = t-1. There are then t+2 knots positioned
%          at t = linspace(min(x),max(x),t+2);
%       t: 1xK vector defining manually placed knot positions where 
%          t = sort(t);
%          Note: the knot positions need not be uniform, and
%                that t(1) can be <min(x) and t(K) can be >max(x).
%          Note: that knot positions must be such that there are
%                at least 3 unique data points between each knot
%                tk,tk+1 for k=1,...,K-1.
%
%  OPTIONAL INPUT:
%   order = {1} positive integer defines the polynomial order or a
%               negative integer to indiate that the polynomial basis
%               should not be included.
%
%  Example:
%    [basis,t] = smoothbasis(1:50,5,2); figure, plot(basis,'-'), grid, vline(t,'k')
%
%I/O: [basis,t] = smoothbasis(x,t,order);
%
%See also: B3SPLINE, POLYBASIS

% Copyright © Eigenvector Research, Inc. 2018
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin<3
  o      = 1; %set default order
end
x        = x(:);
n        = length(x);              %Number of data pts
if isscalar(x)
  n      = x;
  x      = (1:n)';
else
  x      = x(:);
  n      = length(x);              %Number of data pts
end

if isscalar(t)
  t      = linspace(min(x),max(x),t+2);
elseif isvector(t)
  t      = sort(t);
end
k        = length(t)-2;            %Number of B0 basis funs (between knots)
dt       = diff(t);                %Distance between knots

if o>=0
  basis  = zeros(n,k+o); 
else
  basis  = zeros(n,k-1);         %Spline Bases K+1 B0, K B1, K-1 B2
end

b1       = zeros(n,k);
for i1=1:k
  i2        = find(x>=t(i1)&x<t(i1+1));
  b1(i2,i1) = (x(i2)-t(i1))/dt(i1);
  i2        = find(x>=t(i1+1)&x<t(i1+2));
  b1(i2,i1) = (t(i1+2)-x(i2))/dt(i1+1);
end

for i1=1:k-1
  i2           = find(x>=t(i1)  &x<t(i1+2));
  z            = (x(i2)  -t(i1))/sum(dt(i1  :i1+1));
  basis(i2,i1) =                z.*b1(i2,i1);
  i2           = find(x>=t(i1+1)&x<t(i1+3));
  z            = (t(i1+3)-x(i2))/sum(dt(i1+1:i1+2));
  basis(i2,i1) = basis(i2,i1) + z.*b1(i2,i1+1);  
end
if o>=0
  basis(:,k:end)  = polybasis(x,o);
end
basis    = normaliz(basis')';
