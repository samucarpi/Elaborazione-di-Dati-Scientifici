function [basis] = polybasis(x,o)
%POLYBASIS provides a set of polynomial basis functions
%  POLYBASIS utility to provide a basis = P; based on the 1xN scale (x) where
%  P is a NxJ set of polynomial functions defined by (order) J = order+1.
%  
%  INPUTS:
%        x = (1xN vector) of independent variable values 
%              (e.g., an axis scale) or
%            (integer scalar) defining N the number of elements in
%               the basis function(s).
%    order = {1} positive integer defines the polynomial order.
%
%  OUTPUT:
%    basis = NxK set of polynomial functions where K = order+1 normalized
%              to unit 2-norm (e.g., basis(:,1)'*basis(:,1) = 1);
%
%  Example:
%    basis = polybasis(1:50,2); figure, plot(basis,'-'), grid
%
%I/O: basis = polybasis(x,order);
%
%See also: SMOOTHBASIS, B3SPLINE

% Copyright © Eigenvector Research, Inc. 2018
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if isscalar(x)
  n    = x;
else
  n    = length(x);              %Number of data pts
end
basis  = normaliz( (ones(1+o,1)*mncn((1:n)')') .^((0:o)'*ones(1,n)) )';
