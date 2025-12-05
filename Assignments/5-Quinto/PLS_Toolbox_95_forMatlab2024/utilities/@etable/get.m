function myval = get(obj,propertyName)
%ETABLE/GET Overload of GET for etable.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin<2
  myval = obj;
  return
end

switch propertyName
  case ''
    
  otherwise
    myval = obj.(propertyName);
end

    
    
