function scriptobj = execute(scriptobj,scriptMode)
%EVRISCRIPT_STEP/EXECUTE Execute a script step.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin>1 & ~isempty(scriptMode)
  if scriptobj.step_lock
    error('Script is locked - cannot change settings')
  end
  scriptobj.step_mode = scriptMode;
end

wasEmptyMode = isempty(scriptobj.step_mode);
if wasEmptyMode
  %no mode selected? see if one of the modes is valid
  cmodes = scriptobj.step_module.modes;
  if length(cmodes)>1
    %search for best fit mode
    for modeindex = 1:length(cmodes);
      if validateRequired(scriptobj,cmodes{modeindex});
        %enough data for this mode to work? Use it
        %(Note: this works even if object is LOCKED)
        scriptobj.step_mode = cmodes{modeindex};
        break;  %stop looking
      end
    end
    if isempty(scriptobj.step_mode)
      error('No script modes match the currently set properties.')
    end
  else
    %only have one mode - must be it
    scriptobj.step_mode = cmodes{1};
  end
end
    
validateRequired(scriptobj);
scriptobj = setUninitializedOptionals(scriptobj);
scriptobj = executeCommand(scriptobj);

if wasEmptyMode
  scriptobj.step_mode = '';  %return to empty after execution
end

if nargout==0
  assignin('caller',inputname(1),scriptobj)
  clear scriptobj
end


%------------------------------------------------------------
function x = setUninitializedOptionals(x)
%SETUNINITIALIZEDOPTIONAL % Initialize any uninitialized optional args for the step_mode to []
% Do nothing if step_mode is empty
step_mode = x.step_mode;
if isempty(step_mode)
  % do nothing
  return
else
  % verify all optional variables are initialized, or set them = []:
  optionals = x.step_module.optional; % includes all modes
  if isempty(optionals)
    return
  end
  optional = x.step_module.optional.(step_mode);
  if isempty(optional)
    return
  end
  
  if ~isempty(x.variables)
    usedFields=fieldnames(x.variables);
  else
    usedFields = [];
  end
  missingOptionalFields = setdiff(optional, usedFields);
  
  % initialize missing args to []
  for i=1:length(missingOptionalFields)
    x.variables.(missingOptionalFields{i}) = [];
  end
end


%---------------------------------------------------------------------------------------------------
function [var] = safe_eval(var, cmd, options)
try
  eval(cmd);
catch
  le = lasterror;
  try
    me = strmatch('safe_eval',{le.stack.name});
    le.stack = le.stack([1:me-1]);
  catch
  end
  rethrow(le);
end

%---------------------------------------------------------------------------------------------------
function scriptobj = executeCommand(scriptobj)

cmds       = scriptobj.step_module.command;
scriptMode = scriptobj.step_mode;

% Create a script label if it is empty
if isempty(scriptobj.step_label)
  scriptobj.step_label = [scriptobj.step_keyword '_' scriptobj.step_mode];
end

runcmd = cmds.(scriptMode);
% execution of command
resvar = safe_eval(scriptobj.variables, runcmd, scriptobj.options);

%copy over "outputs" from resvar
newfields = scriptobj.step_module.outputs.(scriptMode);
if ~isempty(newfields)
  for field = newfields(:)'
    % Add this field back into variables
    scriptobj.variables.(field{:}) = resvar.(field{:});
  end
end

%-----------------------------------------------------------
function valid = validateRequired(x,step_mode)
%VALIDATEFIELDS check all script.step_module.required, for ''step_mode'' are present in variables.
% Checks against required. Throw error if no outputs requested, otherwise,
% return "valid" flag (1=is valid)

if nargin<2
  step_mode = x.step_mode;
end
if isempty(step_mode)
  error('Script mode is empty');
else
  % verify fld is in either  module.required/optional IF step_mode is set
  required = x.step_module.required.(step_mode);
  
  if ~isempty(x.variables)
    usedFields = fieldnames(x.variables);
    emptyFields = {};
    for k=1:length(usedFields)
      if isempty(x.variables.(usedFields{k}))
        emptyFields{end+1} = usedFields{k};
      end
    end
    usedFields = setdiff(usedFields,emptyFields);  %drop empty fields from "used" list
  else
    usedFields = {};
    emptyFields = {};
  end
  missingRequiredFields = setdiff(required, usedFields);
  numMissing = length(missingRequiredFields);
  
  if numMissing > 0 & nargout==0
    missingNames = sprintf(', %s',missingRequiredFields{:});
    missingNames = missingNames(3:end);
    error('One or more properties required for mode "%s" are missing: %s', step_mode,missingNames);
  end
  valid = numMissing==0;
end
