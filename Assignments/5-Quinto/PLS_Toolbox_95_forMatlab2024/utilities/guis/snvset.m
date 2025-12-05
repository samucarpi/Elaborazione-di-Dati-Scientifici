function varargout = snvset(varargin)
%SNVSET GUI used to modfiy settings of SNV.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI
%
%I/O:   p = snvset(p)
% (or)  p = snvset('default')
%
%See also: SNV, PREPROCESS

%Copyright Eigenvector Research 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 8/3/2001
% 8/15/01 JMS fixed intro code to remove R10 warnings, corrected help
% 9/18/01 JMS rewrote from normset for detrend
% 9/18/01 JMS rewrote from detrendset for auto
% 9/18/01 JMS rewrote from autoset for snv

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

%store p for modification when done
setappdata(handles.settingsfigure,'settings',p)

% --------------------------------------------------------------------
function p = encode(handles)
% encode the GUI's settings into the Preprocessing structure
% This routine must take the current GUI object settings and "encode" them
%  into the userdata property (as well as any other structure changes)

p          = getappdata(handles.settingsfigure,'settings');
p.userdata = struct('offset',str2num(get(handles.offset,'string')));

p.description = sprintf('%s (scale offset = %#.3g)', p.description, p.userdata.offset);

% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
end
         
p = preprocess('validate',p);  %validate what was passed in
  
p.description   = 'SNV';
p.calibrate     = {'[data,out{1},out{2}] = snv(data,userdata);'};
p.apply         = {'[data,out{1},out{2}] = snv(data,userdata);'};
p.undo          = {'data = snv(data,out{1},out{2});'};
p.out           = {};
p.settingsgui   = 'snvset';
p.settingsonadd = 0;
p.usesdataset   = 0;
p.caloutputs    = 0;
p.tooltip       = 'Standard Normal Variate scaling of samples (weighted normalization)';
p.category      = 'Normalization';

if isempty(p.userdata)
  p.userdata    = struct('offset',0);          %defaults
end
if ~isstruct(p.userdata);
  p.userdata = struct('offset',p.userdata);
end


% --------------------------------------------------------------------
function offset_Callback(h, eventdata, handles, varargin)

val = str2num(get(handles.offset,'string'));
if isempty(val); val = 0; end
set(handles.offset,'string',num2str(val));
