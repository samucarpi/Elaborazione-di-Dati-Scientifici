function refresh(obj,leafloc)
%EVRITREE/REFRESH Refresh children of a node.
% If 'leafloc' not given the refreshes current selected node. If 'leafloc'
% given then uses expandtoleaf to go to location and refresh.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = get_evritree_obj(obj);
jt  = obj.java_tree;
%Get model.
tm = jt.getModel;

if nargin<2 | isempty(leafloc)
  %Get current node.
  currentnode = evrijavamethodedt('getLastSelectedPathComponent',jt);
else
  currentnode = expandtoleaf(obj,leafloc);
end

if currentnode.isLeafNode
  %No children to refresh.
  return
end

if ~isempty(currentnode)
  nodevalue = currentnode.getValue;
else
  return
end

%Get new node.
newnodes = node_expand_callback(obj.tree, nodevalue, obj.parent_figure, obj.tag);
%Remove all children.
currentnode.removeAllChildren;

for i = 1:length(newnodes)
  currentnode.add(newnodes(i));
  %For reference you can also insert using:
  % obj.tree.Model.insertNodeInto(newNode,selNode,selNode.getChildCount());
  %This could more efficient if we know exactly what's being created (i.e.,
  %adding a model to the cache).
end

%Let model know there were changes and refresh the view.
evrijavamethodedt('nodeStructureChanged',tm,currentnode);


