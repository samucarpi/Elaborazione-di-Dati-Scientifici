function varargout = autoset(varargin)
%AUTOSET GUI used to modfiy settings of AUTO.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI
%
%I/O:   p = autoset(p)
% (or)  p = autoset('default')
%
%See also: AUTO, PREPROCESS

%Copyright Eigenvector Research 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 8/3/2001
% 8/15/01 JMS fixed intro code to remove R10 warnings, corrected help
% 9/18/01 JMS rewrote from normset for detrend
% 9/18/01 JMS rewrote from detrendset for auto

if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))% LAUNCH GUI

	fig = openfig(mfilename,'reuse');
  set(fig,'WindowStyle','modal');
  centerfigure(fig,gcbf);

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
      varargout{1} = encode(handles);
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
% This routine must take the current userdata (defined in the default routine)
%  and appropriately update the GUI objects based on values therein

if nargin<2; p = []; end
p = default(p);           %get default settings (but maintain userdata if any)

%set up GUI based on decoded structure
set(handles.offset,'string',num2str(p.userdata.offset));
set(handles.stdthreshold,'string',num2str(p.userdata.stdthreshold));
set(handles.badreplacement,'string',num2str(p.userdata.badreplacement));
if strcmp('robust', p.userdata.algorithm)
  set(handles.algorithm,'Value', 1);
else
  set(handles.algorithm,'Value', 0);
end

%store p for modification when done
setappdata(handles.settingsfigure,'settings',p)

% --------------------------------------------------------------------
function p = encode(handles)
% encode the GUI's settings into the Preprocessing structure
% This routine must take the current GUI object settings and "encode" them
%  into the userdata property (as well as any other structure changes)

p          = getappdata(handles.settingsfigure,'settings');
if get(handles.algorithm, 'Value')==1
  algo_str = 'robust';
else
  algo_str = 'standard';
end
p.userdata = struct(...
  'offset'      ,str2num(get(handles.offset,'string')),...
  'stdthreshold',str2num(get(handles.stdthreshold,'string')),...
  'badreplacement',str2num(get(handles.badreplacement,'string')),...
  'algorithm', algo_str ...
  );

p = setdescription(p);

% --------------------------------------------------------------------
function p = setdescription(p)

if strcmp('robust', p.userdata.algorithm)
  algo = sprintf('%s algorithm, ', p.userdata.algorithm);
  str = sprintf('%s, (%s, offset %#.3g', p.description, algo, p.userdata.offset);
else
  str = sprintf('%s, (offset %#.3g', p.description, p.userdata.offset);
end

% str = sprintf('%s, (%s, offset %#.3g', algo, p.description, p.userdata.offset);
if length(p.userdata.stdthreshold)==1
  str = sprintf('%s, thresh %#.3g', str, p.userdata.stdthreshold);
elseif length(p.userdata.stdthreshold)>1
  str = sprintf('%s, thresh <vector>', str);
end
p.description = sprintf('%s, badrepl %#.3g)', str, p.userdata.badreplacement);

% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
end
         
p = preprocess('validate',p);  %validate what was passed in
  
p.description   = 'Autoscale';
p.calibrate     = {'[data,out{1},out{2}] = auto(data,userdata);'};
p.apply         = {'data = scale(data,out{1},out{2},userdata);'};
p.undo          = {'data = rescale(data,out{1},out{2},userdata);'};
p.out           = {};
p.settingsgui   = 'autoset';
p.settingsonadd = 0;
p.usesdataset   = 1;
p.caloutputs    = 2;
p.tooltip       = 'Mean center and scale each variable to unit standard deviation';
p.category      = 'Scaling and Centering';

defaults = [];
temp = auto('options');          %get defaults
defaults.offset = temp.offset;
defaults.badreplacement = temp.badreplacement;
defaults.stdthreshold = temp.stdthreshold;
defaults.algorithm = temp.algorithm;

if isempty(p.userdata);
  %no userdata yet
  p.userdata = defaults;
elseif isnumeric(p.userdata)
  %numeric value for userdata is old format (only specifying offset) to
  %make this work with this GUI, convert it into a structure
  defaults.offset = p.userdata;
  p.userdata = defaults;
end


% --------------------------------------------------------------------
function offset_Callback(h, eventdata, handles, varargin)

val = str2num(get(handles.offset,'string'));
if isempty(val); val = 0; end
set(handles.offset,'string',num2str(val));


% --- Executes during object creation, after setting all properties.
function stdthreshold_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stdthreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function stdthreshold_Callback(hObject, eventdata, handles)
% hObject    handle to stdthreshold (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stdthreshold as text
%        str2double(get(hObject,'String')) returns contents of stdthreshold as a double

val = str2num(get(handles.stdthreshold,'string'));
if isempty(val); val = 0; end
set(handles.stdthreshold,'string',num2str(val));

% --- Executes on button press in load.
function load_Callback(hObject, eventdata, handles)
% hObject    handle to load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

val = lddlgpls('double','Choose Scaling Threshold Variable');
if isempty(val);
  return
end
if all(size(val)>1);
  erdlgpls('Selected variable must be a vector or scalar value. Load aborted.','Load Threshold Error');
  return
end
val = val(:)';
set(handles.stdthreshold,'string',num2str(val));


% --- Executes on button press in help.
function help_Callback(hObject, eventdata, handles)
% hObject    handle to help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

evrihelp('autoset')

% --- Executes during object creation, after setting all properties.
function badreplacement_CreateFcn(hObject, eventdata, handles)
% hObject    handle to badreplacement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function badreplacement_Callback(hObject, eventdata, handles)
% hObject    handle to badreplacement (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of badreplacement as text
%        str2double(get(hObject,'String')) returns contents of badreplacement as a double

val = str2num(get(handles.badreplacement,'string'));
if isempty(val); val = 0; end
set(handles.badreplacement,'string',num2str(val));

% --- Executes during object creation, after setting all properties.
function algorithm_CreateFcn(hObject, eventdata, handles)
% hObject    handle to algorithm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


function algorithm_Callback(hObject, eventdata, handles)
% hObject    handle to algorithm (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of badreplacement as text
%        str2double(get(hObject,'String')) returns contents of badreplacement as a double

% val = str2num(get(handles.badreplacement,'string'));
% if isempty(val); val = 0; end
% set(handles.badreplacement,'string',num2str(val));

val = get(handles.algorithm,'Value');
if isempty(val); val = 0; end
set(handles.algorithm,'Value', val);
