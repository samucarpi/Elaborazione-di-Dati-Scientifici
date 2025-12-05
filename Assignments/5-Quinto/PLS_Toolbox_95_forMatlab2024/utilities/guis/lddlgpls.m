function varargout = lddlgpls(varargin)
%LDDLGPLS Dialog to load variable from workspace or MAT file.
% Input (klass) filters for only the specified class:
%    'double'      loads 2-way DOUBLE variable {default},
%    'cell'        loads CELL variable,
%    'char'        loads 2-way CHAR variable,
%    'struct'      loads a STRUCT variable,
%    'dataset'     loads a DATASET object,
%    'doubdataset' loads a 2-way DOUBLE or DATASET,
%    '*'           loads any class and size variable.
%   or a cell containing one or more strings defining standard Matlab
%   classes.
% Input (message) is an optional string to put at the head
%  of the dialog box.
% Input (options) is an optional input structure containing one or more of
%  the following fields:
%      exitonall : [ {0} | 1 ] when 1, selecting ">>> ALL <<<" from the
%                   list of variables will cause the load dialog to exit
%                   with an empty output.
% Outputs (value), (name) and (location) return
%  the information about the selected variable. (location)
%  will be empty if the source was the base workspace.
%  Output (dir) will be the directory the file was loaded from. String will
%  be ">> Base Workspace <<" if value was loaded from Matlab workspace.
%
%I/O: [value,name,location] = lddlgpls(klass,message);
%I/O: [value,name,location,dir] = lddlgpls(klass,message);
%
%See also: SVDLGPLS

%old I/O (still valid!)
%I/O: [value,name,location] = lddlgpls(callhand,callhand2,klass,message);
% Inputs (callhand) and (callhand2) are handles of two
%  different gui objects which will receive in their "userdata"
%  the value and name, respectively, of the selected variable.
%  Although these inputs must be present, they can be empty
%  to indicate no GUI assignment (see optional outputs below).

%Copyright Eigenvector Research, Inc 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 1/8/01 Initial 3.0 coding to match old lddlgpls
%jms 1/11/02 fixed bug associated with no-input call and one-input call
%jms 1/18/02 added "folder" to window, check for empty var name in save,
%   made "save" always active (test for bad varname in save)
%jms 2/4/02 changed folder to pulldown menu w/"baseworkspace" as option.
%jms 2/26/02 -added "from workspace"/"from file" button
%   -Removed other defunct base workspace code
%   -Cleaned up disable code and nargin checks
%   -empty varname or filename input returns to last selected for load
%jms 3/11/02 -allow browsing of folder names with "." in them
%   -fixed svdlgpls default variable name bug (first-time display of base workspace)
%jms 4/1/02 -removed varargout debug display line in zero-outputs test
%jms 4/14/03 -added DEMO mode (use setplspref('lddlgpls','demo',1) )
%jms 5/21/03 -added dataset to image load options
%jms 5/23/03 -ignore dataset size when loading from file (we are unable to tell real size)
%   -test for wrong-size dataset loaded from file after load (see above comment)
%   -enter in varname automatically loads
%   -allow resize of GUI
%jms 9/10/03 -added better test for bad variable name characters
%jms 8/19/05 -case-insensitive sort of folders
%   -use Matlab-based test for double-click
%   -better logic to detect [enter] in edit varname field (causes automatic load/save)

%TODO: Fix load from var.

if strcmp(getappdata(0,'debug'),'on');
  dbstop if all error
end

