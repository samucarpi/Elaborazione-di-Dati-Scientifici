function mynodes = getlineage(obj,pid)
%EVRICACHEDB/GETLINEAGE Get list of item types stored in db.
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

%REMOVE THIS COMMENTED OUT CODE AFTER 6.5 RELEASE.
% %NOTE: This query gets anything with a "name" attribute. As of PLSTB 6.2
% %only Data has "name" but we may need to update this query to include
% %another WHERE clause "AND C.type=''data''" to refine only data records.
% %NOTE: Could use view_Cache_with_name view here as only table.
% qry = ['SELECT DISTINCT C.cacheID, SD.valChar, C.type FROM '...
% 'evri_cache_db.sourceData SD, evri_cache_db.cache C, evri_cache_db.sourceAttributes SA '...
% 'WHERE SD.cacheID=C.cacheID AND SD.sourceAttributesID=SA.sourceAttributesID '...
% 'AND SA.name=''name'' AND C.projectID = ' num2str(pid)];

qry = ['SELECT VC.vCacheID, VC.vName, VC.vType FROM evri_cache_db.view_Cache_with_name VC '...
  'WHERE VC.vType=''data'' AND  VC.vProjectID = ' num2str(pid)];

vdata = dbo.runquery(qry);

if isempty(vdata{1})
  viewnames = '';
else
  %Check for empty cells. In some weird cases it appears that some data
  %doesn't get added with a name and then causes a [] rather than '' here.
  %This might be fixed in runquery somehow in the future.
  ecells = cellfun('isempty',vdata(:,2));
  if any(ecells)
    %Empty name found, replace with empty string.
    vdata(ecells,2) = {''};
  end
  
  viewnames = sortrows(vdata,2);
  [junk, uniqueidx] = unique(viewnames(:,2));
  mynames = viewnames(uniqueidx,[2 3]);
  
  for i = 1:size(mynames,1)
    mynodes(i).val = ['getlineage_children_bydates|' mynames{i,1}];
    mynodes(i).nam = mynames{i,1};
    mynodes(i).str = mynames{i,1};
    mynodes(i).icn = getcacheicon(mynames{i,2});
    mynodes(i).isl = false;
    mynodes(i).chd = '';%Doesn't workw with feval. ['getlineage_children_date(''' mynames{i,1} ''')'];
  end
end

qry = ['SELECT DISTINCT C.cacheID, C.name, C.type FROM evri_cache_db.cache C '...
  'WHERE C.type=''data'' AND C.projectID = ' num2str(pid)];

allnames = sortrows(dbo.runquery(qry),2);

if size(allnames,1)>size(viewnames,1)
  %Add no
  mynodes(end+1).val = ['getlineage_children_bydates|unnamed'];
  mynodes(end).nam = 'unnamed';
  mynodes(end).str = 'Unnamed Data';
  mynodes(end).icn = getcacheicon('data');
  mynodes(end).isl = false;
  mynodes(end).chd = '';%Doesn't workw with feval. ['getlineage_children_date(''' mynames{i,1} ''')'];
end






