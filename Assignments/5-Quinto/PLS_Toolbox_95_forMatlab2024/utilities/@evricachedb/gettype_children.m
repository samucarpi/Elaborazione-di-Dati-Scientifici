function mynodes = gettype_children(obj,mytype,pid)
%EVRICACHEDB/GETTYPE_CHILDREN Get list of items for given type.
% Returns cell array of strings. If 'pid' is given then it is used, if
% it's a 0 then all projects are queried.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mynodes = [];
dbo = obj.dbobject;

if nargin<2
  mytype = 'data';
end

if nargin<3
  pid = checkproject(obj);%Get current projectID.
end
  
typeqry = ['SELECT mc.name, mc.description from evri_cache_db.cache AS mc WHERE mc.type = ''' mytype ''''];
if pid~=0
  typeqry = [typeqry ' AND mc.projectID= '  num2str(pid)];
end

mychildren = dbo.runquery(typeqry);
mychildren = sortrows(mychildren);

for j = 1:size(mychildren,1)
  mynodes(j).val = ['cachestruct|' mychildren{j,1}];
  mynodes(j).nam = mychildren{j,1};
  mynodes(j).str = ['item: ' mychildren{j,2}];
  mynodes(j).icn = getcacheicon([mytype]);
  mynodes(j).isl = false;
  mynodes(j).chd = [];%Info queried from cache DB now. cacheobjinfo([types{i} '/' mychildren(j).name '/'],mychildren(j));
  mynodes(j).isc = true;
  mynodes(j).typ = mytype;
end
