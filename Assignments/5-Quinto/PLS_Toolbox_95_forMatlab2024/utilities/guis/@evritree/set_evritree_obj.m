function set_evritree_obj(obj)
%EVRITREE/SET_EVRITREE_OBJ Save object to appdata of tree.

% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if ishandle(obj.parent_figure)
  setappdata(obj.parent_figure,obj.tag,obj);
end


