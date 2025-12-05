function mouse_clicked_callback(hObj,ev,fh,treeObj,varargin)
%EVRITREE/MOUSE_CLICKED_CALLBACK Click on tree node.
%  Run code for left or right or double click on node.
%    Left click   - usually nothing happens.
%    Right click  - shows context menu if available.
%    Double click - opens and or does action.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Not really used but leaving for possible future use.
% if nargin>4
%   source = varargin{1};
% else
%   source = 'tree';
% end

[click_type, click_count] = get_click_info(ev);

%Get copy of object.
obj = get_evritree_obj(fh,treeObj);

%Don't do anything if we're disabled.
if strcmp(obj.disable_mouse_callbacks,'on')
  return
end

%Get row and row.
jth = obj.tree;%Peer handle.
jt = obj.java_tree;%Java obj.

%Set current row if we're in single selection. Do this because if user
%doesn't click on top of leaf it won't select (e.g., in the white space to
%right of leaf)
myrow = evrijavamethodedt('getClosestRowForLocation',jt,ev.getX,ev.getY);
if strcmp(obj.selection_type,'single')
  evrijavamethodedt('setSelectionRow',jt,myrow);
end
%Get node path/s
%TODO: Enable mulitple selctions/paths in future.
%nodepaths = evrijavamethodedt('getSelectionPaths',jt);
drawnow
nodepath  = evrijavamethodedt('getClosestPathForLocation',jt,ev.getX,ev.getY);
nodepath  = evrijavamethodedt('getLastPathComponent',nodepath);
nodename  = [];
nodevalue = [];
if ~isempty(nodepath)
  nodename = char(nodepath.getName);
  nodevalue = nodepath.getValue;
end

%Set path of last noded clicked.
obj.last_path = get_path_from_node(obj,nodepath);
set_evritree_obj(obj);

myfcn = [];

%Run code for particular source.
if click_type == 1
  %left click
  myfcn = obj.tree_clicked_callback;
  if click_count==2
    myfcn = obj.tree_doubleclicked_callback;
  end
else
  myfcn = obj.tree_rightclick_callback;
end

%Run additional callbacks if needed.
myvars = getmyvars(myfcn);
if iscell(myfcn)
  myfcn = myfcn{1};
end

if click_type==2 & ~isempty(obj.tree_contextmenu) & ishandle(obj.tree_contextmenu)
  %Run callback if available. Since this is a right click menu we need node
  %under mouse, not selected node.
  myrow     = evrijavamethodedt('getClosestRowForLocation',jt,ev.getX,ev.getY);
  nodepath  = evrijavamethodedt('getClosestPathForLocation',jt,ev.getX,ev.getY);
  nodepath  = evrijavamethodedt('getLastPathComponent',nodepath);
  nodename  = [];
  nodevalue = [];
  if ~isempty(nodepath)
    nodename  = char(nodepath.getName);
    nodevalue = nodepath.getValue;
    evrijavamethodedt('setSelectionRow',jt,myrow);
  end
  myfcn = obj.tree_contextmenu_callback;
  myvars = getmyvars(myfcn);
  if ~isempty(myfcn)
    feval(myfcn,hObj,ev,myvars{:},obj,myrow,nodepath,nodename,nodevalue);
  end
  %Right click so place context menu.
  set(obj.tree_contextmenu,'position',getmouseposition(obj.parent_figure));
  set(obj.tree_contextmenu,'visible','on');
end

if click_type==1
  %Left click.
  if ev.getClickCount == 2
    %TODO: Need to add double click code from evritree.
    if ~isempty(myfcn)
      feval(myfcn,hObj,ev,myvars{:},obj,myrow,nodepath,nodename,nodevalue);
    end
  else
    %Single click, updaste icons if needed.
    mytree = getstruct(obj,nodevalue);%This can come back empty.
    
    %Look for | in new cache struct naming scheme.
    if isempty(mytree)
      if strfind(nodevalue,'|')
        mytree(1).nam = nodevalue;
      else
        %Need a dummy struct so no errors occur below.
        mytree(1).nam = '';
      end
      mytree(1).val = mytree(1).nam;%Need to spoof .val too.
    end
    
    if isfield(mytree,'chk')&&~isempty(mytree.chk)
      %Switch icons for all siblings.
      updateicon(obj,mytree, nodepath)
    end
    
    if isfield(mytree,'clb')&&length(mytree)==1&&~isempty(mytree.clb)% || getappdata(fh,'force_tree_callback')
      %Try feval to callback with figure handle and node name as keyword.
      try
        feval(mytree.clb,'tree_callback',hObj,ev,myvars{:},obj,myrow,nodepath,nodename,nodevalue)
      catch
        error(lasterr)
      end
    else
      if ~isempty(myfcn)
        feval(myfcn,hObj,ev,myvars{:},obj,myrow,nodepath,nodename,nodevalue);
      end
    end
  end
end


%Note to self: add path to last component but not as java object. Try
%fixing this in evritree.



