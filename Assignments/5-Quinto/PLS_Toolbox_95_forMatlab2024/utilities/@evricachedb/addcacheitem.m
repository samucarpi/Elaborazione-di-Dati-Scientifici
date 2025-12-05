function val = addcacheitem(obj,item,prj_name)
%EVRICACHEDB/ADDCACHEITEM Add an item structure to the cache.
% 

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

dbo = obj.dbobject;
checkcachedb(obj)
if nargin<3
  prj_name = modelcache('projectfolder');%Use current project.
end
  
%Add new project (if needed) and get ID number.
prjID = addproject(obj, prj_name);

%Check for existing item.
val = checkcache(obj,item,prjID);

if isempty(val)
  %Add new item.
  dsc = item.description;
  if length(dsc)>1000
     dsc = dsc(1:1000);
  end
  nm = item.name;
  if length(nm)>100
    nm = nm(1:100);
  end
  %sqlstr = ['INSERT INTO evri_cache_db.cache (projectID,name,type,description,cacheDate) VALUES ('...
  %  num2str(prjID) ', ''' nm ''', ''' item.type ''', ''' dsc ''', ' sprintf('%0.20g',now) ')'];
  %val = dbo.runquery(sqlstr);%Get ID back.
  sqlstr = ['INSERT INTO evri_cache_db.cache (projectID,name,type,description,cacheDate) VALUES ('...
    '?, ?, ?, ?, ?)'];
  val = jpreparedstatement(dbo,sqlstr,{prjID nm item.type dsc now},{'Int','String','String','String','Double'});
  val = val{:};
else
  %List out of date so just update timestamp.
  sqlstr = ['UPDATE evri_cache_db.cache SET cacheDate=' sprintf('%0.20g',now) ' WHERE cacheID= ' num2str(val) ];
  numrows = dbo.runquery(sqlstr);%Update query just returns rows affected.
  if numrows>1
    error('More than one row was updated in modelcache additem, database has duplicate data.')
  end
  return
end

%Add links.
if ~isempty(item.links)
  wc = '';
  for i = 1:length(item.links)
    %Create where clause.
    wc = [wc 'name = ''' item.links(i).target ''' OR '];
  end
  wc(end-3:end) = '';
  
  sqlstr = ['INSERT INTO evri_cache_db.link (cacheID, childID) SELECT ' num2str(val) ', evri_cache_db.cache.cacheID '...
            'FROM evri_cache_db.cache WHERE ' wc ];
  id_junk = dbo.runquery(sqlstr);
end

%Add source info.
addsource(obj,item,val);



