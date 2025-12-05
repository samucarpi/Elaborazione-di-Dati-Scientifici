function out = getmoddates(obj,pid,flag,myname)
%EVRICACHEDB/GETMODDATES Get list of cachid/moddates for given project.
% Input 'flag' (0/1) will add additional cache item information to output.
%
% NOTE: This query can be costly for large caches since it's retrieving 6 element
% date vectors for every cache item and can't use a where clause.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

dbo = obj.dbobject;

if nargin<2
  pid = checkproject(obj);%Get current projectID.
end
if nargin<3
  flag = 0;
end
if nargin<4
  myname = '';
end

qry = ['SELECT SD.cacheID, SD.valNum FROM '...
  'evri_cache_db.sourceData SD, evri_cache_db.cache C, evri_cache_db.sourceAttributes SA '...
  'WHERE SD.cacheID=C.cacheID AND SD.sourceAttributesID=SA.sourceAttributesID '...
  'AND (SA.name=''moddate'' OR SA.name=''time'') AND C.projectID = ' num2str(pid) ' ORDER BY SD.sourceDataID'];%Make sure ordered so when we recombine date vectors they're in right order.

if ~isempty(myname)
  subqry = ['SELECT C.cacheID FROM evri_cache_db.sourceData SD, '...
    'evri_cache_db.cache C, evri_cache_db.sourceAttributes SA '...
    'WHERE SD.cacheID=C.cacheID AND SD.sourceAttributesID=SA.sourceAttributesID '...
    'AND SA.name=''name'' AND SD.valChar=''' myname ''' AND C.projectID = ' num2str(pid)];
  qry = [qry  ' AND c.cacheID IN (' subqry ')'];
end


if flag
  %Get other cache data for given project.
  qry2 = ['SELECT C.cacheID, C.name, C.type, C.description FROM evri_cache_db.cache C '...
  'WHERE C.projectID = ' num2str(pid)];
  cdata = dbo.runquery(qry2);
end

mydata = dbo.runquery(qry);
mydata = [[mydata{:,1}]; [mydata{:,2}]]';
sids = unique(mydata(:,1));
out = [];
for i = 1:length(sids)
  this_data = mydata(sids(i)==mydata(:,1),2)';
  if isempty(this_data)
    continue;
  end
  if flag
    out = [out;{datenum(this_data)} cdata(ismember([cdata{:,1}],sids(i)),:)];
  else
    out = [out; {datenum(this_data)} {sids(i)}];
  end
end
