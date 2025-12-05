function out = browse(varargin)
%BROWSE PLS_Toolbox Toolbar and Workspace browser.
%I/O: browse
%
%See also: ANALYSIS

%Copyright Eigenvector Research, Inc. 2000
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.
%JMS 2/4/04 -released with beta to developers
%JMS 2/6/04 -added option for figure icons in window
%   -changed option names and converted some to logical
%rsk 06/08/04 Name change to 'Toolbox Browser'
%jms 6/14/04 If autoopen, don't allow move of icons
%jms 9/18/04 return figure number on construct
%rsk 05/31/06 add model icon.

%check if we should be using the "old-style" desktop format
persistent desktop
if isempty(desktop)
  desktop = getplspref('browse','desktop');
  if isempty(desktop); desktop = 0; end
end
if checkmlversion('<','7.1') | desktop
  if nargout==0
    browse_old(varargin{:});
  else
    out = browse_old(varargin{:});
  end
  return
end

if nargin==0 || (nargin==1 && isstruct(varargin{1}));
  
  options = [];
  
  fig = findobj(allchild(0),'tag','eigenworkspace');
  if ~isempty(fig);
    %fig already exists - only need to make visible and update (if
    %anything)
    figure(fig);
    set_workspace_nodes(guihandles(fig));  %refresh workspace
    if nargout>0;
      out = fig;
    end
    return;
  end
  
  %need to create figure
  if nargin==1
    options = varargin{1};
  end
  options = reconopts(options,'browse');
  fig = figure(...
    'visible','off',...
    'busyaction','cancel',...
    'integerhandle','off',...
    'CloseRequestFcn', 'try;browse(''closegui'');catch;delete(gcbo);end');
  toolbar(fig,'help');
  
  initmsg = uicontrol(fig,'style','text',...
    'BackgroundColor',[1 1 1],...
    'ForegroundColor',[0 0 .4],...
    'units','normalized',...
    'position',[0 0 1 .55],...
    'string','Initializing... Please Wait...',...
    'fontsize',14,...
    'fontname','Courier',...
    'fontweight','bold');
  
  %get last figure position (stored previously)
  pos = get(fig,'position');
  %Default figure size is 560w 420h but we need it wider so current
  %directory dropdown and buttons are not truncated.
  pos(3) = 760;
  set(fig,'position',pos)
  centerfigure(fig)
  positionmanager(fig,'browse') %set fig to previously stored position and make sure on-screen
  
  for fld = fieldnames(options)';
    setappdata(fig,fld{:},getfield(options,fld{:}));
  end
  
  if solo
    name = [solo(1) ' Workspace Browser'];
  else
    name = 'PLS_Workspace Browser';
  end
  
  set(fig,...
    'visible','on',...
    'menubar','none',...
    'doublebuffer','on',...
    'numbertitle','off',...
    'color',[1 1 1],...
    'tag','eigenworkspace',...
    'units','pixels',...
    'name',name);
  %delete(setdiff(allchild(fig),[findobj(fig,'type','uimenu'); findobj(fig,'type','uitoolbar'); findobj(fig,'type','uipushtool')]));
  setappdata(fig,'workspace',[]);
  
  delete(findobj(fig,'tag','figbrowsermenu'));
  
  hmenu = uimenu(fig,'Label','&File','tag','FileMenu','callback','browse(''filemenu'')');
  uimenu(hmenu,'label','&New DataSet...','callback','editds(''filenew'',editds);');
  h1 = uimenu(hmenu,'label','&Import Data...','callback','');
  editds_addimportmenu(h1,'autoimport(get(gcbo,''userdata''),struct(''target'',''workspace''));browse(''workspace'',''update'');');
  
  uimenu(hmenu,'label','Change &Directory','callback','browse(''changepwd'');','separator','on');
  uimenu(hmenu,'label','&Load Workspace...','callback','browse(''workspace'',''load'')','separator','on','tag','wsload');
  uimenu(hmenu,'label','&Save Workspace...','callback','browse(''workspace'',''save'')','tag','wssave');
  uimenu(hmenu,'label','&Clear Workspace','callback','browse(''workspace'',''clear'')');
  uimenu(hmenu,'label','Save &Item...','tag','editSave','callback','browse(''datacontextmenu'',gcbo,''save'');','separator','on');
  
  emenu = uimenu(hmenu,'label','&Export Item...','tag','fileExport');
  elist = autoexport('options');
  elist = elist.validtypes;
  for k = 1:size(elist,1);
    uimenu(emenu,'label',elist{k,2},'callback',['browse(''datacontextmenu'',gcbo,''export'');'],'userdata',elist{k,1});
  end
  
  uimenu(hmenu,'label','&Change Cache','tag','fileChangeCache','callback','modelcache(''changecachedir'','''');','separator','on');
  uimenu(hmenu,'label','Remote &Automation','callback','browse(''automation'');','separator','on','tag','FileAutomation');
  uimenu(hmenu,'label','Cl&ose','callback','close(gcbf)','separator','on','tag','FileClose');
  
  hmenu = uimenu(fig,'Label','&Edit','tag','EditMenu','callback','browse(''editmenu'')');
  uimenu(hmenu,'label','&Combine Items','tag','editCombine','callback','browse(''datacontextmenu'',gcbo,''combine'');');
  uimenu(hmenu,'label','&Delete Item','tag','editDelete','callback','browse(''datacontextmenu'',gcbo,''delete'');');
  uimenu(hmenu,'label','&View Contents','tag','editView','callback','browse(''datacontextmenu'',gcbo,''view'');');
  uimenu(hmenu,'label','Open in &Editor','tag','editEdit','callback','browse(''datacontextmenu'',gcbo,''edit'');');
  
  h1 = uimenu(hmenu,'label','&Options','tag','editoptions','separator','on');
  uimenu(h1,'label','&Edit Default Fontsize','callback','browse(''editdefaultfontsize'',gcf)','tag','editdefaultfontsize')
  uimenu(h1,'label','Edit Default &Colormap','callback','editdefaultcolormap','tag','editdefaultcolorbar')
  uimenu(h1,'label','&Workspace Browser Options','callback','browse(''browseoptions'',gcf)','tag','editpreferences')
  uimenu(h1,'label','Workspace &Shortcuts','callback','browse selectshortcuts','tag','editshortcuts')
  uimenu(h1,'label','&Model Cache Settings','callback','modelcache settings','tag','editcachesettings')
  uimenu(h1,'label','&Window Docking Settings','callback','analysis(''editdocksettings'',gcbo,[],guidata(gcbo))','tag','editdocksettings')

  h2 = uimenu(h1,'label','&GRoot Settings','tag','editgroot'); 
  uimenu(h2,'label','&Open GRootEditor','callback','browse(''browse_grootsettings'',''edit'')','tag','editopengrooteditor') 
  uimenu(h2,'label','&GRoot Reset All','callback','browse(''browse_grootsettings'',''resetall'')','tag','editgrootresetall')

  h3 = uimenu(h1,'label','&Python','tag','editconfigpy'); 
  uimenu(h3,'label','&Configure Python with Conda','callback','browse(''browse_pyconfig'',''addConda'')','tag','editconfigpyaddconda') 
  uimenu(h3,'label','&Configure Python with Archived File','callback','browse(''browse_pyconfig'',''addArchived'')','tag','editconfigpyaddarchived') 
  uimenu(h3,'label','&Remove PLS_Toolbox Python Environment','callback','browse(''browse_pyconfig'',''remove'')','tag','editconfigpyremove') 
  uimenu(h3,'label','&Remove Miniconda3/Anaconda3','callback','browse(''browse_pyconfig'',''delete'')','tag','editconfigpydelete') 
  uimenu(h3,'label','&Check Environment Status','callback','browse(''browse_pyconfig'',''check'')','tag','editconfigpycheck') 
  uimenu(h3,'label','&Display Appropriate Python Version','callback','browse(''browse_pyconfig'',''which'')','tag','editconfigpywhich')

  uimenu(h1,'label','&Preferences (Expert)','tag','expertprefs','callback','prefexpert','separator','on');
  
  hmenu = uimenu(fig,'Label','&View','tag','ViewMenu','callback','browse(''viewmenu'')');
  uimenu(hmenu,'label','&Refresh Window','callback','browse(''refresh'',gcf);','separator','off');
  uimenu(hmenu,'label','Reset &Model Cache','callback','modelcache(''reset'');','separator','on');
  
  hmenu = uimenu(fig,'Label','&Analyze','tag','AnalyzeMenu','callback','browse(''analyzemenu'')');
  anallist = analysistypes;
  for j=1:size(anallist,1);
    uimenu(hmenu,'label',anallist{j,2},'callback','browse(''analyze'',gcbo)','userdata',anallist{j,1},'separator',anallist{j,4});
  end
  h1 = uimenu(hmenu,'label','Other Tools','callback','','separator','on');
  list = browse_shortcuts([],struct('show',''));  %get all shortcut items
  for j=1:length(list);
    if ~strcmp(list(j).type,'favorites') && ~strcmp(list(j).drop,'off') && ((~iscell(list(j).fn) && ~ismember(list(j).fn,{'analysis'})) || (iscell(list(j).fn) && ~ismember(list(j).fn{1},{'analysis'})));
      uimenu(h1,'label',list(j).name,'callback','browse(''analyze'',gcbo)','userdata',list(j));
    end;
  end
  
  %Custom add-in parent menu. If add-in codes are entered via Help/Enable
  %Addin menu then this menu will be made visible and sub menu items may
  %appear. 
  amenu = uimenu(fig,'Label','&Add-In','tag','AddinMenu','callback','','visible','off');

  %Help menu
  if solo
    hname = solo(1);
  else
    hname = 'PLS_Toolbox';
  end
  hmenu = uimenu(fig,'Label','&Help','tag','HelpMenu','callback','browse(''helpmenu'')');
  uimenu(hmenu,'label',[hname ' &Help'],'tag','help_helppls','callback','helppls;');
  uimenu(hmenu,'label','&Adjust Help Font Size','callback','browse(''updatehelpfont'',gcf);');
  uimenu(hmenu,'label',['&Chemometrics Tutorial'],'tag','help_tbmanual','callback','pls_toolboxhelp;','separator','on');
  if ~solo
    uimenu(hmenu,'label','Function &Reference Manual','tag','help_refmanual','callback','pls_toolboxhelp(''ref'');');
    uimenu(hmenu,'label','&DataSet Object Manual','tag','help_datasetmanual','callback','pls_toolboxhelp(''dso'');');
  end
  uimenu(hmenu,'label','&Eigenvector Research (online)','tag','help_evrionline','callback','pls_toolboxhelp(''web'');','separator','on');
  uimenu(hmenu,'label','&FAQ (online)','tag','help_faqonline','callback','pls_toolboxhelp(''faq'');');
  uimenu(hmenu,'label','How-To &Movies (online)','tag','help_moviesonline','callback','pls_toolboxhelp(''movies'');');
  if ~strcmp(evriupdate('mode'),'disabled')
    uimenu(hmenu,'label','Check for &Updates (online)','tag','help_checkupdates','callback','evriupdate');
  end
  uimenu(hmenu,'label','&Send Error Report','tag','help_senderror','callback','evrireporterror','visible','on','separator','on'); 
  uimenu(hmenu,'label','&Function Use Reporting...','tag','help_evristats','callback','evristats','visible','on','separator','off','checked','off');
  
  uimenu(hmenu,'label',['Reset &License'],'tag','help_clearlicense','callback','browse(''resetlicense'',guidata(gcbo))','visible','on','separator','off');
  if ~solo
    phh = uimenu(hmenu,'label','&Move Path Folders','tag','help_movepath');
    uimenu(phh,'label','&Top of Matlab Path','tag','help_movepath_top','callback','evrimovepath(''top'');');
    uimenu(phh,'label','&Bottom of Matlab Path','tag','help_movepath_bottom','callback','evrimovepath(''bottom'');');
  end
  uimenu(hmenu,'label',['&Enable Add-in ' hname],'tag','addin_enable','callback','browse(''addinmenu'',gcbf)','separator','on');
  
  uimenu(hmenu,'label',['&About ' hname],'tag','help_aboutplstb','callback','plsver;','separator','on');
  
  testmenu = uimenu(hmenu,'label','Testing','tag','help_testingmenu','visible','off','userdata','help_special','separator','off');
  uimenu(testmenu,'label','Test Command &Window','tag','help_testwindow','callback','browse testwindow','visible','on','separator','off');
  uimenu(testmenu,'label','&Analysis Test','tag','help_analtest','callback','browse(''unittest'',''analysis_test'')','visible','on','separator','off');
  
  figbrowser on
  
  ood = evriupdate('autosilent');
  if ood==1
    uimenu(fig,'label','New Version!','tag','new_version_flag','callback','evriupdate');
  elseif ood==2;
    uimenu(fig,'label','Maintenance!','tag','new_version_flag','callback','evriupdate');
  end
  
  toolbar(fig,'browse');
  
  %create workspace context menu
  hcontext = findobj(fig,'tag','wscontextmenu');
  if isempty(hcontext)
    hcontext = uicontextmenu;
    set(hcontext,'callback','browse(''wscontextmenu'',gcbo)');
    set(hcontext,'tag','wscontextmenu')
  end
  uimenu(hcontext,'label','New DataSet','callback','editds(''filenew'',editds);');
  uimenu(hcontext,'label','&Clear Workspace','callback','browse(''workspace'',''clear'')');
  uimenu(hcontext,'label','Refresh','callback','browse;','separator','on')
  
  %create data object context menu
  hdcontext = findobj(fig,'tag','datacontextmenu');
  if isempty(hdcontext)
    hdcontext = uicontextmenu;
    set(hdcontext,'callback','browse(''datacontextmenu'',gcbo)');
    set(hdcontext,'tag','datacontextmenu')
  end

  uimenu(hdcontext,'label','Rename','callback','browse(''datacontextmenu'',gcbo,''rename'');');
  uimenu(hdcontext,'label','View','callback','browse(''datacontextmenu'',gcbo,''view'');','separator','on');
  uimenu(hdcontext,'label','Plot','callback','browse(''datacontextmenu'',gcbo,''plot'');','separator','off');
  uimenu(hdcontext,'label','Edit','callback','browse(''datacontextmenu'',gcbo,''edit'');');
  uimenu(hdcontext,'label','Copy','callback','browse(''datacontextmenu'',gcbo,''copy'');','separator','on');
  uimenu(hdcontext,'label','Duplicate','callback','browse(''datacontextmenu'',gcbo,''duplicate'');');
  uimenu(hdcontext,'label','Combine','callback','browse(''datacontextmenu'',gcbo,''combine'');');
  uimenu(hdcontext,'label','Compare','callback','browse(''datacontextmenu'',gcbo,''compare'');','separator','on');
  uimenu(hdcontext,'label','Save','callback','browse(''datacontextmenu'',gcbo,''save'');');
  uimenu(hdcontext,'label','Delete','callback','browse(''datacontextmenu'',gcbo,''delete'');');
  uimenu(hdcontext,'label','Delete All Others','callback','browse(''datacontextmenu'',gcbo,''keep'');');
  menuh = uimenu(hdcontext,'label','Analyze');
  anallist = analysistypes;
  for j=1:size(anallist,1);
    uimenu(menuh,'label',anallist{j,2},'callback','browse(''analyze'',gcbo)','userdata',anallist{j,1},'separator',anallist{j,4});
  end
  
  emenu = uimenu(hdcontext,'label','&Export Item...','tag','fileExport');
  elist = autoexport('options');
  elist = elist.validtypes;
  for k = 1:size(elist,1);
    uimenu(emenu,'label',elist{k,2},'callback',['browse(''datacontextmenu'',gcbo,''export'');'],'userdata',elist{k,1});
  end
  
  emenu = uimenu(hdcontext,'label','&Export Cache Model','tag','cacheExport','callback','browse(''datacontextmenu'',gcbo,''cacheexport'');','separator','on');
  
  h1 = uimenu(menuh,'label','Other Tools','callback','','separator','on');
  list = browse_shortcuts([],struct('show',''));  %get all shortcut items
  for j=1:length(list);
    if ~strcmp(list(j).drop,'off') && ((~iscell(list(j).fn) && ~ismember(list(j).fn,{'analysis'})) || (iscell(list(j).fn) && ~ismember(list(j).fn{1},{'analysis'})));
      uimenu(h1,'label',list(j).name,'callback','browse(''analyze'',gcbo)','userdata',list(j));
    end;
  end
  
  %Shortcut context menu.
  sccontext = findobj(fig,'tag','shortcutcontextmenu');
  if isempty(sccontext)
    sccontext = uicontextmenu;
    set(sccontext,'callback','browse(''shortcutcontextmenu'',gcbo)');
    set(sccontext,'tag','shortcutcontextmenu')
  end
  uimenu(sccontext,'tag','addfavorites','label','Add to Favorites','callback','browse(''shortcutcontextmenu'',gcbo,''add'');');
  uimenu(sccontext,'tag','removefavorites','label','Remove from Favorites','callback','browse(''shortcutcontextmenu'',gcbo,''remove'');');
  
  %Check/add addin menu items.
  evricustomize
  
  %call add-on post gui init functions
  fns = evriaddon('browse_post_gui_init');
  for j=1:length(fns)
    feval(fns{j},fig);
  end
  
  gui_init(fig)

  if strcmpi(options.grootmanager,'on')
    grootmanager('startup');
  end
  
  set(fig,...
    'handlevisibility','callback',...   %turn handle visibilty off except to callbacks
    'resizefcn','browse(''resize'',gcbf);');
  
  if exist('socketserver')
    socketserver('autostart')
  end
  
  evritip('browse');
  if nargout>0;
    out = fig;
  end

  resize(fig);
  
  if ishandle(initmsg);
    delete(initmsg);
  end
  
elseif ischar(varargin{1}) && ismember(varargin{1},{'options','io'})
%   options.iconsize    = 30;
%   options.fontsize    = 8;
%   options.fontname    = 'Helvetica';
  options.automation   = 'disabled';
  options.wsname_width = 40;%Characters.
  options.dropconcatenate = 'on';
  options.desktop      = false;
  options.nomovies     = false;
  options.defaultcacheview = 'date';
  options.grootmanager = 'off';
  options.definitions  = @optiondefs;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; out = evriio(mfilename,varargin{1},options); end
  return;
  
else
  
  if nargout==0
    feval(varargin{:});
  else
    out = feval(varargin{:});
  end
  
end

%-----------------------------------------
function gui_init(fig)
%Initialize GUI objects, add java objects, and set callbacks. In genreal,
%add figure handle to userdata of trees so it's easier to find. Add legacy
%varlist structure fields to userdata of nodes so we can use existing code.

make_panel(fig,0)

import java.awt.*
import javax.swing.*

fontsize = getdefaultfontsize;
pos = get(fig,'position');

%Add top controls in Current Directory area.
cdlbl = uicontrol(fig,'style','text','tag','current_directory_label','units',...
  'pixels','position',[200 pos(4)-26 100 22],'String','Current Folder : ',...
  'background','white','horizontalalignment','right','fontsize',fontsize);

%Use javacompnent here so everthing gets run on EDT thread after.
[comboj, comboh] = javacomponent('javax.swing.JComboBox',[1 1 1 1],fig);
comboj.setToolTipText('Enter or select a new location.');
comboj.setEditable(true);
%Use handle() when using callbacks on java object.
combo_handle = handle(comboj,'CallbackProperties');
set(combo_handle,'ActionPerformedCallback',@edit_currentdir_callback);
set(comboh,'units','pixels','position',[200 pos(4)-42 500 22],'tag','current_directory_dropdown');
set(comboh,'UserData',comboj);

%On Mac at least there's residual (grey) system color that looks crappy so get rid of it.
comboj.setBackground(Color.WHITE);

%Add buttons.
bicons = browseicons;
changecd = uicontrol(fig,'style','pushbutton','tag','change_cd','units',...
  'pixels','position',[704 pos(4)-42 30 30],'cdata',bicons.folderOpen_22,...
  'tooltip','Change the Current Folder.','callback',@changepwd);
upbtn = uicontrol(fig,'style','pushbutton','tag','up_one_dir','units',...
  'pixels','position',[738 pos(4)-42 30 30],'cdata',bicons.folderUpOne_22,...
  'tooltip','Change Current Folder up one folder.','callback',@change_currentdir_upone_callback);

pause(.1);drawnow

%Run current folder update here after pause so java components are created
%and get handles... seems to error out if done before puase (EDT gets run)
%because handle isn't correct. If this is Solo, the pwd is managed by
%opentoolbox and related code.

if ismac && strcmp(pwd,'/') && exist('~/Desktop','dir')
  %Don't start off browse with current directory as root.
  cd('~/Desktop')
end

comboj.setSelectedItem(pwd)

%-------------------------------------------------
function make_panel(fig,resize_flag)
%Make or remake main panel of browse.

main_panel = getappdata(fig,'main_panel');
if ~isempty(main_panel)
  %Clear references to appdata.
  setappdata(fig,'shortcut_tree',[]);
  setappdata(fig,'workspace_tree',[]);
  delete(main_panel);
  setappdata(fig,'main_panel',[])
  pause(.3)
  drawnow;
end

handles = guihandles(fig);
bopts = browse('options');

fontsize = getdefaultfontsize;

import java.awt.*
import javax.swing.*

set(fig,'units','pixels');
pos = get(fig,'position');

%Set a custom structure for modelcache.
copts.parent_function = 'browse';%Function with tree_callback sub.
copts.showhide        = 'off';%Show the hide cache leaf.
copts.showview        = 'on';
copts.showdemo        = 'on';
copts.showsettings    = 'off';
copts.showclear       = 'off';
copts.showhelp        = 'off';
copts.demo_gui        = ''; %Show all demo data.
mycache = cachestruct('type',copts);
setappdata(fig,'treestructure',mycache);
setappdata(fig,'treestructure_options',copts);

%Set shortcut tree drag/drop.
try
  scdnd = evrijavaobjectedt(DropTargetList);%EVRI Custom drop target class.
catch
  le = lasterror;
  if ~isempty(strfind(le.message,'DropTargetList'))
    msg = 'Missing Java object (DropTargetList). Please RESTART Matlab and try again.';
    evrierrordlg(msg,'Restart Needed')
    delete(fig);
    error(msg);
  end
  rethrow(le)
end
scdnd = handle(scdnd,'CallbackProperties');
set(scdnd,'DropCallback',{@dropCallbackFcn,fig,'sctree'});
set(scdnd,'DragEnterCallback',{@dragEnterCallbackFcn,fig,'sctree'});
set(scdnd,'DragOverCallback',{@dragOverCallbackFcn,fig,'sctree'});
set(scdnd,'DragExitCallback',{@dragExitCallbackFcn,fig,'sctree'});

%Set workspace tree drag/drop.
wsdnd = evrijavaobjectedt(DropTargetList);%EVRI Custom drop target class.
wsdnd = handle(wsdnd,'CallbackProperties');
set(wsdnd,'DropCallback',{@dropCallbackFcn,fig,'wstree'});
set(wsdnd,'DragEnterCallback',{@dragEnterCallbackFcn,fig,'wstree'});
set(wsdnd,'DragOverCallback',{@dragOverCallbackFcn,fig,'wstree'});
set(wsdnd,'DragExitCallback',{@dragExitCallbackFcn,fig,'wstree'});

%Dummy node to create tree.
myroot = uitreenode_overload('','Topics (double click to open)','',false);

%Create the shortcut tree.
[sctree_java, sctree,scPane] = uitree_overload(fig,myroot,'',1);
sctree_h = handle(sctree_java,'CallbackProperties');
set(sctree_h,'MousePressedCallback', {@mouse_pressed_shortcut_callback,fig});
sctree.setDndEnabled(true);
sctree.getTree.getCellRenderer.setBackgroundNonSelectionColor(Color.white)
sctree.getTree.setDropTarget(scdnd)

setappdata(handles.eigenworkspace,'shortcut_tree',sctree);
sctree_java.getSelectionModel.setSelectionMode(javax.swing.tree.TreeSelectionModel.CONTIGUOUS_TREE_SELECTION);
drawnow

%Update nodes to actual shortcuts.
set_shortcut_nodes(guihandles(fig))

%Dummy node to create tree.
myroot = uitreenode_overload('1','Current Workspace Variables','',false);

%Create the workspace tree.
[wstree_java, wstree,scPane] = uitree_overload(fig,myroot,'',1);
wstree_h = handle(wstree_java,'CallbackProperties');
set(wstree_h,'MousePressedCallback', {@mouse_pressed_workspace_callback,fig});
set(wstree_h,'MouseMovedCallback',{@ws_mousemotionlistener,fig})
set(wstree_h, 'MouseReleasedCallback', @generic_callback);
set(wstree_h, 'KeyPressedCallback', {@ws_keypress,fig});

wstree.getTree.setDropTarget(wsdnd)
wstree.setDndEnabled(true);
setappdata(handles.eigenworkspace,'workspace_tree',wstree);
wstree_java.getSelectionModel.setSelectionMode(javax.swing.tree.TreeSelectionModel.DISCONTIGUOUS_TREE_SELECTION);
drawnow;
set_workspace_nodes(guihandles(fig))

%Create model cache tree.
etopts = evritreefcn('options');
etopts.closebtn = 'off';
etopts.parent_function = 'browse';
etopts.parent_callback = 'tree_callback';
[mctree, mccontainer] = evritreefcn(fig,'show',bopts.defaultcacheview,etopts);
safeMethod('expandRow',mctree.getTree,0);

%For some reason the tree container seems to get rendered then abandoned on
%the figure and is visible in background. Putting it into a panel seems to
%fix the problem. I tried doing this will all of the panels but it didn't
%seem to work so workspace and shortcut trees are created differently in
%tree overload function (similar to Yair's findjobj function).
hp = uipanel(fig,'tag','modelc_cache_container_holder','units','pixels','Position',[1 1 1 1],'visible','off');
set(mccontainer, 'Parent', hp); 

%This all will allow evritreefcn.m to call tree_callback in browse.m since the
%cache structure doesn't have a callback associated with it.
setappdata(handles.eigenworkspace,'force_tree_callback','browse')
pause(.1)
%Set the containters to small so you can't see them before we move the
%trees to jpanel. There's a way to create trees without panels but I'm not
%confident in how to do it and still be HG happy.
%set([mccontainer sccontainer wscontainer],'Position',[0 0 .001 .001])
drawnow

%Make model cache panel.
mcPane = mctree.getScrollPane;
mcPanel = JPanel(BorderLayout);
mcPanel.add(mcPane, BorderLayout.CENTER);
mcPanel.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEmptyBorder, 'Model Cache'))

%Make shortcut panel.
scPane = sctree.getScrollPane;
scPanel = JPanel;
bl = javax.swing.BoxLayout(scPanel,javax.swing.BoxLayout.Y_AXIS);
scPanel.setAlignmentX(Component.LEFT_ALIGNMENT)
scPanel.setLayout(bl)
scPane.setAlignmentX(Component.LEFT_ALIGNMENT)
scPanel.add(scPane);
scPanel.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEmptyBorder, 'Analysis Tools'))

%A lot of drama for a simple edit combo box.
jLabeli = evrijavaobjectedt('javax.swing.JLabel');
ico     = evrijavaobjectedt('javax.swing.ImageIcon',evriwhich('evri_long.png'));
jLabeli.setBorder(BorderFactory.createCompoundBorder(BorderFactory.createLineBorder(Color.black),jLabeli.getBorder))
jLabeli.setMinimumSize(Dimension(1, 17));

%Don't use BorderFactory with javacomponent unless you really intend to,
%seems to hang onto space after you move the component into a new java
%parent.
[labelj,labelh] = javacomponent(jLabeli,[0 0 1 1],fig);
pause(.1);%Need a little time for javacomponent to complete.
labelj_handle = handle(labelj,'CallbackProperties');
set(labelj_handle,'MouseClickedCallback','web(''http://www.eigenvector.com'',''-browser'');');
set(labelj_handle,'ToolTipText','Open Eigenvector Home Page');
set(labelj_handle,'Background',Color.WHITE)
set(labelj_handle,'Icon',ico);
scPanel.add(Box.createVerticalStrut(2));%Add 2 pixel space between.
scPanel.add(labelj);

%Make workspace panel.
wsPane = wstree.getScrollPane;
wsPanel = JPanel(BorderLayout);
wsPanel.add(wsPane,BorderLayout.CENTER)
wsPanel.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEmptyBorder, 'Workspace'))

%Make top/bottom tree split pane.
treePane = JSplitPane(JSplitPane.VERTICAL_SPLIT);
treePane.setTopComponent(wsPanel);
treePane.setBottomComponent(mcPanel)
treePane.setOneTouchExpandable(true);
treePane.setContinuousLayout(true);
treePane.setResizeWeight(0.6);

%Make the left/right pane.
lrPane = JSplitPane(JSplitPane.HORIZONTAL_SPLIT, scPanel, treePane);
lrPane.setOneTouchExpandable(true);
lrPane.setContinuousLayout(true);
lrPane.setResizeWeight(0.3);
lrPane.setDividerLocation(.2) 

%Make global panel.
globalPanel = JPanel(BorderLayout);
globalPanel.add(lrPane, BorderLayout.CENTER);
%Use javacomponent to put on EDT.
[obj, hcontainer] = javacomponent(globalPanel, [0,0,max(100,pos(3)),max(100,pos(4)-100)], fig);
set(hcontainer,'units','pixels','tag','mainpanel','userdata',obj);

setappdata(fig,'main_panel',obj)

%Expand favorites on startup so user can have fast access.
mypref = getfield(browse_shortcuts('options'),'favorites');
if ~isempty(mypref)
  %Expand favorites so user will see resutls. 
  sctree = getappdata(fig,'shortcut_tree');
  safeMethod('expandRow',sctree.getTree,1);
end

%Set divider width to default. This is about the right width when using
%default browse window size but will look weird with smaller/larger sizes.
lrPane.setDividerLocation(.48)

if resize_flag
  resize(fig);
end

%-------------------------------------------------
function edit_currentdir_callback(obj, event)
%Change directory from combobox.

%The comboBoxChanged get's fired on an edit event (comboBoxEdited) as well
%so we only need to monitor the Chanded event.

%NOTE: If we want to have dynamic list that moves items around and employs
%checking, we need to get the entire list, reorder it, them use
%.removeAllItems and add them back in the new order. 
%TODO: Save diectory list as plspref.

if strcmp(event.getActionCommand,'comboBoxChanged')
  myidx = obj.getSelectedIndex;
  if myidx == -1
    %Edit.
    mydir = obj.getSelectedItem;
    if exist(mydir,'dir')
      cd(mydir);
      obj.insertItemAt(mydir,0)
    else
      obj.setSelectedItem(obj.getItemAt(0))
    end
  else
    %Selection.
    mydir = obj.getSelectedItem;
    if myidx~= 0 && exist(mydir,'dir')
      cd(mydir);
    end
  end
  
  %Make sure list is only 20 items long.
  mycount = obj.itemCount;
  
  if mycount>20
    obj.removeItemAt(mycount-1);
  end
end

%-------------------------------------------------
function generic_callback(obj,evnt)

%-------------------------------------------------
function change_currentdir_upone_callback(obj,evnt)
%Push up one directory button.
handles = guihandles(obj);

cd('..');

jcmbo = get(handles.current_directory_dropdown,'userdata');
jcmbo.setSelectedItem(pwd);

%-------------------------------------------------
function drop_sctree_callback(tree, targ_node, fh, varargin)
%Both trees drop here. You can only get here by dropping something on a
%node (not open space).

if targ_node.isRoot
  %Can't drop anything on root node, causes error when run
  %.setSelectionPath so return here.
  return
end

%fh = get(get(tree,'UIContainer'),'Parent');
%fh = ancestor(get(tree,'UIContainer'),'Figure');
handles = guihandles(fh);
tpane = tree.getScrollPane;
%treeh = tpane.getViewport.getComponent(0);
tree_name = char(tree.getRoot.getName);

if nargin>3
  droped_file_list = varargin{1};%List of file names including path.
else
  droped_file_list = '';
end

% %Target structure is stored in appdata of leaf when we create the tree.
% if checkmlversion('>=','7.6')
%   %!!!!!!!!!!!Need to run this on EDT or causes memory leak.
%   targ_node = javaMethodEDT('getTargetNode',value);
% else
%   targ_node = value.getTargetNode;
% end

jtree = tree.getTree;

select_path = evrijavaobjectedt('javax.swing.tree.TreePath', targ_node.getPath);

%Set current selection in tree to node being dropped on so user gets a cue
%of where drop occurred.
safeMethod('setSelectionPath',jtree,select_path);

%Short cut noded being dropped on.
targ_struct = get(targ_node,'UserData');

if isempty(targ_struct)
  return
end

%Check selection in appdata, if is empty then do nothing. Selection appdata
%is set by button down on cache or workspace tree.
myitem = getappdata(handles.eigenworkspace,'current_variable');

if ~isempty(droped_file_list)
  switch class(droped_file_list{1})
    case 'dataset'
      %Dropping variable.
      myitem.location = 'data';
    otherwise
      %Dropping a file list.
      myitem.location = 'file';
  end
else
  if isempty(myitem)
    return
  end
end

if strcmp(myitem.location,'workspace')
  %Get workspace variable.
  source = get_multiple_tree_selections(fh);
  for i=1:length(source);
    source(i).class = whatclass(source(i),handles.eigenworkspace);
  end
elseif strcmp(myitem.location,'demo')
  if isfield(targ_struct,'fn')&&iscell(targ_struct.fn)&&strcmp(targ_struct.fn{1},'analysis')
    %Special case for demo data, spoof a call as if it were from native cache
    %tree on figure.
    myfig = executeshortcut(targ_struct);
    analysis('tree_double_click',myfig,myitem.name,struct('val',['demo/' myitem.name]),[])
    return
  else
    myitem.class = whatclass(myitem,handles.eigenworkspace);
    source = myitem;
  end
elseif strcmp(myitem.location,'file')
  source.name     = droped_file_list;
  source.class    = 'file';
  source.location = 'file';
  source.value    = 'file';
elseif strcmp(myitem.location,'data')
  source.name     = 'data';
  source.class    = 'data';
  source.location = 'data';
  source.value    = droped_file_list{1};
  if length(droped_file_list)>1
    %Only try to load at most 2 items.
    source(2).name     = 'data';
    source(2).class    = 'data';
    source(2).location = 'data';
    source(2).value    = droped_file_list{2};
  end
else
  %Get cache item.
  source = myitem;
end

if strcmpi(tree_name(1:7),'current')
  %We're on the workspace tree.
  targ_struct.value = getvar(fh,targ_struct);
  if ~isfield(source,'value') | isempty(source.value)
    for i = 1:length(source)
      %Get value (from cache or ws) if needed.
      source(i).value = getvar(fh,source(i));
    end
  end
  %Workspace tree.
  browsefns(targ_struct,source);
else
  %Shortcut tree.
  switch targ_struct.drop
    case 'off'
      erdlgpls({'Dragging to this shortcut is not supported'},'Drag Canceled')
    case 'manual'
      erdlgpls({'Dragging to this shortcut is not currently supported',' ','Please load item manually'},'Drag Canceled')
      executeshortcut(targ_struct);
    case {'figure','on'}
      droponfig(executeshortcut(targ_struct),gcbf,source);
    case 'input'
      if length(source)>1
        %put dso inputs FIRST then models, then others
        dsos   = ismember({source.class},'dataset');
        models = ismember({source.class},'model');
        source = source([find(dsos) find(models) find(~dsos&~models)]);
      end
      [vars{1:length(source)}] = getvar(fh,source);  %get all items
      executeshortcut(targ_struct,vars{:});  %call shortcut
  end
end
%-------------------------------------------------
function mouse_pressed_shortcut_callback(tree, value,varargin)
%Mouse pressed on Shortcut Tree.

fh = varargin{1};
handles = guihandles(fh);

%Use swing utiltites to detect right/left click because modifiers can
%differ across hardware. E.g, Mac laptop right-click doesn't work with
%modifiers.
import javax.swing.*

%Grab sc tree.
sctree = getappdata(handles.eigenworkspace,'shortcut_tree');
jtree =sctree.getTree;

%Determine if user clicked on a leaf or in empty space.
myrow = jtree.getRowForLocation(value.getX,value.getY);
scnode = [];

if myrow>0 %Node 0 is label.
  myvar = '';
  %Look at click.
  if javax.swing.SwingUtilities.isLeftMouseButton(value) && value.getClickCount == 2
    %Double click, open GUI method if appropriate.
    scnode = jtree.getLastSelectedPathComponent;
    if isempty(scnode)
      %No node selected.
      return
    end
    myvar = get(scnode,'UserData');
    
    if ~isempty(myvar)
      doubleclick(fh,myvar)
    end
  elseif javax.swing.SwingUtilities.isRightMouseButton(value) && value.getClickCount == 1
    %Right click, set focus and display context menu.
    
    %Select row because it may not be current selection.
    safeMethod('setSelectionRow',jtree,myrow);
    
    scnode = jtree.getLastSelectedPathComponent;
    if isempty(scnode)
      %No node selected.
      return
    end
    
    myvar = get(scnode,'UserData');
    if isempty(myvar)
      %Note an actual short cut.
      return
    end
    
    cm = findobj(fh,'tag','shortcutcontextmenu');
    set([allchild(handles.shortcutcontextmenu)],'Enable','off');
    set(cm,'position',get_tree_contextmenu_pos(fh,value));
    if strcmp(myvar.type,'favorites')
      %Enable remove.
      set(handles.removefavorites,'Enable','on')
    else
      %Enable add.
      set(handles.addfavorites,'Enable','on')
    end
    set(cm,'visible','on');
  end
  %Save current shortcut info.
  setappdata(fh,'current_shortcut',myvar)
end
%-------------------------------------------------
function mouse_pressed_workspace_callback(tree, value,varargin)
%Mouse pressed on Workspace Tree.

%NOTE: Use one appdata field that contains structure of var with needed
%fields: name, class, location.

fh = varargin{1};
handles = guihandles(fh);

%Use swing utiltites to detect right/left click because modifiers can
%differ across hardware. E.g, Mac laptop right-click doesn't work with
%modifiers.
import javax.swing.*

%Grab workspace tree.
wstree = getappdata(handles.eigenworkspace,'workspace_tree');
jtree =wstree.getTree;
cm = [];%Context menu.

%Determine if user clicked on a leaf or in empty space.
myrow = jtree.getRowForLocation(value.getX,value.getY);

if myrow <2 && javax.swing.SwingUtilities.isRightMouseButton(value)
  %Just show new data context menu for right click on none-node or non-var (row 0 or row 1).
  cm = findobj(fh,'tag','wscontextmenu');
  set(allchild(cm),'enable','on')
  set(cm,'position',get_tree_contextmenu_pos(fh,value));
  set(cm,'visible','on');
  return
end

%Get list of multiple rows.
myrows = jtree.getSelectionRows;
myrows(myrows==1)=[];%Remove first row since it's the label row.
setappdata(handles.eigenworkspace,'current_ws_rows',[]);%Clear selected rows.

if javax.swing.SwingUtilities.isLeftMouseButton(value) && value.getClickCount == 2%Use swing utiltites because modifiers aren't perfect.
  %Double click.
  myind = get(jtree.getLastSelectedPathComponent,'UserData');
  if ~isempty(myind)
    doubleclick(fh,myind)
  end
  return
elseif javax.swing.SwingUtilities.isRightMouseButton(value)%Use swing utiltites because modifiers aren't perfect.
  cm = findobj(fh,'tag','datacontextmenu');
  if ismac & (java.awt.event.InputEvent.BUTTON1_MASK+java.awt.event.InputEvent.META_MASK)==value.getModifiers
    %Mac is confusing with command-(left click) and right click being the
    %same. So check for command left click here and assume user is
    %multi-selecting. If command-control-left click then user wants context
    %menu.
    cm = [];
  elseif isempty(myrows) | length(myrows)==1
    %Only reset focus on right click location if one node is selected. If
    %more than one then assume they know what they're doing.
    safeMethod('setSelectionRow',jtree,myrow);
  end
  
end

%Any click in workspace area will update current variable if possible.
check_selection(handles);%Make sure there's a selection in the other trees.

%Get node.
wsnode = jtree.getLastSelectedPathComponent;
if isempty(wsnode)
  %No node selected.
  setappdata(handles.eigenworkspace,'current_variable','');%Clear cur var.
  return
end

%Set current var to workspace, this info is generated and stored in
%set_workspace_nodes function.
setappdata(handles.eigenworkspace,'current_variable',get(wsnode,'userdata'));

%Hard to get dragged row in some situations so save it here.
setappdata(handles.eigenworkspace,'current_ws_rows',myrows);

%Show context menu if needed.
if ~isempty(cm)
  set(cm,'position',get_tree_contextmenu_pos(fh,value));
  datacontextmenu(cm,[])
  set(cm,'visible','on');
end

%-------------------------------------------------
function tree_double_click(fig,tree_type,tree, leaf)
%Respond to double click on tree.

switch tree_type
  case 'cache'
   myvar = getappdata(fig,'current_variable');
   if ~isempty(myvar) && strcmpi(myvar.location,'demo')
     
     %myname = strrep(myval,'demo/','');
     [demo_data, demo_loadas, demo_idx, demo_varnames] = getdemodata(myvar.name);
     demo_data = demo_data(logical(demo_idx));
     demo_varnames = demo_varnames(logical(demo_idx));
     for i = 1:length(demo_data)
       assignin('base',safename(demo_varnames{i}),demo_data{i})
     end
     %Load demo into workspace.
     %evalin('base', ['load(''' myvar.name ''')'])
   end
   
end
set_workspace_nodes(guihandles(fig))

%-------------------------------------------------
function loadcacheitem(fig,eventdata,handles, varargin)
%Respond to double click on cache tree "item" and load it into workspace.

myvar = getappdata(fig,'current_variable');
mydata = getvar(fig,myvar);

if isempty(mydata) && isempty(myvar)
  %User dropped or doubleclicked a node that isn't loadable so just return.
  return
end

%Use Dataset name when loading cache item. Append "_#" for multiple copies.
if isdataset(mydata) && ~isempty(mydata.name)
  evrivarname(safename(mydata.name),'base',mydata);
else
  evrivarname(safename(myvar.name),'base',mydata);
end

set_workspace_nodes(handles)
  
%--------------------------------------------------------------------
function mypos = get_tree_contextmenu_pos(fh,ev)
%Get position for context menu on tree given fh figure handle and ev clicke
%event.

mypos = getmouseposition(fh);

%--------------------------------------------------------------------
function cache_tree_right_click(tree,value,jleaf,fh)
%Put context menu on model cache. This is called from evritreefcn.

handles = guihandles(fh);

%Add current var if needed.
myStr = char(jleaf.getName);
if length(myStr)>5 && strcmp(myStr(1:5),'item:')
  %Construct var and save it.
  myname     = fliplr(strtok(fliplr(jleaf.getValue),'/'));
  myloc = strfind(myname,'|');
  if ~isempty(myloc)
    %Account for new naming of structures.
    myname = myname(myloc+1:end);
  end
  myvar.name = myname;
  myvar.location = 'modelcache';
  myvar.class    = get(jleaf,'UserData');
  if strcmp(myvar.class,'data')
    myvar.class = 'dataset';
  end
  setappdata(fh,'current_variable',myvar);
else
  %Clear so we don't inject unusual behavior.
  setappdata(fh,'current_variable','');
end

%Focus already set in evritreefcn so right-clicked row is current.
cm = findobj(fh,'tag','datacontextmenu');

%Show context menu if needed.
if ~isempty(cm)
  set(cm,'position',get_tree_contextmenu_pos(fh,value));
  datacontextmenu(cm,'cache_tree')
  set(cm,'visible','on');
end

%--------------------------------------------------------------------
function check_selection(handles)
%Make sure there's a selection in both workspace and shortcut tree before
%dropping anything otherwise a nasty error occurs.

mytrees = {'shortcut_tree' 'workspace_tree'};

for tt = mytrees
  mytree = getappdata(handles.eigenworkspace,tt{:});
  mytree = mytree.getTree;
  mynode   = mytree.getLastSelectedPathComponent;
  if isempty(mynode)
    %Set selection to first node.
    safeMethod('setSelectionRow',mytree,0);
  end
end

%--------------------------------------------------------------------
function tree_callback(fh,keyword,mystruct,jleaf)
%Left click on tree callback switch yard.

handles = guihandles(fh);
check_selection(handles);

if ~isempty(jleaf)
  myname = char(jleaf.getName);
else
  myname = '';
end

if isempty(mystruct)
  %Allow for empty mystruct input so can call tree_callback with just
  %'view' keywords and everything else empty.
  mystruct.val = '';
end
  
%If leaf is an item or demo then set current variable.
if length(myname)>5 && strcmp(myname(1:5),'item:') 
  myname     = mystruct.nam;
  myloc = strfind(myname,'|');
  if ~isempty(myloc)
    %Account for new naming of structures.
    myname = myname(myloc+1:end);
  end
  myvar.name = myname;
  myvar.class = get(jleaf,'userdata');
  myvar.location = 'modelcache';
  setappdata(handles.eigenworkspace,'current_variable',myvar)
elseif length(mystruct.val)>5 && strcmp(mystruct.val(1:5),'demo/')
  myvar.name = mystruct.nam;
  myvar.class = 'dataset';
  myvar.location = 'demo';
  setappdata(handles.eigenworkspace,'current_variable',myvar)
else
  setappdata(handles.eigenworkspace,'current_variable','')
end

setview = '';%Should we save cache view.
switch keyword
  case {'viewbylineage' 'lineage'}
    setview = 'lineage';
  case {'viewbydate' 'date'}
    setview = 'date';
  case {'viewbytype' 'type'}
    setview = 'type';
  case 'importtocache'
    modelcache('importobj');
end

if ~isempty(setview)
  setappdata(handles.eigenworkspace,'cachetreetype',setview)
  evritreefcn(handles.eigenworkspace,'update');
  %Save cache view as default.
  newopts = browse('options');
  newopts.defaultcacheview = setview;
  setplspref('browse',newopts);
end

%--------------------------
function set_shortcut_nodes(handles)
%Create and or update the shortcuts nodes. This list is static and not too
%large so don't need to use lazy tree expansion (with expand leaf
%function), just create entire node structure. Tree must be saved in
%appdata, it really hard to look up otherwise.

sctree = getappdata(handles.eigenworkspace,'shortcut_tree');
jtree = sctree.getTree;
%Save old state of expanded paths.
myoldpaths = jtree.getExpandedDescendants(jtree.getPathForRow(0));

if checkmlversion('>=','7.6')
  myroot = javaMethodEDT('getRoot',sctree);
else
  myroot = sctree.getRoot;
end

%Remove all children, we'll rebuild everything accept the root node.
myroot.removeAllChildren

varlist = browse_shortcuts([]);

%Method types.
opts = browse_shortcuts('options');
types = opts.typeicons;
mytypes = types(1,:);
myicons = types(2,:);
ctypes = {varlist.type};
ctypes = ctypes(~cellfun('isempty',ctypes));

%Check for favorites.
if ismember('favorites',ctypes)
  mytypes = [{'favorites'} mytypes];
  myicons = [{'favorites_16'} myicons];
end

checktypes = unique(ctypes);
checktypes = checktypes(~ismember(checktypes,mytypes));
mytypes = [mytypes checktypes];
myicons = [myicons repmat('groups_16',1,length(checktypes))];
bicons = browseicons;

for i = 1:length(mytypes)
  %Sort leafs.
  idx = ismember(ctypes,mytypes{i});
  idx = find(idx);
  
  if any(idx)
    thistype = uitreenode_overload(mytypes{i},upper(mytypes{i}),myicons{i},false);
    if ~strcmpi(mytypes{i},'eigenguide online videos');
      %standard categories
      [junk,neworder] = sort({varlist(idx).name});
      idx = idx(neworder);  %sort
      for j = 1:length(idx)
        scnode = uitreenode_overload([mytypes{i} '/' strrep(varlist(idx(j)).name,' ','_')],varlist(idx(j)).name,'bluearrow_16',true);
        set(scnode,'UserData',varlist(idx(j)));
        thistype.add(scnode);
      end
      myroot.add(thistype)
      
    else  %online videos
      catname = '';
      catnode = thistype;
      for j = 1:length(idx)
        switch varlist(idx(j)).class
          case 'category'
            catname = strrep(varlist(idx(j)).name,' ','_');
            catnode = uitreenode_overload([mytypes{i} '/' catname],varlist(idx(j)).name,'book_16',false);
            thistype.add(catnode);
          otherwise
            scnode = uitreenode_overload([mytypes{i} '/' catname '/' strrep(varlist(idx(j)).name,' ','_')],varlist(idx(j)).name,'bluearrow_16',true);
            set(scnode,'UserData',varlist(idx(j)));
            catnode.add(scnode);
        end
      end
      myroot.add(thistype)

    end
  end
end

safeMethod('setRoot',sctree,myroot)
pause(.1);
%Need to show first level.
safeMethod('expandRow',sctree.getTree,0);

%Try to expand to last tree path. Use try/catch in case path no longer
%exists.
if ~isempty(myoldpaths)
  while myoldpaths.hasMoreElements
    try
      tp = myoldpaths.nextElement;
      currentPath = jtree.getNextMatch(tp.getLastPathComponent.toString,0,[]);
      if ~isempty(currentPath)
        sctree.getTree.expandPath(currentPath);
      end
    end
  end
end

%--------------------------
function set_workspace_nodes(handles)
%Update the workspace tree.

wstree = getappdata(handles.eigenworkspace,'workspace_tree');
if isempty(wstree)
  %Can get an update call before tree is created.
  return
end

opts = browse('options');
if checkmlversion('>=','7.6')
  myroot = javaMethodEDT('getRoot',wstree);
else
  myroot = wstree.getRoot;
end

varlist = evalin('base','whos');

if ~isempty(varlist)
  longname = size(char({varlist.name}),2);
else
  longname = 0;
end
namewidth = min(opts.wsname_width,longname);%lesser of the longest name or wsname_width
namewidth = max(5,namewidth);%Guarantee 5 chars.
valuewidth = 25;
byteswidth = 10;

%HTML Tags
h1 = '<html><pre>';
h2 = '</pre></html>';

%Remove all children, we'll rebuild everything accept the root node.
myroot.removeAllChildren
%Make a table of the workspace.
header = ['Name' repmat(' ',1,namewidth-4) ' Value' repmat(' ',1,valuewidth-6) '  Bytes' repmat(' ',1,byteswidth-5)];
myroot.add(uitreenode_overload('myheader_wstree',[h1 header h2],'blank_16',true));

for i = 1:size(varlist,1)
  varlist(i).location = 'workspace';

  %Reset HTML formatting.
  h1 = '<html><pre>';
  h2 = '</pre></html>';
  %name
  myname = varlist(i).name;
  if length(myname)>namewidth
    myname = [myname(1:namewidth-3) '...'];
  end
  
  %Get class.
  myclass = varlist(i).class;
  if regexp(myclass,'[u]?int*')==1
    %Assume u/int 6-64.
    myclass = 'numeric';
  end
  
  %size
  mysize = '';
  mysize = sprintf('%ix',varlist(i).size);
  mysize = mysize(1:end-1);
  
  %class
  switch myclass
    case 'dataset'
      h1 = '<html><pre><b>';
      h2 = '</b></pre></html>';
      myicon = evriwhich('data.gif');
    case {'double' 'float' 'single' 'numeric'}
      myicon = 'array3by3_16';
    case {'struct' 'evrimodel'}
      myvar = varlist(i);
      myvar.location = 'workspace';
      [cls,mytype] = whatclass(myvar,handles.eigenworkspace);
      switch cls
        case {'model' 'prediction' 'preprocessing'}
          h1 = '<html><pre><b>';
          h2 = '</b></pre></html>';
          if strcmp(cls,'preprocessing')
            myicon = 'preprocessing_16';
          else
            %Size is always the same for model or pred so replace with
            %type.
            mytype = strrep(mytype,'_PRED','');
            mysize = mytype;
            myicon = evriwhich([cls '.gif']);
          end
          myclass = cls;
        otherwise
          myicon = 'hierarchyRight_16';
      end
    case 'char'
      myicon = 'char3_16';
    case 'cell'
      myicon = 'cell2_16';
    otherwise
      myicon = 'cube_16';
  end
  
  %value w/ size
  myval = ['<' mysize ' ' myclass '>'];
  
  if length(myval)>valuewidth
    myval = [myval(1:valuewidth-3) '...'];
  end

  sizestr = sprintf('%G',varlist(i).bytes);
  
  myval_html = strrep(myval,'<','&#60;');
  myval_html = strrep(myval_html,'>','&#62;');
  
  myline = [myname repmat(' ',1,namewidth-length(myname)) ' ' myval_html repmat(' ',1,valuewidth-length(myval)) ' ' sizestr repmat(' ',1,byteswidth-length(sizestr))];
  myline = ['<meta charset="UTF-8">' myline];
  
  
  thisnode = uitreenode_overload(varlist(i).name,[h1 myline h2],myicon,true);
  
  %Add some info so it's easier to figure out later.
  set(thisnode,'UserData', struct('name',varlist(i).name,'class',myclass,'location','workspace','size',varlist(i).size));
  myroot.add(thisnode);
end

safeMethod('setRoot',wstree,myroot);

%Save whos list so we can check for updates.
setappdata(handles.eigenworkspace,'workspace',varlist);
setappdata(handles.eigenworkspace, 'current_variable',[]); % clear current variable.

%Need to show first level.
pause(.1);%Need pause for older versions of Matlab to create object.
safeMethod('expandRow',wstree.getTree,0);

%---------------------------
function safeMethod(method,obj,myval)
%Safe method call with no outputs.

if checkmlversion('>=','7.6')
  javaMethodEDT(method,obj,myval);
else
  %Use direct call, in most cases this should go out on EDT I think.
  switch method
    case 'expandRow'
      obj.expandRow(myval);
    case 'setSelectionRow'
      obj.setSelectionRow(myval);
    case 'setSelectionPath'
      obj.setSelectionPath(myval);
    case 'setRoot'
      obj.setRoot(myval);
  end
end


%---------------------------
function root = uitreenode_overload(val,desc,iconloc,isleaf)
%Overload for uitreenode.
%UITREENODE('v0', Value, Description, Icon, Leaf)

myicons = browseicons;
myicon = [];
if ismember(iconloc,fieldnames(myicons))
  myicon = myicons.(iconloc);
  iconloc = '';
end

if checkmlversion('>=','7.6')
  %Have to use the 'v0' switch in 2008b plus.
  root = uitreenode('v0',val, desc, iconloc, isleaf);
else
  root = uitreenode(val, desc, iconloc, isleaf);
end

if ~isempty(myicon)
  myicon = im2java(myicon);
  root.setIcon(myicon);
end
%---------------------------
function [tree_java, tree_raw, tree_scroll] = uitree_overload(fh,root,myExpfcn,ttype)

if nargin<4
  ttype = 0;
end
  
if ttype
  %Use this new type of tree creation to solve problem of tree container
  %rendering then being abandoned when tree is put into splitpane (sort of
  %shadow affect behind splitpane). Had to use a panel for modelcache since
  %I didn't want to change how its container was used.
  tree_raw = com.mathworks.hg.peer.UITreePeer;
  tree_rawh = handle(tree_raw,'callbackproperties');
  set(tree_rawh,'NodeExpandedCallback',myExpfcn);
  tree_rawh.setRoot(root);
  tree_scroll = tree_rawh.getScrollPane;
  tree_java = tree_scroll.getViewport.getComponent(0);
else
  if checkmlversion('>=','7.6')
    [tree_java, tree_raw] = uitree('v0',fh,'Root', root,'parent', fh,'ExpandFcn',myExpfcn);
  else
    [tree_java, tree_raw] = uitree(fh,'Root', root,'parent', fh,'ExpandFcn',myExpfcn);
  end
end

% if checkmlversion('>=','7.6')
%   [t, tcontainer] = uitree('v0',fh,'Root', root,'parent', fh,'ExpandFcn',myExpfcn);
% else
%   [t, tcontainer] = uitree(fh,'Root', root,'parent', fh,'ExpandFcn',myExpfcn);
% end
% %-----------------------------------------
%update browse figure IF it already exists
function reactivate

h = findobj(allchild(0),'tag','eigenworkspace');
if ~isempty(h);
  browse;
  figure(h);
end

%-----------------------------------------
function resize(fig,varargin)
%Resize callback.

handles = guihandles(fig);

opts = browse('options');
set(fig,'units','pixels');
figpos = get(fig,'Position');

%Logo button.
%set(handles.gowebsite,'position',[4 4 300 20]);
%set(handles.evrilabel,'position',[4 4 figpos(3)-8 16]);
%Current directory label.
set(handles.current_directory_label,'position',[4 figpos(4)-24 100 20]);

%Set combo width.
cmwidth = max(400,figpos(3)-166);
cmbottom = figpos(4)-24;

%Current directory combo.
if isfield(handles,'current_directory_dropdown') && ishandle(handles.current_directory_dropdown)
  %Occationaly resize gets called before java component is rendered.
  set(handles.current_directory_dropdown,'position',[104 cmbottom cmwidth 22]);
end
%Change directory button.
set(handles.change_cd,'position',[cmwidth+108 cmbottom 24 24])
%Up one directory button.
set(handles.up_one_dir,'position',[cmwidth+136 cmbottom 24 24])

set(handles.mainpanel,'position',[2 2 max(100,figpos(3)-4) max(100,figpos(4)-28)])

set_workspace_nodes(handles)

%------------------------------------------------
function ws_keypress(obj,ev,varargin)

fh = varargin{1};
handles = guidata(fh);

switch ev.getKeyCode
  case 113   %F2
    contextmenu_command(fh,'rename')
    
  case {127 8}
    delans = evriquestdlg('This will permanently delete item from the workspace. Are you certain you want to do this?','WARNING: Delete','Yes','Cancel','Yes');
    if strcmp(delans,'Yes'); 
      %Delete or Backspace
      contextmenu_command(fh,'Delete');
    end
  case 10
    %Enter = double-click
    wstree = getappdata(handles.eigenworkspace,'workspace_tree');
    jtree =wstree.getTree;
    myind = get(jtree.getLastSelectedPathComponent,'UserData');
    if ~isempty(myind)
      doubleclick(fh,myind)
    end
end

%------------------------------------------------
function ws_mousemotionlistener(obj,ev,varargin)
%Workspace motion listener for updating current ws variables. Input 'obj'
%will be workspace tree. Figure is varargin{1};

%disp(['window motion   ' datestr(now)])

%Was using a puase(.05) but that cuased recursion errors so use date diff
%in appdata to be more robust.
persistent mypause

if isempty(mypause)
  %Sometimes mouse listener calls get stacked up (on Mac at least) so try
  %to speed things up using persisent var.
  mypause = datenum(0,0,0,0,0,.05); %.05 seconds
end
fh = varargin{1};

if ishandle(fh)
  lastcheck = getappdata(fh,'workspace_update_time');
  if isempty(lastcheck) | (now-lastcheck)>mypause
    %get(obj,'userdata');
    update(fh);
    setappdata(fh,'workspace_update_time',now)
    %disp(['update   ' datestr(now)])
  end
end

%------------------------------------------------
function update(fig)
%Update workspace.

%Can take time to update so make it non-fatal if error occurs. This can
%happen if user closes while update is happening (e.g., mouse-over after
%closing window).
try
  if getappdata(fig,'license_reset')
    return
  end
  handles = guihandles(fig);
  %Update cur dir if needed.
  jobj = get(handles.current_directory_dropdown,'UserData');
  %jobj = jobj.UserData;
  curdir = jobj.getSelectedItem;
  if ~strcmp(curdir,pwd)
    jobj.setSelectedItem(pwd);
  end
  
  figvars = getappdata(fig,'workspace');
  currentvars = evalin('base','whos');
  b1 = [];
  if ~isempty(figvars)
    b1 = [figvars.bytes];
  end
  b2 = [currentvars.bytes];
  
  if length(b1)==length(b2)
    %Check bytes first because it's faster
    if all(b1==b2)
      if (isempty(b1)&&isempty(b2)) || all(all(char({figvars.name})==char({currentvars.name})))
        %Probably no changes.
        return
      end
    end
  end
  
  %Something has changed so udpate workspace nodes.
  set_workspace_nodes(handles);
catch
  
end

%------------------------------------------------
function refresh(fig)
%Refresh all trees.
handles = guihandles(fig);


%Update cur dir if needed.
jobj = get(handles.current_directory_dropdown,'UserData');
%jobj = jobj.UserData;
jobj.setSelectedItem(pwd);

%Remove and add back the tree components to fix any problems 

%Cache tree.
 make_panel(fig,1)

%------------------------------------------------------
function [cls, type] = whatclass(info,fig)
%Get class of 'info' and 'type' if available.

type = [];
switch info.class
  case {'struct' 'evrimodel'}
    if isfield(info,'value') & ~isempty(info.value)
      temp = value;
    else
      temp = getvar(fig,info);
    end
    if ismodel(temp)
      type = temp.modeltype;
      if ~isempty(findstr(lower(temp.modeltype),'_pred'))
        cls = 'prediction';
      else
        cls = 'model';
      end
    elseif all(ismember({'apply','calibrate','description'},fieldnames(temp)))
      type = temp.keyword;
      cls = 'preprocessing';
    else
      cls = 'struct';
    end
  otherwise
    cls = info.class;
end

%------------------------------------------------
function shortcutcontextmenu(obj,cmd)
%Shortcut tree callback.

fig = ancestor(obj,'figure');

myvar = getappdata(fig,'current_shortcut');
if isempty(myvar)
  %Not a shortcut node.
  return
end

mypref = getfield(browse_shortcuts('options'),'favorites');

if strcmp(cmd,'add')
  if ~ismember(myvar.name,mypref)
    mypref = [{myvar.name} mypref];
  end
else%remove
  myidx = ismember(mypref,myvar.name);
  if any(myidx)
    mypref(myidx) = [];
  end
end

setplspref('browse_shortcuts','favorites',mypref);
set_shortcut_nodes(guihandles(fig));

if ~isempty(mypref)
  %Expand favorites so user will see resutls. 
  sctree = getappdata(fig,'shortcut_tree');
  safeMethod('expandRow',sctree.getTree,1);
end


%------------------------------------------------
function datacontextmenu(obj,cmd)
%Menu callback for context menu and or file menu items.

fig = ancestor(obj,'figure');

switch get(obj,'type')
  case 'uicontextmenu'
    hand = get(obj,'children');
    handlbl = get(hand,'label');

    myvar = get_current_variable(fig);
    if isempty(myvar)
      return
    end
    set(hand,'enable','off'); %disable all first

    if ~isempty(myvar)&&length(myvar)>1
      if all(ismember({myvar.class},{'double','dataset'}));
        set(hand(ismember(handlbl,{'Combine'})),'enable','on')
      end
    end
    
    switch myvar(1).class
      case 'dataset'
        enable = {'Plot' 'View' 'Rename' 'Edit' 'Copy' 'Duplicate' 'Save' 'Delete' 'Delete All Others' 'Analyze'};
      case 'model'
        enable = {'View' 'Rename' 'Edit' 'Copy' 'Duplicate' 'Compare' 'Save' 'Delete' 'Delete All Others' '&Export Cache Model'};
      case {'cell' 'char'}
        enable = {'View' 'Rename' 'Duplicate' 'Delete' 'Delete All Others'};
      case {'double'}
        enable = {'Plot' 'View' 'Rename' 'Edit' 'Duplicate' 'Save' 'Delete' 'Delete All Others' 'Analyze'};
      otherwise
        enable = {'Edit' 'Rename' 'View' 'Duplicate' 'Delete' 'Delete All Others' 'Analyze'};
    end
    enable{end+1} =  '&Export Item...';  %always
    if strcmpi(myvar(1).location,'modelcache')
      %disable certain features if in cache
      enable = setdiff(enable,{'Rename' 'Duplicate' 'Delete' 'Delete All Others'});
    end
    set(hand(ismember(handlbl,enable)),'enable','on')
    
  case 'uimenu'
    % actually perform various menu actions
    if nargin<2 || isempty(cmd)
      cmd = strrep(get(obj,'label'),'&','');
    end
    contextmenu_command(fig,cmd);
    set_workspace_nodes(guihandles(fig));
end
%------------------------------------------------
function myvar = get_current_variable(fig)

myvar = getappdata(fig,'current_variable');
% if isempty(myvar) | isempty(myvar.class)
%   return
% end

if ~isempty(myvar) && strcmp(myvar.location,'workspace')
  %Check for multiple nodes.
  myvar = get_multiple_tree_selections(fig);
end


%------------------------------------------------
function contextmenu_command(fig,cmd)
%Run command from context menu.

myvar = get_current_variable(fig);
switch lower(cmd)
  case {'rename'}
    newname = '';
    while isempty(newname)
      newname = inputdlg('New Item Name:','Rename',1,{myvar(1).name});
      if isempty(newname)
        return
      end
      newname = newname{1};
      newname(~ismember(newname,['A':'Z' 'a':'z' '0':'9' '_'])) = []; %drop bad characters
      if newname(1)<='9'
        erdlgpls('Name cannot start with a number.','Illegal Name');
        newname = '';
      end
    end
    if evalin('base',['exist(''' newname ''',''var'')']);
      ok = evriquestdlg(['Item ''' newname ''' already exists. OK to overwrite?'],'Item Exists','Overwrite','Cancel','Overwrite');
      if strcmp(ok,'Cancel') | isempty(ok)
        return
      end
    end
    try
      % edge case - chose to overwrite original variable with the same name
      % nothing to do so don't enter!
      if ~strcmp(newname, myvar(1).name)
        evalin('base', [newname ' = ' myvar(1).name ';']);
        evalin('base', ['clear(''' myvar(1).name ''');']);
      end
    catch
      erdlgpls({'Could not rename item: ',lasterr},'Rename Error');
    end
    
  case {'save','save item...'}
    %Save first variable if more than one exists.
    if length(myvar)>1
      [FileName,PathName] = uiputfile({'*.mat';'*.*'},'Save as');
      if isnumeric(FileName)
        %User cancel.
        return
      end
      tosave = [];
      for idx = 1:length(myvar);
        tosave.(myvar(idx).name) = getvar(fig,myvar(idx));
        %tosave{idx} = getvar(fig,myvar(idx));
      end
      save(fullfile(PathName,FileName),'-struct','tosave')
    else
      svdlgpls(getvar(fig,myvar(1)),'Save as...',myvar(1).name,'file');
    end
  case {'delete' 'delete item'}
    if isempty(myvar);
      return;
    end
    idx = ismember({myvar.location},'workspace');
    evalin('base',['clear' sprintf(' %s',myvar(idx).name)]);
    pause(.5)
    update(fig)
  case {'keep' 'keep item'}
    ok = evriquestdlg(['Delete all items other than the one selected?'],'Delete All Others','Delete','Cancel','Delete');
    if strcmp(ok,'Cancel') | isempty(ok)
      return
    end
    idx = ismember({myvar.location},'workspace');
    evalin('base',['keep' sprintf(' %s',myvar(idx).name)]);
    pause(.5)
    update(fig)
  case {'compare'}
    for idx = 1:length(myvar);
      modeloptimizer('snapshot',getvar(fig,myvar(idx)));
    end
    mofh = modeloptimizergui;
    pause(.1)
    modeloptimizergui('update_callback',guihandles(mofh))
  case {'edit' 'open in editor'}
    for idx = 1:length(myvar);
      doubleclick(fig,myvar(idx));
      pause(.2);
    end
  case {'copy' 'duplicate'}
    for idx = 1:length(myvar);
      if strcmp(cmd,'duplicate')
        newname = getwscopyname(myvar(idx).name);
        evalin('base',[newname '=' myvar(idx).name ';']);
      else
        %Copy
        copy_clipboard(getvar(fig,myvar(idx)));
      end
    end
  case {'combine' 'combine items'}
    cls = {myvar.class};
    notvalid = ~ismember(cls,{'double','dataset'});
    if any(notvalid)
      onebad = min(find(notvalid));
      erdlgpls(sprintf('Could not operate on "%s" - invalid type ("%s") ',myvar(onebad).name,cls{onebad}),'Combine Failed');
      return
    end
    
    %open first item in dataset editor, then concat others
    h = editds(getvar(fig,myvar(1)));
    editds('setvarname',h,myvar(1).name);
    for ind=2:length(myvar)
      data = getvar(fig,myvar(ind));
      if ~isdataset(data)
        data = dataset(data);
      end
      data.name = myvar(ind).name;
      editds('fileload',h,{data data.name '' 'Augment'});  %force augmentation of this new data
    end
    
  case {'plot'}
    for idx = 1:length(myvar);
      plotgui('new',getvar(fig,myvar(idx)),'plotby',0);
    end
    
  case {'view' 'view contents'}
    set(fig,'pointer','watch');    
    for idx = 1:length(myvar);
      viewobj(getvar(fig,myvar(idx)),myvar(idx).name,myvar(idx).class);
    end
    set(fig,'pointer','arrow');
    
  case 'export'
    myfmt = get(gcbo,'userdata');
    myfmt = strrep(myfmt,'*.','');
    for idx = 1:length(myvar);
      try
        autoexport(getvar(fig,myvar(idx)),myfmt);
      catch
        evrierrordlg(lasterr,'Export Error');
        break;
      end
    end
  case 'cacheexport'
    modelcache('export',myvar(1).name);
    
end

%------------------------------------------------
function myvar = get_multiple_tree_selections(obj)
%Grab "var" struct for multiple leafs on tree and put into structure. This
%only works for workspace tree currently.

fig = ancestor(obj,'figure');
if isempty(fig)
  %Can't find browse figure so return.
  return
end

myvar = getappdata(fig,'current_variable');
if isempty(myvar)
  return
end

if strcmp(myvar.location,'workspace')
  %Check for multiple nodes.
  wstree = getappdata(fig,'workspace_tree');
  jtree =wstree.getTree;
  
  %Get node.
  wsnode = jtree.getLastSelectedPathComponent;
  if isempty(wsnode)
    %Can't find node.
    return
  end
  
  %myrows = jtree.getSelectionRows;
  myrows = getappdata(fig,'current_ws_rows');
  if length(myrows)>1
    %Get multi selected.
    jtree.setSelectionRows(myrows)
    nodes = jtree.getSelectionPaths;
    for i = 1:length(nodes)
      myvar(i) = get(nodes(i).getPathComponent(1),'userdata');
    end
  end
end

%-------------------------------------------------
function filemenu

fig = gcbf;

%handle item save and delete
hand = [findobj(gcbo,'tag','fileExport') findobj(gcbo,'tag','editSave') findobj(gcbo,'tag','editDelete')];
handlbl = get(hand,'tag');
set(hand,'enable','off'); %disable all first

if exist('socketserver')
  status = socketserver('autostart','status');
  switch status
    case 'on'
      checked = 'on';
      enb     = 'on';
    case 'disabled'
      checked = 'off';
      enb     = 'off';
    otherwise   %off or undefined
      checked = 'off';
      enb     = 'on';
  end
else
  checked = 'off';
  enb     = 'off';
end
set(findobj(fig,'tag','FileAutomation'),'enable',enb,'checked',checked);

varlist = getappdata(fig,'current_variable');
if isempty(varlist)
  return
end

if length(varlist)~=1
  return
end

if ~strcmp(varlist.location,'workspace')
  return
end

switch varlist.class
  case 'dataset'
    enable = {'editSave' 'fileExport'};
  case 'model'
    enable = {'editSave' 'fileExport'};
  case 'struct'
    enable = {'editSave' 'fileExport'};
  case {'cell' 'char'}
    enable = {'fileExport'};
  otherwise
    enable = {'fileExport'};
end
set(hand(ismember(handlbl,enable)),'enable','on')

%-------------------------------------------------
function editmenu

fig = gcbf;

hand = get(gcbo,'children');
handlbl = get(hand,'tag');
set(hand,'enable','off'); %disable all first

%turn on expert prefs option
set(findobj(hand,'tag','editoptions'),'enable','on');

varlist = get_current_variable(fig);
if isempty(varlist)
  return
end

if length(varlist)>1
  if all(ismember({varlist.class},{'double','dataset'}));
    en = 'on';
  else
    en = 'off';
  end
  set(hand(ismember(handlbl,{'editCombine'})),'enable',en)
  return
end

switch varlist.class
  case 'dataset'
    enable = {'editEdit' 'editView' 'editDelete'};
  case 'model'
    enable = {'editEdit' 'editView' 'editDelete'};
  case 'struct'
    enable = {'editView' 'editEdit' 'editDelete'};
  case {'cell' 'char'}
    enable = {'editView' 'editDelete'};
  otherwise
    enable = {'editEdit' 'editView' 'editDelete'};
end
set(hand(ismember(handlbl,enable)),'enable','on')

%-------------------------------------------------
function helpmenu

h = findobj(gcbo,'userdata','help_special');
if ~isempty(h);
  if get(gcbf,'currentcharacter')==19 %CTRL-s to show testing menu.
    set(h,'visible','on');
    set(gcbf,'selectiontype','normal')
  else
    set(h,'visible','off');
  end
end

if ~strcmp(evriupdate('mode'),'disabled')
  enb = 'on';
else
  enb = 'off';
end
h = findobj(gcbo,'tag','help_checkupdates');
set(h,'visible',enb);

if getplspref('evristats','accumulate')
  ch = 'on';
else
  ch = 'off';
end
h = findobj(gcbo,'tag','help_evristats');
set(h,'checked',ch)

%-------------------------------------------------
function addinmenu(varargin)
% Show interface to enter new addin code. 

f = varargin{1};

if ishandle(f)
  mymenu = findobj(f,'tag','AddinMenu');
else
  return
end

myaddincode = inputdlg(['Additional tools and utilities can be enabled by using '...
                   'an add-in code. These codes may be provided by Eigenvector '...
                   'and other vendors. Enter the code below:'],'Ender Add-In Code');

if ~isempty(myaddincode)
  %Check the code.
  if ~evricustomize('checkacode',myaddincode)
    evrierrordlg('Add-in code not valid. Contact add-in code provider.','Add-in Code Error' )
    return
  end
  
  %Received code. Send to enable function.
  acodes = {};
  if ispref('EVRI','addincodes');
    acodes = getpref('EVRI','addincodes');
  end
  
  if ~ismember(myaddincode,acodes)
    %Add the code.
    acodes(end+1) = myaddincode;
    setpref('EVRI','addincodes',acodes);
    %Update addin menus.
    evricustomize
  end
end

%------------------------------------------------
function resetlicense(handles)
%Reset license code.

%Can't do straight call to reset because errors occure with windowbutton
%motion calling into evriio when code has been deleted.

try
  setappdata(handles.eigenworkspace,'license_reset',1)
  evriclearlicense
  
catch
  disp(lasterr)
  setappdata(handles.eigenworkspace,'license_reset',0)
end
setappdata(handles.eigenworkspace,'license_reset',0)
%-------------------------------------------------
function viewmenu
fig = gcbf;
hand = get(gcbo,'children');

%-------------------------------------------------
function analyzemenu

fig = gcbf;

hand = get(gcbo,'children');

myvar = get_current_variable(fig);

if isempty(myvar)
  enb = 'on';
else
  enb = 'on';
  for i=1:length(myvar);
    switch myvar(i).class
      case {'struct' 'cell' 'char'}
        %if any selected item is one of these, don't enable any method
        enb = 'off';
    end
  end
end
set(hand,'enable',enb);

%------------------------------------------------
function closegui
%Close GUI.
try
  positionmanager(gcbf,'browse','set')  %grab current position and store for next opening
catch
end

%close gui
delete(gcbf)

%------------------------------------------------
function analyze(mode)
%Activate analysis with selected data and given mode.

if ishandle(mode)
  %handle to context menu item - get userdata which describes mode to start
  mode = get(mode,'userdata');
end

fig = gcbf;

myvar = get_current_variable(fig);
if ~(isempty(myvar))
  %  return
  %end
  
  data = {getvar(fig,myvar(1))};
  if (length(myvar)==2)
    data{2} = getvar(fig,myvar(2));
  end
end

if ~(isstruct(mode))
  %start up analysis with the selected method activated
  obj = evrigui('analysis');
  obj.setMethod(mode);
  if ~isempty(myvar)
    %and automatically load data
    obj.drop(data{:});
  end
else
  if ~isempty(myvar)
    executeshortcut(mode,data{:});
  else
    executeshortcut(mode);
  end
end

% %---------------------------------------------------
% function drop(fig,h)
% %Drop icon on figure.
% 
% varlist = getappdata(fig,'workspace');
% if isempty(varlist);
%   %sometimes happens if we opened a new figure quickly on double-clicking
%   return
% end
% 
% dropfig = get(0,'pointerwindow');
% 
% %locate index from handle
% ind = find(cat(2,varlist.box)==h);
% 
% xdat = get(h,'xdata');
% ydat = get(h,'ydata');
% 
% %did this get dropped on something
% olap = find(overlap(xdat,ydat,varlist));
% 
% shift = [xdat(1)-varlist(ind).extent(1) ydat(1)-varlist(ind).extent(2)];
% %move box back under the original icon
% set(varlist(ind).box,'xdata',get(varlist(ind).box,'xdata')-shift(1));
% set(varlist(ind).box,'ydata',get(varlist(ind).box,'ydata')-shift(2));
% %and select it
% varlist(ind).selected = true;
% set(varlist(ind).box,'visible','off')
% 
% selected = find([varlist.selected]);
% if isempty(olap);    %move item(s)
%   for j=selected;
%     varlist(j) = moveitem(fig,varlist(j),shift);
%   end
%   setappdata(fig,'workspace',varlist);
%   
%   if fig~=dropfig;
%     droponfig(dropfig,fig,varlist(selected));
%   end
% elseif length(olap)==1 & all(selected~=olap)    %dropped on SOMETHING
%   target = varlist(olap);
%   target.value = getvar(fig,olap);
%   
%   source = varlist(selected);
%   for j = 1:length(selected);
%     source(j).value = getvar(fig,selected(j));
%   end
%   browsefns(target,source)
% end
% 
% update(fig);
% 
%---------------------------------------------------
function droponfig(dropfig,fig,selected)
%Call drop callback on one of main figure types.

if ~ishandle(dropfig);
  return
end

figtag = get(dropfig,'tag');
if isempty(figtag) %no tag? use figuretype (for PlotGUI target support)
  figtag = getappdata(dropfig,'figuretype');
end

if isempty(figtag);
  return
end

%Unused style of drop.
if iscell(selected)
  error('Can''t drop cell array. Report bug to helpdesk.')
end

switch lower(figtag)
  case 'analysis'
    if length(selected)>2;
      %Can't sort out order (x, y, cal, val) of drop for more than two data objects.
      erdlgpls('Can only drag one or two items onto an Analysis window');
      selected = selected(1:2);
    end
    data = {getvar(fig,selected(1))};
    if length(selected)==2;
      data{2} = getvar(fig,selected(2));
    end
    analysis('drop',dropfig, [], guidata(dropfig), data{:});
    checkformove(whos,selected);    
  case 'editds'
    for j=1:length(selected);
      editds('fileload',dropfig,{getvar(fig,selected(j)) selected(j).name ''});
    end
  case 'plotgui'
    dropfig = editds(plotgui('getlink',dropfig),'invisible');  %create editds which points to plotgui
    for j=1:length(selected);
      editds('fileload',dropfig,{getvar(fig,selected(j)) selected(j).name ''});
    end
    drawnow;
    close(dropfig)
    drawnow;
  case 'caltransfergui'
    if length(selected)>2;
      erdlgpls('Can only drag one or two items onto an Calibration Transfer window');
    end
    data = {getvar(fig,selected(1))};
    if length(selected)==2;
      data{2} = getvar(fig,selected(2));
    end
    caltransfergui('drop',dropfig, [], guidata(dropfig), data{:});
  case 'miagui'
    for j=1:length(selected);
      miagui('drop',dropfig,[],guidata(dropfig),getvar(fig,selected(j)));
    end
    checkformove(whos,selected);
  otherwise
    data = {};
    for j=1:length(selected);
      data{j} = getvar(fig,selected(j));
    end
    try
      feval(lower(figtag),'drop',dropfig,[],guidata(dropfig),data{:});
    catch
      erdlgpls({'Dragging to this window is not currently supported',' ','Please load item manually'},'Drag Canceled')
    end
end

%---------------------------------------------------
function  moved = checkformove(w,selected)
%Check size of data and memory and give warning about deleting
%data from base workspace to save memory

moved = false;
if isfield(w,'bytes')
  try
    m = memory;
    if isfield(m,'MemAvailableAllArrays')
      m = m.MemAvailableAllArrays;
    else
      m = inf;
    end
  catch
    m = inf;
  end
  if (sum([w.bytes])>500000 & (m<3e9)) | sum([w.bytes])>(m/4)
    %seems to be a small amount of memory relative to data
    % (if data is > 500MB and memory is <3GB OR if data is > 25% of
    % memory)
    resp = evriquestdlg('Leaving this data in the base workspace may limit your total available memory. Should it be moved out of the workspace to save memory?','Move Data?','Move Data','Leave Data in Workspace','Move Data');
    if strcmpi(resp,'Move Data')
      %delete it...
      evalin('base',['clear ' sprintf('%s ',selected.name)])
      moved = true;
    end
  end
end


%---------------------------------------------------
function doubleclick(fig,ind)

state = getappdata(fig,'opening');
set(fig,'pointer','watch')

if isempty(state) || state==0
  try
    
    setappdata(fig,'opening',1);
    
    switch ind.class
      case {'double','logical','single','uint8','int8','uint32','int32'}
        openmode = evriquestdlg('How should this item be opened: Edit as new DataSet object or as a raw data (ordinary matrix)?','Open Item','Create DataSet','As Raw Data','Cancel','Create DataSet');
      case 'dataset'
        openmode = 'dataset';
      case 'preprocessing'
        openmode = 'preprocess';
      case 'model'
        openmode = 'model';
      case 'shortcut'
        openmode = 'shortcut';
      case {'figure','controls'}
        openmode = 'figure';
      case 'char'
        openmode = 'view';
      otherwise
        openmode = 'matlab';
    end
    
    switch openmode
      case {'raw' 'As Raw Data'}
        try
          h = editds;
          setappdata(h,'asraw',1);
          data = dataset(getvar(fig,ind));
          data.name = ind.name;
          editds('fileload',h,{data data.name ''});
          %           editds('setvarname',h,ind.name);
        catch
          openvar(ind.name);
        end
      case {'dataset','Create DataSet'}
        try
          h = editds(getvar(fig,ind));
          editds('setvarname',h,ind.name);
        catch
          erdlgpls({['Unable to open ' ind.name],lasterr},'Can Not Open')
        end
      case {'matlab','Matlab Editor'}
        viewobj(getvar(fig,ind),ind.name,ind.class);
      case {'preprocess'}
        putvar(fig,preprocess(getvar(fig,ind)),ind.name);
      case 'model'
        model = getvar(fig,ind);
        
        if isa(model,'evrimodel')
          %use evrimodel method
          edit(model);
        else
          %backwards compatibility code
          methods = analysistypes;
          if ismember(lower(model.modeltype),methods(:,1));
            %one of the valid analysis methods
            dropfig = evrigui('analysis');
            dropfig.drop(model);  %drop model
          else
            %something else, try opening and dropping
            fn = lower(model.modeltype);
            dropfig = feval(fn);
            try
              feval(fn,'drop',dropfig,[], guidata(dropfig), model);
            catch
              %do nothing
            end
          end
        end
        
      case 'figure'
        targetfig = ind.fn;
        if ishandle(targetfig)
          figure(targetfig);
        end
        %     set(0,'currentfigure',ind.fn);
      case 'shortcut'
        executeshortcut(ind);
      case 'view'
        viewobj(getvar(fig,ind),ind.name,ind.class)        
    end
    
  catch
    erdlgpls('Sorry, unable to open this item...')
    lasterr
  end
end

set(fig,'pointer','arrow')
setappdata(fig,'opening',0);

%------------------------------------------------
function viewobj(item,name,cls)

h = [];
switch lower(cls)
  case {'char'}
    h = infobox(item);
  case {'model' 'evrimodel'}
    try
      h = infobox(modlrder(item));
    catch
      try
        info = char(str2cell(sprintf(encodexml(item,name,0))));
        h = infobox(info);
      catch
        erdlgpls('Unable to view this object. Try "Edit", if available.');
      end
    end
  otherwise
    opts.openmode = 'new';
    if iscell(item) & ~isempty(item) & all(cellfun('isclass',item,'char'))
      infobox(item,opts);
    else
      try
        info = char(str2cell(sprintf(encode(item),name,0)));
        h = infobox(info,opts);
      catch
        erdlgpls('Unable to view this object. Try "Edit", if available.');
      end
    end
    
end

if ~isempty(h) & ishandle(h)
  infobox(h,'font','Monospaced')
end

%------------------------------------------------
function out = executeshortcut(item,varargin)

drawnow;

fn = item.fn;
if ~iscell(fn);
  fn = {fn};
end
if nargin>1
  fn = [fn varargin];
end

try
  if isempty(item.nargout) | item.nargout==0
    if nargout==0
      feval(fn{:});
    else
      out = feval(fn{:});
    end
  else
    [z{1:item.nargout}] = feval(fn{:});
    for j=1:length(z);
      if ~isempty(z{j}) %& ~ishandle(z{j})
        %no outputs or not a figure? Offer standard save dialog
        svdlgpls(z{j});
      end
    end
  end
catch
  erdlgpls(sprintf('Unable to complete action. \n%s',lasterr),'Unable to complete action');
  out = [];
end

%----------------------------------------------------------
function out = solo(givename)
%returns true when being run as solo
% optional first input returns product name

if nargin>0
  [ver,out]=evrirelease;
  return
end

if exist('isdeployed') && isdeployed;
  out = 1;
else
  out = 0;
end

%-------------------------------------------
function changepwd(folder,ev)
%change the current working directory, folder can be string or java object.

handles = guihandles(gcf);

if nargin<1 || ~ischar(folder)
  folder = evriuigetdir(pwd,'Select new working directory');
  if ~ischar(folder)
    %User cancel.
    return
  end
end

jcmbo = get(handles.current_directory_dropdown,'userdata');
jcmbo.setSelectedItem(folder);%Goes to edit_currentdir_callback.

%TODO: Not sure what this setting is for so I'll keep it until check with Jeremy. 
setappdata(0,'lddlgpls_fromfile',[])

%-------------------------------------------
function workspace(mode)
%save or load the entire workspace

switch mode
  case 'load'
    [file,folder] = evriuigetfile({'*.mat'},'Load Workspace');
    if ischar(file)
      try
        content = load(fullfile(folder,file),'-mat');
        list = fieldnames(content);
        for f=list(:)';
          assignin('base',f{:},content.(f{:}));
        end
        update(gcbf);
      catch
        erdlgpls({'Could not load workspace',lasterr},'Load Canceled');
      end
    end
    
  case 'save'
    tryagain = true;
    while tryagain
      [file,folder] = evriuiputfile({'*.mat'},'Save Workspace');
      tryagain = false;
      if ischar(file) && any(ismember(file,'()'''));
        erdlgpls({'File names may not contain the characters: ( ) or ''','Please select a different name for the save.'},'Save Canceled');
        tryagain = true;
        drawnow;
      end
    end
    if ischar(file)
      %get variables into local structure
      list = evalin('base','who');
      content = [];
      for j=list(:)'
        content.(j{:}) = evalin('base',j{:});
      end
      try
        save(fullfile(folder,file),'-mat','-struct','content');
      catch
        erdlgpls({'Could not save workspace',lasterr},'Save Canceled');
      end
    end
  case 'clear'
    clans = evriquestdlg('Delete all items from the workspace? (Unsaved items will be lost)','Confirm Delete All','Yes','Cancel','Yes');
    if ~strcmp(clans,'Yes')
      return
    end
    try
      evalin('base',['clear']);
      update(gcbf);
    catch
      erdlgpls({'Could not clear workspace',lasterr},'Clear Canceled');
    end
  case 'update'
    %Update workspace variables.
    allch = allchild(0);
    myfigs = get(allch,'tag');
    if ~iscell(myfigs)
      myfigs = {myfigs};
    end
    fig = allch(ismember(myfigs,'eigenworkspace'));
    if ~isempty(fig)
      refresh(fig)
    end
