function addcolumnsorting(obj)
%ETABLE/ADDCOLUMNSORTING Add sorting menu items to right-click menu.
% Also add other menu items.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get Java table.
jt = obj.java_table;

%Add column sorting if needed.
if strcmp(obj.column_sort,'on')
  %Add sorting to context menu.
  mymenu = evrijavaobjectedt(get(jt,'RowHeaderPopupMenu'));
  
  %Add menu items.
  sa = evrijavaobjectedt('com.mathworks.mwswing.MJMenuItem');
  sa.setText('Sort Ascending');
  sd = evrijavaobjectedt('com.mathworks.mwswing.MJMenuItem');
  sd.setText('Sort Descending');
  mymenu.add(javax.swing.JSeparator);
  mymenu.add(sa);
  mymenu.add(sd);
  % Assign menu callbacks
  set(handle(sa,'callbackproperties'),'ActionPerformedCallback',{@sortTable_callback,obj.parent_figure,obj.tag,'ascend'})
  set(handle(sd,'callbackproperties'),'ActionPerformedCallback',{@sortTable_callback,obj.parent_figure,obj.tag,'descend'}) 
elseif strcmp(obj.column_sort,'builtin')
  %This doesn't work for data when it's formatted strings and not numeric.
  if checkmlversion('>','7.5')%Greater than 2007b
    jt.setAutoCreateRowSorter(true);
    jt.setUpdateSelectionOnSort(true);
  end
end

if strcmp(obj.copy_all,'on')
  %Add sorting to context menu.
  mymenu = evrijavaobjectedt(get(jt,'RowHeaderPopupMenu'));
  
  %Add menu items.
  sa = evrijavaobjectedt('com.mathworks.mwswing.MJMenuItem');
  sa.setText('Copy All');
  mymenu.add(sa);
  % Assign menu callbacks
  set(handle(sa,'callbackproperties'),'ActionPerformedCallback',{@copy_callback,obj.parent_figure,obj.tag,'all'})
end
