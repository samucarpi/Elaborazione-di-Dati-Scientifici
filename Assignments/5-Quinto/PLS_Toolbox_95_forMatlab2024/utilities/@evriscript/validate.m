function isValid = validate(x)
%EVRISCRIPT/VALIDATE Validate variable references of evriscript's steps.
%  Returns true/false indicating references are valid
%  Input is the evriscript of interest (x) and output is logical.
%I/O: isValid = validate(x)

%Copyright Eigenvector Research, Inc. 2005

isValid = true;
theSteps = x.steps;
nsteps = length(theSteps);
disp(sprintf('\n\n===================================='));
disp(sprintf('evriscript: ''%s'' validation', x.label));
disp(sprintf('===================================='));
for j=1:nsteps
  disp(sprintf('Step[%i]: ----------------------------', j));
  thestep = theSteps{j};
  % get all variables in cell arrray of structs
  variables{j} = thestep.variables;
  outputs = thestep.step_outputs;
  
  % Find index of the target step for each reference and step
  [theVars, refsStruct] = resolveStepReferences(theSteps, j);
  
  names = fieldnames(variables{j});
%   names = union(names,thestep.step_inputs); % step_inputs include all inputs over all modes
  disp('  Input variables:');
  for jj=1:length(names)
    name = names{jj};
    if isfield(variables{j},name)
      value = getfield(variables{j}, char(names{jj}));
      valueclass = class(value);
    else
      value = '';
      valueclass = ' ---> ERROR: Value is unassigned';
      isValid = false;
    end
    if isa(value, 'evriscript_reference')
      try
        % get indexOfTargetStep and varname for this name
        istr = findStrInCellArray({refsStruct.name}, name);
        itarget = refsStruct(istr).indexOfTargetStep;
        if isempty(itarget) | istr<0
          error('validate: could not resolve reference %s in step %i', name, j);
        end
        disp(sprintf('      %s: \t %s ---> step[%i]: %s', name, valueclass, ...
          refsStruct(istr).indexOfTargetStep, refsStruct(istr).varname ));
      catch
        varname = value.ref_variable;
        disp(sprintf('      %s: \t %s ---> %s     ERROR: REFERENCE IS UNRESOLVABLE', name, valueclass, varname));
        isValid = false;
      end
    else
      disp(sprintf('      %s: \t %s:', name, valueclass));
    end
  end
  % and outputs
  disp('  Output variables:');
  nouts = length(outputs);
  for iout = 1:nouts
    disp(sprintf('      %s', outputs{iout}));
  end
end
disp(sprintf('===================================='));

%---------------------------------------------------------------------------------------------------
% From chain subsref:
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
      % Does step.variables contain variable with this name?  Or output variable with this name
      zzz=step.step_outputs;
      
      if isfield(step.variables, char(zz)) | findStrInCellArray(zzz, char(zz))>-1
        %       value = getfield(step.variables, char(zz));
        value = j; % this is the index of the target step in the chain which this ref resolves to
        return
      end
    end
  end
end

%---------------------------------------------------------------------------------------------------
function index = findStrInCellArray(carray, str)
%FINDSTRINCELLARRAY returns index of string in cell array of strings, or -1 if not found.
index = -1;
if ischar(str)
  for i=1:length(carray)
    if ischar(carray{i}) & strcmp(carray{i}, str)
      index = i;
      break;
    end
  end
end

%---------------------------------------------------------------------------------------------------
function [step, resolvedRefStruct] = resolveStepReferences(theSteps, istep)
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
  indexOfTargetStep = resolveRef(ref, theSteps, istep);
  resolvedRefStruct(ir).name = name;
  resolvedRefStruct(ir).varname = varname;
  resolvedRefStruct(ir).indexOfTargetStep = indexOfTargetStep;
end
