function nodestruct = cachestruct(varargin)
%CACHESTRUCT Creates structure of model cache items for display in evritree.
% Input 'ctype' is type of sorting used when creating structure, 'date',
% 'type', 'lineage'. DSO dates are .moddate and model/prediction dates are
% .time field.
%
%I/O: nodestruct = cachestruct(ctype);
%
%See also: MODELCACHE

%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% RSK 10/22/2007

if nargin==0
  varargin{1} = 'io';
end

if ischar(varargin{1}) && ismember(varargin{1},evriio([],'validtopics'));
  options = [];
  options.parent_function = 'analysis';%Function with tree_callback sub.
  options.showhide        = 'on';%Show the hide cache leaf.
  options.showview        = 'on';%Show view leafs.
  options.showdemo        = 'on';
  options.showsettings    = 'on';
  options.showclear       = 'on';
  options.showhelp        = 'on';
  options.showimport      = 'on';
  options.demo_gui        = 'analysis';%Subset of demo data to use from demodata.xml.
  if nargout==0;
    clear varargout;
    evriio(mfilename,varargin{1},options);
  else
    nodestruct = evriio(mfilename,varargin{1},options);
  end
  return;
elseif length(varargin)==2&&ismember(varargin{1},{'date' 'type' 'lineage'})&&isstruct(varargin{2})
  %cachestruct(ctype,options)
  ctype = varargin{1};
  options = varargin{2};
  
elseif length(varargin)>1
  %Call named subfunction.
  if nargout == 0;
    %normal calls with a function
    feval(varargin{:}); % FEVAL switchyard
  else
    nodestruct = feval(varargin{:}); % FEVAL switchyard
  end
  return
else
  ctype = varargin{1};
  options = cachestruct('options');
end

options = reconopts(options,'cachestruct');


list = modelcache('getcache');
if isempty(list)
  nodestruct = getsettingsnodes(options);
  nodestruct(2).val = num2str(1);
  nodestruct(2).nam = '';
  nodestruct(2).str = 'No Cached Data Available';
  nodestruct(2).icn = which('emptycache.gif');
  nodestruct(2).isl = true;
  nodestruct = [nodestruct getdemodata_int(options)];
  return
end

try
  %It appears as if a lot of errors occur at this step. What I think
  %happens is the 'list' above comes back as not empty but subsequent calls
  %below return empty queries and cause indexing errors when exracting
  %various information about cache items.
  nodes      = [];
  nodestruct = [];
  switch ctype
    case 'date'
      cobj = evricachedb;
      nodes = cobj.getdates;
      nodestruct = nodes;
      
    case 'type'
      cobj = evricachedb;
      %types = unique({list.type});
      nodes = cobj.gettypes;
      nodestruct = nodes;
      
    case 'lineage'
      %Data->Date->Model or Pred
      cobj = evricachedb;
      nodes = getlineage(cobj);
      nodestruct = nodes;
  end
  
catch
  %Show once per session warning asking to reset/restart.
  evritip('cacheconnectionwarning')
end

%Add demo data.
nodeset = getdemodata_int(options);
nodes   = [nodeset nodes];

%Add settings.
nodeset    = getsettingsnodes(options);
nodestruct = [nodeset nodes];

%------------------------------------------------
function outstruct = cacheobjinfo(valstr, sourceitem)
%CACHEOBJINFO Extracts info about cache object into a structure for use with cache structure.
% INPUT:
%   valstr     - the prefix string for the value (val) field (e.g.,'wine/date/').
%                NOTE: Must include all dividers '/' (including last one).
%   sourceitme - single cache item to extract data from.

