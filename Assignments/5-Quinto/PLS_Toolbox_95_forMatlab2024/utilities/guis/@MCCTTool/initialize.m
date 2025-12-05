function obj = initialize(obj,incoming_props)
%CALTRANSFERTOOL/INITIALIZE Set initial info of object.
% Build initial window and controls.

% Copyright © Eigenvector Research, Inc. 2016
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


% Create main window
fig = figure('Tag','caltransfertoolfigure',...
  'NumberTitle', 'off', ...
  'HandleVisibility','callback',...
  'Integerhandle','off',...
  'Name', 'Model Centric Calibration Transfer Tool',...
  'Renderer','OpenGL',...
  'MenuBar','none',...
  'visible','on',...
  'color',[.95 .95 .95],...
  'CloseRequestFcn', {@closeGUI, obj},...
  'Units','pixels');
obj.mainFigure = fig;

%Check if javaset has been run.
if ~exist('DropTargetList','class'); evrijavasetup; end

% Use waitbar when making slave models.
obj.UseWaitbar = 1;

positionmanager(fig,'MCCTTool')
centerfigure(fig);

%Save object to main figure.
setappdata(fig,'MCCToolObject',obj);

%Add menus.
addmenus(obj,fig)

%Add toolbar.
addtoolbar(obj,fig)

%Add panels and controls.
addpanelcontrols(obj,fig)

%Add drag drop handler.
figdnd = evrijavaobjectedt(DropTargetList);%EVRI Custom drop target class.
figdnd = handle(figdnd,'CallbackProperties');
jFrame = get(handle(fig),'JavaFrame');

jAxis  = jFrame.getAxisComponent;
jAxis.setDropTarget(figdnd);
set(figdnd,'DropCallback',@(src,evt) dropCallback(obj,src,evt));

addtable(obj,fig)

addcaltcontrols(obj,fig)

%Add main save and close button.
savebtn = uicontrol(fig,'Style','pushbutton','String','Save',...
    'Units','Normalized','Position',[.71 .005 .14 .05],...
    'tag','mainSaveButton','fontsize',obj.guiFontSize,...
    'tooltip','Save current secondary model',...
    'Callback',@(src,evt) menuCallback(obj,src,evt,'mainsave',''));
  
closebtn = uicontrol(fig,'Style','pushbutton','String','Close',...
    'Units','Normalized','Position',[.855 .005 .14 .05],...
    'tag','mainCloseButton','fontsize',obj.guiFontSize,...
    'tooltip','Close window',...
    'Callback',@(src,evt) menuCallback(obj,src,evt,'mainclose',''));

%Force update of table in case figure is being created from saved object.
obj.forceUpdateTable = true;
  
obj.updateWindow(1)

end


%--------------------------------------------------------------------------
function addtable(obj,fig)
%Create etable object. 

mytbl = etable('parent_figure',fig,'tag','resulttable','autoresize','AUTO_RESIZE_OFF',...
  'custom_cell_renderer','on','cell_click_selection','row','column_sort','off',...
  'units','normalized','position',[0.005 0.06 .99 .4],'FontSize',obj.guiFontSize,...
  'column_labels',{'CAL/VAL' 'PP Index' 'TransferType' 'X Preprocessing' 'Model ID'},...
  'data',{' ' ' ' ' ' ' ' ' '},...
  'row_multiselection','on','column_sort','on','editable','off',...
  'table_clicked_callback',@(src,evt) tableCallback(obj,src,evt,1),...
  'row_clicked_callback',@(src,evt) tableCallback(obj,src,evt,1),...
  'row_doubleclicked_callback',@(src,evt) tableCallback(obj,src,evt,2));

% Use post sort callback to recolor cells if using coloring.
%'post_sort_callback', {@update_after_sort,fig})

mytbl.grid_color = [.9 .9 .9];%Grid color is light grey.
mytbl.row_header_width = 70;
mytbl.editable = 'off';%Don't allow edits on table.

%TODO: Add click callback to load model, insertpp,  line into interface

