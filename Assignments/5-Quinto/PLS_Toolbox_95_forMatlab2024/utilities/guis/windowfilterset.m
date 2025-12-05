function varargout = windowfilterset(varargin)
% WINDOWFILTERSET MATLAB code for windowfilterset.fig
%      WINDOWFILTERSET, by itself, creates a new WINDOWFILTERSET or raises the existing
%      singleton*.
%
%      H = WINDOWFILTERSET returns the handle to a new WINDOWFILTERSET or the handle to
%      the existing singleton*.
%
%      WINDOWFILTERSET('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WINDOWFILTERSET.M with the given input arguments.
%
%      WINDOWFILTERSET('Property','Value',...) creates a new WINDOWFILTERSET or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before windowfilterset_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to windowfilterset_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2020
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Edit the above text to modify the response to help windowfilterset

% Last Modified by GUIDE v2.5 13-Jul-2020 14:16:21

% Begin initialization code - DO NOT EDIT
  gui_Singleton = 1;
  gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @windowfilterset_OpeningFcn, ...
    'gui_OutputFcn',  @windowfilterset_OutputFcn, ...
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


if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))% LAUNCH GUI

  fig = openfig(mfilename,'reuse');
  set(fig,'WindowStyle','modal');
  centerfigure(fig,gcbf);
  setappdata(fig,'parentfig',gcbf);

  %resize as needed for font size
  fs = getdefaultfontsize('normal');
  scl = fs/10;
  remapfig([0 0 1 1],[0 0 scl scl],fig)
  set(allchild(fig),'fontsize',fs)
  pos = get(fig,'position');
  set(fig,'position',pos.*[1 1 scl scl]-[pos(3:4)*(scl-1) 0 0]);
  
	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
	guidata(fig, handles);
  if nargin > 0;
    setup(handles, varargin{1})
  else
    setup(handles, []);
  end

	% Wait for callbacks to run and window to be dismissed:
	uiwait(fig);

	if nargout > 0
    if ishandle(fig);  %still exists?
      varargout{1} = encode_settings(handles);
      close(fig);
    else
      varargout{1} = varargin{1};   %return 
    end
  end

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

  if ismember(varargin{1},evriio([],'validtopics'));
    options = [];
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

% --- Executes just before windowfilterset is made visible.
function windowfilterset_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to windowfilterset (see VARARGIN)

% Choose default command line output for windowfilterset
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes windowfilterset wait for user response (see UIRESUME)
% uiwait(handles.settingsfigure);
sel_algo = 'Mean';
set(handles.algo, 'Value', 2);
hide_orShow(handles, sel_algo);
set(handles.trbflag, 'Value', 2);

dat = preprocess('getdataset',getappdata(handles.settingsfigure,'parentfig'));
if ~isempty(dat)
  dataDims = numel(size(dat));
  if dataDims > 2
    modeString = cell(dataDims,1);
    for bb = 1:dataDims
      modeString{bb} = ['Mode ' num2str(bb)];
    end
    set(handles.mode, 'String', modeString);
  end
end
set(handles.mode, 'Value', 2);



% --- Outputs from this function are returned to the command line.
function varargout = windowfilterset_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes on selection change in algo.
function algo_Callback(hObject, eventdata, handles)
% hObject    handle to algo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns algo contents as cell array
%        contents{get(hObject,'Value')} returns selected item from algo

algo_contents = cellstr(get(handles.algo,'String'));
sel_algo = algo_contents{get(handles.algo,'Value')};

hide_orShow(handles, sel_algo);

% --- Executes during object creation, after setting all properties.
function algo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to algo (see GCBO)
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

uiresume(gcbf)
% --- Executes on button press in cancelbtn.
function cancelbtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(gcbf)

% --- Executes on button press in helpbtn.
function helpbtn_Callback(hObject, eventdata, handles)
% hObject    handle to helpbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

evrihelp('Filtering_and_despiking_settings_gui');

