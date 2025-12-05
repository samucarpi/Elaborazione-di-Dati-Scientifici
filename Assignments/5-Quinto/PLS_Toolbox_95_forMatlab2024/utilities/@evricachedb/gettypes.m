function mynodes = gettypes(obj,pid)
%EVRICACHEDB/GETTYPES Get list of item types stored in db.
% Returns cell array of strings. If 'pid' is given then it is used, if
% it's a 0 then all projects are queried.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mynodes = [];
dbo = obj.dbobject;

if nargin<2
  pid = checkproject(obj);%Get current projectID.
end

typeqry = 'SELECT DISTINCT evri_cache_db.cache.type from evri_cache_db.cache';% order by evri_cache_db.cache.type';
if pid~=0
  typeqry = [typeqry ' WHERE evri_cache_db.cache.projectID= '  num2str(pid)];
end

mytypes = sortrows(dbo.runquery(typeqry));

for i = 1:length(mytypes)
  mynodes(i).val = ['gettype_children|' mytypes{i}];
  mynodes(i).nam = mytypes{i};
  mynodes(i).str = upper(mytypes{i});
  mynodes(i).icn = getcacheicon(mytypes{i});
  mynodes(i).isl = false;
  mynodes(i).chd = ['gettype_children(''' mytypes{i} ''')'];
end
