function thisdata = getselecteddata(obj)
%ETABLE/GETSELECTEDDATA Get selected data.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get tables.
jt = obj.java_table;
clms = double(jt.getSelectedColumns+1);
rws  = double(jt.getSelectedRows+1);

mydata = obj.data;
thisdata = mydata(rws(:),clms(:));

