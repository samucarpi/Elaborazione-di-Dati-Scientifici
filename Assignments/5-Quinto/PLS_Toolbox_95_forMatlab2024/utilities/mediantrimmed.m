function x = mediantrimmed(x,n,dim)
%MEDIANTRIMMED Trimmed median.
%  INPUTS:
%     x = vector with M elements or MxN matrix of data.
%         higher order arrays are also supported.
%     n = trimming factor
%         If (n>1) and even, (n) is the number of samples to
%         exclude from the calculation.
%         If (0<n<1), (n) is the fraction of samples to
%         exclude from the calculation.
%         If n>m(dim), then (n) is set to zero and the normal
%         median is used.
%
%  OPTIONAL INPUT:
%   dim = defines the dimension/mode along which the mean
%         is estimated (see MEAN). If dim is not defined
%         the first non-singleton dimension is used.
%
%  OUTPUT:
%    mx = trimmed median
%
%I/O: mx = mediantrimmed(x,n,dim);
%
%See also: AUTO, MEAN, MEANTRIMMED, MEDIAN

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
  error('MEDIANTRIMMED requires two inputs.')
end
x = meantrimmed(x,n,dim,'median');
