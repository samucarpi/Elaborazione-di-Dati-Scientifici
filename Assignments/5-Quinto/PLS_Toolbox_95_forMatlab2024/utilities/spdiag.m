function out = spdiag(X,k)
%SPDIAG Simplified sparse diagonal function.
% This simple diag operation takes the place of diag(A) where A is a
% vector but creates a sparse diagonal matrix which saves significant
% memory. It can be used in place of any diag operation whether A is a
% matrix or vector (the matrix input just defaults to the standard diag
% operation.)
%
% For help with I/O, see the standard Matlab function diag.
%
%I/O: spdiag(v,k)
%I/O: spdiag(v)
%I/O: spdiag(X,k)
%I/O: spdiag(X)
%
%See also: SPDIAGS

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

[m,n] = size(X);
if m==1 | n==1
  if nargin<2
    k = 0;
  end
  l = length(X);
  out = spdiags(X(:),k,l,l);
else
  if nargin<2
    out = diag(X);
  else
    out = diag(X,k);
  end
end
