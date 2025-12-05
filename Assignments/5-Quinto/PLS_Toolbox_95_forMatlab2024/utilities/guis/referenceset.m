function varargout = referenceset(varargin)
%REFERENCESET Settings used to modfiy reference/background correction settings.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided.
% if p is 'default', default structure is returned without GUI.
%
%
%I/O:   p = referenceset
%I/O:   p = referenceset(p)
%
%See also: SCALE, PREPROCESS

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
if nargin == 0  | ~ischar(varargin{1})% LAUNCH GUI
  
  fig = openfig(mfilename,'reuse');
  set(fig,'WindowStyle','modal');
  centerfigure(fig,gcbf);
  set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
  setappdata(fig,'parentfig',gcbf);
  
  % Generate a structure of handles to pass to callbacks, and store it.
  handles = guihandles(fig);
  
  guidata(fig, handles);
  if nargin > 0 & isstruct(varargin{1})
    %Save pp to appdata.
    setappdata(fig,'settings',varargin{1});
  end
  
  setup(handles)
  
  % Wait for callbacks to run and window to be dismissed:
  uiwait(fig);
  
  if nargout > 0
    if ishandle(fig);  %still exists?
      varargout{1} = encode_settings(handles);
    else
      varargout{1} = [];
    end
  end
  if ishandle(fig);  %still exists?
    close(fig);
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

%-------------------------------------------------------------
function setup(handles)
%Set default values.

set(findobj(handles.referenceset,'type','uicontrol'),'fontsize',getdefaultfontsize)

p = getappdata(handles.referenceset,'settings');
p = default(p);

%enable appropriate operation box
if p.userdata.operation==2
  %divide operation
  set(handles.background,'value',0)
  set(handles.ref,'value',1)
else
  %"subtract" operation
  set(handles.background,'value',1)
  set(handles.ref,'value',0)
end

[data,myid] = getdataset(handles);
calavailable = ~isempty(data);
setappdata(handles.referenceset,'calavailable',calavailable);
setappdata(handles.referenceset,'calexcludeable',~isempty(myid))

if isempty(p.userdata.data)    %no data loaded?
  set(handles.sourcemenu,'value',1); % = calibration data
else
  set(handles.sourcemenu,'value',2-(~calavailable)); % = external data
  setappdata(handles.referenceset,'data',p.userdata.data);
end


setappdata(handles.sourcemenu,'oldvalue',get(handles.sourcemenu,'value'));
update_sourcerow(handles)

setappdata(handles.referenceset,'settings',p)

%-------------------------------------------------------------
function [data,myid] = getdataset(handles)

[data,other,myid] = preprocess('getdataset',getappdata(handles.referenceset,'parentfig'));

%-------------------------------------------------------------
function update_sourcerow(handles)
%update source row control based on current settings

value = get(handles.sourcemenu,'value');
index = get(handles.sourcerow,'value');
calavailable = getappdata(handles.referenceset,'calavailable');

sourcestring = {'Calibration Data','External Data','Load New External Data...'};

if ~calavailable
  value = value+1;
end

switch value
  case 1
    %calibration data
    data = getdataset(handles);
    sourcestring = sourcestring(1:2);
    set(handles.harddelete,'enable','on')

  otherwise
    %external data (already loaded)
    data = getappdata(handles.referenceset,'data');
    value = 2;
    set(handles.harddelete,'enable','off','value',0)
    
end
if ~calavailable
  value = value-1;
  sourcestring = sourcestring(2:end);
end

set(handles.sourcemenu,'string',sourcestring,'value',value);
if isempty(data)
  set(handles.sourcerow,'min',0,'max',2,'enable','off','value',[],'string','--none loaded--');
  set(handles.pushbutton3,'enable','off');
  return
end
set(handles.pushbutton3,'enable','on');

%populate row list with info from loaded data
m   = size(data,1);
index = max([index 1]);
index = min(m,index);
labels = '';
if isdataset(data)
  labels = data.label{1};
end
if isempty(labels);
  labels = str2cell(sprintf('Row %i\n',1:m));
end
set(handles.sourcerow,'value',index,'string',labels,'min',1,'max',1,'enable','on');

%-------------------------------------------------------------
function btn_ok_Callback(hObject, eventdata, handles)
%Ok button callback.
uiresume(gcbf);

%-------------------------------------------------------------
function btn_help_Callback(hObject, eventdata, handles)
%Show help.

evrihelp('Background_Reference_Settings');

%-------------------------------------------------------------
function btn_cancel_Callback(hObject, eventdata, handles)
%Cancel.
close(gcbf)