% --------------------------------------------------------------------
function setup(handles, p)
windowfilterset_OpeningFcn(handles.settingsfigure,[],handles);
% p is preprocessing structure (if any)
if nargin<2 
  p = []; 
end
p = default(p);           %get default settings (but maintain userdata if any)

algo_contents = cellstr(get(handles.algo,'String'));
% sel_algo = algo_contents{get(handles.algo,'Value')};
algoValue = find(ismember(algo_contents,p.userdata.options.algorithm));
set(handles.algo,'value',algoValue);
sel_algo = algo_contents{get(handles.algo,'Value')};
set(handles.window, 'string', num2str(p.userdata.window));
set(handles.mode, 'Value', p.userdata.options.mode);

if strcmp(sel_algo, 'Despike')
  tolValue  = p.userdata.options.tol;
  if isnan(tolValue)
    tolString = '[ ]';
  else
    tolString = num2str(tolValue);
  end  
  set(handles.tol, 'string', tolString);
  set(handles.threshold, 'string', num2str(p.userdata.options.dsthreshold));
  trbFlag_contents = cellstr(get(handles.trbflag,'String'));
%   sel_trbflag = trbFlag_contents{get(handles.trbflag,'Value')};
  trbFlagValue = find(ismember(trbFlag_contents,p.userdata.options.trbflag));
  set(handles.trbflag,'value',trbFlagValue);
elseif any(strcmp(sel_algo, {'Mean Trimmed', 'Median Trimmed'}))
  set(handles.trimfactor, 'string', num2str(p.userdata.options.ntrim));
end
hide_orShow(handles, sel_algo);
setappdata(handles.settingsfigure, 'settings', p);

% --------------------------------------------------------------------
function p = encode_settings(handles)
% encode the GUI's settings into the Preprocessing structure

p = getappdata(handles.settingsfigure,'settings');

algo_contents = cellstr(get(handles.algo,'String'));
sel_algo = algo_contents{get(handles.algo,'Value')};
winValue = str2double(get(handles.window, 'string'));
modeValue = get(handles.mode, 'Value');

tolValue = [];
thresholdValue = [];
trbFlag = [];
trimFactorValue = [];

trimAlgos = {'Mean Trimmed', 'Median Trimmed'};

if strcmp(sel_algo, 'Despike')
  tolValue = str2double(get(handles.tol, 'string'));
  thresholdValue = str2double(get(handles.threshold, 'string'));
  trbFlagContents = get(handles.trbflag, 'string');
  trbFlag = trbFlagContents(get(handles.trbflag, 'Value'));
elseif any(strcmp(sel_algo,trimAlgos))
  trimFactorValue = str2double(get(handles.trimfactor, 'string'));
end

p.userdata.window = winValue;
p.userdata.options    = struct('algorithm', sel_algo,'mode', modeValue, 'ntrim', trimFactorValue, 'trbflag', trbFlag, 'tol', tolValue, 'dsthreshold', thresholdValue); 

p = setdescription(p);

% --------------------------------------------------------------------
function p = setdescription(p)

algo = p.userdata.options.algorithm;
win = p.userdata.window;
winString = num2str(win);
mode = num2str(p.userdata.options.mode);

p.description = ['Filter and Despike (Algorithm: ' algo ', Window: ' winString ', Mode: ' mode];

if strcmp(algo, 'Despike')
  tolValue  = p.userdata.options.tol;
  
  
  if isnan(tolValue)
    tolString = 'empty';
  else
    tolString = num2str(tolValue);
  end

  trbFlag = p.userdata.options.trbflag;
  thresholdValue = p.userdata.options.dsthreshold;
  txt_toUse = [', Tol: ' tolString ', TRB Flag: ' trbFlag ', Threshold: '...
    num2str(thresholdValue) ')'];
%   p.description = sprintf('%s', txt_toUse , p.description);
elseif any(strcmp(algo,{'Mean Trimmed', 'Median Trimmed'}))
  trimValue = p.userdata.options.ntrim;
  trimString = num2str(trimValue);
  txt_toUse = [', Trim Factor: ' trimString ')'];  
