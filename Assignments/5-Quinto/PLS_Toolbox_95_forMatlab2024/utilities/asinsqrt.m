function x = asinsqrt(x,a)
%ASINSQRT arcsin square root transformation.
%  ASINSQRT is often used when the input (x) is a set of proportions.
%  For input(x) the transformation is given by
%    ax = arcsin(sqrt(x));
%  or if optional scalar input (c) is included it is:
%    ax = arcsin(sqrt(x+a));
%  The input (x) must be non-negative and lie on  0<= x <1.
%
%   INPUT:
%      x = MxN matrix to transform (class double or DataSet).
%          Input (x) must be non-negative and lie on  0<= x <1.
%
%   OPTIONAL INPUT:
%      c = scalar offset {default: c = 0}.
%
%   OUTPUT:
%     ax = x transformed using arcsin square root transformation.
%
%I/O: ax = asinsqrt(x,c);
%I/O: asinsqrt demo
%
%See also: AUTO, ASINHX, PR_ENTROPY

% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin<2 || isempty(a)
  a   = 0; 
end

% run test on x to ensure this works ok, try/catch to be graceful

if isdataset(x)
  x.data  = asin(sqrt(x.data+a));
else
  x       = asin(sqrt(x+a));
end
