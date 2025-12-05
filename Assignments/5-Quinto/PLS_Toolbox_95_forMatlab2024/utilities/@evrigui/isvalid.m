function out = isvalid(obj)
%EVRIGUI/ISVALID Overload for EVRIGUI object.

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

out = false;
if ishandle(obj.handle)
  if strcmp(get(obj.handle,'tag'),expectedtag(obj.interface,obj))
    out = true;
  end
end

  
