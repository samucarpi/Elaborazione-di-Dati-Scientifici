function varargout = nnreduceset(varargin)
% NNREDUCESET Allow user to select number of samples to reduce to.
% Standard dialog but includes "help" button to direct user to help page.
%See also: REDUCENNSAMPLES

%Copyright Eigenvector Research, Inc 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0 | nargin==1 & isnumeric(varargin{1})
  fig = openfig('nnreduceset.fig');
  handles = guihandles(fig);
  nnreduceset_OpeningFcn(fig,[],handles,varargin{:});
  varargout{1} = nnreduceset_OutputFcn(fig, [], handles);
  return
end

if nargout
  [varargout{1:nargout}] = feval(varargin{:});
else
  feval(varargin{:});
end



% --- Executes just before nnreduceset is made visible.
function nnreduceset_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to nnreduceset (see VARARGIN)

% Choose default command line output for nnreduceset
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% Set default values
if nargin>3
  def = varargin{1};
else
  def = 10;
end
set(handles.nsamp,'value',def,'string',num2str(def));  %in case they put a bad value in, this will be what we fill in instead

centerfigure(handles.nnreduceset,gcbf);
evriwindowstyle(handles.nnreduceset,0,1);
uicontrol(handles.nsamp);

% UIWAIT makes nnreduceset wait for user response (see UIRESUME)
uiwait(handles.nnreduceset);


% --- Outputs from this function are returned to the command line.
function varargout = nnreduceset_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isstruct(handles) & ishandle(handles.nnreduceset)
  varargout{1} = get(handles.nsamp,'value');
  close(handles.nnreduceset);
else
  varargout{1} = [];
end




function nsamp_Callback(hObject, eventdata, handles)
% hObject    handle to nsamp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nsamp as text
%        str2double(get(hObject,'String')) returns contents of nsamp as a double

s = get(handles.nsamp,'string');
oldval = get(handles.nsamp,'value');
newval = str2double(s);
newval = round(newval);
if isempty(newval) | newval<1
  s = num2str(oldval);
else
  s = num2str(newval);
  set(handles.nsamp,'value',newval);
end
set(handles.nsamp,'string',s);

% --- Executes during object creation, after setting all properties.
function nsamp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nsamp (see GCBO)
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

uiresume(handles.nnreduceset);

% --- Executes on button press in cancelbtn.
function cancelbtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(handles.nnreduceset);

% --- Executes on button press in helpbtn.
function helpbtn_Callback(hObject, eventdata, handles)
% hObject    handle to helpbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

evrihelp('reducennsamples')

