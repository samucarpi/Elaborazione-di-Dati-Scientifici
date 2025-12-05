function k = kurtosis(x,flag,dim)
%KURTOSIS Returns the kurtosis statistic for a vector or matrix.
% Returns the kurtosis statistic for a vector or matrix, x. Missing data is
% ignored for the calculation.
%
% INPUTS:
%   x    = vector or matrix
% OPTIONAL INPUTS:
%   flag = bias-correction disable flag. When set to 0 (zero), the kurtosis
%          is corrected for sampling bias. Default is 1 (one) to return the
%          uncorrected kurtosis. The correction for bias is done by the
%          formula: 
%                k = (n-1)/((n-2)*(n-3)) * ((n+1)*k-3*(n-1))+3
%          where n is the number of non-missing elements in the given
%          column of x.
%   dim  = dimension of x over which to calculate the kurtosis. Default is
%          1, over rows (kurtosis calculated down columns.)
%
% OUTPUTS:
%   k    = kurtosis of x over the specified dimension (dim)
%
%I/O: k = kurtosis(x)
%I/O: k = kurtosis(x,flag,dim)

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

[junk,mn4] = mncn(mcx.^4);
[junk,mn2] = mncn(mcx.^2);
k = mn4 ./ (mn2.^2);

if ~flag
  n  = sum(~isnan(x),1);
  k = (n-1)./((n-2).*(n-3)).*((n+1).*k-3*(n-1))+3;
end

