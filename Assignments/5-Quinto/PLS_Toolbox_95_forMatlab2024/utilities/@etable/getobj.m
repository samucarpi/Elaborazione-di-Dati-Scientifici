function obj = getobj(obj)
%ETABLE/GETOBJ Get object to appdata of table.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if ishandle(obj.parent_figure)
  obj = getappdata(obj.parent_figure,obj.tag);
end
