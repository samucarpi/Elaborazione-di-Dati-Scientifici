function varargout = oscset(varargin)
%OSCSET GUI used to modfiy settings of Orthogonal Signal Correction GUI.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI
%
%I/O:   p = oscset(p)
% (or)  p = oscset('default')
%
%See also: OSCAPP, OSCCALC, PREPROCESS

%Copyright Eigenvector Research, Inc. 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 8/3/2001
% 8/15/01 JMS fixed intro code to remove R10 warnings, corrected help
% 9/18/01 JMS rewrote from normset for detrend
% 9/18/01 JMS rewrote from detrendset for auto
% 9/18/01 JMS rewrote from autoset for savgol
% 1/23/02 JMS added keyword to structure
% 4/09/02 JMS rewrote from savgol for oscset

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
% This routine must take the current userdata (defined in the default routine)
%  and appropriately update the GUI objects based on values therein

if nargin<2; p = []; end
p = default(p);           %get default settings (but maintain userdata if any)

%set up GUI based on decoded structure
set(handles.components,'string',num2str(p.userdata(1)));
set(handles.iterations,'string',num2str(p.userdata(2)));
set(handles.tolerance, 'string',num2str(p.userdata(3)));

%store p for modification when done
setappdata(handles.settingsfigure,'settings',p)

% --------------------------------------------------------------------
function p = encode(handles)
% encode the GUI's settings into the Preprocessing structure
% This routine must take the current GUI object settings and "encode" them
%  into the userdata property (as well as any other structure changes)

p          = getappdata(handles.settingsfigure,'settings');
p.userdata = [str2num(get(handles.components,'string')) str2num(get(handles.iterations,'string')) str2num(get(handles.tolerance,'string'))];

str = sprintf('OSC (#components = %d', p.userdata(1));
str = sprintf('%s, #iters = %d', str, p.userdata(2));
p.description = sprintf('%s, tolerance = %#.3g%s)', str, p.userdata(3), '%');

% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
end
         
p = preprocess('validate',p);  %validate what was passed in
  
p.description   = 'OSC (Orthogonal Signal Correction)';
p.calibrate     = {'if length(otherdata)<1; error([''OSC requires y-block'']); end; if isa(otherdata{1},''dataset''); otherdata{1} = otherdata{1}.data(include{1},otherdata{1}.include{2}); end; [data,out{1},out{2}] = osccalc(data,otherdata{1},userdata(1),userdata(2),userdata(3));'};
p.apply         = {'data = oscapp(data,out{1:2});'};
p.undo          = {};   %cannot undo
p.out           = {};
p.settingsgui   = 'oscset';
p.settingsonadd = 0;
p.usesdataset   = 0;
p.caloutputs    = 2;
p.keyword       = 'osc';
p.tooltip       = 'Orthogonal Signal Correction clutter removal';
p.category      = 'Filtering';

if isempty(p.userdata);
  p.userdata    = [1 0 99.9];          %defaults
end

% --------------------------------------------------------------------
function  components_Callback(h, eventdata, handles, varargin)
val = str2num(get(handles.components,'string'));
if isempty(val) & length(val)>1; val = 0; end
if val == 0; val = 1; end;
set(handles.components,'string',num2str(val));

% --------------------------------------------------------------------
function  iterations_Callback(h, eventdata, handles, varargin)
val = str2num(get(h,'string'));
if isempty(val) & length(val)>1; val = 0; end
if val < 0; val = 0; end;
val = round(val);
set(h,'string',num2str(val));

% --------------------------------------------------------------------
function  tolerance_Callback(h, eventdata, handles, varargin)
val = str2num(get(h,'string'));
if isempty(val) & length(val)>1; val = 0; end
if val <= 0;  val = 99.9; end;
if val > 100; val = 100; end;
set(h,'string',num2str(val));
