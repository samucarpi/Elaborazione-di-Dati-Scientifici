function x=subsasgn(x,index,value)
%EVRISCRIPT_STEP/SUBSASGN Assign for evriscript_step objects using Structure and index notation.
% Usage x.fld1 = value; or x.fld1.fld2 = value;
% Sets the 'fld1' field for a evriscript_step object to (value).
% If 'fld1' is not a field of evriscript_step then sets the x.variables.fld1 = value.
% If 'fld1' = 'variables' then sets  x.variables.fld2 = value.
% If 'fld1' = 'options' then sets 
%    x.options.fld2 = value, provided 'fld2' is already a field of x.options,
%    and opens error dialog otherwise.
%I/O: x.fld1 = value; 
%I/O: x.fld1.fld2 = value;

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

nnargin = nargin;
error(nargchk(3,3,nnargin));   %give error if nargin is not appropriate

if isempty(index); error('Invalid subscripting'); end;

if strcmp(index(1).type,'()')
  subs = index(1).subs{1};
  if numel(subs)>1 | subs>2
    error('Invalid subscripting on evriscript_step object');
  end
  if subs==2
    %index of 2 indicates concatenation into chain
    x = cat(2,x,value);
    return;
  else
    %index of 1 is just the object itself - no foul
    index = index(2:end);
  end    
end
if ~strcmp(index(1).type,'.');
  error('Assignment subscripting not permitted on main evriscript_step object');
else
  fld1=index(1).subs;
end;

if nnargin==3
  if ~ischar(fld1)
    error('Invalid evriscript_step object field.')
  end
  
  switch fld1
    case {'step_module'}
      %attempt to change script_module
      error('evriscript_step property "step_module" is read-only. Generate new evriscript_step object to change step_module.')
      
    case {'step_keyword' 'step_lockedvars' 'step_inputs' 'step_required'}
      %attempt to change read-only field
      error('evriscript_step property "%s" is read-only.',fld1)
      
  end
  if length(index)==1
    switch fld1
      
      case {'step_lock'}
        %attempt to lock object
        checklock(x)
        
        if value %attempting to LOCK
          %note which vars are currently used
          usedvars = fieldnames(x.variables);
          lockedvars = {};
          for j=1:length(usedvars)
            if ~isempty(x.variables.(usedvars{j}))
              %make note of all vars which are non-empty right now
              lockedvars{end+1} = usedvars{j};
            end
          end
          %store list and turn on lock
          x.step_lockedvars = lockedvars;
          x.step_lock = true;
        end
        
      case {'step_mode'}
        %setting script mode - make sure it is a valid mode
        checklock(x)
        if ~ismember(value,x.step_module.modes) & ~isempty(value)
          error('Invalid mode for this script type ("%s"). Use object.step_module.modes to see list of valid modes',x.step_module.keyword);
        end
        x.step_mode = value;
        
      case 'options'
        checklock(x)
        % Allow user to replace the options struct PROVIDED the struct 
        % they are inserting includes all the fields in the x.options. 
        % This relaxation of the prior fields requirement is not relaxed
        % when the user is updating a specific option, such as:
        % step.options.newopt = 'blah';  In this case "newopt" must already
        % be a field in the step.options. This is to prevent accidentally
        % not setting an option because the name was misspelt.
        if ~isstruct(value) | ~all(ismember(fieldnames(x.options), [fieldnames(value);{'rawmodel'}]))
          error('Overwriting options directly requires structure with all prior options fields presnt')
        end
        x.(fld1) = value;
        
      case fieldnames(x)
        % setting one of the standard fields of the object
        checklock(x)
        x.(fld1) = value;

      otherwise
        % validate field is in either  module.required/optional for ANY mode
        validatefield(x, fld1);
        checklock(x,fld1)
        x.variables.(fld1) = value;
    end

  % The following may not be needed, and only adds to .variables
  elseif length(index)==2
    if ~strcmp(index(2).type,'.');
      error('Assignment subscripting not permitted on evriscript_step ''%s'' object', fld1);
    else
      fld2=index(2).subs;
    end;
    
    switch fld1
      case {'options'}
        %attempt to change option
        checklock(x)
        if ismember(fld2, fieldnames(x.options))
          x.options.(fld2) = value;   % verify fld2 is already in x.options when setting script.options.fld2
        else
          error('%s is not a valid options field for evriscript_step', fld2);
        end
        
      case {'variables' 'properties'}
        %index into "variables" or "properties" field (same field)
        validatefield(x, fld2);
        checklock(x,fld2)
        x.variables.(fld2) = value;   % set the field
        
      otherwise
        %sub-indexing into variable directly. OK as long as variable exists
        validatefield(x, fld1);
        checklock(x,fld1)
        x.variables.(fld1).(fld2) = value;   % set the field
        
    end  
  elseif ismember(fld1,fieldnames(x.variables))   
    % ANY other subsasgn into existing variable is also OK
    %EG:
    % obj.myvar.subfield... = foo
    % obj.myvar(1:3) = foo
    validatefield(x, fld1);
    checklock(x,fld1);
    x.variables.(fld1) = subsasgn(x.variables.(fld1),index(2:end),value);   % set the field
  elseif strcmp(fld1, 'options')
    % allow any option struct member to be added
    nopt = length(index);
    if  any(strcmp({index.type},'.')==0)
      error('Assignment subscripting not permitted on evriscript_step ''%s'' object', fld1);
    else
      % assign any options field
      switch nopt
        case {3}    % assign to options.a.b
          x.options.(lower(index(2).subs)).(lower(index(3).subs)) = value;
        case {4}    % assign to options.a.b.c
          x.options.(lower(index(2).subs)).(lower(index(3).subs)).(lower(index(4).subs)) = value;
        case {5}    % assign to options.a.b.c.d
          x.options.(lower(index(2).subs)).(lower(index(3).subs)).(lower(index(4).subs)).(lower(index(5).subs)) = value;
        otherwise
          error('Assignment subscripting too deep');
      end
    end
  else
    error('Invalid assignment subscripting on evriscript_step ''%s'' object', fld1);
  end
end

%---------------------------------------------------------
function validatefield(x, fld)
%VALIDATEFIELD checks fld is in either module.required or module.optional for ANY mode
allTotal = x.step_module.inputs;
if ~ismember(fld,allTotal)
  error('Field ''%s'' is not a valid input with any execute mode or is a Read Only output', fld);
end

%---------------------------------------------------------
function checklock(x,property)
if x.step_lock
  if nargin>1 & ~isempty(property)
    if ismember(property,x.step_lockedvars)
      %locked var (one that was set when we locked)
      error('Script is locked - cannot change locked properties')
    end    
  else
    %standard field: always locked
    error('Script is locked - cannot change settings')
  end
end
