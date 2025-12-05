function val = subsref(varargin)
%ESLIDER/SUBSREF Retrieve fields of ESLIDER objects.

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = varargin{1};
index = varargin{2};
feyld = index(1).subs; %Field name.

if length(index)>1;
  switch feyld
    case 'position'
      val = obj.position(index(2).subs{:});
    otherwise
      error(['Index error, can''t index into field: ' feyld '.'])
  end
  
else
  switch feyld
    case 'isvalid'
      if ishandle(obj.axis)&&ishandle(obj.patch)
        val = true;
      else
        val = false;
      end
    otherwise
      val = obj.(feyld);
  end
  
end

