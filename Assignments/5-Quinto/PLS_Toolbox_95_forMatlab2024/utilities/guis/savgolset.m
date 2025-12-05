function varargout = savgolset(varargin)
%SAVGOLSET GUI used to modfiy settings of SAVGOL.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI.
%
%I/O:   p = savgolset(p)
% (or)  p = savgolset('default')
%
%See also: PREPROCESS, SAVGOL

%Copyright Eigenvector Research 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 8/3/2001
% 8/15/01 JMS fixed intro code to remove R10 warnings, corrected help
% 9/18/01 JMS rewrote from normset for detrend
% 9/18/01 JMS rewrote from detrendset for auto
% 9/18/01 JMS rewrote from autoset for savgol
% 1/23/02 JMS added keyword to structure
% 10/7/02 JMS added odd-width test, made savgol dataset enabled
% 02/24/06 RSK added warning for smooth to deriv switch.

if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))% LAUNCH GUI

	fig = openfig(mfilename,'reuse');
  set(fig,'WindowStyle','modal','units','pixels','Resize','on');
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
      varargout{1} = [];   %return empty (canceled)
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
set(handles.width,'string',num2str(p.userdata.width));
set(handles.polynomialorder,'value',p.userdata.order+1);
set(handles.derivativeorder,'value',p.userdata.deriv+1);
set(handles.useexcluded,'value',strcmp(p.userdata.useexcluded,'true'));
if strcmp(p.userdata.tails,'weighted')
  set(handles.wtails,'value',true)
else
  set(handles.wtails,'value',false)
end

fontsize = getdefaultfontsize('normal');
sc = fontsize/9;

ch = allchild(handles.settingsfigure);
ch(~isprop(ch,'fontsize')) = [];
set(ch,'fontunits','points','fontsize',fontsize);

remapfig([0 0 1 1],[0 0 sc sc],handles.settingsfigure);

fpos = get(handles.settingsfigure,'position');
set(handles.settingsfigure,'position',[fpos(1:2) fpos(3:4)*sc])
positionmanager(handles.settingsfigure,'onscreen');
setappdata(handles.settingsfigure,'settings',p)

% --------------------------------------------------------------------
function p = encode(handles)
% encode the GUI's settings into the Preprocessing structure
% This routine must take the current GUI object settings and "encode" them
%  into the userdata property (as well as any other structure changes)

p = getappdata(handles.settingsfigure,'settings');
if get(handles.useexcluded,'value')
  useexcluded = 'true';
else
  useexcluded = 'false';
end

p.userdata.width = str2num(get(handles.width,'string'));
p.userdata.order = get(handles.polynomialorder,'value')-1;
p.userdata.deriv = get(handles.derivativeorder,'value')-1;
p.userdata.useexcluded = useexcluded;

if get(handles.wtails,'value')
  p.userdata.tails = 'weighted';
  p.userdata.wt    = '1/d';
else
  p.userdata.tails = 'polyinterp';
  p.userdata.wt    = '';
end

p = setdescription(p);

% --------------------------------------------------------------------
function p = setdescription(p)

ordinal = {'zero' '1st','2nd','3rd','4th','5th','6th'};
details = sprintf('order: %i, window: %i pt',p.userdata.order,p.userdata.width);

if strcmp(p.userdata.useexcluded,'false')
  details = [details ', incl only'];
end

details = [details ', tails: ' p.userdata.tails];

if p.userdata.mode==1
  modename = 'Column-Wise ';
else
  modename = '';
end

if p.userdata.deriv>0;
  p.description = sprintf('%s%s Derivative (%s)',modename,ordinal{p.userdata.deriv+1},details); 
  p.keyword = 'derivative';
else
  p.description = sprintf('%sSmoothing (%s)',modename,details); 
  p.keyword = 'smooth';
end
p.keyword = [p.keyword lower(strtrim(modename))];

% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
end
         
p = preprocess('validate',p);  %validate what was passed in

