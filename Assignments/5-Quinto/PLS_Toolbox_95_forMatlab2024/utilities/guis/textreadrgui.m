function varargout = textreadrgui(varargin)
% TEXTREADRGUI M-file for textreadrgui.fig
%      TEXTREADRGUI, by itself, creates a new TEXTREADRGUI or raises the existing
%      singleton*.
%
%      H = TEXTREADRGUI returns the handle to a new TEXTREADRGUI or the handle to
%      the existing singleton*.
%
%      TEXTREADRGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TEXTREADRGUI.M with the given input arguments.
%
%      TEXTREADRGUI('Property','Value',...) creates a new TEXTREADRGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before textreadrgui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to textreadrgui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Edit the above text to modify the response to help textreadrgui

% Last Modified by GUIDE v2.5 02-Apr-2015 17:10:21

if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))% LAUNCH GUI

	fig = openfig(mfilename,'reuse');
  set(fig,'WindowStyle','modal');
  options = textreadrgui_OpeningFcn(fig,[],guihandles(fig),varargin{:});
  if ishandle(fig)
    delete(fig);
  end
  
	if nargout > 0
    varargout{1} = options;   %return 
  end

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
  
  if ismember(varargin{1},evriio([],'validtopics'));
    options = [];
    options.parsing = 'graphical_selection';
    if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return; 
  end
  
  try
    if nargout == 0;
      feval(varargin{:});
    else
      [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    end
	catch
		disp(lasterr);
	end

end


% --- Executes just before textreadrgui is made visible.
function opts = textreadrgui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to textreadrgui (see VARARGIN)

% Choose default command line output for textreadrgui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

set(hObject,'Color',get(0,'defaultUicontrolBackgroundColor'));

%encode options into GUI
if nargin<4
  opts = textreadr('options');
else
  opts = varargin{1};
end
if strcmpi(opts.parsing,'gui')
  %default value for parsing...
  guiopts = textreadrgui('options');
  opts.parsing = guiopts.parsing;
  if isempty(opts.parsing)
    opts.parsing = 'graphical_selection';
  end
end
opts.parsing = find(ismember({'automatic','auto_strict','manual','stream','graphical_selection'},opts.parsing));
set(handles.parsing,'value',opts.parsing);
set(handles.commentcharacter,'string',opts.commentcharacter);
set(handles.headerrows,'string',num2str(opts.headerrows));
set(handles.rowlabels,'string',num2str(opts.rowlabels));
set(handles.collabels,'string',num2str(opts.collabels));
set(handles.euformat,'value',strcmp(opts.euformat,'on'));
set(handles.multipledelim,'value',strcmp(opts.multipledelim,'single'));
set(handles.compactdata,'value',strcmp(opts.compactdata,'yes'));
set(handles.transposedata,'value',strcmp(opts.transpose,'yes'));
set(handles.autobuild3d,'value',opts.autobuild3d);

parsing_Callback(handles.parsing,[],handles)
delimiter_Callback(handles.delimiter,[],handles)

centerfigure(handles.textreadrgui,gcbf);

% UIWAIT makes textreadrgui wait for user response (see UIRESUME)
uiwait(handles.textreadrgui);

if ishandle(handles.textreadrgui)
  parsing_options = {'automatic','auto_strict','manual','stream','graphical_selection'};
  eu_options = {'off' 'on'};
  multipledelim_options = {'multiple' 'single'};
  compactdata_options = {'no' 'yes'};
  transposedata_options = {'no' 'yes'};

  opts = textreadr('options');
  opts.parsing = parsing_options{get(handles.parsing,'value')};
  opts.commentcharacter = get(handles.commentcharacter,'string');
  opts.headerrows = str2double(get(handles.headerrows,'string'));
  opts.rowlabels = str2double(get(handles.rowlabels,'string'));
  opts.collabels = str2double(get(handles.collabels,'string'));
  opts.euformat = eu_options{get(handles.euformat,'value')+1};
  opts.multipledelim = multipledelim_options{get(handles.multipledelim,'value')+1};
  opts.compactdata = compactdata_options{get(handles.compactdata,'value')+1};
  opts.transpose = transposedata_options{get(handles.transposedata,'value')+1};
  opts.autobuild3d = get(handles.autobuild3d,'value');
  opts.delimiter = getdelimiter(handles);

else
  opts = [];
end


% --- Executes on selection change in parsing.
function parsing_Callback(hObject, eventdata, handles)
% hObject    handle to parsing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns parsing contents as cell array
%        contents{get(hObject,'Value')} returns selected item from parsing

val = get(handles.parsing,'value');
switch val
  case {1 4 5}
    %automatic parsing
    enable = [handles.commentcharacter handles.headerrows handles.euformat handles.multipledelim handles.compactdata];
    disable = [handles.rowlabels handles.collabels];

  case 2
    %automatic-strict
    enable = [];
    disable = [handles.rowlabels handles.collabels handles.commentcharacter handles.headerrows handles.euformat handles.multipledelim handles.compactdata];

  case 3
    %manual
    enable = [handles.commentcharacter handles.headerrows handles.rowlabels handles.collabels];
    disable = [handles.euformat handles.multipledelim handles.compactdata];

end
if checkmlversion('<=','7.0')
  %if 7.0 or earlier, do NOT allow euformat or multipledelim (because these
  %require regular expression parsing which is NOT supported in these
  %Matlab versions)
  disable = [disable handles.euformat handles.multipledelim];
end

set(enable,'enable','on');
set(disable,'enable','off');


% --- Executes during object creation, after setting all properties.
function parsing_CreateFcn(hObject, eventdata, handles)
% hObject    handle to parsing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function commentcharacter_Callback(hObject, eventdata, handles)
% hObject    handle to commentcharacter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of commentcharacter as text
%        str2double(get(hObject,'String')) returns contents of commentcharacter as a double


% --- Executes during object creation, after setting all properties.
function commentcharacter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to commentcharacter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function headerrows_Callback(hObject, eventdata, handles)
% hObject    handle to headerrows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of headerrows as text
%        str2double(get(hObject,'String')) returns contents of headerrows as a double


% --- Executes during object creation, after setting all properties.
function headerrows_CreateFcn(hObject, eventdata, handles)
% hObject    handle to headerrows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in euformat.
function euformat_Callback(hObject, eventdata, handles)
% hObject    handle to euformat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of euformat

eu = get(handles.euformat,'value');
delim = getdelimiter(handles);
if eu & strcmp(delim,'comma')
  set(handles.euformat,'value',0);
  evriwarndlg('EU Format is not compatible with comma delimited files. EU Format turned off.','EU Format Not Available');
end


% --- Executes on button press in multipledelim.
function multipledelim_Callback(hObject, eventdata, handles)
% hObject    handle to multipledelim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of multipledelim


% --- Executes on button press in compactdata.
function compactdata_Callback(hObject, eventdata, handles)
% hObject    handle to compactdata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of compactdata



function rowlabels_Callback(hObject, eventdata, handles)
% hObject    handle to rowlabels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rowlabels as text
%        str2double(get(hObject,'String')) returns contents of rowlabels as a double

str = get(handles.rowlabels,'string');
val = str2double(str);
if isempty(val) | ~isfinite(val) | val<1
  val = 0;
end
val = floor(val);
set(handles.rowlabels,'string',num2str(val));


% --- Executes during object creation, after setting all properties.
function rowlabels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rowlabels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function collabels_Callback(hObject, eventdata, handles)
% hObject    handle to collabels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of collabels as text
%        str2double(get(hObject,'String')) returns contents of collabels as a double
str = get(handles.collabels,'string');
val = str2double(str);
if isempty(val) | ~isfinite(val) | val<1
  val = 0;
end
val = floor(val);
set(handles.collabels,'string',num2str(val));


% --- Executes during object creation, after setting all properties.
function collabels_CreateFcn(hObject, eventdata, handles)
% hObject    handle to collabels (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ok.
function ok_Callback(hObject, eventdata, handles)
% hObject    handle to ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(handles.textreadrgui);

% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(handles.textreadrgui);


function delimiter_Callback(hObject, eventdata, handles)
% hObject    handle to delimiter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of delimiter as text
%        str2double(get(hObject,'String')) returns contents of delimiter as a double

if strcmp(getdelimiter(handles),'comma') & get(handles.euformat,'value')
  set(handles.euformat,'value',0);
  evriwarndlg('EU Format is not compatible with comma delimited files. EU Format turned off.','EU Format Not Available');
end

% --- Executes during object creation, after setting all properties.
function delimiter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to delimiter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%--------------------------------------------
function delim = getdelimiter(handles)

types = {'' 'comma' 'space' 'tab' 'semi' 'bar'};  %WARNING: Must be in same order as menu!
delim = types{get(handles.delimiter,'value')};


% --- Executes on button press in transposedata.
function transposedata_Callback(hObject, eventdata, handles)
% hObject    handle to transposedata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of transposedata




% --- Executes on button press in helpbtn.
function helpbtn_Callback(hObject, eventdata, handles)
% hObject    handle to helpbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


evrihelp('text_import_settings')


% --- Executes on button press in autobuild3d.
function autobuild3d_Callback(hObject, eventdata, handles)
% hObject    handle to autobuild3d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of autobuild3d
