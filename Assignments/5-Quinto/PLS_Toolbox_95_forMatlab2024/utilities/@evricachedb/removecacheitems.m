function myids = removecacheitems(obj,items)
%EVRICACHEDB/REMOVECACHEITEMS Remove list of items.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

success = false;
dbo = obj.dbobject;

pid = checkproject(obj);%Get current projectID.

myids = [];
for i = 1:length(items)
  myids = [myids; checkcache(obj,items(i),pid)];
end

if ~isempty(myids)
  sqlstr = ['DELETE FROM evri_cache_db.cache WHERE projectID= ? AND cacheID= ? '];
  pdata = num2cell([repmat(pid,length(myids),1) myids]);
  jpreparedstatement(dbo,sqlstr,pdata,{'Int','Int'});
end
