function myselection = getselection(obj,target)
%ETABLE/GETSELECTION Get selected rows, columns, or cells.
% target : {'rows' 'columns' 'cells'}

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get tables.
jt = obj.java_table;

myselection = [];

switch target
  case 'rows'
    myselection = double(jt.getSelectedRows+1);
  case 'columns'
    myselection = double(jt.getSelectedColumns+1);
  case 'cells'
    myselection = [];
    for j = double(jt.getSelectedColumns+1)'
      for i = double(jt.getSelectedRows+1)'
        myselection = [myselection sub2ind([jt.getRowCount jt.getColumnCount],i,j)];
      end
    end
end
