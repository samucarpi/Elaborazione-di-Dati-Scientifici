function update(obj)
%EVRITREE/UPDATE Update tree data.

% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

% Rebuild tree???

% Rebuild root node from updated data.
mt  = obj.tree;
jt  = obj.java_tree;
jth = obj.tree_container;

%If root not visible the expandrow call below doesn't work. Need to turn
%visible on when replace root node.
if strcmp(obj.root_visible,'off')
  jt.setRootVisible(true);
end

newroot = uitreenode_o('',obj.root_name,obj.root_icon,false);
mt.setRoot(newroot);
expandrow(obj,0);

if strcmp(obj.root_visible,'off')
  jt.setRootVisible(false);
end
