function [v,s] = svd_xx(h,x)
%SVD_XX Calculates SVD of X'X or XX' symmetric matrix.
%  Assume that [u,s,v] = svd(x) then
%    [v,s] = svd_xx(h,x);
%  SVD is more accurate, but SVD_XX can be used for large matrices and
%  gives a fast approximation.
%
%  For (x) MxN, use h = xtx when M>N and h = xxt when M<N.
%
%  INPUTS:
%    x = matrix MxN class double.
%    h = [ 'xtx' | 'xxt'] string goverining if the SVD is for
%          X'*X or X*X'.
%
%  OUTPUTS:
%    v = unitary matrix such that x'*x = v*diag(s)*v'.
%    s = vector of singlar values (in contrast SVD gives a digonal matrix).
%
%I/O: [v,s] = svd_xx(h,x);

%Copyright Eigenvector Research, Inc. 2021
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

h       = str2func(h);
[v,s]   = h(x);
end

function [v,s] = xtx(x)
  [v,s] = svd(x'*x,"vector");
end %xtx

function [v,s] = xxt(x)
  [v,s] = svd(x*x',"vector");
  v     = normaliz(v'*x)';
end %xxt