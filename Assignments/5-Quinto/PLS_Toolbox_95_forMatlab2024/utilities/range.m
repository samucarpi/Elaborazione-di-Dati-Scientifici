function y = range(x,dim)
%RANGE Calculates the range of the values. 
%
% INPUT:
%   x = data vector or matrix.
%
% OPTIONAL INPUT:
%   dim = dimension for taking the range (default = 1).
%
% OUTPUT:
%   y = range [scalar if (x) is a vector, vector if (x) is a matrix].
%
% Example: x = [8  1  6
%               3  5  7 
%               2  9  2]
%   range(x) is [6 8 5] and range(x,2) is [7 4 7].
%
%I/O: y = range(x);
%I/O: y = range(x,dim);
%
%See also: AUTO, MNCN, NORMALIZ, NPREPROCESS, REGCON, SCALE, SNV, STD

% Copyright © Eigenvector Research, Inc. 2007
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
% NBG


if nargin<2, dim = 1; end
y = max(x,[],dim)-min(x,[],dim);
