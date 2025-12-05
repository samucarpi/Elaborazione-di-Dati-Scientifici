function mynodes = getlinks_children(obj,myitem)
%EVRICACHEDB/GETLINKS Get items linked to 'myitem'.
% Returns list of item names linked to myitem.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mynodes = [];
dbo = obj.dbobject;

pid = checkproject(obj);%Get current projectID.

%Make data node.
linkqry = ['SELECT evri_cache_db.cache.name, evri_cache_db.cache.description, evri_cache_db.cache.type '...
  'FROM evri_cache_db.cache '...
  'WHERE evri_cache_db.cache.projectID= '  num2str(pid) ' AND  evri_cache_db.cache.cacheID = ' num2str(myitem)];
mydata = dbo.runquery(linkqry);

i = 1;
mynodes(i).val = ['cachestruct|' mydata{i,1}];
mynodes(i).nam = mydata{i,1};
mynodes(i).str = ['item: ' mydata{i,2}];
mynodes(i).icn = getcacheicon(mydata{i,3});
mynodes(i).isl = false;
mynodes(i).chd = '';%Doesn't work with object ['getdate_children(''' thisdate ''')'];
mynodes(i).isc = true;
mynodes(i).typ = mydata{i,3};

%Make child nodes.
linkqry = ['SELECT evri_cache_db.cache.name, evri_cache_db.cache.description, evri_cache_db.cache.type, evri_cache_db.cache.cacheDate '...
  'FROM evri_cache_db.link INNER JOIN evri_cache_db.cache ON evri_cache_db.link.cacheID=evri_cache_db.cache.cacheID '...
  'WHERE evri_cache_db.cache.projectID= '  num2str(pid) ' AND  evri_cache_db.link.childID = ' num2str(myitem)];
mydata = dbo.runquery(linkqry);

%Sort on date.
[junk,indx]=sort([mydata{:,end}],obj.date_sort);
mydata = mydata(indx,:);

if ~isempty(mydata) & ~isempty(mydata{1})
  for i = 1:size(mydata,1)
    mynodes(i+1).val = ['cachestruct|' mydata{i,1}];
    mynodes(i+1).nam = mydata{i,1};
    mynodes(i+1).str = ['item: ' mydata{i,2}];
    mynodes(i+1).icn = getcacheicon(mydata{i,3});
    mynodes(i+1).isl = false;
    mynodes(i+1).chd = '';%Doesn't work with object ['getdate_children(''' thisdate ''')'];
    mynodes(i+1).isc = true;
    mynodes(i+1).typ = mydata{i,3};
  end
end
