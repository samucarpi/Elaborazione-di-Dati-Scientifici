function varargout = mscorrset(varargin)
%MSCORRSET GUI used to modfiy settings of MSCORR (MSC).
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI
%
%I/O:   p = mscorrset(p)
% (or)  p = mscorrset('default')
%
%See also: MSCORR, PREPROCESS

%Copyright Eigenvector Research, Inc. 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 8/3/2001

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


%| ABOUT CALLBACKS:
%| GUIDE automatically appends subfunction prototypes to this file, and 
%| sets objects' callback properties to call them through the FEVAL 
%| switchyard above. This comment describes that mechanism.
%|
%| Each callback subfunction declaration has the following form:
%| <SUBFUNCTION_NAME>(H, EVENTDATA, HANDLES, VARARGIN)
%|
%| The subfunction name is composed using the object's Tag and the 
%| callback type separated by '_', e.g. 'slider2_Callback',
%| 'figure1_CloseRequestFcn', 'axis1_ButtondownFcn'.
%|
%| H is the callback object's handle (obtained using GCBO).
%|
%| EVENTDATA is empty, but reserved for future use.
%|
%| HANDLES is a structure containing handles of components in GUI using
%| tags as fieldnames, e.g. handles.figure1, handles.slider2. This
%| structure is created at GUI startup using GUIHANDLES and stored in
%| the figure's application data using GUIDATA. A copy of the structure
%| is passed to each callback.  You can store additional information in
%| this structure at GUI startup, and you can change the structure
%| during callbacks.  Call guidata(h, handles) after changing your
%| copy to replace the stored original so that subsequent callbacks see
%| the updates. Type "help guihandles" and "help guidata" for more
%| information.
%|
%| VARARGIN contains any extra arguments you have passed to the
%| callback. Specify the extra arguments by editing the callback
%| property in the inspector. By default, GUIDE sets the property to:
%| <MFILENAME>('<SUBFUNCTION_NAME>', gcbo, [], guidata(gcbo))
%| Add any extra arguments after the last argument, before the final
%| closing parenthesis.


% --- Executes just before mscorrset is made visible.
function mscorrset_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mscorrset (see VARARGIN)

% Choose default command line output for mscorrset
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mscorrset wait for user response (see UIRESUME)
% uiwait(handles.settingsfigure);
set(handles.meanref, 'Value', 1);
set(handles.loadbtn, 'Enable', 'off');
set([handles.sizetxtlbl handles.sizetxt], 'Enable', 'off');
szstr = '<empty>';
set(handles.sizetxt, 'String', szstr);
setRefText(handles);


% --------------------------------------------------------------------
function meancenter_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.meancenter.

% --------------------------------------------------------------------
function mode_Callback(hObject, eventdata, handles)

val = str2num(get(handles.mode,'string'));
if isempty(val) | ~isfinite(val); val = get(handles.mode,'value'); end
val = fix(val);
if val<1; val = 1; end
mydata = getappdata(handles.mscorrset,'dataset');
if ~isempty(mydata) & val>ndims(mydata);
  val = ndims(mydata);
end
set(handles.mode,'string',num2str(val),'value',val);  

% --------------------------------------------------------------------
function okbtn_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.okbtn.

extref_btnState = get(handles.extrefdata, 'Value');
extref_stringState = get(handles.sizetxt, 'String');

if extref_btnState == 1 & strcmp(extref_stringState, '<empty>')
  evrihelpdlg('Please select an external reference source', 'MSC Help');
  return
end

uiresume(gcbf)

% --------------------------------------------------------------------
function cancelbtn_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.cancelbtn.
close(gcbf)

% --------------------------------------------------------------------
function setup(handles, p)
% p is preprocessing structure (if any)

mscorrset_OpeningFcn(handles.mscorrset,[],handles);
if nargin<2 
  p = []; 
end
p = default(p);           %get default settings (but maintain userdata if any)

mydata = preprocess('getdataset');
if ~isempty(mydata)
  if p.userdata.mode>ndims(mydata);
    p.userdata.mode = ndims(mydata);
  end
  if ndims(mydata)<3;
    set([handles.mode handles.modetext],'enable','off');
  else
    set([handles.mode handles.modetext],'enable','on');
  end
