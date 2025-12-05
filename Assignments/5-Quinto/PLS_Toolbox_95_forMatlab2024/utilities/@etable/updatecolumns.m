function updatecolumns(obj)
%ETABLE/UPDATECOLUMNS Update column header labels.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get tables.
mytable = obj.table;
jt = obj.java_table;

%Change labels.
mydata = obj.data;

clbls = {};
if isdataset(mydata) && strcmp(obj.ds_use_col,'on')
  %Try and pull column labels out of dso.
  clbls = str2cell(obj.data.label{2,1})';
end

%Get column names.
columnheaders = getcolumnlabels(obj);

if strcmp(obj.add_row_labels,'on')
  %Insert column of labels.
  [rhead, rowlbls] = getrowlabels(obj);
  columnheaders = [rhead columnheaders];
end

curheaders = cell(mytable.getColumnNames);
if length(columnheaders)<length(curheaders)
  %Fill existing with blank (space char) otherwise will throw java error.
  columnheaders = [columnheaders repmat({' '},1,length(curheaders)-length(columnheaders))];
elseif length(columnheaders)>length(curheaders)
  %Table will automatically get bigger.
  
end

mytable.setColumnNames(columnheaders);

