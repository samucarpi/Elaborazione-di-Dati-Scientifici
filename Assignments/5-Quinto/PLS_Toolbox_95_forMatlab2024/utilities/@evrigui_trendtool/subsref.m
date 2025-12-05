function out = subsref(obj,subindex,parent,varargin)
%EVRIGUI_fcn/SUBSREF Overload for EVRIGUI GUI object.

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

  
if nargin<3 | ~isa(parent,'evrigui')
  error('Access to %s interface only permitted when attached to parent EVRIGUI object',class(obj));
end

if ~strcmp(subindex(1).type,'.') 
  error('Invalid indexing for object')
end

key = subindex(1).subs;
if ismember(key,validmethods(obj))
  %requested a method using indexing
  
  if strcmp(key,'close')
    %redirect "close" to parent object
    parent.close;
    out = 1;
    return
  end
  
  %check for additional input parameters (as (...) input)
  args = {};
  if length(subindex)>=2
    if strcmp(subindex(2).type,'()')
      args = subindex(2).subs;
      subindex = subindex(3:end);
    else
      subindex = subindex(2:end);
    end
  else
    subindex = [];
  end
  
  %call method
  if nargout==0
    feval(key,obj,parent,args{:});
  else
    out = feval(key,obj,parent,args{:});
    if ~isempty(subindex)
      out = subsref(out,subindex);
    end
  end
  return
  
else
  %requested a field, see if we can give it
  switch key
    case {}
      out = obj.(key);
      if length(subindex)>1
        out = subsref(out,subindex(2:end));
      end
    otherwise
      error('Invalid property or method call.')
  end  
end
