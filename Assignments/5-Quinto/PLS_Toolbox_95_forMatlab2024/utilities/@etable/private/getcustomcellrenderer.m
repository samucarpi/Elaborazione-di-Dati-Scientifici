function mycellrenderer = getcustomcellrenderer(obj,mycolumn)
%ETABLE/GETCUSTOMCELLRENDERER Get custom cell renderer for given column.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%NOTE: This is a slow call so try to minimize calls to this in loops.

%Get Java table.
jt = obj.java_table;

mycellrenderer = [];

try
  %Check for cell renderer and set to new renderer if needed.
  mycellrenderer = jt.getColumnModel.getColumn(mycolumn-1).getCellRenderer;
  if ~strcmp(class(mycellrenderer),'CustomTableCellRenderer')
    mycellrenderer = evrijavaobjectedt('CustomTableCellRenderer');
    jt.getColumnModel.getColumn(mycolumn-1).setCellRenderer(mycellrenderer);
  end
catch
  evritip('tablecellrendererjava')
end
