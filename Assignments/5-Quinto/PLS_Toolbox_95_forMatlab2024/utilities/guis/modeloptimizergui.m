function varargout = modeloptimizergui(varargin)
%MODELoptimizerGUI GUI for modeloptimizer.
% Generic code for setting up a Figure from mcode only. Use the following
% keys to search and replace.
%   tag/function = "modeloptimizergui"
%   title/name   = "Generic GUI"
%
%  INPUTS:
%   models = a cell array containing one or more models.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%      exclude_columns: [{'ID' 'Date'}] Columns to exclude from results
%                       table.
%      include_columns: [{'' ''}] Columns to always include in results
%                       table, excluded columns will not be shown (must
%                       remove from exclude list first).
%       hide_emptycols: ['off'|{'on'}] Hide columns with all empty values (unless included/excluded).
%         hide_repcols: ['off'|{'on'}] Hide columns with all the same value (unless included/excluded).
%          color_table: ['off'|{'on'}] Color cells in table according to value.
%        cell_colormap: [{'bone'}] Colormap for table cells.
%           show_built: ['off'|{'on'}] Show column indicating if model is built.
%
%
%I/O: h = modeloptimizergui(fig) %Fig is handle to analysis figure.
%I/O: modeloptimizergui(data) %Open preloaded.
%
%See also: PLOTGUI

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%TODO: Fix column ordering, use of union/setdiff/ismember seems to reorder
%somwhere.
%TODO: Complete code for no ncomps.

if nargin==0 | ~ischar(varargin{1}) % LAUNCH GUI
  msg = checkcache;
  if ~isempty(msg);
    erdlgpls(msg,'Model Optimizer Error')
    if nargout>0
      varargout = {[]};
    end
    return
  end
  
  try
    %Start GUI
    fig = findobj(allchild(0),'tag','modeloptimizergui');
    if ~isempty(fig);
      %Only one optimizer gui at a time. All calls to modeloptimizer get
      %parsed into one model no matter if GUI exits or not.
      figure(fig);
      
      if nargin>0 & ~isempty(varargin{1}) & isnumeric(varargin{1})
        if ishandle(varargin{1})
          warning('EVRI:ModeloptimizerFigHandle','Analysis figure handle is no longer valid.')
        else
          setappdata(fig,'analysis_figure',varargin{1})
        end
      end
      
      if nargout>0;
        varargout{1} = fig;
      end
      
      update_callback(guihandles(fig))
      return;
    end
    
    h=waitbar(1,['Starting Model Optimizer...']);
    drawnow
    %Open figure and initialize
    %fig = openfig('modeloptimizergui.fig','new','invisible');
    
    fig = figure('Tag','modeloptimizergui',...
      'NumberTitle', 'off', ...
      'HandleVisibility','callback',...
      'Integerhandle','off',...
      'Name', 'Model Optimizer',...
      'Renderer','OpenGL',...
      'MenuBar','none',...
      'ResizeFcn','modeloptimizergui(''resize_callback'',gcbo,[],guihandles(gcbf))',...
      'CloseRequestFcn','try;modeloptimizergui(''closereq_callback'',gcbo,[],guihandles(gcbf),0);catch;delete(gcbf);end',...
      'visible','off',...
      'Units','pixels');
    
    %Set up gui controls.
    gui_enable(fig)
    
    figbrowser('addmenu',fig); %add figbrowser link
    
    %Position gui from last known position.
    positionmanager(fig,'modeloptimizergui');
    
    handles = guihandles(fig);
    
    pause(.1);drawnow
    set(fig,'visible','on');
    
    resize_callback(fig,[],handles);
    
    evritip('Model Optimizer Cal/Val',...
  'Model Optimizer is designed to work with models and calibration data. It is recommended to take a snapshot without validation data loaded. Use the Ca/Val button to apply Model Optimizer models to validation data',1);
 
    %Get analysis fig if passed.
    if nargin>0 & ~isempty(varargin{1}) & isnumeric(varargin{1})
      if ~ishandle(varargin{1})
        warning('EVRI:ModeloptimizerFigHandle','Analysis figure handle is no longer valid.')
      else
        setappdata(fig,'analysis_figure',varargin{1})
      end
    end
  catch
    if exist('fig','var') & ishandle(fig); delete(fig); end
    if exist('h','var') & ishandle(h); close(h);end
    erdlgpls({'Unable to start the Model optimizer' lasterr},[upper(mfilename) ' Error']);
  end
  
  if exist('h','var') & ishandle(h)
    close(h);
  end
  
  if nargout>0
    varargout{1} = fig;
  end
  
else % INVOKE NAMED SUBFUNCTION OR CALLBACK
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = [];
        options.renderer            = 'opengl';%Opengl can be slow on Mac but it's the only renderer that displays alpha.
        options.exclude_columns     = {'ID' 'date'};%Never show columns named.
        options.include_columns     = {};%Show these columns if not in exclude_columns.
        options.options_fields      = {'Algorithm' 'algorithm'; 'Confidence Limit' 'confidencelimit'; 'Orthoganlize' 'orthogonalize';'Points' 'npts';'Robust Alpha' 'roptions.alpha'};
        options.hide_emptycols      = 'on';%Hide columns with all empty values.
        options.hide_repcols        = 'on';%Hide columns with all the same value.
        options.color_table         = 'on';%Color cells in table according to value.
        options.cell_colormap       = 'bone';%Colormap for table cells.
        options.show_built          = 'on';%Show column indicating if model is built.
        options.definitions         = @optiondefs;
        
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;
      otherwise
        if nargout == 0;
          %normal calls with a function
          feval(varargin{:}); % FEVAL switchyard
        else
          [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
        end
    end
    
  catch
    if ~isempty(gcbf);
      set(gcbf,'pointer','arrow');  %no "handles" exist here so try setting callback figure
    end
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end
 
end

%--------------------------------------------------------------------
function varargout = gui_enable(fig)
%Initialize the the gui.

%Check for cache.
error(checkcache)

%Get handles and save options.
handles = guihandles(fig);
gopts = modeloptimizergui('options');

%Set persistent options.
%fopts = analyzeparticles('options');
%fopts.display = 'off';
%Save options.
setappdata(fig,'gui_options',gopts);
%setappdata(fig,'fcn_options',fopts);

%Get position.
figpos = get(fig,'position');
figcolor = [.92 .92 .92];
set(fig,'Color',figcolor,'Renderer',gopts.renderer);

%Add drag drop handler.
figdnd = evrijavaobjectedt(DropTargetList);%EVRI Custom drop target class.
figdnd = handle(figdnd,'CallbackProperties');
jFrame = get(handle(handles.modeloptimizergui),'JavaFrame');

%Don't think we need to run on EDT but if the need arises be sure to

%accommodate 7.0.4.
jAxis  = jFrame.getAxisComponent;
jAxis.setDropTarget(figdnd);
set(figdnd,'DropCallback',{@dropCallbackFcn,handles.modeloptimizergui});

%Set extra fig properties.
set(fig,'Toolbar','none')

%File menu.
hmenu = uimenu(fig,'Label','&File','tag','menu_file');
uimenu(hmenu,'tag','loadmodelmenu','Separator','off','label','&Load Optimizer','callback','modeloptimizergui(''loadmodel'',gcbo,[],guidata(gcbf))');
uimenu(hmenu,'tag','savemodelmenu','label','Save &Optimizer','callback','modeloptimizergui(''save_callback'',gcbo,[],guidata(gcbf),''model'')');
uimenu(hmenu,'tag','clearmodelmenu','label','&Clear Optimizer'        ,'callback','modeloptimizergui(''clear_Callback'',gcbo,[],guidata(gcbf),''model'')');
uimenu(hmenu,'tag','closemenu','Separator','on','label','&Close','callback','modeloptimizergui(''closereq_callback'',gcbo,[],guidata(gcbf),''import'')');
%Edit menu.
hmenu = uimenu(fig,'Label','&Edit','tag','menu_edit');
uimenu(hmenu,'tag','changefiguremenu','label','&Change Analysis Figure','callback','modeloptimizergui(''change_analysisfigure'',guidata(gcbf))');
uimenu(hmenu,'tag','includecolumns','label','&Include Columns','callback','modeloptimizergui(''select_columns_Callback'',gcbo,[],guidata(gcbf))','separator','on');
uimenu(hmenu,'tag','excludecolumns','label','&Exclude Columns','callback','modeloptimizergui(''select_columns_Callback'',gcbo,[],guidata(gcbf))');
uimenu(hmenu,'tag','refreshtree','label','&Refresh Window','callback','modeloptimizergui(''update_callback'',guidata(gcbf))','separator','on');
uimenu(hmenu,'tag','guioptionsmenu','Separator','on','label','&Options','callback','modeloptimizergui(''editoptions'',gcbo,[],guidata(gcbf),''gui'')');
%Help menu.
hmenu = uimenu(fig,'Label','&Help','tag','menu_help');
uimenu(hmenu,'tag','openhelpmenu','label','&Model optimizer Analysis Help','callback','modeloptimizergui(''openhelp_ctrl_Callback'',gcbo,[],guidata(gcbf))');
uimenu(hmenu,'tag','plshelp','label','&General Help','callback','helppls');

%Make context menu.
hcontext = uicontextmenu('parent',fig);
set(hcontext,'CreateFcn','modeloptimizergui(''cmenu_callback'',gcbo,[],guidata(gcbf));');
set(hcontext,'tag','treecontextmenu')

uimenu(hcontext,'tag','colapsetree','label','&Collapse Tree','callback','modeloptimizergui(''cmenu_callback'',gcbo,[],guidata(gcbf));');
uimenu(hcontext,'tag','runall','label','&Run All Models','callback','modeloptimizergui(''cmenu_callback'',gcbo,[],guidata(gcbf));');
uimenu(hcontext,'tag','addsnapshot','label','&Add Snapshot','callback','modeloptimizergui(''cmenu_callback'',gcbo,[],guidata(gcbf));');
uimenu(hcontext,'tag','addsnapshots','label','&Add All Snapshots','callback','modeloptimizergui(''cmenu_callback'',gcbo,[],guidata(gcbf));');
uimenu(hcontext,'tag','addall','label','&Add All Combinations','callback','modeloptimizergui(''cmenu_callback'',gcbo,[],guidata(gcbf));');
uimenu(hcontext,'tag','addpp','label','&Survey Preprocessing','callback','modeloptimizergui(''cmenu_callback'',gcbo,[],guidata(gcbf));');
uimenu(hcontext,'tag','clearsnapshot','label','&Clear Snapshot','callback','modeloptimizergui(''cmenu_callback'',gcbo,[],guidata(gcbf));');
uimenu(hcontext,'tag','clearmodel','label','&Clear Model','callback','modeloptimizergui(''cmenu_callback'',gcbo,[],guidata(gcbf));');
uimenu(hcontext,'tag','clearsnapshots','label','&Clear All Snapshots','callback','modeloptimizergui(''cmenu_callback'',gcbo,[],guidata(gcbf));');
uimenu(hcontext,'tag','clearmodels','label','&Clear All Models','callback','modeloptimizergui(''cmenu_callback'',gcbo,[],guidata(gcbf));');
uimenu(hcontext,'tag','clearall','label','&Clear All','callback','modeloptimizergui(''cmenu_callback'',gcbo,[],guidata(gcbf));','separator','on')

%Make compare models tree.
mytbl = etable('parent_figure',fig,'tag','comparetable','autoresize','AUTO_RESIZE_OFF',...
  'custom_cell_renderer','on','column_sort','on','table_clicked_callback',{@table_click_callback,fig,1},...
  'row_clicked_callback',{@table_click_callback,fig,1},'row_doubleclicked_callback',{@table_click_callback,fig,2},...
  'units','pixels','data',{true '' '' '' '' ''},'column_labels',{' ' ' ' ' ' ' ' ' ' ' '},...
  'custom_cell_renderer','on','replace_nan_with',' ','post_sort_callback', {@update_after_sort,fig});%,'data_changed_callback',{@datachange_callback,fig});