end

%--------------------------------------------------------------------------
function addtoolbar(obj,fig)
%Add toolbar.
toolbar(fig,'mccttool');
drawnow;
handles = guihandles(fig);
%Need to assign callback on object since toolbar isn't object aware yet.
for i = {'setopts' 'calcmodel' 'zoomwin' 'zoomin' 'zoomout' 'zoomdefault' 'maketable'}
  set(handles.(i{:}),'ClickedCallback',@(src,evt) menuCallback(obj,src,evt,'buttonclick',i{:}))
end

end

%--------------------------------------------------------------------------
function addcaltcontrols(obj,fig)
%Panels and controls for calt survey setup.

modeltypesh = uipanel(fig,'tag','caltransfer_methods','Title','Calibration Transfer Model Types',...
  'Units','Normalized','position',[0.005 0.47 .495 .22],'fontsize',obj.guiFontSize);

settingsh = uipanel(fig,'tag','caltransfer_combos','Title','Calibration Transfer Model Settings',...
  'Units','Normalized','position',[0.50 0.47 .495 .22],'fontsize',obj.guiFontSize);

ctypes = {'ds'       'Direct Standardization (DS)'                 ;
  'pds'      'Piecewise Direct Standardization (PDS)'               ;
  'dwpds'    'Double Window Piecewise Direct Standardization (DWPDS)' ;
  'sst'      'Spectral Space Transformation (SST)'                  ;
  };

btm = .80;
for i = 1:size(ctypes,1)
  r = uicontrol(modeltypesh,'Style','radiobutton','String',ctypes{i,2},...
    'Units','Normalized','Position',[.03 btm .9 .2],...
    'tag',ctypes{i,1},'fontsize',obj.guiFontSize,'Callback',@obj.updateWindow);
  btm = btm - .23;
end

instpp = uicontrol(modeltypesh,'Style','pushbutton','String','Prepo Insert',...
  'Units','Normalized','Position',[.7 .81 .28 .2],...
  'tag','insterppbutton','fontsize',obj.guiFontSize,...
  'HorizontalAlignment', 'center','Callback',@(src,evt) menuCallback(obj,src,evt,'buttonclick','setinsertpp'));

combobtn = uicontrol(modeltypesh,'Style','pushbutton','String','Calculate',...
    'Units','Normalized','Position',[.7 .01 .28 .2],...
    'tag','calcCombosButton','fontsize',obj.guiFontSize,'Callback',@(src,evt) menuCallback(obj,src,evt,'calccombo',''));
  
btm = .80;

edt = uicontrol(settingsh,'Style','text','String','Min',...
  'Units','Normalized','Position',[.45 btm .18 .17],...
  'tag',[ctypes{i,1} '_1'],'fontsize',obj.guiFontSize,...
  'enable','on','HorizontalAlignment', 'center');
edt = uicontrol(settingsh,'Style','text','String','Step',...
  'Units','Normalized','Position',[.66 btm .1 .17],...
  'tag',[ctypes{i,1} '_1'],'fontsize',obj.guiFontSize,...
  'enable','on','HorizontalAlignment', 'center');
edt = uicontrol(settingsh,'Style','text','String','Max',...
  'Units','Normalized','Position',[.77 btm .18 .17],...
  'tag',[ctypes{i,1} '_2'],'fontsize',obj.guiFontSize,...
  'enable','on','HorizontalAlignment', 'center');

ctypes = MCCTObject.getCalibrationTransferModelParams;

%Defaults.
caltopts = caltransfer('options');
caltdefaults = {num2str(caltopts.pds.win);
  num2str(caltopts.dwpds.win(1));
  num2str(caltopts.dwpds.win(2));
  num2str(caltopts.sst.ncomp);};

defaultsteps = {'2' '2' '2' '1'};

