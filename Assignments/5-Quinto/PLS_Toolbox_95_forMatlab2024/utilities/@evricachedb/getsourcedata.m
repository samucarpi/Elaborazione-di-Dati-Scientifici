function out = getsourcedata(obj,sids,att)
%EVRICACHEDB/GETSOURCEDATA Get source data table for a vector of cachIDs.
% This should be fast way of getting large index of source data using
% temporary table. Input 'sids' can be a numeric array of ID numbers or
% cell array of cacheID names (string). Input 'att' is a string of a single
% attribute to get data for.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

dbo = obj.dbobject;
out = [];

if nargin<3
  att = [];
end

if iscell(sids) && ischar(sids{1})
  %using a list of names so conver to IDs.
  temp_ids = [];
  junk = [];
  projid = addproject(obj, modelcache('projectfolder'));  %project ID (makes sure its there too)
  for i = 1:length(sids)
    junk.name = sids{i};
    temp_ids(i) = checkcache(obj,junk,projid);
  end
  sids = temp_ids;
end

%Create temp table if it's not there.
myconn = dbo.getconnection;
metadata = myconn.getMetaData;%Can't index so have to use 2 calls.
table_rs = metadata.getTables('','EVRI_CACHE_DB','TEMP_CACHE_ID','TABLE');
if ~table_rs.next
  dbo.runquery('CREATE TABLE evri_cache_db.temp_cache_id ( cacheID INTEGER NOT NULL )');
end

%Remove all rows.
dbo.runquery('DELETE FROM evri_cache_db.temp_cache_id');

sqlstr = ['INSERT INTO evri_cache_db.temp_cache_id (cacheID) VALUES (?)'];
if size(sids,2)>1
  sids = sids';
end
%Fast way of populating table.
jpreparedstatement(dbo,sqlstr,num2cell(sids),{'Int'});

if isempty(att)
  %Now do select with join and no where clause.
  dataqry = ['SELECT sourceData.* FROM evri_cache_db.sourceData INNER JOIN '...
    'evri_cache_db.temp_cache_id ON evri_cache_db.sourceData.cacheID=evri_cache_db.temp_cache_id.cacheID'];
  out = dbo.runquery(dataqry);
else
  source_info = dbo.runquery(['SELECT * FROM evri_cache_db.sourceAttributes WHERE name = ''' att '''']);
  if isempty(source_info)
    return
  end
  dataqry = ['SELECT sourceData.* FROM evri_cache_db.sourceData INNER JOIN '...
    'evri_cache_db.temp_cache_id ON evri_cache_db.sourceData.cacheID=evri_cache_db.temp_cache_id.cacheID '...
    'AND evri_cache_db.sourceData.sourceAttributesID = ' num2str(source_info{1})];
  mydata = dbo.runquery(dataqry);
  for i = 1:length(sids)
    this_data = mydata(ismember([mydata{:,2}],sids(i)),:);
    if isempty(this_data)
      continue;
    end
    switch source_info{3}
      case 'numeric'
        out = [out; {[this_data{:,5}]}];
      case 'string'
        out = [out; this_data(:,4)];
      case 'xml'
        if ~isempty(mydata)
          out = [out; {parsexml(this_data{:,4})}];
        end
    end
  end
end

