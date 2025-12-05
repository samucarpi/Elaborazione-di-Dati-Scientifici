function varargout = gapsegmentset(varargin)
%GAPSEGMENTSET GUI used to modfiy settings of GAPSEGMENT.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI.
%
%I/O:   p = gapsegmentset(p)
% (or)  p = gapsegmentset('default')
%
%See also: PREPROCESS, SAVGOL

%Copyright Eigenvector Research 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))% LAUNCH GUI

	fig = openfig(mfilename,'reuse');
  set(fig,'WindowStyle','modal','units','pixels');
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
      varargout{1} = []; %return empty (canceled)
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
set(handles.gap,'string',num2str(p.userdata.gap));
set(handles.segment,'string',num2str(p.userdata.segment));
set(handles.derivativeorder,'value',p.userdata.order);

fontsize = getdefaultfontsize;

%store p for modification when done
setappdata(handles.settingsfigure,'settings',p)
set([handles.text1 handles.gap handles.text2 handles.segment handles.text3 handles.derivativeorder handles.text6],'fontsize',fontsize)
set(allchild(handles.settingsfigure),'units','normalized')
set(handles.settingsfigure,'resize','on')
% --------------------------------------------------------------------
function p = encode(handles)
% encode the GUI's settings into the Preprocessing structure
% This routine must take the current GUI object settings and "encode" them
%  into the userdata property (as well as any other structure changes)

p = getappdata(handles.settingsfigure,'settings');
p.userdata.gap     = str2num(get(handles.gap,'string'));
p.userdata.segment = str2num(get(handles.segment,'string'));
p.userdata.order   = get(handles.derivativeorder,'value');

p = setdescription(p);

% --------------------------------------------------------------------
function p = setdescription(p)

ordinal = {'1st','2nd','3rd','4th','5th','6th'};
details = sprintf('gap: %i, segment: %i',p.userdata.gap,p.userdata.segment);

p.description = sprintf('Gap Segment %s Derivative (%s)',ordinal{p.userdata.order},details); 

% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
end
         
p = preprocess('validate',p);  %validate what was passed in

p.description   = 'Gap Segment Derivative';
p.calibrate     = {'data = gapsegment(data,userdata.order,userdata.gap,userdata.segment,struct(''algorithm'',userdata.algorithm));'};
p.apply         = {'data = gapsegment(data,userdata.order,userdata.gap,userdata.segment,struct(''algorithm'',userdata.algorithm));'};
p.undo          = {};   %cannot undo
p.out           = {};
p.settingsgui   = 'gapsegmentset';
p.settingsonadd = 1;
p.usesdataset   = 0;
p.caloutputs    = 0;
p.keyword       = 'gapsegment';
p.tooltip       = 'Gap Segment smoothing and derivatives';
p.category      = 'Filtering';

if isempty(p.userdata);
  p.userdata = struct('order',1,'gap',5,'segment',5,'algorithm','standard');   %defaults for NEW instances
end

% --------------------------------------------------------------------
function gap_Callback(h, eventdata, handles, varargin)
val = str2num(get(handles.gap,'string'));
if isempty(val) | val<3; val = 3; end
val = val+1-mod(val,2);   %round to odd #
set(handles.gap,'string',num2str(val));

% --------------------------------------------------------------------
function derivativeorder_Callback(h, eventdata, handles, varargin)


% --- Executes on button press in helpbtn.
function helpbtn_Callback(hObject, eventdata, handles)
% Open help page.
evrihelp('gapsegment');



function segment_Callback(hObject, eventdata, handles)
% hObject    handle to segment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of segment as text
%        str2double(get(hObject,'String')) returns contents of segment as a
%        double
val = str2num(get(handles.segment,'string'));
if isempty(val) | val<3; val = 3; end
val = val+1-mod(val,2);   %round to odd #
set(handles.segment,'string',num2str(val));

% --- Executes during object creation, after setting all properties.
function segment_CreateFcn(hObject, eventdata, handles)
% hObject    handle to segment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
