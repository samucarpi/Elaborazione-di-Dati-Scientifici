function varargout = genericgui(varargin)
%GENERICGUI Generic GUI build code. 
% Generic code for setting up a Figure from mcode only. Use the following
% keys to search and replace.
%   tag/function = "genericgui"
%   title/name   = "Generic GUI"
%  
%
%I/O: h = genericgui() %Open gui and return gui handle.
%I/O: genericgui(data) %Open preloaded.
%
%See also: PLOTGUI

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0 || ~ischar(varargin{1}) % LAUNCH GUI
  try
    %Start GUI
    h=waitbar(1,['Starting Generic GUI...']);
    drawnow
    %Open figure and initialize
    %fig = openfig('genericgui.fig','new','invisible');
    
    fig = figure('Tag','genericgui',...
      'NumberTitle', 'off', ...
      'HandleVisibility','callback',...
      'Integerhandle','off',...
      'Name', 'Generic GUI',...
      'Renderer','OpenGL',...
      'MenuBar','none',...
      'ResizeFcn','genericgui(''resize_callback'',gcbo,[],guihandles(gcbf))',...
      'CloseRequestFcn','try;genericgui(''closereq_callback'',gcbo,[],guihandles(gcbf),0);catch;delete(gcbf);end',...
      'visible','off',...
      'Units','pixels');
    
    %Set up gui controls.
    gui_enable(fig)
    
    figbrowser('addmenu',fig); %add figbrowser link
    
    %Position gui from last known position.
    positionmanager(fig,'genericgui');
    
    handles = guihandles(fig);
    fpos = get(handles.genericgui,'position');
    
    pause(.1);drawnow
    set(fig,'visible','on');
    
    resize_callback(fig,[],handles);
    
    %Get data if passed.
    if nargin>0 && ~isempty(varargin{1})
      loaddata(fig,[],handles,'auto',varargin{1});
    end
  catch
    if ishandle(fig); delete(fig); end
    if ishandle(h); close(h);end
    erdlgpls({'Unable to start the Generic GUI' lasterr},[upper(mfilename) ' Error']);
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
gopts = genericgui('options');

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
jFrame = get(handle(handles.genericgui),'JavaFrame');
%Don't think we need to run on EDT but if the need arises be sure to
%accommodate 7.0.4. 
jAxis  = jFrame.getAxisComponent;
jAxis.setDropTarget(figdnd);
set(figdnd,'DropCallback',{@dropCallbackFcn,handles.genericgui});


%Set extra fig properties.
set(fig,'Toolbar','none')

%Add menu items.
hmenu = uimenu(fig,'Label','&File','tag','menu_file');

uimenu(hmenu,'tag','loaddatamenu','label','&Load Workspace Data','callback','genericgui(''loaddata'',gcbo,[],guidata(gcbf),''load'')');
uimenu(hmenu,'tag','importdatamenu','label','&Import Data','callback','genericgui(''loaddata'',gcbo,[],guidata(gcbf),''import'')');
uimenu(hmenu,'tag','loadmodelmenu','Separator','on','label','&Load Model','callback','genericgui(''loadmodel'',gcbo,[],guidata(gcbf))');
uimenu(hmenu,'tag','savedatamenu','Separator','on','label','&Save Data','callback','genericgui(''save_callback'',gcbo,[],guidata(gcbf),''data'')');
uimenu(hmenu,'tag','savemodelmenu','label','Save &Model','callback','genericgui(''save_callback'',gcbo,[],guidata(gcbf),''model'')');

cmenu = uimenu(hmenu,'tag','clearmenu','Separator','on','label','&Clear');
uimenu(cmenu,'tag','cleardatamenu', 'label','&Data'         ,'callback','genericgui(''clear_Callback'',gcbo,[],guidata(gcbf),''data'')');
uimenu(cmenu,'tag','clearmodelmenu','label','&Model'        ,'callback','genericgui(''clear_Callback'',gcbo,[],guidata(gcbf),''model'')');
uimenu(cmenu,'tag','clearppmenu',   'label','&Preprocessing','callback','genericgui(''clear_Callback'',gcbo,[],guidata(gcbf),''pp'')');
uimenu(cmenu,'tag','clearallmenu',  'label','&All'          ,'callback','genericgui(''clear_Callback'',gcbo,[],guidata(gcbf),''all'')','Separator','on');