switch sourceitem.type
  case 'data'
    %Data info.
    subsublist = {'Name:' 'DataSet Type:' 'Author:' 'Size:' 'Include Size:' 'Mod Date:'};
    subsubfieldname = {'name' 'type' 'author' 'size' 'include_size' 'moddate'};
    ind = 1;
    for ii = 1:length(subsublist)
      try
        outstruct(ind).val = [valstr subsublist{ii}];
        outstruct(ind).nam = subsublist{ii};
        if ~isfield(sourceitem.source,subsubfieldname{ii}) | isempty(sourceitem.source.(subsubfieldname{ii}))
          outstruct(ind).str = subsublist{ii};
        else
          switch subsubfieldname{ii}
            case {'size' 'include_size'}
              outstruct(ind).str = [subsublist{ii} ' ' num2str(sourceitem.source.(subsubfieldname{ii}))];
            case 'moddate'
              outstruct(ind).str = [subsublist{ii} ' ' datestr(sourceitem.source.(subsubfieldname{ii}))];
            otherwise
              
              outstruct(ind).str = [subsublist{ii} ' ' sourceitem.source.(subsubfieldname{ii})];
          end
        end
        outstruct(ind).icn = '';%getcacheicon('info');
        outstruct(ind).isl = true;
      catch
        continue
      end
      ind = ind+1;
    end
  case {'model' 'prediction'}
    %Model info.
    subsublist = {'Model Type:' 'Number of Components/LVs:' 'Preprocessing:' ...
      'Include Size:'  'RMSEC: ' 'RMSECV: ' 'RMSEP: ' 'CrossVal Method: ' ...
      'CrossVal Split: ' 'CrossVal Iter: ' 'Mod Date: '};
    subsubfieldname = {'modeltype' 'ncomp' 'preprocessing' 'include_size' 'rmsec' 'rmsecv' 'rmsep' 'cvmethod' 'cvsplit' 'cviter' 'time'};
    isnumericfield = [0     1     0     1     1     1     1     0     1     1 1];  %indicates if the corresponding fieldname will be numeric
    ind = 1;
    for ii = 1:length(subsublist)
      try
        outstruct(ind).val = [valstr subsublist{ii}];
        outstruct(ind).nam = subsublist{ii};
        if ~isempty(sourceitem.source) && isfield(sourceitem.source,subsubfieldname{ii})
          if isnumericfield(ii)
            myval = sourceitem.source.(subsubfieldname{ii});
            if strcmp(subsubfieldname{ii}(1:3),'rms')&&~isempty(myval)
              %Pull out RMS vector.
              try
                if isempty(sourceitem.source.ncomp)
                  sourceitem.source.ncomp = size(myval,2);  %try using last column if we don't have ncomp
                end
                if ~isempty(sourceitem.source.ncomp) & size(myval,2)>=sourceitem.source.ncomp
                  myval = myval(:,sourceitem.source.ncomp);
                elseif strcmpi(sourceitem.source.modeltype,'ann') && strcmp(subsubfieldname{ii},'rmsep')
                  %Special case for ANN PRED, it has nan in rmsep that
                  %don't get accounted for in database pull, need to use
                  %last value. See getcacheindex around line 126.
                  myval = myval(:,end);
                else
                  myval = [];
                end
              catch
                myval = [];
              end
            elseif strcmp(subsubfieldname{ii},'time')
              myval = datestr(sourceitem.source.(subsubfieldname{ii}));
            elseif isempty(myval)
              outstruct(ind) = [];  %delete this node
              continue
            end
            if size(myval,1)>size(myval,2)
              myval = myval';
            end
            outstruct(ind).str = [subsublist{ii} ' ' num2str(myval)];
          elseif strcmp(subsubfieldname{ii},'preprocessing')
            outstruct(ind).str = ['Preprocessing: ' getpreprostr(sourceitem.source)];
          elseif isempty(sourceitem.source.(subsubfieldname{ii}));
            outstruct(ind) = [];  %delete this node
            continue
          else
            outstruct(ind).str = [subsublist{ii} ' ' sourceitem.source.(subsubfieldname{ii})];
          end
          
          outstruct(ind).icn = '';%  getcacheicon('info');
          outstruct(ind).isl = true;
        else
          outstruct = [];
        end
      catch
        outstruct(ind) = [];  %delete this node
        continue
      end
      ind = ind+1;
    end
    %   case 'prediction'
    %     outstruct = [];
  otherwise
    outstruct = [];
end

%------------------------------------------------
function ppstr = getpreprostr(msource)
%Construct preprocess string.

predesc  = '';
predescy = '';

if isfieldcheck('msource.preprocessing',msource);
  if ~isempty(msource.preprocessing{1})
    ppi = msource.preprocessing{1};
    predesc = [ppi{1}];
    for i = 2:length(ppi)
      predesc = [predesc ' , ' ppi{i}];
    end
  else
    predesc = ['X: ' 'none'];
  end
  
  if length(msource.preprocessing)>1;
    predesc = [predesc ' ] [ '];
    if isempty(msource.preprocessing{2})
      predescy = 'Y: none';
    else
      ppi = msource.preprocessing{2};
      ppcustomy = ['Y: ' ppi{1}];
      for i = 2:length(ppi)
        ppcustomy = [ppcustomy ' , ' ppi{1}];
      end
      predescy = ['Y: ' ppcustomy];
    end
  end
