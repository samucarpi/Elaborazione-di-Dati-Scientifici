function obj = get_evritree_obj(obj,tag)
%EVRITREE/GET_EVRITREE_OBJ Get object to appdata of table.
% Get object from figure handle and tag or object.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%For some reason we need to have getter function in private folder, doesn't
%seem to work in main folder.

if ~isempty(obj)
  if strcmpi(class(obj),'evritree')
    if ishandle(obj.parent_figure)
      obj = getappdata(obj.parent_figure,obj.tag);
    end
  else
    if nargin<2;
      tag = 'evritree';
    end
    obj = getappdata(obj,tag);
  end
end
