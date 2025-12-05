function mynodes = getdate_children(obj,myday,pid)
%EVRICACHEDB/GETDATE_CHILDREN Get list of items for given day.
% Returns cell array of strings. If 'pid' is given then it is used, if
% it's a 0 then all projects are queried.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mynodes = [];
dbo = obj.dbobject;

if nargin<2
  myday = floor(now);
elseif ~isnumeric(myday)
  myday = datenum(myday);
end

if nargin<3
  pid = checkproject(obj);%Get current projectID.
end

switch obj.date_source
  case 'moddate'
    mydates = getmoddates(obj,pid,1);
  case 'cachedate'
    mydates = getcachedates(obj,pid,1,myday);
end

if isempty(mydates)
  return
end

%FIXME: Move this code to getcachedates.m.
thisday = num2str(myday);
mychildren = mydates([mydates{:,1}]>myday,:);
mychildren = mychildren([mychildren{:,1}]<(myday+1),:);

% typeqry = ['SELECT mc.name, mc.description, mc.type from evri_cache_db.cache AS mc WHERE mc.cacheDate > ' num2str(myday) ' AND mc.cacheDate < ' num2str(myday+1)];
% if pid~=0
%   typeqry = [typeqry ' AND mc.projectID= '  num2str(pid)];
% end

%Add descend sorting of children to match that of the parent leaf.
[B,IX] = sort([mychildren{:,1}],obj.date_sort);
mychildren = mychildren(IX,:);

for j = 1:size(mychildren,1)
  mynodes(j).val = ['cachestruct|' mychildren{j,3}];
  mynodes(j).nam = mychildren{j,3};
  mynodes(j).str = ['item: ' mychildren{j,5}];
  mynodes(j).icn = getcacheicon(mychildren{j,4});
  mynodes(j).isl = false;
  mynodes(j).chd = [];%Info queried from cache DB now. cacheobjinfo([types{i} '/' mychildren(j).name '/'],mychildren(j));
  mynodes(j).isc = true;
  mynodes(j).typ = mychildren{j,4};
end
