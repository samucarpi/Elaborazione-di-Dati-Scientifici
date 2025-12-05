function x = meantrimmed(x,n,dim,opt)
%MEANTRIMMED Trimmed mean.
%  INPUTS:
%     x = vector with M elements or MxN matrix of data.
%         higher order arrays are also supported.
%     n = trimming factor
%         If (n>1) and even, (n) is the number of samples to
%         exclude from the calculation.
%         If (0<n<1), (n) is the fraction of samples to
%         exclude from the calculation.
%         If n>m(dim), then (n) is set to zero and the normal
%         mean is used.
%
%  OPTIONAL INPUT:
%   dim = defines the dimension/mode along which the mean
%         is estimated (see MEAN). If dim is not defined
%         the first non-singleton dimension is used.
%
%  OUTPUT:
%    mx = trimmed mean
%
%I/O: mx = meantrimmed(x,n,dim);
%
%See also: AUTO, MEAN, MEDIAN, MEDIANTRIMMED

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  if nargout==0 
    evriio(mfilename,x,options); 
    clear x; 
  else 
    x = evriio(mfilename,x,options); 
  end
  return 
end

if nargin<2
  error('MEANTRIMMED requires two inputs.')
end
if n<0
  error('Input (n) must be >0.')
end
if nargin<4
  opt = 'mean';
end
m     = size(x);
if nargin<3 || isempty(dim)
  dim = find(m~=1);
  dim = dim(1);
end

if isint(n) 
  if isneg(n)
    error('Input (n) must be non-negative.')
  elseif n>=m(dim)      %check if <non-singleton dim
    n = 0;
  else
    if mod(n,2) ~= 0    %check if not an even
    error('Input (n) must be an even integer.')
    end
  end
elseif n>0 && n<1
  n   = round(n*m(dim));
  if mod(n,2) ~= 0  
    n = n+1;
  end
else
  error('Input (n) must be n>1 and even, or 0<n<1.')
end

x    = sort(x,dim);
id   = cell(1,length(m));
for i1=1:length(m)
  id{i1} = 1:m(i1);
end
id{dim}  = id{dim}(n/2+1:m(dim)-n/2);
switch lower(opt)
case 'mean'
  x      = mean(x(id{:}),dim);
case 'median'
  x      = median(x(id{:}),dim);
end
