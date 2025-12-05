function varargout = coaddset(varargin)
% COADDSET MATLAB code for coaddset.fig
%      COADDSET, by itself, creates a new COADDSET or raises the existing
%      singleton*.
%
%      H = COADDSET returns the handle to a new COADDSET or the handle to
%      the existing singleton*.
%
%      COADDSET('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COADDSET.M with the given input arguments.
%
%      COADDSET('Property','Value',...) creates a new COADDSET or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before coaddset_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to coaddset_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Edit the above text to modify the response to help coaddset

% Last Modified by GUIDE v2.5 05-Oct-2010 08:52:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @coaddset_OpeningFcn, ...
                   'gui_OutputFcn',  @coaddset_OutputFcn, ...
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


% --- Executes just before coaddset is made visible.
function coaddset_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to coaddset (see VARARGIN)

% Choose default command line output for coaddset
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

if nargin>3
  str = get(handles.mode,'string');
  data = varargin{1};

  if ndims(data)>2
    str = str2cell(sprintf('Mode %i\n',[1:ndims(data)]));
  end  
  if isdataset(data) & strcmp(data.type,'image')
    imgmode = data.imagemode;
    if imgmode<=length(str)
      str{imgmode} = 'Pixels';
    end
  end
  set(handles.mode,'string',str);
end


set(handles.binsize,'string','2','value',2);

% --- Outputs from this function are returned to the command line.
function varargout = coaddset_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiwait(handles.coaddsettings);

if ishandle(handles.coaddsettings)
  
  actions = get(handles.action,'string');
  out = struct('binsize',get(handles.binsize,'value'),'mode',get(handles.mode,'value'),'action',actions(get(handles.action,'value'),:));

  close(handles.coaddsettings);
else
  out = [];
end

varargout{1} = out;



function binsize_Callback(hObject, eventdata, handles)
% hObject    handle to binsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of binsize as text
%        str2double(get(hObject,'String')) returns contents of binsize as a double

str = get(handles.binsize,'string');
val = str2double(str);
if isempty(val) | ~isfinite(val) | val<1
  val = get(handles.binsize,'value');
else
  set(handles.binsize,'value',val);
end
set(handles.binsize,'string',num2str(val));

% --- Executes during object creation, after setting all properties.
function binsize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to binsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in mode.
function mode_Callback(hObject, eventdata, handles)
% hObject    handle to mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns mode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from mode


% --- Executes during object creation, after setting all properties.
function mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in action.
function action_Callback(hObject, eventdata, handles)
% hObject    handle to action (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns action contents as cell array
%        contents{get(hObject,'Value')} returns selected item from action


% --- Executes during object creation, after setting all properties.
function action_CreateFcn(hObject, eventdata, handles)
% hObject    handle to action (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in okbtn.
function okbtn_Callback(hObject, eventdata, handles)
% hObject    handle to okbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(gcbf);

% --- Executes on button press in cancelbtn.
function cancelbtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(gcbf);
