function varargout = gscaleset(varargin)
%GSCALESET GUI used to modfiy settings for gscale.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided
% if p is 'default', default structure is returned without GUI
%
%I/O:   p = gscaleset(p)
% (or)  p = gscaleset('default')
%
%See also: GSCALE, PREPROCESS

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
% JMS 8/26/2002

if nargin == 0  | (nargin == 1 & isa(varargin{1},'struct'))% LAUNCH GUI

	fig = openfig(mfilename,'reuse');
  set(fig,'WindowStyle','modal');
  centerfigure(fig,gcbf);
  setappdata(fig,'parentfig',gcbf);

	% Generate a structure of handles to pass to callbacks, and store it. 
  handles = guihandles(fig);
  if ismac
    %Temp solution for guide differences in Mac.
    set(handles.numblockslabel,'backgroundcolor',get(0,'defaultUicontrolBackgroundColor'));
  end
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
    elseif ~isempty(varargin)
      varargout{1} = varargin{1};%return 
    else
      varargout{1} = [];
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
function  numblocks_Callback(h, eventdata, handles, varargin)
% Stub for Callback of the uicontrol handles.numblocks.

nb = get(handles.numblocks,'string');
nb = str2double(nb);
nb = round(nb);
if isempty(nb) | ~isfinite(nb); nb = getappdata(handles.numblocks,'oldval'); end

if nb<0;
  %get class set on variables of dataset. If invalid reset to nb=0
  dso = getappdata(handles.gscaleset,'dataset');
  nbn = -nb;
  if ~isempty(dso) & isdataset(dso)
    if (size(dso.class,2)< nbn | isempty(dso.class{2,nbn}))
      evrierrordlg(sprintf('Class set #%d is invalid for this DataSet', nbn));
      nb = getappdata(handles.numblocks,'oldval');
    end
  end
end

if nb<0
  %good class set - update classset menu too
  set(handles.classset,'value',abs(nb)+1)
  bgcolor = get(handles.gscaleset,'color');
else
  %no class
  set(handles.classset,'value',1)
  bgcolor = [1 1 1];
end

set(handles.numblocks,'string',num2str(nb),'backgroundcolor',bgcolor);
setappdata(handles.numblocks,'oldval',nb);
if nb>=0
  setappdata(handles.numblocks,'lastnonclass',nb)
end

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

fig = handles.gscaleset;

%store p for modification when done
setappdata(fig,'settings',p)

%resize as needed for font size
fs = getdefaultfontsize('normal');
scl = fs/10;
remapfig([0 0 1 1],[0 0 scl scl],fig)
set(allchild(fig),'fontsize',fs)
pos = get(fig,'position');
set(fig,'position',pos.*[1 1 scl scl]-[pos(3:4)*(scl-1) 0 0]);

%get parent data
pfig = getappdata(fig,'parentfig');
if isempty(pfig)
  pdata = [];
elseif strcmpi(get(pfig,'tag'),'analysis')
  pdata = analysis('getobjdata','xblock',guidata(pfig));
else
  pdata = preprocess('getdataset',pfig);
end
setappdata(fig,'dataset',pdata);

if p.userdata.numblocks<0
  classset = abs(p.userdata.numblocks);
else
  classset = 0;
end

set(handles.classset,'string',{''},'enable','off','value',1); %default is turned off
if ~isempty(pdata)
  classes = pdata.class(2,:);
  classnames = pdata.classname(2,:);
  found = ~cellfun('isempty',classes);
  if any(found)
    for j=1:length(found);
      if ~found(j)
        classnames{j} = '(empty)';
      else
        if length(classnames)<j | isempty(classnames{j})
          classnames{j} = sprintf('Set #%i',j);
        end
      end
    end
    classnames = [{''} classnames];
    set(handles.classset,'string',classnames,'value',classset+1,'enable','on')
    setappdata(handles.classset,'found',found);
  end
end

%set up GUI based on decoded structure
nb = p.userdata.numblocks;
set(handles.numblocks,'string',num2str(nb));
setappdata(handles.numblocks,'oldval',nb);
if nb>=0
  setappdata(handles.numblocks,'lastnonclass',nb)
else
  setappdata(handles.numblocks,'lastnonclass',1)
end
numblocks_Callback(handles.numblocks,[],handles);

set(handles.centeringcb,'value',p.userdata.center);



% --------------------------------------------------------------------
function p = encode(handles)
% encode the GUI's settings into the Preprocessing structure

p = getappdata(handles.gscaleset,'settings');

p.userdata.numblocks = str2num(get(handles.numblocks,'string'));    
p.userdata.center    = get(handles.centeringcb,'value');

if p.userdata.numblocks >= 0
  p.description = sprintf('%s (Number of blocks = %#d', p.description, p.userdata.numblocks);
else
  cset = -p.userdata.numblocks;
  p.description = sprintf('%s (Using Class Set #%#d', p.description, cset);
end

if ~p.userdata.center
  p.description = [p.description ', No Centering)'];
else
  p.description = [p.description ', With Centering)'];
end

% --------------------------------------------------------------------
function p = default(p)
%  pass back the default structure for this preprocessing method
% if "p" is passed in, only the userdata from that structure is kept

if nargin<1 | isempty(p);
  p = preprocess('validate');    %get a blank structure
end

p = preprocess('validate',p);  %validate what was passed in

p.description   = 'Group Scale';
p.calibrate     = { '[data,out{1},out{2}] = gscale(data,userdata.numblocks,userdata.center);' };
p.apply         = { 'data = gscaler(data,userdata.numblocks,out{1},out{2});' };
p.undo          = { 'data = gscaler(data,userdata.numblocks,out{1},out{2},1);' };
p.out           = {};
p.settingsgui   = 'gscaleset';
p.settingsonadd = 0;
p.usesdataset   = 1;
p.caloutputs    = 2;
p.keyword       = 'gscale';
p.tooltip       = 'Scale groups of variables to grand variance and optional mean center';
p.category      = 'Scaling and Centering';

defaultud = struct('numblocks',1,'center',1);
if isempty(p.userdata);
  %nothing, create default
  p.userdata = defaultud;
elseif ~isstruct(p.userdata)
  %old non-structure, move into fields
  p.userdata = struct('numblocks',p.userdata,'center',1);
else
  %got a structure - assure it has all fields
  p.userdata = reconopts(p.userdata,defaultud);
end

%-------------------------------------------------------------------
function linkwithfunctions
%placeholder function - this is just so that we'll make sure the compiler
%includes these functions when compileing

gscale
gscaler


% --- Executes on button press in centeringcb.
function centeringcb_Callback(hObject, eventdata, handles)
% hObject    handle to centeringcb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of centeringcb


% --- Executes on selection change in classset.
function classset_Callback(hObject, eventdata, handles)
% hObject    handle to classset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns classset contents as cell array
%        contents{get(hObject,'Value')} returns selected item from classset

nb = get(handles.classset,'value')-1;
if nb==0
  nb = getappdata(handles.numblocks,'lastnonclass');
else
  nb = num2str(-nb);
end
set(handles.numblocks,'string',nb);
numblocks_Callback(handles.numblocks,[],handles);


% --- Executes during object creation, after setting all properties.
function classset_CreateFcn(hObject, eventdata, handles)
% hObject    handle to classset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
