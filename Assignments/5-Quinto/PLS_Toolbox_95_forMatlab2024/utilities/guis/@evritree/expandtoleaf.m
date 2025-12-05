function nextnode = expandtoleaf(obj,leafloc)
%EVRITREE/EXPANDTOLEAF Expand tree to a leaf.
%

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

obj = get_evritree_obj(obj);

% Assume we have to do it this "manual" (loop through) way because of load
% children lazy method (i.e., children are created at time of use and not
% all at once).
%
% Also will only expand to last location all other expanded nodes will
% collapse. In future we can have more dynamic interaction with nodes and
% cache.

if isempty(leafloc)
  leafloc = obj.last_path;
end

mytree   = obj.tree;
mystruct = obj.tree_data;
jtree    = obj.java_tree;
rootnode = mytree.getRoot;

if isempty(leafloc)
  return
end

mysep = obj.path_sep;
if strcmp(mysep,'\')
  %Need to escape.
  mysep = '\\';
end

%Start at top node and start searching down myloc for leaf nodes
mylocs = textscan(leafloc,'%s','delimiter',mysep); %parse location.
mylocs = mylocs{:};
mylocs = mylocs(~cellfun('isempty',mylocs));
if isempty(mylocs)
  nextnode = [];
  return;
end

%Get rid of drive letter if ispc and not using root.

mynode = rootnode;%Get root node.
stillsearch = 1;%Flag to continue search.

myrow = 0;%Row count from root.

%Check for root.
myval = char(mynode.getName);

%Check for root.
myval = char(mynode.getName);
if strcmp(mylocs{1},myval)
  %Remove root drive from tree since we're expanding from the root. On unix
  %root is just / so there's no drive letter before it.
  mylocs = mylocs(2:end);
elseif javax.swing.filechooser.FileSystemView.getFileSystemView.isDrive(java.io.File([myval filesep])) & ...
       javax.swing.filechooser.FileSystemView.getFileSystemView.isDrive(java.io.File([mylocs{1} filesep]))
  %Switching drives so need to rebuild root.
  [junk,obj] = get_path_struct(obj,[mylocs{1} filesep]);
  jt  = obj.tree;
  mynode = uitreenode_o('',obj.root_name,obj.root_icon,false);
  jt.setRoot(mynode);
  set_evritree_obj(obj)%Save object to figure.
  expandrow(obj,0)%Draw first node/s.
  mystruct = obj.tree_data;
  mylocs = mylocs(2:end);
  drawnow;
end

% if strcmp(obj.root_visible,'off')
%   myrow = 1;%No root showing so start at 1.
% end
nextnode = [];
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
    myval = char(nextnode.getValue);
    %NOTE: Changed above from .getName to .getValue. May need to change
    %back when we switch using evritree with modelcache.
    dloc  = strfind(myval,obj.path_sep);
    if ~isempty(dloc)
      myval = myval(dloc(end)+1:end);
    end
    
    if strcmpi(mylocs{i},myval)
      %Grab path to get row count position since indexing depends on wether root
      %node is displayed or not.
      p     = evrijavaobjectedt('javax.swing.tree.TreePath', nextnode.getPath);
      myrow = jtree.getRowForPath(p);
      %At correct location so expand to here.
      evrijavamethodedt('expandRow',jtree,myrow);
      drawnow
      mynode = nextnode;
      stillsearch = 1;
      
      %Run callback on last node in case there are icons that need to be
      %set. Note, '/' is the code for default file browser tree mode (see node_expand_callback).
      if ~isempty(mystruct) && ~strcmp(mystruct,'/') && ~isempty(find(ismember({mystruct.nam},mylocs{i})))
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

%Make last node the current selection.
if ~isempty(nextnode)
  p = evrijavaobjectedt('javax.swing.tree.TreePath', nextnode.getPath);
  if nextnode.getChildCount>0
    %If there are children scroll down so the are visible.
    chp = evrijavaobjectedt('javax.swing.tree.TreePath', nextnode.getChildAt(nextnode.getChildCount-1).getPath);
    evrijavamethodedt('scrollPathToVisible',jtree,chp);
  end
  evrijavamethodedt('setSelectionPath',jtree,p);
  evrijavamethodedt('scrollPathToVisible',jtree,p);
end


