function varargout = modelcache(varargin)
%MODELCACHE Stores and retrieves models in the model cache.
%
% Model Cache commands (these commands may require one or more inputs.)
%  Retreiving Cache Items and Information
%   list              - Display hyperlinked list of model cache.
%   get               - Retrieve one object from the cache by its uniquename.
%   getparents        - Retrieves all objects linked as "used by" a given object.
%   getchildren       - Retrieves all objects linked as "using" a given object.
%   getinfo           - Returns cache item informaiton if object is in cache.
%
%  Editing Cache
%   settings          - Display optionsgui to adjust settings.
%   setdescription    - Change description for an existing entry.
%   deleteitem        - Remove item(s) specified by name from the cache.
%   deletedates       - Remove item(s) > or < a given date (input dir is a
%                       string comparison operator: '>','>=','<' or '<='
%                       indicating how to compare to the given date(s). Up
%                       to two comparison/date pairs can be given. E.g:
%                         ('deletedates','>','2012-10-08')
%                         ('deletedates','>','2012-10-08','<','2012-10-12')
%   deletedatesforce  - Same as deletedates but forces deletion without
%                       user confirmation
%   purgecache        - Remove old items from cache.
%   clear             - Clear entire cache.
%   whos              - Returns a "whos"-style structure of all the objects in the cache.
%   reset             - Reset the database and all internally stored information.
%   
%I/O: modelcache(model)
%I/O: modelcache(model,data)
%I/O: modelcache(model,data,prediction)
%I/O: modelcache list            %list all cached objects
%I/O: modelcache clear           %manually purge cache
%I/O: modelcache settings        %modify modelcache settings
%I/O: success = modelcache('setdescription','name','description')
%I/O: obj     = modelcache('get',name)  %retrieve object from cache by name
%I/O: objs    = modelcache('getparents',obj)  %retrieve object's parents from cache
%I/O: objs    = modelcache('getchildren',obj)  %retrieve object's children from cache
%I/O: list    = modelcache('whos')   %return whos-style structure of objects
%I/O: modelcache('deleteitem',{name1,name2,...})  %remove items from cache
%I/O: modelcache('deletedates',comp,'yyyy-mm-dd')  %remove items before/after this date
%I/O: modelcache('deletedates',comp,'yyyy-mm-dd',comp,'yyyy-mm-dd')
%I/O: modelcache('deletedatesforce',comp,'yyyy-mm-dd')  %delete without confirmation
%
%See also: EVRIDIR

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% HIDDEN HELP
%  Low-level commands (some of these commands are of internal use only)
%   addindex          - Add the indicated information to an index (if not there already).
%   cachefolder       - Get cache directory name.
%   getcache          - Get a tree-based list of objects.
%   getdatasourceplus - Extract all information about data.
%   getmodelsource    - Extract all information about a model.
%   linkstruct        - Create empty link structure.
%   projectfolder     - Get current project directory.
%   save_uniquename   - Returns a unique string which describes the given object, uses UNIQUENAME function.


persistent badfolder modelcache_purged

%check for evriio (with pre-filter to look for local function names to
%reduce calls to evriio and speed some things up)

if nargin==0; varargin = {'io'};end
fevalcall = false;
if ischar(varargin{1})
  switch varargin{1}
    case {'optiondefs' 'cachefolder' 'projectfolder' 'purgecache' 'getcache' 'getparents' 'getchildren' 'listcache' ...
        'whoscache' 'getobj' 'getinfo' 'getdatasourceplus' 'uniquename' 'linkstruct' 'addindex' 'getmodelsource' ...
        'save_uniquename'}
      fevalcall = true;
  
    case evriio([],'validtopics') %Help, Demo, Options
      options = [];
      options.cache = 'on';          % 'on' 'off' 'readonly'
      options.cachefolder = '';      %base cache folder (default is usually: temp/modelcache
      options.project     = '';      %project folder (sub of cachefolder)
      options.maxindexlength = 500;   %maximum number of items in an index file
      options.maxdatasize = 6000^2;   %maximum size of data that can be saved
      options.maxage      = 90;       %maximum number of days to keep items in cache
      options.alertpurgedays  = 30;   %alert user when oldest purged item is older than this many days
      options.alertpurgeitems = 100;   %alert user when this many ITEMS will be purged at once
      options.lineage_date_sort = 'descend';
      options.definitions = @optiondefs;
      if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
      return;
  end
end

%==============================================
%------ FORCE UPGRADE------
%Remove this before release.
if ischar(varargin{1}) & isempty(getappdata(0,'modelcache_force_install'))
  setappdata(0,'modelcache_force_install',1)
  %If new cache doesn't exist and there's an option or old-style temp
  %folder then go for upgrade.
  if ~exist(fullfile(cachefolder,'evri_cache_db'),'dir') & ...
      (exist(cachefolder,'dir') | exist(fullfile(tempdir,'modelcache'),'dir'))
    %Force an upgrade to developers.
    answer = evriquestdlg('Would you like to start a new cache, upgrade your existing cache, or turn model caching off?', ...
      'Existing Model Cache Found','New','Upgrade','Turn Off','New');
    switch answer
      case 'Turn Off'
        setplspref('modelcache','cache','off');
      case 'Upgrade'
        modelcache('upgradecache');
      case 'New'
        %Start new cache in default folder.
        setdefaultcachefolder
    end
  end
end

%==============================================
%NOTE: Set an appdata flag that acts like cache on/off but does not turn it
%off since we don't want to mess with that.
modelcache_check_connection = getappdata(0,'modelcache_check_connection');
if (isempty(modelcache_check_connection) | (now-modelcache_check_connection)>.001)
  %Check to see if connection works, if another Matlab is accessing then we
  %need to turn off the cache. Check every minute.
  setappdata(0,'modelcache_check_connection',now)
  options = modelcache('options');
  if strcmpi(options.cache,'on') && exist(fullfile(options.cachefolder,'evri_cache_db'),'dir')
    cobj = evricachedb;
    %Cache object used to return empty if cache couldn't connect but syntax
    %upgrade changed that behavior, so object is always returned. Now run
    %connection .test instead of check for empty.
    if ~cobj.test %isempty(cobj)
      if isempty(getappdata(0,'modelcache_multiple_connections'))
        evriwarndlg(['Unable to connect to existing cache database. Another '...
          'Eigenvector Research product may be locking the connection. Cache will be be '...
          'turned off until connection can be made.'],'Unable to Connect to Cache Database')
      end
      setappdata(0,'modelcache_multiple_connections',1)
    else
      %We have a good connection so check to see if multiple_connections
      %flag was set. If so then we can trun cache back on.
      if ~isempty(getappdata(0,'modelcache_multiple_connections'))
        setappdata(0,'modelcache_multiple_connections',0);
      end
    end
  end
end

%If DB is locked, need to disable until unlocked.
if ~isempty(getappdata(0,'modelcache_multiple_connections')) && ... %Flag exits.
    getappdata(0,'modelcache_multiple_connections') && ... %Flag is set to 1 = multiple connections exist.
    ~(ischar(varargin{1}) && ismember(varargin{1},{'optiondefs' 'cachefolder' 'projectfolder'})) %Not looking for cache location info, e.g., cache object uses 'cachefolder' call.
  %DB is locked so we're effectively truned off.
  if nargout>0
    [varargout{1}] = [];
  end
  return;
end

%==============================================
%now ready to do real work - check for call to sub-function
if fevalcall
  %('command',...) calling sub-function
  fevalcall = true;
  getoptions; %refresh stored options
  if nargout==0
    feval(varargin{:});
  else
    [varargout{1:nargout}] = feval(varargin{:});
  end
  return
end

%==============================================
%not a sub-function call, caching data...

getoptions; %refresh stored options
%getindex;  %force reread of index files

%check for "settings" command
if ischar(varargin{1})
  %non evriio command
  switch varargin{1}
    case 'settings'
      opts = optionsgui(mfilename);
      if isempty(opts);
        return;
      end
      
      %Check for sorting setting and change in objet.
      cobj=getcacheobj;
      if ~strcmp(opts.lineage_date_sort,cobj.date_sort)
        cobj.date_sort = opts.lineage_date_sort;
        setappdata(0,'evri_cache_object',cobj)
      end
      
      setplspref(mfilename,opts);
      return
  end
end

%Need to create object first before calling .mkdirs otherwise causes errors
%in ML 6.5. Use java so file hierarchy is created.
myfileobj = java.io.File(cachefolder,projectfolder);

%make sure cachefolder exists
if ~myfileobj.mkdirs && ~exist(fullfile(cachefolder,projectfolder),'file')
  if isempty(badfolder)
    badfolder = 1;
    erdlgpls('Model cache folder or project folder was invalid and could not be created. The model cache has been disabled.','Model Cache Folder Error');
  end
  if nargout>0; varargout = cell(1,nargout); end
  return;
end
badfolder = [];  %we made the folder succssfully, reset until next error

%check if we need to clear out the cache
if isempty(modelcache_purged) && (ischar(varargin{1}) && ~ismember(varargin{1},{'upgradecache','changecachedir','movecache' 'projectlist'}))
  options = getoptions;
  modelcache_purged = 1;  %note so we don't try again this session
  if strcmp(options.cache,'on');
    try
      purgecache;
    catch
      erdlgpls('Unable to purge cache automatically. Use "modelcache clear" command to clear cache manually.','Model Cache Purge Error');
    end
  end
end

if ischar(varargin{1})
  %non evriio command
  switch varargin{1}
    case 'clear'
      %clear entire cache
      options = getoptions;
      if ~strcmp(options.cache,'on'); return; end  %cache is not on - return

      %get list of all items in cache
      index = getcache;
      todelete = {};
      for j=1:length(index);
        todelete{j} = findfile(index(j));
      end
      %and all index files in cache
      files    = dir(fullfile(cachefolder,projectfolder,'cacheindex*.mat'));
      for j=1:length(files);
        todelete = [todelete fullfile(cachefolder,projectfolder,files(j).name)];
      end

      for j=1:length(todelete);
        file = todelete{j};
        if exist(file,'file');
          delete(file);
        end
      end
      clearcache
      
      return
    case 'list'
      if nargin==2;
        %get a data set list
        listcache(varargin{2});
      else
        listcache;
      end
      return
      
    case 'whos'
      varargout = {whoscache};
      return
      
    case 'get'
      if nargin<2;
        error('Command "get" requires the object name to retrieve');
      end
      varargout = {getobj(varargin{2})};
      return
      
    case 'find'
      %NOTE: This doen't work because of unique naming.
      if nargin<2;
        error('Command "find" requires the object to check.');
      end
      varargout = {getinfo(varargin{2})};
      return
      
    case 'cachedir'
      varargout = {cachefolder};
      return
    case 'changecachedir'
      %Change current cache directory.
      old_dir = getplspref('modelcache','cachefolder');
      old_project = projectfolder;
      
      %Get new dir.
      if isempty(varargin{2})
        curcacheparent = fileparts(old_dir);
        new_dir = evriuigetdir(curcacheparent,'Locate New Cache Folder');
        if new_dir==0
          %User cancel.
          return
        end
      else
        new_dir = varargin{2};
      end
      
      if ~isdir(new_dir)
        warning('EVRI:ModelcacheFolderNotFound',['New modelcache folder can''t be found.']) 
        return
      end
      
      setplspref('modelcache','cachefolder',new_dir);
      getoptions;
      %Need to make sure not to add old project to new cache.
      new_projects = getprojectlist;
      if isempty(new_projects) || ~ismember(old_project,new_projects)
        %Just set to general.
        setplspref('modelcache','project','general');
      end
      resetcache;
      
%       %TODO: Maybe use "reset"
%       
%       %FIXME: Old project is used in new cache, need to switch project to
%       %general or something else in new cache.
%       
%       %Clear the index so it gets rebuild.
%       setappdata(0,'evri_cache_index',[]);
%       cobj = getcacheobj;
%       if ~strcmp(fullfile(old_dir),fullfile(new_dir))
%         %Force a chache database connection update.
%         cobj.checkcachedb(1);
%       end
%      evritreefcn([],'update');
      return
    case 'movecache'
      %Move entire cache folder from current to a new parent folder.
      movecache(varargin{2});
      return
    case 'upgradecache'
      %Move cache folder to new default location (if needed) then parse the
      %index files into the database.
      options = getoptions;
      msuccess = true;
      oldcache = find_old_cache;%
      if ~isempty(oldcache)&&~strcmp(oldcache,options.cachefolder)
        %Move existing folder from old default to new default.
        msuccess = movecache(evridir,oldcache);
        if ~msuccess
          evriwarndlg('Unable to move existing cache files to new default location. Files will be left in existing location. A new cache will be initialized in the default location. Contact helpdesk@eigenvector.com for additional assitance.','Model Cache Move Error');
        end
      else
        %Building in current cache location, confirm db is built.
        cobj = getcacheobj;
        cobj.checkcachedb(1);
      end
      %Parse all [project] index files into database.
      if msuccess
        psuccess = parsecachefiles;
        if ~psuccess
          evriwarndlg('Unable to parse existing cache files into database. Files may not appear in cache.','Model Cache Parse Error');
        end
      end
      return
    case 'changeproject'
      setplspref('modelcache','project',varargin{2});
      getoptions;
      modelcache('reset')
      %getcache('rebuildcache');
    case 'removeproject'
      pname = varargin{2};
      
      myans = evriquestdlg('Project folder and all data and models within it will be permanently deleted. Is this OK?','Delete Project');
      if ~strcmpi(myans,'yes')
        return
      end
      %Remove from cachedb.
      removeproject(getcacheobj,pname)
      %Remove folder, some latency so try in while loop.
      count = 1;
      while exist(fullfile(cachefolder,pname),'dir')
        rmdir(fullfile(cachefolder,pname),'s');
        count = count+1;
        if count>1000
          break
        end
      end
      %Change current project if needed.
      curproject = modelcache('projectfolder');
      if strcmp(curproject,pname)
        plist = getprojectlist;
        if ~isempty(plist)
          newproject = plist{1};
        else
          newproject = 'general';
        end
        setplspref('modelcache','project',newproject);
      end
      getoptions;
      getcache('rebuildcache');
    case 'renameproject'
      oldname = varargin{2};
      newname = varargin{3};
      
      %Rename in DB.
      renameproject(getcacheobj,oldname,newname);
      %Rename folder.
      movefile(fullfile(cachefolder,oldname),fullfile(cachefolder,newname));
      %Check if need to change current project
      curproject = modelcache('projectfolder');
      if strcmp(curproject,oldname)
        setplspref('modelcache','project',newname);
      end
      getoptions;
      getcache('rebuildcache');
    case 'combineproject'
      fromname = varargin{2};
      toname   = varargin{3};
      
      %Combine in DB.
      success = combineprojects(getcacheobj,fromname,toname);
      
      %Error out if can't find project in database.
      if ~success
        error('Can''t locate project in Cache database.')
      end
      
      %Move files.
      combinecache(fullfile(cachefolder,fromname),fullfile(cachefolder,toname));
      curproject = modelcache('projectfolder');
      if strcmp(curproject,fromname)
        setplspref('modelcache','project',toname);
      end
      getoptions;
      getcache('rebuildcache');
    case 'projectdir'
      varargout = {projectfolder};
      return
    case 'projectlist'
      varargout{1} = getprojectlist;
      return
    case 'exist'
      if nargin<2;
        error('Command "exist" requires the object name to check.');
      end
      varargout{1} = {existobj(varargin{2})};
      return
    case 'reset'
      resetcache;
      return
    case 'export'
      if nargin<2;
        error('Command "exist" requires the object name to check.');
      end
      varargout{1} = {exportobj(varargin{2})};
      return
    otherwise
      if nargout==0
        feval(varargin{:});
      else
        [varargout{1:nargout}] = feval(varargin{:});
      end
      return
  end
end

%- - - - - - - - - - - - - - - - - - - - - - - - -
% Have model and/or data to store in cache

options = getoptions;
if ~strcmp(options.cache,'on')
  %(either 'off' or 'readonly' gets us here)
  %if disabled by preferences, return now
  return
end

modl = varargin{1};
switch nargin
  case 1
    data = [];
    pred = [];
  case 2
    data = varargin{2};
    pred = [];
  case 3
    data = varargin{2};
    pred = varargin{3};
end
if ~iscell(data)
  %convert to cell if not
  data = {data []};
end

%All objects are now summarized for these outputs
%  index(i).name = modelname;
%          .source = modelsource;
%          .links  = modellinks;
%          .filename = '';

%- - - - - - - - - - - - - - - - - - - - - - - - -
% get descriptors of data blocks
dataname = {};
for j=1:length(data);
  if ~isempty(data{j}) && isdataset(data{j})
    %actual dataset - get info from it
    datasource  = getdatasourceplus(data{j});
    %translate datasource info into unique name
    dataname{j} = save_uniquename('data',datasource);
    %NOTE: datalinks are not currently resolved to anything so they will
    %remain empty
    datalinks = linkstruct;

    addindex('data',data{j},dataname{j},datasource,datalinks);
  end
end

%- - - - - - - - - - - - - - - - - - - - - - - - -
%if there was a model, see about getting descriptor of that
if ~isempty(modl) & ismodel(modl)
  modelname   = save_uniquename('model',modl);
  modelsource = getmodelsource(modl);
  modellinks  = linkstruct;
  if isempty(pred) | ~ismodel(pred)
    %if the data isn't associated with the PREDICTION instead of the
    %model, get links to the data
    if ~isempty(dataname)
      %if we were passed data with this model, use it as the reference
      for j=1:length(dataname);
        modellinks = [modellinks linkstruct(dataname{j})];
      end
    elseif isfield(modl,'datasource') && iscell(modl.datasource)
      %otherwise, use whats in datasource
      for j=1:length(modl.datasource)
        modellinks = [modellinks linkstruct(save_uniquename('data',modl.datasource{j}))];
      end
    end
  end

  addindex('model',modl,modelname,modelsource,modellinks);
end

%- - - - - - - - - - - - - - - - - - - - - - - - -
%if there was a model, see about getting descriptor of that
if ~isempty(pred) & ismodel(pred)
  predname   = save_uniquename('prediction',pred);
  predsource = getmodelsource(pred);
  predlinks  = linkstruct;
  if ~isempty(dataname)
    %if we were passed data with this model, use it as the reference
    for j=1:length(dataname);
      predlinks = [predlinks linkstruct(dataname{j})];
    end
  elseif isfield(pred,'datasource') && iscell(pred.datasource)
    for j=1:length(pred.datasource)
      predlinks = [predlinks linkstruct(save_uniquename('data',pred.datasource{j}))];
    end
  end
  if ~isempty(modelname);
    predlinks = [predlinks linkstruct(modelname)];
  end

  addindex('prediction',pred,predname,predsource,predlinks);
end

%----------------------------------------------
function addindex(type,obj,name,source,links)
%add the indicated information to an index (if not there already)
options = getoptions;

if isempty(name)
  %nothing to save - just exit
  return;
end

%create index structure
toadd = struct(...
  'name' ,name,...
  'description',source.summary,...
  'source',source,...
  'type',type,...
  'links',links,...
  'cachedate',now,...
  'filename',[name '.mat']...
  );

index = getcache;
match = 0;
if ~isempty(index);
  match = ismember({index.name},toadd.name);
end

if any(match)
  %We've already got it in a file? update date ONLY
  index(match).cachedate = now;
else
  index = [index;toadd];
end

setcache(index);
addcacheitem(getcacheobj,toadd);%DB will update date only if needed.

if any(match)
  return
end

%create name and save object to disk.
myfileobj = java.io.File(fullfile(cachefolder,projectfolder,type));  %create folder
myfileobj.mkdirs;
if ~strcmp(toadd.type,'data') || prod(toadd.source.size)<=options.maxdatasize;
  savevar(fullfile(cachefolder,projectfolder,type,toadd.filename),toadd.name(1:min(63,end)),obj);
else
  evritip('cachemaxdatasize','CACHE WARNING: This dataset was too large to store and will not be reloadable from the cache. Please make sure you save the data manually (usually File/Save Data menu or similar)',1);
end

%-------------------------------------------------------------------
function success = setdescription(name,description)
%Change description for an existing entry.

success = false;
index = getcache;

%Change name in db.
cobj = getcacheobj;

%Change name in index.
match = ismember({index.name},name);
if any(match)
  %We've already got it in a file? update date ONLY
  index(match).description = description;
  cobj.setdescription(name,description);
  setcache(index);
  success = true;
end

%-------------------------------------------------------------------
function deletedatesforce(varargin)

if nargin<4
  [varargin{end+1:4}] = deal([]);
end
varargin{5} = true;  %set final flag to be true (delete without confirmation)
deletedates(varargin{:});

%-------------------------------------------------------------------
function deletedates(direction,mydate,direction2,mydate2,force)

if nargin<5 | isempty(force)
  force = false;
end

options = getoptions;
if strcmp(options.cache,'off')
  return
end

index = getcache;

if isempty(index)
  %Nothing to purge.
  return
end
dates = [index.cachedate];

dirlookup = {
  '>'  @gt
  '>=' @ge
  '<'  @lt
  '>=' @le
  };

%check first comparison operator
di = strmatch(direction,dirlookup(:,1));
if isempty(di)
  error('Unrecognized comparison operator "%s" (expected < <= > or >= )',direction)
end
cfn = dirlookup{di,2};
cull = cfn(dates,datenum(mydate));

if nargin>2 & ~isempty(direction2)
  %check second operator (if there)
  di = strmatch(direction2,dirlookup(:,1));
  if isempty(di)
    error('Unrecognized comparison operator "%s" (expected < <= > or >= )',direction2)
  end
  cfn = dirlookup{di,2};
  cull = cull & cfn(dates,datenum(mydate2));  
end

%identify items
cull = find(cull);
if isempty(cull)
  return;
end

if ~force
  %confirm with user
  conf = evriquestdlg(sprintf('Confirm you want to delete %i items from the cache?',length(cull)),'Confirm Delete','Delete Items','Cancel','Delete Items');
  if ~strcmpi(conf,'Delete Items')
    return;
  end
end

%delete items
if length(cull)>200
  wbh = waitbar(0,'Deleting cache items...');
else
  wbh = [];
end
group = 25;
for j=1:group:length(cull)
  if ~isempty(wbh)
    if ~ishandle(wbh); return; end
    waitbar(j/length(cull),wbh);
  end
  groupind = cull(j:min(length(cull),j+group-1));
  deleteitem({index(groupind).name})
end
if ~isempty(wbh) & ishandle(wbh); delete(wbh); end

%-------------------------------------------------------------------
function deleteitem(name)
%Delete item.

options = getoptions;
if strcmp(options.cache,'off')
  return
end

index = getcache;

%Change name in db.
cobj = getcacheobj;

if isempty(index)
  %Nothing to purge.
  return
end

if ~iscell(name)
  name = {name};
end

%Don't worry about deleting links for now.
%mylinks = getlinks(cobj,name)';
%bad = ismember({index.name},[{name} mylinks]);

bad = ismember({index.name},name);

try
if any(bad)
  for k= index(bad)';
    %Remove the files.
    filename = findfile(k);
    if exist(filename,'file') && ~isempty(filename)
      delete(filename);
    end
  end
  %Remove the items from the database.
  cobj.removecacheitems(index(bad));
  index(bad) = []; 
  setcache(index);
  
end

catch
  evrierrordlg({'Item may not have been deleted.' lasterr},'Delete Cache Item Error');
end

%-------------------------------------------------------------------
function out = cachefolder
%Get the cache directory.

options = getoptions;

if isempty(options.cachefolder)
  %Make new default.
  out = setdefaultcachefolder;
else
  out = options.cachefolder;
end

%-------------------------------------------------------------------
function out = setdefaultcachefolder
%Create new folder in evridir.
out = fullfile(evridir,'modelcache');
setplspref('modelcache','cachefolder',out)
getoptions;%Update persistent var.

%-------------------------------------------------------------------
%generate project directory name
function out = projectfolder

options = getoptions;
out = options.project;
if isempty(out)
  out = 'general';
end

%-------------------------------------------------------------------
function success = movecache(newfolder,oldfolder)
%Move entire cache directory, 'newfolder' should be parent of evricache
%directory "evricache".
%e.g., success = movecahce('/private/tmp/modelcache/','/Users/scottkoch/EVRI/')

success = true;
try
  if nargin<2
    oldfolder = cachefolder;
  end
  [junk,fld_name]=fileparts(oldfolder);
  
  status = copyfile(oldfolder,fullfile(newfolder,fld_name),'f');%COPYFILE(SOURCE,DESTINATION,MODE)
  
  if status
    %Safe to delete old folder.
    %TODO: Enable delete when we're sure upgrade is working.
    %rmdir(oldfolder,'s');
  end
  
  modelcache('changecachedir',fullfile(newfolder,fld_name));
  %setplspref('modelcache','cachefolder',fullfile(newfolder,fld_name));
  getoptions;%Update persistent var.
catch
  success = false;
end

%-------------------------------------------------------------------
function combinecache(fromfolder,tofolder)
%Combine files from one project to another then delete the from folder.

frm_dirs = dir(fromfolder);
frm_dirs = frm_dirs([frm_dirs.isdir]);
frm_dirs = frm_dirs(~ismember({frm_dirs.name},{'.' '..'}));

for i = 1:length(frm_dirs)
  target = fullfile(tofolder,frm_dirs(i).name);
  if ~exist(target,'file')
    %Make sure target folder is there.
    mkdir(target);
  end
  copyfile(fullfile(fromfolder,frm_dirs(i).name,'*'),target);
end

rmdir(fromfolder,'s');

%-------------------------------------------------------
function index = getindex(filename,newindex)
% get index from a specified file

temp = load(filename,'index');
if isfield(temp,'index');
  index = temp.index;  %extract actual index
else
  index = [];
end

if ~isempty(index) && isfield(index,'name')
  if ~isfield(index,'description');
    [index.description] = deal(index.name);
  else
    empty = cellfun('isempty',{index.description});
    [index(empty).description] = deal(index(empty).name);
  end
end

%----------------------------------------------------
%safely append a variable to a file under a given name
function savevar(targetfilename,varname,var)

if exist(targetfilename,'file')
  mode = {'-append'};
else
  mode = {};
end
myvars = [];
myvars.(varname) = var;
save(targetfilename,'-struct','myvars',mode{:});


%--------------------------------------------------
%Create empty link structure
function links = linkstruct(target)

if nargin==0 || isempty(target)
  %create empty structure
  target = {};
end
links = struct('target',target);


%-------------------------------------------------
%create a unique name which points to the object passed in
function name = save_uniquename(type,obj)

name = safename(uniquename(obj,type));


%---------------------------------------------------------
function purgecache
%Remove items older than max age.

options = getoptions;
%Alway abort purge if cache is off, this can cause problems when database
%if not intialized especailly if a user has turned off cache intentionally
%before "upgrading" to new cache.
if strcmp(options.cache,'off')
  return
end

index = getcache;
cobj = getcacheobj;

if isempty(index)
  %Nothing to purge.
  return
end

cachedates = [index.cachedate];

if ~isfield(options,'firstpurge') | options.firstpurge==0
  %is this the first time we've purged the cache in this installation? Then
  %we'll need to make sure we've accurately matched the settings so we
  %don't throw away models and data they want to keep (because the settings
  %got returned to default on re-installation
  setplspref('modelcache','firstpurge',1)
  options.maxage = max(options.maxage,ceil(now-min(cachedates)));  %just assume they want to keep everything in their cache
  setplspref('modelcache','maxage',options.maxage) 
  getoptions;  %refresh cached internal options
  options = getoptions;
end

bad = cachedates<(now-options.maxage);
if any(bad) 
  %check for unusual purges and give warning
  if sum(double(bad))>options.alertpurgeitems
    msg = sprintf('is about to purge %i old items',sum(double(bad)));
  elseif (min(cachedates)<(now-options.maxage-options.alertpurgedays))
    msg = sprintf('is about to purge items which are %i days old (%i days older than the maximum age allowed)',round(now-min(cachedates)),round(now+1-options.maxage-min(cachedates)));
  else
    msg = '';
  end
  if ~isempty(msg) 
    decision = evriquestdlg({['Model Cache ' msg '. Do you want to:'],' ',...
      ' * Purge old items',' * Adjust maximum age so as to keep old items',' * Disable automatic purging (manual delete only)',...
      ' ','Close this dialog to cancel purge until next session.'},'Purging Model Cache','Purge','Adjust Maximum','Disable Purging','Purge');
    if isempty(decision)
      %cancel
      return;
    end
    switch decision
      case 'Purge'
        %purge all
        %update alertpergeitems so we don't ask for this level again
        setplspref('modelcache','alertpurgeitems',ceil(sum(double(bad))*1.05))  %5% more than this level
      case 'Adjust Maximum'
        %adjust options.maxage
        options.maxage = ceil(now-min(cachedates));
        setplspref('modelcache','maxage',options.maxage)
        getoptions;  %refresh cached internal options
        bad = cachedates<(now-options.maxage);
      case 'Disable Purging'
        %set maxage to INF so NOTHING is ever purged
        options.maxage = inf;
        setplspref('modelcache','maxage',options.maxage)
        getoptions;  %refresh cached internal options
        return;
    end
  end
end

if any(bad)
  for k= index(bad)';
    %Remove the files.
    filename = findfile(k);
    if exist(filename,'file') && ~isempty(filename)
      delete(filename);
    end
  end
  %Remove the items from the database.
  cobj.removecacheitems(index(bad));
  index(bad) = []; 
  setcache(index);
end

%----------------------------------------------------------
% Extract all information about data which we will use to index by later.
function s = getdatasourceplus(data)

s = getdatasource(data);
s.summary = summarize(data);

%----------------------------------------------------------
% Extract all information about a model which we will use to index this
% model by later.
function s = getmodelsource(modl)

% modelsource / predictsource
s = struct(...
  'summary','',...
  'modeltype','',...
  'time',[],...
  'ncomp',[],...
  'preprocessing',{{{} {}}},...
  'rmsec',[],...
  'rmsecv',[],...
  'rmsep',[],...
  'cvmethod',[],...
  'cvsplit',[],...
  'cviter',[],...
  'include_size',[]...
  );

%Get summary information
s.summary = summarize(modl);
s.modeltype = modl.modeltype;
if isfield(modl,'time');
  s.time = modl.time;
end

%get number of components (PCs/LVs/etc)
if isfieldcheck(modl,'.loads') && iscell(modl.loads) && size(modl.loads,1)>=2
  s.ncomp = size(modl.loads{2},2);
end

%summarize preprocessing
if isfieldcheck(modl,'.detail.preprocessing')
  pp = modl.detail.preprocessing;
  desc = {{} {}};
  for j=1:length(pp);
    if ~isempty(pp{j})
      desc{j} = {pp{j}.description};
    end
  end
  s.preprocessing = desc;
end

%copy these detail fields (from model.detail field -> to summary field)
getfields = {
  'rmsec'  'rmsec'
  'rmsecv' 'rmsecv'
  'rmsep'  'rmsep'
  'cv'     'cvmethod'
  'split'  'cvsplit'
  'iter'   'cviter'
  };
for j=1:size(getfields,1);
  if isfieldcheck(modl,['.detail.' getfields{j,1}])
    s.(getfields{j,2}) = modl.detail.(getfields{j,1});
  end
end

if isfieldcheck(modl,'.detail.includ')
  s.include_size = cellfun('size',modl.detail.includ(:,1),2)';
end

%---------------------------------------------------------------------
function out = getprojectlist
%List project folders.
pdir = dir(cachefolder);
pdir = pdir([pdir.isdir]);
%Remove relative dirs and the database directory.
pdir = pdir(~ismember({pdir.name},{'.' '..' 'evri_cache_db'}));
out = {pdir.name};

%---------------------------------------------------------------------
function ind = lookuplink(index,target)
% Search a given index for any items which access a given target

ind = [];
if isempty(index) | ~isfield(index,'links')
  return;
end

%get linear list of all links in this index
temp = [index.links];
%locate target in any of those links
linind = strmatch(target,{temp.target});
%create lookup index to translate back to index number which contained link
indlookup = cumsum(cellfun('length',{index.links}));

%translate all found indices back to index number
for j=1:length(linind);
  this_ind = min(find(indlookup>=linind(j)));
  ind(j) = this_ind;
end
ind = unique(ind);  %and return unique set of matches

%----------------------------------------------------
function clearcache
%Clear appdata index and all records for current project.
setcache([]);
removeproject(getcacheobj,projectfolder)

%----------------------------------------------------
function setcache(index)
%Add index back to appdata.

setappdata(0,'evri_cache_index',index);

%----------------------------------------------------
function index = getcache(type)
%Get a structure list of cache items. Use appdata for saving/reading index
%because using database is just too slow.

if nargin==0;
  type = '';
end

%Alway return empty if cache is off, this can cause problems when database
%if not intialized especailly if a user has turned off cache intentionally
%before "upgrading" to new cache.
opts = getoptions;
if strcmp(opts.cache,'off')
  index = [];
  return
end


index = getappdata(0,'evri_cache_index');
if isempty(index) || strcmp(type,'rebuildcache')
  cobj = getcacheobj;
  if isempty(cobj)
    %Error in connecting so turn off cache.
    setplspref('modelcache','cache','off');
    index = [];
    return
  end
  index = getcacheindex(cobj,'',0);
  setcache(index)
end

if length(index)==1 && isempty(index.name)
  %Empty cache so return [].
  index = [];
  return
end

if ~isempty(type) && ~strcmp(type,'rebuildcache');
  %if asked for only one type, filter that type out
  index = index(ismember({index.type},type));
end

%-----------------------------------------------------
function listcache(target)

index = getcache;
if isempty(index);
  disp('Cache is empty.');
  return
end

for k = find(ismember({index.type},'data'));
  link = sprintf('matlab:assignin(''base'',''%s'',modelcache(''get'',''%s''))',index(k).name,index(k).name);

  disp(sprintf(' <a href="%s">%s</a> %s',link,index(k).description,encodedate(index(k).cachedate,31)));
  ind = lookuplink(index,index(k).name);  %get all linked items

  %display models which link to this data
  modelind = ind(ismember({index(ind).type},'model'));
  for j=1:length(modelind);
    link = sprintf('matlab:assignin(''base'',''%s'',modelcache(''get'',''%s''))',index(ind(j)).name,index(ind(j)).name);
    disp(sprintf('   [M]  <a href="%s">%s</a>',link,index(ind(j)).description));
  end

  %display predictions which link to this data
  predind = ind(ismember({index(ind).type},'prediction'));
  for j=1:length(predind);
    link = sprintf('matlab:assignin(''base'',''%s'',modelcache(''get'',''%s''))',index(ind(j)).name,index(ind(j)).name);
    disp(sprintf('   (P)  <a href="%s">%s</a>',link,index(ind(j)).description));
  end

  disp(' ');
end

%-----------------------------------------------------
%returns a "whos"-style structure of all the objects in the cache
function items = whoscache

index = getcache;

items = [];
for k=1:length(index);
  ind = length(items)+1;
  items(ind,1).name = index(k).name;
  items(ind).size = [1 1];
  items(ind).bytes   = 1;
  if strcmp(index(k).type,'data');
    index(k).type = 'dataset';
  end
  items(ind).class   = index(k).type;
  items(ind).global  = false;
  items(ind).sparse  = false;
  items(ind).complex = false;
  items(ind).nesting.function = '';
  items(ind).nesting.level    = 1;
  items(ind).persistent       = false;
  items(ind).location         = 'ModelCache';
end


%------------------------------------------------
function obj = getobj(name)
%Retrieve one object from the cache. If no object found the return empty.

index = getcache;

obj = [];
myname = [];

sname = safename(name);
for j=1:length(index);
  switch index(j).name
    case name
      myname = name;
    case sname
      myname = sname;
  end
  
  if ~isempty(myname)
    try      
      filename = findfile(index(j));
      obj = load(filename);
    catch
      error('Unable to load object. Cache data file for object could not be located.');
    end
    if ~isfield(obj,index(j).name(1:min(63,end)))
      error('Unable to load object. Cache data file did not contain expected object.')
    end
    obj = obj.(index(j).name(1:min(63,end)));
    return
  end
end

%------------------------------------------------
function objs = getparents(myobj)
%Returns all items used by an object (e.g. data from models, or models from
%predictions)

info = getinfo(myobj);
objs = {};
if ~isempty(info)
  for j=1:length(info.links)
    try
      objs{j} = getobj(info.links(j).target);
    catch
      %no error - just leave empty
    end
  end
end

%------------------------------------------------
function objs = getchildren(myobj)
%Returns all items using an object (e.g. predictions from a model, or
%models from data)

objs  = {};
index = getcache;
info  = getinfo(myobj);
if isempty(info)
  %couldn't find item
  return;
end

%found item, get links
ind   = lookuplink(index,info.name);
links = {index(ind).name};
if ~isempty(links)
  %found item and it has links
  for j=1:length(links)
    try
      objs{j} = getobj(links{j});
    catch
      %no error - just leave empty
    end
  end
end

%------------------------------------------------
function doesexist = existobj(name)
%Check if object file exists (and can be loaded).

index = getcache;

doesexist = false;
for j=1:length(index);
  if strcmp(index(j).name,name)
    if ~isempty(findfile(index(j)))
      doesexist = true;
      break;
    end
  end
end

%------------------------------------------------
function exportdata = exportobj(name)
%Export object and children to mat file. Should be saved in format that
%modelcache expects, 1x3 cell array with {model {data/s} pred}.

if isa(name,'evrimodel')
  name = safename(name.uniqueid);
end

index = getcache;

%Cell to export.
exportdata=cell(1,3);
addobjs = {};
for j=1:length(index)
  if strcmp(index(j).name,name)
    parentobj  = getobj(index(j).name);
    if ~isempty(parentobj)
      addobjs{1} = parentobj;
      %Get links.
      mylinks    = index(j).links;
      for k = 1:length(mylinks)
        thisobj   = getobj(mylinks(k).target);
        if ~isempty(thisobj)
          addobjs = [addobjs {thisobj}];
        else
          %Show a warning.
          warning('EVRI:ModelcacheExportFile',['Cache Export Warning: Can''t locate file (' thisindex.name '). File not included with export.'])
        end
      end
      
      for k = 1:length(addobjs)
        if strcmp(class(addobjs{k}),'evrimodel')
          if addobjs{k}.isprediction
            %Add to cell 3.
            exportdata{3} = addobjs{k};
          else
            exportdata{1} = addobjs{k};
          end
        else
          %Data.
          exportdata{2} = [exportdata{2} addobjs(k)];
        end
      end
      
      [FileName,PathName] = evriuiputfile('*.mat','Export As');
      if ischar(FileName)
        save(fullfile(PathName,FileName),'exportdata')
      end
    else
      warning('EVRI:ModelcacheExportFile',['Cache Export Error: Can''t locate file (' index(j).name '). Export canceled.'])
    end
  end
end

%------------------------------------------------
function importobj(mydata)
%Import mat file (created above) into cache.

if nargin<1 | isempty(mydata)
  [FileName,PathName] = evriuigetfile('*.mat','Locate MAT File');
  if ~ischar(FileName)
    %User cacnel.
    return
  else
    mydata = load(fullfile(PathName,FileName));
  end
end

toadd = {};
if isstruct(mydata) & isfield(mydata,'exportdata')
  %Assume this was a file created above.
  modelcache(mydata.exportdata{:})
else
  %TODO: Add other ways of importing different data types (cell array).
  error('This file does not appear to contain an exported Model Cache item')
end

evritreefcn([],'update');

%------------------------------------------------
function filename = findfile(index)
%locate true location of file (try different permutations of cache
%sub-folders based on what is in index and what is current settings)


%first look assuming cache object does NOT have sub-folder included
[p,f,e]  = fileparts(index.filename);
filename = fullfile(cachefolder,projectfolder,index.type,[f e]);
if ~exist(filename,'file')
  %couldn't find file, check as if the folder name is special and is
  %included in the filename (as a relative path)
  filename = fullfile(cachefolder,index.filename);
  
  if ~exist(filename,'file')
    %couldn't find file, check as if the folder name is special and is
    %included in the filename (as an absolute path)
    filename = index.filename;
    
    if ~exist(filename,'file')
      %STILL couludn't find it? assume empty
      filename = '';
    end
  end
end

%------------------------------------------------
function obj = getinfo(myobj)
%Returns cache item informaiton if it finds it, 'myobj' is the unique cache
%item name OR the object itself (for which the unique cache name will be
%looked up)

list = getcache;
obj = [];
if isempty(list)
  return
end

if ischar(myobj)
  myname = myobj;
else
  %Create name for object.
  if ismodel(myobj)
    if length(myobj.modeltype)>4 && strcmp(myobj.modeltype(end-4:end),'_PRED')
     %Get prediction name.
     myname = save_uniquename('prediction',myobj);
    else
     %Get model name.
     myname = save_uniquename('model',myobj);
    end
  else
    %Assume data.
    myname = save_uniquename('data',myobj);
  end
end

%Look up name created above.
idx = ismember({list.name},{myname});
obj = list(idx);

%--------------------------
function out=getcacheobj
%Get a copy of cache object in appdata(0).

out = getappdata(0,'evri_cache_object');
if isempty(out)
  out = evricachedb;
  setappdata(0,'evri_cache_object',out)
end

%--------------------------
function out=getoptions
%stores options for each call to modelcache
% a call to this function without outputs will refresh options (necessary
% to detect when stored folder has changed)

persistent internal_options
if nargout==0 | isempty(internal_options)
  internal_options = modelcache('options');
end
if nargout>0;
  out = internal_options;
end

%--------------------------
function success = parsecachefiles
%Parse existing cache files into database. Rename file with .bak
%afterwards.

success = true;
try
  cobj = getcacheobj;
  pfolders = modelcache('projectlist');
  
  for i = 1:length(pfolders)
    indexlist = dir(fullfile(cachefolder,pfolders{i},'cacheindex*.mat'));
    if ~isempty(indexlist);
      for j=1:length(indexlist);
        indexfile = fullfile(cachefolder,pfolders{i},indexlist(j).name);
        index = getindex(indexfile);
        if isempty(index)
          %nothing there delete file
          delete(indexfile);
          continue;
        end
        parsecache(cobj,index,pfolders{i})
      end
      
    end
  end
catch
  success = false;
end

%Just added records so we need to rebuild cache index.
modelcache('getcache','rebuildcache')

%--------------------------
function myfolder = find_old_cache
%Find an old cache folder looking in options.cachefolder first then in old
%default location. Return empty if can't find.
%
%NOTE: options.cachefolder will be reset to new (EVRIDIR) default
%location before an upgrade has occured so that's why we need to use this
%search function.

%Look in (current) default folder.
pfolders = getprojectlist;
indexlist = [];
myfolder = [];
for i = 1:length(pfolders)
  indexlist = dir(fullfile(cachefolder,pfolders{i},'cacheindex*.mat'));
  if ~isempty(indexlist);
    myfolder = cachefolder;%Same folder used by getprojectlist
    return
  end
end

%Look in old default location.
mycachefolder = fullfile(tempdir,'modelcache');
if exist(mycachefolder,'dir')
  pdir = dir(mycachefolder);
  pdir = pdir([pdir.isdir]);
  %Remove relative dirs and the database directory.
  pdir = pdir(~ismember({pdir.name},{'.' '..' 'evri_cache_db'}));
  pfolders = {pdir.name};
  for i = 1:length(pfolders)
    indexlist = dir(fullfile(mycachefolder,pfolders{i},'cacheindex*.mat'));
    if ~isempty(indexlist);
      myfolder = mycachefolder;
      return
    end
  end
end

%--------------------------
function projectmenu_callback(h, eventdata, handles, varargin)
%Context menu callback for project management.

t = getappdata(handles.analysis,'treeparent');
fcn = get(t,'GetSelectedCacheItem');

myitem = fcn(handles.analysis);

switch get(h,'tag') 
  case 'removeprj_pm'
    modelcache('removeproject',myitem);
  case 'renameprj_pm'
    newprj = inputdlg('New Project Name (use existing name to combine projects): ','Rename Project',1,{myitem},'on');
    newprj = newprj{1};
    if any(ismember(modelcache('projectlist'),newprj))
      %Combine.
      modelcache('combineproject',myitem,newprj);
    else
      %Just rename.
      modelcache('renameproject',myitem,newprj);
    end
end

%Refresh the cache view.
analysis('cachemenu_callback',handles.analysis, eventdata, handles, varargin)

%--------------------------
function resetcache
%Reset the database and all persistent vars.

getoptions;
cobj = getcacheobj;
%Chage DB connection.
cobj.checkcachedb(1);
%Need to clear this one out because it still in memory.
clear cobj
%Get new object with new connection.
cobj = getcacheobj;

%NOTE: The following code is all executed inside of checkcachedb function
%from above but I'll leave reference here in case we see strange behavior.
%Update persistent lists.
%cobj.checkcache('refresh_cache_list');
%cobj.checkproject('refresh_project_list');
%getcache('rebuildcache');

%Update any trees.
evritreefcn([],'update');

%--------------------------
function out = optiondefs

%NOTE: Can't change cachefolder via optionsgui because we need to change
%the database location as well.

defs = {
  %name             tab        datatype        valid              userlevel       description
  'cache'       	'Setup'     'select'         {'on' 'readonly' 'off'}  'novice'      	'Controls operation of cache. ''on'' records all models and data built. ''readonly'' locks down cache not allowing any recording or clearing.'
  %Must change through changecachedir so db gets shut down. 
  %'cachefolder' 	'Setup'     'directory'      []                 'novice'        'Top-level location of cache folder. All project folders are created in this folder. An empty string will default to the system-specific "temp" folder.'
  'project'       'Setup'     'char'           []                 'novice'      	'Sub-folder in which cache files should be stored. An empty string defaults to project = "general".'
  'maxage'        'Setup'     'double'         'int(1:inf)'       'novice'        'Maximum number of DAYS to keep any item in the cache. Items which are older than this time period are purged at the first access of the cache in each session. A value of "inf" will disable automatic purging (only manual purge will clear cache).'
  'maxdatasize'   'Setup'     'double'         'int(0:inf)'       'intermediate'  'Largest sized dataset (in total number of array elements) which will be stored in the cache. A value of zero disables storing of any sized data. A value of "inf" allows storing of data of any size (WARNING: storing very large datasets may cause significant slowing of model building.)'
  'alertpurgedays' 'Setup'    'double'         'int(1:inf)'       'novice'        'Alert user when the oldest item about to be purged is this many days older than the maxage. Detects when a big change in maxage or usage has occurred.'
  'alertpurgeitems' 'Setup'   'double'         'int(1:inf)'       'novice'        'Alert user when more than this many ITEMS will be purged at once.'
  'lineage_date_sort' 'Setup' 'select'         {'ascend' 'descend'}  'novice'     'How to sort children of lineage leafs.'
  };

out = makesubops(defs);
