function varargout = subsref(obj, s)
%EVRISCRIPT/SUBSREF Enables methods in evriscript object
%I/O: value = obj.field;
%  when (obj) is an evriscript object this returns
%  the value (value) of the evriscript object field ('field') or
%  the result of the method named 'field'.
%  This syntax is used for the following fields:
%    script_chainversion
%    step_keyword
%    label
%    steps
%  or methods:
%    add(evriscript_step); add(evriscript_step, position)
%    delete(position)
%    swap(position1, position2)
%    reference(fromStep,fromProperty,toStep,toProperty)  %create property reference
%    validate
%    execute
%    summarize


%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Enable c(2).field, where 'field' is a valid suffix for an evriscript_step object
if strcmp(s(1).type,'()')
  indices = s(1).subs;
  indices = [indices{:}];
  theSteps = obj.steps;
  if length(indices)>1
    steps = [theSteps{indices}];
  else
    steps = theSteps{indices};
  end
  varargout{1} = steps;
  if length(s)>1 & ~isempty(varargout)
    varargout{1} = subsref(varargout{1},s(2:end));
  end
  return
end

% If not () type, then it must be . type
if ~strcmp(s(1).type,'.')
  error('Invalid indexing for evriscript object');
end

mth = setdiff(methods(obj),{'subsref'});
validmethods = [mth(:)];

subsval = s(1).subs;
switch subsval
  case {'steps' 'step'}
    varargout{1} = obj.steps;
    if length(s)>1 & strcmp(s(2).type,'()') & length(s(2).subs{1})==1
      s(2).type = '{}';  %extract items from cell array 
    elseif length(obj.steps)==1
      varargout{1} = obj.steps{1};
    end
    
  case fieldnames(obj)
    varargout{1} = obj.(subsval);
    
  case {'add' 'delete' 'swap' 'reference'}
    if length(s)>1 & strcmp(s(2).type, '()')
      val = s(2).subs;
      s = s([1 3:end]); %drop step 2
    else
      val = {};
    end
    obj = feval(subsval,obj,val{:});
    if nargout==0
      try%The inputname function may not work in 15b or newer.
        assignin('caller',inputname(1),obj);
      catch
        error(['Object could not be assigned back into workspace. Use output in call, example:   myscript = myscirpt.add(''pca'')'])
      end
    else
      varargout{1} = obj;
    end
       
  case {'summarize'}
    idetail = 0;
    if length(s)>1 & strcmp(s(2).type, '()')
      idetail = s(2).subs;
      idetail = idetail{1};
      if isempty(idetail) | ~isnumeric(idetail)
        error('Level of detail (%i) must be a non-negative integer.', idetail);
      end
      s = s([1 3:end]); %drop step 2
    end
    summarize(obj, idetail);
    
  case {'execute'}
    obj = execute(obj);
    
    if nargout==0
      try%The inputname function may not work in 15b or newer.
        assignin('caller',inputname(1),obj);
      catch
        error(['Object could not be assigned back into workspace. Use output in call, example:   myscript = myscript.execute'])
      end
    else
      varargout{1} = obj;
    end
    
  case {'display' 'disp'}
    disp(obj);
    
  case {'validate'}
    varargout{1}  = validate(obj);
    
  case validmethods
    if nargout>0;
      [varargout{1:nargout}] = feval(subsval,obj);
    else
      varargout{1} = feval(subsval,obj);
    end
    
  otherwise
    if length(obj.steps)==1
      if nargout>0;
        [varargout{1:nargout}] = subsref(obj.steps{1},s);
      else
        varargout{1} = subsref(obj.steps{1},s);
      end
      return
    else
      error('Step to retreive must be specified when assigning to multi-step scripts. Method or property ''%s'' unrecognized for type ''evriscript''.',subsval)
    end
end

% need to only do this if all the s.type are '.'
if length(s)>1 & ~isempty(varargout)
  varargout{1} = subsref(varargout{1},s(2:end));
end