%
%
%
%
%
%
% if SwingUtilities.isRightMouseButton(ev)
%   %Place UIContext menu on selected item (if any).getrowforlocation
%
%   %Use browse right-click menu for "items".
%   if strcmp(get(fh,'tag'),'eigenworkspace') && (length(myStr)>5 && strcmp(myStr(1:5),'item:'))
%     browse('cache_tree_right_click',h, ev,lastselected,fh)
%     return
%   end
%
%   vp = tt.getParent.getViewPosition;
%   tpos = t.PixelPosition;
%
%   %If selected row is a leaf with no children, show load context menu,
%   %otherwise expand.
%   if length(myStr)>5 && strcmp(myStr(1:5),'item:')
%     %Make UI context visible in correct location.
%     cm = findobj(fh,'tag','cacheviewmenu');%'UIContextMenu');
%     if ~isempty(cm)
%       set(cm,'position',[ev.getX+tpos(1)-vp.x (tpos(4)-ev.getY)+tpos(2)+vp.y],'Visible','on');
%     end
%   elseif any(ismember(modelcache('projectlist'),myStr))
%     cp = findobj(fh,'tag','cacheproject');%'UIContextMenu');
%     if ~isempty(cp)
%       set(cp,'position',[ev.getX+tpos(1)-vp.x (tpos(4)-ev.getY)+tpos(2)+vp.y],'Visible','on');
%     end
%   else
%     %Must not have clicked on loadable item. Just try expand to first child.
%     evrijavamethodedt('expandPath',tt,tt.getSelectionPath);
%   end
% else
%   %Left mouse click.
%
%   %If double click then try to load item.
%   if ev.getClickCount == 2
%
%     %Valid item? load it (and invert the open/close command).
%     if length(myStr)>5 && strcmp(myStr(1:5),'item:')
%       %Try code below to fix problem of double event being generated by
%       %double click. Just set row to opposite expand state becuase we know
%       %the first click expanded it.
%       if tt.isExpanded(myrow)
%         %Need to collapse.
%         mymethod = 'collapseRow';
%         %javaMethodEDT('collapseRow',tt,myrow)
%       else
%         %Need to expand.
%         mymethod = 'expandRow';
%         %javaMethodEDT('expandRow',tt,myrow)
%       end
%       evrijavamethodedt(mymethod,tt,myrow);
%
%       %now, try to load object into GUI
%       fname = get(fh,'tag');
%       if strcmp(fname,'eigenworkspace')
%         fname = 'browse';
%       end
%       try
%         feval(fname,'loadcacheitem',fh,[],guihandles(fh),[]);
%       catch
%       end
%     elseif length(nodeval)>4 && strcmp(nodeval(1:4),'demo')
%       %Call tree_callback with double click flag.
%       fname = get(fh,'tag');
%       try
%         %This needs to be refactored for use in analysis and any other guis
%         %but only enable browse for now.
%         if strcmpi(fname,'eigenworkspace')
%           feval('browse','tree_double_click',fh,'cache',tt,lastselected)
%         elseif strcmpi(fname,'analysis')||strcmpi(fname,'miagui')
%           %This should be refactored but this is the safest way to call
%           %this for now.
%           mytree = parsetree(fh,nodeval);
%
%           %If tree is empty don't call anything and return.
%           if isempty(mytree)
%             return
%           end
%
%           feval(fname,'tree_double_click',fh,mytree.nam,mytree,lastselected)
%         end
%       catch
%       end
%     end
%   else
%     %Try executing a callback from the tree structure if it exists.
%
%     %Save location of last selection so we can return to leaf after an
%     %update.
%     if ~isempty(nodeval)
%       setappdata(fh,'cachetreelocation',lastselected);
%     end
%
%     mytree = parsetree(fh,nodeval);%This can come back empty.
%
%     %Look for | in new cache struct naming scheme.
%     if isempty(mytree)
%       if strfind(nodeval,'|')
%         mytree(1).nam = nodeval;
%       else
%         %Need a dummy struct so no errors occur below.
%         mytree(1).nam = '';
%       end
%       mytree(1).val = mytree(1).nam;%Need to spoof .val too.
%     end
%
%     if isfield(mytree,'chk')&&~isempty(mytree.chk)
%       %Switch icons for all siblings.
%       icon_update(mytree, lastselected, t)
%     end
%
%     if isfield(mytree,'clb')&&length(mytree)==1&&~isempty(mytree.clb)% || getappdata(fh,'force_tree_callback')
%       %Try feval to callback with figure handle and node name as keyword.
%       try
%         feval(mytree.clb,'tree_callback',fh,mytree.nam,mytree,lastselected)
%       catch
%         error(lasterr)
%       end
%     end
%
%     %See if there's a forced callback, we need to do one for browse so use
%     %'force_tree_callback' appdata. The cachestruct doesn't have .clb
%     %filled in but we need to do one for browse so use 'force_tree_callback' appdata.
%     if ~isempty(getappdata(fh,'force_tree_callback')) && ~isempty(mytree) && ~isfield(mytree,'clb')%Try not to call twice if clb is there.
%       try
%         feval(getappdata(fh,'force_tree_callback'),'tree_callback',fh,mytree.nam,mytree,lastselected)
%       end
%     end
%   end
% end
%
%
%
%
%
%
%
%
%
%
%
%
%

%---------------------------
function myvars = getmyvars(myfcn)
%Get function from object.

myvars = {};
if iscell(myfcn) && length(myfcn)>1
  myvars = myfcn(2:end);
  myfcn = myfcn{1};
end

%-------------------------
function out = getpathfromnode(mynode)
%Get the path to a node via it's name value so it can be used to return to
%that node after an update.

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
  mysteps = [char(mynode.getName) obj.path_sep mysteps];
  mynode = mynode.getParent;
end
out = mysteps;


