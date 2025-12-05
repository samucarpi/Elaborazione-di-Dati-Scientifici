function x=subsasgn(x,index,val)
%EVRISCRIPT_MODULE/SUBSASGN Enables methods in evriscript_module object
%Fields 'label', 'axisscale', 'title', and 'class' can not be set if 'data'
%is empty. Once field 'data' has been filled it can not be "set" to a different size.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

nnargin = nargin;
error(nargchk(3,3,nnargin));   %give error if nargin is not appropriate

if isempty(index); error('Invalid subscripting'); end;

if ~strcmp(index(1).type,'.');
  error('Assignment subscripting not permitted on main evriscript_module object');
else
  fld1=lower(index(1).subs);
end;

if x.lock
  error('Module is locked - cannot assign values')
end

argset2 = {'required', 'optional' 'outputs'};  %same sub-fields as command and MUST be cell
argset3 = {'command', 'required', 'optional' 'outputs'}; %must have sub-field
if nnargin==3
  if ~ischar(fld1)
    error('Not valid evriscript_module object field.')
  end
  
  if length(index)==1 
    if ismember(fld1,argset3)
      error('Cannot assign the ''%s'' field directly. Identify mode sub-field.', fld1);
    else
      x.(fld1) = val;
    end
  elseif length(index)==2
    if ~strcmp(index(2).type,'.');
      error('Assignment subscripting not permitted on evriscript_module ''%s'' object', fld1);
    else
      fld2=lower(index(2).subs);
    end;
    
    if ismember(fld1,{'command'}) & ~(ischar(val))
      error(['  Value must be class char for field ''' fld1 '''.'])
    end
    if ~ismember(fld1,{'options' 'default'}) & ~(ischar(val) | iscell(val))
      error(['  Value must be class char or cell for field ''' fld1 '''.'])
    end
    
    % Check prerequesites first - if in argset2 then command.fld2 must already exist
    if ismember(fld1,argset2) & ~isfield(x.command, fld2)
      error('''command'' must contain field (''%s'') before it can be added to ''%s''.', fld2, fld1)
    elseif ismember(fld1,argset2) & (~iscell(val) | ~all(cellfun('isclass',val,'char')))
      error('Property for field ''%s'' must be a cell array of strings.',fld1)
    else
      if isempty(x.(fld1)) & isstruct(x.(fld1))
        %if empty structure, assign using "struct" to avoid error
        x.(fld1) = struct(fld2,{val});
      else  %already filled or non-structure - use standard assignment
        x.(fld1).(fld2) = val;   % set the field
      end
    end
      
  else
    error('Invalid assignment subscripting on evriscript_module ''%s'' object', fld1);
  end
  
  % Other specific checks and sets to make when setting  evriscript_module.(fld1).(fld2)
  switch fld1        
    case 'command'
      % Must also create empty fld2 in 'required', 'optional', 'default', if it does not exist
      for target=argset2
        if  ~isfield(x.(char(target)), fld2)
          if isempty(x.(char(target))) & isstruct(x.(char(target)))
            %if empty structure, assign using "struct" to avoid error
            x.(char(target)) = struct(fld2,{{}});   % set the field
          else  %already filled or non-structure - use standard assignment
            x.(char(target)).(fld2) = {};   % set the field
          end          
        end
      end

    case 'description'
      if ~(ischar(val) | iscell(val))
        error('Value must be class char or cell for field ''description''.')
      elseif iscell(val) & size(val,2)>1
        error('Cell input must be size 1x1 for field ''description''.')
      else
        if iscell(val)
          val    = char(val{:});
        end
        x.description = val;
      end
  end
end