end

%-------------------------------------------
function varargout = getvar(fig,inds)
% get variables from the "workspace" or load demo data.
%
% Inputs are:
%  fig  : figure number of browser
%  inds : index/indicies of variable to get
%  OR inds can be a variable NAME
%  OR inds can be the structure description of the item itself
varargout{1} = [];
switch class(inds)
  case 'char'
    %string passed? move it to structure
    varlist.name = inds;
    varlist.class = '';
    varlist.location = '';
  case 'struct'
    %structure passed? assume it is the workspace item
    varlist = inds;
  case 'cell'
    %Passing cell array of file locations that have been dropped.
    varlist.name     = inds;
    varlist.class    = 'file';
    varlist.location = 'file';
    varlist.value    = 'file';
    
  otherwise
    varlist = getappdata(fig,'workspace');
    varlist = varlist(inds);
end

for j = 1:length(varlist);
  if ~ismember(varlist(j).class,{'figure','controls','shortcut'});
    switch lower(varlist(j).location);
      case 'modelcache'
        try
          myname = varlist(j).name;
          myloc = strfind(myname,'|');
          if ~isempty(myloc)
            %Account for new naming of structures.
            myname = myname(myloc+1:end);
          end
          varargout{j} = modelcache('get',myname);
        catch
          evrierrordlg('Cache item cannot be loaded (may have been too big to cache).','Cache Item Not Found');
        end
      case 'demo'
        %For now only load the xblock. There are no known shortcuts that
        %take more than one input and any shortcut that uses analysis is
        %intercepted above.
        [mydemodata, loadas, idx] = getdemodata(varlist(j).name);
        xblk = ismember(loadas,'xblock');
        if any(xblk);
          %got something marked as "xblock"
          varargout = mydemodata(xblk);
        else
          %if there isn't an xblock item, take the first non-empty item
          varargout = mydemodata(min(find(~cellfun('isempty',mydemodata))));
        end
      case 'file'
        if isempty(varlist(j).value)
          varargout{j} = varlist(j).value;
        else
          varargout{j} = autoimport(varlist(j).name);
        end
      case 'data'
        varargout{j} = varlist(j).value;
      otherwise
        %If class file then load with autoimport, otherwise get from
        %workspace.
        if strcmp(varlist(j).class,'file')
          varargout{j} = autoimport(varlist(j).location);
        else
          if ~isempty(varlist(j).name)
            varargout{j} = evalin('base',varlist(j).name);
          end
        end
    end
  else
    varargout{j} = [];
  end