end
setappdata(handles.mscorrset,'dataset',mydata);

%set up GUI based on decoded structure
if ~isempty(p.userdata.xref)
  loadbtn_Callback(handles.loadbtn, [], handles, p.userdata.xref);
  extrefdata_Callback(handles.extrefdata, [], handles);
  set(handles.extrefdata,'value',1);
end
set(handles.meancenter,'value',p.userdata.meancenter);
set(handles.mode,'string',num2str(p.userdata.mode),'value',p.userdata.mode);
setappdata(handles.mscorrset,'window',p.userdata.window);
setappdata(handles.mscorrset,'subinds',p.userdata.subinds);

%Fix window or subind cell array so it appears correctly in GUI
if iscell(p.userdata.window)
  includedVars = mydata.include{2};
  win_forTest = p.userdata.window{1};
  win_txt = [];
  for bb = 1:length(win_forTest)
    inds = includedVars(win_forTest{bb});
    win_txt = [win_txt inds];
  end
  setappdata(handles.mscorrset, 'window_text', win_txt);
end

if ~isempty(p.userdata.subinds) && anyexcluded(mydata)
  includedVars = mydata.include{2};
  if size(mydata,2) ~= size(includedVars,2)
    subinds_txt = includedVars(1,p.userdata.subinds);
    setappdata(handles.mscorrset, 'subinds_text', subinds_txt);
  end
end

update_WinAndSubind(handles);

algoType = p.userdata.options.algorithm;
if strcmp(algoType, 'leastsquares')
  algoVal = 1;
else
  algoVal = 2; % set to median
end
set(handles.algorithm,'value',algoVal);


if strcmp(algoType, 'median')
  set(handles.meancenter, 'Value', 0);
  set([handles.meancenter handles.intercepttext], 'enable', 'off')
end
setRefText(handles);
%store p for modification when done
setappdata(handles.mscorrset,'settings',p);

% --------------------------------------------------------------------
function p = encode_settings(handles)
% encode the GUI's settings into the Preprocessing structure

p = getappdata(handles.mscorrset,'settings');
win = getappdata(handles.mscorrset,'window');
xref_data = getappdata(handles.mscorrset, 'extdata');
meanref_state = get(handles.meanref, 'Value');
subind_win = getappdata(handles.mscorrset,'subinds');
%get algorithm
mylist = get(handles.algorithm, 'String');
mylist = lower(mylist);
algo_value = get(handles.algorithm, 'Value');
algoChoice = lower(mylist{algo_value, 1});

if strcmp(algoChoice, 'least squares')
  useslstsqrs = 1;
  algoChoice = algoChoice(~isspace(algoChoice));
else
  useslstsqrs = 0;
end
% set whether mean, median, or external reference used
if meanref_state
  xref_data = [];
  if useslstsqrs
    ref_source = 'mean';
  else
    ref_source = 'median';
  end
elseif ~isempty(xref_data)
  ref_source = 'external';
end

% get number of regions
if ~isempty(win)
  subind_win = []; %can't use subinds with windows
  if iscell(win)
    if iscell(win{1})
      win = win{:};
    end
    n = length(win);
    win = {win};
  else
    new_win = win;
    end_value = new_win(end);
    new_win(end+1) = end_value+2;
    idx = find(diff(new_win) ~= 1);
    [~,n] = size(idx); % number of regions
  end
end

p.userdata = struct('meancenter',get(handles.meancenter,'value'),'mode',get(handles.mode,'value'),...
  'window', win, 'xref', xref_data,'subinds', subind_win, 'source', ref_source, 'algorithm',algoChoice);

if iscell(win)
  p.userdata.window = {p.userdata.window};
end
p.userdata.options = struct('mc', p.userdata.meancenter,'specmode', p.userdata.mode,'win', p.userdata.window, 'subind',p.userdata.subinds,'algorithm', p.userdata.algorithm);