if nargin < 4 % LAUNCH GUI
  
  %translate input options
  if length(varargin)<1 | isempty(varargin{1})
    varargin{1}  = {'dataset' 'double'};
  end
  if length(varargin)<2 | isempty(varargin{2})
    varargin{2}  = 'Choose Item to Load';
  end
  
  if ~iscell(varargin{1})
    switch lower(varargin{1})
      case 'double'
        validclasses = {'double'};
        validdims    = [2];
      case 'cell'
        validclasses = {'cell'};
        validdims    = [1:10];
      case 'char'
        validclasses = {'char'};
        validdims    = [2];
      case 'struct'
        validclasses = {'struct' 'evrimodel'};
        validdims    = [1:10];
      case 'model'
        validclasses = {'evrimodel'};
        validdims    = [2];
      case 'dataset'
        validclasses = {'dataset'};
        validdims    = [1:10];
      case 'doubdataset'
        validclasses = {'double','dataset'};
        validdims    = [2];
      case 'multivariateimage'
        validclasses = {'double','uint8','dataset'};
        validdims    = [2:100];
      case '*'                          %allow any class
        validclasses = {'*'};
        validdims    = [1:100];
      otherwise
        options = [];
        options.exitonall = 0;
        options.lastpath = get_pls_root;%If
        options.fontsize = getdefaultfontsize;
        if nargout==0
          evriio(mfilename,varargin{1},options);
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;         %        error(['Unrecognized class mode'])
    end
  else
    validclasses = varargin{1};
    validdims = [1:10];
  end
  
  if ismember({'struct'},validclasses) & ~ismember({'evrimodel'},validclasses)
    validclasses{end+1} = 'evrimodel';
  end
  
  if nargin<3 | ~isstruct(varargin{3})
    %no options given (too few inputs or 3rd input is not a structure)
    options = [];
  else
    options = varargin{3};
  end
  options = reconopts(options,mfilename);
  
  fig = openfig(mfilename,'reuse');
  handles = guihandles(fig);         % Generate a structure of handles to pass to callbacks, and store it.
  handles = initgui(handles,options);
  guidata(fig, handles);
  set(handles.text3,'string','Items')
  set(handles.text5,'string','Item:')
  
  setappdata(handles.lddlg,'mode','load');
  setappdata(handles.lddlg,'defaultext','.mat');
  
  set(handles.description,'string',varargin{2});
  setappdata(handles.lddlg,'validclasses',validclasses);
  setappdata(handles.lddlg,'validdims',validdims);
  setappdata(handles.lddlg,'exitonall',options.exitonall);
  
  %call any add-on functions
  fns = evriaddon('lddlgpls_initialize');
  for j=1:length(fns)
    feval(fns{j},handles.lddlg);
  end
  
  %resize to last used size (in this session)
  settings = getsettings;
  if ~isempty(settings.figsize);
    set(handles.lddlg,'position',settings.figsize)
  end
  resize(handles.lddlg, [], handles)
  
  loadfromfile  = settings.fromfile;
  fromworkspace = settings.fromworkspace;
  if (nargin==3 & ~isstruct(varargin{3})) | nargin>3
    %folder (or "file" command) was passed on command line
    if strcmp(varargin{3},'file')
      if isempty(loadfromfile)
        %if "file" requested, but no past folder name exists use pwd
        loadfromfile = pwd;
      end
      %otherwise - we'll use what was in lddlgpls (we were in file mode
      %anyway)
      fromworkspace = 0;
    elseif strcmp(varargin{3},'workspace')
      fromworkspace = 1;
    else
      %specific folder given... use it
      loadfromfile = varargin{3};
      fromworkspace = 0;
    end
  elseif isempty(fromworkspace)
    fromworkspace = 1;  %default is from workspace
  end
  if fromworkspace
    sourcebtn_Callback(fig,[],handles,'');     %update controls for initial base workspace mode
  else
    sourcebtn_Callback(fig,[],handles,loadfromfile);     %update controls for from file
  end
  setappdata(handles.sourcename,'lastfile',loadfromfile);
  
  opts = lddlgpls('options');
  if nargout==0 & isfield(opts,'demo') & opts.demo==1; return; end %end prematurely here for demo's to work with (faked) GUI interface
  
  set(fig,'windowstyle','modal');
  uiwait(fig);      %wait for figure to return
  
  if ishandle(fig);   %figure still exists?
    settings.figsize = get(fig,'position');  %save current fig size and position
    lastdir = get(handles.sourcename,'string');
    lastdir = lastdir{end};
    varargout = {getappdata(fig,'value') get(handles.editvarname,'string') get(handles.editfilename,'string') lastdir};
    mydir = getappdata(handles.lddlg,'pwd');
    %save the folder and filename for next time lddlgpls is called to test if load from base or file
    if ~isempty(varargout{3});
      settings.fromfile = fullfile(mydir,varargout{3});
      settings.fromworkspace = 0;
      if exist('isdeployed') & isdeployed
        %if deployed, change the current working directory to this folder
        cd(mydir);
      end
    else   %unless they loaded from the base workspace, in which case, save flag indicating this
      settings.fromworkspace = 1;
    end;
    setappdata(0,'lddlgpls_settings',settings);
  else
    varargout = {[] [] [] []};    %figure closed, empty response returned
  end
  
  if ishandle(fig);   %figure still exists?
    delete(fig);
  end
  if nargout == 0;
    if ~isempty(varargout{1}) & ~isempty(varargout{2});      %NO output options?!?
      svdlgpls(varargout{1},'Save Loaded Item',varargout{2});
    end
    clear varargout
  end
  
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
  
  try
    if (nargout)
      [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    else
      feval(varargin{:}); % FEVAL switchyard
    end
  catch
    disp(lasterr)
  end
  
end

% --------------------------------------------------------------------
function handles = initgui(handles,options,varargin)
%Update gui.

%Update fontsize for platform.
fontsize = options.fontsize;
hh = findobj(handles.lddlg,'type','uicontrol');
set(hh,'fontsize',fontsize);

%Delete old list.
delete(handles.filelist);
%Get file filter.
filetypes = {'.mat', '.MAT'};
if exist('secureenvelope','file')
  filetypes = [filetypes {'.smat'}];
end

%Add tree with same handle.
tobj = evritree('parent_figure',handles.lddlg,'tag','filelist','visible','off',...
  'units','pixels','position',[5 55 100 100],'file_filter',filetypes,...
  'path_sep',filesep);

%Update handles and add callback.
handles = guihandles(handles.lddlg);
tobj.tree_clicked_callback = {@tree_click_callback,handles};%Update file list in dropdown if dir and update varlist if file.
tobj.tree_nodeexpand_callback = {@tree_node_expand_callback,handles};

%Update icons.
bicons = browseicons;
set(handles.browsebtn,'cdata',bicons.folderOpen_22,'tooltip','Change the Current Folder.');%, 'background',fcolor);
set(handles.upbtn,'cdata',bicons.folderUpOne_22,'tooltip','Change Current Folder up one folder.');%, 'background',fcolor);

% --------------------------------------------------------------------
function filelist_Callback(h, eventdata, handles, varargin)
%Change current directory or file being looked at.

line = get(handles.sourcename,'value');
list = getappdata(handles.sourcename,'string');
  
if isempty(list); list = {'>>'}; end
item = list{min(end,line)};

if length(item)>1 & item(1:2) == '>>';
  %item is base workspace
  
  set(handles.editvarname,'string',getappdata(handles.lddlg,'defaultname'))
  varlist = evalin('base','whos');
  updatevarlist(h,[],handles,varlist);
  
  set(handles.editfilename,'string','')
  set(handles.editfilename,'enable','off');
  