%   p.description = sprintf('%s', txt_toUse, p.description);
else
  txt_toUse = ')';
end
p.description = sprintf('%s',p.description, txt_toUse);

% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
end

p = preprocess('validate',p);  %validate what was passed in
p.description   = 'Filtering and Despiking';
p.calibrate     = {'[data] = windowfilter(data, userdata.window, userdata.options);'};
p.apply         = {'[data] = windowfilter(data, userdata.window, userdata.options);'};
% p.undo          = {'data = rescale(data'',out{2},out{3})'';'};
p.undo          = {};
p.out           = {};
p.settingsgui   = 'windowfilterset';
p.settingsonadd = 0;
p.usesdataset   = 1;
p.caloutputs    = 0;
p.tooltip       = 'Filtering and Despiking - Spectral filtering and despiking';
p.category      = 'Filtering';
p.keyword       = 'window_filter';

ops = windowfilter('options');

if isempty(p.userdata);
  p.userdata.window = 3;
  p.userdata.options    = struct('algorithm',ops.algorithm,'mode', ops.mode, 'ntrim', ops.ntrim, 'trbflag', ops.trbflag, 'tol', ops.tol, 'dsthreshold', ops.dsthreshold);          %defaults
end

function window_Callback(hObject, eventdata, handles)
% hObject    handle to window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of window as text
%        str2double(get(hObject,'String')) returns contents of window as a double
winValue = str2double(get(handles.window, 'string'));
isodd = mod(winValue,2)==1;
if ~isint(winValue) || ~isodd
  evriwarndlg('Window value must be an odd integer', 'Window Filter Warning:');
  set(handles.window, 'String', '3');
  return;
end

