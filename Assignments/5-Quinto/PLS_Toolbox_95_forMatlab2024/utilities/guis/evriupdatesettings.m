function varargout = evriupdatesettings(varargin)
% EVRIUPDATESETTINGS M-file for evriupdatesettings.fig
%      EVRIUPDATESETTINGS, by itself, creates a new EVRIUPDATESETTINGS or raises the existing
%      singleton*.
%
%      H = EVRIUPDATESETTINGS returns the handle to a new EVRIUPDATESETTINGS or the handle to
%      the existing singleton*.
%
%      EVRIUPDATESETTINGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EVRIUPDATESETTINGS.M with the given input arguments.
%
%      EVRIUPDATESETTINGS('Property','Value',...) creates a new EVRIUPDATESETTINGS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before evriupdatesettings_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to evriupdatesettings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Edit the above text to modify the response to help evriupdatesettings

% Last Modified by GUIDE v2.5 30-Jun-2005 14:29:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @evriupdatesettings_OpeningFcn, ...
                   'gui_OutputFcn',  @evriupdatesettings_OutputFcn, ...
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


% --- Executes just before evriupdatesettings is made visible.
function evriupdatesettings_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to evriupdatesettings (see VARARGIN)

% Choose default command line output for evriupdatesettings

modes = {'auto','prompt','never'};
if nargin<4 | ~isstruct(varargin{1})
  options = [];
  options.mode      = 'auto';
  options.frequency = 14;
  varargin{1} = options;
end
handles.output = varargin{1};

mode = max([1 min(find(ismember(modes,lower(handles.output.mode))))]);
set(handles.mode,'value',mode);
mode_Callback(handles.mode, [], handles);

set(handles.frequency,'string',num2str(handles.output.frequency));
setappdata(handles.frequency,'value',handles.output.frequency);
frequency_Callback(handles.frequency, [], handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes evriupdatesettings wait for user response (see UIRESUME)
setappdata(handles.evriupdatesettings,'OK',0);
uiwait(handles.evriupdatesettings);

if getappdata(handles.evriupdatesettings,'OK');
  handles.output.mode      = modes{get(handles.mode,'value')};
  handles.output.frequency = str2num(get(handles.frequency,'string'));
  guidata(hObject, handles);
end
  
% --- Outputs from this function are returned to the command line.
function varargout = evriupdatesettings_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if ishandle(hObject);

  varargout{1} = handles.output;

  close(handles.evriupdatesettings);
end

% --- Executes during object creation, after setting all properties.
function mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in mode.
function mode_Callback(hObject, eventdata, handles)
% hObject    handle to mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns mode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from mode

hfreq = [handles.frequency handles.text2 handles.text5];
if get(hObject,'value')==3;
  set(hfreq,'enable','off');
else
  set(hfreq,'enable','on');
end

% --- Executes during object creation, after setting all properties.
function frequency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function frequency_Callback(hObject, eventdata, handles)
% hObject    handle to frequency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frequency as text
%        str2double(get(hObject,'String')) returns contents of frequency as a double

oldval = getappdata(hObject,'value');
if isempty(oldval) | oldval<0 | oldval==inf
  oldval = 14;
end
val = str2num(get(hObject,'string'));
if length(val)~=1;
  val = oldval;
end
if val<0
  val = oldval;
end

hfreq = [handles.frequency handles.text2 handles.text5];
if val==inf;
  set(handles.mode,'value',3);  %"never check"
  set(hfreq,'enable','off')
  val = oldval;
end

set(handles.frequency,'string',num2str(val));
setappdata(hObject,'value',val)

% --- Executes on button press in ok.
function ok_Callback(hObject, eventdata, handles)
% hObject    handle to ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

setappdata(handles.evriupdatesettings,'OK',1);
uiresume(gcbf);

% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(gcbf);

% --- Executes on button press in checknow.
function checknow_Callback(hObject, eventdata, handles)
% hObject    handle to checknow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

pntr = get(handles.evriupdatesettings,'pointer');
set(handles.evriupdatesettings,'pointer','watch');
evriupdate;
set(handles.evriupdatesettings,'pointer',pntr);