end

%--------------------------------------------
function putvar(fig,result,name)

if nargin>2;
  assignin('base',name,result);
else
  if isempty(result);
    return
  end
  if ~isa(result,'struct');
    for name = fieldnames(result)';
      assignin('base',name{:},getfield(result,name{:}));
    end
  end
end
update(fig);

%----------------------------------------------------------------------
function selectshortcuts

browse_shortcuts select
set_shortcut_nodes(guihandles(findobj(allchild(0),'tag','eigenworkspace')));

%----------------------------------------------------------------------
function testwindow
%hidden special window to perform status tests

answer = {''};
while ~isempty(answer)
  try
    result = evalin('base',answer{1});
  catch
    result = ' ';
    try
      evalin('base',answer{1});
    catch
      result = lasterr;
    end
  end
  if ~isempty(result)
    if ~isa(result,'char')
      result = encode(result,'ans');
    end
    infobox(str2cell(result));
  end
  answer = inputdlg('Browse Command:','Browse Command',1,answer,struct('Resize','on','WindowStyle','normal'));
end

%----------------------------------------------------------------------
function browsefns(target,sources)
%Apply source to target.

%look for dropped files and load item
filelinks = ismember({sources.class},'file');
if any(filelinks)
  if sum(filelinks)>1
    %consolidate
    filelinks = find(filelinks);
    linksources = sources(filelinks);
    filelist = cat(1,linksources.name);  %grab all names
    sources(filelinks(2:end)) = []; %drop additional entries
    linksources = linksources(1);   %and also in file links
    linksources.name = filelist;
    sources(filelinks(1)) = linksources;
    filelinks = filelinks(1);
  end
  %now only ONE
  try
    sources(filelinks).value = autoimport(sources(filelinks).name);
    if isdataset(sources(filelinks).value)
      sources(filelinks).name = sources(filelinks).value.uniqueid;
    else
      sources(filelinks).name = 'Imported Object';
    end
    sources(filelinks).class = class(sources(filelinks).value);
    sources(filelinks).class = whatclass(sources(filelinks));%,handles.eigenworkspace);
  catch
    erdlgpls({'Unable to import files.' lasterr},'File import failed');
    return
  end
