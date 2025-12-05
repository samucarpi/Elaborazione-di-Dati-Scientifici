function display(obj)
%EVRIMODEL/DISPLAY overload for object.

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

n = inputname(1);
if ~isempty(n)
  disp(sprintf('%s = ',n))
  disp(obj,n);
else
  disp(obj);
end
