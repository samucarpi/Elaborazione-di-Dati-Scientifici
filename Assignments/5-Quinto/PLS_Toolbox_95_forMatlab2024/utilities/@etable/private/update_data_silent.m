function obj = update_data_silent(obj)
%ETABLE/UPDATE_DATA_SILENT Update data in table via table model.
%  Normal updatetable function uses matlab object and overwrites custom
%  cell renderers.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%NOTE: To do a truely silent data update where no data change event is
%called you might be able to use model.setDataVector and model.getDataVector


%Get data and make it into cell array for uitable.
jt = obj.java_table;
m  = jt.getModel;

dat = getdata(obj);

%This property causes the table component to rebuild all the columns when a
%column is added to the table model. Even though we're not adding columns,
%try setting to false so custom renderers don't get destroyed, not sure if
%this will work.
%jt.setAutoCreateColumnsFromModel(false);

dsz = size(dat);
if dsz(1)~=m.getRowCount
  m.setRowCount(dsz(1));
end
if dsz(2)~=m.getColumnCount
  m.setColumnCount(dsz(2));
end

%No great way of updating data other than looping through and using
%setValueAt method.
dcfcn = get(obj.table,'DataChangedCallback');
set(obj.table,'DataChangedCallback',[])
try
  for i = 1:dsz(1)
    for j = 1:dsz(2)
      m.setValueAt(dat{i,j},i-1,j-1);
    end
  end
catch
  le = lasterr;
  set(obj.table,'DataChangedCallback',dcfcn);
  rethrow(le);
end
set(obj.table,'DataChangedCallback',dcfcn)

%Need to do something to get things to render.
jt.getParent.getParent.repaint
drawnow


