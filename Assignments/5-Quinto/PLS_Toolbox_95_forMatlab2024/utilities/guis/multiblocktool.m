function varargout = multiblocktool(varargin)
%multiblocktool Multiblock Tool build code.
% Generic code for setting up a Figure from mcode only. Use the following
% keys to search and replace.
%   tag/function = "multiblocktool"
%   title/name   = "Generic GUI"
%
%
%I/O: h = multiblocktool() %Open gui and return gui handle.
%I/O: multiblocktool(data) %Open preloaded.
%
%See also: EVGRAPH, MULTIBLOCK, PLOTGUI

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0 || ~ischar(varargin{1}) % LAUNCH GUI
  try
    %Start GUI
    h=waitbar(1,['Starting Multiblock Tool...']);
    drawnow
    %Open figure and initialize
    %fig = openfig('multiblocktool.fig','new','invisible');
    
    fig = figure('Tag','multiblocktool',...
      'NumberTitle', 'off', ...
      'HandleVisibility','callback',...
      'Integerhandle','off',...
      'Name', 'Multi-block Tool',...
      'Renderer','OpenGL',...
      'MenuBar','none',...
      'ResizeFcn','multiblocktool(''resize_callback'',gcbo,[],guihandles(gcbf))',...
      'CloseRequestFcn','try;multiblocktool(''closereq_callback'',gcbo,[],guihandles(gcbf),0);catch;delete(gcbf);end',...
      'visible','off',...
      'Units','pixels');
    
    %Set up gui controls.
    gui_enable(fig)
    
    figbrowser('addmenu',fig); %add figbrowser link
    
    %Position gui from last known position.
    positionmanager(fig,'multiblocktool');
    
    handles = guihandles(fig);
    fpos = get(handles.multiblocktool,'position');
    mpos      = getscreensize('pixels');
    % Fix a position issue on >2K screens when rendering windows.
    if ((mpos(3) > 2048) || (mpos(4) > 1080))
      mpos(3:4)=mpos(3:4)*0.4;
    end
    rhs       = fpos(1)+fpos(3)+15;
    if rhs>mpos(3)
      fpos(1) = fpos(1)+fpos(3)+15-(rhs-mpos(3));
    else
      fpos(1) = fpos(1);
    end
    
    % Clamp crossval gui within screen resolution
    if(fpos(1)+ fpos(3) > mpos(1) + mpos(3))
      fpos(1) = mpos(3) - fpos(3) - (0.1*mpos(3));
    end
    if(fpos(2)+ fpos(4) > mpos(2) + mpos(4))
      fpos(2) = mpos(4) - fpos(4) - (0.1*mpos(4));
    end
    if(fpos(1)<mpos(1))
      fpos(1)=mpos(1) + (0.1*mpos(1));
    end
    if(fpos(2)<mpos(2))
      fpos(2)=mpos(2) + (0.1*mpos(2));
    end
    set(fig,'Position',fpos);
    
    pause(.1);drawnow
    set(fig,'visible','on');
    drawnow;
    
    %Set scale of view.
    toolbar_Callback(handles.zoomwin, [], handles)
    
    resize_callback(fig,[],handles);
    
    %Get data if passed.
    if nargin>0 && ~isempty(varargin{1})
      loaddata(fig,[],handles,'auto',varargin{:});
    end
  catch
    if ishandle(fig); delete(fig); end
    if ishandle(h); close(h);end
    erdlgpls({'Unable to start the Multiblock Tool GUI' lasterr},[upper(mfilename) ' Error']);
  end
  
  if ishandle(h)
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

%Get handles and save options.
handles = guihandles(fig);
gopts = multiblocktool('options');

%Set persistent options.
fopts = multiblock('options');
fopts.display = 'off';
fopts.plots   = 'none';

%Save options.
setappdata(fig,'gui_options',gopts);
setappdata(fig,'fcn_options',fopts);

%Set apply mode.
setappdata(handles.multiblocktool,'applymode',0)

%Get position.
figpos = get(fig,'position');
figcolor = [.92 .92 .92];
set(fig,'Color',figcolor,'Renderer',gopts.renderer);

%Add drag drop handler.
figdnd = evrijavaobjectedt(DropTargetList);%EVRI Custom drop target class.
figdnd = handle(figdnd,'CallbackProperties');
jFrame = get(handle(handles.multiblocktool),'JavaFrame');
%Don't think we need to run on EDT but if the need arises be sure to
%accommodate 7.0.4.
jAxis  = jFrame.getAxisComponent;
jAxis.setDropTarget(figdnd);
set(figdnd,'DropCallback',{@dropCallbackFcn,handles.multiblocktool});


%Set extra fig properties.
set(fig,'Toolbar','none')

%Add menu items.
hmenu = uimenu(fig,'Label','&File','tag','menu_file','callback','multiblocktool(''filemenu_callback'',gcbo,guidata(gcbf))');

lmenu = uimenu(hmenu,'Label','&Load Data','tag','load_menu');
uimenu(lmenu,'tag','loadsourcedatamenu','label','&Load Source Data','callback','multiblocktool(''loaddata'',gcbo,[],guidata(gcbf),''load'')');
uimenu(lmenu,'tag','loadnewdatamenu','label','&Load New Data','callback','multiblocktool(''loaddata'',gcbo,[],guidata(gcbf),''loadnew'')');

imenu = uimenu(hmenu,'Label','&Import Data','tag','import_menu');
uimenu(imenu,'tag','importsourcedatamenu','label','&Import Source Data','callback','multiblocktool(''loaddata'',gcbo,[],guidata(gcbf),''import'')');
uimenu(imenu,'tag','importnewdatamenu','label','&Import New Data','callback','multiblocktool(''loaddata'',gcbo,[],guidata(gcbf),''importnew'')');

uimenu(hmenu,'tag','loadsourcemodelmenu','label','&Load Source Model','callback','multiblocktool(''loaddata'',gcbo,[],guidata(gcbf),''model'')');

uimenu(hmenu,'tag','loadmbmodelmenu','Separator','on','label','&Load Multiblock Model','callback','multiblocktool(''loadmodel'',gcbo,[],guidata(gcbf))');
uimenu(hmenu,'tag','savembmodelmenu','label','Save &Model Multiblock','callback','multiblocktool(''save_callback'',gcbo,[],guidata(gcbf),''model'')');
uimenu(hmenu,'tag','savejoineddatamenu','label','&Save Joined Data','callback','multiblocktool(''save_callback'',gcbo,[],guidata(gcbf),''joineddata'')');
uimenu(hmenu,'tag','savejoineddatanewmenu','label','&Save Joined New Data','callback','multiblocktool(''save_callback'',gcbo,[],guidata(gcbf),''joineddatanewall'')');

cmenu = uimenu(hmenu,'tag','clearmbmodelmenu','Separator','on','label','&Clear MultiBlock Model','callback','multiblocktool(''clear_Callback'',gcbo,[],guidata(gcbf),''model'')');
cmenu = uimenu(hmenu,'tag','clearchannelmenu','Label','&Clear Channel');
cmenu = uimenu(hmenu,'tag','clearallmenu','label','&Clear All','callback','multiblocktool(''clear_Callback'',gcbo,[],guidata(gcbf),''all'')');


uimenu(hmenu,'tag','closemenu','Separator','on','label','&Close','callback','multiblocktool(''loaddata'',gcbo,[],guidata(gcbf),''import'')');

hmenu = uimenu(fig,'Label','&Edit','tag','menu_edit');
uimenu(hmenu,'tag','guioptionsmenu','label','&Interface Options','callback','multiblocktool(''editoptions'',gcbo,[],guidata(gcbf),''gui'')');
uimenu(hmenu,'tag','functionoptionsmenu','label','&Function Options','callback','multiblocktool(''editoptions'',gcbo,[],guidata(gcbf),''function'')');
uimenu(hmenu,'tag','refreshmenu','label','&Refresh Graph','callback','multiblocktool(''update_graph'',guidata(gcbf))');

hmenu = uimenu(fig,'Label','&Help','tag','menu_help');
uimenu(hmenu,'tag','openhelpmenu','label','&Multiblock Tool GUI Analysis Help','callback','multiblocktool(''openhelp_ctrl_Callback'',gcbo,[],guidata(gcbf))');

uimenu(hmenu,'tag','plshelp','label','&General Help','callback','helppls');


mygraph = EVGraph(fig,'Units','Pixels','Position',[1 1 1 1]);
mygraph.ExternalFunction = @multiblocktool;

setappdata(fig,'mbgraph',mygraph);

%Add swimlanes.
%Main pool.
mygraph.AddVertex(struct('Tag','calibrationpool', 'Label','Join Settings','Position',[1 1 1 1],'Style','evriSwimPoolV'));
%Swim lanes.
mygraph.AddVertex(struct('Tag','startdata','Label','Source Data', 'Parent','calibrationpool','Position',[1 1 1 1],'Style','evriSwimLaneH'));
mygraph.AddVertex(struct('Tag','models','Label','Source Models', 'Parent','calibrationpool','Position',[1 1 1 1],'Style','evriSwimLaneH'));
mygraph.AddVertex(struct('Tag','modelfields','Label','Model Fields', 'Parent','calibrationpool','Position',[1 1 1 1],'Style','evriSwimLaneH'));
mygraph.AddVertex(struct('Tag','preprocessing','Label','Preprocessing', 'Parent','calibrationpool','Position',[1 1 1 1],'Style','evriSwimLaneH'));
mygraph.AddVertex(struct('Tag','joindata','Label','Join Data','Position',[1 1 1 1],'Style','evriSwimLaneH'));

%Apply pool.
mygraph.AddVertex(struct('Tag','applypool', 'Label','Apply New Data','Position',[1 1 1 1],'Style','evriSwimPoolH'));

%Swim lanes.
mygraph.AddVertex(struct('Tag','newdata','Label','New Data', 'Parent','applypool','Position',[1 1 1 1],'Style','evriSwimLaneH'));
mygraph.AddVertex(struct('Tag','joinnewdata','Label','Join Data', 'Parent','applypool','Position',[1 1 1 1],'Style','evriSwimLaneH'));

%Set appdata for apply pool visibility.
setappdata(fig,'applypoolvisible',1);

