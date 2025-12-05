function setselection(obj,target,myval)
%ETABLE/SETSELECTION Set selected rows, columns, or cells.
% target : {'rows' 'columns' 'cells'}

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get tables.
jt = obj.java_table;

if length(myval)==1
  myval(2) = myval;
end

myval = myval -1;

switch target
  case 'rows'
    jt.setRowSelectionInterval(myval(1),myval(2));
    jt.setColumnSelectionInterval(0,jt.getColumnCount-1);
  case 'columns'
    jt.setRowSelectionInterval(0,jt.getRowCount-1);
    jt.setColumnSelectionInterval(myval(1),myval(2));
  case 'cells'
    jt.setRowSelectionInterval(myval(1),myval(1));
    jt.setColumnSelectionInterval(myval(2),myval(2));
end
