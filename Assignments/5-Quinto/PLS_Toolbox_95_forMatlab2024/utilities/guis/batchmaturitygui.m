function varargout = batchmaturitygui(varargin)
% BATCHMATURITYGUI MATLAB code for batchmaturitygui.fig.

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~isempty(varargin) && ischar(varargin{1})
  if ismember(varargin{1},evriio([],'validtopics'));
    options = [];
    if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return;
  end

  if nargout
    [varargout{1:nargout}] = feval(varargin{:});
  else
    feval(varargin{:});
  end
else
  fig = openfig(mfilename,'new');

  if nargout > 0;
    varargout = {fig};
  end
end


% --------------------------------------------------------------------
function batchmaturitygui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to batchmaturitygui (see VARARGIN)

% Choose default command line output for batchmaturitygui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes batchmaturitygui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --------------------------------------------------------------------
function varargout = batchmaturitygui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



% --------------------------------------------------------------------
function bmpcedit_Callback(hObject, eventdata, handles)
%Update PCs like edit of PCs box or click on table.

%Update handles.
handles = guihandles(handles.analysis);

mypcs = get(handles.bmpcedit,'String');
set(handles.pcsedit,'string',mypcs);

batchmaturity_guifcn('pcsedit_Callback',handles.pcsedit, [], handles)

switch getappdata(handles.analysis,'statmodl')
  case 'calold'
    setappdata(handles.analysis,'statmodl','calnew');
end
analysis('updatestatusboxes',handles);
analysis('toolbarupdate',handles)  %set buttons

% --------------------------------------------------------------------
function bmlvedit_Callback(hObject, eventdata, handles)
%Number of LVs changed.

switch getappdata(handles.analysis,'statmodl')
  case 'calold'
    setappdata(handles.analysis,'statmodl','calnew');
end
analysis('updatestatusboxes',handles);
analysis('toolbarupdate',handles)  %set buttons

% --------------------------------------------------------------------
function panelinitialize_Callback(figh, frameh, varargin)
%Initialize panel objects.

handles = guihandles(figh);
%myctrls = findobj(figh,'userdata','batchmaturitygui');

if ispc
  myfontsize = 10;
else
  myfontsize = 12;
end
mycolor = get(frameh,'BackgroundColor');

lbs = [handles.bmpclabel handles.bmlvlabel handles.bmcllabel handles.bmsplabel];
eds = [handles.bmpcedit handles.bmlvedit handles.bmcledit handles.bmspedit];
set(lbs,'BackgroundColor',mycolor,'FontSize',myfontsize)
set(eds,'BackgroundColor','white','FontSize',myfontsize)
set(handles.helpbtn,'FontSize',myfontsize)

panelupdate_Callback(figh, frameh, varargin)

bmpcedit_Callback(handles.bmpclabel, [], handles)

% --------------------------------------------------------------------
function  panelupdate_Callback(figh, frameh, varargin)

%Update panel objects.
handles = guihandles(figh);

opts = getappdata(handles.analysis, 'analysisoptions');
if isempty(opts)
  %Options were cleared so add them again.
  batchmaturity_guifcn('getoptions',handles);
  opts = getappdata(handles.analysis,'analysisoptions');
end

set(handles.bmcledit,'string',num2str(opts.cl));
set(handles.bmspedit,'string',num2str(opts.smoothing));

% --------------------------------------------------------------------
function panelresize_Callback(figh, frameh, varargin)
% Resize specific to panel manager. figh is parent figure, frameh is frame
% handle.

handles = guihandles(figh);


%Move rest of controls to upper left of frame.
frmpos = get(frameh,'position');%[left bottom width height]

txtpos = get(handles.bmpclabel,'position');
txtpos(3) = 140;
newbottom = (frmpos(2)+frmpos(4)-(txtpos(4)+8));

set(handles.bmpclabel,'position',[8 newbottom txtpos(3) txtpos(4)]);
set(handles.bmpcedit,'position',[16+txtpos(3) newbottom txtpos(3) 24]);

newbottom = newbottom -28;

set(handles.bmlvlabel,'position',[8 newbottom txtpos(3) txtpos(4)]);
set(handles.bmlvedit,'position',[16+txtpos(3) newbottom txtpos(3) 24]);

newbottom = newbottom -36;

set(handles.bmcllabel,'position',[8 newbottom txtpos(3) txtpos(4)]);
set(handles.bmcledit,'position',[16+txtpos(3) newbottom txtpos(3) 24]);

newbottom = newbottom -28;

set(handles.bmsplabel,'position',[8 newbottom txtpos(3) txtpos(4)]);
set(handles.bmspedit,'position',[16+txtpos(3) newbottom txtpos(3) 24]);

newbottom = newbottom -36;

set(handles.helpbtn,'position',[56+txtpos(3) newbottom 100 24])

% --------------------------------------------------------------------
function bmcledit_Callback(hObject, eventdata, handles)
%Confidence level change.
persistent invalidclwarning

handles = guihandles(handles.analysis);

opts = batchmaturity_guifcn('getoptions',handles);
myval = str2num(get(handles.bmcledit,'string'));
if myval<0 | myval>1
  set(handles.bmcledit,'string',num2str(opts.cl));
  if isempty(invalidclwarning)
    evriwarndlg('Invalid setting for Confidence Limit (must be >0 and <1).','Invalid Confidence Limit');
    invalidclwarning = true;
  end
  return;
end
if opts.cl == myval
  return
else
  opts.cl = myval;
end

setopts(handles,opts)

% --------------------------------------------------------------------
function setopts(handles,opts)
%Set options to appdata.

analysis('setopts',handles,lower(getappdata(handles.analysis,'curanal')),opts);
analysis('clearmodel',handles.analysis, [], handles, []);

% --------------------------------------------------------------------
function bmspedit_Callback(hObject, eventdata, handles)
% "smoothing" parameter.
handles = guihandles(handles.analysis);
opts = getappdata(handles.analysis, 'analysisoptions');

myval = str2num(get(handles.bmspedit,'string'));

% smoothing parameter must be 0 <= smoothing <= 0.5
if myval<0 | myval>0.5
  set(handles.bmspedit,'string',num2str(opts.smoothing))
  return;
end
if opts.smoothing == myval
  return
else
  opts.smoothing = myval;
end

setopts(handles,opts)

% --------------------------------------------------------------------
function helpbtn_Callback(hObject, eventdata, handles)
% Open help page.

evrihelp('batchmaturity')

%------------------------------------------------------------------
function panelblur_Callback(varargin)