%Make context menu.
hcontext = findobj(fig,'tag','mbtcontextmenu');
if isempty(hcontext)
  hcontext = uicontextmenu('parent',fig);
  set(hcontext,'callback','multiblocktool(''update_contextmenu'',gcbo)','tag','mbtcontextmenu');
end
uimenu(hcontext,'tag','cmenu_load','label','Load','callback','multiblocktool(''contextmenu_callback'',gcbo,''load'');');
uimenu(hcontext,'tag','cmenu_import','label','Import','callback','multiblocktool(''contextmenu_callback'',gcbo,''import'');');
uimenu(hcontext,'tag','cmenu_new','label','New','callback','multiblocktool(''contextmenu_callback'',gcbo,''new'');');
amenu = uimenu(hcontext,'tag','cmenu_analysis','label','Analyze','callback','');
uimenu(hcontext,'tag','cmenu_plot','label','Plot','callback','multiblocktool(''contextmenu_callback'',gcbo,''plot'');');
uimenu(hcontext,'tag','cmenu_edit','label','Edit','callback','multiblocktool(''contextmenu_callback'',gcbo,''edit'');');
uimenu(hcontext,'tag','cmenu_view','label','View','callback','multiblocktool(''contextmenu_callback'',gcbo,''view'');');
uimenu(hcontext,'tag','cmenu_save','label','Save','callback','multiblocktool(''contextmenu_callback'',gcbo,''save'');','Separator','on');
uimenu(hcontext,'tag','cmenu_delete','label','Clear','callback','multiblocktool(''contextmenu_callback'',gcbo,''delete'');');

anallist = analysistypes;
for j=1:size(anallist,1);
  uimenu(amenu,'label',anallist{j,2},'callback','multiblocktool(''contextmenu_callback'',gcbo,''analysis'');','userdata',anallist{j,1},'separator',anallist{j,4});
end

%Add toolbar.
[htoolbar, hbtns] = toolbar(fig,'multiblocktool');

handles = guihandles(fig);
guidata(fig,handles);
drawnow
resize_callback(fig,[],handles)
update_graph(handles);

%--------------------------------------------------------------
function resize_callback(h,eventdata,handles,varargin)
%Resize callback.
% Update_graph calls resize after it's done.

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

opts = getappdata(handles.multiblocktool, 'gui_options');
set(handles.multiblocktool,'units','pixels');
%Get initial positions.
figpos = get(handles.multiblocktool,'position');

mygraph = getappdata(handles.multiblocktool,'mbgraph');

%Get min width from right most cell.
mydata  = getappdata(handles.multiblocktool,'mbdata');
mywidth = figpos(3)-4;
if ~isempty(mydata)
  %Define width based on number of vertices of data there are.
  mywidth = ((length(mydata)+1)*140);
end

mywidth = max(mywidth,520);

pooltop = 70;

if ~isempty(mygraph)
  swim_w  = mywidth-88;%Width.
  swim_h  = 80;%Height.
  swim_hc = 20;%collapsed height.
  
  m = mygraph.GraphModel;
  
  set(mygraph,'Position',[2 2 figpos(3)-4 figpos(4)-4])
  
  %Swim lanes may be collapsed so adjust height appropriately.
  if m.isCollapsed(mygraph.GetCell('startdata'));
    my_ht = swim_hc;
  else
    my_ht = swim_h;
  end
  
  my_top = 2;
  mygraph.SetCellPosition('startdata',[22 my_top swim_w my_ht])
  
  %-Model lane.
  my_top = my_top+my_ht+4;
  if m.isCollapsed(mygraph.GetCell('models'));
    my_ht = swim_hc;
  else
    my_ht = swim_h;
  end
  
  mygraph.SetCellPosition('models',[22 my_top swim_w my_ht])
  
  %-Model fields lane.
  my_top = my_top+my_ht+4;
  if m.isCollapsed(mygraph.GetCell('modelfields'));
    my_ht = swim_hc;
  else
    my_ht = swim_h;
  end
  
  mygraph.SetCellPosition('modelfields',[22 my_top swim_w my_ht])
  %- Prepro lane.
  my_top = my_top+my_ht+2;
  if m.isCollapsed(mygraph.GetCell('preprocessing'));
    my_ht = swim_hc;
  else
    my_ht = swim_h;
  end
  
  mygraph.SetCellPosition('preprocessing',[22 my_top swim_w my_ht])
  
  %Resize calibration pool.
  if m.isCollapsed(mygraph.GetCell('calibrationpool'))
    %Swim lanes disappear but don't want to shrink vertically.
    mypos = mygraph.GetCellPosition('calibrationpool');
    mygraph.SetCellPosition('calibrationpool',[0 pooltop swim_w+24 swim_hc]);
    mygraph.SetStyle('calibrationpool','evriSwimPoolH');
    pooltop = pooltop+36;
  else
    mygraph.SetCellPosition('calibrationpool',[0 pooltop swim_w+24 my_top+my_ht+2]);
    mygraph.SetStyle('calibrationpool','evriSwimPoolV');
    pooltop = pooltop+my_top+my_ht+10;
  end
  
  %my_top = my_top+88;
  %mygraph.SetCellPosition('joindata',[22 pooltop swim_w 80]);
  
  %- Join data lane.
  if m.isCollapsed(mygraph.GetCell('joindata'));
    my_ht = swim_hc;
  else
    my_ht = swim_h;
  end
  
  mygraph.SetCellPosition('joindata',[22 pooltop swim_w my_ht])
  pooltop = pooltop+my_ht+20;
  
  
  %Resize apply pool if visible.
  my_top = my_top+168;
  
  if getappdata(handles.multiblocktool,'applypoolvisible')
    %Make visible and position.
    mygraph.SetVisible('applypool',true);
    
    thistop = 0;
    if m.isCollapsed(mygraph.GetCell('newdata'));
      my_ht = swim_hc;
    else
      my_ht = swim_h;
    end
    mygraph.SetCellPosition('newdata',[22 thistop swim_w my_ht])
    
    thistop = thistop + my_ht+4;
    if m.isCollapsed(mygraph.GetCell('joinnewdata'));
      my_ht = swim_hc;
    else
      my_ht = swim_h;
    end
    mygraph.SetCellPosition('joinnewdata',[22 thistop swim_w my_ht])
    
    if m.isCollapsed(mygraph.GetCell('applypool'))
      %Swim lanes disappear but don't want to shrink vertically.
      mygraph.SetStyle('applypool','evriSwimPoolH');
      mypos = mygraph.GetCellPosition('applypool');
      mygraph.SetCellPosition('applypool',[0 pooltop swim_w+24 20]);
      
    else
      mygraph.SetCellPosition('applypool',[0 pooltop swim_w+24 thistop+my_ht+2]);
      mygraph.SetStyle('applypool','evriSwimPoolV');
    end
  else
    %Turn off visible.
    mygraph.SetVisible('applypool',true);
    
  end
  
  jcwidth = round(swim_w/3)-4;
  %Resize model and joined data.
  mcell   = GetCell(mygraph,'multiblock_model');
  jdcell  = GetCell(mygraph,'multiblock_joineddataall');
  jdncell = GetCell(mygraph,'multiblock_joineddatanewall');
  
  if ~isempty(mcell)
    mcell.getGeometry.setX(24);
    mcell.getGeometry.setWidth(jcwidth);
  end
  if ~isempty(jdcell)
    jdcell.getGeometry.setX(jcwidth+26);
    jdcell.getGeometry.setWidth(jcwidth);
  end
  if ~isempty(jdncell)
    jdncell.getGeometry.setX((2*jcwidth)+28);
    jdncell.getGeometry.setWidth(jcwidth);
  end
end

%Since there's some direct resizing on java object and not through EVGraph
%we need to call refresh.
mygraph.Graph.refresh

%--------------------------------------------------------------------
function toolbar_Callback(hObject, eventdata, handles, varargin)
%Switch yard for some toolbar button calls.

tag = get(hObject,'tag');

switch tag
  case 'setopts'
    editoptions(hObject, eventdata, handles,'function');
  case 'calcmodel'
    calcmodel_Callback(hObject,eventdata,handles,varargin)
    %case 'applynew'
    %Expand swim pool for new data.
  case {'zoomwin' 'zoomin' 'zoomout' 'zoomdefault'}
    % Zoom graph.
    mygraph = getappdata(handles.multiblocktool,'mbgraph');
    myview = mygraph.GraphComponent.getGraph.getView;
    compLen = mygraph.GraphComponent.getWidth;
    viewLen = myview.getGraphBounds.getWidth;
    myscale = myview.getScale;
    if myscale<.2 & ~strcmpi(tag,'zoomdefault')
      %Add warning if scale is way small and tell user to use scale to
      %window to fix. User somehow zoomed way out and didn't know there was
      %a zooming problem. Window was just blank.
      evriwarndlg('Window zoom level appears to be very low. Use "Zoom to Default Scale" button (1:1) to fix.','Zoom Warning')
    end
    switch tag
      case 'zoomwin'
        myview.setScale(compLen/viewLen * myview.getScale * .9);
      case 'zoomin'
        myview.setScale(myscale+.1)
      case 'zoomout'
        myview.setScale(myscale-.1)
      case 'zoomdefault'
        myview.setScale(1);
    end
    
end

%--------------------------------------------------------------------
function openhelp_ctrl_Callback(hObject, eventdata, handles)
%Open help page.
evrihelp('multiblocktool')

%--------------------------------------------------------------------
function closereq_callback(h,eventdata,handles,varargin)
%Close gui.

if isempty(handles)
  handles = guihandles(h);
end

%Close children.
children = getappdata(handles.multiblocktool,'child_figures');
for j=findobj(handles.multiblocktool)';   %find children in ANY sub-object
  children=[children getappdata(j,'children')];
end
children = children(ishandle(children));
children = children(ismember(char(get(children,'type')),{'figure'}));
close(children);

%Save figure position.
positionmanager(handles.multiblocktool,'multiblocktool','set')

%Manually delete graph object so Java objects get destroyed correctly.
mygraph = getappdata(handles.multiblocktool,'mbgraph');
delete(mygraph);
setappdata(handles.multiblocktool,'mbgraph',[]);

