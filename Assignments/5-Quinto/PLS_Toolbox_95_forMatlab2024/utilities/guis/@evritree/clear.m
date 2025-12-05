function clear(obj)
%EVRITREE/CLEAR Clear the tree.
% Set data to [] and update the root node.

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

obj = get_evritree_obj(obj);
obj.tree_data = [];
updatetree(obj);
set_evritree_obj(obj)
