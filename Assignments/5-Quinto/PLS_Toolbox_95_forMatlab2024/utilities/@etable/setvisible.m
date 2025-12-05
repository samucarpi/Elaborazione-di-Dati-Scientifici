function setvisible(obj,target,myval,mystate)
%ETABLE/SETVISIBLE Set visible rows, columns, or cells.
% target : {'rows' 'columns' 'cells'}
% NOTE: Only columns works for now.
% mystate : {'on' 'off'} Where 'on' is visible. 
%
% Works by shrinking column width to 0.
% 
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
    %Not done.
  case 'columns'
    mycol = jt.getColumnModel.getColumn(myval(1));
    if strcmp(mystate,'off')
      mycol.setMinWidth(0);
      mycol.setMaxWidth(0);
      mycol.setPreferredWidth(0);
    else
      mycol.setMinWidth(15);
      mycol.setMaxWidth(2.1475e+09);
      mycol.setPreferredWidth(75);
    end
  case 'cells'
    %Not done.
end