btm = btm - .20;
for i = 1:size(ctypes,1)
  lbl = uicontrol(settingsh,'Style','text','String',ctypes{i,3},...
    'Units','Normalized','Position',[.03 btm .4 .17],...
    'tag',[ctypes{i,2} '_label'],'fontsize',obj.guiFontSize,...
    'HorizontalAlignment', 'left');
  edt = uicontrol(settingsh,'Style','Edit','String',caltdefaults{i},...
    'Units','Normalized','Position',[.45 btm .18 .17],...
    'tag',[ctypes{i,2} '_1'],'fontsize',obj.guiFontSize,'BackgroundColor','white',...
    'enable','off','Callback',{@checkinput},'userdata',caltdefaults{i});
  edt = uicontrol(settingsh,'Style','Edit','String',defaultsteps{i},...
    'Units','Normalized','Position',[.66 btm .1 .17],...
    'tag',[ctypes{i,2} '_step'],'fontsize',obj.guiFontSize,'BackgroundColor','white',...
    'enable','off','Callback',{@checkinput},'userdata',1);
  edt = uicontrol(settingsh,'Style','Edit','String',caltdefaults{i},...
    'Units','Normalized','Position',[.77 btm .18 .17],...
    'tag',[ctypes{i,2} '_2'],'fontsize',obj.guiFontSize,'BackgroundColor','white',...
    'enable','off','Callback',{@checkinput},'userdata',caltdefaults{i});
  btm = btm - .18;
end

end

%--------------------------------------------------------------------------
function addpanelcontrols(obj,fig)
%Add tabs and panels and controls.

%NOTE: Use of 'block' in item name is a keyword used elsewhere to id data
%      nodes.

fpos = get(fig,'position');

%Add graph for applying.
mygraph = EVGraph(fig,'AddMouseMove',1);
mygraph.AddMouseMove = 1;
mygraph.UseToolTips = 0;
mygraph.ExternalObject = 'MCCTTool';
obj.graph = mygraph;%Save to object.

mygraph.SetGraphPosition([.005 .7 .99 .3])

%Add calibration swim pool.
mygraph.AddVertex(struct('Tag','calibrationpool','Label','Calibration','Position',[1 1 450 250],'Style','evriSwimLaneH;dashed=1'));
mygraph.AddVertex(struct('Tag','validationpool','Label','Validation','Position',[455 1 280 250],'Style','evriSwimLaneH;dashed=1'));

%Add calibration data.
%mygraph.AddVertex(struct('Tag','CalibrationMasterXData', 'Parent','calibrationpool','Label',['Master' char(10) 'X Block'],'Position',[20 30 100 36],'Style','data_unloaded;'));
mygraph.AddVertex(struct('Tag','CalibrationMasterXData', 'Parent','calibrationpool','Label',['Primary' char(10) 'X Block'],'Position',[20 30 100 36],'Style','data_unloaded;'));
mygraph.AddVertex(struct('Tag','CalibrationSlaveXData', 'Parent','calibrationpool','Label',['Secondary' char(10) 'X Block'],'Position',[20 170 100 36],'Style','data_unloaded'));
mygraph.AddVertex(struct('Tag','CalibrationYData', 'Parent','calibrationpool','Label','Y Block','Position',[20 100 100 36],'Style','data_unloaded'));

%Add validation data.
mygraph.AddVertex(struct('Tag','ValidationMasterXData', 'Parent','validationpool','Label',['Primary' char(10) 'X Block'],'Position',[20 30 100 36],'Style','data_unloaded'));
mygraph.AddVertex(struct('Tag','ValidationSlaveXData', 'Parent','validationpool','Label',['Secondary' char(10) 'X Block'],'Position',[20 170 100 36],'Style','data_unloaded'));
mygraph.AddVertex(struct('Tag','ValidationYData', 'Parent','validationpool','Label','Y Block','Position',[20 100 100 36],'Style','data_unloaded'));