mytbl.grid_color = [.9 .9 .9];%Grid color is light grey.
mytbl.row_header_width = 70;
mytbl.editable = 'off';%Don't allow edits.
handles = guihandles(fig);

%Make tree.
nodestruct = get_default_nodes(handles,'models');
modeltree = evritree('parent_figure',fig,'tag','modeltree','visible','on',...
  'units','pixels','position',[5 55 100 100],'tree_data',nodestruct,...
  'selection_type','discontiguous','tree_clicked_callback',@tree_callback,...
  'tree_contextmenu',hcontext,'tree_contextmenu_callback',@cmenu_enable_callback,'hide_panel','on');%,...
  %'root_visible','on','root_icon','');

nodestruct = get_default_nodes(handles,'snapshot');
sstree = evritree('parent_figure',fig,'tag','sstree','visible','on',...
  'units','pixels','position',[5 55 100 100],'tree_data',nodestruct,...
  'selection_type','discontiguous','tree_clicked_callback',@tree_callback,...
  'tree_contextmenu',hcontext,'tree_contextmenu_callback',@cmenu_enable_callback,...
  'root_visible','on','root_icon','');

%Make java panels.
import java.awt.*
import javax.swing.*
pos = get(fig,'position');

%Make compare model table panel.
tjt = mytbl.java_table;
fPanel = JPanel(BorderLayout);
fPanel.add(tjt.getParent.getParent.getParent,BorderLayout.CENTER);
fPanel.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEmptyBorder, 'Compared Models'));

tjt.setDropTarget(getDnD('mtable',fig))
tjt.getParent.setDropTarget(getDnD('mtable_viewport',fig))

%Add model compare tree to top panel.
mctree  = modeltree.tree;
mcPane  = mctree.getScrollPane;
mcPanel = JPanel(BorderLayout);
mcPanel.add(mcPane, BorderLayout.CENTER);
mcPanel.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEmptyBorder, 'Compare Models'))

mctree.getTree.setDropTarget(getDnD('mrtree',fig))

%Add snapshot tree to bottom panel.
sntree  = sstree.tree;
snPane  = sntree.getScrollPane;
snPanel = JPanel(BorderLayout);
snPanel.add(snPane, BorderLayout.CENTER);
snPanel.setBorder(BorderFactory.createTitledBorder(BorderFactory.createEmptyBorder, 'Snapshots and Combinations'))
%mcPanel.add(buttonPanel1,BorderLayout.NORTH);

sntree.getTree.setDropTarget(getDnD('sstree',fig))

%Make snapshot, survey, and combinations buttons.
myicons = gettbicons;
cico = javax.swing.ImageIcon(im2java(myicons.combinations));
mico = javax.swing.ImageIcon(im2java(myicons.calc));
surv = javax.swing.ImageIcon(im2java(myicons.toggle_checkbox));

compbosbtn = evrijavaobjectedt('javax.swing.JButton','Add Combinations',cico);
runmodelsbtn = evrijavaobjectedt('javax.swing.JButton','Calculate Models',mico);
surveybtn = evrijavaobjectedt('javax.swing.JButton','Survey Preprocessing',surv);

%Need handle when using callback.
compbosbtnh = handle(compbosbtn,'callbackproperties');
runmodelsbtnh = handle(runmodelsbtn,'callbackproperties');
surveybtnh = handle(surveybtn,'callbackproperties');

pause(.05);
drawnow;

set(compbosbtnh,'ActionPerformedCallback',{@buttonpush,fig,'addcombos'},'MinimumSize',Dimension(34, 34))
set(runmodelsbtnh,'ActionPerformedCallback',{@buttonpush,fig,'run_all'},'MinimumSize',Dimension(34, 34))
set(surveybtnh,'ActionPerformedCallback',{@buttonpush,fig,'surveypp'},'MinimumSize',Dimension(34, 34))
setappdata(fig,'surveyjbutton',surveybtnh);%Need to access the button outside callback later.

%Make button panel.
buttonPanle = JPanel(GridLayout(0,3));
buttonPanle.add(surveybtn);
buttonPanle.add(compbosbtn);
buttonPanle.add(runmodelsbtn);

%Add button panel to snapshot panel.
snPanel.add(buttonPanle, BorderLayout.NORTH);

%Make top/bottom tree split pane.
treePane = JSplitPane(JSplitPane.VERTICAL_SPLIT);
treePane.setTopComponent(mcPanel);
treePane.setBottomComponent(snPanel)
treePane.setOneTouchExpandable(true);
treePane.setContinuousLayout(true);
treePane.setResizeWeight(0.6);

%Make the left/right pane.
lrPane = JSplitPane(JSplitPane.HORIZONTAL_SPLIT, fPanel, treePane);
lrPane.setOneTouchExpandable(true);
lrPane.setContinuousLayout(true);
lrPane.setResizeWeight(0.7);
%lrPane.setDividerLocation(.7)

drawnow

%Use javacomponent to put on EDT.
[obj, hcontainer] = javacomponent(lrPane, [0,0,pos(3),pos(4)], fig);
set(hcontainer,'units','normalized','tag','mainpanel','userdata',obj);
pause(.2)

%Add toolbar.
[htoolbar, hbtns] = toolbar(fig,'modeloptimizergui');

handles = guihandles(fig);
guidata(fig,handles);

%axes('parent',handles.modeloptimizergui,'tag','displayax');

update_callback(handles)

%--------------------------------------------------------------
function out = getDnD(myname,fig)
%Get drag drop object.

out = evrijavaobjectedt(DropTargetList);%EVRI Custom drop target class.
out = handle(out,'CallbackProperties');
set(out,'DropCallback',{@dropCallbackFcn,fig,myname,'drop'});
set(out,'DragEnterCallback',{@dropCallbackFcn,fig,myname,'dragenter'});
set(out,'DragOverCallback',{@dropCallbackFcn,fig,myname,'dragover'});
set(out,'DragExitCallback',{@dropCallbackFcn,fig,myname,'dragexit'});

%--------------------------------------------------------------
function out = checkcache
%check if the cache is on and connected. Returns non-empty error message as
%string if it is NOT working

mcopts = modelcache('options');
out = modelcache('getcacheobj');
if ~strcmpi(mcopts.cache,'on') | isempty(out)
  out = 'Model optimizer can''t function without Model Cache database access. Please check modelchache connection.';
else
  out = '';
end

%makestatusbar(fig,'')
%--------------------------------------------------------------
function resize_callback(h,eventdata,handles,varargin)
%Resize callback.

%Sometimes handles aren't updated so get them manually.
handles = guihandles(h);

if isempty(handles)
  %On some platforms resize is called by openfig before all of controls are
  %created in gui init so just return until handles are available.
  return
end

%Check to see if divider drag.
if nargin>3
  mydrag = varargin{1};
else
  mydrag = 0;
end

set(handles.modeloptimizergui,'units','pixels');

%Get initial positions.
figpos = get(handles.modeloptimizergui,'position');
set(handles.mainpanel,'units','pixels');
set(handles.mainpanel,'position',[2 2 max(1,figpos(3)-4) max(1,figpos(4)-4)]);
%set(handles.mainpanel,'position',[1 20 max(1,figpos(3)-2) max(1,figpos(4)-122)]);

%set(handles.displayax,'units','pixels','position',[2 max(1,figpos(4)-98) max(1,figpos(3)-4) 96]);

%--------------------------------------------------------------------
function buttonpush(h,eventdata,handles,varargin)
%Run modeloptimizer functions.

if ishandle(handles)
  handles = guihandles(handles);
