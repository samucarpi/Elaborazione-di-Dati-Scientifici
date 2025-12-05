function index = findindx(array,r);
%FINDINDX Finds the index of the array element closest to value r.
% Inputs are an array of values (array) and a value to locate (r).
% Output (index) is the linear index into array which will return
% the closest value to r. 
% Example:
%   index = findindx(array,r);      %get an index
%   nearest_value = array(index);   %find the value
%
%I/O: index = findindx(array,r)
%
%See also: LAMSEL

% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%jms 5/04 based on ww function of same name

if nargin == 0; array = 'io'; end
if ischar(array);
  options = [];
  if nargout==0; evriio(mfilename,array,options); else; index = evriio(mfilename,array,options); end
  return; 
end

if isdataset(r)
  r = r.data;
end

if isempty(array)
  %empty array indicates empty output (without error!)
  index = [];
  return
end

if any(size(r)>1);  %vector or array
  index = r;
  for j=1:prod(size(r));
    index(j) = findindx(array,r(j));
  end
else  %scalar
  [difference,index] = min(abs(array(:)-r));
end

%(difference) is absolute value of difference between r and closest array value
