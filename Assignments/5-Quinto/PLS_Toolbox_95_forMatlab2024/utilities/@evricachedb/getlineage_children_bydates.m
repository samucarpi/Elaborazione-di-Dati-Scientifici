function mynodes = getlineage_children_bydates(obj,myname,pid)
%EVRICACHEDB/GETLINEAGE_CHILDREN_BYDATES Get date list of items for given name.
% Returns node structure. 

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mynodes = [];
dbo = obj.dbobject;

if nargin<3
  pid = checkproject(obj);%Get current projectID.
end

% subqry = ['SELECT C.cacheID FROM evri_cache_db.sourceData SD, '...
%   'evri_cache_db.cache C, evri_cache_db.sourceAttributes SA '...
%   'WHERE SD.cacheID=C.cacheID AND SD.sourceAttributesID=SA.sourceAttributesID '...
%   'AND SA.name=''name'' AND SD.valChar=''' myname ''' AND C.projectID = ' num2str(pid)];
% 
% qry = ['SELECT C.cacheDate FROM '... 
% 'evri_cache_db.sourceData SD, evri_cache_db.cache C, evri_cache_db.sourceAttributes SA '...
% 'WHERE SD.cacheID=C.cacheID AND SD.sourceAttributesID=SA.sourceAttributesID '...
% 'AND SA.name=''date'' AND c.cacheID IN (' subqry ') AND C.projectID = ' num2str(pid)];

if strcmp(myname,'unnamed')
  qry = ['SELECT evri_cache_db.cache.cacheDate, evri_cache_db.cache.cacheID ' ...
    'FROM evri_cache_db.cache  LEFT JOIN evri_cache_db.view_Cache_with_name '...
    'ON evri_cache_db.cache.cacheID = evri_cache_db.view_Cache_with_name.vcacheID '...
    'WHERE evri_cache_db.cache.projectID = ' num2str(pid) ' AND evri_cache_db.cache.type = ''data'' ' ...
    'AND evri_cache_db.view_Cache_with_name.vcacheID IS NULL'];
else
  qry = ['SELECT VC.vCacheDate,VC.vCacheID FROM evri_cache_db.view_Cache_with_name '...
    'VC WHERE VC.vType=''data'' AND VC.vProjectID=' num2str(pid) 'AND VC.vName=''' myname ''''];
end

mydata = dbo.runquery(qry);
%Use sort this way so works in older versions of Matlab. Using sortrows
%wasn't working.
[junk,indx]=sort([mydata{:,1}],obj.date_sort);
mydata = mydata(indx,:);

%udates = unique(floor([mydates{:}]));

for i = 1:size(mydata,1)
  thisdate = datestr(mydata{i,1});
  mynodes(i).val = ['getlinks_children|' num2str(mydata{i,2})];
  mynodes(i).nam = thisdate;
  mynodes(i).str = thisdate;
  mynodes(i).icn = '';
  mynodes(i).isl = false;
  mynodes(i).chd = '';%Doesn't work with object ['getdate_children(''' thisdate ''')'];
end