end
switch varargin{1}
  case 'snapshot'
    modeloptimizer('snapshot',get_fig(handles));
    modeloptimizer('combine_snapshots')
  case 'locate'
    afig = get_fig(handles);
    if ~isempty(afig)
      figure(afig);
    end
    return
  case 'addcombos'
    modeloptimizer('assemble_combinations')
  case 'combine'
    modeloptimizer('combine_snapshots')
  case 'run_all'
    set(handles.modeloptimizergui,'pointer','watch')
    try
      modeloptimizer('calculate_models')
    catch
      evriwarndlg('An error occured while calculating all model compinations.  Review combinations and delete models that don''t calculate.', 'Error calculating all models')
    end
    set(handles.modeloptimizergui,'pointer','arrow')
  case 'plottable'
    mytable = getappdata(handles.modeloptimizergui,'comparetable');
    tdata = mytable.data;
    cnames = mytable.column_labels;
    tdata = [cnames; tdata];
    pdata = parsemixed(tdata(:,2:end));
    plotgui(pdata,'new','plottype','bar','viewlabels',1,'viewlabelangle',90,'viewlabelset',2);
    return
  case 'surveypp'
    cmenu_callback(handles.addpp,[],handles)
    return
  case 'loadvaliddata'
   
    update_pred(handles);
    update_display(handles)
    return
end

update_callback(handles)

%--------------------------------------------------------------------
function myfig = change_analysisfigure(handles)
%Select an analysis figure.

setappdata(handles.modeloptimizergui,'analysis_figure',[])
myfig = get_fig(handles);

%--------------------------------------------------------------------
function myfig = get_fig(handles)
%Get a current figure for analysis or create a new one of one doesn't
%exist.

myfig = getappdata(handles.modeloptimizergui,'analysis_figure');
if isempty(myfig) | ~ishandle(myfig)
  hh = findobj(allchild(0),'tag','analysis');
  if isempty(hh)
    %Make new figure.
    myfig = analysis;
  else
    if length(hh)==1
      myfig = hh;
    else
      names = get(hh,'Name');
      if ~iscell(names)
        names = {names};
      end
      
      myval = listdlg('PromptString','Select an Analysis figure:','SelectionMode','single','ListString',names);
      if ~isempty(myval)
        myfig = hh(myval);
      else
        myfig = [];
        return
      end
    end
  end
end

setappdata(handles.modeloptimizergui,'analysis_figure',myfig);

%--------------------------------------------------------------------
function clientsnapshot(myfig)
%Get a snapshot.
opfig = modeloptimizergui;
if isempty(opfig); return; end
setappdata(opfig,'analysis_figure',myfig);
buttonpush(opfig,[],guidata(opfig),'snapshot');

%--------------------------------------------------------------------
function openhelp_ctrl_Callback(hObject, eventdata, handles)
%Open help page.
evrihelp('modeloptimizergui')

%--------------------------------------------------------------------
function closereq_callback(h,eventdata,handles,varargin)
%Close gui.

if isempty(handles)
  handles = guihandles(h);
end

%Save preferences.
setplspref('modeloptimizergui',getappdata(handles.modeloptimizergui,'gui_options'))

%Save figure position.
positionmanager(handles.modeloptimizergui,'modeloptimizergui','set')

if ishandle(handles.modeloptimizergui)
  delete(handles.modeloptimizergui)
end

%--------------------------------------------------------------------
function select_columns_Callback(h,eventdata,handles,varargin)
%Select columns to include/exclude and order.

mymenu   = get(h,'tag');
thislist = getappdata(handles.modeloptimizergui,'available_columns');
gopts = getappdata(handles.modeloptimizergui, 'gui_options');

ecol = gopts.exclude_columns;
icol = gopts.include_columns;
icol = setdiff(icol,ecol);%Don't allow exluded items in include.

switch mymenu
  case 'includecolumns'
    mylist = setdiff(thislist,ecol);
    [newlist,btn] = listchoosegui(mylist,icol);
    if strcmp(btn,'ok')
      gopts.include_columns = newlist;
    end
  case 'excludecolumns'
    [newlist,btn] = listchoosegui(thislist,ecol);
    if strcmp(btn,'ok')
      gopts.exclude_columns = newlist;
    end
end

setappdata(handles.modeloptimizergui, 'gui_options', gopts)
update_table(handles)
update_display(handles)

%--------------------------------------------------------------------
function cmenu_enable_callback(varargin)
%Enable menu items based on what leaf mouse is over.

tobj = varargin{3};
tpath = varargin{7};
handles = guihandles(tobj.parent_figure);
cmenu = tobj.tree_contextmenu;
set(allchild(cmenu),'visible','off','separator','off')

%Add two global items.
set(handles.runall,'visible','on')
set(handles.colapsetree,'visible','on')
set(handles.clearall,'visible','on','separator','on')

if ~isempty(tpath)
  mypath = str2cell(strrep(tpath,'/',char(9)));%Replace / with tab and parse with str2cell.
else
  tpath = '';
  mypath = {''};  
end

myid = [];
[s1,s2] = regexp(tpath,'[\d]+\.[\d]+');
if ~isempty(s1)
  myid = tpath(s1:s2);
end
en = 'on';%Enable flag.
switch mypath{1}
  case 'runs'
    if ~isempty(myid)
      set(handles.clearmodel,'visible','on','separator','on')
      en = 'off';
    end
    set(handles.clearmodels,'visible','on','separator',en)
  case 'snapshot'
    if ~isempty(myid)
      set(handles.addsnapshot,'visible','on','separator','on')
      set(handles.clearsnapshot,'visible','on','separator','on')
      set(handles.addpp,'visible','on','separator','on')
      en = 'off';
    end
    set(handles.addsnapshots,'visible','on','separator','off')
    set(handles.clearsnapshots,'visible','on','separator',en)
  case 'independent'
    set(handles.addall,'visible','on','separator','on')
end

%--------------------------------------------------------------------
function cmenu_callback(h,eventdata,handles,varargin)
%Run context menu items.

mymenu  = get(h,'tag');

%Get tree location info.
mytree   = getappdata(handles.modeloptimizergui,'modeltree');
jt       = mytree.java_tree;

if isempty(jt.getMousePosition)
  %On snapshot tree.
  mytree = getappdata(handles.modeloptimizergui,'sstree');
  jt     = mytree.java_tree;
end

nodepath = evrijavamethodedt('getLastSelectedPathComponent',jt);
tpath    = nodepath.getValue;
myid     = [];
[s1,s2]  = regexp(tpath,'[\d]+\.[\d]+');
if ~isempty(s1)
  myid = tpath(s1:s2);
end

%Get single delete id check.
if ismember(mymenu,{'clearmodel' 'clearsnapshot'})
  if isempty(myid)
    return
  end
end

switch mymenu
  case 'clearmodel'
    modeloptimizer('clear_item','model',myid)
  case 'clearmodels'
    modeloptimizer('clear_item','model',[])
  case 'clearsnapshot'
    modeloptimizer('clear_item','snapshot',myid)
  case 'clearsnapshots'
    modeloptimizer('clear_item','snapshot',[])
  case 'clearall'
    %Clear model.
    modeloptimizer('clear');
  case 'addsnapshot'
    modeloptimizer('move_snapshot',myid);
  case 'addsnapshots'
    modeloptimizer('move_snapshot');
  case 'addall'
    modeloptimizer('assemble_combinations');
  case 'addpp'
    %Check so see if a model node has been selected.
    if isempty(myid)
      evriwarndlg('No Snapshot selected. Select a Snapshot first then click survey button to display options.','Select Snapshot')
    else
      get_snapshot_preprocessing(handles,myid);
    end
    return
  case 'runall'
    modeloptimizer('calculate_models');
  case 'colapsetree'
    try
      jtr = mytree.tree;
      for i = 0:2
        p = evrijavaobjectedt('javax.swing.tree.TreePath', jtr.getRoot.getChildAt(i).getPath);
        jt.collapsePath(p);
        drawnow
      end
    end
    return
end

update_callback(handles)

%--------------------------------------------------------------------
function snpsh = getemptysnpsh
%Get empty snapshot.
snpsh = modeloptimizer('make_optimizer');
snpsh = snpsh.snapshots;

%--------------------------------------------------------------------
function mr = getemptyruns
%Get empty snapshot.
mr = modeloptimizer('make_optimizer');
mr = mr.modelrun;

%--------------------------------------------------------------------
function loadmodel(h,eventdata,handles,varargin)
%Load model.

mymodel = get_model;