% --- Executes during object creation, after setting all properties.
function window_CreateFcn(hObject, eventdata, handles)
% hObject    handle to window (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function trimfactor_Callback(hObject, eventdata, handles)
% hObject    handle to trimfactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trimfactor as text
%        str2double(get(hObject,'String')) returns contents of trimfactor as a double

% --- Executes during object creation, after setting all properties.
function trimfactor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trimfactor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on selection change in trbflag.
function trbflag_Callback(hObject, eventdata, handles)
% hObject    handle to trbflag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns trbflag contents as cell array
%        contents{get(hObject,'Value')} returns selected item from trbflag

% --- Executes during object creation, after setting all properties.
function trbflag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trbflag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function tol_Callback(hObject, eventdata, handles)
% hObject    handle to tol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tol as text
%        str2double(get(hObject,'String')) returns contents of tol as a double

%            tol: {[]} if empty then despike uses the std(median(x)) within
%                   each window to define a tolerance within the window.
%                 If tol>0 scalar, then tol defines the tolerance for all
%                   the windows.
%                 If tol<=0, then tol is estimated by the mean absolute deviation
%                   of madc(x.data(:)) and is the tolerance used for all the windows.

tolValue = get(handles.tol, 'String');
if isempty(tolValue)
  tolValue = '[]';
end
emptyAccepts = {'[]', '[ ]'};
if any(strcmp(tolValue, emptyAccepts))
  tolValue = [];
end
if ~isempty(tolValue)
  tolValue = str2double(tolValue);
  if isnan(tolValue) || ~isscalar(tolValue)
    evriwarndlg('Tolerance parameter must be a scalar', 'WINDOWFILTER WARNING:');
    resetTolBtn_Callback(hObject, eventdata, handles)
  end
end

% --- Executes during object creation, after setting all properties.
function tol_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function threshold_Callback(hObject, eventdata, handles)
% hObject    handle to threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of threshold as text
%        str2double(get(hObject,'String')) returns contents of threshold as a double


% --- Executes during object creation, after setting all properties.
function threshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%---------------------------------------------------------------
function hide_orShow(handles, sel_algo)
%handle resize (only called internally for now, so only need to handle
%dynamic open/close of panels

algo_toResize = {'Despike','Mean Trimmed','Median Trimmed'};
grps = handlegroups(handles);
if any(strcmp(sel_algo, algo_toResize))
  if strcmp(sel_algo, 'Despike')
    set(grps.trimparams, 'visible', 'off');
    set(grps.despikeparams, 'visible', 'on');
  else
    set(grps.trimparams, 'visible', 'on');
    set(grps.despikeparams, 'visible', 'off');
  end
else
  set(grps.trimparams, 'visible', 'off');
  set(grps.despikeparams, 'visible', 'off');
end
resize_Callback(handles.settingsfigure, [], handles)

%---------------------------------------------------------------
function resize_Callback(hObject,eventdata,handles)
%handle resize (only called internally for now, so only need to handle
%dynamic open/close of panels

grps = handlegroups(handles);
set(handles.settingsfigure,'units','pixels');
figpos = get(handles.settingsfigure,'position');

%get height of all visible groups (stacked)
padding = 2;  %padding between groups and at top and bottom
height = padding;
for g = fieldnames(grps)';
  grp = grps.(g{:});
  vis = get(grp(1),'visible');
  if strcmp(vis,'on')
    %group is visible, get height
    set(grp,'units','pixels');
    pos = get(grp,'position');
    pos = cat(1,pos{:});
    height = height + max(pos(:,2)+pos(:,4))-min(pos(:,2)) + padding;
  end    
end

%adjust figure size
figHeightDelta = height-figpos(4);
figpos(4) = height;
figpos(2) = figpos(2)-figHeightDelta;

%dock groups
top = figpos(4)-padding;
for g = fieldnames(grps)';
  grp = grps.(g{:});
  vis = get(grp(1),'visible');
  if strcmp(vis,'on')
    %group is visible, position
    set(grp,'units','pixels');
    pos = get(grp,'position');
    pos = cat(1,pos{:});
    oldtop = max(pos(:,2)+pos(:,4));
    pos(:,2) = pos(:,2)-(oldtop-top);
    set(grp,{'position'},mat2cell(pos,ones(length(grp),1),4))
    top = min(pos(:,2))-padding;
  end    
end

set(handles.settingsfigure,'position',figpos);

%---------------------------------------------------------------
function grps = handlegroups(handles)
%return handles within each group

grps = [];
grps.main = [
  handles.algoframe
  handles.algotxt
  handles.windowtxt
  handles.algo
  handles.window
  handles.modetext
  handles.mode
  handles.modehelptxt
  ];
grps.despikeparams = [
  handles.despikeframe
  handles.despikeopstxt
  handles.toltxt
  handles.thresholdtxt
  handles.trbflagtxt
  handles.tol
  handles.threshold
  handles.trbflag
  handles.resetTolBtn
  handles.resetThresholdBtn
  ];
grps.trimparams = [
  handles.trimparamtxt
  handles.trimfactorframe
  handles.trimfactortxt
  handles.trimfactor
  handles.resetTrimFactorBtn
  ];
grps.buttons = [
  handles.cancelbtn
  handles.okbtn
  handles.helpbtn
  ];

% --- Executes on button press in resetTolBtn.
function resetTolBtn_Callback(hObject, eventdata, handles)
% hObject    handle to resetTolBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

tolDefault = '2';
set(handles.tol, 'String', tolDefault);

% --- Executes on button press in resetThresholdBtn.
function resetThresholdBtn_Callback(hObject, eventdata, handles)
% hObject    handle to resetThresholdBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

thresholdDefault = '2';
set(handles.threshold, 'String', thresholdDefault);

% --- Executes on button press in resetTrimFactorBtn.
function resetTrimFactorBtn_Callback(hObject, eventdata, handles)
% hObject    handle to resetTrimFactorBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

trimFactorDefault = '2';
set(handles.trimfactor, 'string', trimFactorDefault);

function mode_Callback(hObject, eventdata, handles)
% hObject    handle to mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mode as text
%        str2double(get(hObject,'String')) returns contents of mode as a double


% --- Executes during object creation, after setting all properties.
function mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