else
  mydir = getappdata(handles.lddlg,'pwd');
  item = getselectedleaf(handles);
  if iscell(item)
    item = item{1};
  end
  if isempty(item)
   item = getappdata(handles.lddlg,'pwd');
  end
  
  if ~isempty(item)
    itemtype = exist(item);
    
    switch itemtype
      case 7
        %item is a directory
        %wait until open is clicked
        set(handles.editfilename,'string','')
        if ~strcmpi(getappdata(handles.lddlg,'mode'),'save')
          set(handles.editvarname,'string','')
        end
        updatevarlist(h,[],handles);
        set(handles.editvarname,'enable','off')
        %expandtoleaf(ftree,item);
        updatefilelist(h,[],handles,item)
      case 2
        %item is file
        [mydir,fname,ext] = fileparts(item);
        
        if ~strcmpi(getappdata(handles.lddlg,'mode'),'save')
          set(handles.editvarname,'string','')
        end
        try
          if length(ext)>4 & strcmpi(ext,'.smat')
            issmat = true;
            varlist = smatwhos(item);
          elseif length(ext)>3 & strcmpi(ext,'.mat')
            issmat = false;
            varlist = whos('-file',item);
            if length(varlist)==1 & strcmpi(varlist.class,'secureenvelope')
              varlist = smatwhos(item);
            end
          end
          %remove size info on dataset objects
          isds = find(ismember({varlist.class},'dataset'));
          for j = isds;
            varlist(j).size = [];
          end
        catch
          varlist = {};
        end
        
        if ~issmat & ~isempty(varlist) & strcmp(getappdata(handles.lddlg,'mode'),'load');
          varlist            = varlist([1:end 1]);
          varlist(end).name  = '> All... <';
          varlist(end).size  = [0 0];
          varlist(end).bytes = 0;
          varlist(end).class = '*';
        end
        updatevarlist(h,[],handles,varlist);
        updatefilelist(h,[],handles,mydir)
        set(handles.editfilename,'string',[fname ext])
        
    end
    
    set(handles.editfilename,'enable','on','visible','on');
    
  else   %filelist is empty or no file is selected in that list
    if strcmp(getappdata(handles.lddlg,'mode'),'load');
      %Not supposed to happen! Panic and allow only close
      try
        clear(getappdata(handles.lddlg,'filelist'));
      end
      updatevarlist(h,[],handles);
      set(handles.editfilename,'string','');
      set(handles.editfilename,'enable','on');
    else  %save
      if ~isempty(get(handles.editfilename,'string'))
        %got a "new" filename
        updatevarlist(h,[],handles);
      else
        %empty filename and nothing selected? select base
        set(handles.editfilename,'string','');
        set(handles.editfilename,'enable','on');
        updatevarlist(h,[],handles);
      end
    end
  end
end

% --------------------------------------------------------------------
function editfilename_Callback(h, eventdata, handles, varargin)

filename  = get(handles.editfilename,'string');

if isempty(filename)
  filelist_Callback(h,[],handles);
else
  %if strcmp(getappdata(handles.lddlg,'mode'),'load');
    [xpath,xfile,xext] = fileparts(filename); 
    if isempty(xext)
      filename = fullfile(xpath,[xfile getappdata(handles.lddlg,'defaultext')]);
    end
    if exist(filename,'file')
      filename_full = which(filename);
      set(handles.editfilename,'string',filename)
      sourcebtn_Callback(handles.lddlg,[],handles,filename_full);     %update controls for from file
      filelist_Callback(h,[],handles);
    else
      if strcmp(getappdata(handles.lddlg,'mode'),'load')
        set(handles.editfilename,'string','')
      else
        set(handles.editfilename,'string',filename);
        updatevarlist(h,[],handles);
      end
    end
  %else   %save mode
%     %TODO: Fix save mode.
%     if ~ismember(filename,available);     %anything in list match?
%       [xpath,xfile,xext] = fileparts(filename);     %no try renaming as .mat
%       filename = fullfile(xpath,[xfile getappdata(handles.lddlg,'defaultext')]);
%       set(handles.editfilename,'string',filename);
%     end
%     if ~ismember(filename,available);     %nothing in list matches?
%       set(handles.filelist,'value',[])    %unselect in filelist
%       set(handles.filelist,'min',1,'max',3);
%       updatevarlist(h,[],handles);        %and reflect "new" in varlist
%     else
%       set(handles.filelist,'value',strmatch(filename,available,'exact'))
%       set(handles.filelist,'min',0,'max',1);
%       filelist_Callback(h,[],handles);
%     end
%     
  %end
end


% --------------------------------------------------------------------
function varlist_Callback(h, eventdata, handles, varargin)

line = get(handles.varlist,'value');
list = getappdata(handles.lddlg,'varlist');
selectedfiles = getselectedleaf(handles);

if ~isempty(line) & line > 0 & ~isempty(list);
  set(handles.varlist,'min',0,'max',1);
  if length(line) > 1;
    line = line(1);
    set(handles.varlist,'value',line);
  end
  if line > length(list);
    line = length(list);
    set(handles.varlist,'value',line);
  end
  item = list{line};
  
  set(handles.editvarname,'string',item)
  set(handles.editvarname,'enable','on');
  set(handles.loadbtn,'enable','on');
  set(handles.varlist,'enable','on');
  
  if strcmp(get(handles.lddlg,'SelectionType'),'open')
    set(handles.lddlg,'SelectionType','normal')  %force back to "normal" so we don't use this open instruction
    loadbtn_Callback(handles.lddlg, [], handles);
  end
  
