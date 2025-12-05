function varargout = subsref(scriptobj, s)
%EVRISCRIPT_STEP/SUBSREF Enables methods in evriscript_step object
%I/O: value = scriptobj.field;
%  when (scriptobj) is an evriscript_step object this returns
%  the value (value) of the evriscript_step object field ('field') or
%  the result of the method named field.
%  This syntax is used for the following fields:
%    scriptversion
%    step_keyword
%    properties
%    step_module
%    step_required
%    step_inputs
%
%  or methods:
%    execute
%    factoryoptions
%    display
%    clone

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if strcmp(s(1).type,'()')
  varargout = {scriptobj};
  return
end
if ~strcmp(s(1).type,'.')
  error('This type of indexing not allowed on evriscript_step object')
end

%get list of outputs
if ~isempty(scriptobj.step_mode);
  outputs = scriptobj.step_module.outputs.(scriptobj.step_mode);
else
  outputs   = struct2cell(scriptobj.step_module.outputs);
  outputs   = [outputs{:}];
end
if isempty(scriptobj.variables)
  scriptobj.variables = struct([]);
end

%look for what the user was asking for
subsval = s(1).subs;
switch subsval
  case 'properties'
    varargout{1} = scriptobj.variables;
    
  case 'factoryoptions'
    varargout{1} = scriptobj.step_module.options;
    
  case 'options'
    %get options
    varargout{1} = scriptobj.options;
    
  case 'step_required'
    if isempty(scriptobj.step_mode)
      error('Cannot show required properties when "step_mode" is unassigned')
    end
    varargout{1} = scriptobj.step_module.required.(scriptobj.step_mode);

  case 'step_optional'
    if isempty(scriptobj.step_mode)
      error('Cannot show optional properties when "step_mode" is unassigned')
    end
    varargout{1} = scriptobj.step_module.optional.(scriptobj.step_mode);

  case 'step_inputs'
    varargout{1} = scriptobj.step_module.inputs;

  case 'step_outputs'
    varargout{1} = outputs;    
    
  case 'step_modes'
    
    varargout{1} = scriptobj.step_module.modes;

  case fieldnames(scriptobj)
    varargout{1} = scriptobj.(subsval);
    
  case fieldnames(scriptobj.variables)
    varargout{1} = scriptobj.variables.(subsval);
    
  case scriptobj.step_module.inputs
    %NOTE! got here because the specified value is an input, but it is
    %unassigned as of yet. (if it has been assigned, the above case will
    %catch it). So return empty.
    varargout{1} = [];
    
  case outputs
    %NOTE! got here because the specified value is an OUTPUT, but it is
    %unassigned as of yet. (if it has been assigned, the above case will
    %catch it).
    error('This property is not assigned because the step has not yet been executed.')
    
  case {'execute'}
    if length(s)==2 & strcmp(s(2).type, '()') & ~isempty(s(2).subs)
      if iscell(s(2).subs)
        newmode = char(s(2).subs);
      else
        newmode = s(2).subs;
      end
      s = s([1 3:end]);  %drop item 2
    else
      newmode = '';
    end
%     try
      scriptobj = execute(scriptobj,newmode);
%     catch
%       error(lasterr)
%     end
    
    if nargout==0
      try%The inputname function may not work in 15b or newer.
        assignin('caller',inputname(1),scriptobj);
      catch
        error(['Object could not be assigned back into workspace. Use output in call, example:   myscript = myscript.execute'])
      end
      varargout = {};
    else
      varargout{1} = scriptobj;
    end
    
  case {'display' 'disp'}
    mode = 0;
    if length(s)>1
      if strcmp(s(2).type,'()')
        mode = s(2).subs{1};
        s = s([1 3:end]);  %drop item 2
      else
        error('Invalid mode for display command')
      end
    end
    disp(scriptobj,mode);
    
  case {'clone'}
    varargout{1} = clone(scriptobj);
    
  case methods(scriptobj)
    if nargout>0;
      [varargout{1:nargout}] = feval(subsval,scriptobj);
    else
      varargout{1} = feval(subsval,scriptobj);
    end

  otherwise
    error('Undefined function or method ''%s'' for input arguments of type ''evriscript_step''.',subsval)
end

% need to only do this if all the s.type are '.'
if length(s)>1 & ~isempty(varargout)
  varargout{1} = subsref(varargout{1},s(2:end));
end


