function tableCallback(obj,jobj,ev,varargin)
%TABLECALLBACK Callback for interaction with table.
%

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mytbl = obj.mainTable;
tbldata = mytbl.data;
myrow = getselection(mytbl,'rows');
mymodel = tbldata{myrow,end};
obj.setModelTo(mymodel);
updateWindow(obj);

end

