function mystruct = getstruct(obj,mypath)
%EVRITREE/GETSTRUCT Get structure/sub structure for nodes.
% Get structure for underlying node data (structure array). If 'mypath' is
% specified, the sub structure for the path is retrieved.

% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Get sub struct of current tree node.
mystruct = [];

mystruct = obj.tree_data ;%Original tree structure data.

%If data is empty don't call anything and return.
if isempty(mystruct)
  return
end

if nargin<2 | isempty(mypath)
  %Same as obj.tree_data.
  return
end

rem = mypath;
L1 = {};
while (any(rem))
  %Create cell array of stings with each field name as seperate cell.
  [S1, rem] = strtok(rem, '/');
  L1 = [L1 {S1}];
end

%Locate and extract leaf inot mytree.
for i = 1:length(L1)
  if isempty(mystruct) | (length(mystruct)==1 & isempty(mystruct.nam))
    %We're at an undifined leaf.
    break
  end
  %Step through structure to find child structure (.chd).
  idx = find(ismember({mystruct.nam},L1{i}));
  if isempty(idx)
    %I'm at a leaf, don't try to expand.
    return
  end
  if i == length(L1)
    %Last branch of tree so don't index into child (chd).
    mystruct = mystruct(idx);
  else
    mystruct = mystruct(idx).chd;
  end
  
  if ~isstruct(mystruct)
    %We're in a spectial mode so return empty.
    mystruct = [];
    break
  end
end