else %empty varlist or no items selected
  if isempty(line) & ~isempty(list);
    %nothing selected in list (but list exists)
    if strcmp(getappdata(handles.lddlg,'mode'),'load');
      set(handles.loadbtn,'enable','off');     %load mode: don't allow load
    else
      set(handles.loadbtn,'enable','on');      %save mode: do allow save
    end
  elseif ~isempty(selectedfiles);
    %anything selected in filelist? then this is an existing file/workspace
    set(handles.varlist,'min',1,'max',3);
    set(handles.varlist,'string',{'     <no matches>'},'value',[]);
    set(handles.varlist,'enable','off');
    if strcmp(getappdata(handles.lddlg,'mode'),'load');
      set(handles.editvarname,'string','');
      set(handles.editvarname,'enable','off');
      set(handles.loadbtn,'enable','off');
    else
      set(handles.editvarname,'enable','on');
      set(handles.loadbtn,'enable','on');
    end
  else
    %new filename provided
    set(handles.varlist,'min',1,'max',3);
    set(handles.varlist,'string',{'     <new file>'},'value',[]);
    set(handles.varlist,'enable','off');
    set(handles.editvarname,'enable','on');
    set(handles.editvarname,'string',getappdata(handles.lddlg,'defaultname'));
    if strcmp(getappdata(handles.lddlg,'mode'),'load');
      if ~isempty(get(handles.editvarname,'string'));
        set(handles.loadbtn,'enable','on');
      else
        set(handles.loadbtn,'enable','off');
      end
    else
      set(handles.loadbtn,'enable','on');
    end
  end
end


% --------------------------------------------------------------------
function editvarname_Callback(h, eventdata, handles, varargin)

varname   = get(handles.editvarname,'string');
available = getappdata(handles.lddlg,'varlist');

if strcmp(getappdata(handles.lddlg,'mode'),'load');
  
  if isempty(varname)
    if isempty(get(handles.varlist,'value'));
      set(handles.varlist,'value',1);
    end
    set(handles.varlist,'min',0,'max',1);
    varlist_Callback(h,[],handles);
  else
    if ~ismember(varname,available)
      varlist_Callback(h,[],handles);
    else
      set(handles.varlist,'value',strmatch(varname,available,'exact'))
      set(handles.varlist,'min',0,'max',1);
      varlist_Callback(handles.lddlg,[],handles);
      if (~isempty(gcbo) & double(get(handles.lddlg,'currentcharacter'))==13 & gcbo==handles.editvarname)
        loadbtn_Callback(handles.lddlg, [], handles);
      end
    end
  end
  
else    %save
  
  if ~ismember(varname,available)
    %var name not in list
    set(handles.varlist,'min',1,'max',3,'value',[])
    if ~isempty(varname);       %save as new variable?
      set(handles.loadbtn,'enable','on');
      spacechars = (varname==' ');
      badchars = ((varname<'0' & varname~=' ') | (varname>'9' & varname<'A') | (varname>'Z' & varname<'a' & varname~='_'));
      if any(badchars | spacechars);
        varname(spacechars) = '_';
        varname(badchars) = [];
        set(handles.editvarname,'string',varname);
      else
        if (~isempty(get(0,'currentfigure')) & ~isempty(gcbo) & double(get(gcf,'currentcharacter'))==13 & gcbo==handles.editvarname); loadbtn_Callback(handles.lddlg, [], handles); end
      end
    else        %empty variable name
      set(handles.editvarname,'string',getappdata(handles.lddlg,'defaultname'));
      set(handles.loadbtn,'enable','on');
    end
  else          %overwrite existing variable
    set(handles.varlist,'value',strmatch(varname,available,'exact'))
    set(handles.varlist,'min',0,'max',1);
    set(handles.loadbtn,'enable','on');
    if (~isempty(gcbo) & double(get(handles.lddlg,'currentcharacter'))==13 & gcbo==handles.editvarname)
      loadbtn_Callback(handles.lddlg, [], handles);
    end
  end
  
end


% --------------------------------------------------------------------
function loadbtn_Callback(h, eventdata, handles, varargin)

if strcmp(getappdata(handles.lddlg,'mode'),'load');
  %check sourcename pulldown menu
  line = get(handles.sourcename,'value');
  list = getappdata(handles.sourcename,'string');
  if isempty(list); list = {'>>'}; end
  item = list{line};
  if item(1) ~= '>';   %not base workspace? get name from filelist
    line = 1;
    list = getselectedleaf(handles);
  end
  
  if ~isempty(line) & line > 0 & ~isempty(list);
    item = list{line};
    
    varname   = get(handles.editvarname,'string');
    available = getappdata(handles.lddlg,'varlist');
    if ~ismember(varname,available)
      %don't allow load of non-existant variable
      set(handles.loadbtn,'enable','off');
      return
    end
    
    switch item(1)
      case '[';
        %item is a directory
        %Can't do "load"! just return
      case '>';
        %item is base workspace
        value = evalin('base',varname);
        setappdata(handles.lddlg,'value',value);
        uiresume(gcbf);
      otherwise;
        %item is file
        mydir   = getappdata(handles.lddlg,'pwd');
        
        if ismac & strcmp(mydir,'/')
          erdlgpls('Can''t Load directly from root "/" folder. Copy file to different location before loading.','Mac Load Error')
          uiresume(gcbf)
          return
        end
        
        if strcmp(varname,'> All... <');
          confirm = evriquestdlg('This will load all items in file into the workspace.', ...
            'Load All to Workspace', ...
            'Load','Cancel','Load');
          if strcmp(confirm,'Load');
            contents = load(item,'-mat');
            list = fieldnames(contents);
            for item=list(:)';
              assignin('base',item{:},contents.(item{:}));
            end
            %otherwise...
            if getappdata(handles.lddlg,'exitonall');
              %instructed to exit if user loads all to base workspace? do so
              %now...
              uiresume(gcbf)
              return
            end
            sourcebtn_Callback(handles.lddlg,[],handles,[]);    %set to base workspace
          end;
        else
          %load JUST that one variable
          value   = load(item,'-mat',varname);
          asfield = fieldnames(value);                  %find out what field name it came in as
          value   = getfield(value,asfield{1});         %and extract that one field from value
          
          %test to see if it meets the requirements of size
          % (Normally, the only vars listed are ones which meet the size
          % requirement. However, DataSets inside files can't be checked for
          % size so ALL datasets are available for loading. As a result, we
          % must check here for valid dataset sizes.)
          validclasses = getappdata(handles.lddlg,'validclasses');
          validdims    = getappdata(handles.lddlg,'validdims');
          if isa(value,'dataset') & ~ismember(length(size(value.data)),validdims)
            if length(size(value.data))<min(validdims);
              erdlgpls({['This DataSet object is only ' num2str(length(size(value.data))) ' dimensional.'],...
                ['A ' num2str(min(validdims)) ' dimenstional DataSet is expected'],'Please select a different item.'},'Unable to load item');
            else
              erdlgpls({['This DataSet object is ' num2str(length(size(value.data))) ' dimensional.'],...
                ['A ' num2str(max(validdims)) ' dimenstional DataSet is expected'],'Please select a different item.'},'Unable to load item');
            end
          else
            setappdata(handles.lddlg,'value',value);      %store for retrieval
            uiresume(gcbf);
          end
        end
    end
    
  end
  
