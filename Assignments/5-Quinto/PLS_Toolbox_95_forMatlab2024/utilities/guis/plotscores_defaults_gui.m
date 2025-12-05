function varargout = plotscores_defaults_gui(varargin)
% PLOTSCORES_DEFAULTS_GUI M-file for plotscores_defaults_gui.fig
%      PLOTSCORES_DEFAULTS_GUI, by itself, creates a new PLOTSCORES_DEFAULTS_GUI or raises the existing
%      singleton*.
%
%      H = PLOTSCORES_DEFAULTS_GUI returns the handle to a new PLOTSCORES_DEFAULTS_GUI or the handle to
%      the existing singleton*.
%
%      PLOTSCORES_DEFAULTS_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOTSCORES_DEFAULTS_GUI.M with the given input arguments.
%
%      PLOTSCORES_DEFAULTS_GUI('Property','Value',...) creates a new PLOTSCORES_DEFAULTS_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plotscores_defaults_gui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plotscores_defaults_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Edit the above text to modify the response to help plotscores_defaults_gui

% Last Modified by GUIDE v2.5 01-Feb-2008 13:22:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plotscores_defaults_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @plotscores_defaults_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before plotscores_defaults_gui is made visible.
function plotscores_defaults_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plotscores_defaults_gui (see VARARGIN)

% Choose default command line output for plotscores_defaults_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Store original values
setappdata(handles.defaultplotsgui,'cancel_info',getplspref('plotscores_defaults'));

