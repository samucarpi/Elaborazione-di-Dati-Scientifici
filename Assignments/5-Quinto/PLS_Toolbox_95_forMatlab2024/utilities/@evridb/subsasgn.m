function obj = subsasgn(obj,index,val)
%EVRIDB/SUBSASGN Subscript assignment reference for evridb.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

feyld = index(1).subs; %Field name.

if length(index)>1 && ~strcmp(feyld,'arguments');
  error(['Index error, can''t assign into field: ' feyld '.'])
else
  switch feyld
    case 'type'
      %Fill in default driver and provider.
      obj = setdriverdefault(obj,val);
      obj.type = val;
    case 'arguments'
      %Index asignment into arguments. You can assign whole structure or
      %each value but not indexed sub-structure.
      if length(index)==1
        %Whole structure, test for name and value fields.
        fldnames = fieldnames(val);
        if length(fldnames) == 2 && all(ismember(fldnames,{'name','value'}))
          obj.arguments = val;
        else
          error(['Unrecognized structure for ''arguments'' must have only fields for .name and .value'])
        end
      elseif length(index)==2
        obj.arguments(index(2).subs{:}) = val;
      else
        %Indexing each value.
        %This code does not handle multi value subscripts may need to add that
        %functionality in future if there's a demand. Arguments are not widely used
        %currently.
        if strcmp(index(3).subs,'name')
          obj.arguments(index(2).subs{:}).name = val;
        elseif strcmp(index(3).subs,'value')
          obj.arguments(index(2).subs{:}).value = val;
        else
          error(['Unrecognized field for ''arguments'' must have only fields for .name and .value'])
        end
      end
      
      
    otherwise
      obj.(feyld) = val;
  end
  
end


