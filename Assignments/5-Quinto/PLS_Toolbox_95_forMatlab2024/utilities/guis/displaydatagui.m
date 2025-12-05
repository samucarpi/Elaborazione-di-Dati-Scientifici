function varargout = displaydatagui(varargin)
% DISPLAYDATAGUI M-file for displaydatagui.fig
%      DISPLAYDATAGUI, by itself, creates a new DISPLAYDATAGUI or raises the existing
%      singleton*.
%
%      H = DISPLAYDATAGUI returns the handle to a new DISPLAYDATAGUI or the handle to
%      the existing singleton*.
%
%      DISPLAYDATAGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DISPLAYDATAGUI.M with the given input arguments.
%
%      DISPLAYDATAGUI('Property','Value',...) creates a new DISPLAYDATAGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before displaydatagui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to displaydatagui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Edit the above text to modify the response to help displaydatagui

% Last Modified by GUIDE v2.5 21-Jan-2008 10:40:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @displaydatagui_OpeningFcn, ...
                   'gui_OutputFcn',  @displaydatagui_OutputFcn, ...
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


% --- Executes just before displaydatagui is made visible.
function displaydatagui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to displaydatagui (see VARARGIN)

% Choose default command line output for displaydatagui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

if nargin>3 && ~isempty(varargin{1});
  default = varargin{1};
  if isstruct(default)
    default = [default.datahat default.residuals default.data];
  end
else
  default = [1 0 0];
end
set(handles.datahat,'value',default(1));
set(handles.residuals,'value',default(2));
set(handles.data,'value',default(3));

% UIWAIT makes displaydatagui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = displaydatagui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if ~isempty(handles)
  val = getselected(handles);
  varargout{1} = struct('datahat',val(1),'residuals',val(2),'data',val(3));
  close(gcf)
else
  varargout{1} = [];
end

% --- Executes on button press in datahat.
function datahat_Callback(hObject, eventdata, handles)
% hObject    handle to datahat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of datahat
stat = getselected(handles);
if ~any(stat)
  set(handles.residuals,'value',1)
end

% --- Executes on button press in residuals.
function residuals_Callback(hObject, eventdata, handles)
% hObject    handle to residuals (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of residuals
stat = getselected(handles);
if ~any(stat)
  set(handles.datahat,'value',1)
end

% --- Executes on button press in data.
function data_Callback(hObject, eventdata, handles)
% hObject    handle to data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of data
stat = getselected(handles);
if ~any(stat)
  set(handles.datahat,'value',1)
end

% --- Executes on button press in ok.
function ok_Callback(hObject, eventdata, handles)
% hObject    handle to ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
uiresume(gcbf);

% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(gcbf);


%-------------------------------------------------------
function stat = getselected(handles)

stat = [get(handles.datahat,'value') get(handles.residuals,'value') get(handles.data,'value')];