% Add items to model and plot lists
modeltypes = sort(setdiff(fieldnames(plotscores_defaults('options'))',{'subplots' 'maxplots' 'maxy' 'functionname'}));
modeltypeindex = 1;
% look for modeltypeindex, the index of current analysis in modeltypes.
% If gcbf is empty, or curanal not found in modeltypes then set modeltypeindex = 1
if ~isempty(gcbf)
  figappdata = getappdata(gcbf);
  if ~isempty(figappdata)
    curanal = figappdata.curanal;    % e.g. 'pls'
    if ~isempty(curanal)
      modeltypeindex = find(strcmpi(modeltypes, curanal));
      if isempty(modeltypeindex)
        modeltypes{end+1} = curanal;
        modeltypeindex = length(modeltypes);
      end
    end
  end
end
set(handles.modeltype,'string',upper(modeltypes),'value',modeltypeindex);
modeltype_Callback(handles.modeltype,[],handles);

% UIWAIT makes plotscores_defaults_gui wait for user response (see UIRESUME)
% uiwait(handles.defaultplotsgui);


% --- Outputs from this function are returned to the command line.
function varargout = plotscores_defaults_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout = {[]};


% --- Executes during object creation, after setting all properties.
function modeltype_CreateFcn(hObject, eventdata, handles)
% hObject    handle to modeltype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in modeltype.
function modeltype_Callback(hObject, eventdata, handles)
% hObject    handle to modeltype (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns modeltype contents as cell array
%        contents{get(hObject,'Value')} returns selected item from modeltype

str = get(handles.modeltype,'string');
val = get(handles.modeltype,'value');

plottypes = plotscores_defaults('plottypes');
used      = plotscores_defaults(str{val});
usedval   = find(ismember(lower(plottypes),lower(used)));

setappdata(handles.defaultplotsgui,'original',usedval);

% Store list of options, selected items
set(handles.plottypes,'string',plottypes,'value',usedval,'min',0,'max',2);
plottypes_Callback(handles.plottypes,[],handles);  %and update GUI buttons

% --- Executes during object creation, after setting all properties.
function plottypes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to plottypes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in plottypes.
function plottypes_Callback(hObject, eventdata, handles)
% hObject    handle to plottypes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns plottypes contents as cell array
%        contents{get(hObject,'Value')} returns selected item from plottypes

originalval = getappdata(handles.defaultplotsgui,'original');
usedval = get(handles.plottypes,'value');

if comparevars(originalval,usedval)
  %no changes have been made from defaults
  enb_set = 'off';
  enb_ok  = 'on';
else
  enb_set = 'on';
  enb_ok  = 'off';
end
set([handles.setbutton handles.resetbutton],'enable',enb_set);
set([handles.okbutton handles.modeltype],'enable',enb_ok);


% --- Executes on button press in setbutton.
function setbutton_Callback(hObject, eventdata, handles)
% hObject    handle to setbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get cell array of plot types
plottypes = get(handles.plottypes,'string');
usedval   = get(handles.plottypes,'value');
used      = plottypes(usedval);

% get modeltype string
modeltypes = get(handles.modeltype,'string');
modeltype  = modeltypes{get(handles.modeltype,'value')};

% store as defaults for this model type and note this in appdata here
setplspref('plotscores_defaults',lower(modeltype),used);
setappdata(handles.defaultplotsgui,'original',usedval);

%update GUI
plottypes_Callback(handles.plottypes, [], handles)

% --- Executes on button press in okbutton.
function okbutton_Callback(hObject, eventdata, handles)
% hObject    handle to okbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(gcbf);


% --- Executes on button press in resetbutton.
function resetbutton_Callback(hObject, eventdata, handles)
% hObject    handle to resetbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%restore selected items in plot types list
set(handles.plottypes,'value',getappdata(handles.defaultplotsgui,'original'));

%update GUI
plottypes_Callback(handles.plottypes, [], handles)

% --- Executes on button press in cancelbutton.
function cancelbutton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

setplspref('plotscores_defaults',getappdata(handles.defaultplotsgui,'cancel_info'));
close(gcbf);


% --- Executes on button press in nonebutton.
function nonebutton_Callback(hObject, eventdata, handles)
% hObject    handle to nonebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%restore selected items in plot types list
set(handles.plottypes,'value',[]);

%update GUI
plottypes_Callback(handles.plottypes, [], handles)

% --- Executes on resize of GUI.
function resize_Callback(hObject, eventdata, handles)
% hObject    handle to nonebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles)
  return
end

fig = handles.defaultplotsgui;
set(fig,'units','pixels');
figpos = get(fig,'position');

figpos(3) = max(figpos(3),300);
figpos(4) = max(figpos(4),200);
for f = fieldnames(handles)';
  set(handles.(f{:}),'units','pixels');
end

% frame1 (top frame)
pos = get(handles.frame1,'position');
offset = pos(1);  %universal offset based on frame1's left offset
pos(3) = figpos(3)-offset*2;
pos(4) = figpos(4)-pos(2)-offset;
set(handles.frame1,'position',pos);
f1pos = pos;

% frame2 (bottom frame)
pos = get(handles.frame2,'position');
pos(3) = figpos(3)-offset*2;
set(handles.frame2,'position',pos);
f2pos = pos;

% text1 (model type)
pos = get(handles.text1,'position');
pos(2) = f1pos(2)+f1pos(4)-offset-pos(4);
pos(3) = f1pos(3)-offset-pos(1);
set(handles.text1,'position',pos);
hindex = pos(2);

% modeltype pulldown
pos = get(handles.modeltype,'position');
pos(2) = hindex-pos(4);
pos(3) = f1pos(3)-offset-pos(1);
set(handles.modeltype,'position',pos)
hindex = pos(2);

% plottypes
pos = get(handles.text2,'position');
pos(2) = hindex-offset*3-pos(4);
set(handles.text2,'position',pos)
hindex = pos(2);

% plottypes list
pos = get(handles.plottypes,'position');
pos(3) = f1pos(3)-offset-pos(1);
pos(4) = max(hindex-pos(2),5);
set(handles.plottypes,'position',pos)

%set and reset buttons
pos = get(handles.resetbutton,'position');
pos(1) = f1pos(1)+f1pos(3)-pos(3)-offset;
set(handles.resetbutton,'position',pos)
vindex = pos;
pos = get(handles.setbutton,'position');
pos(1) = vindex(1)-offset-pos(3);
set(handles.setbutton,'position',pos);

%OK/cancel
okpos = get(handles.okbutton,'position');
canpos = get(handles.cancelbutton,'position');
center = f2pos(3)/2+f2pos(1);
bwidth = canpos(1)+canpos(3)-okpos(1);
boffset = canpos(1)-okpos(1)-okpos(3);
okpos(1) = center-bwidth/2;
canpos(1) = okpos(1)+okpos(3)+boffset;
set(handles.okbutton,'position',okpos);
set(handles.cancelbutton,'position',canpos);

% --- Executes on button press in defaultbutton.
function defaultbutton_Callback(hObject, eventdata, handles)
% hObject    handle to defaultbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% get modeltype string
modeltypes = get(handles.modeltype,'string');
modeltype  = lower(modeltypes{get(handles.modeltype,'value')});

% get plotscores_defaults' factory setting
default = plotscores_defaults('factoryoptions');
if isfield(default,modeltype);
  default = default.(modeltype);
else
  default = {};
end

plottypes = get(handles.plottypes,'string');
usedval   = find(ismember(lower(plottypes),lower(default)));
set(handles.plottypes,'value',usedval);

%update GUI buttons
plottypes_Callback(handles.plottypes, [], handles)