end

ppstr = ['[' predesc predescy ']'];
if iscell(ppstr)
  ppstr = [ppstr{:}];
end

%------------------------------------------------
function iconpath = getcacheicon(type)
%Get full path to icon for given type of data (model,data,prediction).

type = strrep(type,'*','na');
iconpath = which([lower(type) '.gif']);
if isempty(iconpath)
  iconpath = which('other.gif');
end

%------------------------------------------------
function nodes = getsettingsnodes(opts)
%Create node structure for adjustng tree view and modelcache settings. Make
%sure value strings are named exactly as menu items in GUI because we use
%those names to find callback.

nodes.val = 'settings';
nodes.nam = 'settings';
nodes.str = 'Cache Settings and View';
nodes.icn = which('settings.gif');;
nodes.isl = false;

n = 0;
if strcmp(opts.showview,'on')
  n=n+1;
  nodes.chd(1).val = ['settings' '/' 'viewbylineage'];
  nodes.chd(1).nam = 'viewbylineage';
  nodes.chd(1).str = 'View Cache By Lineage';
  nodes.chd(1).icn = which('info.gif');
  nodes.chd(1).isl = true;
  nodes.chd(1).clb = opts.parent_function;
  n=n+1;
  nodes.chd(2).val = ['settings' '/' 'viewbydate'];
  nodes.chd(2).nam = 'viewbydate';
  nodes.chd(2).str = 'View Cache By Date';
  nodes.chd(2).icn = which('info.gif');
  nodes.chd(2).isl = true;
  nodes.chd(2).clb = opts.parent_function;
  n=n+1;
  nodes.chd(3).val = ['settings' '/' 'viewbytype'];
  nodes.chd(3).nam = 'viewbytype';
  nodes.chd(3).str = 'View Cache By Type';
  nodes.chd(3).icn = which('info.gif');
  nodes.chd(3).isl = true;
  nodes.chd(3).clb = opts.parent_function;
end

n=n+1;
nodes.chd(n).val = ['settings' '/' 'changeproject'];
nodes.chd(n).nam = 'changeproject';
nodes.chd(n).str = 'Change Project';
nodes.chd(n).icn = which('folder.gif');
nodes.chd(n).isl = false;
nodes.chd(n).chd = getcachedir(nodes.chd(n).val);

if strcmp(opts.showimport,'on')
  n=n+1;
  nodes.chd(n).val = ['settings' '/' 'importtocache'];
  nodes.chd(n).nam = 'importtocache';
  nodes.chd(n).str = 'Import Model';
  nodes.chd(n).icn = which('modelimport.gif');
  nodes.chd(n).isl = true;
  nodes.chd(n).clb = opts.parent_function;
end

if strcmp(opts.showsettings,'on')
  n=n+1;
  nodes.chd(n).val = ['settings' '/' 'opencachesettings'];
  nodes.chd(n).nam = 'opencachesettings';
  nodes.chd(n).str = 'Edit Model Cache Settings';
  nodes.chd(n).icn = which('settings.gif');
  nodes.chd(n).isl = true;
  nodes.chd(n).clb = opts.parent_function;
end

if strcmp(opts.showclear,'on')
  n=n+1;
  nodes.chd(n).val = ['settings' '/' 'clearcache'];
  nodes.chd(n).nam = 'clearcache';
  nodes.chd(n).str = 'Clear Model Cache Contents';
  nodes.chd(n).icn = which('emptycache.gif');
  nodes.chd(n).isl = true;
  nodes.chd(n).clb = 'cachestruct';
end

if strcmp(opts.showhelp,'on')
  n=n+1;
  nodes.chd(n).val = ['settings' '/' 'opencachehelp'];
  nodes.chd(n).nam = 'opencachehelp';
  nodes.chd(n).str = 'Cache Viewer Help';
  nodes.chd(n).icn = which('help.gif');
  nodes.chd(n).isl = true;
  nodes.chd(n).clb = opts.parent_function;
end

if strcmp(opts.showhide,'on')
  n=n+1;
  nodes.chd(n).val = ['settings' '/' 'hidecacheviewer'];
  nodes.chd(n).nam = 'hidecacheviewer';
  nodes.chd(n).str = 'Hide Cache Viewer';
  nodes.chd(n).icn = which('close.gif');
  nodes.chd(n).isl = true;
  nodes.chd(n).clb = opts.parent_function;