if ishandle(handles.multiblocktool)
  delete(handles.multiblocktool)
end

%--------------------------------------------------------------------
function drop(h,eventdata,handles,varargin)

if ismodel(varargin{1}) & strcmpi(varargin{1}.modeltype,'multiblock')
  loadmodel(h,[],handles,varargin{:})
else
  loaddata(h,[],handles,'auto',varargin{:})
end

%---------------------------------------------------------------------
function dropCallbackFcn(obj,ev,varargin)
%Parse dnd object then call drop.
mygraph = varargin{1};
if ishandle(mygraph)
  fig = ancestor(mygraph,'figure');
  mygraph = getappdata(fig,'mbgraph');
else
  fig = mygraph.ParentFigure;
end

handles = guihandles(fig);

dropdata = drop_parse(obj,ev,'',struct('getcacheitem','on'));
if isempty(dropdata{1})
  %Probably error.
  %TODO: Process workspace vars.
  return
end

mycell = mygraph.Graph.getSelectionCell;
if ~isempty(mycell) & size(dropdata,1)==1
  %If droping a single data onto a newdata node then try to load it.
  myid = char(mycell.getId);
  [cellid, celltype] = getcellinfo(myid);
  if ~strcmp(cellid,'startdata')
    if isempty(celltype) | strcmp(celltype,'joindata')
      return
    end
  end
  if ismember(celltype,{'newdata'})
    mydata = getappdata(handles.multiblocktool,'mbdata');
    temp_data = dropdata{1,2};
    
    if ~isdataset(temp_data) & isnumeric(temp_data)
      %Make a dataset with numeric data.
      temp_data             = dataset(temp_data);
      temp_data.name        = ['Unnamed Data ' datestr(now,'yyyymmddTHHMMSSFFF')];
    end
    
    if ~ismember(class(temp_data),{'dataset'})
      evriwarndlg(['Data type: ' class(temp_data) ' not permitted. Use only Dataset.'])
      return
    end
    
    %Load new data into correct spot.
    mydata(ismember({mydata.id},cellid)).newdata = temp_data;
    setappdata(handles.multiblocktool,'mbdata',mydata)
    %TODO: I think we need to rebuild model and apply to new data.
%     clear_Callback(handles.multiblocktool,[],handles,'model')
    update_graph(handles);
    return
  end
end

%Call load data.
loaddata(handles.multiblocktool,[],handles,'auto',dropdata{:,2})

%-------------------------------------------------
function dragOverCallbackFcn(obj, ev, varargin)
%Highlight drag location.
% If over New data or PP then highlight cell.
mygraph = varargin{1};
mycell = mygraph.GraphComponent.getCellAt(ev.getLocation.getX,ev.getLocation.getY);

if isempty(mycell)
  return
end

myid = char(mycell.getId);

if ~isempty(strfind(myid,'_preprocess')) | ~isempty(strfind(myid,'_newdata')) | ~isempty(strfind(myid,'startdata'))
  mygraph.Graph.setSelectionCell(mycell)
else
  %Dragging over something else.
end

%---------------------------------------------------------------------
function clickCallbackFcn(obj,ev,varargin)
%Parse mouse clicks on graph. Set right-click menu up.

mygraph = varargin{1};
fig = mygraph.ParentFigure;
figpos = get(fig,'position');
handles = guihandles(fig);
mydata  = getappdata(handles.multiblocktool,'mbdata');

mycell = mygraph.GraphComponent.getCellAt(ev.getX,ev.getY);

if isempty(mycell)
  %Clicking in open space.
  return
end

%Clicking on cell.
myid = char(mycell.getId);
cm = findobj(fig,'tag','mbtcontextmenu');
setappdata(fig,'current_clicked_cell',myid);

[cellid, celltype] = getcellinfo(myid);

if strcmp(celltype,'joindata')
  %If celltype join data then spoof call to main joineddata menu.
  celltype = 'joineddataall';
  cellid = 'multiblock';
end

set(allchild(cm),'visible','off','separator','off');
set(handles.cmenu_edit,'Label','Edit');%Can be set to "view" for mdoel fields.
if ismember(cellid,{'startdata' 'models' 'modelfields' 'preprocessing' ...
    'calibrationpool' 'applypool' 'joindata' 'newdata' 'joinnewdata'})
  %May have colapsed or expanded swimlane. Need to call resize.
  resize_callback(handles.multiblocktool,[],handles)
else
  %Clicking on cell (vetrex or edge).
  if javax.swing.SwingUtilities.isRightMouseButton(ev)
    showcm = 0;
    if ~isempty(mydata) & any(~cellfun('isempty',{mydata.id})) & ismember(cellid,{mydata.id});
      %Right clicking on a cell.
      switch celltype
        case 'rawdata'
          set([handles.cmenu_edit handles.cmenu_delete handles.cmenu_save handles.cmenu_plot handles.cmenu_analysis],'enable','on','visible','on')
          set([handles.cmenu_save],'separator','on')
        case 'model'
          set([handles.cmenu_edit handles.cmenu_delete handles.cmenu_save],'enable','on','visible','on')
          set([handles.cmenu_save],'separator','on')
        case 'modelfields'
          set([handles.cmenu_edit handles.cmenu_view handles.cmenu_delete handles.cmenu_save],'enable','on','visible','on')
          set(handles.cmenu_edit,'Label','Choose')
          set([handles.cmenu_save],'separator','on')
        case 'preprocessing'
          set([handles.cmenu_edit handles.cmenu_delete],'enable','on','visible','on')
          set([handles.cmenu_delete],'separator','on')
        case {'joindata' 'joinnewdata'}
          set([handles.cmenu_edit handles.cmenu_plot handles.cmenu_delete handles.cmenu_save handles.cmenu_analysis],'enable','on','visible','on')
          set(handles.cmenu_edit,'Label','View')
          set([handles.cmenu_save],'separator','on')
        case 'newdata'
          mypos = ismember({mydata.id},cellid);
          if isempty(mydata(mypos).newdata)
            status = 'off';
            set(handles.cmenu_load, 'enable','on','visible','on');
          else
            status = 'on';
          end
          set([handles.cmenu_edit handles.cmenu_delete handles.cmenu_save handles.cmenu_plot],'enable',status,'visible',status)
          set([handles.cmenu_save],'separator','on')
        otherwise
          return
      end
      showcm = 1;
    else
      showcm = 1;
      if strcmp(cellid,'multiblock') & strcmp(celltype,'model')
        enbl = 'on';
        if isempty(getappdata(handles.multiblocktool,'model'))
          enbl = 'off';
        end
        set([handles.cmenu_delete handles.cmenu_save],'enable',enbl,'visible','on')
      elseif strcmp(cellid,'multiblock') & (strcmp(celltype,'joineddataall') | strcmp(celltype,'joineddatanewall'))
        enbl = 'on';
        if strcmp(celltype,'joineddataall') & isempty(getappdata(handles.multiblocktool,'joined_data'))
          enbl = 'off';
        elseif strcmp(celltype,'joineddatanewall') & isempty(getappdata(handles.multiblocktool,'joined_data_new'))
          enbl = 'off';
        end
        set([handles.cmenu_analysis handles.cmenu_edit handles.cmenu_plot handles.cmenu_delete handles.cmenu_save],'enable',enbl,'visible','on')
        set(handles.cmenu_edit,'Label','View')
        set([handles.cmenu_save],'separator','on')
      elseif strcmp(cellid,'postjoin') & strcmp(celltype,'model')
        set([handles.cmenu_edit],'enable','on','visible','on')
      else
        showcm = 0;
        
      end
    end
    
    myloc = getmouseposition(fig);
    
    if showcm
      set(cm,'position',myloc);
      set(cm,'visible','on');
      return
    end
  elseif javax.swing.SwingUtilities.isLeftMouseButton(ev) & ev.getClickCount==2
    %If double click on vertex then do default context menu function.
    if ~isempty(mydata) & any(~cellfun('isempty',{mydata.id})) & ismember(cellid,{mydata.id});
      switch celltype
        case {'rawdata' 'model' 'modelfields' 'preprocessing' 'joindata' 'newdata'}
          contextmenu_callback(handles.cmenu_edit,'edit')
        otherwise
          return
      end
    end
    
  end
  
end


%---------------------------------------------------------------------
function filemenu_callback(h,handles)
%File menu update.

fig = ancestor(h,'figure');

mydata   = getappdata(handles.multiblocktool,'mbdata');
model    = getappdata(handles.multiblocktool,'model');
jdata    = getappdata(handles.multiblocktool,'joined_data');
jdatanew = getappdata(handles.multiblocktool,'joined_data_new');

if ~isempty(model)
  %Can't have model without joined data so enable both.
  set([handles.savembmodelmenu handles.savejoineddatamenu],'enable','on')
else
  set([handles.savembmodelmenu handles.savejoineddatamenu],'enable','off')
end

if ~isempty(jdatanew)
  %Can't have model without joined data so enable both.
  set([handles.savejoineddatanewmenu],'enable','on')
else
  set([handles.savejoineddatanewmenu],'enable','off')
end