uimenu(hmenu,'tag','closemenu','Separator','on','label','&Close','callback','genericgui(''loaddata'',gcbo,[],guidata(gcbf),''import'')');

hmenu = uimenu(fig,'Label','&Edit','tag','menu_edit');
uimenu(hmenu,'tag','guioptionsmenu','label','&Interface Options','callback','genericgui(''editoptions'',gcbo,[],guidata(gcbf),''gui'')');
uimenu(hmenu,'tag','functionoptionsmenu','label','&Function Options','callback','genericgui(''editoptions'',gcbo,[],guidata(gcbf),''function'')');

hmenu = uimenu(fig,'Label','&Help','tag','menu_help');
uimenu(hmenu,'tag','openhelpmenu','label','&Generic GUI Analysis Help','callback','genericgui(''openhelp_ctrl_Callback'',gcbo,[],guidata(gcbf))');

uimenu(hmenu,'tag','plshelp','label','&General Help','callback','helppls');

%Add Image place holder.
myaxis = axes('parent',fig,'tag','genericgui_axis','units','pixels',...
  'XTickLabel','','YTickLabel','','ZTickLabel','','XTick',[],'YTick',[],'ZTick',[],...
  'XColor','white','YColor','white','ZColor','white');

%Add toolbar.
%TODO: Update toolbar button set.
[htoolbar, hbtns] = toolbar(fig,'zzzz');

handles = guihandles(fig);
guidata(fig,handles);
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

opts = getappdata(handles.genericgui, 'gui_options');
set(handles.genericgui,'units','pixels');
%Get initial positions.
figpos = get(handles.genericgui,'position');

%--------------------------------------------------------------------
function openhelp_ctrl_Callback(hObject, eventdata, handles)
%Open help page.
evrihelp('genericgui')

%--------------------------------------------------------------------
function closereq_callback(h,eventdata,handles,varargin)
%Close gui.

if isempty(handles)
  handles = guihandles(h);
end

%Save figure position.
positionmanager(handles.genericgui,'genericgui','set')

if ishandle(handles.genericgui)
  delete(handles.genericgui)
end

%--------------------------------------------------------------------
function loadmodel(h,eventdata,handles,varargin)
%Load model.

mymodel = getappdata(handles.genericgui,'model');

%Check for overwrite of model.
if ~isempty(mymodel);
  ans=evriquestdlg('Clear existing model?', ...
    'Clear Model','Clear','Cancel','Clear');
  switch ans
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

setappdata(handles.genericgui,'model',mymodel);
%setappdata(handles.genericgui,'fcn_options',mymodel.detail.options)

%Update preprocess.
setappdata(handles.genericgui,'preprocessing',mymodel.detail.options.preprocessing{1});

%--------------------------------------------------------------------
function drop(h,eventdata,handles,varargin)
loaddata(h,[],handles,'auto',varargin{:})

%---------------------------------------------------------------------
function dropCallbackFcn(obj,ev,varargin)
%Parse dnd object then call drop.

handles = guihandles(varargin{1});

dropdata = drop_parse(obj,ev,'',struct('getcacheitem','on'));
if isempty(dropdata{1})
  %Probably error.
  %TODO: Process workspace vars.
  return
end

%Call load data. 
%TODO: Possible dropdata could be more than one item.
loaddata(handles.genericgui,[],handles,'auto',dropdata{:,2})

%--------------------------------------------------------------------
function loaddata(h,eventdata,handles,varargin)
%Load data.

%TODO: Add warning for more than 3D data.
opts   = getappdata(handles.genericgui, 'gui_options');

mode = varargin{1};%Type of load dialog to run.
name = '';
switch mode
  case 'import'
    %Import single image.
    aopts.importmethod = 'editds_defaultimportmethods';
    mydata = autoimport([],[],aopts);
  case 'load'
    %Load single image from mat.
    [mydata,name,location] = lddlgpls({'double' 'dataset' 'cell' 'uint8'},['Select Data']);
  case 'auto'
    %Data provided in varargin.
    mydata = varargin{2};
