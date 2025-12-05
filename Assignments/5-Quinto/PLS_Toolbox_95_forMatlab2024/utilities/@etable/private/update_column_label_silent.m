function obj = update_column_label_silent(obj)
%ETABLE/update_column_label_silent Update colum labels in table via column model.
%  Normal updatetable function uses matlab object and overwrites custom
%  cell renderers. 

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get Java table.
jt = obj.java_table;

columnheaders = obj.column_labels;
for i = 1:length(columnheaders)
  jt.getColumnModel.getColumn(i-1).setHeaderValue(columnheaders{i});
end

%Need to do something to get things to render.
jt.getParent.getParent.repaint
drawnow
