function [mynodes, mypaths, myvalues] = getselected(obj)
%EVRITREE/GETSELECTED Get selected nodes and paths.

% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get tables.
mynodes = evrijavamethodedt('getSelectedNodes',obj.tree);
mypaths = evrijavamethodedt('getSelectionPaths',obj.java_tree);

myvalues = [];

for i = 1:length(mynodes)
  myvalues = [myvalues; {mynodes(i).getValue}];
end