%Check for overwrite of model (check to see it's not an empty model).
if ~isempty(mymodel) & ~isempty(mymodel.optimizer.snapshots.id) & ~isempty(mymodel.optimizer.modelrun.snapshots.id)
  myans=evriquestdlg('Clear existing model?', ...
    'Clear Model','Clear','Cancel','Clear');
  switch myans
    case {'Cancel'}
      return
  end
end

if length(varargin)==0;
  [mymodel,name,location] = lddlgpls('struct','Select Model');
else
  mymodel = varargin{1};
end

if isempty(mymodel)
  return
end

set_model(handles,mymodel);
update_callback(handles);

%--------------------------------------------------------------------
function drop(h,eventdata,handles,varargin)
%Handle a drop call.

myobj = varargin{1};
mytyp = class(myobj);

switch(mytyp)
  case 'evrimodel'
    %Save via modeloptimizer and run load logic.
    loadmodel(h,eventdata,handles,myobj)
end

%---------------------------------------------------------------------
function dropCallbackFcn(obj,ev,varargin)
%Parse dnd action.

handles = guihandles(varargin{1});

if nargin<3 | length(varargin)<3
  %Drop not coming from recognized location.
  return
end

fig = varargin{1};
parent = varargin{2};%Tree being dropped on.
context = varargin{3};%Type of DnD action, dragin dragon dragexit drop.

if strcmp(context,'drop')
  dropdata = drop_parse(obj,ev,'',struct('getcacheitem','on','concatenate','on'));
  if isempty(dropdata{1})
    %Possible error of dropdata.
    return
  end
  
  %If it's a model from cache or from workspace then try to load.
  if (strcmpi(dropdata{end,1},'model') | strcmpi(dropdata{end,1},'file')) &...
      ismodel(dropdata{end,2})
    mod = dropdata{end,2};
    if strcmp(mod.MODELTYPE,'MODELOPTIMIZER')
      loadmodel(fig,[],guihandles(fig),mod)
    else
      modeloptimizer('snapshot',mod);
    end
  end
  update_callback(handles);
end

%--------------------------------------------------------------------
function clear_Callback(h,eventdata,handles,varargin)
%Clear one or more items in gui.

item = varargin{1};

switch item
  case 'model'
    modeloptimizer('clear')
    update_callback(handles)
end

resize_callback(h,eventdata,handles)

%--------------------------------------------------------------------
function save_callback(h,eventdata,handles,varargin)
%Save table or image to file/workspace.

obj = [];
nm = '';
switch varargin{1}
  case 'model'
    obj = get_model;
    nm = 'optimizer Model';
end

if ~isempty(obj)
  svdlgpls(obj,['Save ' nm],nm)
end

%--------------------------------------------------------------------
function editoptions(h, eventdata, handles, varargin)
%Edit options using optionsGUI for current analysis.

if nargin<4 | isempty(varargin{1})
  varargin{1} = 'gui';
end

switch varargin{1}
  case 'gui'
    opts = getappdata(handles.modeloptimizergui,'gui_options');
    outopts = optionsgui(opts);
    if ~isempty(outopts)
      setappdata(handles.modeloptimizergui,'gui_options',outopts);
      if ~strcmp(opts.renderer,outopts.renderer)
        %Change renderer.
        set(handles.modeloptimizergui,'renderer',outopts.renderer);
      end
    end
    
  case 'function'
    opts = getappdata(handles.modeloptimizergui,'fcn_options');
    outopts = optionsgui(opts);
    if ~isempty(outopts)
      setappdata(handles.modeloptimizergui,'fcn_options',outopts);
    end
end
update_callback(handles)

%--------------------------------------------------------------------
function mymodel = get_model(handles)
%Get model from appdata. If model location is changed in the future this
%will make it easier to accomodate.
pause(.01);drawnow; %Flush things so optimizer can get saved/updated.
mymodel = modeloptimizer('get_optimizer');

%--------------------------------------------------------------------
function mymodel = set_model(handles,newmodel)
%Set model from appdata. If model location is changed in the future this
%will make it easier to accomodate.

modeloptimizer('save_optimizer',newmodel);

%--------------------------------------------------------------------
function update_callback(handles)
%Update GUI.
update_tree(handles)
update_table(handles)
%update_statusbar(handles)
update_display(handles)

%-----------------------------------------------
function propupdateshareddata(h,myobj,keyword,userdata,varargin)
%Input 'h' is the  handle of the subscriber object.
%The myobj variable comes in with the following structure.
%
%   id       - unique id of object.
%   myobj    - shared data (object).
%   keyword  - keyword for what was updated (may be empty if nothing specified
%   userdata - additional data associated with the link by user

%-----------------------------------------------
function updateshareddata(h,myobj,keyword,userdata,varargin)
%Input 'h' is the  handle of the subscriber object.
%The myobj variable comes in with the following structure.
%
%   id           - unique id of object.
%   object       - shared data (object).
%   properties   - structure of "properties" to associate with shared data.

if isempty(keyword); keyword = 'Modify'; end

if strcmpi(keyword,'modify') |strcmpi(keyword,'include')
  %Update image and recalc.
  handles = guihandles(h);
  newdata = myobj.object;
  setappdata(handles.modeloptimizergui,'data',newdata);
  update_callback(handles.modeloptimizergui, [], handles)
end

%--------------------------------------------------------------------
function set_SDO(handles)
%Set image into SDO and appdata, change shareddata to reflect new image.

%Set shareddata.
myobj = getshareddata(handles.modeloptimizergui);
if ~isempty(myobj)
  %If somehow more than one object make sure use first.
  myobj = myobj{1};
end

mydata = getappdata(handles.modeloptimizergui,'data');

if isempty(myobj)
  if~isempty(mydata)
    %Adding for the first time.
    myprops.itemType = 'modeloptimizergui_data';
    myprops.itemIsCurrent = 1;
    myprops.itemReadOnly = 0;
    myid = setshareddata(handles.modeloptimizergui,mydata,myprops);
    linkshareddata(myid,'add',handles.modeloptimizergui,'modeloptimizergui');
  else
    %Don't add an empty data object.
  end
else
  if ~isempty(mydata)
    %Update shareddata.
    setshareddata(myobj,mydata,'update');
  else
    %Set to empty = clear shareddata.
    removeshareddata(myobj,'standard');
  end
end

%------------------------------------------------
function nodes = get_default_nodes(handles,flavor)
%Create node structure for adjustng tree view and modelcache settings. Make
%sure value strings are named exactly as menu items in GUI because we use
%those names to find callback.
%Flavor = 'snapshot' or 'models'

%TODO: Add icons for snapshot and combi to tree.

if nargin<2
  flavor = [];
end

mymodel = get_model;
myit    = mymodel.optimizer;
nodes = [];

if isempty(flavor) | strcmp(flavor,'snapshot')
  nodes(end+1).val = 'snapshot';
  nodes(end).nam = 'snapshot';
  nodes(end).str = 'Snapshots';
  nodes(end).icn = which('model.gif');
  nodes(end).isl = false;
  nodes(end).chd = getsnapshotnodes(handles,'snapshot',myit.snapshots);
  
  nodes(end+1).val = 'independent';
  nodes(end).nam = 'independent';
  nodes(end).str = 'Combinations';
  nodes(end).icn = which('model.gif');
  nodes(end).isl = false;
  [inodes,totalvals] = getindysturct('independent',myit.combinations);
  nodes(end).chd = inodes;
  if totalvals>1
    nodes(end).str = ['Combinations (' num2str(totalvals) ')'];
  end
end

if isempty(flavor) | strcmp(flavor,'models')
  nodes(end+1).val = 'runs';
  nodes(end).nam = 'runs';
  nodes(end).str = 'Models';
  nodes(end).icn = which('model.gif');
  nodes(end).isl = false;
  nodes(end).chd = getrunsturct(handles,'runs',myit.modelrun);
end

make_data_table(handles)

%-----------------------------------------------------------------
function [nodes,totalvals] = getindysturct(parent,mystruct)
%Get combination (independent) nodes.

nodes = [];
myvals = {'Ncomp/LVs' 'ncomp';'X-Preprocessing' 'xpreprocessing'; 'Y-Preprocessing' 'ypreprocessing';'Options' 'options'; 'Cross Validation' 'cvi'; 'X Data' 'xdata_cacheid'; 'Y Data' 'ydata_cacheid'};
%optionfields = {'algorithm' 'confidencelimit' 'orthogonalize'};
totalvals = 1;
for i = 1:length(mystruct)
  nodes(i).val = [parent '/' mystruct(i).id];
  nodes(i).nam = mystruct(i).id;
  nodes(i).str = ['Combination ' sprintf('%d',i)];
  nodes(i).icn = '';
  nodes(i).isl = false;
  nodes(i).chd = [];
  if ~isempty(mystruct(i).id)
    for j = 1:size(myvals,1)
      myval = mystruct(i).(myvals{j,2});
      mysz = length(myval);
      if mysz>0
        totalvals = totalvals*mysz;
      end
      mysz = num2str(mysz);
      if isempty(nodes(i).chd)
        nodes(i).chd = makenode(parent,myvals{j,2},['(' mysz ') '  myvals{j,1}],'',true);
      else
        nodes(i).chd(j) = makenode(parent,myvals{j,2},['(' mysz ') '  myvals{j,1}],'',true);
      end
      
    end
    %NOTE: Comment out the line below if we want to enable sets again.
    nodes = nodes(i).chd;
  else
    nodes(i).str = 'Empty';
    nodes(i).isl = true;
  end
end

%-----------------------------------------------------------------
function nodes = getrunsturct(handles,parent,mystruct)
%Get run nodes.

for i = 1:length(mystruct)
  nodes(i).val = [parent '/' mystruct(i).id];
  nodes(i).nam = mystruct(i).id;
  
  myname = mystruct(i).run_name;
  if isempty(myname)
    myname = ['Run ' sprintf('%d',i)];
  end
  
  nodes(i).str = myname;
  nodes(i).icn = '';
  nodes(i).isl = false;
  if ~isempty(mystruct(i).id)
    %nodes(i).chd = getsnapshotnodes(handles,nodes(i).val,mystruct(i).snapshots);
    %NOTE: Comment out the line below if we want to enable sets again.
    nodes = getsnapshotnodes(handles,parent,mystruct(i).snapshots);
  else
    nodes(i).str = 'Empty';
    nodes(i).isl = true;
  end
end

%-----------------------------------------------------------------
function nodes = getsnapshotnodes(handles,parent,mystruct)
%Get snapshot nodes.

%Make persistent variable cache for modelcache items so save overhead of
%looking them up every time the tree is refreshed.

persistent datanodesx datanodesy

if isempty(datanodesx)
  datanodesx = {'' []};
end

if isempty(datanodesy)
  datanodesy = {'' []};
end

nodes = [];

%Node names.
myvals = {'Model Type' 'modeltype'; 'Ncomp/LVs' 'ncomp';'X-Preprocessing' 'xpreprocessing';...
  'Y-Preprocessing' 'ypreprocessing';'Options' 'options'; 'Cross Validation' 'crossval';...
  'X Data' 'xdata'; 'Y Data' 'ydata'};

gopts     = getappdata(handles.modeloptimizergui, 'gui_options');
optionfields = gopts.options_fields;

parentlabel = 'Snapshot';
if strcmpi(parent,'runs')
  parentlabel = 'Model';
end

for i = 1:length(mystruct)
  nodes(i).val = [parent '/' mystruct(i).id];
  nodes(i).nam = mystruct(i).id;
  nodes(i).str = [parentlabel ' ' sprintf('%d',i)];
  nodes(i).icn = '';
  nodes(i).isl = false;
  if ~isempty(mystruct(i).id)
    for j = 1:size(myvals,1)
      
      %Make leaf nodes.
      if strcmp(myvals{j,2},'modeltype')
        mname = upper(mystruct(i).options.functionname);
        nodes(i).chd(j) = makenode(nodes(i).val,myvals{j,2},[myvals{j,1} ' = ' mname],'',true);
        continue
      end
      
      if strcmp(myvals{j,2},'ncomp')
        nodes(i).chd(j) = makenode(nodes(i).val,myvals{j,2},[myvals{j,1} ' = ' num2str(mystruct(i).ncomp)],'',true);
        continue
      end
      
      if strcmp(myvals{j,2},'xpreprocessing')
        ppstr = getppstring(mystruct(i).xpreprocessing);
        nodes(i).chd(j) = makenode(nodes(i).val,myvals{j,2},['X Preprocessing = [' ppstr ']'],'',true);
        continue
      end
      
      if strcmp(myvals{j,2},'ypreprocessing')
        ppstr = getppstring(mystruct(i).ypreprocessing);
        nodes(i).chd(j) = makenode(nodes(i).val,myvals{j,2},['Y Preprocessing = [' getppstring(mystruct(i).ypreprocessing) ']'],'',true);
        continue
      end
      
      %Make parent>leaf nodes.
      nodes(i).chd(j) = makenode(nodes(i).val,myvals{j,2},myvals{j,1},'',false);
      switch myvals{j,2}
        case 'options'
          mychild = 1;
          for k = 1:length(optionfields)
            if isfield(mystruct(i).options,optionfields{k,2})
              subnodes = makenode(nodes(i).chd(j).val,'algorithm',[upper(optionfields{k,2}) ' = ' num2str(mystruct(i).options.(optionfields{k,2}))],'',true);
              if mychild==1;
                nodes(i).chd(j).chd = subnodes;%Changing datatypes so need direct assign because can't index into empty array.
              else
                nodes(i).chd(j).chd(mychild) = subnodes;
              end
              mychild = mychild+1;
            end
          end
        case 'crossval'
          mycvi = mystruct(i).cvi;
          if ~iscell(mycvi)
            mycvi = {'custom' '' ''};
          end
          nodes(i).chd(j).chd = makenode(nodes(i).chd(j).val,'method',['Method = ' mycvi{1}],'',true);
          if length(mycvi{2})>1
            cvi2str = '[Vector]';
          else
            cvi2str = num2str(mycvi{2});
          end
          nodes(i).chd(j).chd(2) = makenode(nodes(i).chd(j).val,'split',['Split = ' cvi2str],'',true);
          nodes(i).chd(j).chd(3) = makenode(nodes(i).chd(j).val,'iteration',['Iteration = ' num2str(mycvi{3})],'',true);
        case 'xdata'
          xdatmsg = '';
          if isempty(mystruct(i).xdata_cacheid)
            mynode = [];
            xdatmsg = 'none';
            nodes(i).chd(j) = makenode(nodes(i).val,myvals{j,2},['X Data (none)'],'',true);
            continue
          else
            %Since we may be cycling over several x blocks keep a cache
            %around so we don't have to do expensive node build for each
            %iteration.
            mynodeindex = ismember(datanodesx(:,1),mystruct(i).xdata_cacheid);
            if ~any(mynodeindex)
              %don't have this one yet
              mynode = get_data_node(mystruct(i).xdata_cacheid);
              datanodesx(end+1,1:2) = {mystruct(i).xdata_cacheid mynode};
            else
              mynode = datanodesx{mynodeindex,2};
            end
            
            if isempty(mynode)
              if isempty(xdatmsg)
                xdatmsg = 'not found';
              end
              nodes(i).chd(j) = makenode(nodes(i).val,myvals{j,2},['X Data (' xdatmsg ')'],'',true);
            else
              nodes(i).chd(j).chd = mynode;
            end
          end
        case 'ydata'
          ydatmsg = '';
          if isempty(mystruct(i).xdata_cacheid)
            mynode = [];
            ydatmsg = 'none';
            nodes(i).chd(j) = makenode(nodes(i).val,myvals{j,2},['Y Data (none)'],'',true);
            continue
          else
            if isempty(mystruct(i).ydata_cacheid)
              mynode = [];
            else
              mynodeindexy = ismember(datanodesy(:,1),mystruct(i).ydata_cacheid);
              if ~any(mynodeindexy)
                %don't have this one yet
                mynode = get_data_node(mystruct(i).ydata_cacheid);
                datanodesy(end+1,1:2) = {mystruct(i).ydata_cacheid mynode};
              else
                mynode = datanodesy{mynodeindexy,2};
              end
            end
            
            if isempty(mynode)
              if isempty(ydatmsg)
                ydatmsg = 'not found';
              end
              nodes(i).chd(j) = makenode(nodes(i).val,myvals{j,2},['Y Data (' ydatmsg ')'],'',true);
              continue
            else
              nodes(i).chd(j).chd = mynode;
            end
          end
      end
    end
  else
    nodes(i).str = 'Empty';
    nodes(i).isl = true;
  end
  
  if (strcmpi(parent,'runs') | strcmpi(parent,'snapshot')) & isfield(nodes(i),'chd')
    removenode = makenode(nodes(i).val,'remove','Remove',which('close.gif'),true);
    nodes(i).chd = [removenode nodes(i).chd];
  end
  
end

%------------------------------------------
function make_data_table(handles)
%Make the Compare Models table from models runs.

persistent datanodesx datanodesy

if isempty(datanodesx)
  datanodesx = {'' []};
end

if isempty(datanodesy)
  datanodesy = {'' []};
end

mymodel   = get_model;
gopts     = getappdata(handles.modeloptimizergui, 'gui_options');
modelruns = mymodel.optimizer.modelrun;
mystruct  = modelruns.snapshots;

%Encode column headings.
myvals = {'Model Type' 'modeltype'; 'Ncomp/LVs' 'ncomp';...
  'CV Method' 'cvmethod'; 'CV Splits' 'cvsplit'; 'CV Iterations' 'cviter';...
  'X-Preprocessing' 'xpreprocessing'; 'Y-Preprocessing' 'ypreprocessing';...
  'X Data' 'xdata'; 'X Include Size' 'xdatainclude';...
  'Y Data' 'ydata'; 'Y Include Size' 'ydatainclude';...
  'Error Message' 'errormsg';...
  'Nodes 1st layer' 'nhid1'; 'Nodes 2nd layer' 'nhid2'};

colNames = [{'ID' 'id'; 'Model Name' 'modelname'}; myvals; gopts.options_fields];
%Need to track data type so options with mixed types can be accommodated in
%table. Only tracking option DT for now so most of the cell array will just
%be empty but will match in size to number of columns.
datatypes = cell(size(colNames,1),1);

mytable = cell(1,size(colNames,1));

%Make persistent list of data so don't have to query cache on duplicates.  
datanodes = {'' []};

for i = 1:length(mystruct)
  if ~isempty(mystruct(i).id)
    for j = 1:size(colNames,1)
      switch colNames{j,2}
        case 'id'
          mytable{i,j} = mystruct(i).id;
        case 'modelname'
          mytable{i,j} = ['Model ' sprintf('%d',i)];
        case 'modeltype'
          mytable{i,j} = upper(mystruct(i).options.functionname);
        case 'ncomp'
          % Only enter ncomp values for these factor-based model types:
          if ismember(lower(mystruct(i).options.functionname), {'pca' 'mpca' 'plsda' 'pls' 'npls' 'pcr'})
            mytable{i,j} = mystruct(i).ncomp;
          else
            mytable{i,j} = [];
          end
        case 'nhid1'
          % Only enter option.nhid1 values for these  model types:
          if ismember(lower(mystruct(i).options.functionname), { 'ann' 'annda'})
            mytable{i,j} = mystruct(i).options.nhid1;
          else
            mytable{i,j} = [];
          end
        case 'nhid2'
          % Only enter option.nhid2 values for these  model types:
          if ismember(lower(mystruct(i).options.functionname), { 'ann' 'annda'})
            mytable{i,j} = mystruct(i).options.nhid2;
          else
            mytable{i,j} = [];
          end

        case 'xpreprocessing'
          mytable{i,j} = getppstring(mystruct(i).xpreprocessing);
        case 'ypreprocessing'
          mytable{i,j} = getppstring(mystruct(i).ypreprocessing);  
        case {'cvmethod' 'cvsplit' 'cviter'}
          mycvi = mystruct(i).cvi;
          if ~iscell(mycvi)
            mycvi = {'custom' [] []};
          end
          switch colNames{j,2}
            case 'cvmethod'
              mytable{i,j} = mycvi{1};
            case 'cvsplit'
              if length(mycvi{2})>1
                mytable{i,j} = '[vector]';
              else
                if i>1 & isnumeric(mycvi{2}) & ischar(mytable{i-1,j})
                  mytable{i,j} = num2str(mycvi{2});
                else
                  mytable{i,j} = mycvi{2};
                end
              end
            case 'cviter'
            mytable{i,j} = mycvi{3};
          end
          
        case {'xdata' 'xdatainclude'}
          if isempty(mystruct(i).xdata_cacheid)
            mytable{i,j} = '';
          else
            %Since we may be cycling over several x blocks keep a cache
            %around so we don't have to do expensive node build for each
            %iteration.
            mynodeindex = ismember(datanodesx(:,1),mystruct(i).xdata_cacheid);
            if ~any(mynodeindex)
              %don't have this one yet
              mynode = get_data_node(mystruct(i).xdata_cacheid);
              datanodesx(end+1,1:2) = {mystruct(i).xdata_cacheid mynode};
            else
              mynode = datanodesx{mynodeindex,2};
            end
            
            if ~isempty(mynode)
              if strcmp(colNames{j,2},'xdata')
                %Raw x data size.
                mysz = sprintf('%d x ',str2num(strrep(mynode(4).str,'Size: ','')));
                mytable{i,j} = mysz(1:end-3);
              else
                %X data include size.
                mysz = sprintf('%d x ',str2num(strrep(mynode(5).str,'Include Size: ','')));
                mytable{i,j} = mysz(1:end-3);
              end
            end
          end
        case {'ydata' 'ydatainclude'}
          
          if isempty(mystruct(i).ydata_cacheid)
            mynode = [];
          else
            mynodeindexy = ismember(datanodesy(:,1),mystruct(i).ydata_cacheid);
            if ~any(mynodeindexy)
              %don't have this one yet
              mynode = get_data_node(mystruct(i).ydata_cacheid);
              datanodesy(end+1,1:2) = {mystruct(i).ydata_cacheid mynode};
            else
              mynode = datanodesy{mynodeindexy,2};
            end
          end
          
          if ~isempty(mynode)
            if strcmp(colNames{j,2},'ydata')
              %Raw y data size.
              mysz = sprintf('%d x ',str2num(strrep(mynode(4).str,'Size: ','')));
              mytable{i,j} = mysz(1:end-3);
            else
              %Y data include size.
              mysz = sprintf('%d x ',str2num(strrep(mynode(5).str,'Include Size: ','')));
              mytable{i,j} = mysz(1:end-3);
            end
          end
        case 'errormsg'
          if isfield(mystruct(i), 'errormsg')
            mytable{i,j} = mystruct(i).errormsg;
          end
        otherwise
          try
            %Should be an option field but wrap in try/catch so it doesn't
            %bomb if an option screwed up.
            if isfield(mystruct(i).options,colNames{j,2})
              %First level options is most likely.
              myval = mystruct(i).options.(colNames{j,2});
              if i>1 & isnumeric(myval) & ischar(mytable{i-1,j})
                %Different data type so switch to string.
                mytable{i,j} = num2str(mystruct(i).options.(colNames{j,2}));
              else
                mytable{i,j} = mystruct(i).options.(colNames{j,2});
              end
            elseif isfieldcheck(mystruct(i).options,['.' colNames{j,2}])
              %Next, check for sub field.
              mytable{i,j} = getsubstruct(mystruct(i).options, colNames{j,2});
            elseif isfield(mystruct(i),colNames{j,2})
              %Lastly, check for first level of snapshot struct.
              myval = mystruct(i).(colNames{j,2});
              if i>1 & isnumeric(myval) & ischar(mytable{i-1,j})
                mytable{i,j} = num2str(mystruct(i).(colNames{j,2}));
              else
                mytable{i,j} = mystruct(i).(colNames{j,2});
              end
            end
          end
      end
    end
  end
end

setappdata(handles.modeloptimizergui,'run_table_columns',colNames(:,1));
setappdata(handles.modeloptimizergui,'run_table',mytable);

%------------------------------------------
function predesc = getppstring(pp)
%Get preprocessing string.

if ~isempty(pp)
  predesc = [pp(1).description];
  for i = 2:length(pp)
    predesc = [predesc ' , ' pp(i).description];
  end
else
  predesc = ['X: ' 'none'];
end

%------------------------------------------
function datanode = get_data_node(myid)
%Get data nodes from cachestruct.

if ~isempty(myid)
  cobj = evricachedb;
  sourceitem = getcacheindex(cobj,myid,1);
  datanode = cachestruct('cacheobjinfo','data', sourceitem);
end

%-----------------------------------------------------------------
function node = makenode(parent,val,str,icn,isl)
%Make a simple node.

node.val = [parent '/' val];
node.nam = val;
node.str = str;
node.icn = icn;
node.isl = isl;
node.chd = [];
node.clb = 'modeloptimizergui';

%-----------------------------------------------------------------
function update_after_sort(fig)
%Update display after a column sort.
handles = guihandles(fig);
update_display(handles);

%-----------------------------------------------------------------
function update_tree(handles)
%Update tree data.

mnodes  = get_default_nodes(handles,'models');
mtree = getappdata(handles.modeloptimizergui,'modeltree');
mtree.tree_data = mnodes;

snodes  = get_default_nodes(handles,'snapshot');
stree = getappdata(handles.modeloptimizergui,'sstree');
stree.tree_data = snodes;

%drawnow; pause(.1)
%expandrow(mtree,0)
%expandrow(stree,0)

drawnow; pause(.1)
expandtoleaf(mtree,mnodes(1).nam);%Expand snapshots.
expandtoleaf(stree,snodes(1).nam);%Expand combinations.
expandtoleaf(stree,snodes(2).nam);%Expand runs.
drawnow; pause(.1)
mtree.root_visible = 'off';
stree.root_visible = 'off';

mtree.root_handles_show = 'on';
stree.root_handles_show = 'on';

%--------------------------------------------------------------------
function update_display(handles)
%update cell coloring on table.

%Get options for hiding columns.
gopts = getappdata(handles.modeloptimizergui, 'gui_options');

if ~strcmpi(gopts.color_table,'on')
  return
end

%Get data.
mytable   = getappdata(handles.modeloptimizergui,'comparetable');
thistable = mytable.data;

if size(thistable,1)==1
  %Can't color.
  return
end

%Can't remember why I put this background to white before coloring. Costs a
%lot of time so comment out for now and remove if there are no problems.
%setbackground(mytable,'table',[],'white')

cm = getcolormat(gopts.cell_colormap);
cm = cm([1:100],:);
%TODO: May need specific cm direction for columns.

for i = 1:size(thistable,2)
  thiscol = thistable(:,i);
  emptycol  = cellfun('isempty',thiscol);
  isnumcol  = cellfun(@isnumeric,thiscol(~emptycol));
  firstclass = class(thiscol{1});
  if all(isnumcol)
    %Numeric.
    if any(emptycol)
      thiscol(emptycol) = repmat({0},sum(emptycol),1);
    end
    thiscol = normaliz([thiscol{:}],[],inf);
  else
    if any(emptycol)
      thiscol(emptycol) = repmat({' '},sum(emptycol),1);
    end
    if ~strcmp(firstclass,'logical')
      [C,ia,thiscol] = unique(thiscol);
      if all(thiscol==1)
        %If column all the same value then change to zero so it shows as
        %white.
        thiscol = zeros(length(thiscol),1);
      end
      thiscol = normaliz(thiscol',[],inf);
    else
      thiscol = zeros(length(thiscol),1);
    end
  end
  if ~strcmp(firstclass,'logical')
    crow = max(round(thiscol*100),1);%Color row;
    crow = min(crow,100);
    column_colormap = cm(crow,:);
    setbackground(mytable,'column',i,column_colormap);
  end
end

%--------------------------------------------------------------------
function mycm = getcolormat(ctype)
%Get color map.

switch ctype
  case 'autumn'
    mycm = autumn(250);
  case 'bone'
    mycm = bone(250);
  case 'colorcube'
    mycm = colorcube(250);
  case 'cool'
    mycm = cool(250);
  case 'copper'
    mycm = copper(250);
  case 'flag'
    mycm = flag(250);
  case 'gray'
    mycm = gray(250);
  case 'hot'
    mycm = hot(250);
  case 'hsv'
    mycm = hsv(250);
  case 'jet'
    mycm = jet(250);
  case 'lines'
    mycm = lines(250);
  case 'pink'
    mycm = pink(250);
  case 'prism'
    mycm = prism(250);
  case 'rwb'
    mycm = rwb(250);
  case 'spring'
    mycm = spring(250);
  case 'summer'
    mycm = summer(250);
  case 'white'
    mycm = white(250);
  case 'winter'
    mycm = winter(250);
  otherwise
    mycm = bone(250);
end

mycm = flipud(mycm);

%--------------------------------------------------------------------
function cleanplots(handles,hh)
%Remove all lables and ticks from plots. Input 'hh' is vector of handles.
set(hh,'XTickLabel','','YTickLabel','','ZTickLabel','','XTick',[],'YTick',[],'ZTick',[],'XColor','white','YColor','white','ZColor','white')

%--------------------------------------

function update_pred(handles)
% Update the rmsep column
gopts = getappdata(handles.modeloptimizergui, 'gui_options');
mymodel = get_model;
myit    = mymodel.optimizer;
mytable = getappdata(handles.modeloptimizergui,'comparetable');

% code to find unbuilt models and ask user if unbuilt models should be built 
ridx = length(myit.modelrun);
modcount = length(myit.modelrun(ridx).snapshots);
myexst = cell(1,modcount);
for bb = 1:modcount
  myexst(bb) = modelcache('exist',safename(myit.modelrun(ridx).snapshots(bb).modelID));%Make sure item is in cache.
end
notBuilt = cell2mat(myexst);

if find(notBuilt==0)
  need_toBuild = 1;
else
  need_toBuild = 0;
end

if need_toBuild % there are unbuilt models in table
  myquestion = sprintf(['There are snapshots that have not been built in the Model Optimizer table.\n'...
'Would you like to build these models and continue applying models to the validation data?']);
  buttonPressed = evriquestdlg(myquestion,...
    'Unbuilt Models Detected',...
    'Yes',...
    'No',...
    'Yes');
  
  switch buttonPressed
    case 'Yes'
      buttonpush('','',handles,'run_all'); % build unbuilt models
      update_pred(handles);
      return
    case 'No'
      need_toBuild = 0;
  end
end
mylist = [{myit.modelrun.snapshots.id}' {myit.modelrun.snapshots.modelID}'];
[columnkeys, columnlabels, tablevalues] = comparemodels(mylist(:,2),struct('plots','none'));
typeIndex = contains(columnkeys,'modeltype');
modTypes = tablevalues(:,typeIndex);

isClassificationModel = checkIfClassification(modTypes);

if ~need_toBuild
  xdata = lddlgpls({'double' 'dataset'},'Load Validation X-Block');
  if ~all(isClassificationModel)
    ydata = lddlgpls({'double' 'dataset'},'Load Validation Y-Block');
  else
    ydata = [];
  end
end
% Need to check that data has the correct number of variables.  
if isempty(xdata)
  return
end
if ~all(isClassificationModel)
  if isempty(ydata)
    return
  end
end

%If user loaded manually then it could be a double so convert to dataset so
%size check below doesn't fail.
if ~isdataset(xdata)
  xdata = dataset(xdata);
end

if ~all(isClassificationModel)
  if ~isdataset(ydata)
    ydata = dataset(ydata);
  end
end

if ~all(isClassificationModel)
  if xdata.size(1) ~= ydata.size(1)
    erdlgpls('Selected valiation blocks have different number of samples.  Select x and y blocks with equal number of samples');
    return;
  end
end

%ID NCOMP XPP YPP XSIZE XINCD YSIZE YINCD CVMethod CVSplit CVIter
mycolumns = getappdata(handles.modeloptimizergui,'run_table_columns')';
update_column_list(handles,mycolumns);
data_table = getappdata(handles.modeloptimizergui,'run_table');%Table object.
tsize      = size(data_table);

%Run comparemodels (function is quick).
%mylist = [{myit.modelrun.snapshots.id}' {myit.modelrun.snapshots.modelID}'];
if isempty(mylist) | (size(mylist,1)==1 & isempty(mylist{1,1}))
  %Nothing computed yet.
  mytable.column_labels = repmat({' '},1,5);
  mytable.data = [repmat({' '},1,5)];
  return
else
  runidx = ~cellfun('isempty',mylist(:,2));
  if any(runidx)
    %Concat compare model results.
    [columnkeys, columnlabels, tablevalues] = comparemodels(mylist(runidx,2),struct('plots','none'));
    
    idind = ismember(columnlabels,'Model ID');
    
    [preds, flag1] = modeloptimizer('calculate_preds', xdata, ydata, tablevalues(:,idind));
    if ~all(isClassificationModel)
      if size(preds{1,2},2) > 1
        multivarY = 1;
      else
        multivarY = 0;
      end
      
      if ~any(flag1)
        erdlgpls('No models have the same number of variables as selected validation data', 'Incorrect number of variables');
        %error('The number of variables in your selected validation data does not match the number of variables expected');
        
        return
      end
      ind=find(ismember(columnlabels,'RMSEP (Pred)'));
      % tablevalues
      for i = 1:size(tablevalues,1)
        if flag1(i) ==0
          tablevalues{i,ind} = nan;
        elseif multivarY
          tablevalues{i,ind} = sprintf('%3.3g ', preds{i,2});
        else
          tablevalues{i,ind} = preds{i,2};
        end
      end
    else
      if isempty(preds)
        errordlg('No class information in validation set','No Class Information');
        return;
      end
      inds=find(ismember(columnkeys,{'fppred' 'fnpred' 'erpred' 'ppred' 'fpred'}));
      for i = 1:size(tablevalues,1)
        myValues = preds{i,2};
        %       'fppred' 'Avg. False Pos. Rate (Pred)'  []
        %       'fnpred' 'Avg. False Neg. Rate (Pred)'  []
        %       'erpred' 'Error Rate (Pred)'            []
        %       'ppred'  'Precision (Pred)'             []
        %       'fpred'  'F1 Score (Pred)'              []
        tablevalues{i,inds(1)} = myValues(1);
        tablevalues{i,inds(2)} = myValues(2);
        tablevalues{i,inds(3)} = myValues(3);
        if isnan(myValues(4))
          tablevalues{i,inds(4)} = 'NaN';
        else
          tablevalues{i,inds(4)} = myValues(4);
        end
        if isnan(myValues(5))
          tablevalues{i,inds(5)} = 'NaN';
        else
          tablevalues{i,inds(5)} = myValues(5);
        end
        
      end
    end
    
    if ~isempty(columnkeys)
      remcols = ~ismember(columnkeys,{'ncomp' 'preprox' 'preproy' 'uniqueid' 'modeltype' 'lwr_npts' 'lwr_algor'});
      %Save the available columns so we can allow user to modify columns that
      %are shown.
      update_column_list(handles,[mycolumns columnlabels(remcols)]);
      
      ucol       = ismember(columnkeys,{'uniqueid'});
      data_table = [data_table cell(tsize(1),length(find(remcols)))];
      for i = 1:size(tablevalues,1)
        %Find index for modelid in tablevalues and map back to thistable.
        mylist(~runidx,2) = repmat({''},sum(~runidx),1);%Make sure empties are strings so ismember works below.
        myrow = ismember(mylist(:,2),tablevalues(i,ucol));
        data_table(myrow,tsize(2)+1:end) = tablevalues(ones(sum(myrow),1)*i,remcols);
      end
      mycolumns = [mycolumns columnlabels(remcols)];
    end
  end
end

showcols = ones(1,size(data_table,2));

%TODO: Disable filter so show all fields when only one model.
if tsize(1)>1
  if strcmpi(gopts.hide_emptycols,'on')
    %Check for empty columns and remove.
    for i = 1:size(data_table,2)
      empt = cellfun('isempty',data_table(:,i));
      if all(empt)
        showcols(i) = 0;
      end
    end
  end
  
  if strcmpi(gopts.hide_repcols,'on')
    %Check for columns with all same value and remove.
    for i = 1:size(data_table,2)
      thiscol = data_table(:,i);
      empt = cellfun('isempty',thiscol);
      isch = cellfun('isclass',thiscol,'char');
      if any(isch)
        thiscol(empt) = repmat({''},sum(empt),1);
        sameval = unique(thiscol);
      elseif isnumeric(data_table{1,i})
        sameval = unique([data_table{:,i}]);
      else
        %Can't figure out datatype.
        sameval = [1 1];
      end
      if length(sameval)<2
        if ~any(empt)
          showcols(i) = 0;
        end
      end
    end
  end
end

%Remove/add columns based on options.
ecol = gopts.exclude_columns;
icol = gopts.include_columns;
[junk,icolidx] = setdiff(icol,ecol);%Don't allow exluded items in include.
icol = icol(sort(icolidx));%Make sure they're in the orginal order.

if ~isempty(ecol)
  showcols(ismember(lower(mycolumns),lower(ecol))) = 0;
end

if ~isempty(icol)
  shidx = ismember(lower(mycolumns),lower(icol));
  showcols(shidx) = 1;
  %Reorder table and columns.
  shidx0 = [];
  for i = 1:length(icol)
    shidx0 = [shidx0 find(ismember(lower(mycolumns),lower(icol(i))))];
  end
  neworder = [shidx0 find(~shidx)];
  showcols  = showcols(neworder);
  data_table = data_table(:,neworder);
  mycolumns = mycolumns(neworder);
end

%ID Column is special. It always needs to be there.
idloc = ismember(lower(mycolumns),'id');
showidcol = showcols(idloc);
showcols(idloc) = 1;%Force it on.

%Update data.
data_table = data_table(:,logical(showcols));
mycolumns = mycolumns(:,logical(showcols));

%Model run column.
mcol = repmat({false},tsize(1),1);
for i = 1:size(mylist,1)
  %See if model has been run.
  myrow = ismember(mylist(:,1),data_table(i,idloc));
  if ~isempty(mylist{myrow,2})
    mcol{i} = true;
  end
end

%Add run column.
data_table = [mcol data_table];
mycolumns = [{'Built'} mycolumns];
idloc = [false idloc];%Add column so id location is correct.

%Update table.
mytable.data          = data_table;
mytable.column_labels = mycolumns;
mytable.column_format = {'bool'};

if ~showidcol
  setvisible(mytable,'columns',find(idloc),'off');
end

if strcmp(gopts.show_built,'on')
  setcolumnwidth(mytable,1,20)
else
  setvisible(mytable,'columns',1,'off');
end

%--------------------------------------------------------------------
function update_table(handles)
%Update uitable (java table).

%Get options for hiding columns.
gopts = getappdata(handles.modeloptimizergui, 'gui_options');

mymodel = get_model;
myit    = mymodel.optimizer;
mytable = getappdata(handles.modeloptimizergui,'comparetable');

%ID NCOMP XPP YPP XSIZE XINCD YSIZE YINCD CVMethod CVSplit CVIter
mycolumns = getappdata(handles.modeloptimizergui,'run_table_columns')';

update_column_list(handles,mycolumns);

data_table = getappdata(handles.modeloptimizergui,'run_table');%Table object.
tsize      = size(data_table);

%Run comparemodels (function is quick).
mylist = [{myit.modelrun.snapshots.id}' {myit.modelrun.snapshots.modelID}'];
if isempty(mylist) | (size(mylist,1)==1 & isempty(mylist{1,1}))
  %Nothing computed yet.
  mytable.column_labels = repmat({' '},1,5);
  mytable.data = [repmat({' '},1,5)];
  return
else
  runidx = ~cellfun('isempty',mylist(:,2));
  if any(runidx)
    %Concat compare model results.
    [columnkeys, columnlabels, tablevalues] = comparemodels(mylist(runidx,2),struct('plots','none'));
    if ~isempty(columnkeys)
      remcols = ~ismember(columnkeys,{'ncomp' 'preprox' 'preproy' 'uniqueid' 'modeltype' 'lwr_npts' 'lwr_algor', 'nhid1', 'nhid2'});
      %Save the available columns so we can allow user to modify columns that
      %are shown.
      update_column_list(handles,[mycolumns columnlabels(remcols)]);
      
      ucol       = ismember(columnkeys,{'uniqueid'});
      data_table = [data_table cell(tsize(1),length(find(remcols)))];
      for i = 1:size(tablevalues,1)
        %Find index for modelid in tablevalues and map back to thistable.
        mylist(~runidx,2) = repmat({''},sum(~runidx),1);%Make sure empties are strings so ismember works below.
        myrow = ismember(mylist(:,2),tablevalues(i,ucol));
        data_table(myrow,tsize(2)+1:end) = tablevalues(ones(sum(myrow),1)*i,remcols);
      end
      mycolumns = [mycolumns columnlabels(remcols)];
    end
  end
end

showcols = ones(1,size(data_table,2));

%TODO: Disable filter so show all fields when only one model.
if tsize(1)>1
  if strcmpi(gopts.hide_emptycols,'on')
    %Check for empty columns and remove.
    for i = 1:size(data_table,2)
      empt = cellfun('isempty',data_table(:,i));
      if all(empt)
        showcols(i) = 0;
      end
    end
  end
  
  if strcmpi(gopts.hide_repcols,'on')
    %Check for columns with all same value and remove.
    for i = 1:size(data_table,2)
      thiscol = data_table(:,i);
      empt = cellfun('isempty',thiscol);
      isch = cellfun('isclass',thiscol,'char');
      if any(isch)
        thiscol(empt) = repmat({''},sum(empt),1);
        sameval = unique(thiscol);
      elseif isnumeric(data_table{1,i})
        sameval = unique([data_table{:,i}]);
      else
        %Can't figure out datatype.
        sameval = [1 1];
      end
      if length(sameval)<2
        if ~any(empt)
          showcols(i) = 0;
        end
      end
    end
  end
end

%Remove/add columns based on options.
ecol = gopts.exclude_columns;
icol = gopts.include_columns;
[junk,icolidx] = setdiff(icol,ecol);%Don't allow exluded items in include.
icol = icol(sort(icolidx));%Make sure they're in the orginal order.

if tsize(1)==1
  %If there is only one model only show a few summary columns so it doesn't
  %look weird with tons of columns.
  ecol = lower(mycolumns);
  icol = {'model name' 'model type' 'ncomp/lvs' 'x-preprocessing' 'y-preprocessing'};
end

if ~isempty(ecol)
  showcols(ismember(lower(mycolumns),lower(ecol))) = 0;
end

if ~isempty(icol)
  shidx = ismember(lower(mycolumns),lower(icol));
  showcols(shidx) = 1;
  %Reorder table and columns.
  shidx0 = [];
  for i = 1:length(icol)
    shidx0 = [shidx0 find(ismember(lower(mycolumns),lower(icol(i))))];
  end
  neworder = [shidx0 find(~shidx)];
  showcols  = showcols(neworder);
  data_table = data_table(:,neworder);
  mycolumns = mycolumns(neworder);
end

%ID Column is special. It always needs to be there.
idloc = ismember(lower(mycolumns),'id');
showidcol = showcols(idloc);
showcols(idloc) = 1;%Force it on.

%Update data.
data_table = data_table(:,logical(showcols));
mycolumns = mycolumns(:,logical(showcols));

%Model run column.
mcol = repmat({false},tsize(1),1);
for i = 1:size(mylist,1)
  %See if model has been run.
  myrow = ismember(mylist(:,1),data_table(i,idloc));
  if ~isempty(mylist{myrow,2})
    mcol{i} = true;
  end
end

%Add run column.
data_table = [mcol data_table];
mycolumns = [{'Built'} mycolumns];
idloc = [false idloc];%Add column so id location is correct.

%Update table.
mytable.data          = data_table;
mytable.column_labels = mycolumns;
mytable.column_format = {'bool'};

if ~showidcol
  setvisible(mytable,'columns',find(idloc),'off');
end

if strcmp(gopts.show_built,'on')
  setcolumnwidth(mytable,1,20)
else
  setvisible(mytable,'columns',1,'off');
end

%-----------------------------------------------------------------
function varargout = tree_callback(varargin)
%Tree callback, highlight row in table.
% varargin{end} should be path string to node.

if ~isempty(varargin{end})
  mypath = str2cell(strrep(varargin{end},'/',char(9)));%Replace / with tab and parse with str2cell.
  handles = guihandles(varargin{3}.parent_figure);
  
  mymodel = get_model;
  myit    = mymodel.optimizer;
  if strcmpi(mypath{end},'remove')
    myid = mypath{end-1};
    if strcmpi(mypath{1},'runs')
      %Remove run.
      modeloptimizer('clear_item','model',myid)
    else
      %Remove snapshot.
      modeloptimizer('clear_item','snapshot',myid)
    end
    update_callback(handles)
    return
  end
  
  %Enable survey button if in snapshots.
  sbtn = getappdata(handles.modeloptimizergui,'surveyjbutton');
  if ~strcmpi(mypath{1},'snapshot')
    set(sbtn,'Enabled',false)
  else
    set(sbtn,'Enabled',true)
  end
  
  if ~strcmpi(mypath{1},'runs') | length(mypath)==1
    %Only work on run nodes.
    return
  end
  
  %Look for ID and highlight in table.
  mytable   = getappdata(handles.modeloptimizergui,'comparetable');
  thistable = mytable.data;
  empt      = cellfun('isempty',thistable);
  if all(empt)
    %Dont' go any further if no table is around.
    return
  end
  
  thiscols  = mytable.column_labels;
  idcol     = ismember(thiscols,'ID');
  %Second level should always be
  midx = ismember(thistable(:,idcol),mypath{2});
  lpth = length(mypath);
  while ~any(midx)
    if lpth<1
      break
    end
    midx = ismember(thistable(:,1),mypath{lpth});
    if ~any(midx)
      lpth = lpth - 1;
    else
      lpth = 0;
    end
  end
  
  %Highlight row.
  if any(midx)
    midx    = find(midx);
    mytable = getappdata(handles.modeloptimizergui,'comparetable');
    setselection(mytable,'rows',midx);
  end
end

%-----------------------------------------------------------------
function varargout = datachange_callback(varargin)
%Callback from table.

fig     = varargin{1};
handles = guihandles(fig);

%-----------------------------------------------------------------
function varargout = table_click_callback(varargin)
%Callback from table.

click_count = 1;
if nargin>1
  click_count = varargin{2};
end

fig     = varargin{1};
handles = guihandles(fig);

mymodel   = get_model;
myit      = mymodel.optimizer;
mytable   = getappdata(handles.modeloptimizergui,'comparetable');
mytree    = getappdata(handles.modeloptimizergui,'modeltree');
myrow     = getselection(mytable,'rows');
thistable = mytable.data;
thiscols  = mytable.column_labels;
idcol     = ismember(thiscols,'ID');

% thistable = getappdata(handles.modeloptimizergui,'run_table');
%
selected_IDs = thistable(myrow,idcol);

if click_count == 1
  for i = 1:length(selected_IDs)
    expandtoleaf(mytree,['runs/' selected_IDs{i}]);
  end
elseif click_count == 2
  %Open model/s.
  myidx     = ismember({myit.modelrun.snapshots.id},selected_IDs{1});
  mymodelid = myit.modelrun.snapshots(myidx).modelID;
  mymodel   = modelcache('get',mymodelid);
  afig = get_fig(handles);
  if isempty(afig); return; end
  obj = evrigui(afig);
  figure(obj.handle);
  obj.drop(mymodel);
end

%-----------------------------------------------------------------
function varargout = update_column_list(handles,mylist)
%Add new items to available columns list.

if ~isempty(mylist)
  thislist = getappdata(handles.modeloptimizergui,'available_columns');
  thislist = union(thislist,mylist);
  setappdata(handles.modeloptimizergui,'available_columns',thislist)
end

%-----------------------------------------------------------------
function varargout = get_snapshot_preprocessing(handles,myid)
%Get snapshot preprocessing iteration for preprocessing.

if isempty(myid)
  return
end

mymodel = getappdata(0,'evri_model_optimizer');
myit    = mymodel.optimizer;

myss = ismember({myit.snapshots.id},myid);
if any(myss)
  thisss = myit.snapshots(myss);
else
  evriwarndlg('Can''t find snapshot.')
  return
end

xpp = thisss.xpreprocessing;
ypp = thisss.ypreprocessing;

%May need to use this approach to figure out if y should be offered.
% opts = myit.combinations(didx).options;
% modlblank = evrimodel(opts{1}.functionname);
% isyused   = modlblank.isyused;
newpp = preprocessiterator(xpp);
if isempty(newpp) 
  %User cancel.
  return
elseif (isnumeric(newpp) & newpp==-1)
  evriwarndlg('Survey is not availbe for preprocessing methods in this snapshot. See PREPROCESSITERATOR for a list of methods that can be surveyed.',...
    'Prepocess Survey Warning');
  return
end

newpp = [newpp cell(length(newpp),1)];

modeloptimizer('copy_snapshot_newpp',myss,newpp);

update_callback(handles)

%Get snapshot.

%Get preprocessing.

%Send pp (X then Y if needed) to iteration and get back list.

%Send PP to MO/copy_snapshot_newpp

%-----------------------------------------------------------------
function isClassificationModel = checkIfClassification(modTypes)
classificationModelTypes = {'PLSDA'
  'SVMDA'
  'SIMCA'
  'ANNDA'
  'ANNDLDA'
  'KNN'
  'LREGDA'
  'LDA'
  'XGBDA'};
isClassificationModel = contains(modTypes,classificationModelTypes);


%-----------------------------------------------------------------
function out = optiondefs
defs = {
  %name                    tab              datatype        valid                            userlevel       description
  'renderer'               'Display'        'select'        {'opengl' 'zbuffer' 'painters'}  'novice'        'Figure renderer (selection will affect alpha and performance).';
  'hide_emptycols'         'Display'        'select'        {'on' 'off'}                     'novice'        'Hide columns with all empty values.';
  'hide_repcols'           'Display'        'select'        {'on' 'off'}                     'novice'        'Hide columns with all the same value.';
  'color_table'            'Display'        'select'        {'on' 'off'}                     'novice'        'Color cells in table according to value.';
  'cell_colormap'          'Display'        'select'        {'autumn' 'bone' 'colorcube' 'cool' 'copper' 'flag' 'gray' 'hot' 'hsv' 'jet' 'lines' 'pink' 'prism' 'rwb' 'spring' 'summer' 'white' 'winter'} 'novice' 'Colormap for table cells.';
  'show_built'             'Display'        'select'        {'on' 'off'}                     'novice'        'Show column indicating if model is built.';
  };
out = makesubops(defs);
