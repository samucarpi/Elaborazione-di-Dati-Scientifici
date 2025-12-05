function varargout = scriptexpert(varargin)
% SCRIPTEXPERT M-file for scriptexpert.fig
%      SCRIPTEXPERT, by itself, creates a new SCRIPTEXPERT or raises the existing
%      singleton*.
%
%      H = SCRIPTEXPERT returns the handle to a new SCRIPTEXPERT or the handle to
%      the existing singleton*.
%
%      SCRIPTEXPERT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SCRIPTEXPERT.M with the given script arguments.
%
%      SCRIPTEXPERT('Property','Value',...) creates a new SCRIPTEXPERT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before scriptexpert_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to scriptexpert_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Edit the above text to modify the response to help scriptexpert

% Last Modified by GUIDE v2.5 25-Aug-2010 12:16:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @scriptexpert_OpeningFcn, ...
                   'gui_OutputFcn',  @scriptexpert_OutputFcn, ...
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


% --- Executes just before scriptexpert is made visible.
function scriptexpert_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no results args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to scriptexpert (see VARARGIN)

% Choose default command line results for scriptexpert
handles.output = hObject;

if ~exist('socketparse','file')
  delete(hObject);
  evrierrordlg('Script execution is not available with your installed product.','Not Available');
  return
end

centerfigure(hObject);

set(handles.split,'buttondownfcn','moveobj(''down'',gcbo)','enable','off');
moveobj('y',handles.split);
setappdata(handles.split,'buttonupfcn','scriptexpert(''scriptexpert_ResizeFcn'',gcbf,[],guidata(gcbf))');

% Update handles structure
guidata(hObject, handles);

txthandles = findobj(allchild(hObject),'type','uicontrol');
set(txthandles,'fontsize',getdefaultfontsize)

% UIWAIT makes scriptexpert wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = scriptexpert_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning results args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line results from handles structure
if ~isempty(handles) & isfield(handles,'output');
  varargout{1} = handles.output;
else
  varargout = {[]};
end



function script_Callback(hObject, eventdata, handles)
% hObject    handle to script (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of script as text
%        str2double(get(hObject,'String')) returns contents of script as a double


% --- Executes during object creation, after setting all properties.
function script_CreateFcn(hObject, eventdata, handles)
% hObject    handle to script (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in results.
function results_Callback(hObject, eventdata, handles)
% hObject    handle to results (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns results contents as cell array
%        contents{get(hObject,'Value')} returns selected item from results


% --- Executes during object creation, after setting all properties.
function results_CreateFcn(hObject, eventdata, handles)
% hObject    handle to results (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in execute.
function execute_Callback(hObject, eventdata, handles)
% hObject    handle to execute (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

cmd = get(handles.script,'string');
if ~iscell(cmd)
  cmd = str2cell(cmd);
end
cmd = sprintf('%s\n',cmd{:});

set(handles.results,'string','(...Executing...)','value',[],'listboxtop',1);
drawnow;

data = struct('result',[],'error','','date','');
data.date = [datestr(now,'ddd ') datestr(now,'dd mmm yyyy HH:MM:SS')];
[data.error,data.result,contenttype] = socketparse(cmd);

if strcmp(contenttype,'plain')
  str = data2plain(data);
else
  str = encodexml(struct('response',data));
end
str = str2cell(str,1);
set(handles.results,'string',str,'value',[],'listboxtop',1);


% --- Executes on button press in clearscript.
function clearscript_Callback(hObject, eventdata, handles)
% hObject    handle to clearscript (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.script,'string','');


% --------------------------------------------------------------------
function listmenu_Callback(hObject, eventdata, handles)
% hObject    handle to listmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(gco,'tag'),'results')
  en = 'off';
else
  en = 'on';
end
set(handles.listpaste,'enable',en)

% --------------------------------------------------------------------
function listcopy_Callback(hObject, eventdata, handles)
% hObject    handle to listcopy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get string and convert to cell if needed
str = get(gco,'string');
if ~iscell(str)
  str = str2cell(str);
end

%put onto clipboard in string format
clipboard('copy',sprintf('%s\n',str{:}));


% --------------------------------------------------------------------
function listclear_Callback(hObject, eventdata, handles)
% hObject    handle to listclear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(gco,'string','');



% --------------------------------------------------------------------
function listpaste_Callback(hObject, eventdata, handles)
% hObject    handle to listpaste (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

str = clipboard('paste');
if iscell(str)
  str = sprintf('%s\n',str{:});
end
oldstr = get(gco,'string');
if ~iscell(oldstr)
  oldstr = str2cell(oldstr,1);
end
oldstr = sprintf('%s\n',oldstr{:});
set(gco,'string',[oldstr str])


% --- Executes on button press in clearresults.
function clearresults_Callback(hObject, eventdata, handles)
% hObject    handle to clearresults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

set(handles.results,'string','');


% --- Executes when scriptexpert is resized.
function scriptexpert_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to scriptexpert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

figpos = get(handles.scriptexpert,'position');

move= {'label1' 'script' 'execute' 'help' 'clearresults' 'clearscript' 'split' 'label2' 'results'};
for f = move
  pos.(f{:}) = get(handles.(f{:}),'position');
end

%vertical adjustments
offset = 2;

pos.split(4) = 6;  %force split to be 3 pixels high (moving makes it bigger)
minScriptHeight = 50;

%split script and results as per free space
freeytop = figpos(4)-pos.label1(4)-pos.execute(4)-pos.split(2)-offset*9;
if freeytop<minScriptHeight
  pos.split(2) = pos.split(2)-minScriptHeight+freeytop;
  freeytop = minScriptHeight;
end
freeybtm = max(minScriptHeight,pos.split(2)-pos.label2(4)-offset*7);
pos.script(4) = freeytop;
pos.results(4) = freeybtm;


pos.label1(2)       = figpos(4)-pos.label1(4)-offset;
pos.script(2)       = pos.label1(2)-pos.script(4)-offset;
pos.execute(2)      = pos.script(2)-pos.execute(4)-offset;
pos.help(2)         = pos.script(2)-pos.help(4)-offset;
pos.clearresults(2) = pos.script(2)-pos.clearresults(4)-offset;
pos.clearscript(2)  = pos.script(2)-pos.clearscript(4)-offset;
pos.label2(2)       = pos.split(2)-pos.label2(4)-offset*3;
pos.results(2)      = pos.label2(2)-pos.results(4)-offset;

%width adjustments
fw = figpos(3)-offset*2;  %full width
pos.label1(3)       = fw;
pos.script(3)       = fw;

pos.help(1)         = pos.execute(1)+pos.execute(3)+offset*2;
pos.clearresults(1) = max(pos.help(1)+pos.help(3)+pos.clearscript(3)+offset*4,fw-offset*3-pos.clearresults(3));
pos.clearscript(1)  = pos.clearresults(1)-offset*2-pos.clearscript(3);

pos.split([1 3])    = [offset fw];
pos.label2(3)       = fw;
pos.results(3)      = fw;

for f = move
  pos.(f{:}) = [pos.(f{:})(1:2) max([5 5],pos.(f{:})(3:4))];
  set(handles.(f{:}),'position',pos.(f{:}));
end


% --- Executes on button press in split.
function split_Callback(hObject, eventdata, handles)
% hObject    handle to split (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on button press in help.
function help_Callback(hObject, eventdata, handles)
% hObject    handle to help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

evrihelp('Solo_Predictor_Script_Construction')

