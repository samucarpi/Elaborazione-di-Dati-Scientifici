function setselected(obj,myloc)
%EVRITREE/SETSELECTED Expand tree to old location.
%
% Assume we have to do it this "manual" (loop through) way because of load
% children lazy method (i.e., children are created at time of use and not
% all at once).
%
% Also will only expand to last location all other expanded nodes will
% collapse. In future we can have more dynamic interaction with nodes and
% cache.

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

return

%Need to figure out best way to impelement old code below.

if nargin<2 | isempty(myloc)
  myloc = getappdata(obj.parent_figure,'cachetreelocation');
end

%Stopped here.

if isempty(myloc) || myloc.isRoot
  return
end

%Walk up last tree pos and creat a path.
mysteps = char(myloc.getName);
myloc = myloc.getParent;
while ~myloc.isRoot
  mysteps = [char(myloc.getName) obj.path_sep mysteps];
  myloc = myloc.getParent;
end
myloc = mysteps;

mytree = getappdata(fh,'treeparent');
mystruct = getappdata(fh,'treestructure');
jtree = mytree.getTree;
rootnode = mytree.getRoot;

if isempty(myloc)
  return
end

mysep = obj.path_sep;
if strcmp(mysep,'\')
  %Need to escape.
  mysep = '\\';
end

%Start at top node and start searching down myloc for leaf nodes
mylocs = textscan(myloc,'%s','delimiter',mysep); %parse location.
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
    dloc  = strfind(myval,obj.path_sep);
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

