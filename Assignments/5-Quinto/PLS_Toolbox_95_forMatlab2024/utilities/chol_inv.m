function [x] = chol_inv(x,c)
%CHOL_INV returns a regularized inverse of X'*X based on the Cholesky decomposition.
%  For input (x) = X, CHOL_INV regularizes X'*X based on an approximation
%  of the regularized matrix with a maximum condition number of ~(c).
%  The algorithm is intended to optimize the calculation based on speed 
%  while providing a reasonably accurate inverse.
%  inv(X'*X) is approximated as inv(X'*X  + eye(size(X,2))*trace(X'*X)/c).
%
%  INPUTS:
%     x = an MxN matrix and
%     c = the approximate condition number of
%         X'*X  + eye(size(X,2))*trace(X'*X)/c.
%
%  OUTPUT:
%    xi = inv(X'*X  + eye(size(X,2))*trace(X'*X)/c).
%
%I/O: [x] = chol_inv(x,c);

% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%  X'*X   = R'*R;   R = chol(X'*X);
%  inv(x) = inv(R'*R) = inv(R)*inv(R');

a     = speye(size(x,2));
x     = x'*x;
x     = chol(x+trace(x)*a/c); % R of R'*R = chol(x'*x)
x     = x\a;                  % inv(R) using back substitution
x     = x*x';