if strcmp(p.userdata.algorithm, 'leastsquares')
  p.description = 'MSC (Mean';
  if p.userdata.meancenter
    p.description = sprintf('%s, w/intercept', p.description);
  else
    p.description = sprintf('%s, no intercept', p.description);
  end
  if p.userdata.mode ~= 2
    p.description = sprintf('%s, spectral mode = %d', p.description, p.userdata.mode);
  end
  if ~isempty(p.userdata.window)
    p.description = sprintf('%s, %d region(s)', p.description, n);
  end
  if ~isempty(p.userdata.xref)
    p.description = sprintf('%s, external reference', p.description);
  end
  if ~isempty(p.userdata.subinds)
    p.description = sprintf('%s, subindices', p.description);
  end
  p.description = sprintf('%s)', p.description);
else
  if strcmp(p.userdata.algorithm, 'median')
    p.keyword = 'msc_median';
    p.tooltip = 'Multiplicative Signal Correction - median ratio normalization';
    p.description = 'MSC (Median';
  end
%   p.description = sprintf('%s, no intercept', p.description);
  if p.userdata.mode ~= 2
    p.description = sprintf('%s, spectral mode = %d', p.description, p.userdata.mode);
  end
  if ~isempty(p.userdata.window)
    p.description = sprintf('%s, %d region(s)', p.description, n);
  end
  if ~isempty(p.userdata.xref)
    p.description = sprintf('%s, external reference', p.description);
  end
  if ~isempty(p.userdata.subinds)
    p.description = sprintf('%s, subindices', p.description);
  end
  p.description = sprintf('%s)', p.description);
end


% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
end

p = preprocess('validate',p);  %validate what was passed in
p.description   = 'MSC (Mean)';
p.calibrate     = {'[data,out{2},out{3},out{1}] = mscorr(data,userdata.xref,userdata.options);'};
p.apply         = {'[data,out{2},out{3}] = mscorr(data,out{1},userdata.options);'};
p.undo          = {'data = rescale(data'',out{2},out{3})'';'};
p.out           = {};
p.settingsgui   = 'mscorrset';
p.settingsonadd = 0;
p.usesdataset   = 0;
p.caloutputs    = 1;
p.tooltip       = 'Multiplicative Signal Correction - weighted normalization and baseline removal';
p.category      = 'Normalization';
p.keyword       = 'msc';

myuserdata = struct('meancenter',1,'mode',2, 'window',[], 'xref', [],  'subinds', [], 'source', 'mean', 'algorithm', 'leastsquares');
if isempty(p.userdata);
  p.userdata = myuserdata;
else
  if isnumeric(p.userdata)
    %old old format - update
    myuserdata.meancenter = p.userdata(1);
    myuserdata.mode = p.userdata(2);
    p.userdata = myuserdata;
  elseif length(fieldnames(p.userdata))==2
    %old format - update
    myuserdata.meancenter = p.userdata.meancenter;
    myuserdata.mode = p.userdata.mode;
    p.userdata = myuserdata;
  end
end

mydata = preprocess('getdataset');
if ~isempty(mydata)
  if p.userdata.mode>ndims(mydata);
    p.userdata.mode = ndims(mydata);
  end
  if ndims(mydata)>2;
    p.settingsonadd = 1;
  end
end

p.userdata.options = struct('mc', p.userdata.meancenter,'specmode', p.userdata.mode,'win', p.userdata.window, 'subind',p.userdata.subinds,'algorithm', p.userdata.algorithm);
if strcmp(p.userdata.options.algorithm, 'median')
  p.keyword = 'msc_median';
  p.tooltip = 'Multiplicative Signal Correction - median ratio normalization';
end

% --- Executes during object creation, after setting all properties.
function mode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


%-------------------------------------------------------------------
function linkwithfunctions
%placeholder function - this is just so that we'll make sure the compiler
%includes these functions when compiling

mscorr


% --- Executes on button press in extrefdata.
function extrefdata_Callback(hObject, eventdata, handles)
% hObject    handle to extrefdata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of extrefdata

extref_btnState = get(handles.extrefdata, 'Value');

if extref_btnState == 0
  set(handles.extrefdata, 'Value', 1);
end

set(handles.meanref, 'Value', 0);
set(handles.loadbtn, 'Enable', 'On');
set([handles.sizetxtlbl handles.sizetxt], 'Enable', 'On');
myid = getappdata(handles.mscorrset, 'extdata');