else
  
  %FIXME: These getting cleared.
  varname  = get(handles.editvarname,'string');
  mydir    = getappdata(handles.lddlg,'pwd');
  filename = get(handles.editfilename,'string');
  value    = getappdata(handles.lddlg,'value');
  
  %no filename and in To File mode? don't save
  if ~strcmp(get(handles.sourcebtn,'string'),'To File') & isempty(filename);
    erdlgpls('A filename is required','Save Dialog');
    return;
  end
  
  %no var, don't save
  if isempty(varname);
    erdlgpls('A name for the item is required','Save Dialog');
    return;
  end
  
  if isempty(filename)
    %save in base workspace
    if evalin('base',sprintf('exist(''%s'',''var'')',varname))
      overwrite = evriquestdlg(sprintf('"%s" already exists.\nDo you want to replace it?',varname),'Confirm Save As','Yes','No','Yes');
      if ~strcmp(overwrite,'Yes')
        return;
      end
    end
    assignin('base',varname,value);
    uiresume(gcbf);
  else
    if filename(1)~='[';      %if item is a directory we can't do "save"! just return (shouldn't have happened!)
      if strcmp(filename(end-4:end),'.smat') & exist(fullfile(mydir,filename),'file')
        overwrite = evriquestdlg(sprintf('%s already exists.\nDo you want to replace it?',filename),'Confirm Save As','Yes','No','Yes');
        if ~strcmp(overwrite,'Yes')
          return;
        end
      end
      try
        if exist(fullfile(mydir,filename),'file') & ismember(varname,who('-file',fullfile(mydir,filename)))
          overwrite = evriquestdlg(sprintf('"%s" already exists in this file.\nDo you want to replace it?',varname),'Confirm Save As','Yes','No','Yes');
          if ~strcmp(overwrite,'Yes')
            return;
          end
        end
        msg = safesave(fullfile(mydir,filename),varname,value);
        if isempty(msg)
          uiresume(gcbf);
        else
          erdlgpls(msg,'Save Error')
        end
      catch
        erdlgpls(lasterr,'Save Error')
      end
    end
  end
  
end


% --------------------------------------------------------------------
function cancelbtn_Callback(h, eventdata, handles, varargin)

close(gcbf);

% --------------------------------------------------------------------
function updatefilelist(h, eventdata, handles, varargin)
%Update list of folders in source dropdown. Also expand to leaf is
%nargin>1. 


if nargin < 4; varargin = {pwd}; end
if nargin < 5; varargin{2} = []; end

ftree = getappdata(handles.lddlg,'filelist');

if isempty(varargin{1}) | (length(varargin{1})>2 & varargin{1}(1:2)=='>>');
  %empty or >>? must be "Base Workspace"
  str   = {'>> Workspace <<'};
  strtrim = str;
  setappdata(handles.sourcename,'string',str);
  filelist_Callback(handles.lddlg,[],handles);
else
  pathstr  = varargin{1};
  setappdata(handles.lddlg,'pwd',pathstr);
  if ~isempty(varargin{2})
    %Expand to file leaf.
    setappdata(handles.lddlg,'building_tree',1)
    expandtoleaf(ftree,fullfile(pathstr,varargin{2}));
    setappdata(handles.lddlg,'building_tree',[])
  else
    %Do not expand to folder or user will never be able to close a leaf.
    %expandtoleaf(ftree,pathstr);
  end
  str     = {};
  strtrim = {};
  temp1   = pathstr;
  temp2   = 'startloop';
  while ~isempty(temp2)     %piece apart path
    [temp1,temp2]  = splitpath(temp1);
    str{end+1}     = [temp1 temp2];
    if length(str{end}) > 55;
      [z2,z1] = splitpath(str{end});
      [z3,z2] = splitpath(z2);
      z1      = [z2 filesep z1];
      strtrim{end+1} = [z3(1:max([(55-length(z1)) 3])) '...' filesep z1];
    else
      strtrim{end+1} = str{end};
    end
  end
  str      = fliplr(str);
  strtrim  = fliplr(strtrim);
end

set(handles.sourcename,'string',strtrim);
set(handles.sourcename,'value',length(str));
setappdata(handles.sourcename,'string',str);

%filelist_Callback(handles.lddlg,[],handles);

% --------------------------------------------------------------------
function [p1,p2] = splitpath(p)

if isempty(p); p1=[]; p2=[]; return; end

if p(end) == filesep; p(end)=[]; end    %drop ending filesep char

ind = max(findstr(p,filesep));
if ~isempty(ind);
  p1  = p(1    :ind);
  p2  = p(ind+1:end  );
else
  p1  = [p filesep];
  p2  = [];
end

% --------------------------------------------------------------------
function updatevarlist(h, eventdata, handles, varargin)

