function delete(varargin)
%EVRITREE/DELETE Delete object.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = [];
for i = 1:nargin
  if strcmp(class(varargin{i}),'evritree')
    obj = varargin{i};
  end
end

if ~isempty(obj)
  if ishandle(obj.tree)
    %Remove callbacks (might help with mem leak). 
    addcallbacks(obj,1)
    jt = obj.java_tree;
    rt = jt.getRoot;
    delete(rt);
    delete(jt);
    %Delete tree handle.
    delete(obj.tree)
    drawnow
  end
  
  if ishandle(obj.parent_figure)
    %Remove object from figure appdata.
    setappdata(obj.parent_figure,obj.tag,[]);
  end
end