end

%look for "priority" items
for type = {'shortcut' 'model' 'preprocessing' 'controls' 'figure' 'dataset'}
  if ~strcmp(target.class,type{:}) & ismember(type{:},{sources.class})
    %swap model to be target (as if target was dropped on model instead of vice-versa)
    sourceind = min(find(ismember({sources.class},type{:})));
    temp = sources(sourceind);
    sources = target;
    target = temp;
    break;  %don't bother looking for other items
  end
  if strcmp(target.class,type{:});
    %got one of these? stop now
    break;
  end
end

%check for dropping item on itself
targsource = ismember({sources.name},target.name);
if any(targsource)
  sources(targsource) = [];  %drop where target shows up in sources
  if isempty(sources)
    %dropped on itself? exit now
    return;
  end
end

fig = [];

if strcmp(target.class,'model')
  %You can never drop x and y with the code below, it will only drop
  %one at a time. Should try to drop both then try one at a time if there's a
  %failer?
  fig = gcbf;
  %Make sure drop source is data.
  
  %FIX code below, just cut and paste. Stopped here.
  dropdata = {};
  for sourceind = 1:length(sources);
    source = sources(sourceind);
    
    if ~ismember(source.class,{'dataset','double'})
      erdlgpls({'Sorry. These items can not be used together.',['Object "' source.name '" is not valid as data.']},'Unable to use items')
      return
    end
    dropdata = [dropdata {getvar(fig,source)}];
  end
  
  mymodl = getvar(fig,target);
  
  try
    %Should try to drop both then try one at a time if there's a
    %failer because one at a time can work in some situations. 
    methods = analysistypes;
    if ismember(lower(mymodl.modeltype),methods(:,1));
      %one of the valid analysis methods
      dropfig = evrigui('analysis');
      dropfig.drop(mymodl);  %drop model
      
      if ~isempty(dropdata)
        switch length(dropdata)
          case 1
            %Just drop as X.
            dropfig.setXblockVal(dropdata{1});
          case 2
            if mymodl.isyused
              %Drop as X and Y.
              dropfig.setXblockVal(dropdata{1});
              dropfig.setYblockVal(dropdata{2});
            else
              %Cat and drop.
              catdropdata = augment(-1,dropdata{1},dropdata{2});%Will display dialog if more than one dim match.
              dropfig.setXblockVal(catdropdata);
            end
          otherwise
            %Cat everything and send it in as X.
            catdropdata = augment(-1,dropdata{:});%Will display dialog if more than one dim match.
            dropfig.setXblockVal(catdropdata);
        end
        
      end
      dropfig.apply;
    else
      %something else, assume v3.0 I/O and apply and then save results
      fn = lower(mymodl.modeltype);
      prediction = feval(fn,dropdata{:},mymodl,struct('plots','none','display','off'));
      svdlgpls(prediction,'Save results as...','prediction');
    end
    return
  end
