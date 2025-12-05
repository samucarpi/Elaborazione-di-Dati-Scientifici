function val = subsref(varargin)
%MAGNIFYTOOL/SUBSREF Retrieve fields of MAGNIFYTOOL objects.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = varargin{1};
index = varargin{2};
feyld = index(1).subs; %Field name.

if length(index)>1;
  switch feyld
    otherwise
      error(['Index error, can''t index into field: ' feyld '.'])
  end
  
else
  switch feyld
    case 'isvalid'
      if ishandle(obj.target_axis)&&~isempty(obj.patch_handle)&&ishandle(obj.patch_handle)&&ishandle(obj.display_axis)
        val = true;
      else
        val = false;
      end
    otherwise
      val = obj.(feyld);
  end
  
end
