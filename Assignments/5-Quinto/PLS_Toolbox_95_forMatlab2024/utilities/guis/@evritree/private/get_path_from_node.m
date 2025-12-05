function out = get_path_from_node(obj,mynode)
%EVRITREE/GET_PATH_FROM_NODE Get text (Name) path to a node. 
%  Use name value so tree can traverse to same path after an update.

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NOTE: Save text path instead of java object (as was done before) to
%prevent possible memory leak.

out = [];
if isempty(mynode) || mynode(end).isRoot
  return
end

%Walk up last tree pos and creat a path.
mysteps = char(mynode.getName);
mynode = mynode.getParent;
while ~mynode.isRoot
  mysteps = [char(mynode.getName) obj.path_sep mysteps];
  mynode = mynode.getParent;
end
out = mysteps;

