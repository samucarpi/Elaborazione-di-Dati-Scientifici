function updaterows(obj)
%ETABLE/UPDATEROWS Update rows with current obj settings.


% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get Java table.
jt = obj.java_table;

if ~isempty(obj.row_height)
  jt.setRowHeight(obj.row_height)
end

%Change labels.
mydata = obj.data;

%Get row names.
[rowhead, rowheaders] = getrowlabels(obj);

%Turn off row headers.
if strcmp(obj.ds_use_row,'off')
  %Add row labels with custom row header table. Not sure of the best way to
  %do this so here's my hack.
  
  %   mydata = obj.data;
  %   mylavels = [];
  %
  %   if isdataset(mydata)
  %
  %     mylabels = str2cell(mydata.label{1,1});
  %     if ~isempty(mylabels)
  %       %FIXME: This doesn't really work. Was using UitablePeer to create a
  %       %table quickly so I didn't have to loop though large label list. Not
  %       %sure how to do that fast.
  %       parent_scroll_pane = jt.getParent.getParent();
  %       row_model = javax.swing.table.DefaultTableModel;
  %       rownum = length(mylabels);
  %       row_model.setRowCount(rownum);
  %       row_model.setColumnCount(1);
  %       table_h= com.mathworks.hg.peer.UitablePeer(row_model);
  %       table_h.setData(mylabels);
  %       parent_scroll_pane.setRowHeaderView(table_h.getTable)
  %     end
  %   end
  
else
  
  %   %FIXME: This is just test code to manipulate row header.
  %   parent_scroll_pane = jt.getParent.getParent();
  %   rowviewport = jt.getParent.getParent.getRowHeader;
  %   %Set rowheader width.
  %   rowdim = rowviewport.getPreferredSize;
  %   rowdim.width = 1;
  %   rowviewport.setPreferredSize(rowdim);
  %   parent_scroll_pane.revalidate;
  
end


% Rough Code examples

%Add a new row header table. This doesn't work well but it's possible:
% rt_new = com.mathworks.mwswing.MJTable(10,1)
% rt_new.setValueAt(1,1,0)
% rt_new.setValueAt(5,1,0)
% rt_new.setValueAt(8,2,0)
% rt_new.setValueAt(90,3,0)
% parent_scroll_pane.setRowHeaderView(rt_new)
