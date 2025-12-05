function varargout = npreproscaleset(varargin)
%NPREPROSCALESET GUI used to modfiy settings of NPREPROCESS for scaling.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI
%
%I/O:   p = npreproscaleset(p)
% (or)  p = npreproscaleset('default')
%
%See also: AUTO, PREPROCESS

%Copyright Eigenvector Research 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 8/3/2001

if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))% LAUNCH GUI

	fig = openfig(mfilename,'reuse');
  set(fig,'WindowStyle','modal');
  centerfigure(fig,gcbf);
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
		[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
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
function mode_Callback(hObject, eventdata, handles)

val = str2num(get(handles.mode,'string'));
val = fix(val);
val(~isfinite(val)) = [];
val(val<1) = [];
mydata = getappdata(handles.scaling,'dataset');
if ~isempty(mydata);
  val(val>ndims(mydata)) = [];
end
if isempty(val); val = get(handles.mode,'value'); end

set(handles.mode,'string',num2str(val),'value',val);  

% --------------------------------------------------------------------
function  okbtn_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.okbtn.
uiresume(gcbf)

% --------------------------------------------------------------------
function  cancelbtn_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.cancelbtn.
close(gcbf)

% --------------------------------------------------------------------
function setup(handles, p)
% p is preprocessing structure (if any)

if nargin<2; p = []; end
p = default(p);           %get default settings (but maintain userdata if any)

mydata = preprocess('getdataset');
if ~isempty(mydata)
  if size(p.userdata{1}(2),2)>ndims(mydata);
    p.userdata{1} = p.userdata{1}(:,1:ndims(mydata));
  end
end
setappdata(handles.scaling,'dataset',mydata);

%set up GUI based on decoded structure
set(handles.mode,'string',num2str(find(p.userdata{1}(2,:))),'value',find(p.userdata{1}(2,:)));  

%store p for modification when done
setappdata(handles.scaling,'settings',p)

% --------------------------------------------------------------------
function p = encode(handles)
% encode the GUI's settings into the Preprocessing structure

p = getappdata(handles.scaling,'settings');

mydata = getappdata(handles.scaling,'dataset');
if ~isempty(mydata);
  temp = zeros(2,ndims(mydata));
else
  temp = zeros(2,2);
end
temp(2,get(handles.mode,'value')) = 1;

p.userdata = {temp};


% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
end

p = preprocess('validate',p);  %validate what was passed in
p.description = 'Multiway Scale';
p.calibrate = { '[data,out{1}] = npreprocess(data,userdata{1},[],0,struct(''display'',''off''));' };
p.apply = { 'data = npreprocess(data,out{1},0,struct(''display'',''off''));' };
p.undo = { 'data = npreprocess(data,out{1},1,struct(''display'',''off''));' };
p.out = {};
p.settingsgui = 'npreproscaleset';
p.settingsonadd = 1;
p.usesdataset = 1;
p.caloutputs = 1;
p.keyword = 'Scaling';
p.tooltip       = 'Autoscaling for multiway arrays.';
p.category      = 'Scaling and Centering';

if isempty(p.userdata);
  p.userdata = {[0 0;0 1]};
end

mydata = preprocess('getdataset');
if ~isempty(mydata)
  if size(p.userdata{1},2)>ndims(mydata);
    p.userdata{1} = p.userdata{1}(:,1:ndims(mydata));
  end
  if size(p.userdata{1},2)<ndims(mydata);
    p.userdata{1}(2,ndims(mydata)) = 0;
  end
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

npreprocess