end

%Concate datasets. Try to do it in "bulk" if possible.
if strcmp(target.class,'dataset') & all(ismember({sources.class},{'dataset' 'double' 'single'}))
  mydata = {target.value sources.value};
  if all(cellfun(@(x) isdataset(x),mydata))
    names = cellfun(@(x) x.name,mydata,'uniformoutput',false);
    if length(unique(names))<length(names)
      %more than two are duplicates?
      target.value.name = target.name;
      for j=1:length(sources)
        sources(j).value.name = sources(j).name;
      end
      mydata = {target.value sources.value};
    end
  end
  try
    myresult = augment(-1,mydata{:});
    assignin('base',evrivarname(target.name),myresult)
  catch
    erdlgpls({'Sorry. These items can not be used together.',lasterr},'Unable to use items')
  end
  return
end

for sourceind = 1:length(sources);
  source = sources(sourceind);  %cycle through all source objects (if > 1)
  
  switch target.class;  %dropped on item of class X
    
    case 'shortcut'  %dropped onto a shortcut
      
      switch target.drop
        case 'off'
          erdlgpls({'Dragging to this shortcut is not supported'},'Drag Canceled')
        case 'manual'
          erdlgpls({'Dragging to this shortcut is not currently supported',' ','Please load item manually'},'Drag Canceled')
          executeshortcut(target);
        case {'figure','on'}
          droponfig(executeshortcut(target),gcbf,source);
        case 'input'
          executeshortcut(target,source.value);
      end
      
      %=======================================================
    case {'controls','figure'}  %dropped onto a figure
      
      try
        droponfig(target.fn,gcbf,source);
      catch
        erdlgpls({'Sorry. These items can not be used together.',lasterr},'Unable to use items')
      end
      
      %=======================================================
    case 'preprocessing'  %dropped onto a preprocessing structure
      
      try
        newppdata = preprocess('calibrate',target.value,source.value);
        evrivarname([source.name '_preprocessed'],'base',newppdata);
      catch
        erdlgpls({'Sorry. These items can not be used together.'},'Unable to use items')
      end
      
      %=======================================================
    case 'model'
      
      fig = gcbf;
      try
        if ~ismember(source.class,{'dataset','double'})
          erdlgpls({'Sorry. These items can not be used together.',['Object "' source.name '" is not valid as data.']},'Unable to use items')
          return
        end
        data = {getvar(fig,target) getvar(fig,source)};
        
        if ~ismodel(data{1})
          erdlgpls('This does not appear to be a valid model object','Invalid model');
          return
        end
        
        methods = analysistypes;
        if ismember(lower(data{1}.modeltype),methods(:,1));
          %one of the valid analysis methods
          dropfig = evrigui('analysis');
          dropfig.drop(data{1});  %drop model
          dropfig.setXblockVal(data{2});
          dropfig.apply;
        else
          %something else, assume v3.0 I/O and apply and then save results
          try
            fn = lower(data{1}.modeltype);
            prediction = feval(fn,data{[2 1]},struct('plots','none','display','off'));
          catch
            erdlgpls({'Sorry. These items can not be used together.',lasterr},'Unable to use items')
            return
          end
          svdlgpls(prediction,'Save results as...','prediction');
        end
      catch
        erdlgpls({'Sorry. These items can not be used together.',lasterr},'Unable to use items')
      end
      
      %=======================================================
    otherwise
      
      if ~ismember(source.class,{'double','dataset'})
        erdlgpls('Sorry. These items can not be used together.','Unable to use items')
        return
      end
      try
        if ~isdataset(target.value)
          target.value = dataset(target.value);
          target.class = 'dataset';
        end
        browsefns(target,source)
      catch
        erdlgpls({'Sorry. These items can not be used together.',lasterr},'Unable to use items')
        return
      end
      
  end
