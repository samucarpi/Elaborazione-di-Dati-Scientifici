function x = asinhx(x,c)
%ASINHX arcsinh transform.
%  For input(x) the transformation is given by
%    ax = arcsinh(x);
%  or if optional input (c) is included it is:
%    ax = arcsinh(x+c);
%
%   INPUT:
%      x = MxN matrix to transform (class double or DataSet).
%
%   OPTIONAL INPUT:
%      c = scalar offset {default: c = 0}.
%
%   OUTPUT:
%     ax = x transformed using arcsin square root transformation.
%
%I/O: ax = asinhx(x,c);
%I/O: asinhx demo
%
%See also: AUTO, ASINSQRT, PR_ENTROPY

% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin<2 || isempty(c)
  c   = 0; 
end

if isdataset(x)
  x.data  = asinh(x.data+c);
else
  x       = asinh(x+c);
end