%Master prepro.
mygraph.AddVertex(struct('Tag','calmasterp1', 'Parent','calibrationpool','Label',['Pre' char(10) 'Xfer'],'Position',[140 30 40 36],'Style','preprocessing_unloaded'));
%mygraph.AddVertex(struct('Tag','calmasterpinsert', 'Parent','calibrationpool','Label','','Position',[215 43 10 10],'Style','preprocessing_unloaded'));
mygraph.AddVertex(struct('Tag','calmasterp2', 'Parent','calibrationpool','Label',['Post' char(10) 'Xfer'],'Position',[270 30 40 36],'Style','preprocessing_unloaded'));

%Slave prepro.
mygraph.AddVertex(struct('Tag','calslaveprepropool', 'Parent','calibrationpool','Label','','Position',[190 160 60 60],'Style','data_unloaded_gray;entryX=.4'));
%mygraph.AddVertex(struct('Tag','calslavep1', 'Parent','calibrationpool','Label','Pre','Position',[150 170 40 35],'Style','preprocessing_unloaded'));
mygraph.AddVertex(struct('Tag','TransferModel', 'Parent','calibrationpool','Label','Xfer','Position',[200 170 40 36],'Style','preprocessing_unloaded'));
mygraph.AddVertex(struct('Tag','calslavep2', 'Parent','calibrationpool','Label',['Post' char(10) 'Xfer'],'Position',[270 170 40 36],'Style','preprocessing_unloaded'));

%Models.
mygraph.AddVertex(struct('Tag','MasterModel', 'Parent','calibrationpool','Label',['Primary' char(10) 'Model'],'Position',[340 66 100 36],'Style','model_unloaded'));
mygraph.AddVertex(struct('Tag','SlaveModel', 'Parent','calibrationpool','Label',['Secondary' char(10) 'Model'],'Position',[340 138 100 36],'Style','model_unloaded'));

%Predictions.
mygraph.AddVertex(struct('Tag','ValidationResults', 'Parent','validationpool','Label',['Validation' char(10) 'Results'],'Position',[150 100 100 36],'Style','prediction_unloaded'));
%mygraph.AddVertex(struct('Tag','predslave', 'Parent','validationpool','Label',['Slave' char(10) 'Prediction'],'Position',[150 130 100 36],'Style','prediction_unloaded'));

%Connectors.
myedgestruct = '';
myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','CalibrationMasterXDatajoin','Label','','Source','CalibrationMasterXData','Target','calmasterp1','Style','evriEdgeNoArrow')];
myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','p1insert','Label','','Source','calmasterp1','Target','calmasterp2','Style','evriEdgeNoArrow')];
%myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','insertp2','Label','','Source','calmasterpinsert','Target','calmasterp2','Style','evriEdgeNoArrow')];

myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','CalibrationSlaveXDatajoin','Label','','Source','CalibrationSlaveXData','Target','TransferModel','Style','evriEdgeNoArrow')];
myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','CalibrationSlaveXDatap1','Label','','Source','calslavep1','Target','TransferModel','Style','evriEdgeNoArrow')];
myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','tmodeltocalslavep2','Label','','Source','TransferModel','Target','calslavep2','Style','evriEdgeNoArrow')];

%Edges going from master pp to slave calt/pp
myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','inserttocaltransfer','Label','','Source','calmasterp1','Target','calslaveprepropool','Style','evriEdgeStraight')];
myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','calmastertoslaveP1','Label','','Source','calmasterp2','Target','calslavep2','Style','evriEdge')];

myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','calmasterp2tomodel','Label','','Source','calmasterp2','Target','MasterModel','Style','evriEdgeNoArrow')];
myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','calslavep2tomodel','Label','','Source','calslavep2','Target','SlaveModel','Style','evriEdgeNoArrow')];

myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','mastermodeltopred','Label','','Source','MasterModel','Target','ValidationResults','Style','evriEdgeNoArrow')];
myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','slavemodeltopred','Label','','Source','SlaveModel','Target','ValidationResults','Style','evriEdgeNoArrow')];

myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','mastervaltopred','Label','','Source','ValidationMasterXData','Target','ValidationResults','Style','evriEdgeNoArrow')];
myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','slavevaltopred','Label','','Source','ValidationSlaveXData','Target','ValidationResults','Style','evriEdgeNoArrow')];

myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','calytomastermodel','Label','','Source','CalibrationYData','Target','MasterModel','Style','evriEdgeNoArrow')];
myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','calytoslavemodel','Label','','Source','CalibrationYData','Target','SlaveModel','Style','evriEdgeNoArrow')];

myedgestruct = [myedgestruct EVGraph.getDefaultEdge('Tag','valytoresults','Label','','Source','ValidationYData','Target','ValidationResults','Style','evriEdgeNoArrow')];


mygraph.AddEdge(myedgestruct);

end

%--------------------------------------------------------------------------
function addmenus(obj,fig)

%Add menu items.
hmenu = uimenu(fig,'Label','&File','tag','menu_file');

lmenu = uimenu(hmenu,'tag','menu_load','label','&Load Workspace Data');
uimenu(lmenu,'tag','menu_loadcallabel','label','<html><font color="blue"><u>Calibration</u></font></html>','enable','off');
uimenu(lmenu,'tag','menu_loadcalmaster','label','&Primary','callback',@(src,evt) menuCallback(obj,src,evt,'load','CalibrationMasterXData'));
uimenu(lmenu,'tag','menu_loadcalslave','label','&Secondary','callback',@(src,evt) menuCallback(obj,src,evt,'load','CalibrationSlaveXData'));
uimenu(lmenu,'tag','menu_loadcalyblock','label','&Y-Block','callback',@(src,evt) menuCallback(obj,src,evt,'load','CalibrationYData'));

uimenu(lmenu,'tag','menu_loadvallabel','label','<html><font color="blue"><u>Validation</u></font></html>','enable','off','Separator','on');
uimenu(lmenu,'tag','menu_loadvalmaster','label','&Primary','callback',@(src,evt) menuCallback(obj,src,evt,'load','ValidationMasterXData'));
uimenu(lmenu,'tag','menu_loadvalslave','label','&Secondary','callback',@(src,evt) menuCallback(obj,src,evt,'load','ValidationSlaveXData'));
uimenu(lmenu,'tag','menu_loadvalyblock','label','&Y-Block','callback',@(src,evt) menuCallback(obj,src,evt,'load','ValidationYData'));

uimenu(hmenu,'tag','menu_loadmodel','label','&Load Primary Model','callback',@(src,evt) menuCallback(obj,src,evt,'load','MasterModel'));

uimenu(hmenu,'tag','menu_loadcaltmodel','label','&Load Calibration Transfer Model','callback',@(src,evt) menuCallback(obj,src,evt,'load','TransferModel'));

uimenu(hmenu,'tag','menu_mcctobject','label','&Save MCCT Object','callback',@(src,evt) menuCallback(obj,src,evt,'save','mccttoolobject'),'Separator','on');
uimenu(hmenu,'tag','menu_saveslavemodel','label','&Save Secondary Model','callback',@(src,evt) menuCallback(obj,src,evt,'save','modelslave'),'Separator','on');
uimenu(hmenu,'tag','menu_saveppslavedata','label','&Save Preprocessed Secondary Data','callback',@(src,evt) menuCallback(obj,src,evt,'save','slaveppdata'));

uimenu(hmenu,'tag','menu_clear','label','&Clear Results','callback',@(src,evt) menuCallback(obj,src,evt,'clear','clearresults'),'Separator','on');
uimenu(hmenu,'tag','menu_clear','label','&Clear All','callback',@(src,evt) menuCallback(obj,src,evt,'clear','clearall'),'Separator','off');

hmenu = uimenu(fig,'Label','&Edit','tag','menu_edit');

%uimenu(hmenu,'tag','includecolumns','label','&Include Columns','callback',@(src,evt) menuCallback(obj,src,evt,'columnselect','include'));
uimenu(hmenu,'tag','excludecolumns','label','&Exclude Columns','callback',@(src,evt) menuCallback(obj,src,evt,'columnselect','exclude'));

