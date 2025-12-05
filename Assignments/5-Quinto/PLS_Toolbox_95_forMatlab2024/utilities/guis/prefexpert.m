function varargout = prefexpert(varargin)
% PREFEXPERT M-file for prefexpert.fig
%      PREFEXPERT, by itself, creates a new PREFEXPERT or raises the existing
%      singleton*.
%
%      H = PREFEXPERT returns the handle to a new PREFEXPERT or the handle to
%      the existing singleton*.
%
%      PREFEXPERT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PREFEXPERT.M with the given input arguments.
%
%      PREFEXPERT('Property','Value',...) creates a new PREFEXPERT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before prefexpert_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to prefexpert_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Edit the above text to modify the response to help prefexpert

% Last Modified by GUIDE v2.5 28-Jul-2006 11:26:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
  'gui_Singleton',  gui_Singleton, ...
  'gui_OpeningFcn', @prefexpert_OpeningFcn, ...
  'gui_OutputFcn',  @prefexpert_OutputFcn, ...
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


% --- Executes just before prefexpert is made visible.
function prefexpert_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to prefexpert (see VARARGIN)

% Choose default command line output for prefexpert
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes prefexpert wait for user response (see UIRESUME)
% uiwait(handles.prefexpert);

centerfigure(handles.prefexpert);

update_listbox(handles);
setappdata(handles.prefexpert,'origprefs',getplspref);
set(handles.reset,'enable','off');

if isempty(getappdata(0,'prefexpert_warning'))
  try
    evriwarndlg({'WARNING! Advanced Users Only.',' ','Change these settings with care.','If problems occur, use "Factory Default" to reset.'},'Advanced Users Warning');
  catch
  end
  setappdata(0,'prefexpert_warning',1)
end


% --- Outputs from this function are returned to the command line.
function varargout = prefexpert_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes during object resize
function resize_Callback(hObject,eventdata,handles)

if ~isfield(handles,'prefexpert');
  %don't do this if we didn't get valid handles (yet)
  return
end
fig = get(handles.prefexpert,'position');

header = get(handles.tableheader,'position');
pos = get(handles.preflist,'position');
if fig(3)>40;
  pos(3) = fig(3)-pos(1);
end
pos(4) = fig(4)-pos(2)-header(4)-4;
if pos(3)>5 & pos(4)>5;
  set(handles.preflist,'position',pos);
end

header(2) = pos(2)+pos(4)+2;
if fig(3)>40;
  header(3) = fig(3)-header(1);
end
set(handles.tableheader,'position',header);


% --- Executes during object creation, after setting all properties.
function preflist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to preflist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

set(hObject,'BackgroundColor','white');

% --- Executes on selection change in preflist.
function preflist_Callback(hObject, eventdata, handles)
% hObject    handle to preflist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns preflist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from preflist

prefs = getappdata(handles.prefexpert,'prefs');
val = get(handles.preflist,'value');
if ~isempty(val)
  %make sure only one is selected
  val = val(1);
  set(handles.preflist,'value',val);
else
  %nothing selected, consider as "0"
  val = 0;
end

%look up in data
val = val-2;
if val>0;
  set(handles.functionname,'string',prefs{val,1});
  set(handles.optionname,'string',prefs{val,2});
else
  %nothing selected or
  set(handles.functionname,'string','');
  set(handles.optionname,'string','');
end
functionname_Callback(handles.optionname, [], handles);
optionname_Callback(handles.optionname, [], handles);


% --- Executes during object creation, after setting all properties.
function functionname_CreateFcn(hObject, eventdata, handles)
% hObject    handle to functionname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
  set(hObject,'BackgroundColor','white');
else
  set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function functionname_Callback(hObject, eventdata, handles)
% hObject    handle to functionname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of functionname as text
%        str2double(get(hObject,'String')) returns contents of functionname as a double

fn = get(handles.functionname,'string');
fn = lower(fn);  %force to be lower-case
set(handles.functionname,'string',fn);
if ~isempty(fn) & (~exist(fn) | ismember(fn,{'evriinstall'}))
  set(handles.functionname,'string','');
  set(handles.optionname,'string','');
  set(handles.value,'string','','userdata','');
end
update_listbox(handles);

% --- Executes on button press in viewoptions.
function viewoptions_Callback(hObject, eventdata, handles)
% hObject    handle to viewoptions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of viewoptions

update_listbox(handles);


% --- Executes during object creation, after setting all properties.
function optionname_CreateFcn(hObject, eventdata, handles)
% hObject    handle to optionname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
  set(hObject,'BackgroundColor','white');
else
  set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function optionname_Callback(hObject, eventdata, handles)
