function  obj = execute(obj)
%EVRISCRIPT/EXECUTE Execute the steps in an evriscript.
%
% For each step:
%   Search vars of that step for references
%   Resolve references by:
%     searching back through executed steps for id and varname
%     fill in new values
%     execute the step
%     replace references (so that rerunning chain with new input data does not use old ref values)
% Go to next step
% At end of chain execution all generated vars should be available

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


theSteps = obj.steps;
nsteps = length(theSteps);
if nsteps < 1
  error('There are no steps in this evriscript. Nothing to execute')
else
  for istep=1:nsteps
    % resolve references, execute and reset references
    [step, refsStruct] = resolveStepReferences(theSteps, istep);
    try
      step = step.execute;
    catch
      le = lasterror;
      le.message = [sprintf('Error executing step %i :',istep) le.message];
      rethrow(le);
    end
    step = resetStepReferences(refsStruct, step);
    
    % reinsert modified step after it executed
    theSteps{istep}=step;
  end
  obj.steps = theSteps;
end


%---------------------------------------------------------------------------------------------------
function refs = getReferences(theVars)
refs = struct;
if isempty(theVars) | isempty(fieldnames(theVars))
  return
end
names = fieldnames(theVars);
iref = 1;
for iname = 1:length(names)
  name = names{iname};
  if iscell(name)
    name = char(name);
  end
  value = theVars.(name);
  if isa(value, 'evriscript_reference')
    refs(iref).name = name;
    refs(iref).ref = value;
    iref = iref+1;
  end
end

%---------------------------------------------------------------------------------------------------
function value = resolveRef(ref, theSteps, istep)
% Look through previous executed steps to find the referenced value
value = [];
nsteps = length(theSteps);
if istep < 2 | nsteps < 2
  return
else
  for jj=1:(istep-1)   %j=(istep-1):1
    j = istep-jj;
    step = theSteps{j};
    if step.step_id==ref.step_id
      % this is the step referred to. Check for the variable named ref.name
      zz=ref.ref_variable;
      % Does step.variables contain variable with this name?
      if isfield(step.variables, char(zz))
        value = step.variables.(char(zz));
        return
      end
    end
  end
end

%---------------------------------------------------------------------------------------------------
function [step, refsStruct] = resolveStepReferences(theSteps, istep)
resolvedRefStruct = struct;
step = theSteps{istep};
refsStruct = getReferences(step.variables);

if isempty(fieldnames(refsStruct))
    return
end

if istep==1
  if isempty(fieldnames(refsStruct))
    return
  else
    error('First step of chain contains a reference variable. This is not permitted')
  end
end

nrefs = size(refsStruct);
for ir=1:nrefs(2)
  % resolve refs using prior steps
  refinfo = refsStruct(ir);
  name = refinfo.name;
  ref = refinfo.ref;
  varname = ref.ref_variable;
  % Resolve reference using previous, executed steps
  varvalue = resolveRef(ref, theSteps, istep);
  resolvedRefStruct(ir).name = name;
  resolvedRefStruct(ir).varname = varname;
  resolvedRefStruct(ir).varvalue = varvalue;
end
%  update step.variables with the referenced values
for j=1:nrefs(2)
  name = resolvedRefStruct(j).name;
  vvalue = resolvedRefStruct(j).varvalue;
  step.variables.(name) = vvalue;
end

%---------------------------------------------------------------------------------------------------
function step = resetStepReferences(refsStruct, step)
if isempty(fieldnames(refsStruct)) | isempty(step)
  return
end
% reset references for this step
nrefs = size(refsStruct);
for j=1:nrefs(2)
  name = refsStruct(j).name;
  ref = refsStruct(j).ref;
  step.variables.(name) = ref;
end

