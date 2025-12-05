function nodes = node_expand_callback(tree, value, varargin)
%EVRITREE/NODE_EXPAND_CALLBACK Node expand callbck.
% This is assigned when tree is created in initialize.m. 
%   In node.val, use "/" as separator for hierarchical location. Use "|" if
%   a query should be used (via modelcache) to generate node children.
%

% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Expansion function for tree node.
obj = get_evritree_obj(varargin{1},varargin{2});

mytree   = obj.tree_data;
htree    = obj.tree;
rootnode = htree.getRoot;

%If tree is empty then stick a leaf in saying it's empty.
if isempty(mytree)
  nodes(1) = uitreenode_o('1', 'No Data Available', '', true);
  return
end

cpos = strfind(value,'|');%Look for query indicator.

if isempty(cpos)
  %Use / indexing to build leaf info.
  rem = value;
  L1 = {};
  while (any(rem))
    %Create cell array of stings with each field name as seperate cell.
    [S1, rem] = strtok(rem, obj.path_sep);
    L1 = [L1 {S1}];
  end
  
  %Remove drive letter (at root) if present.
  if ~isempty(L1)
    rval = char(rootnode.getName);
    if strcmp(L1{1},rval)
      L1 = L1(2:end);
    end
  end
  
  for i = 1:length(L1)
    %Step through structure to find child structure (.chd).
    idx = find(ismember({mytree.nam},L1{i}));
    if isfield(mytree,'isc') && mytree(idx).isc
      %This is the end of a cache structure with model/data information to be
      %displayed from database.
      sourceitem = getcacheindex(evricachedb,L1{i},1);
      mytree     = cachestruct('cacheobjinfo', [value obj.path_sep], sourceitem);
    else
      if ~isempty(idx) && isfield(mytree(idx),'chd')
        child = mytree(idx).chd;
        if strcmp(child,'/')
          %If single '/' then means in file browser mode so look up next level.
          mytree = get_path_struct(obj,mytree(idx).val);
        else
          mytree = child;
        end
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
      mytree     = cachestruct('cacheobjinfo', [qval obj.path_sep], sourceitem);
    end
  else
    child_idx = ismember({mytree.nam},qval);
    
    mytree = feval(qry,cobj,qval);
  end
end

if ~isempty(mytree)
  for i = 1:length(mytree)
    %Create nodes first then hand them to uicontrol on figure.
    nodes(i) = uitreenode_o(mytree(i).val,mytree(i).str,mytree(i).icn,mytree(i).isl);
    if isfield(mytree,'typ')
      nodes(i).UserData = mytree(i).typ;
    end
  end
else
  nodes = [];
end

%Set path of last noded clicked.
obj.last_path = get_path_from_node(obj,nodes);
set_evritree_obj(obj);

%Run additional callbacks if needed.
myfcn = obj.tree_nodeexpand_callback;
myvars = getmyvars(myfcn);
if iscell(myfcn)
  myfcn = myfcn{1};
end

if ~isempty(myfcn)
  feval(myfcn,tree,value,myvars{:},nodes);
end

%---------------------------
function myvars = getmyvars(myfcn)
%Get function from object.

myvars = {};
if iscell(myfcn) && length(myfcn)>1
  myvars = myfcn(2:end);
  myfcn = myfcn{1};
end