% hObject    handle to optionname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of optionname as text
%        str2double(get(hObject,'String')) returns contents of optionname as a double

fn = get(handles.functionname,'string');
pname = get(handles.optionname,'string');

if isempty(fn) | ismember(pname,{'definitions' 'functionname' 'name'});
  pname = '';
  set(handles.optionname,'string',pname);
end


if isempty(fn) | isempty(pname);
  val = [];
else
  val = getplspref(fn,pname);
end
if ~isempty(val)
  val = encode(val,'',struct('structformat','struct','forceoneline','on'));
end
set(handles.value,'string',val,'userdata',val);
update_listbox(handles);

% --- Executes during object creation, after setting all properties.
function value_CreateFcn(hObject, eventdata, handles)
% hObject    handle to value (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
  set(hObject,'BackgroundColor','white');
else
  set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function value_Callback(hObject, eventdata, handles)
% hObject    handle to value (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of value as text
%        str2double(get(hObject,'String')) returns contents of value as a double

ok = 'on';
clr = get(handles.ok,'backgroundcolor');
if ~strcmp(get(handles.value,'string'),get(handles.value,'userdata'));
  ok = 'off';
  clr = clr.*[1 .8 .8];
end
set(handles.ok,'enable',ok)
set(handles.set,'backgroundcolor',clr);


% --- Executes on button press in clear.
function clear_Callback(hObject, eventdata, handles)
% hObject    handle to clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fn = get(handles.functionname,'string');
pname = get(handles.optionname,'string');
if ~isempty(fn) & ~isempty(pname);
  %single option reset
  setplspref(fn,pname,'factory');
  set(handles.reset,'enable','on');
elseif ~isempty(fn) & isempty(pname);
  %single function reset
  ans = evriquestdlg(['Reset ' fn ' preferences to Factory Defaults?'],'Reset Preferences','Yes','Cancel','Cancel');
  if strcmp(ans,'Yes');
    setplspref(fn,'factory');
    set(handles.reset,'enable','on');
  end
elseif isempty(fn) & isempty(pname);
  %ALL function reset
  setplspref('factory');  %gives warning in setplspref
  set(handles.reset,'enable','on');
end
update_listbox(handles);


% --- Executes on button press in set.
function set_Callback(hObject, eventdata, handles)
% hObject    handle to set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fn = get(handles.functionname,'string');
pname = get(handles.optionname,'string');
val = get(handles.value,'string');
if ~isempty(fn) & ~isempty(pname);

  if ~isempty(val)
    %   nval = num2str(val);
    %   if isempty(nval);
    %     setplspref(fn,pname,val);   %string value
    %   else
    %     setplspref(fn,pname,nval);  %numerical value
    %   end

    %the following will revserse ANY string, but I don't like it much...
    try;
      evalin('caller',['setplspref(''' fn ''',''' pname ''',' val ');']);
      set(handles.reset,'enable','on');
      set(handles.value,'userdata',val);  %copy into userdata so we know it has been set
    catch
      erdlgpls('Invalid Override Value - Unable to parse (check for missing quotes on string?)');
    end
  elseif isempty(val);
    setplspref(fn,pname,'factory');
    set(handles.reset,'enable','on');
    set(handles.value,'userdata',val);  %copy into userdata so we know it has been set
  end
end
update_listbox(handles);


%-------------------------------------------
function update_listbox(handles)

fn = get(handles.functionname,'string');
if get(handles.viewoptions,'value') & ~isempty(fn)
  set(handles.tableheader,'string','Function Options')
  [prefs,prefcell] = disppref(fn);
  setappdata(handles.prefexpert,'prefs',prefcell);
else
  set(handles.tableheader,'string','Override Preferences')
  [prefs,prefcell] = disppref;
  setappdata(handles.prefexpert,'prefs',prefcell);
end

if isempty(prefs);
  set(handles.preflist,'string',' ','enable','inactive','min',0,'max',2,'value',[]);
else
  %   if isempty(get(handles.preflist,'value'))
  %     set(handles.preflist,'value',1);
  %   end
  set(handles.preflist,'string',prefs,'enable','on','min',0,'max',2,'value',[]);
end

if isempty(fn);
  en = 'off';
else
  en = 'on';
end
set([handles.optionname handles.clear handles.set],'enable',en);

ok = 'on';
clr = get(handles.ok,'backgroundcolor');
if strcmp(en,'off') | isempty(get(handles.optionname,'string'));
  en = 'off';
else
  en = 'on';
  if ~isempty(get(handles.value,'userdata')) && ~isempty(get(handles.value,'string')) && ~strcmp(get(handles.value,'string'),get(handles.value,'userdata'));
    ok = 'off';
    clr = clr.*[1 .8 .8];
  end
end
set(handles.ok,'enable',ok);
set(handles.set,'enable',en);
set(handles.set,'backgroundcolor',clr);

% --------------------------------------------------------------------
function filesaveas_Callback(hObject, eventdata, handles)
% hObject    handle to filesaveas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[file,folder,filterindex] = evriuiputfile({'*.xml','XML Preferences file (*.xml)';'*.mat','Matlab-format Preferences file (*.mat)'},'Save Preferences As...');
if ischar(file)
  Preferences = getplspref;
  [junk,junk,filetype] = fileparts(file);
  if isempty(filetype)
    switch filterindex
      case 1
        filetype = '.xml';
      case 2
        filetype = '.mat';
    end
    file = [file filetype];
  end
  switch lower(filetype)
    case '.mat'
      save(fullfile(folder,file),'Preferences','-mat');
    case '.xml'
      encodexml(struct('Preferences',Preferences),'Settings',fullfile(folder,file));
    otherwise
      erdlgpls('Unrecognized or invalid file type.','Save As Error');
  end
end


% --------------------------------------------------------------------
function fileload_Callback(hObject, eventdata, handles)
% hObject    handle to fileload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[file,folder] = evriuigetfile({'*.xml','XML Preferences file (*.xml)';'*.mat','Matlab-format Preferences file (*.mat)'},'Load Preferences');
if ischar(file)
  try
    [junk,junk,filetype] = fileparts(file);
    switch lower(filetype)
      case '.mat'
        pref = load(fullfile(folder,file),'-mat');
        pref = pref.Preferences;
      case '.xml'
        pref = parsexml(fullfile(folder,file));
        pref = pref.Settings.Preferences;
    end
    ans = evriquestdlg('Merge current preferences with contents of this preferences file?','Confirm Preferences Load','Merge','Cancel','Merge');
    if ~strcmp(ans,'Cancel')
      setplspref(pref);
      set(handles.reset,'enable','on');
      update_listbox(handles);
    end

  catch
    erdlgpls({'Invalid or unreadable preferences file.' lasterr},'Error Loading Preferences');
  end
end


% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

origpref = getappdata(handles.prefexpert,'origprefs');
setplspref(origpref);
close(handles.prefexpert);


% --- Executes on button press in ok.
function ok_Callback(hObject, eventdata, handles)
% hObject    handle to ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(handles.prefexpert);


% --- Executes on button press in reset.
function reset_Callback(hObject, eventdata, handles)
% hObject    handle to reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

origpref = getappdata(handles.prefexpert,'origprefs');
setplspref(origpref);
set(handles.viewoptions,'value',0);
set(handles.preflist,'value',1);
preflist_Callback(handles.preflist,[],handles);
set(handles.reset,'enable','off');


%------------------------------------------
%create cell array and good-formatted descriptive list of options
function [desc,pr] = disppref(fn,p)

if nargin==0;
  p=getpref('PLS_Toolbox');
else
  if nargin==1
    %got a function name only, look up its options
    if ismember(fn,{'evriinstall'})
      %NEVER look up options on these functions
      p = [];
    else
      %normal function - look up options (errors = no options)
      try
        p = reconopts([],fn);
      catch
        p = [];
      end
    end
  end
  if ~isstruct(p);
    p = struct([]);
  end
  %remove some bad fields (never show them)
  for badfield = {'definitions' 'functionname' 'name'};
    if isfield(p,badfield{:});
      p = rmfield(p,badfield{:});
    end
  end
  %create as sub-structure
  p = struct(fn,p);
end

pr = {};
dispfns = {};
if ~isempty(p);
  for onefn = sort(fieldnames(p))';
    fnprefs = getfield(p,onefn{:});
    dispname = onefn;
    if ~isempty(fnprefs)
      prefnames = fieldnames(fnprefs);
      for onepref = prefnames';
        pref = getfield(fnprefs,onepref{:});
        %create WHOLE cell of all items
        pr = [pr;{onefn{:} onepref{:} encode(pref,'',struct('structformat','struct','forceoneline','on'))}];
        %and create a cell of function names for display
        dispfns = [dispfns;dispname];
        dispname = {' '};
      end
    end
  end
end

desc = [strvcat('Function Name','-------------',dispfns{:}) repmat(' ',size(pr,1)+2,2) strvcat('Option','------',pr{:,2}) repmat(' ',size(pr,1)+2,2) strvcat('Value','-----',pr{:,3})];




% --------------------------------------------------------------------
function howtouse_Callback(hObject, eventdata, handles)
% hObject    handle to howtouse (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

evrihelp('expert_preferences_gui');
