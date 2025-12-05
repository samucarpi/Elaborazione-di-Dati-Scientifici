function delete(varargin)
%ETABLE/DELETE Delete object.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = [];
for i = 1:nargin
  if strcmp(class(varargin{i}),'etable')
    obj = varargin{i};
  end
end

if ishandle(obj.table)
  %A java error occurs if table row header has label. Some ML java code
  %searches for the column with empty value so we need to set it back to
  %empty.
  clear(obj,'all');
  drawnow
  delete(obj.table)
  drawnow
end

if ~isempty(obj)
  if ishandle(obj.parent_figure)
    %Remove object from figure appdata.
    setappdata(obj.parent_figure,obj.tag,[]);
    
    %If figure was created by etable object then delete it.
    if strcmp(get(obj.parent_figure,'tag'),'etable_default_figure')
      delete(obj.parent_figure)
    end
  end
end
