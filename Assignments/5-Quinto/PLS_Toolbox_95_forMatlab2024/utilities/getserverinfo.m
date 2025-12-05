function varargout = getserverinfo(varargin)
% GETSERVERINFO M-file for getserverinfo.fig
%      GETSERVERINFO, by itself, creates a new GETSERVERINFO or raises the existing
%      singleton*.
%
%      H = GETSERVERINFO returns the handle to a new GETSERVERINFO or the handle to
%      the existing singleton*.
%
%      GETSERVERINFO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GETSERVERINFO.M with the given input arguments.
%
%      GETSERVERINFO('Property','Value',...) creates a new GETSERVERINFO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before getserverinfo_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to getserverinfo_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
%See also: GUIDATA, GUIDE, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Edit the above text to modify the response to help getserverinfo

% Last Modified by GUIDE v2.5 02-Jul-2010 11:15:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @getserverinfo_OpeningFcn, ...
                   'gui_OutputFcn',  @getserverinfo_OutputFcn, ...
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


% --- Executes just before getserverinfo is made visible.
function getserverinfo_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to getserverinfo (see VARARGIN)

% Choose default command line output for getserverinfo
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

defaults = {'127.0.0.1' '2212' ''};
if isempty(varargin)
  varargin = {defaults};
else
  varargin{1}(end+1:3) = defaults(length(varargin{1})+1:3);
end

set(handles.ipaddress,'string',varargin{1}{1})
set(handles.port,'string',varargin{1}{2});
set(handles.accesscode,'string',varargin{1}{3});

% UIWAIT makes getserverinfo wait for user response (see UIRESUME)
uiwait(handles.getserverinfo);


% --- Outputs from this function are returned to the command line.
function varargout = getserverinfo_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

if isfield(handles,'getserverinfo') & ishandle(handles.getserverinfo)
  varargout = {{get(handles.ipaddress,'string') get(handles.port,'string') get(handles.accesscode,'string')}};
  close(handles.getserverinfo);
else
  varargout = {[]};
end



function ipaddress_Callback(hObject, eventdata, handles)
% hObject    handle to ipaddress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ipaddress as text
%        str2double(get(hObject,'String')) returns contents of ipaddress as a double


% --- Executes during object creation, after setting all properties.
function ipaddress_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ipaddress (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function port_Callback(hObject, eventdata, handles)
% hObject    handle to port (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of port as text
%        str2double(get(hObject,'String')) returns contents of port as a double


% --- Executes during object creation, after setting all properties.
function port_CreateFcn(hObject, eventdata, handles)
% hObject    handle to port (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function accesscode_Callback(hObject, eventdata, handles)
% hObject    handle to accesscode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of accesscode as text
%        str2double(get(hObject,'String')) returns contents of accesscode as a double


% --- Executes during object creation, after setting all properties.
function accesscode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to accesscode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in okbtn.
function okbtn_Callback(hObject, eventdata, handles)
% hObject    handle to okbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(handles.getserverinfo);

% --- Executes on button press in cancelbtn.
function cancelbtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(handles.getserverinfo);
