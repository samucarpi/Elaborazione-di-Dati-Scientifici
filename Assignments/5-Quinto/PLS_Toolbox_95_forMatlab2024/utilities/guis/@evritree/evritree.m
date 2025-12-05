function varargout = evritree(varargin)
%EVRITREE/EVRITREE Wrapper object for working with jtree in Matlab.
%
%
% Calling with no inputs creates a figure with tree based on file system.
%
% NOTE: Not all properties are initialized. If using properties other than
% the following they may need to be assigned after object creation:
%   figure_parent
%   tag
%
% Nodes based on structure in .tree_data field. If not default filesystem
% tree will show.
%   .val = {string} Unique value, used in traversing tree, haded to tree expansion function.
%   .nam = {string} Unique value used in traversing tree.
%   .str = {string} Display name.
%   .icn = {string} Location of icon image.
%   .isl = {bool} Is a leaf or not.
%   .clb = {string or function handle} Callback for when node is expanded or clicked.
%   .chd = {struct} Child structure with same fields as above.
%
%   EXAMPLE:
%
%   nodestruct(1).val = num2str(1);
%   nodestruct(1).nam = '';
%   nodestruct(1).str = 'No Cached Data Available';
%   nodestruct(1).icn = which('emptycache.gif');
%   nodestruct(1).isl = true;
%   nodestruct(1).clb = 'analysis(''subfcn'',gcbo)';
%   nodestruct(1).chd = getchildstructure();
%
%
%I/O: obj = evritree(varargin)
%I/O: obj = evritree(data);%Create figure with tree of data.
%I/O: obj = evritree(data,'parent_figure',figh);
%
%See also: EVRITREE

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

% NOTE: We use this wrapper to contain all custom java calls so we can more
% easily monitor thread safety and manage code.
%

%TODO: Add tooltip to tree/window.
%TODO: Add tooltip to nodes.
%TODO: Modify subsasign to deal with modifying file_filter property on the fly.

switch nargin
  case 0
    obj = getdefaults;
    obj = class(obj,'evritree');
    obj = initialize(obj);
  otherwise
    if ischar(varargin{1}) && (strcmp(varargin{1},'update') || strcmp(varargin{1},'delete'))
      %Try to udpate the tree on the figure.
      thisobj = findmyobj(varargin{2});
      
      if strcmp(varargin{1},'delete')
        delete(thisobj)
        return
      end
      
      return
    end
    
    %Legacy call to old function.
    if ~ischar(varargin{1}) && ishandle(varargin{1})
      if nargout==0
        evritreefcn(varargin{:});
      else
        [varargout{1:nargout}] = evritreefcn(varargin{:});
      end
      return
    end
    
    %Create object.
    obj = getdefaults;
    
    property_argin = varargin;
    
    %Try to assign value pairs.
    incoming_props = {};
    while length(property_argin) >= 2,
      prop = property_argin{1};
      val = property_argin{2};
      incoming_props = [incoming_props {prop}];
      property_argin = property_argin(3:end);%Cut off first 2.
      if isfield(obj,prop)
        obj.(prop) = val;
      end
    end
    obj = class(obj,'evritree');
    obj = initialize(obj,incoming_props);
    varargout{1} = obj;
end

%----------------------------
function obj = getdefaults
%Default values.
obj.evritreeversion       = 1.0;
obj.parent_figure         = [];%Parent figure.
obj.time_stamp            = now;
obj.closebtn              = 'on';%Add a "spoofed" close button to the tree.

%Root node items.
obj.root_name             = '';%Tree root name default.
obj.root_icon             = which('evri.png');
obj.root_visible          = 'on';%If root node is visible.
obj.root_handles_show     = 'on';%When root visible off, show expansion +/- signs in root.
obj.last_path             = '';%Text path of node last clicked or expanded.

obj.tree_data             = [];%Structure of tree data, if empty defaults to file system.
obj.file_filter           = {};%If making tree of file system, apply filter to files.
obj.path_sep              = '/';%Separator of text path to leaf (used in .val hierarchy).
%TODO: Modify subsasign to deal with modifying file_filter property.

%Container props, all asigned through subsasgn.
obj.tree_container        = [];%tree container handle.
obj.tag                   = 'evritree';%Tag is used to find object so if using more than one tree on figure use different tag.
obj.visible               = 'on';
obj.units                 = 'pixel';
obj.position              = [0 0 200 200];
obj.editable              = 'on';%Enable selections and clicks. NOT USED YET
obj.data_changed_callback = '';%NOT USED YET
obj.hide_panel            = 'off';%'on' if you are extracting scroll pane the orignal container sometimes can't be removed so store it in a hidden panel.

%tree props.
obj.tree                  = [];%Matlab uitree object, hanlde wrapper object.
obj.java_tree             = [];%Jtree object.
obj.java_parent           = [];%Java object if tree is moved into parent java container (like a panel).
obj.selection_type        = 'single';%Type of selection allowed [{'single'}|'contiguous'|'discontiguous']
obj.tree_fontsize         = [];%Empty = default.
obj.tree_fontstyle        = 'plain';%{'plain' 'bold' 'italic'}
obj.tree_fontname         = '';%Empty = default.
obj.tree_contextmenu      = [];
obj.tree_contextmenu_callback = '';%Called when menu created.
%obj.disable_data_callback = 'off';%Turn off data change callback when updating data. Use this with large trees and or when programatially updating tree.

%Callbacks, function handles only. Can use to add interaction with other contorls (highlight items in tree for instance).
obj.disable_mouse_callbacks      = 'off';%Disable callbacks from being run. NOT FULLY WORKING
obj.tree_clicked_callback        = '';
obj.tree_doubleclicked_callback  = '';%Inconsistent behavior if tree is editree.
obj.tree_rightclick_callback     = '';
obj.tree_mousepressed_callback   = '';
obj.tree_nodeexpand_callback     = '';
obj.column_clicked_callback      = '';
obj.selection_changed_callback   = '';%Selection in tree changed.





