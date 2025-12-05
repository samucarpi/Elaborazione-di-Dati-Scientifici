function varargout = normset(varargin)
%NORMSET GUI used to modfiy settings of NORMALIZ.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI
%
%I/O:   p = normset(p)
% (or)  p = normset('default')
%
%See also: NORMALIZ, PREPROCESS

%Copyright Eigenvector Research 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 8/3/2001
% 8/15/01 JMS fixed intro code to remove R10 warnings, corrected help
% 2/26/04 JMS set default order to 1st

if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))% LAUNCH GUI

	fig = openfig(mfilename,'reuse');
  set(fig,'WindowStyle','modal');
  centerfigure(fig,gcbf);
  setappdata(fig,'parentfig',gcbf);

	% Use system color scheme for figure:
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

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
    options.defaultnormtype = 1;
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

% --------------------------------------------------------------------
function okbtn_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.okbtn.
uiresume(gcbf)

% --------------------------------------------------------------------
function cancelbtn_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.cancelbtn.
close(gcbf)

% --------------------------------------------------------------------
function setup(handles, p)
% p is preprocessing structure (if any)

if nargin<2; p = []; end
p = default(p);           %get default settings (but maintain userdata if any)

%set up GUI based on decoded structure
normtype = p.userdata.normtype;
if isinf(normtype); normtype = 3; end
set(handles.normtype,'value',normtype);

%store p for modification when done
setappdata(handles.settingsfigure,'settings',p)
setappdata(handles.settingsfigure,'window',p.userdata.window)
update_selectedwindow(handles)
% --------------------------------------------------------------------
function p = encode_settings(handles)
% encode the GUI's settings into the Preprocessing structure

p = getappdata(handles.settingsfigure,'settings');

normtype = get(handles.normtype,'value');
if normtype==3; normtype = inf; end
win = getappdata(handles.settingsfigure,'window');
p.userdata = struct('normtype',normtype,'window',win);

p = setdescription(p);

% --------------------------------------------------------------------
function p = setdescription(p)

switch p.userdata.normtype
  case 1
    type = '1-Norm, Area = 1';
  case 2
    type = '2-Norm, Length = 1';
  case inf
    type = 'inf-Norm, Maximum = 1';
end
p.description = sprintf('Normalize (%s)',type);

% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
end

p = preprocess('validate',p);  %validate what was passed in
p.description   = 'Normalize';
p.calibrate     = {'[data,out{2}] = normaliz(data,0,userdata.normtype,userdata.window);'};
p.apply         = {'[data,out{2}] = normaliz(data,0,userdata.normtype,userdata.window);'};
p.undo          = {'data.data = spdiags(out{2},0,length(out{2}),length(out{2}))*data.data;'};
p.out           = {};
p.settingsgui   = 'normset';
p.settingsonadd = 1;
p.usesdataset   = 1;
p.caloutputs    = 0;
p.tooltip       = 'Scale each sample (row) to sum of intensity or power of intensity';
p.category      = 'Normalization';

options = normset('options');  %get our options

if isempty(p.userdata);
  p.userdata    = struct('normtype',options.defaultnormtype,'window',[]);          %defaults
end



% --------------------------------------------------------------------
function normtype_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.normtype.


% --- Executes on button press in select.
function select_Callback(hObject, eventdata, handles)
% hObject    handle to select (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dat = preprocess('getdataset',getappdata(handles.settingsfigure,'parentfig'));
win = getappdata(handles.settingsfigure,'window');
if isempty(dat)
  sel = inputdlg({'Window Indices:'},'Select window',1,{encode(win,'')});
  win = str2num(sel{1});
else
  %we've got data, share it and allow plotgui to modify the include field
  evritip('normsetselect','Use Include and Exclude to indicate region which should be used for normalization (only included region will be used).',1)
  if ~isempty(win);
    dat.include{2} = win;
  end
  items = [];
  items.cont = {'string','Done','Callback','uiresume(getappdata(gcbf,''target''));'};
  
  btnlist = {
    'selectx'      'selectonly' 'plotgui(''makeselection'',gcbf);plotgui(''menuselection'',''EditExcludeUnselected'')'   'enable' 'Choose Included Range'    'off'   'push'
    'selectxplus'  'selectadd'  'plotgui(''makeselection'',gcbf);plotgui(''menuselection'',''EditIncludeSelection'')'    'enable' 'Add to Included'          'off'   'push'
    'selectxminus' 'selectsub'  'plotgui(''makeselection'',gcbf);plotgui(''menuselection'',''EditExcludeSelection'')'    'enable' 'Subtract from Included'   'off'   'push'
    'ok'           'accept'     'close(gcbf)'                                                                            'enable' 'Accept and close'         'on'    'push'
    };

  %share data and get plotgui to modify include field
  myid = setshareddata(handles.settingsfigure,dat);  
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
  dat = myid.object;
  win = dat.include{2};
  if length(win)==size(dat,2);
    %everything selected? interpret as empty
    win = [];
  end
  removeshareddata(myid);
  
end
  
setappdata(handles.settingsfigure,'window',win);
update_selectedwindow(handles)

% --- Executes on button press in reset.
function reset_Callback(hObject, eventdata, handles)
% hObject    handle to reset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

win = [];
setappdata(handles.settingsfigure,'window',win);
update_selectedwindow(handles);

% --- Executes during object creation, after setting all properties.
function selectedwindow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to selectedwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in selectedwindow.
function selectedwindow_Callback(hObject, eventdata, handles)
% hObject    handle to selectedwindow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns selectedwindow contents as cell array
%        contents{get(hObject,'Value')} returns selected item from selectedwindow

%---------------------------------------------
function update_selectedwindow(handles)

win = getappdata(handles.settingsfigure,'window');
if isempty(win);
  win = '(all variables)';
else
  win = encode(win,'');
end
set(handles.selectedwindow,'string',win);

%enable/disable window selection based on size of data
dat = preprocess('getdataset',getappdata(handles.settingsfigure,'parentfig'));
en = 'on';
if ndims(dat)>2
  en = 'off';
end
set([handles.selectedwindow handles.reset handles.select],'enable',en);
  
