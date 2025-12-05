function setobj(obj)
%ETABLE/SETOBJ Save object to appdata of table.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if ishandle(obj.parent_figure)
  setappdata(obj.parent_figure,obj.tag,obj);
end


