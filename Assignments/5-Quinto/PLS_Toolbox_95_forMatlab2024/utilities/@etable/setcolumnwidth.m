function setcolumnwidth(obj,column,width)
%ETABLE/SETCOLUMNWIDTH Set width of a column.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get Java table.
jt = obj.java_table;

if isempty(column)
  column = 1:jt.getColumnModel.getColumnCount;
end

for i = 1:length(column)
  %Add some column sizing.
  col = evrijavaobjectedt(jt.getColumnModel.getColumn(column(i)-1));
  %col.setMinWidth(width)
  col.setPreferredWidth(width);
  col.setWidth(width)
end
drawnow
