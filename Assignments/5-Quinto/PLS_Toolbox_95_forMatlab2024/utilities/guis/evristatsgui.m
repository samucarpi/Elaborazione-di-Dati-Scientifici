function varargout = evristatsgui(varargin)
% EVRISTATSGUI M-file for evristatsgui.fig
%      EVRISTATSGUI, by itself, creates a new EVRISTATSGUI or raises the existing
%      singleton*.
%
%      H = EVRISTATSGUI returns the handle to a new EVRISTATSGUI or the handle to
%      the existing singleton*.
%
%      EVRISTATSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EVRISTATSGUI.M with the given input arguments.
%
%      EVRISTATSGUI('Property','Value',...) creates a new EVRISTATSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before evristatsgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to evristatsgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


% Edit the above text to modify the response to help evristatsgui

% Last Modified by GUIDE v2.5 17-Apr-2013 13:16:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @evristatsgui_OpeningFcn, ...
                   'gui_OutputFcn',  @evristatsgui_OutputFcn, ...
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


% --- Executes just before evristatsgui is made visible.
function evristatsgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to evristatsgui (see VARARGIN)

% Choose default command line output for evristatsgui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

if ~ispc
  set([handles.no handles.yes],'foregroundcolor',[0 0 0]);
end
set([handles.text2 handles.usercode handles.text3],'fontsize',getdefaultfontsize+2);
set([handles.text1 handles.text5],'fontsize',getdefaultfontsize('heading'));

[v,p]= evrirelease;
set(hObject,'name',[p ' Use Information']);

centerfigure(hObject);

% UIWAIT makes evristatsgui wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = evristatsgui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;


% --- Executes on button press in yes.
function yes_Callback(hObject, eventdata, handles)
% hObject    handle to yes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


setplspref('evristats','accumulate',1)
setplspref('evristats','asked',1);
evrihelpdlg('Thank you - the function use feature is now ENABLED.','Function Use Feature');

close(gcbf);

% --- Executes on button press in no.
function no_Callback(hObject, eventdata, handles)
% hObject    handle to no (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

setplspref('evristats','accumulate',0)
setplspref('evristats','asked',1);
close(gcbf);


% --- Executes on button press in example.
function example_Callback(hObject, eventdata, handles)
% hObject    handle to example (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

evrihelp('Function_Use_Statistics',1);