end


%************ Drag Drop Functions ****************
%-------------------------------------------------
function dropCallbackFcn(obj, ev, varargin)
%Get drop transfer data from object and try to do appropriate callback. Try
%to parse drop code here then use existing drop code for actual work.

%Test cases:
% x 1) Drag single WS data item to pca.
% x 2) Drag multiple items from WS to pls. (only works for 1-2 items, doesn't work for 4 items)
% x 3) Drag single file to WS.
% x 4) Drag multiple file to WS (seems to work but depends on autoimport). 
% x 5) Drag single file to PCA shortcut node.
% x 6) Drag multiple files to PLS shorcut node.
% x 7) Drag cache demo node to WS.
% x 8) Drag single cache node to WS.
% * 9) Drag multiple cache nodes to WS. (Multiple selections not allowed)
% x 10) Drag single cache node to PCA.
% * 11) Drag multiple cache nodes to PLS. (Multiple selections not allowed)
% x 12) Drag ws node onto aonther for concat.
%   13) Drag PCA to WS dataset.


fig = varargin{1};
context = varargin{2};%Where item is being dropped on: 'wstree'=workspace, 'sctree'=shortcut tree
dropdata = drop_parse(obj,ev,'filelocation');%Get dropped objects/file locations.

if isempty(dropdata{1})
  %Possible error of dropdata.
  return
