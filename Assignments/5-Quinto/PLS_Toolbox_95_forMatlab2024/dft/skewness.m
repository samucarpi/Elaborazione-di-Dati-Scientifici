function s = skewness(x,flag,dim)
%SKEWNESS Returns the skewness statistic for a vector or matrix.
% Returns the skewness statistic for a vector or matrix, x. Missing data is
% ignored for the calculation.
%
% INPUTS:
%   x    = vector or matrix
% OPTIONAL INPUTS:
%   flag = bias-correction disable flag. When set to 0 (zero), the skewness
%          is corrected for sampling bias. Default is 1 (one) to return the
%          uncorrected skewness. The correction for bias is done by the
%          formula: 
%                s = sqrt(n*(n-1))/(n-2) * s
%          where n is the number of non-missing elements in the given
%          column of x.
%   dim  = dimension of x over which to calculate the skewness. Default is
%          1, over rows (skewness calculated down columns.)
%
% OUTPUTS:
%   s    = skewness of x over the specifed dimension (dim)
%
%I/O: s = skewness(x)
%I/O: s = skewness(x,flag,dim)

% Copyright © Eigenvector Research, Inc. 2015
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin<2 | isempty(flag)
  flag = 1;
end
if nargin<=2 | isempty(dim)
  dim = 1;
end

switch dim
  case 2
    x = x';
  case 1
    %OK...
    if size(x,1)==1 & size(x,2)>1
      %unless we have a ROW vector, then transpose
      x = x';
    end
  otherwise
    error('dim of %i not supported',dim)
end

mcx = mncn(x);

[junk,mn3] = mncn(mcx.^3);
[junk,mn2] = mncn(mcx.^2);
s = mn3 ./ (mn2.^1.5);

if ~flag
  n  = sum(~isnan(x),1);
  s  = sqrt(n.*(n-1))./(n-2).*s;
end

