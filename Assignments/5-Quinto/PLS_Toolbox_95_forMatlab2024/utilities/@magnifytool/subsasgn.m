function obj = subsasgn(obj,index,val)
%MAGNIFYTOOL/SUBSASGN Subscript assignment reference for MAGNIFYTOOL.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

feyld = index(1).subs; %Field name.

if length(index)>1;
  error(['Index error, can''t assign into field: ' feyld '.'])
else
  switch feyld
    case ''
      
    otherwise
      obj.(feyld) = val;
  end
  
end

if ~isempty(obj.display_axis)
  %Save to parent figure if possible.
  setappdata(obj.display_axis,'magnifytool',obj);
end