end

if isempty(mydata);  %canceled out of import?
  return;
else
  %Clear data.
  clear_Callback(h,eventdata,handles,'data');
end

if isshareddata(mydata)
  temp_data = mydat.object;
else
  temp_data = mydata;
end

if ~isdataset(temp_data)
  %Assume data is numeric (double uint8).
  temp_data             = dataset(temp_data);
  if ~isempty(name)
    if iscell(name)
      temp_data.name        = name{1};
    else
      temp_data.name        = name;
    end
  else
    temp_data.name        = datestr(now,'yyyymmddTHHMMSSFFF');
  end
end

setappdata(handles.genericgui,'data',temp_data)

resize_callback(handles.genericgui,[],handles);


%--------------------------------------------------------------------
function clear_Callback(h,eventdata,handles,varargin)
%Clear one or more items in gui.

item = varargin{1};

switch item
  case 'data'
    setappdata(handles.genericgui,'data',[]);
  case 'model'
    setappdata(handles.genericgui,'model',[]);
  case {'pp' 'preprocessing'}
    setappdata(handles.genericgui,'preprocessing',[]);
    return
  case 'all'
    setappdata(handles.genericgui,'data',[]);
    setappdata(handles.genericgui,'model',[]);
    setappdata(handles.genericgui,'preprocessing',[]);
end

resize_callback(h,eventdata,handles)

%--------------------------------------------------------------------
function save_callback(h,eventdata,handles,varargin)
%Save table or image to file/workspace.

obj = [];
nm = '';
switch varargin{1}
  case 'data'
    obj = getappdata(handles.genericgui,'data');
    nm = 'Data';
  case 'model'
    obj = getappdata(handles.genericgui,'model');
    nm = 'Model';
end

if ~isempty(obj)
  svdlgpls(obj,['Save ' nm],nm)
end

%--------------------------------------------------------------------
function editoptions(h, eventdata, handles, varargin)
%Edit options using optionsGUI for current analysis.

switch varargin{1}
  case 'gui'
    opts = getappdata(handles.genericgui,'gui_options');
    outopts = optionsgui(opts);
    if ~isempty(outopts)
      setappdata(handles.genericgui,'gui_options',outopts);
    end
    
    if ~strcmp(opts.renderer,outopts.renderer)
      %Change renderer.
      set(handles.genericgui,'renderer',outopts.renderer);
    end
    
  case 'function'
    opts = getappdata(handles.genericgui,'fcn_options');
    outopts = optionsgui(opts);
    if ~isempty(outopts)
      setappdata(handles.genericgui,'fcn_options',outopts);
    end
end

%--------------------------------------------------------------------
function update_callaback(handles)
%Update GUI.

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

if strcmpi(keyword,'modify') ||strcmpi(keyword,'include')
  %Update image and recalc.
  handles = guihandles(h);
  newdata = myobj.object;
  setappdata(handles.genericgui,'data',newdata);
  update_callback(handles.genericgui, [], handles)
end

%--------------------------------------------------------------------
function set_SDO(handles)
%Set image into SDO and appdata, change shareddata to reflect new image.

%Set shareddata.
myobj = getshareddata(handles.genericgui);
if ~isempty(myobj)
  %If somehow more than one object make sure use first.
  myobj = myobj{1};
end

mydata = getappdata(handles.genericgui,'data');

if isempty(myobj)
  if~isempty(mydata)
    %Adding for the first time.
    myprops.itemType = 'genericgui_data';
    myprops.itemIsCurrent = 1;
    myprops.itemReadOnly = 0;
    myid = setshareddata(handles.genericgui,mydata,myprops);
    linkshareddata(myid,'add',handles.genericgui,'genericgui');
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

%-----------------------------------------------------------------
function out = optiondefs()
defs = {
  %name                    tab              datatype        valid                            userlevel       description
  'renderer'               'Image'          'select'        {'opengl' 'zbuffer' 'painters'}  'novice'        'Figure renderer (selection will affect alpha and performance).';

  };
out = makesubops(defs);
