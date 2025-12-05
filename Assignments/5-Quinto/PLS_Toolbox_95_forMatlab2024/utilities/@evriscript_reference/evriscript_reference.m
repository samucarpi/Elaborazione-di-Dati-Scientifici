function reference = evriscript_reference(varname, scriptobj)
%CREATE AN EVRISCRIPT_REFERENCE OBJ GIVEN AN EVRISCRIPT_STEP AND VARIABLE NAME

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1
  scriptobj = struct('step_id',nan);
  varname = '';
end

reference = struct('evriscript_referenceversion','1.0');
reference.step_id = scriptobj.step_id;
reference.ref_variable = varname;
% reference.script_value = [];

reference = class(reference,'evriscript_reference'); 