p.description   = 'SG Smooth/Derivative';
p.calibrate     = {'data = savgol(data,userdata.width,userdata.order,userdata.deriv,struct(''wt'',userdata.wt,''tails'',userdata.tails,''useexcluded'',userdata.useexcluded,''mode'',userdata.mode));'};
p.apply         = {'data = savgol(data,userdata.width,userdata.order,userdata.deriv,struct(''wt'',userdata.wt,''tails'',userdata.tails,''useexcluded'',userdata.useexcluded,''mode'',userdata.mode));'};
p.undo          = {};   %cannot undo
p.out           = {};
p.settingsgui   = 'savgolset';
p.settingsonadd = 1;
p.usesdataset   = 1;
p.caloutputs    = 0;
p.keyword       = 'sg';
p.category      = 'Filtering';
p.tooltip       = 'Savitzky-Golay smoothing and derivatives.';

%get value for how to handle tails
tails = char(getplspref('savgolset','tails'));
if isempty(tails)
  tails = 'polyinterp';  %how to handle tails (default if no preference is set)
end

%Get weight default.
wt = char(getplspref('savgolset','wt'));
if isempty(wt)
  wt = '';
end

if isempty(p.userdata);
  p.userdata = struct('width',15,'order',2,'deriv',0,'useexcluded','true','tails',tails,'wt',wt,'mode',2);   %defaults for NEW instances
end
if isnumeric(p.userdata);
  %convert to structure if not
  p.userdata = struct('width',p.userdata(1),'order',p.userdata(2),'deriv',p.userdata(3),'useexcluded','true','tails',tails,'wt',wt);  %defaults if passed as userdata (backwards compatibility)
end
if ~isfield(p.userdata,'useexcluded')
  p.userdata.useexcluded='true';   %backwards compatibility (will be used for internal cases only in pre-release software where struct already existed without this option)
end
if ~isfield(p.userdata,'tails')
  p.userdata.tails = tails;
end
if ~isfield(p.userdata,'wt')
  p.userdata.wt = wt;
end
if ~isfield(p.userdata,'mode')
  p.userdata.mode = 2;
end

% --------------------------------------------------------------------
function width_Callback(h, eventdata, handles, varargin)
val = str2num(get(handles.width,'string'));
if isempty(val) | val<3; val = 3; end
val = val+1-mod(val,2);   %round to odd #
set(handles.width,'string',num2str(val));

% --------------------------------------------------------------------
function polynomialorder_Callback(h, eventdata, handles, varargin)

po = get(handles.polynomialorder,'value');
do = get(handles.derivativeorder,'value');
if do > po; set(handles.derivativeorder,'value',po); end   %bump down deriv. order if new poly order is lower than it

% --------------------------------------------------------------------
function derivativeorder_Callback(h, eventdata, handles, varargin)

po = get(handles.polynomialorder,'value');
do = get(handles.derivativeorder,'value');

p = getappdata(handles.settingsfigure,'settings');
%Create warning if changing from "smoothing" to "derivative". Warn once per
%session with appdata(0). 

if p.userdata.deriv==0 & do>0
  if isempty(getappdata(0,'savgolsmoothwarning'))
    evriwarndlg(['By changing the derivative order, you are changing from smoothing to derivatives.  If you only want smoothing, set the derivative order back to zero.  This warning will not re-appear']...
      ,'Converting to Derivative');
  end
  setappdata(0,'savgolsmoothwarning',1)
end 

if po < do; set(handles.polynomialorder,'value',do); end    %bump up poly order if new derivative is higher than it



% --- Executes on button press in useexcluded.
function useexcluded_Callback(hObject, eventdata, handles)
% hObject    handle to useexcluded (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of useexcluded


% --- Executes on button press in wtails.
function wtails_Callback(hObject, eventdata, handles)
% hObject    handle to wtails (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of wtails


% --- Executes on button press in helpbtn.
function helpbtn_Callback(hObject, eventdata, handles)
% Open help page.
evrihelp('savgol');