toggle_state = get(hObject, 'Value');

if ~isempty(myid)
  toggle_state = 1;
end

if ~toggle_state
  set(handles.loadbtn, 'Enable', 'off');
  set([handles.sizetxtlbl handles.sizetxt], 'Enable', 'off');
end
if isempty(myid)
  szstr = '<empty>';
  set(handles.sizetxt, 'String', szstr);
else
  cursize = size(myid);
  szstr   = sprintf('%d x ', cursize);
  szstr   = szstr(1:end-2);
  szstr   = char(szstr);
  set(handles.sizetxt, 'String', szstr);
end

% --- Executes on button press in loadbtn.
function loadbtn_Callback(hObject, eventdata, handles, extdata)
% hObject    handle to loadbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if nargin<4;
  extdata = lddlgpls('doubdataset','Select External Reference Data');
  if isempty(extdata)
    return;
  end
end
if ~isnumeric(extdata) && ~isdataset(extdata)
  evrierrordlg('External reference must be a DataSet Object or type double.')
  return;
end

sel = [];
if size(extdata,1) > 1
  [sel,ok] = selectfromlist(extdata);
%   extdata = extdata.data(sel,:);
end

if isdataset(extdata)
  extdata = extdata.data;
end

if ~isempty(sel)
  extdata = extdata(sel,:);
end

%Do variable size checking between xref and dataset
mydata = preprocess('getdataset',getappdata(handles.mscorrset,'parentfig'));
if ~isempty(mydata)
  excludedVars = (size(mydata,2) ~= size(mydata.include{2},2));
  totalSize_Match = size(mydata,2) == size(extdata,2);
  incldSize_Match = size(mydata.include{2},2) == size(extdata,2);
  
  if ~totalSize_Match && ~incldSize_Match
    evrihelpdlg('Number of variables in the selected reference does not match number of variables in Dataset.', 'MSC Help: VARIABLE MISMATCH');
    extdata = [];
  end
  if excludedVars && totalSize_Match
    extdata = extdata(:,mydata.include{2});
  end
end

setappdata(handles.mscorrset,'extdata',extdata)
extrefdata_Callback(handles.extrefdata, [], handles);

function sizetxt_Callback(hObject, eventdata, handles)
% hObject    handle to sizetxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sizetxt as text
%        str2double(get(hObject,'String')) returns contents of sizetxt as a double


% --- Executes during object creation, after setting all properties.
function sizetxt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sizetxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in select.
function select_Callback(hObject, eventdata, handles)
% hObject    handle to select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dat = preprocess('getdataset',getappdata(handles.mscorrset,'parentfig'));
win = getappdata(handles.mscorrset,'window');
tag = 'window';
[win, win_forText] = getSelection(handles,dat,win,tag);

if isempty(win_forText)
  win_forText = win;
end
setappdata(handles.mscorrset, 'window_text', win_forText);
setappdata(handles.mscorrset,'window',win);
update_WinAndSubind(handles)

% --- Executes on selection change in selectedwindow.
function selectedwindow_Callback(hObject, eventdata, handles)
% hObject    handle to selectedwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns selectedwindow contents as cell array
%        contents{get(hObject,'Value')} returns selected item from selectedwindow

% --- Executes during object creation, after setting all properties.
function selectedwindow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to selectedwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in reset.
function reset_Callback(hObject, eventdata, handles)
% hObject    handle to reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

win = [];
setappdata(handles.mscorrset,'window',win);
setappdata(handles.mscorrset, 'window_text', win);
update_WinAndSubind(handles);
set([handles.selectedsubinds handles.resetsubinds handles.selectsubinds handles.text5],'enable','on');

% --- Executes on selection change in selectedsubinds.
function selectedsubinds_Callback(hObject, eventdata, handles)
% hObject    handle to selectedsubinds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns selectedsubinds contents as cell array
%        contents{get(hObject,'Value')} returns selected item from selectedsubinds

