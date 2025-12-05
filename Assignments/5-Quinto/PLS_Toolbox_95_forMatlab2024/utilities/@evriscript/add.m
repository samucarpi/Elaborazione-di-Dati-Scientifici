function obj = add(obj,step,insertIndex)
%EVRISCRIPT/ADD Add an evriscript_step to an evriscript object.
%I/O: obj = add(obj,step)   %add to end
%I/O: obj = add(obj,step,insertIndex)  %add at insertIndex position

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<2
  error('Script to add to chain must be provided');
end

opts = evriscript('options');
if opts.keywordonly & ~ischar(step)
  error('Building EVRISCRIPT from %s is currently disabled',class(step));
end

switch class(step)
  case 'evriscript_module'
    %a module? turn it into a step
    step = evriscript_step(step);
    
  case 'evriscript_step'
    %OK - what we need, no change needed... fall through
    
  case 'char'
    step = evriscript_step(step);  %convert char to step and fall through

  case 'evriscript'
    %if adding one chain to another, do so one step at a time
    for j=1:length(step.steps);
      obj = add(obj,step.steps{j});
    end
    return  %and exit now
  
  otherwise
    error('Only evriscript_step or evriscript objects can be added to an evriscript');
    
end

theSteps = obj.steps;

% step can only be an evriscript_step by this point.
% Check that the new step, 'step', has a step_id different from the existing steps' step_id
checkStepId(step, theSteps);

if nargin<3 | isempty(theSteps)
  obj.steps = [theSteps(:)' {step}];     % e.g. c.add(scriptA), so just add it at end of chain
else
  isIndexValidForCellArray(insertIndex, theSteps)
  theSteps = theSteps([1:insertIndex insertIndex:end]);
  theSteps{insertIndex} = step;   % insert at position insertIndex in the cell array
  obj.steps = theSteps;
end
% update the script label
obj.label = setlabel(obj);

%---------------------------------------------------------------------------------------------------
function checkStepId(newstep, theSteps)
nsteps = length(theSteps);
% Check the existing script steps to see if any have step_id = newstep.step_id
for j=1:nsteps
  theStep = theSteps{j};
  if theStep.step_id==newstep.step_id
    % Found a match: need to change newstep's step_id:
    newstep.step_id = now+rand(1);
    assignin('caller',inputname(1), newstep);
    return
  end
end

%---------------------------------------------------------------------------------------------------
function label = setlabel(script)

label = '';
if isempty(script) | isempty(script.steps)
  return
end

theSteps = script.steps;
label = [theSteps{1}.step_keyword];
for i=2:length(theSteps)
  step = theSteps{i};
  label = [label ':' step.step_keyword];
end
