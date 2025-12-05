function obj = initialize(obj,incoming_props)
%EVRITREE/INITIALIZE Set initial info of object.
% Build initial tree and add static features. Use updatetree and or
% sub-functions to add additional dynamic items.

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Need data and figure to do anything.
% if isempty(obj.data)
%   %Make 1 empty cell.
%   obj.data = {' '};
% end

warningtoggle;%Turn off unwanted warnings.

if isempty(obj.parent_figure)
  obj.parent_figure = figure('tag','evritree_default_figure');
  %If no parent the probably testing so use whole figure window.
  obj.units = 'normalized';
  obj.position = [0 0 1 1];
end

%Get tree root.
if isempty(obj.tree_data)
  %Using default file browser so get root file system folder.
  [junk,obj] = get_path_struct(obj);
end

myroot = uitreenode_o('',obj.root_name,obj.root_icon,false);

%Create the tree.
[obj.tree, obj.tree_container] = uitree_o('Parent',obj.parent_figure,'Root',myroot,'ExpandFcn',{@node_expand_callback,obj.parent_figure,obj.tag});

%If hiding use panel in lower left.
if strcmp(obj.hide_panel,'on')
  hp = uipanel(obj.parent_figure,'tag',[obj.tag '_hide_panel'],'units','pixels','Position',[1 1 1 1]);
  set(obj.tree_container, 'Parent', hp); 
  drawnow
  %Latency makes setting visible off risky since it won't render object if
  %it's not visible yet. Just rely on it being 1 pixel in size to hide.
  %set(hp,'visible','off')
end


%Set initial properties.
set(obj.tree_container,'tag',obj.tag,'visible',obj.visible,'units',obj.units,'position',obj.position)
%Make sure object are on EDT.
obj.java_tree = evrijavaobjectedt(get(obj.tree,'Tree'));

drawnow
%---- 
set_evritree_obj(obj)%Save object to figure.
expandrow(obj,0)%Draw first node/s.

%Update properties.
myprops = {'root_visible' 'root_handles_show' 'selection_type' };
for i = myprops
  set(obj,i{:},obj.(i{:}));%Run through subsasgn.
end

%Add click/datachange callbacks. It must be here so datachange callback
%doesn't get called for every single cell when first adding data above.
addcallbacks(obj)