% --- Executes during object creation, after setting all properties.
function selectedsubinds_CreateFcn(hObject, eventdata, handles)
% hObject    handle to selectedsubinds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in selectsubinds.
function selectsubinds_Callback(hObject, eventdata, handles)
% hObject    handle to selectsubinds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dat = preprocess('getdataset',getappdata(handles.mscorrset,'parentfig'));
subinds = getappdata(handles.mscorrset,'subinds');
tag = 'selectsubinds';
[subinds, subinds_forText] = getSelection(handles, dat, subinds, tag);

if isempty(subinds_forText)
  subinds_forText = subinds;
end
if iscell(subinds)
  new_subinds = [];
  for bb = 1:length(subinds)
    inds = subinds{bb};
    new_subinds = [new_subinds inds];
  end
  subinds = new_subinds;
end
setappdata(handles.mscorrset, 'subinds_text', subinds_forText)
setappdata(handles.mscorrset, 'subinds', subinds);
update_WinAndSubind(handles)

% --- Executes on button press in resetsubinds.
function resetsubinds_Callback(hObject, eventdata, handles)
% hObject    handle to resetsubinds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

subinds = [];
setappdata(handles.mscorrset,'subinds',subinds);
setappdata(handles.mscorrset, 'subinds_text', subinds)
update_WinAndSubind(handles);
set([handles.selectedwindow handles.reset handles.select handles.text4],'enable','on');