if nargin > 3 & ~isempty(varargin{1});
  list = varargin{1};
else
  list = {};
end

validclasses = getappdata(handles.lddlg,'validclasses');
validdims    = getappdata(handles.lddlg,'validdims');

%find valid variables (those that match classes and dims defined earlier)
%and find longest name of those to use
keep      = [];
maxlength = 10;
for k=1:length(list);
  %determine actual valid size (drop empty vars) NOTE: a class of * is a special item we need to always keep
  if strcmp(list(k).class,'*') | ((ismember('*',validclasses) | ismember(list(k).class,validclasses)) & (isempty(list(k).size) | ~any(list(k).size==0)) & (isempty(list(k).size) | ismember(length(list(k).size),validdims)));
    keep = [keep k];
    maxlength = max([maxlength length(list(k).name)]);
  end
end

if length(keep) == 1 & strcmp(list(keep).class,'*'); keep = []; end; %don't allow special items if no vars matched validclasses

if ~isempty(keep);
  
  list = list(keep);    %drop non-valid classes
  
  desc = cell(0);
  for k=1:length(list);
    name = list(k).name;
    if ~strcmp(list(k).class,'*');
      if ~isempty(list(k).size)
        desc{k} = [name blanks(maxlength-fix((length(name)))) ' ' sprintf('%ix',list(k).size(1:end-1)) sprintf('%i',list(k).size(end)) ' ' '(' list(k).class ')'];
      else
        desc{k} = [name blanks(maxlength-fix((length(name)))) ' '  sprintf('%i bytes',list(k).bytes)  '  (' list(k).class ')'];
      end
    else      %special item which doesn't have size info (e.g. >> Load All... <<)
      desc{k} = [name];
    end
  end
  
  setappdata(handles.lddlg,'varlist',{list.name});
  set(handles.varlist,'string',desc);
  if strcmp(getappdata(handles.lddlg,'mode'),'load');
    set(handles.varlist,'min',0,'max',1);
    set(handles.varlist,'value',1);
  else
    set(handles.varlist,'min',1,'max',3);
    set(handles.varlist,'value',[]);
    set(handles.editvarname,'string',getappdata(handles.lddlg,'defaultname'));
  end
  set(handles.varlist,'enable','on');
  set(handles.editvarname,'enable','on');
  
else
  setappdata(handles.lddlg,'varlist',{});
  set(handles.varlist,'string',{});
  set(handles.varlist,'min',1,'max',3);
  set(handles.varlist,'value',[]);
  set(handles.varlist,'enable','off');
end
varlist_Callback(handles.lddlg,[],handles);

% --------------------------------------------------------------------
function msg = safesave(SAFESAVEfilename,SAFESAVEvarname,SAFESAVEvalue)
% Special function to save user variables into file... isolated from
%  other functions to assure no funny filenames are used which might cause problems

msg = '';
try
  tosave = struct(SAFESAVEvarname,{SAFESAVEvalue});
catch
  badchars=~ismember(SAFESAVEvarname,['0':'9' 'A':'Z' 'a':'z' '_']);
  if isempty(SAFESAVEvarname)
    msg = 'Variable name empty';
  elseif ismember(SAFESAVEvarname(1),['0':'9'])
    msg = 'Variable name cannot start with a number';
  elseif  any(badchars)
    msg = ['Variable name cannot contain the character(s): ' sprintf('%s ',SAFESAVEvarname(badchars))];
  else
    msg = 'Invalid variable name';
  end
  return
end

[SAFESAVEjunkpath,SAFESAVEfile,SAFESAVEext] = fileparts(SAFESAVEfilename);

if ismac & strcmp(SAFESAVEjunkpath,'/')
  %Saving to the root folder with '/' in file name causes error on Mac.
  SAFESAVEfilename = SAFESAVEfilename(2:end);
end

%check if the size is too large to save under default file format
v73flag = {};
try
  whosinfo = whos('tosave');
  if whosinfo.bytes>2e9
    v73flag = {'-v7.3'};
  end
catch
  %no error - just save without flag
end

switch SAFESAVEext
  case '.smat'
    securesave(SAFESAVEfilename,'-struct','tosave',v73flag{:})
  otherwise
    if exist(SAFESAVEfilename,'file')
      save(SAFESAVEfilename,'-struct','tosave','-append',v73flag{:})
    else
      save(SAFESAVEfilename,'-struct','tosave',v73flag{:})
    end
end

% --------------------------------------------------------------------
function sourcename_Callback(h, eventdata, handles, varargin)
%Change directory from "Look in" dropdown menu.

line = get(handles.sourcename,'value');
list = getappdata(handles.sourcename,'string');
if isempty(list); list = {pwd}; line = 1; end
%Send "dummy" space character to force updastefilelist to update tree path. 
updatefilelist(handles.lddlg,[],handles,list{line},' ')
filelist_Callback(handles.lddlg,[],handles)

% --------------------------------------------------------------------
function upbtn_Callback(h, eventdata, handles, varargin)

line = get(handles.sourcename,'value');

  if ~isempty(getappdata(handles.lddlg,'building_tree'))
    %If flag for building tree is still there then return. There could be 1-2
    %second delay in building tree if current folder is really deep in file
    %system.
    return
  end

if line > 1;
  set(handles.sourcename,'value',line-1);
  %Check to see if building tree.
  sourcename_Callback(handles.sourcename,eventdata,handles);
end

% --------------------------------------------------------------------
function browsebtn_Callback(h, eventdata, handles, varargin)

if checkmlversion('<','6.5');
  [filename,newpath] = evriuigetfile('*.*','Select any file in target folder');
else
  newpath = evriuigetdir(getappdata(handles.lddlg,'pwd'));
end

if isnumeric(newpath);  %check if cancel was pressed
  return
end

if ~strcmp(newpath(end),filesep)
  newpath = [newpath filesep];
