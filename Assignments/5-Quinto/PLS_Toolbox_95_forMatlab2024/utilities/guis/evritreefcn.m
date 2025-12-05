function varargout = evritreefcn(fh,mode,ctype,options)
%EVRITREEFCN Creates a tree view of cached datasets, models, and predections.
%  Input 'fh' is parent figure handle. Input 'mode' governs update
%  behavior, mode='update' gets the current node and tries to navigate back
%  to it, mode=new just rebuilds and opens the first row.
%
% INPUTS:
%   fh     - Parent figure handle.
%   mode   - [{'show'} | 'update' | 'hide'] create, update, or destroy the tree and it's java panel.
%   ctype  - ['lineage' | 'date' | 'object' | 'custom'] cache type to "display by" in tree.
%               lineage - dispaly by lineage.
%               date    - dispaly by date.
%               object  - display by type of object.
%               custom  - structure must be manually assigned to figure
%                         appdata 'treestructure' field.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%           position: [] four element vector of default position to display
%                     tree panel at on parent figure.
%           tag     : ['evricahcetree'] Tag name for tree, default name
%                     will be used to propogate updates for modelcache.
%                     Change tag name when using custom tree.
%           rootname: '' String for naming root node of tree. Default is
%                     for Model Cache.
%           closebtn: [{'on'} | 'off']
%    parent_function: '' parent function name (e.g., 'analysis').
%    parent_callback: '' parent callback function.
%      NOTE: These two items are used to form the callback for the close
%      button. They may be used for different purposes in the future.
%       mycallback = [options.parent_function '(''' options.parent_callback ''',gcbo,[],guidata(gcbf));']
%
% Drag and drop functionality resides with the "drop" function for the
% interface being dropped on. As will load context menu.
%
% Creating Structure For A Tree:
%   When ctype is set ot custom, you can create a custom structure with the
%   following fields, add it to an appdata field of the figure as 'treestructure',
%   and a tree will be created correctly:
%     nodestruct(1).val = 1;  %Unique identifier
%     nodestruct(1).nam = '';  %Unique Name
%     nodestruct(1).str = 'No Cached Data Available';  %String displayed
%     nodestruct(1).icn = which('emptycache.gif');  %Icon
%     nodestruct(1).isl = true;  %Terminal leaf or expandable
%     nodestruct(1).clb = 'analysis';  %Function for callback
%   For nodes that will have active icons the following fields are
%   required. When a node is activated its icon becomes .icn image and all
%   others become .chk image.
%     nodestruct(1).chk = which('evri_check.gif');  %Icon
%
%   The callback 'clb' calls the subfunction 'tree_callback' in the named
%   function with two inputs, the figure handle and the leaf name (as a
%   keyword).
%
%Each node needs the following:
%   value  - string or handle to a subnode (I think).
%   string - the text displayed for the node.
%   icon   - path to icon (or java icon object).
%   isleaf - true/false as to wether node has children.
%
%  NOTE: Add expansion callbacks (listeners) to tree as needed.
%
%I/O: varargout = evritreefcn(fh,mode,ctype,options)
%
%See also ANALYSIS, CACHESTRUCT, MODELCACHE

%Copyright Eigenvector Research 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.
%rsk 11/01/07
% NOTE: There can be thread safety problems when calling non-static methods
% that require using java.awt.EventQueue.invokeLater() or javaObjectEDT,
% javaMethodEDT.

if nargin == 0; fh = 'io'; end
varargin{1} = fh;
if ischar(varargin{1});
  options = [];
  options.position = [];
  options.tag      = 'evricahcetree';
  options.rootname = '';
  options.closebtn = 'on';
  options.parent_function = '';
  options.parent_callback = '';
  %options.multiselect = 'off'; %Doesn't work with the mouse pressed callback.
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

if nargin < 2
  mode = 'show';
end

if nargin<=2
  %Check if stored in appdata.
  if ~isempty(fh)
    ctype = getappdata(fh,'cachetreetype');
  else
    ctype = [];
  end
  if isempty(ctype)
    %Use default.
    ctype = 'lineage';
  end
end

if nargin<=3
  options = evritreefcn('options');
end

options = reconopts(options,'evritreefcn');

switch mode
  case 'show'
    
    %Get any old objects so they can be deleted later. This stops the
    %flashing problem when updating to a new tree.
    myoldtree = getappdata(fh,'treeparent');
    myoldbutton = findobj(fh,'tag','closecacheviewer');
    myoldcontainer = getappdata(fh,'treecontainer');
    
    import javax.swing.*;
    
    %Create a root tree node object with ML function.
    if isempty(options.rootname)
      rootname = ['Cache : "' modelcache('projectfolder') '" ' upper(ctype) ' View (* = Not Available)'];
    else
      rootname = options.rootname;
    end
    root = uitreenode_overload('',rootname,which('evri.png'),false);
    
    %Create a tree object and hand our root node to it.
    [t, tcontainer] = uitree_overload(fh,root,@myExpfcn);
    %Can't set callback in above call because error will happen.
    set(t, 'NodeSelectedCallback', @selected_cb);
    
    %Create property for storying type of tree.
    sp = schema.prop(t, 'tag', 'mxArray');
    sp2 = schema.prop(t,'GetSelectedCacheItem','mxArray');
    sp3 = schema.prop(t,'RenameSelectedCacheItem','mxArray');
    sp4 = schema.prop(t,'RemoveSelectedCacheItem','mxArray');
    sp5 = schema.prop(t,'IconUpdate','mxArray');
    set(t,'tag',options.tag);
    set(t,'GetSelectedCacheItem',@getcurrentselection);
    set(t,'RenameSelectedCacheItem',@renamecacheitem);
    set(t,'RemoveSelectedCacheItem',@removecacheitem);
    set(t,'IconUpdate',@icon_update);
    
    %Note: the NodeDroppedCallback method doesn't seem to work going from
    %java frame to GUIDE object. No event gets triggered when you drop.
    
    %Reposition.
    if isempty(options.position)
      if ishandle(myoldtree)
        drawnow%Need to make sure object is there.
        units = get(myoldtree,'units');
        options.position = get(myoldtree,'position');
      else
        units = 'normalized';
        options.position = [0 0 .39 1];
      end
    else
      units = 'pixels';
    end
    set(t, 'Units', units,...
      'position', options.position)
    %Bug in Matlab doesn't move the container so have to move it
    %manually.
    set(tcontainer, 'Units', units,...
      'position', options.position)
    
    %Put tree and its container handle in parent figure.
    %NOTE: Seems to be bug in ML (7.0 and maybe others) that you need to
    %move (and delete) both tree and its container.
    %TODO: Test this assumption.
    setappdata(fh,'treeparent',t);
    setappdata(fh,'treecontainer',tcontainer);
    
    try
      if ishandle(myoldtree)
        delete(myoldtree)
      end
    end
    try
      if ishandle(myoldbutton)
        delete(myoldbutton)
      end
    end
    try
      if ishandle(myoldcontainer)
        delete(myoldcontainer)
      end
    end
    
    %set background color
    mytree = t.getTree;
    mytree_h = handle(mytree,'CallbackProperties');%Get handled jtree so we can set callbacks.
    clr = java.awt.Color(.93,.93,.93);

    evrijavamethodedt('setBackground',mytree,clr);

    %Shows warning in new releases and doesn't really work anyway.
    %set(mytree,'DragEnabled','on');
    drawnow;
    
    %     %Set multiselect.
    %     if 1;%strcmpi(options.multiselect,'on')
    %       sm = mytree.getSelectionModel;
    %       set(t,'MultipleSelectionEnable',sm.DISCONTIGUOUS_TREE_SELECTION);
    %     end
    
    %Put current model cache into parent figure.
    setmodelcache(fh,ctype)
    
    %Pass back tree handle.
    varargout{1} = t;
    
    %Expand to first level of tree so it looks correct.
    %Save figure handle into tree.
    %set(mytree,'UserData',fh)
    evrijavamethodedt('expandRow',mytree,0);
    
    evrijavamethodedt('setBackground',mytree,clr.white);

    drawnow;
    
    
    %Save figure handle into tree.
    %set(mytree,'UserData',fh)
    
    %     %Add context menu.
    %     mymenu = uicontextmenu;
    %     uimenu(mymenu, 'Label', 'Load Item', 'Callback', @selectitem_cb)
    %     uimenu(mymenu, 'Label', 'View Item', 'Callback', @selectitem_cb)
    %     set(mytree,'UIContextMenu',mymenu)
    
    %Add context menus.
    set(mytree_h, 'MousePressedCallback', {@mouse_cb, fh});
    set(mytree_h, 'MouseReleasedCallback', {@mouserel_cb, fh});
    
    varargout{1} = t;
    varargout{2} = tcontainer;
    
  case 'update'
    %Cache has been updated so rebuild cache struct, save to figure, delete
    %all leafs, and expand to first node then try to expand to saved node
    %(expandtoleaf has the code to do so).

    %Create a root tree node object with ML function.
    if isempty(options.rootname)
      rootname = ['Cache : "' modelcache('projectfolder') '" ' upper(ctype) ' View (* = Not Available)'];
    else
      rootname = options.rootname;
    end
    
    if strcmp(ctype,'custom')
      %Just rebuild the parent figure tree. This isn't a model cache tree.
      cachefigs = fh;
    else
      cachefigs = findallcachefigs;
    end
    
    for i = 1:length(cachefigs)
      %Can't seem to use the .removeAllChildren trick here so just create a
      %new root (for each tree, java is reference) and expand it.
      myroot = uitreenode_overload('',rootname,which('evri.png'),false);
      
      fh = cachefigs(i);
      
      %Current java tree.
      mytree = getappdata(fh,'treeparent');
      
      %Put current model cache into parent figure.
      setmodelcache(fh,ctype)
      
      %Don't think we need edt call here since TMW does naked call in their
      %code. Tree must already be on EDT.
      mytree.setRoot(myroot);
      
      evripause(.1)

      %Expand to row 0, this won't reset old location.
      evrijavamethodedt('expandRow',mytree.getTree,0);

      evripause(.1)
      drawnow
      
      %Try to expand to old location.
      expandtoleaf(fh);
    end

  case 'hide'
    
    %Evaluate cacheview_closeFcn for figure.
    fname = get(fh,'tag');
    feval(fname,'cacheview_closeFcn',fh);
    varargout{1} = [];
    
    try
      %Delete tree.
      delete(getappdata(fh,'treeparent'))
    end
    try
      %Delete close button.
      delete(findobj(fh,'tag','closecacheviewer'));
    end
    try
      %Delete container, might fix ML 7.0 problem.
      delete(getappdata(fh,'treecontainer'))
    end
    
    %     %Evaluate cacheview_closFcn for figure.
    %     fname = get(fh,'tag');
    %     feval(fname,'resize_callback',fh);
    %     varargout{1} = [];
    
  case 'addclose'
    %Get rid of old button if there.
    try
      %Delete close button.
      delete(findobj(fh,'tag','closecacheviewer'));
    end
    
    %Got a list, get position and set default values
    mytree = getappdata(fh,'treeparent');
    pos = get(mytree,'PixelPosition');
    
    if ~isempty(options.parent_function)
      %Create custom callback.
      mycallback = [options.parent_function '(''' options.parent_callback ''',gcbo,[],guidata(gcbf));'];
    else
      mycallback = 'analysis(''cachemenu_callback'',gcbo,[],guidata(gcbf));';
    end
    
    
    %add "close" button
    bsz = 15;
    delete(findobj(fh,'tag','closecacheviewer'));
    varargout{1} = uicontrol(fh,...
      'style','pushbutton',...
      'tag','closecacheviewer',...
      'string','X',...
      'position',[pos(1)+pos(3)-bsz-18 pos(2)+pos(4)-bsz-1 bsz bsz],...
      'callback',mycallback);
end

%-------------------------------------------------
function selected_cb(tree, value)
%On selection callback for tree node.
%TODO: Hand back object here as right click.

rem = value.getCurrentNode.getValue;
L1 = {};
while (any(rem))
  %Create cell array of stings with each field name as seperate cell.
  [S1, rem] = strtok(rem, '/');
  L1 = [L1 {S1}];
end

%-------------------------------------------------
function nodes = myExpfcn(tree, value)
%Expansion function for tree node.

th = get(tree);
%fh = get(th.UIContainer,'Parent');
fh = ancestor(th.UIContainer,'Figure');
mytree = getappdata(fh,'treestructure');

%If tree is empty then stick a leaf in saying it's empty.
if isempty(mytree)
  nodes(1) = uitreenode_overload('1', 'No Cached Data Available', '', true);
  return
end
cpos = strfind(value,'|');
if isempty(cpos)
  %Use / indexing to build leaf info.
  rem = value;
  L1 = {};
  while (any(rem))
    %Create cell array of stings with each field name as seperate cell.
    [S1, rem] = strtok(rem, '/');
    L1 = [L1 {S1}];
  end
  
  for i = 1:length(L1)
    %Step through structure to find child structure (.chd).
    idx = find(ismember({mytree.nam},L1{i}));
    if isfield(mytree,'isc') && mytree(idx).isc
      %This is the end of a cache structure with model/data information to be
      %displayed from database.
      sourceitem = getcacheindex(evricachedb,L1{i},1);
      mytree     = cachestruct('cacheobjinfo', [value '/'], sourceitem);
    else
      if ~isempty(idx) && isfield(mytree(idx),'chd')
        mytree = mytree(idx).chd;
      else
        mytree = [];
      end
    end
  end
  
else
  %Use query to get leaf info.
  cobj = evricachedb;
  qry = value(1:cpos-1);%query function
  qval = value(cpos+1:end);%query value
  if strcmp(qry,'cachestruct')
    sourceitem = getcacheindex(cobj,qval,1);
    if length(sourceitem)>1
      mytree = [];
      mytree.val = [qval '/Info:'];
      mytree.nam = 'Info:';
      mytree.str = 'Data Not Available';
      mytree.icn = '';
      mytree.isl = logical([ 1 ]);
    else
      mytree     = cachestruct('cacheobjinfo', [qval '/'], sourceitem);
    end
  else
    child_idx = ismember({mytree.nam},qval);
    
    mytree = feval(qry,cobj,qval);
  end
end

if ~isempty(mytree)
  for i = 1:length(mytree)
    %Create nodes first then hand them to uicontrol on figure.
    nodes(i) = uitreenode_overload(mytree(i).val,mytree(i).str,mytree(i).icn,mytree(i).isl);
    if isfield(mytree,'typ')
      nodes(i).UserData = mytree(i).typ;
    end
  end
else
  nodes = [];
end

%-------------------------------------------------
function expandtoleaf(fh)
%Expand tree to old location.
%
% Assume we have to do it this "manual" (loop through) way because of load
% children lazy method (i.e., children are created at time of use and not
% all at once).
%
% Also will only expand to last location all other expanded nodes will
% collapse. In future we can have more dynamic interaction with nodes and
% cache.

myloc = getappdata(fh,'cachetreelocation');

if isempty(myloc)
  return
end

mytree = getappdata(fh,'treeparent');
mystruct = getappdata(fh,'treestructure');
jtree = mytree.getTree;
rootnode = mytree.getRoot;

if isempty(myloc)
  return
end

%Start at top node and start searching down myloc for leaf nodes

mylocs = textscan(myloc,'%s','delimiter','/'); %parse location.
mylocs = mylocs{:};

mynode = rootnode;%Get root node.
stillsearch = 1;%Flag to continue search.
myrow = 0;%Row count from root.

for i = 1:length(mylocs)
  if ~stillsearch
    break
  end
  stillsearch = 0;
  
  %Have to have a puase here becuase object doesn't seem to be created fast
  %enough to allow getChildCount to occur. Returns empty without pause.
  evripause(.1)
  
  %Step through first "row" of children.
  for j = 1:mynode.getChildCount
    nextnode = mynode.getChildAt(j-1);%Account for zero indexing in getChildAt.
    myval = nextnode.getName;
    dloc  = strfind(myval,'/');
    if ~isempty(dloc)
      myval = myval(dloc(end)+1:end);
    end
    
    if strcmpi(mylocs{i},myval)
      myrow = j+myrow; %Account for glogal row indexing from root(jtree);
      %At correct location so expand to here.
      evrijavamethodedt('expandRow',jtree,myrow);
      drawnow
      mynode = nextnode;
      stillsearch = 1;
      
      %Run callback on last node in case there are icons that need to be
      %set.
      if ~isempty(mystruct) && ~isempty(find(ismember({mystruct.nam},mylocs{i})))
        idx = find(ismember({mystruct.nam},mylocs{i}));
        if i == length(mylocs)
          %Last branch of tree so don't index into child (chd).
          mystruct = mystruct(idx);
          %Try calling callback.
          if isfield(mystruct,'clb')&&length(mystruct)==1&&~isempty(mystruct.clb)% || getappdata(fh,'force_tree_callback')
            %Try feval to callback with figure handle and node name as keyword.
            try
              feval(mystruct.clb,'tree_callback',fh,mystruct.nam,mystruct,mynode)
            catch
              error(lasterr)
            end
          end
        else
          mystruct = mystruct(idx).chd;
        end
      end
      break
    end
  end
end

%------------------------
function mouse_cb(h, ev, varargin)
%Add right click context menu items.
set(h, 'MouseReleasedCallback', {@mouserel_cb, varargin{1}});
import javax.swing.*;

%Get stored paretn/tree data.
fh = varargin{1};
t  = getappdata(fh,'treeparent');
tt = t.Tree;
myrow = evrijavamethodedt('getClosestRowForLocation',tt,ev.getX,ev.getY);
evrijavamethodedt('setSelectionRow',tt,myrow);
%Get name of node.
lastselected = evrijavamethodedt('getLastSelectedPathComponent',tt);
myStr = char(lastselected.getName);
nodeval = lastselected.getValue;

if SwingUtilities.isRightMouseButton(ev)
  %Place UIContext menu on selected item (if any).getrowforlocation
  
  %Use browse right-click menu for "items".
  if strcmp(get(fh,'tag'),'eigenworkspace') && (length(myStr)>5 && strcmp(myStr(1:5),'item:'))
    browse('cache_tree_right_click',h, ev,lastselected,fh)
    return
  end
  
  vp = tt.getParent.getViewPosition;
  tpos = t.PixelPosition;
  
  %If selected row is a leaf with no children, show load context menu,
  %otherwise expand.
  if length(myStr)>5 && strcmp(myStr(1:5),'item:')
    %Make UI context visible in correct location.
    cm = findobj(fh,'tag','cacheviewmenu');%'UIContextMenu');
    if ~isempty(cm)
      mousepos = getmouseposition(fh);
      set(cm,'position',mousepos,'Visible','on');
    end
    
    %If item is not a model disable compare model.
    ppos = strfind(nodeval,'|');
    if ~isempty(ppos) & ~isempty(cm)
      hh = guihandles(cm);
      myinfo = modelcache('getinfo',nodeval(ppos+1:end));
      if strcmp(myinfo.type,'model')
        set([hh.comparcacheitem hh.exporttocache],'enable','on')
      else
        set([hh.comparcacheitem hh.exporttocache],'enable','off')
      end
      %Make import to cache invisible for now.
      set(hh.importtocache,'visible','off')
    end
    
  elseif any(ismember(modelcache('projectlist'),myStr))
    cp = findobj(fh,'tag','cacheproject');%'UIContextMenu');
    if ~isempty(cp)
      mousepos = getmouseposition(fh);
      set(cp,'position',mousepos,'Visible','on');
    end
  else
    %Must not have clicked on loadable item. Just try expand to first child.
    evrijavamethodedt('expandPath',tt,tt.getSelectionPath);
  end
else
  %Left mouse click.
  
  %If double click then try to load item.
  if ev.getClickCount == 2
    
    %Valid item? load it (and invert the open/close command).
    if length(myStr)>5 && strcmp(myStr(1:5),'item:')
      %Try code below to fix problem of double event being generated by
      %double click. Just set row to opposite expand state becuase we know
      %the first click expanded it.
      if tt.isExpanded(myrow)
        %Need to collapse.
        mymethod = 'collapseRow';
        %javaMethodEDT('collapseRow',tt,myrow)
      else
        %Need to expand.
        mymethod = 'expandRow';
        %javaMethodEDT('expandRow',tt,myrow)
      end
      evrijavamethodedt(mymethod,tt,myrow);
      
      %now, try to load object into GUI
      fname = get(fh,'tag');
      if strcmp(fname,'eigenworkspace')
        fname = 'browse';
      end
      try
        feval(fname,'loadcacheitem',fh,[],guihandles(fh),[]);
      catch
      end
    elseif length(nodeval)>4 && strcmp(nodeval(1:4),'demo')
      %Call tree_callback with double click flag.
      fname = get(fh,'tag');
      try
        %This needs to be refactored for use in analysis and any other guis
        %but only enable browse for now.
        if strcmpi(fname,'eigenworkspace')
          feval('browse','tree_double_click',fh,'cache',tt,lastselected)
        elseif strcmpi(fname,'analysis')||strcmpi(fname,'miagui')
          %This should be refactored but this is the safest way to call
          %this for now.
          mytree = parsetree(fh,nodeval);
          
          %If tree is empty don't call anything and return.
          if isempty(mytree)
            return
          end
          
          feval(fname,'tree_double_click',fh,mytree.nam,mytree,lastselected)
        end
      catch
      end
    end
  else
    %Try executing a callback from the tree structure if it exists.
    
    %Save location of last selection so we can return to leaf after an
    %update.
    if ~isempty(nodeval)
      mypath = getpathfromnode(lastselected);
      setappdata(fh,'cachetreelocation',mypath);
    end
    
    mytree = parsetree(fh,nodeval);%This can come back empty.
    
    %Look for | in new cache struct naming scheme.
    if isempty(mytree)
      if strfind(nodeval,'|')
        mytree(1).nam = nodeval;
      else
        %Need a dummy struct so no errors occur below.
        mytree(1).nam = '';
      end
      mytree(1).val = mytree(1).nam;%Need to spoof .val too.
    end
    
    if isfield(mytree,'chk')&&~isempty(mytree.chk)
      %Switch icons for all siblings.
      icon_update(mytree, lastselected, t)
    end
    
    if isfield(mytree,'clb')&&length(mytree)==1&&~isempty(mytree.clb)% || getappdata(fh,'force_tree_callback')
      %Try feval to callback with figure handle and node name as keyword.
      try
        feval(mytree.clb,'tree_callback',fh,mytree.nam,mytree,lastselected)
      catch
        erdlgpls(lasterr,'Error')
      end
    end
    
    %See if there's a forced callback, we need to do one for browse so use
    %'force_tree_callback' appdata. The cachestruct doesn't have .clb
    %filled in but we need to do one for browse so use 'force_tree_callback' appdata.
    if ~isempty(getappdata(fh,'force_tree_callback')) && ~isempty(mytree) && ~isfield(mytree,'clb')%Try not to call twice if clb is there.
      try
        feval(getappdata(fh,'force_tree_callback'),'tree_callback',fh,mytree.nam,mytree,lastselected)
      end
    end
  end
end

%------------------------
function out = parsetree(fh,nodeval)
%Get sub struct of current tree node.

out = [];

mytree = getappdata(fh,'treestructure');%Original tree structure.

%If tree is empty don't call anything and return.
if isempty(mytree)
  return
end

rem = nodeval;
L1 = {};
while (any(rem))
  %Create cell array of stings with each field name as seperate cell.
  [S1, rem] = strtok(rem, '/');
  L1 = [L1 {S1}];
end

%Locate and extract leaf inot mytree.
for i = 1:length(L1)
  if isempty(mytree)
    %We're at an undifined leaf.
    break
  end
  %Step through structure to find child structure (.chd).
  idx = find(ismember({mytree.nam},L1{i}));
  if isempty(idx)
    %I'm at a leaf, don't try to expand.
    return
  end
  if i == length(L1)
    %Last branch of tree so don't index into child (chd).
    mytree = mytree(idx);
  else
    mytree = mytree(idx).chd;
  end
end

out = mytree;


%------------------------
function mouserel_cb(h, ev, varargin)
%If left click releasing while on status area then assume drag and drop.
%NOTE: As of ML version 2007a/b, the java drag and drop interface seems to
%not work correctly with ML objects so use hack below.
import javax.swing.*;
if SwingUtilities.isLeftMouseButton(ev)
  fh = varargin{1};
  
  if checkmlversion('>=','8.4')
    curfig = double(get(0,'CurrentFigure'));
  else
    curfig = get(0,'pointerwindow');
  end
  
  if curfig==fh
    %If mouse is still on the figure then proceed.
    
    %Note: CurrentPoint poperty doesn't seem to work with java frames so we
    %have to hack a relative position via the mouse event object orginating
    %on the java frame.
    
    t  = getappdata(fh,'treeparent');
    tpos = get(t,'PixelPosition');
    
    handles = guihandles(fh);
    %FIXME: Need to use statusimage position here.
    %     dspos = get(handles.datastatus,'Position');
    %     mspos = get(handles.modelstatus,'Position');
    %
    %     %xpos and ypos are justified to upper left of java frame.
    %     xpos = ev.getX();
    %     ypos = ev.getY();
    %
    %     %Assume status boxes make one big rectangle.
    %     if xpos>-tpos(1) && xpos<(-tpos(1)+(dspos(3)+mspos(3)))
    %       %xpos is not off left edge of the figure and not off to right of data
    %       %windows.
    %       if ypos>0 && ypos<(dspos(4))
    %         %ypos is not above the data windows (because they should be same
    %         %height) and not below them.
    %         fname = get(fh,'tag');
    %         feval(fname,'loadcacheitem',fh,[],handles,[]);
    %
    %       end
    %     end
  end
end
%loadcacheitem(h, eventdata, handles, varargin)

%------------------------
function icon_update(mystruct, jleaf, t)

[I_off,map_off] = imread(mystruct.icn);
[I_on,map_on] = imread(mystruct.chk);

jImage_off = im2java(I_off,map_off);
jImage_on = im2java(I_on,map_on);

set(jleaf,'Icon',jImage_on)

if isfield(mystruct,'chk')
  
  %Step through siblings down.
  mysib = jleaf;
  while true
    mysib = mysib.getNextSibling;
    if isempty(mysib)
      break
    else
      set(mysib,'Icon',jImage_off);
    end
  end
  
  %Step through siblings up.
  mysib = jleaf;
  while true
    mysib = mysib.getPreviousSibling;
    if isempty(mysib)
      break
    else
      set(mysib,'Icon',jImage_off);
    end
  end
  t.repaint
end


%-------------------------
function setmodelcache(fh,ctype)
%Set cache into current figure.

opts = getappdata(fh,'treestructure_options');
if isempty(opts)
  opts = cachestruct('options');
end

switch char(ctype)
  case {'date' 'cachebydate'}
    mystruct = cachestruct('date',opts);
  case {'type' 'cachebytype'}
    mystruct = cachestruct('type',opts);
  case {'lineage' 'cachebylineage'}
    mystruct = cachestruct('lineage',opts);
  case 'custom'
    mystruct = getappdata(fh,'treestructure');
  otherwise
    mystruct = [];
end

setappdata(fh,'treestructure',mystruct);
setappdata(fh,'cachetreetype',ctype);

%-------------------------
function varargout = getcurrentselection(fh)
%Get selected item from tree.
%TODO, add multiselect.

t  = getappdata(fh,'treeparent');
tt = t.getTree;
cacheselected = tt.getLastSelectedPathComponent;
%For now, use "item: " in name to indicate if selected node points to a
%retrievable item otherwise, just return name of node.
if isempty(cacheselected)
  varargout{1} = {[]};
  return
end
myname = char(cacheselected.getName);
iloc = strfind(myname,'item: ');
if ~isempty(iloc)
  str = cacheselected.getValue;
  str = str(max(findstr(str,'|'))+1:end);
  varargout{1} = {modelcache('get',str)};
else
  str = cacheselected.getValue;
  varargout{1} = str(max(findstr(str,'/'))+1:end);
end

%-------------------------
function cachefigs = findallcachefigs
%Find all figures with cachetrees on them.

cachefigs = [];

%logic to handle when findall(0) and findobj fail because a figure gets
%destroyed while we're passing from one to the other. Repeat the operation
%5 times and then return empty as the "soft failure" mode 
repeat = true;
it = 0;
le = lasterror;
while repeat
  try
    it = it+1;
    if it>5;
      return;
    end
    figs = unique(findobj(findall(0),'type','figure'));
    repeat = false;
  catch
    lasterror(le);  %reset to initial error state
    repeat = true;
  end
end

for i = 1:length(figs)
  th = getappdata(figs(i),'treeparent');
  if ~isempty(th)&&ishandle(th)&&strcmp(get(th,'tag'),'evricahcetree')
    cachefigs = [cachefigs; figs(i)];
  end
end

%-------------------------
function renamecacheitem(fh)
%Rename an item and recreate tree.

t  = getappdata(fh,'treeparent');
tt = t.getTree;
cacheselected = tt.getLastSelectedPathComponent;
%For now, use "item: " in name to indicate if selected node points to a
%retrievable item.
mydesc = char(cacheselected.getName);
iloc = strfind(mydesc,'item: ');
if ~isempty(iloc)
  mydesc = mydesc(7:end);
  myname = cacheselected.getValue;
  myname = myname(max(findstr(myname,'|'))+1:end);
  newdesc = inputdlg('New Cached Item Name: ','Change Cached Item Name',1,{mydesc},'on');
  if ~isempty(newdesc)
    newdesc = newdesc{:};
    success = modelcache('setdescription',myname,newdesc);
    if success
      evritreefcn(fh,'update')
    end
  end
end

%-------------------------
function removecacheitem(fh)
%Remove an item and recreate tree.

t  = getappdata(fh,'treeparent');
tt = t.getTree;
cacheselected = tt.getLastSelectedPathComponent;
%For now, use "item: " in name to indicate if selected node points to a
%retrievable item.
mydesc = char(cacheselected.getName);
iloc = strfind(mydesc,'item: ');
if ~isempty(iloc)
  mydesc = mydesc(7:end);
  myname = cacheselected.getValue;
  myname = myname(max(findstr(myname,'|'))+1:end);
  
  modelcache('deleteitem',myname);
  evritreefcn(fh,'update')  
end

%-------------------------
function out = getpathfromnode(mynode)
%Get the path to a node via it's name value so it can be used to return to
%that node after an updaste.

%NOTE: Save text path instead of java object (as was done before) to
%prevent possible memory leak.

out = [];
if isempty(mynode) || mynode.isRoot
  return
end

%Walk up last tree pos and creat a path.
mysteps = char(mynode.getName);
mynode = mynode.getParent;
while ~mynode.isRoot
  mysteps = [char(mynode.getName) '/' mysteps];
  mynode = mynode.getParent;
end
out = mysteps;

%---------------------------
function root = uitreenode_overload(val,desc,iconloc,isleaf)
%Overload for uitreenode.
%UITREENODE('v0', Value, Description, Icon, Leaf)

if checkmlversion('>=','7.6')
  %Have to use the 'v0' switch in 2008b plus.
  root = uitreenode('v0',val, desc, iconloc, isleaf);
else
  root = uitreenode(val, desc, iconloc, isleaf);
end

%---------------------------
function [t, tcontainer] = uitree_overload(fh,root,myExpfcn)

if checkmlversion('>=','7.6')
  [t, tcontainer] = uitree('v0',fh,'Root', root,'parent', fh,'ExpandFcn',myExpfcn);
else
  [t, tcontainer] = uitree(fh,'Root', root,'parent', fh,'ExpandFcn',myExpfcn);
end

