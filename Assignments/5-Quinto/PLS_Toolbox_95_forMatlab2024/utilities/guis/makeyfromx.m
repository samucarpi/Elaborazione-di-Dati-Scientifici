function varargout = makeyfromx(varargin)
% MAKEYFROMX MATLAB code for makeyfromx.fig
%      MAKEYFROMX, by itself, creates a new MAKEYFROMX or raises the existing
%      singleton*.
%
%      H = MAKEYFROMX returns the handle to a new MAKEYFROMX or the handle to
%      the existing singleton*.
%
%      MAKEYFROMX('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAKEYFROMX.M with the given input arguments.
%
%      MAKEYFROMX('Property','Value',...) creates a new MAKEYFROMX or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before makeyfromx_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to makeyfromx_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help makeyfromx

% Last Modified by GUIDE v2.5 05-Feb-2021 12:40:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @makeyfromx_OpeningFcn, ...
                   'gui_OutputFcn',  @makeyfromx_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before makeyfromx is made visible.
function makeyfromx_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to makeyfromx (see VARARGIN)

% Choose default command line output for makeyfromx
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

if nargin<4 || isempty(varargin{1});
  evrierrordlg('No List of Variables or Axis Scale passed','No Input passed');
  close(handles.makeyfromx);
  return
end

listToUse = varargin{1};
setappdata(handles.makeyfromx, 'SelectionList', listToUse);
buildList(hObject, eventdata, handles);

fromCols = varargin{2};
if ~fromCols
  setappdata(handles.makeyfromx, 'FromCols', fromCols);
  set(handles.move, 'String', 'Create Y');
  set(handles.move, 'Tooltip', 'Create Y from selection');
  set(handles.makeselectiontext, 'String', 'Make Selection (from Axis Scales):');
end

emptySets = varargin{3};
setappdata(handles.makeyfromx, 'EmptySets', emptySets);

% UIWAIT makes makeyfromx wait for user response (see UIRESUME)
uiwait(handles.makeyfromx);


% --- Outputs from this function are returned to the command line.
function varargout = makeyfromx_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure


if isfield(handles,'makeyfromx') & ishandle(handles.makeyfromx)
  %contents = cellstr(get(handles.selectfrom,'String'));
  sel = get(handles.selectfrom,'Value');
  %selContents = contents(sel);
  moveDeleteCheckStatus = get(handles.movedelete, 'Value');
  if moveDeleteCheckStatus
    actionToPerform = 'moveDelete';
  else
    actionToPerform = 'move';
  end  
  varargout = {sel actionToPerform};
  close(handles.makeyfromx);
else
  varargout = {[] []};
end

%varargout{1} = handles.output;


% --- Executes on selection change in selectfrom.
function selectfrom_Callback(hObject, eventdata, handles)
% hObject    handle to selectfrom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns selectfrom contents as cell array
%        contents{get(hObject,'Value')} returns selected item from selectfrom


% --- Executes during object creation, after setting all properties.
function selectfrom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to selectfrom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function buildList(hObject,eventdata, handles)
listToUse = getappdata(handles.makeyfromx, 'SelectionList');
for i = 1:length(listToUse)
  if strcmp(listToUse(i), 'Empty')
    emptyFix = ['<html><em><font color = #A0A0A0>' listToUse{i} '</font></em></html>'];
    listToUse{1,i} = emptyFix;
  end
end 
set(handles.selectfrom,'String', listToUse);


% --- Executes on button press in movedelete.
function movedelete_Callback(hObject, eventdata, handles)
% hObject    handle to movedelete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of movedelete
moveCheckStatus = get(handles.move, 'Value');
if moveCheckStatus
  set(handles.move, 'Value', 0);
end
set(handles.movedelete, 'Value', 1);


% --- Executes on button press in move.
function move_Callback(hObject, eventdata, handles)
% hObject    handle to move (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of move
moveDeleteCheckStatus = get(handles.movedelete, 'Value');
if moveDeleteCheckStatus
  set(handles.movedelete, 'Value', 0);
end
set(handles.move, 'Value', 1);


% --- Executes on button press in okbtn.
function okbtn_Callback(hObject, eventdata, handles)
% hObject    handle to okbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

sel = get(handles.selectfrom,'Value');
emptySets = getappdata(handles.makeyfromx, 'EmptySets');
fromCols = getappdata(handles.makeyfromx, 'FromCols');
if ~fromCols & ~isempty(emptySets)
  for j = 1:length(emptySets)
    if any(find(sel==emptySets(j)))
      evriwarndlg('Selection includes an empty axis scale set. Please select only non-empty sets.', 'Empty Set Selected');
      return;
    end
  end
end

uiresume(handles.makeyfromx);

% --- Executes on button press in cancelbtn.
function cancelbtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.makeyfromx);