%Update "channel" clearing menu.
nchannels = length(mydata);
set(allchild(handles.clearchannelmenu),'visible','off');
for i = 1:length(mydata)
  %Check for existing menu and add it if not there.
  if ~isfield(handles,['channel_' num2str(i)])
    cmenu = uimenu(handles.clearchannelmenu,'tag',['channel_' num2str(i)],'label',['Channel ' num2str(i)],'callback',['multiblocktool(''clear_Callback'',gcbo,[],guidata(gcbf),''' num2str(i) ''')']);
  else
    set(handles.(['channel_' num2str(i)]),'visible','on')
  end
end


%---------------------------------------------------------------------
function contextmenu_callback(cmenuobj,menuaction)
%Callbacks from context menu displayed after right-click on vertex.

fig = ancestor(cmenuobj,'figure');
handles = guihandles(fig);

currentcell = getappdata(fig,'current_clicked_cell');

if isempty(currentcell)
  %If there's no current cell then we can't tell what context menu is
  %displayed over so just return.
  return
end

[cellid, celltype] = getcellinfo(currentcell);
mydata = getappdata(handles.multiblocktool,'mbdata');
savedata = 0;
%Some things are edited here and need to have model cleared. Other items
%are using shareddata which will subsequently clear the model in shareddata
%update callback below.
clearmodel = 0;%flag

if strcmp(celltype,'joindata')
  %If user right clicks on a joindata cell then spoof call to
  %joineddataall icon.
  cellid = 'multiblock';
  celltype = 'joineddataall';
elseif strcmp(celltype,'joinnewdata')
  cellid = 'multiblock';
  celltype = 'joineddatanewall';
end

if isempty(celltype)
  %Not on cell with a type. Don't have any of these but could be possible
  %if we have temporary cells.
  return
elseif strcmp(cellid,'multiblock')
  %Action on mb model or joined data.
  switch menuaction
    case 'save'
      save_callback(handles.multiblocktool,[],handles,celltype)
    case {'clear' 'delete'}
      clear_Callback(handles.multiblocktool,[],handles,celltype)
    case {'analysis' 'plot' 'edit'}
      jdata = [];
      switch celltype
        case 'joineddataall'
          jdata = getappdata(handles.multiblocktool,'joined_data');
        case 'joineddatanewall'
          jdata = getappdata(handles.multiblocktool,'joined_data_new');
      end
      if ~isempty(jdata)
        if strcmp(menuaction,'analysis')
          obj = evrigui('analysis');
          obj.setMethod(get(cmenuobj,'userdata'));
          obj.drop(jdata);
        elseif strcmp(menuaction,'plot')
          plotgui('new',jdata);
        elseif strcmp(menuaction,'edit')
          editds(jdata)
        end
        
      end
  end
else
  %Get data for given ID.
  thisdata = mydata(ismember({mydata.id},cellid));
  
  switch menuaction
    case 'edit'
      switch celltype
        case {'rawdata' 'newdata'}
          %Get shareddata object and send it to editds. This updates
          %automatically.
          if check_editor(thisdata,'editds')
            return
          end
          sdoid = set_SDO(handles,cellid,celltype);
          hh    = editds(sdoid);
          savedata = 1;
          thisdata.editor_handle = [thisdata.editor_handle(ishandle(thisdata.editor_handle)) hh];
          adopt(handles,hh)
          drawnow
        case 'model'
          modl = thisdata.model;
          if modl.isprediction
            evriwarndlg('Prediction cannot be editted','No Edit')
            return
          end
          
          if check_editor(thisdata,'analysis')
            return
          end
          obj = evrigui('analysis');
          
          %Check to see if there's raw data (a viable xblock).
          if ~isempty(thisdata.rawdata)
            obj.drop(thisdata.rawdata);
            xid = obj.getXblockId;
            linkshareddata(xid,'add',fig,'multiblocktool',struct('cellid',cellid,'celltype',celltype));
          end
          
          obj.drop(modl);
          if isempty(thisdata.rawdata)
            %Pull original data from analysis (which was pulled from
            %cache).
            xid = obj.getXblockId;
            if ~isempty(xid)
              thisdata.rawdata = xid.object;
              savedata = 1;
              linkshareddata(xid,'add',fig,'multiblocktool',struct('cellid',cellid,'celltype',celltype));
            end
          end 
          
          %Add listener for data change.
          mid = obj.getModelId;
          linkshareddata(mid,'add',fig,'multiblocktool',struct('cellid',cellid,'celltype',celltype));
          adopt(handles,obj.handle)
          savedata = 1;
          thisdata.editor_handle = obj.handle;
        case 'modelfields'
          thisfilter = thisdata.modelfields;
          if isempty(thisfilter)
            [defaultfields, defaultfields_list] = getmodeloutputs(thisdata.model,0);
          else
            defaultfields_list = thisfilter(:,1);
          end
          %Prompt user for what fields to use on this model.
          thisfilter = getmodeloutputs(thisdata.model,defaultfields_list);
          if ~isempty(thisfilter)
            thisdata.modelfields = thisfilter;
            savedata = 1;
            clearmodel = 1;
          end
        case 'preprocessing'
          %Choose preprocessing for raw data or model data.
          curpp   = thisdata.preprocessing;
          curdata = get_raw_data(thisdata);
          if isempty(curdata)
            return
          end
          [xpp,ppchange]= preprocess(curpp, curdata);
          %Will return orginal pp if cancel so just set appdata as needed.
          if ppchange
            thisdata.preprocessing = xpp;
            savedata = 1;
            clearmodel = 1;
          else
            return
          end
      end
      
    case 'delete'
      switch celltype
        case 'rawdata'
          %Special case for save data so do it  here.
          myeditors = thisdata.editor_handle;
          myeditors = myeditors(ishandle(myeditors));
          close(myeditors);
          
          mydata = mydata(~ismember({mydata.id},cellid));
          setappdata(handles.multiblocktool,'mbdata',mydata)
          clearmodel = 1;
        case 'model'
          if isempty(thisdata.rawdata)
            mydata = mydata(~ismember({mydata.id},cellid));
            setappdata(handles.multiblocktool,'mbdata',mydata)
          else
            thisdata.model       = [];
            thisdata.modelfields = [];
            savedata = 1;
          end
          clearmodel = 1;
        case 'modelfields'
          thisdata.modelfields = [];
          savedata = 1;
          clearmodel = 1;
        case 'preprocessing'
          thisdata.preprocessing = [];
          savedata = 1;
          clearmodel = 1;
        case 'newdata'
          thisdata.newdata = [];
          clear_Callback(handles.multiblocktool,[],handles,'joineddatanewall')
          savedata = 1;
        case 'joindata'
          
      end
    case 'plot'
      switch celltype
        case {'rawdata' 'modelfields' 'model' 'newdata'}
          if check_editor(thisdata,'plotgui')
            return
          end
          
          %Get shareddata object and send it to plotgui. This updates
          %automatically.
          sdoid = set_SDO(handles,cellid,celltype);
          hh    = plotgui('new',sdoid);
          savedata = 1;
          thisdata.editor_handle = [thisdata.editor_handle(ishandle(thisdata.editor_handle)) hh];
          adopt(handles,hh)
      end
    case 'analysis'
      if ~isempty(thisdata.editor_handle) & any(ishandle(thisdata.editor_handle))
        delans = evriquestdlg('Only one editor (DataSet Editor or Analysis Model Editor) can be open at a time. Close existing editor?','WARNING: Close Editor','Yes','Cancel','Yes');
        if strcmp(delans,'Yes');
          %Delete or Backspace
          close(thisdata.editor_handle(ishandle(thisdata.editor_handle)));
        else
          figure(thisdata.editor_handle);
          return
        end
      end
      analysistype = get(cmenuobj,'userdata');
      obj = evrigui('analysis');
      obj.setMethod(analysistype);
      %and automatically load data
%       if strcmp(celltype,'joindata')
%       end
      obj.drop(thisdata.rawdata);
      xid = obj.getXblockId;
      linkshareddata(xid,'add',fig,'multiblocktool',struct('cellid',cellid,'celltype',celltype));
      
      savedata = 1;
      thisdata.editor_handle = obj.handle;
      
    case 'view'
      switch celltype
        case 'modelfields'
          modelfielddata = get_raw_data(thisdata,'modelfields');
          if ~isempty(modelfielddata)
            editdsfig = editds(modelfielddata);
            editds('noedit',editdsfig,1);
          end
          return
      end
    case 'save'
      dlgname = '';
      switch celltype
        case 'model'
          dlgname = 'Model';
          thisobj = thisdata.model;
        case 'rawdata'
          dlgname = 'Data';
          thisobj = thisdata.rawdata;
        case 'newdata'
          dlgname = 'Data';
          thisobj = thisdata.newdata;
        case 'modelfields'
          dlgname = 'Extracted Model Data';
          thisobj = get_raw_data(thisdata,'modelfields');
      end
      svdlgpls(thisobj,['Save ' dlgname]);
    case 'load'
      %Right clicked on empty "New Data" block
      mydata = getappdata(handles.multiblocktool,'mbdata');
      temp_data = lddlgpls({'double' 'dataset' 'cell' 'struct'},['Select Data']);
      
      if ~isdataset(temp_data) & isnumeric(temp_data)
        %Make a dataset with numeric data.
        temp_data             = dataset(temp_data);
        temp_data.name        = ['Unnamed Data ' datestr(now,'yyyymmddTHHMMSSFFF')];
      end
      
      if ~ismember(class(temp_data),{'dataset'})
        evriwarndlg(['Data type: ' class(temp_data) ' not permitted. Use only Dataset.'])
        return
      end      
      %Load new data into correct spot.
      mydata(ismember({mydata.id},cellid)).newdata = temp_data;
      setappdata(handles.multiblocktool,'mbdata',mydata)
  end
end

setappdata(fig,'current_clicked_cell',[]);

if savedata
  mydata(ismember({mydata.id},cellid)) = thisdata;
  setappdata(handles.multiblocktool,'mbdata',mydata)
end

if clearmodel
  clear_Callback(handles.multiblocktool,[],handles,'model')
end

drawnow
update_graph(handles);


% if javax.swing.SwingUtilities.isRightMouseButton(ev)
%   scl = mygraph.Graph.getView.getScale;
%   if scl==1
%     mygraph.Graph.getView.setScale(2)
%   else
%     mygraph.Graph.getView.setScale(1)
%   end
% end
% mygraph.Graph.refresh;

%---------------------------------------------------------------------
function out = check_editor(thisdata,editortype)
%Check if an editor is already open for given dataset.
% If out = 1 then abort editing, user wants to keep existing editor open.
% If out = 0 then close editors and continue.
% If out = -1 then window already open and has been made current figure.
%
% editortype - ['analysis' | 'editds' | 'plotgui'] string of editor that we're switch TO.

out = 0;

myeditors = thisdata.editor_handle;
myeditors = myeditors(ishandle(myeditors));
if isempty(myeditors)
  return
end


if ~strcmp(editortype,'analysis')
  %Not switching to analysis so if other editors are not analysis then just
  %add them to list. Plotgui and Editds can be open at same time.
  mytags = get(myeditors,'tag');
  if ~iscell(mytags)
    mytags = {mytags};
  end
  if ~any(ismember(mytags,'analysis'))
    thiseditor = [];
    if strcmp(editortype,'plotgui')
      for i = 1:length(myeditors)
        myftype = getappdata(myeditors(i),'figuretype');
        if ~isempty(myftype) & strcmpi(myftype,'plotgui')
          thiseditor(end+1) = myeditors(i);
        end
      end
    elseif strcmp(editortype,'editds')
      thiseditor = myeditors(ismember(mytags,editortype));
    end
    
    if ~isempty(thiseditor)
      out = -1;
      figure(thiseditor);
    else
      
    end
    return
  end
end

%Look up linked editors.
if ~isempty(myeditors)
  delans = evriquestdlg('Analysis model editor cannot be open at same time as other editors. Close existing editor?','WARNING: Close Editor','Yes','Cancel','Yes');
  if strcmp(delans,'Yes');
    %Delete or Backspace
    close(myeditors);
  else
    out = 1;
    figure(myeditors(1));
    return
  end
end

%---------------------------------------------------------------------
function [cellid, celltype] = getcellinfo(celltag)
%Parse the cell tag into id number and type.

unscrpos = strfind(celltag,'_');
if isempty(unscrpos)
  cellid = celltag;
  celltype = '';
else
  cellid = celltag(1:unscrpos-1);
  celltype = celltag(unscrpos+1:end);
end

%---------------------------------------------------------------------
function keypressCallbackFcn(obj,ev,varargin)
%Parse mouse clicks on graph.
mygraph = varargin{1};
fig = mygraph.ParentFigure;
handles = guihandles(fig);

%---------------------------------------------------------------------
function out = get_raw_data(thisdata,celltype)
%Get dataset from loaded data structure. Make dataset from model fields is
%needed.

if nargin<2
  %Get data for model of dataset dependign on what's available.
  celltype = 'rawdata';
  if ~isempty(thisdata.model)
    celltype = 'modelfields';
  end
end

out = [];
switch celltype
  case 'rawdata'
    out = thisdata.rawdata;
  case 'newdata'
    out = thisdata.newdata;
  case 'model'
    out = thisdata.model;
  case 'modelfields'
    %Pull data out of model into dataset.
    if isempty(thisdata.modelfields)
      evriwarndlg('No model fields are selected. Select model fields before selecting prepocessing.','Select Model Fields')
      return
    end
    out = multiblock('applyfilter',thisdata.model,thisdata.modelfields(:,2));
    out = dataset(out);
end

%--------------------------------------------------------------------
function loaddata(h,eventdata,handles,varargin)
%Load data.

%TODO: Add warning for more than 3D data.
opts   = getappdata(handles.multiblocktool, 'gui_options');

mode = varargin{1};%Type of load dialog to run.
name = '';
isnew = 0;

switch mode
  case {'import' 'importnew'}
    %Import single image.
    aopts.importmethod = 'editds_defaultimportmethods';
    mydata = autoimport([],[],aopts);
  case {'load' 'model' 'loadnew'}
    %Load from workspace or mat.
    [mydata,name,location] = lddlgpls({'double' 'dataset' 'cell' 'struct'},['Select Data']);
  case {'auto' 'autonew'}
    %Data provided in varargin.
    mydata = varargin(2:end);
end

if ismember(mode,{'loadnew' 'importnew' 'autonew'})
  isnew = 1;
end

if isempty(mydata);  %canceled out of import?
  return;
end

if ~iscell(mydata)
  mydata = {mydata};
end

curdat = getappdata(handles.multiblocktool,'mbdata');
newdataidx = 1;

for i = 1:length(mydata)
  temp_data = mydata{i};
  if isshareddata(temp_data)
    temp_data = temp_data.object;
  end
  
  %Test if is dataset and if has classes in variable mode. Ask user if they
  %want to split.
  if isdataset(temp_data) & isempty(getappdata(handles.multiblocktool,'split_class_check_never')) & isempty(getappdata(handles.multiblocktool,'split_class_check_loading'))
    %Check to see if there's class info.
    canuse = find(cellfun(@(i) length(unique(i))>1,temp_data.class(2,:)));  %more than one class defined - can use
    if ~isempty(canuse)
      myans = evriquestdlg('Variable (Mode 2) classes detected. Would you like to split dataset being loaded? (Never = not this session)','Split On Class','Yes','No','Never','No');
      myset = [];
      switch lower(myans)
        case 'yes'
          if length(canuse)>1
            %Ask for set.
            names = temp_data.classname(2,canuse);
            for j=1:length(names)
              if isempty(names{j})
                names{j} = sprintf('Class Set %i',canuse(j));
              end
            end
            myset = listdlg('PromptString','Select Class Set:','SelectionMode','Single','liststring',names);
            myset = canuse(myset);
          else
            myset = canuse;
          end
        case 'never'
          setappdata(handles.multiblocktool,'split_class_check_never',1)
      end
      
      if ~isempty(myset)
        classsplitds = splitds(temp_data,'class',2,myset);
        setappdata(handles.multiblocktool,'split_class_check_loading',1)
        try
          loaddata(h,eventdata,handles,'auto',classsplitds{:})
        catch
          erdlgpls({'Unable to load new data. ' lasterr},[upper(mfilename) ' Error']);
        end
        setappdata(handles.multiblocktool,'split_class_check_loading',[])
        return
      end
      
    end
    
  end
  
  if ~isdataset(temp_data) & isnumeric(temp_data)
    %Make a dataset with numeric data.
    temp_data             = dataset(temp_data);
    if ~isempty(name)
      myname = name;
      if iscell(myname)
        myname = myname{i};
      end
      temp_data.name        = myname;
    else
      temp_data.name        = ['Unnamed Data ' datestr(now,'yyyymmddTHHMMSSFFF')];
    end
  end
  
  if ~ismember(class(temp_data),{'dataset' 'evrimodel'})
    evriwarndlg(['Data type: ' class(temp_data) ' not permitted. Use only Dataset or EVRIModel.'],'Cannot load object')
    continue
  end
  
  if isnew & ~isempty(curdat)
    %Add to first open new spot.
    emptyspot = cellfun('isempty',{curdat.newdata});
    emptyspot = find(emptyspot);
    if isempty(emptyspot)
      evriwarndlg(['Clear existing New Data or load new Source Data before adding additional New Data.'],'Cannot Load New Data')
      return
    end
    curdat(emptyspot(1)).newdata = temp_data;
    continue
  end
  
  %Need to get truncated value
  %so don't have sig dig error when converting back and forth.
  curdat(end+1).id = num2str(now+rand,'%10.10f');
  curdat(end).rawdata     = [];
  curdat(end).model       = [];
  if isdataset(temp_data)
    curdat(end).rawdata     = temp_data;
  else
    curdat(end).model       = temp_data;
    %Get raw data from cache if it's there.
    thisdata = modelcache('find',temp_data.datasource{1});
    if ~isempty(thisdata)
      curdat(end).rawdata = modelcache('get',thisdata.name);
    end
  end
  
  curdat(end).modelfields   = [];
  %Add default preprocessing.
  if isempty(curdat(end).model)
    %Data default is block variance.
    curdat(end).preprocessing = preprocess('default','blockvariance');
  else
    %Model default is autoscale.
    curdat(end).preprocessing = preprocess('default','autoscale');
  end
  curdat(end).newdata       = [];
  curdat(end).editor_handle = {};%Can be (editds + plotgui) or analysis.
end

setappdata(handles.multiblocktool,'mbdata',curdat)
%Need to clear model and joinned data.
if ~isnew
  clear_Callback(handles.multiblocktool,[],handles,'model')
end

update_graph(handles);

%--------------------------------------------------------------------
function loadmodel(h,eventdata,handles,varargin)
%Load a multiblock model.

if nargin<4 | isempty(varargin{1})
  [mymod,name,location] = lddlgpls({'struct' 'model'},['Select Model']);
else
  mymod = varargin{1};
end

if isempty(mymod)
  %User cancel.
  return
end

mbmod = struct('id',[],'rawdata',[],'model',[],'modelfields',[],'preprocessing',[],'newdata',[],'editor_handle',[]);
opts = mymod.options;
if ~isempty(mymod.mdata)
  for i = 1:length(mymod.mdata)
    mbmod(i).id = num2str(now+rand,'%10.10f');
    if isdataset(mymod.mdata{i})
      mbmod(i).rawdata = mymod.mdata{i};
    elseif ismodel(mymod.mdata{i})
      %Look up from cache, if cannot find we're in apply only mode.
      mbmod(i).model = mymod.mdata{i};
      mbmod(i).modelfields = opts.filter{i};
    else
      %Look up from cache, if cannot find we're in apply only mode.
      thisdata = modelcache('find',mymod.mdata{i});
      if ~isempty(thisdata)
        mbmod(i).rawdata = modelcache('get',thisdata.name);
      else
        mbmod(i).rawdata = [];
        %In apply mode.
        setappdata(handles.multiblocktool,'applymode',1);
      end
    end
    mbmod(i).preprocessing = opts.preprocessing{i};
  end
  
  setappdata(handles.multiblocktool,'mbdata',mbmod)
end

update_graph(handles);

%--------------------------------------------------------------------
function clear_Callback(h,eventdata,handles,varargin)
%Clear one or more items in gui.

item = varargin{1};

switch item
  case 'data'
    setappdata(handles.multiblocktool,'mbdata',[]);
  case 'joineddataall'
    setappdata(handles.multiblocktool,'joined_data',[]);
  case 'joineddatanewall'
    setappdata(handles.multiblocktool,'joined_data_new',[]);
  case 'model'
    setappdata(handles.multiblocktool,'model',[]);
    setappdata(handles.multiblocktool,'joined_data',[]);
    setappdata(handles.multiblocktool,'joined_data_new',[]);
  case 'all'
    setappdata(handles.multiblocktool,'mbdata',[]);
    setappdata(handles.multiblocktool,'model',[]);
    setappdata(handles.multiblocktool,'joined_data',[]);
    setappdata(handles.multiblocktool,'joined_data_new',[]);
  otherwise
    item = str2num(item);
    if ~isempty(item)
      mydata = getappdata(handles.multiblocktool,'mbdata');
      if length(mydata)>=item
        %Deleting a channel.
        mydata = getappdata(handles.multiblocktool,'mbdata');
        mydata(item) = [];
        setappdata(handles.multiblocktool,'mbdata',mydata);
      end
    end
end

update_graph(handles);

%--------------------------------------------------------------------
function save_callback(h,eventdata,handles,varargin)
%Save table or image to file/workspace.

obj = [];
nm = '';
switch varargin{1}
  case {'joineddata' 'joineddataall'}
    obj = getappdata(handles.multiblocktool,'joined_data');
    nm = 'JoinedData';
  case {'joineddatanew' 'joineddatanewall'}
    obj = getappdata(handles.multiblocktool,'joined_data_new');
    nm = 'JoinedDataNew';
  case 'model'
    obj = getappdata(handles.multiblocktool,'model');
    nm = 'MultiblockModel';
end

if ~isempty(obj)
  svdlgpls(obj,['Save ' nm],nm)
end

%--------------------------------------------------------------------
function editoptions(h, eventdata, handles, varargin)
%Edit options using optionsGUI for current analysis.

switch varargin{1}
  case 'gui'
    opts = getappdata(handles.multiblocktool,'gui_options');
    outopts = optionsgui(opts);
    if ~isempty(outopts)
      setappdata(handles.multiblocktool,'gui_options',outopts);
      if ~strcmp(opts.renderer,outopts.renderer)
        %Change renderer.
        set(handles.multiblocktool,'renderer',outopts.renderer);
      end
    end
  case 'function'
    opts = getappdata(handles.multiblocktool,'fcn_options');
    outopts = optionsgui(opts);
    if ~isempty(outopts)
      setappdata(handles.multiblocktool,'fcn_options',outopts);
    end
end

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

%TODO: see if we can detect .editor_handle is being deleted and remove it
%from mydata.

%Update data.
handles  = guihandles(h);
mydata   = getappdata(handles.multiblocktool,'mbdata');
if isempty(userdata)
  cellid   = myobj.id.properties.userdata.cellid;
  celltype = myobj.id.properties.userdata.celltype;
else
  cellid   = userdata.cellid;
  celltype = userdata.celltype;
end
thisdata = mydata(ismember({mydata.id},cellid));
objdata  = myobj.object;

if isdataset(objdata)
  switch celltype
    case 'rawdata'
      thisdata.rawdata = objdata;
    case 'newdata'
      thisdata.newdata = objdata;
    otherwise
      
  end
  %If data is modified then any model is obsolete.
  thisdata.model = [];
  if length(thisdata.preprocessing)==1 & strcmpi(thisdata.preprocessing.keyword,'autoscale')
    %Return pp to data default if it's on the model default.
    thisdata.preprocessing = preprocess('default','blockvariance');
  end
elseif ismodel(objdata)
  %If adding model for first time, check for default pp on data and
  %change to autoscael for model.
  if isempty(thisdata.model) & length(thisdata.preprocessing)==1 & strcmpi(thisdata.preprocessing.keyword,'blockvariance')
    thisdata.preprocessing = preprocess('default','autoscale');
  end
  thisdata.model = objdata;
end

mydata(ismember({mydata.id},cellid)) = thisdata;
setappdata(handles.multiblocktool,'mbdata',mydata);
if ~strcmpi(keyword,'quiet')
  %Clear mulitblock model.
  clear_Callback(handles.multiblocktool,[],handles,'model');
end
update_graph(handles);


%--------------------------------------------------------------------
function sdoid = set_SDO(handles,myid,celltype)
%Set sharred data item.

%Set shareddata.
sdoid = get_SDO(handles,myid,celltype);

if nargin<4
  myprops = [];
end

thisdata    = get_current_data(handles,myid);
thisdataraw = get_raw_data(thisdata,celltype);%Create dataset from model if needed.

myuserdata.cellid = myid;
myuserdata.celltype = celltype;

if isempty(sdoid)
  if~isempty(thisdata)
    %Adding for the first time.
    myprops.itemType = celltype;
    myprops.itemIsCurrent = 1;
    myprops.itemReadOnly = 0;
    myprops.userdata = myuserdata;
    sdoid = setshareddata(handles.multiblocktool,thisdataraw,myprops);
    linkshareddata(sdoid,'add',handles.multiblocktool,'multiblocktool',myuserdata);
  else
    %Don't add an empty data object.
  end
else
  if ~isempty(thisdata)
    %Update shareddata.
    if ~isempty(myprops)
      %update properties (quietly - without propogating callbacks)
      updatepropshareddata(sdoid,'update',myprops,'quiet')
    end
    setshareddata(sdoid,thisdataraw,'quiet');
  else
    %Set to empty = clear shareddata.
    removeshareddata(sdoid,'standard');
  end
end

%--------------------------------------------------------------------
function out = get_current_data(handles,myid)
%Get current data based on appdata (set when node is clicked in clickCallbackFcn).
%Input 'myid' will search for given ID rather than current data.

out = [];
if nargin>1
  myidx = myid;
else
  myidx = setappdata(handles.multiblocktool,'current_clicked_cell',myid);
end

if ~isempty(myidx)
  mydata = getappdata(handles.multiblocktool,'mbdata');
  mypos = ismember({mydata.id},myidx);
  if ~isempty(mydata) && any(mypos)
    out = mydata(mypos);
  else
    evriwarndlg('Current data not available. Try making clicking on node to select data.')
  end
end

%--------------------------------------------------------------------
function sdoID = get_SDO(handles,myid,celltype)
%Get SDO.

queryprops.itemType = celltype;
queryprops.itemIsCurrent = 1;
queryprops.userdata = struct('cellid',myid,'celltype',celltype);
sdoID = searchshareddata(handles.multiblocktool,'query',queryprops);

if length(sdoID)>1
  error(['There appears to be more than one current ' myitem ' registered.']);
end

%-------------------------------------------------
function dragEnterCallbackFcn(obj, ev, varargin)
%disp('drag enter')
setappdata(varargin{1},'TreeHoverTimestamp',[]);

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
function update_graph(handles)
%Add or update cells as needed. Some repositioning is done here rather than
%resize callback because we're already looping through the data. Note that
%resize callback is called at end of this function.

mydata  = getappdata(handles.multiblocktool,'mbdata');
mygraph = getappdata(handles.multiblocktool,'mbgraph');
mycells = GetCells(mygraph);%nx2 cell with id in first column.
leftpos = 10;

mbmodel = getappdata(handles.multiblocktool,'model');
jdata   = getappdata(handles.multiblocktool,'joined_data');
jdatanew   = getappdata(handles.multiblocktool,'joined_data_new');
figpos  = get(handles.multiblocktool,'position');
% if isempty(mydata)
%   %Clear all vertices and edges.
%   startlane = mygraph.GetCell('startdata');
%   return
% end
g = mygraph.Graph;

rawdataids = [];
if ~isempty(mydata)
  %Make list of of rawdata ids.
  rawdataids = [{mydata.id}' repmat({'_rawdata'},length(mydata),1)];
  %Join columns.
  rawdataids = str2cell(cell2str(rawdataids));
end

%Cull out any deleted cells.
rdata = ~cellfun('isempty',(strfind(mycells(:,1),'_rawdata')));%Index of raw data cells.
rdatacells = mycells(rdata,1);
for i = 1:length(rdatacells)
  [cellid, celltype] = getcellinfo(rdatacells{i});
  %If this dataid is not found then remove all of it's associated cells.
  if isempty(mydata) | (~isempty(cellid) & ~ismember(cellid,{mydata.id}))
    del_cells = find(~cellfun('isempty',(strfind(mycells(:,1),cellid))));
    for j = 1:length(del_cells)
      g.removeCells(mycells(del_cells(j),2));
      drawnow
    end
  end
end

%Get current cells (after delete).
mycells = GetCells(mygraph);
%Get history below if it's available to name join types.
join_history = {};
join_history_new = {};

leftpos = 15;
for i = 1:length(mydata)
  
  %Get raw data type.
  if ~isempty(mydata(i).rawdata)
    mystyle = 'data_loaded';
  else
    mystyle = 'data_unloaded';
  end
  
  %Build all vertices and edges then adjust visiblity and posisiton as
  %needed.
  vertexparents = {'startdata' 'models' 'modelfields'  'preprocessing'  'joindata'  'newdata'  'joinnewdata'};
  %!!! Visibility code below depends on the order of this cell array. Change
  %carefully!
  vertexnames   = {'_rawdata' '_model' '_modelfields' '_preprocessing' '_joindata' '_newdata' '_joinnewdata'};
  vertextlabel  = {'Data' 'Model' 'Model Fields' 'Preprocessing' 'Joined Data' 'New Data' 'Joined Data'};
  vertexstyleunloaded   = {'data_unloaded' 'model_unloaded' 'model_unloaded' 'preprocessing_unloaded' 'data_unloaded_gray' 'data_unloaded' 'data_unloaded_gray'};
  vertexstyleloaded   = {'data_loaded' 'model_loaded' 'model_loaded' 'preprocessing_loaded' 'data_loaded' 'data_loaded' 'data_loaded'};
  
  %   %Eache edge has name, source and targe. So nx3 cell array [name source target].
  %   edgenames     = {'rawdatatomodel' '_rawdata' '_model'};
  
  %Structure lists for vertex and edge, do a bulk add below because it's
  %faster.
  myvertexstruct = [];
  myedgestruct = [];
  
  %If raw data vertex is not created, assume we need to create all
  %(vertical) vertices and edges for a given raw data cell.
  if ~ismember(rawdataids(i),mycells(:,1))
    for j = 1:length(vertexnames)
      myvertexstruct = [myvertexstruct EVGraph.getDefaultVertex('Tag',[mydata(i).id vertexnames{j}],'Label',vertextlabel{j},'Parent',vertexparents{j},'Position',[leftpos 30 100 35],'Style',vertexstyleunloaded{j})];
      if j>1 & ~strcmp(vertexnames{j},'_newdata')
        %Add edges to each vertex in the chain exept between cal and val
        %data.
        myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag',[mydata(i).id vertexnames{j-1} '_to' vertexnames{j}],'Label','','Source',[mydata(i).id vertexnames{j-1}],'Target',[mydata(i).id vertexnames{j}],'Style','evriEdge')];
      end
    end
    %Add edge from data to pp.
    myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag',[mydata(i).id vertexnames{1} '_to' vertexnames{4}],'Label','','Source',[mydata(i).id vertexnames{1}],'Target',[mydata(i).id vertexnames{4}],'Style','evriEdge')];
    
    if i>1
      %Add edges for join to join.
      myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag',[mydata(i).id '_joindatatojoindata'],'Label','','Source',[mydata(i-1).id '_joindata'],'Target',[mydata(i).id '_joindata'],'Style','evriEdgeOval')];
      myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag',[mydata(i).id '_joinnewdatatojoinnewdata'],'Label','','Source',[mydata(i-1).id '_joinnewdata'],'Target',[mydata(i).id '_joinnewdata'],'Style','evriEdgeOval')];
    end
    
    %Need to add vertex list first then edge.
    mygraph.AddVertex(myvertexstruct);
    mygraph.AddEdge(myedgestruct);
  else
    %Move cells over to next x position.
    
    %Shift to correct position and update data style.
    for j = vertexnames;
      thiscell = GetCell(mygraph,[mydata(i).id j{:}]);
      thiscell.getGeometry.setX(leftpos);
      if strcmp(j{:},'_joindata')
        if ~isempty(jdata)
          SetStyle(mygraph,[mydata(i).id j{:}],'data_loaded');
        else
          SetStyle(mygraph,[mydata(i).id j{:}],'data_unloaded_gray');
        end
      end
      
      if strcmp(j{:},'_joinnewdata')
        if ~isempty(jdatanew)
          SetStyle(mygraph,[mydata(i).id j{:}],'data_loaded');
        else
          SetStyle(mygraph,[mydata(i).id j{:}],'data_unloaded_gray');
        end
      end
      
    end
    
    %Check for join to join edges.
    if i>1
      %Check for join since data may have been deleted.
      
      thiscell = GetCell(mygraph,[mydata(i).id '_joindatatojoindata']);
      if isempty(thiscell)
        %Data must have been deleted so create new edge.
        myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag',[mydata(i).id '_joindatatojoindata'],'Label','','Source',[mydata(i-1).id '_joindata'],'Target',[mydata(i).id '_joindata'],'Style','evriEdgeOval')];
        myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag',[mydata(i).id '_joinnewdatatojoinnewdata'],'Label','','Source',[mydata(i-1).id '_joinnewdata'],'Target',[mydata(i).id '_joinnewdata'],'Style','evriEdgeOval')];
        mygraph.AddVertex(myvertexstruct);
        mygraph.AddEdge(myedgestruct);
        thiscell = GetCell(mygraph,[mydata(i).id '_joindatatojoindata']);
      end
      
      if ~isempty(jdata) & isempty(join_history) & isfield(jdata.userdata,'join_history')
        join_history = jdata.userdata.join_history;
      end
      
      if ~isempty(jdatanew) & isempty(join_history_new) & isfield(jdatanew.userdata,'join_history')
        join_history_new = jdatanew.userdata.join_history;
      end
      
      if ~isempty(join_history)
        thiscell.setValue(join_history{i-1})
      else
        thiscell.setValue('')
      end
      
      thiscellnew = GetCell(mygraph,[mydata(i).id '_joinnewdatatojoinnewdata']);
      if ~isempty(join_history_new)
        thiscellnew.setValue(join_history_new{i-1})
      else
        thiscellnew.setValue('')
      end
      
    end
    
  end
  
  %*****************************************
  %Check for style and what to make visible.
  %Adjust data.
  if ~isempty(mydata(i).rawdata)
    SetStyle(mygraph,[mydata(i).id vertexnames{1}],'data_loaded')
  else
    SetStyle(mygraph,[mydata(i).id vertexnames{1}],'data_unloaded')
  end
  
  %Adjust model, model fields, and connectors.
  if ~isempty(mydata(i).model)
    SetStyle(mygraph,[mydata(i).id vertexnames{2}],'model_loaded')
    SetVisible(mygraph,{[mydata(i).id vertexnames{2}] ...
      [mydata(i).id vertexnames{3}] [mydata(i).id vertexnames{2} '_to' vertexnames{3}]...
      [mydata(i).id vertexnames{3} '_to' vertexnames{4}]},true)
    SetVisible(mygraph,{[mydata(i).id vertexnames{1} '_to' vertexnames{4}]},false)
    if isempty(mydata(i).rawdata)
      %If only model is loaded the set raw data visible off.
      SetVisible(mygraph,{[mydata(i).id vertexnames{1}] [mydata(i).id vertexnames{1} '_to' vertexnames{2}]},false)
    else
      SetVisible(mygraph,{[mydata(i).id vertexnames{1}] [mydata(i).id vertexnames{1} '_to' vertexnames{2}]},true)
    end
    if isempty(mydata(i).modelfields)
      SetStyle(mygraph,[mydata(i).id vertexnames{2}],'model_loaded')
    else
      SetStyle(mygraph,[mydata(i).id vertexnames{2}],'model_loaded')
    end
  else
    %Not sure if we'll have visible or not so just set style and visibility
    %for now.
    SetStyle(mygraph,[mydata(i).id vertexnames{2}],'model_unloaded')
    SetVisible(mygraph,{[mydata(i).id vertexnames{2}] [mydata(i).id vertexnames{1} '_to' vertexnames{2}]...
      [mydata(i).id vertexnames{3}] [mydata(i).id vertexnames{2} '_to' vertexnames{3}]...
      [mydata(i).id vertexnames{3} '_to' vertexnames{4}]},false)
    SetVisible(mygraph,{[mydata(i).id vertexnames{1} '_to' vertexnames{4}]},true)
    %If no model then make sure modelfields is empty.
  end
  
  if ~isempty(mydata(i).modelfields)
    %Visibility is handeld in model statement above.
    SetStyle(mygraph,[mydata(i).id vertexnames{3}],'model_loaded')
  else
    SetStyle(mygraph,[mydata(i).id vertexnames{3}],'model_unloaded')
  end
  
  if ~isempty(mydata(i).newdata)
    %Visibility is handeld in model statement above.
    SetStyle(mygraph,[mydata(i).id vertexnames{6}],'data_loaded')
  else
    SetStyle(mygraph,[mydata(i).id vertexnames{6}],'data_unloaded')
  end
  
  leftpos = leftpos+140;
  
end

modelstyle = 'model_unloaded';
datastyle = 'data_unloaded';
if ~isempty(mbmodel)
  modelstyle = 'model_loaded';
  datastyle = 'data_loaded';
end

jdpos = mygraph.GetCellPosition('joindata');

%*****************************************
%Style for Joined Data, MB Model and Post Join Model

%Update model cell.
if ~ismember('multiblock_model',mycells(:,1))
  %Create model cell.
  mygraph.AddVertex(EVGraph.getDefaultVertex('Tag','multiblock_model','Label','Multiblock Model','Position',[10 20 150 35],'Style','model_unloaded2'));
else
  %Update
  thiscell = GetCell(mygraph,'multiblock_model');
%   thiscell.getGeometry.setX(20);
%   thiscell.getGeometry.setY(20);
  if ~isempty(mbmodel)
    SetStyle(mygraph,'multiblock_model','model_loaded2');
  else
    SetStyle(mygraph,'multiblock_model','model_unloaded2');
  end
end

% if ~ismember('mbmodeltopostjoinmodel',mycells(:,1)) & ~isempty(mydata)
%   mygraph.AddEdge(EVGraph.getDefaultEdge('Tag','mbmodeltopostjoinmodel','Label','','Source',[mydata(i).id '_joindata'],'Target','multiblock_model','Style','evriEdge'));
% end

%Update joined data all.
if ~ismember('multiblock_joineddataall',mycells(:,1))
  %Create model cell.
  mygraph.AddVertex(EVGraph.getDefaultVertex('Tag','multiblock_joineddataall','Label','Joined Data','Position',[170 20 150 35],'Style','data_unloaded2'));
  mygraph.AddVertex(EVGraph.getDefaultVertex('Tag','multiblock_joineddatanewall','Label','Joined New Data','Position',[330 20 150 35],'Style','data_unloaded2'));
  
  modeltojdstyle = 'edgeStyle=orthogonalEdgeStyle;elbow=vertical;exitX=.5;exitY=0;entryX=.5;entryY=0;strokeWidth=2;endArrow=none;rounded=0;segment=70';
  %mygraph.AddVertex(EVGraph.getDefaultVertex('Tag','multiblock_joineddataall','Label','Joined Data','Position',[300 jdpos(2)+jdpos(4)+10 150 35],'Style',datastyle));
  %mygraph.AddEdge(EVGraph.getDefaultEdge('Tag','mbmodeltojoindataall','Label','','Source','multiblock_model','Target','multiblock_joineddataall','Style',modeltojdstyle));
  %mygraph.AddEdge(EVGraph.getDefaultEdge('Tag','mbmodeltojoindataall','Label','','Source','multiblock_model','Target','multiblock_joineddatanewall','Style',modeltojdstyle));
else
  %Update
  %   thiscell = GetCell(mygraph,'multiblock_joineddataall');
  %   thiscell2 = GetCell(mygraph,'multiblock_joineddatanewall');
  %   thiscell.getGeometry.setX(170);
  %   thiscell.getGeometry.setY(20);
  %   thiscell2.getGeometry.setX(330);
  %   thiscell2.getGeometry.setY(20);
  if ~isempty(jdata)
    SetStyle(mygraph,'multiblock_joineddataall','data_loaded2');
  else
    SetStyle(mygraph,'multiblock_joineddataall','data_unloaded2');
  end
  
  if ~isempty(jdatanew)
    SetStyle(mygraph,'multiblock_joineddatanewall','data_loaded2');
  else
    SetStyle(mygraph,'multiblock_joineddatanewall','data_unloaded2');
  end
  
end

% %Update post join model cell.
% if ~ismember('multiblock_postjoinmodel',mycells(:,1))
%   %Create model cell.
%   mygraph.AddVertex(EVGraph.getDefaultVertex('Tag','multiblock_postjoinmodel','Label','Post Join Model','Position',[500 jdpos(2)+jdpos(4)+10 150 35],'Style',modelstyle));
%   mygraph.AddEdge(EVGraph.getDefaultEdge('Tag','joineddataalltopostjoinmodel','Label','','Source','multiblock_joineddataall','Target','postjoin_model','Style','evriEdge'));
% else
%   %Update
%   thiscell = GetCell(mygraph,'multiblock_postjoinmodel');
%   thiscell.getGeometry.setX(500);
%   thiscell.getGeometry.setY(jdpos(2)+jdpos(4)+10);
%   SetStyle(mygraph,'multiblock_postjoinmodel',modelstyle);
% end

%g.setSelectionCells(curselction);
updatedescriptions(handles);

%Enable buttons.
if ~isempty(mydata)
  set(handles.calcmodel,'enable','on')
else
  set(handles.calcmodel,'enable','off')
end

drawnow
resize_callback(handles.multiblocktool,[],handles)

%-------------------------------------------------
function mydesc = getdescription(obj)
%Get description string for an object.

if isdataset(obj)
  myname = obj.name;
  if isempty(myname)
    myname = 'Unnamed';
  end
  mysize = obj.sizestr;
elseif ismodel(obj)
  myname = [obj.modeltype ' Model'];
  mysize = sprintf('%ix',obj.datasource{1}.size);
  mysize = mysize(1:end-1);
else
  error('EVRI:MultiblocktoolWrongDatatype',['Data type: ' class(obj) ' not supported.'])
end

mydesc = sprintf('%s\n%s',myname,mysize);

%-------------------------------------------------
function mydesc = updatedescriptions(handles)
%Update description string for model and prepro veticies.

mydata  = getappdata(handles.multiblocktool,'mbdata');
mygraph = getappdata(handles.multiblocktool,'mbgraph');
mycells = GetCells(mygraph);%nx2 cell with id in first column.
jdata   = getappdata(handles.multiblocktool,'joined_data');
jdatanew   = getappdata(handles.multiblocktool,'joined_data_new');

if ~isempty(jdata)
  %Get the first Augmented Data class to determine size of joined data.
  augmentidx = jdata.classname(2,:);
  if ~isempty([augmentidx{:}])
    augmentidx = ismember(augmentidx,'Augmented Data');
    augmentidx = find(augmentidx);
    augmentidx = augmentidx(1);
    augclass   = jdata.class{2,augmentidx};
    augclass_counts = hist(augclass,length(unique(augclass)));
  else
    augclass_counts = size(jdata,2);
  end
end

if ~isempty(jdatanew)
  %Get the first Augmented Data class to determine size of joined data.
  augmentidx = jdatanew.classname(2,:);
  if ~isempty([augmentidx{:}])
    augmentidx = ismember(augmentidx,'Augmented Data');
    augmentidx = find(augmentidx);
    augmentidx = augmentidx(1);
    augclass   = jdatanew.class{2,augmentidx};
    augclass_counts_new = hist(augclass,length(unique(augclass)));
  else
    augclass_counts_new = size(jdatanew,2);
    
  end
end

if ~isempty(mycells)
  %Loop through pp cells and update
  for i = 1:length(mydata)
    
    %Data.
    datadesc = 'Empty';
    if ~isempty(mydata(i).rawdata)
      datadesc = getdescription(mydata(i).rawdata);
    end
    setcellvalue(mygraph,[mydata(i).id '_rawdata'],datadesc)
    
    %New Data.
    datadesc = 'Empty';
    if ~isempty(mydata(i).newdata)
      datadesc = getdescription(mydata(i).newdata);
    end
    setcellvalue(mygraph,[mydata(i).id '_newdata'],datadesc)
    
    %Model.
    datadesc = 'Empty';
    if ~isempty(mydata(i).model)
      datadesc = getdescription(mydata(i).model);
    end
    setcellvalue(mygraph,[mydata(i).id '_model'],datadesc)
    
    %Model fields.
    mfdesc = 'None';
    if ~isempty(mydata(i).modelfields)
      mfdesc = [num2str(size(mydata(i).modelfields,1)) ' Fields'];
    end
    setcellvalue(mygraph,[mydata(i).id '_modelfields'],mfdesc);
    
    %Preprocessing.
    ppdesc = 'None';
    if ~isempty(mydata(i).preprocessing)
      thisprepro      = mydata(i).preprocessing;
      if ~isempty(thisprepro)
        ppdesc = [thisprepro(1).description];
        if length(thisprepro)>1
          ppdesc = [ppdesc char(10) thisprepro(2).description];
        end
        if length(thisprepro)>2
          ppdesc = [ppdesc char(10) '...'];
        end
      end
    end
    setcellvalue(mygraph,[mydata(i).id '_preprocessing'],ppdesc);
    
    %Joined data accumulative size.
    jddesc = 'Joined Data';
    if ~isempty(jdata)
      jdsize = size(jdata);
      mysize = sprintf('%ix',[jdsize(1) sum(augclass_counts(1:i))]);
      mysize = mysize(1:end-1);
      jddesc = [jddesc char(10) mysize];
    end
    setcellvalue(mygraph,[mydata(i).id '_joindata'],jddesc);
    
    jddesc = 'Joined Data';
    if ~isempty(jdatanew)
      jdsize = size(jdatanew);
      mysize = sprintf('%ix',[jdsize(1) sum(augclass_counts_new(1:i))]);
      mysize = mysize(1:end-1);
      jddesc = [jddesc char(10) mysize];
    end
    setcellvalue(mygraph,[mydata(i).id '_joinnewdata'],jddesc);
    
  end
  mygraph.Graph.refresh
end

%--------------------------
function setcellvalue(mygraph,cellname,val)
%Set text in cell.

thiscell = GetCell(mygraph,cellname);
if ~isempty(thiscell)
  thiscell.setValue(val)
end

%--------------------------------------------------------------------
function calcmodel_Callback(h,eventdata,handles,varargin)
%Calculate a MB model.

opts    = getappdata(handles.multiblocktool,'fcn_options');
mydata  = getappdata(handles.multiblocktool,'mbdata');

if ~all(cellfun('isempty',{mydata.model}) == cellfun('isempty',{mydata.modelfields}))
  %Need to check if model fields are assigned and get them if they are
  %not.
  evriwarndlg('One or more models do not have fields selected. Double-click on Model Fields icon to choose fields.', 'Choose Model Fields')
  return
end

mbmod = getappdata(handles.multiblocktool, 'model');

if isempty(mbmod)
  % no model saved to app => need to calibrate on source data and apply to
  % new data (if loaded)
  
  opts.preprocessing = {mydata.preprocessing};
  opts.filter        = {mydata.modelfields};
  
  %Assemble multiblock input.
  mbdata = {};
  for i = 1:length(mydata)
    thisdata = mydata(i).rawdata;
    if ~isempty(mydata(i).model)
      thisdata = mydata(i).model;
    end
    mbdata = [mbdata {thisdata}];
  end
  
  %Calibrate the mb model.
  [mbmod, joined_data] = multiblock(mbdata,opts);
  setappdata(handles.multiblocktool,'model',mbmod);
  setappdata(handles.multiblocktool,'joined_data',joined_data);
  
  try
    modelcache(mbmod,mbdata)
  catch
    disp(encode(lasterror))
  end
  
  %Join new data if available.
  emptyspot = cellfun('isempty',{mydata.newdata});
  if all(~emptyspot)
    joinedNewData = multiblock({mydata.newdata}, mbmod);
    setappdata(handles.multiblocktool,'joined_data_new',joinedNewData);
  end
else
  if multiblock('isPreProCalibrated',mbmod)
    % MB model is saved to app and the preprocessing steps are calibrated
    opts.preprocessing = {mbmod.options.preprocessing};
    opts.filter        = {mydata.modelfields};
    emptyspot = cellfun('isempty',{mydata.newdata});
    if all(~emptyspot)
      joinedNewData = multiblock({mydata.newdata}, mbmod);
      setappdata(handles.multiblocktool,'joined_data_new',joinedNewData);
    end
  else
    % really shouldn't get here - means that there is a MB model created
    % which does not have calibrated preprocessing
    return
  end
end


update_graph(handles);

%-------------------------------------------------------------
function adopt(handles,child)
%Add a given child handle to a child list so can be closed when gui closes.

children = getappdata(handles.multiblocktool,'child_figures');
children = union(children,child);
setappdata(handles.multiblocktool,'child_figures',children);

%--------------------------------------------------------------------
function update_from_analysis(fig,action,item,obj,myid)
%Addon command from Analysis setobj action.
% This should only happen when pushing data into analysis (analyzing data
% when there's no model). If loading a model then shareddata object can be
% accessed.

switch action
  case 'post'
    switch item
      case 'model'
        %See if there's a link to multiblock.
        if ~isempty(myid)
        modellinks = myid.links;
        for i = 1:length(modellinks)
          if strcmp(modellinks(i).callback,'multiblocktool')
            %Multiblock tool is already linked so return.
            return
          end
        end
        else
          return;
        end
        
        %If model is empty then user probably changed analysis that cleared
        %data. 
        if isempty(myid.object)
          return
        end
        
        %Get xblock, this should have id link to multiblock figure that is
        %parent of the model. Have to do lookup this way since we're coming
        %blind from analysis.
        figobj = evrigui(fig);
        xid = figobj.getXblockId;
        if isempty(xid)
          return
        end
        
        lnks = xid.links;
        myfig = [];
        for i = 1:length(lnks)
          if strcmp(lnks(i).callback,'multiblocktool')
            myfig = lnks(i).handle;
            cellid = lnks(i).userdata.cellid;
            break
          end
        end
        
        if isempty(myfig)
          return
        end
        
        %Check to see if this item exists already.
        linkshareddata(myid,'add',myfig,'multiblocktool',lnks(i).userdata);
        %Need to add model and update graph.
        updateshareddata(myfig,myid,'modify',lnks(i).userdata)
    end
end


%-----------------------------------------------------------------
function out = optiondefs()
defs = {
  %name                    tab              datatype        valid                            userlevel       description
  'renderer'               'Image'          'select'        {'opengl' 'zbuffer' 'painters'}  'novice'        'Figure renderer (selection will affect alpha and performance).';
  
  };
out = makesubops(defs);
% 