uimenu(hmenu,'tag','menu_refresh','label','&Refresh Window','callback',@(src,evt) menuCallback(obj,src,evt,'refresh',''),'separator','on');
uimenu(hmenu,'tag','menu_options','label','&Interface Options','callback',@(src,evt) menuCallback(obj,src,evt,'options','guioptions'));

hmenu = uimenu(fig,'Label','&Help','tag','menu_help');
uimenu(hmenu,'tag','menu_mainhelp','label','&Model Centric Calibration Transfer Help','callback',@(src,evt) menuCallback(obj,src,evt,'help','mainhelp'));
uimenu(hmenu,'tag','menu_demohelp','label','&Load Demo','callback',@(src,evt) menuCallback(obj,src,evt,'help','demo'));
uimenu(hmenu,'tag','menu_plshelp','label','&General Help','callback','helppls');

%Make context menu.
hcontext = uicontextmenu('parent',fig,'tag','mcctcontextmenu','callback',@(src,evt) menuCallback(obj,src,evt,'update_cmenu'));
uimenu(hcontext,'tag','cmenu_load','label','Load','callback',@(src,evt) menuCallback(obj,src,evt,'load'));
uimenu(hcontext,'tag','cmenu_import','label','Import','callback',@(src,evt) menuCallback(obj,src,evt,'import'));

uimenu(hcontext,'tag','cmenu_plot','label','Plot','callback',@(src,evt) menuCallback(obj,src,evt,'plot'));
uimenu(hcontext,'tag','cmenu_edit','label','Edit','callback',@(src,evt) menuCallback(obj,src,evt,'edit'));
uimenu(hcontext,'tag','cmenu_view','label','View','callback',@(src,evt) menuCallback(obj,src,evt,'view'));
uimenu(hcontext,'tag','cmenu_save','label','Save','callback',@(src,evt) menuCallback(obj,src,evt,'save'),'Separator','on');
uimenu(hcontext,'tag','cmenu_delete','label','Clear','callback',@(src,evt) menuCallback(obj,src,evt,'delete'));

end

%--------------------------------------------------------------------------
function checkinput(varargin)
%Check inputs of calt combinations. Make sure numeric, integer, and not
%negative. Set value back to last value via .userdata field.

h = varargin{1};
myval = str2num(get(h,'String'));

if isempty(myval) | myval<1 
  %Use old value.
  myval = get(h,'userdata');
end

if ~isint(myval)
  myval = round(myval);
end

if ismember(get(h,'tag'),{'win1_1' 'win1_2' 'win2_1' 'win2_2'})
  %Make sure it's odd.
  myval = myval+1-mod(myval,2); 
end

%Update value.
set(h,'String',num2str(myval),'userdata',myval);

end

%--------------------------------------------------------------------------
function closeGUI(varargin)
%Close widow.

obj = varargin{3};
fig = varargin{1};

try
  %Model check.
  if ~isempty(obj.SlaveModel)
    savedmods = getappdata(obj.figure,'SavedModels');
    modl = obj.SlaveModel;
    if ~ismember(modl.uniqueid,savedmods)
      ans=evriquestdlg('Secondary Model not saved. What do you want to do?', ...
        'Model Not Saved','Quit Without Saving','Save & Quit','Cancel','Quit Without Saving');
      switch ans
        case {'Cancel'}
          return
        case {'Save & Quit'}
          targname = defaultmodelname(modl,'variable','save');
          [what,where] = svdlgpls(modl,'Save Model',targname);
      end
    end
  end
  
  %close all children
  children = getappdata(fig,'staticchildplot');
  children = children(ishandle(children));
  children = children(ismember(char(get(children,'type')),{'figure'}));
  close(children);
  
  %Save options.
  setplspref('MCCTTool',obj.MCCTToolOptionalInputs)
  
  %Save figure position.
  positionmanager(fig,'MCCTTool','set');
end

drawnow;
delete(obj.graph);
if ishandle(fig)
  setappdata(fig,'MCCToolObject',[]);%Need to remove appdata or will stay in memory.
  delete(obj)
  delete(fig)
end

end