end
%sourcebtn_Callback(handles.sourcename,eventdata,handles,newpath);
updatefilelist(handles.lddlg,[],handles,newpath,' ')
% --------------------------------------------------------------------
function sourcebtn_Callback(h, eventdata, handles, varargin)
%Change between file and workspace as source.

line = get(handles.sourcename,'value');
list = getappdata(handles.sourcename,'string');

%Check to see if building tree.
if ~isempty(getappdata(handles.lddlg,'building_tree'))
  %If flag for building tree is still there then return. There could be 1-2
  %second delay in building tree if current folder is really deep in file
  %system.
  return
end
if isempty(list); list = {' '}; line = 1; end   %empty? trigger base workspace
item = list{line};

if nargin < 4;  %toggle between base and file
  if (length(item)>1 & item(1:2) == '>>');
    lastfile = getappdata(handles.sourcename,'lastfile');
    if isempty(lastfile); lastfile = {''}; end
    if ~iscell(lastfile); lastfile = {lastfile}; end
    if isempty(deblank(lastfile{1}))
      lastfile = {' '};
    end
    varargin = lastfile;
  else
    varargin{1} = [];
  end
end
%test what was input and trigger appropriate source
if isempty(varargin{1});
  filemode = 0;
else
  filemode = 1;
  if exist(deblank(varargin{1}))==7  %if it is a folder name, just use it
    path = varargin{1};
    varargin{1} = '';
  else
    [path,name,ext] = fileparts(varargin{1});
    varargin{1} = [name ext];
  end
  setappdata(handles.sourcename,'lastfile',varargin{1});
  if ~isempty(path);
    list = {};
    setappdata(handles.lddlg,'pwd',path);
  end
end

if filemode;   %currently in base workspace, make it file mode
  
  if strcmp(getappdata(handles.lddlg,'mode'),'load');
    set(handles.sourcebtn,'string','From Workspace')
  else
    set(handles.sourcebtn,'string','To Workspace')
  end
  
  set(handles.sourcename,'enable','on');
  set([handles.browsebtn handles.upbtn handles.editfilename handles.filelist handles.text2 handles.text4],'visible','on');
  
  set(handles.varlist,'string',{' '},'value',1);
  
  if length(list)>1;
    item = list{end-1};
    set(handles.sourcename,'value',length(list)-1)
  else
    set(handles.sourcename,'value',1);
    mydir = getappdata(handles.lddlg,'pwd');
    if isempty(mydir) | ~exist(mydir,'file'); mydir = pwd; end;
    setappdata(handles.sourcename,'string',{mydir '>>'});
    item = mydir;
  end
  if isempty(varargin{1})
    %Make sure to force tree update.
    varargin{1} = ' ';
  end
  
  updatefilelist(handles.lddlg,[],handles,item,varargin{1})
  filelist_Callback(handles.lddlg,[],handles);
  resize(handles.lddlg, [], handles)

else    %currently in file mode (or no mode) make it base workspace mode
  
  %extract current filename (if any) and save for when we come back to file mode
  selectedfile = getselectedleaf(handles);
  if ~isempty(selectedfile)
    setappdata(handles.sourcename,'lastfile',selectedfile);
  end
  
  if strcmp(getappdata(handles.lddlg,'mode'),'load');
    set(handles.sourcebtn,'string','From File')
  else
    set(handles.sourcebtn,'string','To File')
  end
  set(handles.sourcename,'enable','off');
  set([handles.browsebtn handles.upbtn handles.editfilename handles.filelist handles.text2 handles.text4],'visible','off');
  
  set(handles.varlist,'string',{' '},'value',1);
  
  set(handles.sourcename,'value',length(list))
  updatefilelist(handles.lddlg,[],handles,[])   %trigger "base workspace"
  filelist_Callback(handles.lddlg,[],handles);
  resize(handles.lddlg, [], handles)
  
end

% --------------------------------------------------------------------
function resize(h, eventdata, handles, varargin)
%Resize callback for figure.

set(h,'resize','on','resizefcn','lddlgpls(''resize'',gcbf,[],guidata(gcbf));');

offset   = 5;
minwidth = 482;
minheight = 180;
set(handles.lddlg,'units','pixels');
figsize = get(handles.lddlg,'position');
setappdata(0,'lddlgpls_size',figsize);  %save current fig size and position

pos.description = get(handles.description,'position');
pos.text7       = get(handles.text7,'position');
pos.upbtn       = get(handles.upbtn,'position');
pos.browsebtn   = get(handles.browsebtn,'position');
pos.sourcename  = get(handles.sourcename,'position');
pos.filelist    = get(handles.filelist,'position');
pos.text2       = get(handles.text2,'position');
pos.varlist     = get(handles.varlist,'position');
pos.text3       = get(handles.text3,'position');
pos.frame1      = get(handles.frame1,'position');
pos.text4       = get(handles.text4,'position');
pos.editfilename = get(handles.editfilename,'position');
pos.text5       = get(handles.text5,'position');
pos.editvarname = get(handles.editvarname,'position');
pos.loadbtn     = get(handles.loadbtn,'position');
pos.cancelbtn   = get(handles.cancelbtn,'position');

if figsize(3)<minwidth;
  figsize(3) = minwidth;
end
if figsize(4)<minheight
  figsize(4) = minheight;
end

btsz = 32;

%description
pos.description(2) = figsize(4)-offset-pos.description(4);
pos.description(1) = offset;
pos.description(3) = figsize(3)-offset*2;

%text7 "look in"
pos.text7(2) = pos.description(2)-pos.text7(4);

%"browse" button
pos.browsebtn(1) = figsize(3)-offset-pos.browsebtn(3);
pos.browsebtn(2) = pos.description(2)-pos.browsebtn(4)+6;
pos.browsebtn(3) = btsz;
pos.browsebtn(4) = btsz;

