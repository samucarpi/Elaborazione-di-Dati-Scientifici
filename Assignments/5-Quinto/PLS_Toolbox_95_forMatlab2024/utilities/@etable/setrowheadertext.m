function setrowheadertext(obj)
%ETABLE/SETROWHEADERTEXT Set row header table text (text above row gutter).

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%NOTE: This causes java error if table is closed without text being set to ''.
%Too problematic to implement now so disable here. Remove the 'return' when
%ready to enable.
return
%Get Java table.
jt = obj.java_table;

parent_scroll_pane = evrijavaobjectedt(jt.getParent.getParent);
rowviewport = evrijavaobjectedt(jt.getParent.getParent.getRowHeader);
rowtable = evrijavaobjectedt(rowviewport.getComponent(0));
%getrenderer(rowtable);%%%DOES NOT WORK CORRECTLY, CAN"T SEEM TO GET BACKGROUND COLOR RIGHT, GOES TO WHITE. 
rowtable.getColumnModel.getColumn(0).setHeaderValue(java.lang.String(obj.row_header_text))

try
  parent_scroll_pane.repaint;%Won't show up unless we repaint for some reason.
end
%-----------------------------
function getrenderer(rowtable)
%Special case to add custom renderer to header column.

try
  %Check for cell renderer and set to new renderer if needed.
  mycellrenderer = rowtable.getColumnModel.getColumn(0).getHeaderRenderer;
  mybackground = rowtable.getColumnModel.getColumn(0).getBackground;
  if ~strcmp(class(mycellrenderer),'CustomTableCellRenderer')
    mycellrenderer = evrijavaobjectedt('CustomTableCellRenderer');
    rowtable.getColumnModel.getColumn(0).setHeaderRenderer(mycellrenderer);
  end
catch
  %No warning because this will likely be called in a loop.
end