end

%call add-on functions for settings branch
fns = evriaddon('cachestruct_settings_branch');
for j=1:length(fns)
  nodes = feval(fns{j},nodes);
end


%------------------------------------------------
function outstruct = getcachedir(valprefix)
%Build cache folder/project structure.

myfolder = modelcache('cachedir');
myproject = modelcache('projectdir');
outstruct = [];

if isempty(myfolder)
  return
end

myprojs = modelcache('projectlist');

for i = 1:length(myprojs)
  outstruct(end+1).val = [valprefix '/' myprojs{i}];
  outstruct(end).nam = myprojs{i};
  outstruct(end).str = myprojs{i};
  outstruct(end).icn = which('folder.gif');
  outstruct(end).isl = true;
  outstruct(end).clb = 'cachestruct';
  if strcmp(myprojs{i},myproject)
    outstruct(end).icn = which('folderselected.gif');
  end
  
end

outstruct(end+1).val = [valprefix '/New Project'];
outstruct(end).nam = 'New Project';
outstruct(end).str = 'New Project...';
outstruct(end).icn = which('newfolder.gif');
outstruct(end).isl = true;
outstruct(end).clb = 'cachestruct';

%--------------------------------------------------------------------
function tree_callback(fh,keyword,mystruct,jleaf)
%Left click callback switch for tree control.

curproj = modelcache('projectlist');

%Callback for tree node left click.
switch keyword
  case 'clearcache'
    ok = evriquestdlg('Clear all items from cache? This can not be undone.','Clear Cache','OK','Cancel','OK');
    if strcmp(ok,'OK')
      modelcache clear
      analysis('cachemenu_callback',fh,[],guihandles(fh))
    end
    return
  case {curproj{:} 'New Project'}
    %Change cache project.
    changeproject(keyword,fh);
    return
end

%--------------------------------------------------------------------
function changeproject(nodename,fh)
%Change cache folder (project) callback.

if strcmpi(nodename,'new project')
  newprj = inputdlg('New Project Name: ','Create New Cache Project',1,{''},'on');
  if isempty(newprj)
    return
  end
  projname = newprj{:};
else
  %Change current cache project.
  projname = nodename;
end
wbh = waitbar(0.5,'Changing Project...');
try
  modelcache('changeproject',projname);
catch
  le = lasterror;
  if ishandle(wbh); delete(wbh); end
  rethrow(le)
end
if ishandle(wbh); delete(wbh); end


%------------------------------------------------
function nodes = getdemodata_int(opts)
%Create node structure for adjustng tree view and modelcache settings. Make
%sure value strings are named exactly as menu items in GUI because we use
%those names to find callback.

nodes = [];
if strcmp(opts.showdemo,'on')
  nodes.val = 'demo';
  nodes.nam = 'demo';
  nodes.str = 'Demo Data';
  nodes.icn = which('folder.gif');
  nodes.isl = false;
  
  nodes.chd(1).val = ['demo' '/' 'showdemopage'];
  nodes.chd(1).nam = 'showdemopage';
  nodes.chd(1).str = 'Show Descriptions of Demo DataSets';
  nodes.chd(1).icn = which('discussionitem_icon.gif');
  nodes.chd(1).isl = true;
  nodes.chd(1).clb = opts.parent_function;
  
  %Parse demos from xml file.
  mydata = getdemodata('',opts.demo_gui);
  if isempty(mydata) | (iscell(mydata) & isempty(mydata{1}))
    %No data.
    return
  else
%  if ~isempty(mydata)
    %drop duplicate FILE names too (browse doesn't care and this helps in
    %case we have the same file referenced from two different GUIs but with
    %different NAMES (only duplicate names are filtered by getdemodata, not
    %files)
    names = {mydata.file};
    [u,i] = unique(names);
    dups = setdiff(1:length(mydata),i);
    mydata(dups) = [];  %drop duplicates
    
    for i = 1:length(mydata)
      nodes.chd(i).val = ['demo' '/' mydata(i).file];
      nodes.chd(end).nam = mydata(i).file;
      nodes.chd(end).str = mydata(i).name;
      nodes.chd(end).icn = getcacheicon('data');
      nodes.chd(end).isl = true;
      nodes.chd(end).clb = opts.parent_function;
    end
  end
  
end

