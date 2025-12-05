function addproperty(obj,pname,pval)
%EVRITREE/ADDPROPERTY Add property field to tree.


% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get Java table.
jt = obj.java_tree;


%Create property for storying type of tree.
sp  = schema.prop(jt, pname, 'mxArray');
set(jt,pname,pval);