%"up" button
pos.upbtn(1) = pos.browsebtn(1)-offset-pos.upbtn(3)+4;
pos.upbtn(2) = pos.description(2)-pos.upbtn(4)+6;
pos.upbtn(3) = btsz;
pos.upbtn(4) = btsz;

%sourcename menu
pos.sourcename(2) = pos.description(2)-pos.sourcename(4);
pos.sourcename(3) = figsize(3)-(figsize(3)-pos.upbtn(1))-offset-pos.sourcename(1);

%filelist header
pos.text2(2) = pos.upbtn(2)-pos.text2(4)-offset;

%filelist
pos.filelist(2) = pos.varlist(2);
if strcmp(get(handles.varlist,'visible'),'on');
  pos.filelist(3) = (figsize(3)-offset*2)/2-offset/2;
else
  pos.filelist(3) = figsize(3)-offset*2;
end
pos.filelist(4) = pos.text2(2)-pos.filelist(2)-offset;

%filelist header
pos.text2(1) = pos.filelist(1);
pos.text2(3) = pos.filelist(3);

%varlist header
pos.text3(2) = pos.upbtn(2)-pos.text3(4)-offset;

%Var name text and editbox.
pos.text5(1)       = pos.filelist(1)+pos.filelist(3)+offset;
pos.editvarname(1) = pos.text5(1)+pos.text5(3)+4;
pos.editvarname(3) = figsize(3)-pos.editvarname(1)-2*offset;

%File name editbox.
pos.editfilename(1) = pos.text4(1)+pos.text4(3)+4;
pos.editfilename(3) = figsize(3)-pos.editvarname(1)+20;

%varlist
if strcmp(get(handles.filelist,'visible'),'on');
  pos.varlist(1) = pos.filelist(1)+pos.filelist(3);
else
  pos.varlist(1) = offset;
end
pos.varlist(3) = figsize(3)-pos.varlist(1)-offset;
pos.varlist(4) = pos.text3(2)-pos.varlist(2)-offset;

%varlist header
pos.text3(1) = pos.varlist(1);
pos.text3(3) = pos.varlist(3);

%Buttons, load and cancel.
pos.loadbtn(1) = figsize(3)-pos.loadbtn(3)*2-14;%pos.frame1(1)+pos.frame1(3)-pos.loadbtn(3)-pos.cancelbtn(3)-6;
pos.cancelbtn(1) = figsize(3)-pos.cancelbtn(3)-10;%pos.frame1(1)+pos.frame1(3)-pos.loadbtn(3)-6;

%lower frame
pos.frame1(3) = figsize(3)-pos.frame1(1)-offset;

set(handles.description,'position',pos.description);
set(handles.text7,'position',pos.text7);
set(handles.browsebtn,'position',pos.browsebtn);
set(handles.upbtn,'position',pos.upbtn);
set(handles.sourcename,'position',pos.sourcename);
set(handles.filelist,'position',pos.filelist);
set(handles.text2,'position',pos.text2);
set(handles.varlist,'position',pos.varlist);
set(handles.text3,'position',pos.text3);
set(handles.frame1,'position',pos.frame1);
set(handles.text5,'position',pos.text5);
set(handles.editvarname,'position',pos.editvarname);
set(handles.editfilename,'position',pos.editfilename);
set(handles.loadbtn,'position',pos.loadbtn);
set(handles.cancelbtn,'position',pos.cancelbtn);

%--------------------------------------------------------------
function settings = getsettings(varargin)

defaultsettings.figsize = [];
defaultsettings.fromfile = '';
defaultsettings.fromworkspace = 1;
defaultsettings.tofile = '';
defaultsettings.toworkspace = 1;

settings = getappdata(0,'lddlgpls_settings');
settings = reconopts(settings,defaultsettings);

%--------------------------------------------------------------
function varlist = smatwhos(file)

varlist = struct('name','','size',[],'bytes',[],'class','');
varlist(1) = [];  %make empty structure

if ~exist('secureload')
  return
end

contents = load(file);
fields   = fieldnames(contents);
for j=1:length(fields);
  varlist(j).name  = fields{j};
  varlist(j).size  = size(contents.(fields{j}));
  varlist(j).bytes = 0;
  varlist(j).class = class(contents.(fields{j}));
end

%---------------------------
function tree_click_callback(varargin)
%Refresh tree node if doubleclicked.
handles = varargin{3};
%Call filelist callback.
filelist_Callback(handles.lddlg, [], handles, varargin)

%---------------------------
function tree_node_expand_callback(varargin)
%Expanding node.
%filelist_Callback(handles.lddlg, [], handles, varargin)

%---------------------------
function out = get_pls_root
%Get PLS_Toolbox root folder.

out = fileparts(which('evriinstall'));

%---------------------------
function fontsize = getdefaultfontsize
%Get default fontsize.
fontsize = 10;
if ~ispc
  fontsize = 12;
end

%---------------------------
function refreshbtn_Callback(hObject, eventdata, handles)
%Refresh either tree or workspace.

if strcmp(get(handles.filelist,'visible'),'on');
  %File mode, refresh tree.
  ftree = getappdata(handles.lddlg,'filelist');
  refresh(ftree);
else
  %Variable mode.
  varlist = evalin('base','whos');
  updatevarlist(handles.lddlg,[],handles,varlist);
end

%---------------------------
function helpbtn_Callback(hObject, eventdata, handles)
%Open help file.
evrihelp('loading_and_saving')

%---------------------------
function out = getselectedleaf(handles)
%Get default fontsize.
out = [];
ftree = getappdata(handles.lddlg,'filelist');
if ~isempty(ftree)
  [junk1, junk2, out] = getselected(ftree);
end

