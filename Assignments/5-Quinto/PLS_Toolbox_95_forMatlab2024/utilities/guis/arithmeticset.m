function varargout = arithmeticset(varargin)
%ARITHMETICSET Settings used to modfiy arithmetic operations.
% Both input (p) and output (p) are preprocessing structures
% If no input is supplied, GUI with default settings is provided.
% if p is 'default', default structure is returned without GUI.
%
%
%I/O:   p = arithmeticset
%I/O:   p = arithmeticset(p)
%
%See also: ARITHMETIC, PREPROCESS

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
    btn_cancel_Callback(fig, [], handles)
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

set(findobj(handles.arithmeticset,'type','uicontrol'),'fontsize',getdefaultfontsize)

p = getappdata(handles.arithmeticset,'settings');
p = default(p);

mylist = arithmetic('list');
thislist = cell2str(mylist,'  ');
thislist = strvcat(thislist(1:end-1,:),'Select Type');

myval = find(ismember(mylist,p.userdata.operation));
set(handles.popupmenu1,'string',thislist,'value',myval,'fontname','Courier');
%Add constant.
set(handles.edit1,'string',num2str(p.userdata.constant));

%Add indices.
inds = p.userdata.indices;
if ~isempty(inds)
  if iscell(inds)
    inds = inds{1};
  end
  eopts.includeclear = 'off';
  istr = encode(inds,'',eopts);
  set(handles.edit2,'string',istr)
end
setappdata(handles.arithmeticset,'settings',p)
setappdata(handles.arithmeticset,'window',inds);
update_selectedwindow(handles)

%-------------------------------------------------------------
function btn_ok_Callback(hObject, eventdata, handles)
%Ok button callback.
uiresume(handles.arithmeticset);

%-------------------------------------------------------------
function btn_help_Callback(hObject, eventdata, handles)
%Show help.

evrihelp('Arithmetic_Settings');

%-------------------------------------------------------------
function btn_cancel_Callback(hObject, eventdata, handles)
%Cancel.

if ishandle(handles.arithmeticset)
  pgfig = getappdata(handles.arithmeticset,'pgfigure');
  if ~isempty(pgfig) & ishandle(pgfig)
    %If user cancels out of Arithmetic gui without closing PG then do it
    %now.
    close(pgfig)
  end
  close(handles.arithmeticset)
end

%--------------------------------------------------------------------
function p = encode_settings(handles)
% encode the GUI's settings into the Preprocessing structure
% This routine must take the current GUI object settings and "encode" them
%  into the userdata property (as well as any other structure changes)

p  = getappdata(handles.arithmeticset,'settings');

%Get operation.
mylist = arithmetic('list');
myval = get(handles.popupmenu1,'value');
myop = mylist{myval,1};
p.userdata.operation = myop;

%Get constant.
myconst = str2num(get(handles.edit1,'string'));
p.userdata.constant = myconst;

%Get indices.
p.userdata.indices = getappdata(handles.arithmeticset,'window');

%Mode is always 2 for this interface.
p.userdata.modes = 2;

s = regexprep(mylist{myval,2},'c',sprintf('%g',myconst));
p.description = sprintf('%s: %s ',mylist{myval,1},s);

%--------------------------------------------------------------------
function pd = default(p)
%Create default structure for this preprocessing method if "p" is passed
%in, only the userdata from that structure is kept.

pd = arithmetic('default');

if nargin>0 & ~isempty(p);
  %Copy over userdata.
  pd.userdata = p.userdata;
end

%--------------------------------------------------------------------
function selectbtn_Callback(hObject, eventdata, handles)
% hObject    handle to selectbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dat = preprocess('getdataset',getappdata(handles.arithmeticset,'parentfig'));

win = str2num(get(handles.edit2,'string'));
if isempty(dat)
  sel = inputdlg({'Window Indices:'},'Select window',1,{encode(win,'')});
  win = str2num(sel{1});
else
  %we've got data, share it and allow plotgui to modify the include field
  evritip('arithmeticsetselect','Use Include and Exclude to indicate region which should be used for arithmetic operation (only included region will be used).',1)
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
  myid = setshareddata(handles.arithmeticset,dat);  
  fig = plotgui('new',myid,...
  'plotby',0,...
  'viewclasses',1,...
  'selectionmode','xs',...
  'pgtoolbar',0,...
  'viewexcludeddata',1);

  toolbar(fig,'',btnlist,'selectiontoolbar');
  
  %Set menu to variables.
  %setappdata(fig,'axismenuindex',{1 2 0})
  %setappdata(fig,'axismenuvalues',{1 2 0});
  %plotgui('update');
  plotgui('update','axismenuindex',{1 2 0},'axismenuvalues',{1 2 0});
  
  setappdata(handles.arithmeticset,'pgfigure',fig);%Save so we can close figure if user cancels out of arithmetic window.
  
  while ishandle(fig)
    uiwait(fig);
  end

  %get include field after figure is closed
  dat = myid.object;
  if isempty(dat)
    %Data is no longer available, user may of canceled.
    return
  end
  
  win = dat.include{2};
  if length(win)==size(dat,2);
    %everything selected? interpret as empty
    win = [];
  end
  removeshareddata(myid);
end

setappdata(handles.arithmeticset,'window',win);
update_selectedwindow(handles)

%---------------------------------------------
function update_selectedwindow(handles)

win = getappdata(handles.arithmeticset,'window');
if isempty(win);
  win = '(all variables)';
else
  win = encode(win,'');
end
set(handles.edit2,'string',win);

%---------------------------------------------
function edit2_Callback(hObject, eventdata, handles)
% Edit of variable range.

win = str2num(get(handles.edit2,'string'));
setappdata(handles.arithmeticset,'window',win);

update_selectedwindow(handles)