% --- Executes on button press in meanref.
function meanref_Callback(hObject, eventdata, handles)
% % hObject    handle to meanref (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hint: get(hObject,'Value') returns toggle state of meanref

meanref_btnState = get(handles.meanref, 'Value');

if meanref_btnState == 0
  set(handles.meanref, 'Value', 1);
end

set(handles.extrefdata, 'Value', 0);
set(handles.loadbtn, 'Enable', 'Off');
set([handles.sizetxtlbl handles.sizetxt], 'Enable', 'Off');



% --- Executes on selection change in algorithm.
function algorithm_Callback(hObject, eventdata, handles)
% hObject    handle to algorithm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns algorithm contents as cell array
%        contents{get(hObject,'Value')} returns selected item from algorithm

mylist = get(handles.algorithm, 'String');
mylist = lower(mylist);
algo_value = get(handles.algorithm, 'Value');
algoChoice = lower(mylist{algo_value, 1});

if strcmp(algoChoice, 'least squares')
   set(handles.meancenter, 'Value', 1)
   set([handles.meancenter handles.intercepttext], 'enable', 'on')
else
  set(handles.meancenter, 'Value', 0)
  set([handles.meancenter handles.intercepttext], 'enable', 'off')
end
setRefText(handles);



% if strcmp(algoType, 'median')
%   set([handles.meancenter handles.intercepttext], 'enable', 'off')
% elseif strcmp(algoType, 'leastsquares')
%   set([handles.meancenter handles.intercepttext], 'enable', 'on')
% end

% --- Executes during object creation, after setting all properties.
function algorithm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to algorithm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in helpbtn.
function helpbtn_Callback(hObject, eventdata, handles)
% hObject    handle to helpbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
evrihelp('msc_settings_gui')

%-------------Function to select indices for Window or Subindices-----
function [wins_toUse, wins_forText] = getSelection(handles, dat, win, tag)

wins_forText = [];
%tag should be 'select' or 'selectsubinds'
if strcmp(tag, 'window')
  txt_toUse = 'Window';
  useSub = 0;
else
  txt_toUse = 'Subindices';
  useSub = 1;
end

if isempty(dat)
  sel_inds = inputdlg({txt_toUse},['Select ' txt_toUse] ,1,{encode(win,'')});
  if ~isempty(sel_inds)
  wins_toUse = str2num(sel_inds{1});
  else
    return
  end
else
  %we've got data, share it and allow plotgui to modify the include field
  dat_win = dat;
  selectMethod = evriquestdlg(['How would you like to select ' txt_toUse ' ?'],['Select ' txt_toUse],'Use plot of data','Enter indices', 'Use plot of data');
  if strcmp(selectMethod, 'Enter indices')
    sel_inds = inputdlg({[txt_toUse ':']},['Select ' txt_toUse] ,1,{encode(win,'')});
    if ~isempty(sel_inds)
     wins_toUse = str2num(sel_inds{1});
    else
      return
    end
  elseif strcmp(selectMethod, 'Use plot of data')
    evritip('mscorrselect','Use Include and Exclude to indicate region which should be used for correction (only included region will be used).',1)
    
    if ~isempty(win)
      if strcmp(tag, 'selectsubinds')
        win_txt = getappdata(handles.mscorrset,'subinds_text');
        if ~isempty(win_txt)
          win = win_txt;
        end
      elseif strcmp(tag, 'window')
        win_txt = getappdata(handles.mscorrset,'window_text');
        if ~isempty(win_txt)
          win = win_txt;
        elseif iscell(win)
          win = win{:};
          new_win = [];
          for bb = 1:length(win)
            inds = win{bb};
            new_win = [new_win inds];
          end
          win = new_win;
        end
      end
      dat_win.include{2} = win;
    end

%     if ~isempty(win)
%       if iscell(win) && strcmp(tag, 'window')
%         win_txt = getappdata(handles.mscorrset,'window_text');
%       elseif strcmp(tag, 'selectsubinds')
%         win_txt = getappdata(handles.mscorrset,'subinds_text');
%       end
%       if ~isempty(win_txt)
%         win = win_txt;
%       elseif iscell(win)
%         win = win{:};
%         new_win = [];
%         for bb = 1:length(win)
%           inds = win{bb};
%           new_win = [new_win inds];
%         end
%         win = new_win;
%       else
%         dat_win.include{2} = win;
%       end
%     end
%     
    items = [];
    items.cont = {'string','Done','Callback','uiresume(getappdata(gcbf,''target''));'};
    
    btnlist = {
      'selectx'      'selectonly' 'plotgui(''makeselection'',gcbf);plotgui(''menuselection'',''EditExcludeUnselected'')'   'enable' 'Choose Included Range'    'off'   'push'
      'selectxplus'  'selectadd'  'plotgui(''makeselection'',gcbf);plotgui(''menuselection'',''EditIncludeSelection'')'    'enable' 'Add to Included'          'off'   'push'
      'selectxminus' 'selectsub'  'plotgui(''makeselection'',gcbf);plotgui(''menuselection'',''EditExcludeSelection'')'    'enable' 'Subtract from Included'   'off'   'push'
      'ok'           'accept'     'close(gcbf)'                                                                            'enable' 'Accept and close'         'on'    'push'
      };
    
    %share data and get plotgui to modify include field
    myid = setshareddata(handles.mscorrset,dat_win);
    fig = plotgui('new',myid,...
      'plotby',0,...
      'viewclasses',1,...
      'selectionmode','xs',...
      'pgtoolbar',0,...
      'viewexcludeddata',1);
    toolbar(fig,'',btnlist,'selectiontoolbar');
    
    while ishandle(fig)
      uiwait(fig);
    end
    
    %get include field after figure is closed
    dat_win = myid.object;
    sel_inds = dat_win.include{2};
    
    if anyexcluded(dat) && ~isempty(sel_inds)
      if size(dat,2) ~= size(dat.include{2},2)
        new_win        = sel_inds;% Add a new isolating point end
        end_value      = new_win(end);
        new_win(end+1) = end_value+2;
        idx            = find(diff(new_win) ~= 1); % Find indexes of isolating points
        [m,n]          = size(idx);
        start_idx      = 1 ; % Set start index
        for bb = 1:n
          end_idx           = idx(bb); % Set end index
          region            = new_win(start_idx:end_idx); % Find consecuative sequences
          start_idx         = end_idx + 1; % update start index for the next consecuitive sequence
          window_cell(bb,1) = {region};
        end
        includedVars       = dat.include{2};
        for tt = 1:length(window_cell)
          [~,sel_inds_fixed{tt}] = ismember(window_cell{tt},includedVars);
        end
        wins_toUse = sel_inds_fixed;
        wins_forText = sel_inds;
      end
    else
      wins_toUse = sel_inds;
    end
    
    if length(sel_inds)==size(dat,2);
      %everything selected? interpret as empty
      wins_toUse = [];
    end
    removeshareddata(myid);
  end
end

%--------------update window or subindices section-------------
%Update the text shown for selected window or subindices
function update_WinAndSubind(handles, varargin)

win = getappdata(handles.mscorrset,'window_text');
if isempty(win)
  win = getappdata(handles.mscorrset, 'window');
end
subinds = getappdata(handles.mscorrset,'subinds_text');
if isempty(subinds)
  subinds = getappdata(handles.mscorrset, 'subinds');
end
dat = preprocess('getdataset',getappdata(handles.mscorrset,'parentfig'));

if ndims(dat)>2
  nway_data = 1;
else
  nway_data = 0;
end

if isempty(win)
  haveWin = 0;
else
  haveWin = 1;
  subinds = [];
end

if isempty(subinds)
  haveSubinds = 0;
else
  haveSubinds = 1;
  win = [];
end

if haveWin
  win = encode(win, '');
  set(handles.selectedwindow,'string',win);
  set([handles.selectedsubinds handles.resetsubinds handles.selectsubinds handles.text5],'enable','off');
elseif haveSubinds
  subinds = encode(subinds, '');
  set(handles.selectedsubinds,'string',subinds);
  set([handles.selectedwindow handles.reset handles.select handles.text4],'enable','off');
else
  win = '(all variables)';
  set(handles.selectedwindow,'string',win);
  subinds = '(all variables)';
  set(handles.selectedsubinds,'string',subinds);
  en = 'on';
  if nway_data
    en = 'off';
  end
  set([handles.selectedsubinds handles.resetsubinds handles.selectsubinds handles.text5],'enable',en);
  set([handles.selectedwindow handles.reset handles.select handles.text4],'enable',en);
end

%------------------------------------------------------------
function [sel,ok] = selectfromlist(data)

% lblbase = 'Rows';
mode = 1;
label = 'Select a Row to use as a Reference';
default = 1;

% if ndims(data)<3;
%   switch mode
%     case 1
%       lblbase = 'Rows';
%     case 2
%       lblbase = 'Columns';
%   end
% else
%   lblbase = ['items from mode ' num2str(mode)];
% end

modesz = size(data,1);
% if modesz>10000;
%   r = evriquestdlg('Bulk Change may take a long time to prepare a list with modes that have more than 10,000 items. Do you still want to do this?','Large List Warning','Yes','Cancel','Yes');
%   if strcmp(r,'Cancel');
%     sel = [];
%     ok = false;
%     return;
%   end
% end

if isdataset(data)
  str = [num2str((1:modesz)')];
  lbls = data.label{mode};
  if ~isempty(lbls);
    str = [str repmat(': ',modesz,1) lbls];
  end
  str = [str repmat(' [ ',modesz,1)];
  all_ax = data.axisscale(mode,:);
  nax = 0;
  for j=1:length(all_ax);
    ax = all_ax{j};
    if ~isempty(ax)
      str = [str num2str(ax(:))];
      str = [str repmat(' ',modesz,1)];
      nax = nax+1;
    end
  end
  if nax>0
    str = [str repmat(':',modesz,1)];
  end
  all_classes = data.classid(mode,:);
  for j=1:length(all_classes);
    classes = all_classes{j};
    if ~isempty(classes)
      str = [str char(classes)];
      str = [str repmat(' ',modesz,1)];
    end
  end
  str = [str repmat(' ]',modesz,1)];
else
  num_str = [num2str((1:modesz)')];
  row_str = repmat('Row ', modesz,1);
  str = [row_str num_str];
end
try
  [sel,ok] = listdlg('PromptString',label,'SelectionMode','single',...
    'InitialValue',default,'ListString',str,'ListSize',[300 400]);
catch
  ok = false;
  sel = [];
end
% set(fig,'pointer',ptr);

%------------------------------------------------------------
function setRefText(handles)

mylist = get(handles.algorithm, 'String');
mylist = lower(mylist);
algo_value = get(handles.algorithm, 'Value');
algoChoice = lower(mylist{algo_value, 1});

if strcmp(algoChoice, 'least squares')
   refString = 'Mean';
else
  refString = 'Median';
end
stringToUse = ['Use '  refString ' of data'];
set(handles.meanref, 'String', stringToUse);