end

%Get shortcut types so we can test for SC node and switch the call incase
%user is dropping SC node on data or SC node on SC node.
opts = browse_shortcuts('options');
mytypes = opts.typeicons;
mytypes = mytypes(1,:);
mytypes = [{'favorites'} mytypes];

switch context
  case 'wstree'
    wsTree   = getappdata(fig,'workspace_tree');%Matlab tree.
    jTree    = wsTree.getTree;%Java tree.
    %Get node dropping onto. Will be empty if not droppiong on top node.
    myloc = evrijavamethodedt('getLocation',ev);%Works in 7a.
    targnode = evrijavamethodedt('getPathForLocation',jTree,myloc.getX,myloc.getY);
    
    %Check if this is top node "Current Workspace Variables", if it is then
    %clear targnode so code below acts like dropping into "white space" and
    %loading directly into base workspace.
    if ~isempty(targnode) & strcmp(targnode.getLastPathComponent.getValue,'1')
      targnode = [];
    end
    
    switch dropdata{1}
      case 'treenode'
        %If a tree node is dropped then call existing callbacks.
        myval = evrijavamethodedt('getValue',dropdata{end,2});
        
        if strfind(myval,'demo')
          %Dropping demo node onto workspace so call double click callback that
          %uses current_variable appdata to load data.
          tree_double_click(fig,'cache')
        elseif ismember(myval,mytypes)
          %Dropping a shortcut "type" (parent) node onto the ws. Do nothing
          %for now but my want default method to be used.
          return
        elseif ~isempty(strfind(myval,'/')) &&  ismember(myval(1:strfind(myval,'/')-1),mytypes)
          %Dropping shortcut node onto ws node.
          %Set cur var and reselect the sc node then call drop on sc tree.
          %Get node.
          wsnode = jTree.getLastSelectedPathComponent;
          if isempty(wsnode)
            %No node selected.
            setappdata(handles.eigenworkspace,'current_variable','');%Clear cur var.
            setappdata(handles.eigenworkspace,'current_ws_rows',[])
            return
          end
          %Set current var to workspace.
          setappdata(fig,'current_variable',get(wsnode,'userdata'));
          setappdata(fig,'current_ws_rows',jTree.getSelectionRows)
          
          %Reselect the node that was dragged since it could have been
          %change during drag.
          try
            %This should work if dragging sc node to ws node but I'm not
            %sure how consistantly it will work so wrap in try/catch.
            src_tr = evrijavamethodedt('getSource',ev);
            src_tr = evrijavamethodedt('getTransferable',src_tr);
            src_tf = evrijavamethodedt('getTransferDataFlavors',src_tr);
            src_node = evrijavamethodedt('getTransferData',src_tr,src_tf(1));
          catch
            evriwarndlg('Unable to drop node, try using "right-click menu" or dropping data onto short-cut.','Short-cut Drop Warning')
            return
          end
          %Get tree and reselect the original path since it probably
          %changed as user was dragging the sc node.
          mlTree   = getappdata(fig,'shortcut_tree');%Matlab tree.
          mljt = mlTree.getTree;%Java tree.
          %pp = evrijavaobjectedt('javax.swing.tree.TreePath',evrijavamethodedt('getPath',src_node));
          pp = javax.swing.tree.TreePath(src_node.getPath);
          mljt.setSelectionPath(pp);
          drop_sctree_callback(mlTree, evrijavamethodedt('getLastSelectedPathComponent',mljt),fig)
        elseif strfind(myval,'loadeddata/')
          %Dropping from miagui.
          mfig = findobj(allchild(0),'tag','miagui');
          if ishandle(mfig);
            myhandles = guihandles(mfig);
            thisdata = miagui('get_current_image',myhandles,str2num(myval(strfind(myval,'data/')+5:end)));
            thisdata = thisdata.imagedataset;
            if isempty(targnode)
              evrivarname(safename(thisdata.name),'base',thisdata);
            else
              %Dropping onto something else, need to load into workspace
              %first
              qresponse = evriquestdlg('Data must be loaded into workspace before dropping on other items. Load data now?','Load Data First','Yes','No','Yes');
              switch lower(qresponse)
                case 'yes'
                  evrivarname(safename(thisdata.name),'base',thisdata);
              end
            end
          end
        elseif isempty(targnode)
          %Dropping cache node onto blank space so just load into workspace.
          loadcacheitem(fig,[],guihandles(fig))
        else
          %Dropping ws node onto ws node so try to concat.
          drop_sctree_callback(wsTree,evrijavamethodedt('getLastSelectedPathComponent',jTree),fig);
        end
      otherwise
        %Assume dropping file.
        if isempty(targnode)
          %Just call drop_parse again to load into workspace since there's
          %no concat needed.
          drop_parse(obj,ev,'workspace',struct('concatenate',getfield(browse('options'),'dropconcatenate')));
        else
          %Dropping onto ws node so run concat code.
          drop_sctree_callback(wsTree, evrijavamethodedt('getLastSelectedPathComponent',jTree), fig, dropdata(:,2))
        end
    end
  case 'sctree'
    %Call "old" drop code with node.
    mlTree   = getappdata(fig,'shortcut_tree');%Matlab tree.
    jTree = mlTree.getTree;%Java tree.
    
    %Check to make sure not dropping SC node on SC node.
    mysrc = evrijavamethodedt('getValue',dropdata{end,2});
    targnode = evrijavamethodedt('getLastSelectedPathComponent',jTree);
    mytarg = evrijavamethodedt('getValue',targnode);
    
    if ~isempty(strfind(mysrc,'/')) &&  ismember(mysrc(1:strfind(mysrc,'/')-1),mytypes) && ...
        ~isempty(strfind(mytarg,'/')) &&  ismember(mytarg(1:strfind(mytarg,'/')-1),mytypes)
      return
    end
    
    switch dropdata{1}
      case 'treenode'
        %Dropping a node on a SC node so call existing callback (should
        %refactor this later maybe).
        drop_sctree_callback(mlTree, targnode, fig);%SC nodes are dynamically selected so last selected shold be correct node.
      otherwise
        %Dropping files, pass locations.
        drop_sctree_callback(mlTree, targnode, fig, dropdata(:,2))
    end
