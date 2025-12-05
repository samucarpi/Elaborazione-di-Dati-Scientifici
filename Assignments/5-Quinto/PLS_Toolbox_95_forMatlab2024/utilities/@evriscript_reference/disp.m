function disp(obj)
%EVRISCRIPT_REFERENCE/DISP Overload for display function.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

disp(' EVRIScript_reference Object');
disp(sprintf('        step_id: %20.12f', obj.step_id));
disp(       ['  ref_variable: ''' obj.ref_variable '''']);
