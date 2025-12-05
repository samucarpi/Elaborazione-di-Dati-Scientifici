function [xu] = spltvar(x)
%SPLTVAR Finds the unique variance for each column.
%  For a data matrix (x), SPLTVAR calculates a corresponding matrix (xu)
%  with columns containing the unique signal for each column. For example,
%  suppose that x is an MxN matrix. Then for column n (n=1,...,N) there is
%  a complimentary set of columns j = setdiff(1:N,n) that do not contain n.
%  Then, the part of x(:,i) that is orthogonal to x(:,j) is given by
%      xu(:,n) = x(:,n) - x(:,j)*(pinv(x(:,j))*x(:,n));
%  This is a Gram-Schmidt orthogonalization of x(:,n) to x(:,j).
%
%  INPUT:
%     x = MxN matrix {class double}.
%
%  OUTPUT:
%    xu = MxN matrix 
%
%I/O: [xu] = spltvar(x);

% Copyright © Eigenvector Research, Inc. 2020
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

N         = size(x,2);
xu        = x;                       % Initialize memory for xu

for n=1:N                            % Gram-Schmidt for each column
  j       = setdiff(1:N,n);
  xu(:,n) = x(:,n) - x(:,j)*(pinv(x(:,j))*x(:,n));
end
