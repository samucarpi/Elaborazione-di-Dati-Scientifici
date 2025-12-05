function x=subsasgn(x,index,value)
%EVRISCRIPT/SUBSASGN Assign for evriscript objects using Structure and index notation.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Usage x.fld1 = value; or x.fld1.fld2 = value;
% Sets the 'fld1' field for a evriscript object to (value).
% If 'fld1' is not a field of evriscript then sets the x.variables.fld1 = value.
% If 'fld1' = 'options' then sets
%    x.options.fld2 = value, provided 'fld2' is already a field of x.options,
%    and opens error dialog otherwise.
%I/O: x.fld1 = value;
%I/O: x.fld1.fld2 = value;

nnargin = nargin;
error(nargchk(3,3,nnargin));   %give error if nargin is not appropriate

if isempty(index); error('Invalid subscripting'); end;

if strcmp(index(1).type,'()')
  if length(index)>=2
    % e.g.: c(2).ncomp = 55;
    %setting of PROPERTIES is ok if the lock is set (note: step locks will
    %be set when top-level lock is also on)
    sub1 = index(1).subs;
    ic = sub1{1};
    isIndexValidForCellArray(ic, x.steps)
    x.steps{ic} = subsasgn(x.steps{ic}, index(2:end), value);   % get the step to change
  elseif length(index)==1
    % e.g.: c(2) = step;
    checklock(x);
    thesteps = x.steps;
    ic = index(1).subs{1};
    
    if isempty(value)
      %delete of item
      x = delete(x,ic);
    elseif ic==length(thesteps)+1
      %adding a step to the end
      x = add(x,value);
    else
      %if not adding a step to the end
      isIndexValidForCellArray(ic, thesteps)
      x = add(x,value,ic);
      x = delete(x,ic+1);
    end
  else
    error('Assignment is not permitted on evriscript object using this subscripting (length(index) = %d)', length(index));
  end
  
  if nargout==0
    try%The inputname function may not work in 15b or newer.
      assignin('caller',inputname(1),x)
      clear x
    catch
      error(['Object could not be assigned back into workspace. Use output in call, example:   myscript = myscirpt.add(''pca'')'])
    end
  end
    
  
  return;
elseif strcmp(index(1).type,'.')
  fld1 = lower(index(1).subs);
  switch fld1
    case 'label'
      checklock(x);
      x.label = value;
    case 'lock'
      checklock(x);
      x.lock = value;
    otherwise
      if length(x.steps)==1
        %only one step? assume we're attempting to assign to that step
        x.steps{1} = subsasgn(x.steps{1},index,value);
        if nargout==0
          try%The inputname function may not work in 15b or newer.
            assignin('caller',inputname(1),x)
            clear x
          catch
            error(['Object could not be assigned back into workspace. Use output in call, example:   myscript = myscirpt.add(''pca'')'])
          end
        end        
        return
      else
        error('Step to modify must be specified when assigning to multi-step scripts. Method or property ''%s'' unrecognized for type ''evriscript''.',fld1)
      end
  end
else
  error('Assignment type %s not permitted on evriscript object', index(1).type);
end

%--------------------------------------------------------------
function checklock(x)
if x.lock
  error('Script is locked and cannot be modified')
end
