function out = subsref(obj,subindex)
%EVRIGUI/SUBSREF Overload for EVRIGUI object.

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

validmethods = {'disp' 'close' 'isvalid'};
  
if ~strcmp(subindex(1).type,'.') 
  error('Invalid indexing for EVRIGUI object')
end

if ~isvalid(obj)
  if strcmp(subindex(1).subs,'create')
    obj = evrigui(obj.type);
    return
  elseif strcmp(subindex(1).subs, 'isvalid')
    out = false;
    return
  elseif strcmp(subindex(1).subs, 'display')
    out = disp(obj);
    return
  else
    error('EVRIGUI object is not valid')
  end
end

try
  %process request
  key = subindex(1).subs;
  if ismember(key,validmethods)
    %requested a method using indexing
    if nargout==0
      feval(subindex(1).subs,obj);
    else
      out = feval(subindex(1).subs,obj);
    end
    if length(subindex)>1
      out = subsref(out,subindex(2:end));
    end
    return
  else
    %requested a field, see if we can give it
    switch key
      case {'handle' 'type'}
        out = obj.(key);
        if length(subindex)>1
          out = subsref(out,subindex(2:end));
        end

      case 'interface'
        out = obj.(key);
        if length(subindex)>1
          out = subsref(out,subindex(2:end),obj);
        end

      otherwise
        %assume this is a call into the interface
        out = subsref(obj.interface,subindex,obj);

    end
  end
catch
  rethrow(lasterror);
end