%--------------------------------------------------------------------
function p = encode_settings(handles)
% encode the GUI's settings into the Preprocessing structure
% This routine must take the current GUI object settings and "encode" them
%  into the userdata property (as well as any other structure changes)

p  = getappdata(handles.referenceset,'settings');

sourcetype = get(handles.sourcemenu,'value');
index = get(handles.sourcerow,'value');
calavailable = getappdata(handles.referenceset,'calavailable');
if ~calavailable
  sourcetype = sourcetype+1;
end

switch sourcetype
  case 1
    [data,myid] = getdataset(handles);
    if get(handles.harddelete,'value')      %hard-delete row
      modelcache([],data);
      myid.object = delsamps(myid.object,index,1,2);
    end
      
  otherwise
    data = getappdata(handles.referenceset,'data');
end

data = data(index,:);
if ~isdataset(data)
  data = dataset(data);
end

p.userdata.data = data;
p.userdata.operation = get(handles.ref,'value')+1;

if p.userdata.operation==1
  p.description = 'Fixed Background Subtraction';
else
  p.description = 'Ratio to Reference';
end
lbl = data.label{1};
if ~isempty(lbl)
  p.description = [p.description ' (' lbl ')'];
end

%--------------------------------------------------------------------
function pd = default(p)
%Create default structure for this preprocessing method if "p" is passed
%in, only the userdata from that structure is kept.

pd = [];
pd.description = 'Reference/Background Correction';
pd.calibrate = {'out{userdata.operation}=userdata.data.data(:,data.include{2});data = scale(data,out{:});'};
pd.apply     = {'out{userdata.operation}=userdata.data.data(:,data.include{2});data = scale(data,out{:});'};
pd.undo      = {'out{userdata.operation}=userdata.data.data(:,data.include{2});data = rescale(data,out{:});'};
pd.out       = {};
pd.settingsgui = mfilename;
pd.settingsonadd = 1;
pd.usesdataset = 1;
pd.caloutputs = 0;
pd.keyword = 'referencecorrection';
pd.tooltip = 'Divide by reference or subtract fixed background';
pd.category = 'Transformations';
pd.userdata = struct('data',[],'operation',2);

if nargin>0 & ~isempty(p);
  %Copy over userdata.
  pd.userdata = p.userdata;
end


% --- Executes on button press in ref.
function ref_Callback(hObject, eventdata, handles)
% hObject    handle to ref (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ref
set(handles.background,'value',0);


% --- Executes on button press in background.
function background_Callback(hObject, eventdata, handles)
% hObject    handle to background (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of background

set(handles.ref,'value',0);


% --- Executes on selection change in sourcerow.
function sourcerow_Callback(hObject, eventdata, handles)
% hObject    handle to sourcerow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sourcerow contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sourcerow

% --- Executes during object creation, after setting all properties.
function sourcerow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sourcerow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in sourcemenu.
function sourcemenu_Callback(hObject, eventdata, handles)
% hObject    handle to sourcemenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sourcemenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sourcemenu

value = get(handles.sourcemenu,'value');
oldvalue = getappdata(handles.sourcemenu,'oldvalue');

%if calibration data is NOT available, adjust the value for this
calavailable = getappdata(handles.referenceset,'calavailable');
if ~calavailable
  value = value+1;
  oldvalue = oldvalue+1;
end

switch value
  case 1
    %switch to calibration data, just update
    data = getdataset(handles);
  otherwise
    %switch to external data (or new external data)
    if oldvalue==2 & value==2
      %just re-selected external, don't do anything
      return
    end
    %otherwise, new selection of external OR load new external
    data = lddlgpls('doubdataset','Load Reference/Background Data');
end
if ~isdataset(data)
  data = dataset(data);
end
if ~calavailable
  value    = value-1;
  oldvalue = oldvalue-1;
end

if isempty(data)
  set(handles.sourcemenu,'value',oldvalue);
else
  if value~=1
    %for external data, store the external data now
    setappdata(handles.referenceset,'data',data)
  end
  setappdata(handles.sourcemenu,'oldvalue',oldvalue);
  update_sourcerow(handles);
end


% --- Executes during object creation, after setting all properties.
function sourcemenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sourcemenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in harddelete.
function harddelete_Callback(hObject, eventdata, handles)
% hObject    handle to harddelete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of harddelete

if get(handles.harddelete,'value')
  resp = evriquestdlg('This will PERMANENTLY remove the selected item from your calibration data as soon as you close the settings dialog (original data will be stored in Model Cache). Are you sure you want to do this?','Confirm Hard-Delete','OK','No - Cancel','OK');
  if ~strcmp(resp,'OK')
    set(handles.harddelete,'value',0);
    return
  end
end
