function varargout = getlicensecode(varargin)
% GETLICENSECODE M-file for getlicensecode.fig
%   Valid Properties:
%     'product'  - string product name
%     'version'  - string version number
%     'message'  - string to show in dialog at bottom
%     'validate' - function handle to call for validation of license code
%     'closeall' - boolean flag indicating if all figures should close on
%                  "cancel" 
%
%I/O: code = getlicensecode('property',value,...)

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Edit the above text to modify the response to help getlicensecode

% Last Modified by GUIDE v2.5 16-Aug-2006 22:07:45

% Begin initialization code - DO NOT EDIT

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @getlicensecode_OpeningFcn, ...
                   'gui_OutputFcn',  @getlicensecode_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
else
  %no inputs? create GUI request
  %(this code added to work-around TMW's bug when opening multiple
  %instances of a GUI from a background process.)
  existing = double(findobj(allchild(0),'tag','licensecodefigure'));
  if any(existing);  %already open, skip
    varargout = {''};
    return
  end
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% if nargin==0;
%   if findobj(allchild(0),'tag','licensecodefigure');
%     %already open, skip
%     varargout = {''};
%     return
%   end
%   fig = openfig(mfilename,'new');
%   handles = guihandles(fig);	%structure of handles to pass to callbacks
%   guidata(fig, handles);      %store it.
%   getlicensecode_OpeningFcn(fig,[],handles);
%   varargout{1} = getlicensecode_OutputFcn(fig, [], handles);
%   delete(fig);
% 
% else
%   if nargout
%     [varargout{1:nargout}] = feval(varargin{:});
%   else
%     feval(varargin{:});
%   end
% end


% --- Executes just before getlicensecode is made visible.
function getlicensecode_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to getlicensecode (see VARARGIN)

% Choose default command line output for getlicensecode
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

%If not pc then set background to white otherwise it shows up as ugly gray.
if ~ispc
  set(handles.licensecodeedit,'BackgroundColor','White')
end

[v,p] = evrirelease;
message = '';
validate = @evriio;
closeall = true;

%parse inputs
if ~isempty(varargin)
  for j=1:2:length(varargin)
    if ~ischar(varargin{j}) | j==length(varargin)
      error('Mismatched property/value pairs as input')
    end 
    val = varargin{j+1};
    switch varargin{j}
      case 'product'
        p = val;
      case 'version'
        v = val;
      case 'message'
        message = val;
      case 'validate'
        validate = val;
      case 'closeall'
        closeall = val;
    end
  end
end

setappdata(handles.licensecodefigure,'product',p)
setappdata(handles.licensecodefigure,'version',v)
setappdata(handles.licensecodefigure,'validate',validate)
setappdata(handles.licensecodefigure,'closeall',closeall)
if ~isempty(message)
  set(handles.text2,'string',message);
end
set(handles.licensecodefigure,'name',sprintf('%s %s License Code Required',p,v));

set(handles.licensecodefigure,'visible','on','units','pixels');
drawnow;
centerfigure(handles.licensecodefigure);

if ~exist('isdeployed') | ~isdeployed
  set(handles.licensecodefigure,'windowstyle','modal')
end

%run through validation code (enable/disable objects as needed)
licensecodeedit_Callback(handles.licensecodefigure, [], handles);

% UIWAIT makes getlicensecode wait for user response (see UIRESUME)
uiwait(handles.licensecodefigure);

% --- Outputs from this function are returned to the command line.
function varargout = getlicensecode_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
% varargout{1} = handles.output;
if isfield(handles,'licensecodeedit') & ishandle(handles.licensecodeedit)
  varargout{1} = get(handles.licensecodeedit,'string');
  delete(handles.licensecodefigure)
else
  varargout{1} = [];
end

% --- Executes during object creation, after setting all properties.
function licensecodeedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to licensecodeedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function licensecodeedit_Callback(hObject, eventdata, handles)
% hObject    handle to licensecodeedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of licensecodeedit as text
%        str2double(get(hObject,'String')) returns contents of licensecodeedit as a double

lc = get(handles.licensecodeedit,'string');
lc = strtrim(lc);
set(handles.licensecodeedit,'string',lc);

if ~isempty(lc)
  validate = getappdata(handles.licensecodefigure,'validate');
  result = validate(lc,'validatelicense');
  isgood = isempty(result);
  if ~isgood
    %bad code, change color and give message
    set(handles.licensecodeedit,'backgroundcolor',badcolor);
    p = getappdata(handles.licensecodefigure,'product');
    v = getappdata(handles.licensecodefigure,'version');

    set(handles.text2,'string',{result sprintf('Use button at right to access your license codes for %s %s',p,v)});
    
    %flash color of text (to get attention)
    clr = get(handles.text2,'backgroundcolor');
    for j=1:3;
      set(handles.text2,'backgroundcolor',badcolor);
      pause(.2);
      set(handles.text2,'backgroundcolor',clr);
      pause(.2);
    end      
  else
    %code is good, uiresume (after resetting colors and enabling - but
    %uiresume should just close GUI)
    set(handles.licensecodeedit,'backgroundcolor',goodcolor);
    uiresume(handles.licensecodefigure);
  end
end

%-------------------------------------------------
function out = badcolor
out = [1 .7 .7];

%-------------------------------------------------
function out = goodcolor
out = [.7 1 .7];


% --- Executes on button press in cancelbutton.
function cancelbutton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

closeall = getappdata(handles.licensecodefigure,'closeall');

if closeall
  %delete all GUI-like figures (except licensecodefigure)
  todel = findobj(allchild(0),'type','figure','integerhandle','off');
  delete(setdiff(todel,handles.licensecodefigure));
end

set(handles.licensecodeedit,'string','')
uiresume(handles.licensecodefigure);

% --- Executes on button press in okbutton.
function okbutton_Callback(hObject, eventdata, handles)
% hObject    handle to okbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
licensecodeedit_Callback(handles.licensecodefigure, [], handles);


% --- Executes on button press in getcode.
function getcode_Callback(hObject, eventdata, handles)
% hObject    handle to getcode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

web('https://download.eigenvector.com','-browser')
