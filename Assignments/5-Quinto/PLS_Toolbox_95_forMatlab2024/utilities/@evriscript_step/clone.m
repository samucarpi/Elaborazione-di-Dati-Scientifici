function newobj = clone(oldobj)
% EVRISCRIPT_STEP\CLONE Create clone of EVRIScript_step object.
% This method creates a new script object with the same base script_module type and also populates 
% any variables which are listed as "outputs" from the original script object.
% Another way to describe this is that clone() takes the existing script object and removes the 
% contents of any variables which are NOT listed in the script_module.outputs list. 

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

newobj = evriscript_step(oldobj.step_keyword);     % this will have default variables set.
newobj.step_mode = oldobj.step_mode;

if ~isempty(oldobj.step_mode)
  % copy over variables from oldobj.variables, only those which are in oldobj.step_module.outputs (for step_mode = oldobj.step_mode)
  oldvars = oldobj.variables;
  oldouts = oldobj.step_module.outputs.(oldobj.step_mode);
  copyvars = intersect(fieldnames(oldvars), oldouts);
  
  for i=1:length(copyvars)
    name = copyvars{i};
    newobj.variables.(name) = oldvars.(name);
  end
end
