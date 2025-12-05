function delete(obj)
%DELETE Delete eslider.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ishandle(obj.patch)
  delete(obj.patch)
end
if ishandle(obj.axis)
  delete(obj.axis)
end
