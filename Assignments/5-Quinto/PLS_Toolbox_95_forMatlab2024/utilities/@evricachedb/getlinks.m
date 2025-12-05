function mylinks = getlinks(obj,myitem)
%EVRICACHEDB/GETLINKS Get items linked to 'myitem'.
% Returns list of item names linked to myitem.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mylinks = [];
dbo = obj.dbobject;

pid = checkproject(obj);%Get current projectID.

if ischar(myitem)
  %Passing name as lookup.
  item.name = myitem;
  val = checkcache(obj,item,pid);
elseif isstruct(myitem)
  %Passing item structure.
  val = checkcache(obj,myitem,pid);
else
  %Passing id number.
  val = myitem;
end

if ~isempty(val)
  if length(val)>1
    linkqry = ['SELECT evri_cache_db.cache.name,evri_cache_db.link.cacheID FROM evri_cache_db.link INNER JOIN '...
      'evri_cache_db.cache ON evri_cache_db.link.childID=evri_cache_db.cache.cacheID '...
      'WHERE evri_cache_db.cache.projectID= '  num2str(pid)];
    mylinks = dbo.runquery(linkqry);
    if iscell(mylinks) & size(mylinks,2)>1 & size(mylinks,1)>1
      use = ismember([mylinks{:,2}],val);
      mylinks = mylinks(use,:);
    end
  else
    %single val? get JUST that item
    linkqry = ['SELECT evri_cache_db.cache.name FROM evri_cache_db.link INNER JOIN '...
      'evri_cache_db.cache ON evri_cache_db.link.cacheID=evri_cache_db.cache.cacheID '...
      'WHERE evri_cache_db.cache.projectID= '  num2str(pid) ' AND  evri_cache_db.link.childID = ' num2str(val)];
    mylinks = dbo.runquery(linkqry);
  end
end