end
update(fig)

%-------------------------------------------------
function dragEnterCallbackFcn(obj, ev, varargin)
%disp('drag enter')
setappdata(varargin{1},'scTreeHoverTimestamp',[]);

%-------------------------------------------------
function dragExitCallbackFcn(obj, ev, varargin)
%If dragging something out of tree, set the selection back to what was dragged.

fig = varargin{1};
treesrc = varargin{2};%Source tree.
switch treesrc
  case 'wstree'
    %If exiting wstree, set current node back to one being dragged
    myrows = getappdata(fig,'current_ws_rows');
    mytree = getappdata(fig,'workspace_tree');
    jt = mytree.getTree;
    jt.setSelectionRows(myrows);
    %evrijavamethodedt('setSelectionRows',jt,myrows);
end

%-------------------------------------------------
function dragOverCallbackFcn(obj, ev, varargin)
%Highlight leafs when dragging over them, start a timer if over a branch
%and expand it if user hovers for more than a second.

%Can't use timer because overcallback called differently on differnt
%platforms. On windows callback is continuously called even if mouse stops
%moving.

%NOTE (MEMORY LEAK): For 7a/b can't use evrijavamethodedt/awtinvoke because
%it's too slow so we have to make a direct call on java object. This has
%small potential to cause memory problem or race condition. If this happens
%try the following:
%
% if checkmlversion('>=','7.6')
%   javaMethodEDT('expandRow',obj,myval);
% else
%   %Use direct call, in most cases this should work.
%   obj.expandRow(myval);
% end
  

fig = varargin{1};
treesrc = varargin{2};%Source tree.

%loc = evrijavamethodedt('getLocation',ev);%Works for 7a.

switch treesrc
  case 'sctree'
    mytree = getappdata(fig,'shortcut_tree');
    jt = mytree.getTree;
    myrow = jt.getClosestRowForLocation(ev.getLocation.getX,ev.getLocation.getY);
    %myrow = evrijavamethodedt('getClosestRowForLocation',jt,loc.getX,loc.getY);
  case 'wstree'
    mytree = getappdata(fig,'workspace_tree');
    jt = mytree.getTree;
    myrow = jt.getPathForLocation(ev.getLocation.getX,ev.getLocation.getY);
    %myrow = evrijavamethodedt('getPathForLocation',jt,ev.getLocation.getX,ev.getLocation.getY);
    if isempty(myrow)
      myrow = 0;
    else
      %myrow = evrijavamethodedt('getClosestRowForLocation',jt,loc.getX,loc.getY);
      myrow = jt.getClosestRowForLocation(ev.getLocation.getX,ev.getLocation.getY);
    end
end
%jt.setSelectionRow(myrow)
%evrijavamethodedt('setSelectionRow',jt,myrow);
jt.setSelectionRow(myrow);
if strcmp(treesrc,'wstree')
  return
end
%curnode = evrijavamethodedt('getLastSelectedPathComponent',jt);
curnode = jt.getLastSelectedPathComponent;
myval = curnode.getValue;
curtime = now;

oldVal = getappdata(fig,'scTreeHoverTimestamp');
if isempty(oldVal)|strcmp(myval,oldVal{1})
  setappdata(fig,'scTreeHoverTimestamp',{myval curtime});
else
  if(curtime-oldVal{2})>.000015
    %Hovered for more than a second so expand.
    mypath = javax.swing.tree.TreePath(curnode.getPath);%Create a path we can expand to.
    if ~isempty(mypath)
      %Expand the path.
      %evrijavamethodedt('expandPath',jt,mypath);
      jt.expandPath(mypath)
    end
    setappdata(fig,'scTreeHoverTimestamp',{myval curtime});
  end
end

%--------------------------
function automation
%AUTOMATION toggle automation server

if exist('socketserver')
  socketserver('autostart','toggle')
end

%--------------------------
function browse_pyconfig(mytype)
%Change browse options.


switch mytype  
  case 'addConda'
    result = config_pyenv;
  case 'addArchived'
    o = config_pyenv('options');
    o.source = 'archived';
    result = config_pyenv(o);
  case 'remove'
    result = undo_config_pyenv;
  case 'delete'
    o = undo_config_pyenv('options');
    o.remove_all = 'yes';
    result = undo_config_pyenv(o);
  case 'check'
    result = check_pyenv;
  case 'which'
    result = whichPython;
end

if ~isempty(result);
  evrimsgbox(result,'Configure Python Environment')
end

%--------------------------
function browse_grootsettings(mytype)
%Change browse options.

switch mytype  
  case 'edit'
    grooteditor;
  case 'resetall'
    answer = evriquestdlg('Reset all GROOTMANAGER properties. This will erase all prior groot property sets and defaults and return defaults to factory settings.','GROOT Reset All');
    if strcmpi(answer,'yes')
      grootmanager('clearall')
    end
end

%--------------------------
function browseoptions(fig)
%Change browse options.

handles = guihandles(fig);
newopts = optionsgui('browse');

if isempty(newopts);
  return;
end

%remove fields we don't want to set in plspref
newopts = rmfield(newopts,{'definitions','functionname'});
setplspref('browse',newopts);  %save everything else
browse;  %and update window
setappdata(handles.eigenworkspace,'cachetreetype',newopts.defaultcacheview)
evritreefcn(handles.eigenworkspace,'update');

%--------------------------
function editdefaultfontsize(fig)
%Change browse options.
mysize = num2str(getdefaultfontsize);
newfontsize = inputdlg('New Font Size:','Default Font Size',[1 45],{mysize});
if ~isempty(newfontsize)
  setplspref('getdefaultfontsize','normal',str2num(newfontsize{1}))
end

%--------------------------
function new = getwscopyname(origname)
%Get copy name adapted from workspacefunc.m

mywho = evalin('base', 'who');
counter = 0;
new_base = [origname 'Copy'];
new = new_base;
while checkwsname(new , mywho)
    counter = counter + 1;
    proposed_number_string = num2str(counter);
    new = [new_base proposed_number_string];
end

%--------------------------
function result = checkwsname(name, mywho)
%Check workspace name.

result = false;
counter = 1;
while ~result && counter <= length(mywho)
    result = strcmp(name, mywho{counter});
    counter = counter + 1;
end

%--------------------------
function updatehelpfont(fig)
%Change font size of help CSS.

curfont = evrihelpconfig('','getfont');
curfont = num2str(curfont);

newfontsize = inputdlg('New Font Size (pixels):','Help Font Size',1,{curfont});
%Remove px if it's there.
newfontsize = strrep(newfontsize,'px','');

if ~isempty(newfontsize)
  evrihelpconfig('','setfont',str2num(newfontsize{:}))
end

%--------------------------
function out = showvideo(url)
%Show video from shortcut tree.

web(url,'-browser')

%--------------------------
%run a specified unit test
function unittest(test)

evalin('base',test);

if false
  %make sure critical functions get included in compilation
  analysis_test
end

%--------------------------
function out = optiondefs

defs = {
  %name             tab            datatype        valid           userlevel       description
  %'iconsize'	    'Appearance'	'double'	'int(5:100)'	'novice'        'Size of icons (in pixels)'
  %'fontsize'      'Appearance'	'double'	'int(1:30)'   'novice'        'Font size for icon labels (in points)'
  %'fontname'      'Appearance'	'char'	  []            'novice'        'Font name for icon labels (default = "Helvetica")'
  'desktop'        'Appearance' 'boolean' ''                          'novice'        'Enables "old-style" desktop workspace browser. Does not take effect until restart.'
  'nomovies'       'Appearance' 'boolean' ''                          'novice'        'Disables loading of movie list from Eigenvector website. A value of 1 ("yes") turns OFF movie loading. Does not take effect until restart.'
  'dropconcatenate' 'Behavior'  'select' {'on' 'off'}                 'novice'        'Enables concatenation of selected files when dragging to import. If "on" all dragged files will be concatenated before being put into workspace. If "off", files are imported individually.'
  'automation'     'Behavior'  	'select'	{'on' 'off' 'disabled'}     'intermediate'	'Determines start-up behavior of remote automation server. ''on'' enabled remote automation at startup, ''off'' leaves automation off. ''disabled'' requires user confirmation before starting through menu.'
  'grootmanager'   'Behavior'   'select' {'on' 'off'}                 'novice'        'Initialize grootmanager when browse is opened, this will set groot defaults saved in grootmanager.'
  'wsname_width'   'Appearance' 'double'	'int(1:inf)'                'intermediate'	'Control width (in characters) of name column in workspace window.'
  'defaultcacheview'  'Appearance' 'select'  {'lineage' 'date' 'type'}    'novice'    'Governs the display of the model cache.';
   };

out = makesubops(defs);
