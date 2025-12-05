function [t,c] = testobj(varargin)
%ETABLE/TESTOBJ Test script for etable object.

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Basic data and call.
data = round(rand(10)*10);
lbls = {'AA' 'BB' 'CC' 'EE' 'FF' 'GG' 'HH' 'II' 'JJ' 'KK'};

%Change fonts.
mytbl = etable(data,lbls);
mytbl.table_fontsize = 16;
mytbl.table_fontstyle = 'bold';
mytbl.table_fontname  = 'courier';

%Delete
delete(mytbl)

%Create with custom cell renderer on and change colors.
mytbl = etable(data,lbls,'custom_cell_renderer','on','cell_click_selection','row');
setbackground(mytbl,'cell',[1 1],'red')
setbackground(mytbl,'cell',[2 2],'blue')
setbackground(mytbl,'row',3,'green')
setbackground(mytbl,'column',4,[1 1 0])

%Adjust row header width.
mytbl.row_header_width = 70;
mytbl.row_header_text = 'PC';
mytbl.row_header_text = '';
delete(mytbl)

%Test callbacks.
mytbl = etable(data,lbls,...
  'table_clicked_callback',{'disp','table click'},...
  'table_doubleclicked_callback',{@disp,'table double click'},...
  'table_mousepressed_callback',{@disp,'table mouse pressed'},...
  'row_clicked_callback',{@disp,'row click'},...
  'row_doubleclicked_callback',{@disp,'row double click'},...
  'column_clicked_callback',{@disp,'column click'},...
  'column_doubleclicked_callback',{@disp,'column double click'},...
  'data_changed_callback',{@disp,'data changed'},...
  'selection_changed_callback',{@disp,'selection changed'});

%Callbacks sometimes not added before table is rendered so run again.
addcallbacks(mytbl)
%Try adding row selection.
delete(mytbl)

%Test with parent.
f = figure;
mytbl = etable('parent_figure',f,'tag','ssqtable','row_header_width',70,...
  'autoresize','AUTO_RESIZE_ALL_COLUMNS','custom_cell_renderer','on');
delete(mytbl)

%Test formatting.
data = rand(4,4)*1000;
lbls = {'AA' 'BB' 'CC' 'EE'};
mytbl = etable(data,lbls,'column_format',{'%6.2f' '' '%2.2g' '%-5.2f'});

data = num2cell(data);
data{1,2} = [];
mytbl.data = data;

setcolumnwidth(mytbl,1,300)
setselection(mytbl,'cells',[2 3])
settablealignment(mytbl,'center')

delete(mytbl)

%Test two tables.
f = figure;
mytbl = etable('data',data,'column_labels',lbls,'parent_figure',f,'tag','table1');
mytbl2 = etable('data',rand(4),'column_labels',lbls(1:4),'parent_figure',f,'tag','table2');

%TODO: this doesn't work, need funciton call not indexing.
%I thihk I had the number of labels wrong here. Seems to work now with just
%4 new column labels.
mytbl2.data_silent = data;
mytbl2.column_label_silent = str2cell(char([65:68])')';

delete(mytbl)

data = round(rand(10)*10);
lbls = {'AA' 'BB' 'CC' 'EE' 'FF' 'GG' 'HH' 'II' 'JJ' 'KK'};

%Test bollean cell render.
data = num2cell(data);
data(:,1) = repmat({false},10,1);
mytbl = etable('data',data,'column_labels',lbls,'column_format',{'bool'},'custom_cell_renderer','on');

%Mixed data types.
data = {'a' 'b' 2; 1 2 'c'};
lbls = {'AA' 'BB' 'CC'};
mytbl = etable('data',data,'column_labels',lbls);
jt = mytbl.java_table
%Change editor.
edit_cmb = javaObjectEDT('javax.swing.JComboBox', {'Select 1' 'Select 2' 'b' 'c'});

jt.getColumnModel.getColumn(2).setCellEditor(javax.swing.DefaultCellEditor(edit_cmb))


%Link tables.
f = figure;
mytbl = etable('data',data,'column_labels',lbls,'parent_figure',f,'tag','table1');
data = round(rand(10)*10);
mytbl2 = etable('data',data,'column_labels',lbls,'parent_figure',f,'tag','table2');
mytbl.position = [.01 .01 .97 .48];
mytbl2.position = [.01 .51 .97 .48];

sp1 = mytbl.getscrollpane;
sp2 = mytbl2.getscrollpane;

sp1.getVerticalScrollBar.setModel(sp2.getVerticalScrollBar.getModel);

jt1 = mytbl.java_table;
jt2 = mytbl2.java_table;

jt2.setColumnModel(jt1.getColumnModel);


