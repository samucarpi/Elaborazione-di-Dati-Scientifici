function checkcachedb(obj,forceme)
%EVRICACHEDB/CHECKCACHEDB Check to make sure DB location hasn't changed.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NOTE: This is a bit complicated because we use persistent and stored lists
%of the cache to speed things up. These all need to be rebuilt when you
%change caches.

dbobj = obj.dbobject;

mc_dir = modelcache('cachefolder');
db_dir = dbobj.location;

if nargin<2
  forceme = 0;
end

if ~strcmp(mc_dir,db_dir) || forceme
  %evriwarndlg(['Model Cache folder has changed. Database connection will be updated. ' ...
  %  'Please restart or refresh all application that display the Model Cache.'],'Cache Location Change');
  dbobj.shutdown_derby;
  %Note that database location is how we persistent identify connection objects so we
  %need to close the old location and open the new location.
  
  %Need to get all references before java object is deleted.
  dbobj.closeconnection_force;
  clear('dbobj');
  
  %set(obj,'dbobject',getdatabaseobj(obj));
  
  obj.dbobject = getdatabaseobj(obj);
  dbobj = obj.dbobject;
  dbobj.getconnection;%Make call to connect so new location gets saved out.
  createcachedb(obj);
  
  %Refresh persistent/stored vars.
  checkcache(obj,'refresh_cache_list');
  checkproject(obj,'refresh_project_list');
  
  setappdata(0,'evri_cache_object',obj);
  modelcache('getcache','rebuildcache');
end
