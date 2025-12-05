function obj = checktarget(obj)
%MAGNIFYTOOL/CHECKTARGET Check target axis, delete tool if axis has changed.
% Change detection is based on limits, see note below.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Check target.
if isempty(obj.target_axis)||~ishandle(obj.target_axis)
  ax = findobj(obj.parent_figure,'type','axes','tag','');
  if ~isempty(ax) && length(ax)>1
    ax = [];
  end
else
  ax = obj.target_axis;
end
  
if isempty(ax)
  delete(obj)
  obj = [];
  return
end

%TODO: No good way to tell if plot has changed underlying data so just try
%to keep going.

obj.target_axis = ax;


