function updatetable(obj)
%ETABLE/UPDATETABLE Update table data.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get table.
mytable = obj.table;

%Get data.
mydata = getdata(obj);

%NOTE: Use update_data_silent(obj) to change data without firing datachange
%callback.

mytable.setData(mydata);
drawnow


