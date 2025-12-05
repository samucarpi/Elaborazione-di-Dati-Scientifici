function display(obj, idetail)
%EVRISCRIPT_STEP/DISPLAY Overload for display function to print summary of fields
%I/O: display(evriscript_step)     Display keyword, label and id of evriscript_step
%I/O: display(evriscript_step, 0)  Display keyword, label and id of evriscript_step
%I/O: display(evriscript_step, 1)  Display more fields of evriscript_step
%I/O: display(evriscript_step, 2)  Display more detail of the evriscript_module

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==1
  idetail = 0;
elseif nargin==2 & (isempty(idetail) | ~isnumeric(idetail))
  idetail = 0;
end

disp([inputname(1),' = '])
disp(obj,idetail)
