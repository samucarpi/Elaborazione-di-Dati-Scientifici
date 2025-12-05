function varargout = optionsgui(varargin)
% OPTIONSGUI creates options gui for specified function.
%  Input 'fname' is the name of a function from which to extract
%  preferences structure OR options structure (values will be defaults).
%  See prefobjplace.m for more details.
%
%  Optional structure input (options) can contain any of the fields:
%        userlevel : [ 'novice' | 'intermediate' | 'advanced'] default user
%                    level of interface.
%          disable : [{}] cell of stings with options names to disable in GUI.
%           remove : [{}] cell of stings with options names to remove in GUI.
%
%I/O: opts = optionsgui(fname)
%I/O: opts = optionsgui(fname, options)
%
%See also PREFOBJCB, PREFOBJPLACE

%Copyright Eigenvector Research 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.
%rsk 10/31/05
%rsk 12/02/05 -BUILDOPTIONS functionality moved to optionsgui.
%rsk 01/26/06 - Better error handling if no defs found.
%             - Add delete to cancel/close so Ctrl-C out of modal will work.
%rsk 05/09/06 Add waitbar and pointer indicators.

varargout = {};

persistent useold
if isempty(useold)
  useold = getplspref('optionsgui','use_old_gui');
  if isempty(useold); useold = 0; end
end


if nargin == 0
  error('OPTIONSGUI needs at least one input.')
  return
elseif ischar(varargin{1}) | isstruct(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
  if strcmp(getappdata(0,'debug'),'on');
    dbstop if all error
  end

  try
    if ischar(varargin{1})
      switch lower(varargin{1})
        case evriio([],'validtopics')
          options = defaultoptions;
          if nargout==0
            evriio(mfilename,varargin{1},options)
          else
            varargout{1} = evriio(mfilename,varargin{1},options);
          end
          return;
        otherwise
          %Call as intialize or subfunction. Can't use 'which' function to
          %distinguish input (gui call vs function call) becuase doen't
          %work well when pcoded, so need to use convention that nargin > 2
          %is function call.
          if nargin > 2
            if nargout == 0;
              %normal calls with a function
              feval(varargin{:}); % FEVAL switchyard
            else
              [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
            end
          else
            %No subfunction located so input must be original call and not a
            %subfunction.
            if checkmlversion('<','7.7') | useold %Less than matlab 2008b
              varargout{1} = guirun(varargin{:});
            else
              varargout{1} = optionseditor(varargin{:});
            end
          end
      end
    else
      %Inpute is structure and should be passed to guirun.
      if checkmlversion('<','7.7') | useold %Less than matlab 2008b
        varargout{1} = guirun(varargin{:});
      else
        varargout{1} = optionseditor(varargin{:});
      end
    end
  catch
    erdlgpls(lasterr,[upper(mfilename) ' Error']);
  end

end


%FUNCTIONS/CALLBACKS
%------------------------------------------------------
%Define default property values (may be superseeded by setplspref values)
function default = defaultoptions;
default = [];
default.userlevel = 'intermediate';
default.disable   = '';
default.remove    = '';
default.use_old_gui = false;

% --------------------------------------------------------------------
function opts = guirun(varargin)

wbarh = waitbar(.1,'Intializing Options...');

fname = varargin{1};

fig = openfig(mfilename,'new');
set(fig,'closerequestfcn',['try;' get(fig,'closerequestfcn') ';catch;delete(gcbf);end'])

%Verify that fname has definitions.
if ischar(fname)
  tempopts = feval(fname, 'options');
  if ~isfield(tempopts,'definitions')
    if exist('fig') & ishandle(fig)
      delete(fig)
    end
    erdlgpls(['No definitions field found in options structure for (' fname ').'],[upper(mfilename) ' Error']);
    opts=[];
    close(wbarh)
    return
  end
elseif isstruct(fname) & ~isfield(fname,'definitions')
  if exist('fig') & ishandle(fig)
    delete(fig)
  end
  erdlgpls(['No definitions field found in options structure.'],[upper(mfilename) ' Error']);
  opts=[];
  close(wbarh)
  return
end

waitbar(.5,wbarh);

if nargin < 2
  options = optionsgui('options');
  %NOTE: options must be subset of prefobjplace, it's passed straight to
  %prefobjplace.
else
  options = varargin{2};
end
options = reconopts(options,mfilename);

set(fig,'name','Options / Preferences')
positionmanager(fig,'optionsgui');%Position gui from last known position.

%Change diplay column header for R13.
if checkmlversion('<','7')
  set(findobj(fig,'tag','text4'),'String','Description [right-click to display above]');
end

handles = guihandles(fig);	%structure of handles to pass to callbacks
guidata(fig, handles);      %store it.
gui_init(fig)            %add additional fields
set(fig,'visible','on')

if isprop(fig,'WindowScrollWheelFcn')
  set(fig,'WindowScrollWheelFcn',@scrollWheelCallback)
end

figure(wbarh)
waitbar(.7,wbarh);

if ~isempty(fname)
  try
    prefobjplace(fig,fname,'all',options)
  catch
    error(lasterr)
  end
end
figure(wbarh)
waitbar(1,wbarh);
close(wbarh)
pause(.1);%Need to let waitbar close, seems to not get deleted in 2011a because uiwait gets called too fast.

try
  uiwait(fig); %uiresume called in optionsgui.m
catch
  uiresume(fig)
end

if ishandle(fig)
  handles = guihandles(fig);
  %Save figure position.
  positionmanager(fig,'optionsgui','set') 
else
  handles = [];
end

if ~isempty(handles) & ishandle(handles.optionsgui)
  if nargout > 0 & ishandle(handles.optionsgui)
    opts = getappdata(handles.optionsgui,'newopts');
    dfh = getappdata(handles.optionsgui,'defhandle');
    if ~isempty(opts) & ~isempty(dfh)
      opts.definitions = dfh;
    end
  end
  delete(handles.optionsgui)
else
  opts = [];
end

% if nargout == 0
clear fig         %if no outputs clear fig handle
% elseif nargout > 0
%   varargout{1} = fig;
% end
% --------------------------------------------------------------------
function gui_init(h)
handles = guihandles(h);

%Make File menu invisible.
set(handles.filemenu,'visible','off')

%Make sure background of help display is white, uses system gray on Mac.
set(handles.display_help,'background','white');
%set(handles.optionsframe,'backgroundcolor',get(h,'color'))
%set(handles.frame3,'backgroundcolor',get(h,'color'))
%set(handles.buttonframe,'backgroundcolor',get(h,'color'))

%Set slider value to one and disable.
set(handles.optionsslider,'value',1,'enable','off');
updatefunction(handles); %add function name to function drop down menu.

% --- Outputs from this function are returned to the command line.
function varargout = optionsgui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function functionpopupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to functionpopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
  set(hObject,'BackgroundColor','white');
else
  set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --------------------------------------------------------------------
function functionpopupmenu_Callback(hObject, eventdata, handles)



% --------------------------------------------------------------------
function filemenu_Callback(hObject, eventdata, handles)



% --------------------------------------------------------------------
function togglebutton_Callback(hObject, eventdata, handles)
%Tab toggle button callback.
sliderreset(handles);
if ischar(hObject) & strcmp(hObject,'userlevel')
  %Called from userlevel callback.
  %New userlevel already set prior.
  hObject = findobj(handles.optionsgui,'tag','allbutton');
end

bstring = get(hObject,'String');%String will be tab, is extracted from option definitions in preobjplace.m.
allbtns = findobj(handles.optionsgui,'userdata','tabbutton');%Userdata set in preobjplace.m and fig file.
allbtns = setxor(hObject, allbtns);%Everything accept current object.
set(allbtns, 'value',0); %Set all other buttons to 'up' position.
set(hObject,'value',1); %Reset button down.

if strcmp(bstring,'All')
  %Display all options for userlevel.
  remapopts(handles,getappdata(handles.optionsgui,'userlevel'));
else
  %Display tab for userlevel.
  remapopts(handles,bstring);
end
resetgui(handles)

% --------------------------------------------------------------------
function okbutton_Callback(hObject, eventdata, handles)

uiresume(handles.optionsgui)

% --------------------------------------------------------------------
function cancelbutton_Callback(hObject, eventdata, handles)

if isempty(handles)
  handles = guihandles(hObject);
end

%Save figure position.
positionmanager(handles.optionsgui,'optionsgui','set') 

setappdata(handles.optionsgui,'newopts',[]);
uiresume(handles.optionsgui)

if ishandle(handles.optionsgui)
  delete(handles.optionsgui)
end
% --------------------------------------------------------------------
function resetbutton_Callback(hObject, eventdata, handles)
%Reset button callback.

try
  set(handles.optionsgui,'pointer','watch')
  drawnow
  bt = findobj(handles.optionsgui,'Userdata','optctrl');

  %Find tobble buttons to be deleted (do not delete the allbutton).
  tglbt = setxor(findobj(handles.optionsgui, 'tag','allbutton'),findobj(handles.optionsgui,'userdata','tabbutton'));
  bt = [bt;tglbt];

  initstruct  = getappdata(handles.optionsgui,'initialopts');
  initprflist = getappdata(handles.optionsgui,'inipreflist');
  initopts    = getappdata(handles.optionsgui,'inioptions');
  if isempty(initopts)
    %No options loaded.
    return
  end

  %Find tab button pushed so can return.
  allbtns = findobj(handles.optionsgui,'userdata','tabbutton');
  curbtn = findobj(allbtns,'value',1);
  curbtntag = get(curbtn,'tag');

  delete(bt);
  prefobjplace(handles.optionsgui,initstruct,initprflist,initopts);

  if ~isempty(curbtn)
    curbtn = findobj(handles.optionsgui,'tag',curbtntag);
    togglebutton_Callback(curbtn, [], handles)
  end

  resetgui(handles)
  resize_callback(handles.optionsgui,[],handles)
  set(handles.optionsgui,'pointer','arrow')
catch
  set(handles.optionsgui,'pointer','arrow')
end
% --------------------------------------------------------------------
function novicemenu_Callback(hObject, eventdata, handles)
userlevel = 'novice';
setappdata(handles.optionsgui,'userlevel',userlevel);
setplspref('optionsgui','userlevel',userlevel);
menuset(hObject, eventdata, handles)

% --------------------------------------------------------------------
function intermediatemenu_Callback(hObject, eventdata, handles)
userlevel = 'intermediate';
setappdata(handles.optionsgui,'userlevel',userlevel);
setplspref('optionsgui','userlevel',userlevel);
menuset(hObject, eventdata, handles)

% --------------------------------------------------------------------
function advancedmenu_Callback(hObject, eventdata, handles)
userlevel = 'advanced';
setappdata(handles.optionsgui,'userlevel',userlevel);
setplspref('optionsgui','userlevel',userlevel);
menuset(hObject, eventdata, handles)

% --------------------------------------------------------------------
function menuset(hObject, eventdata, handles)
ul = lower(getappdata(handles.optionsgui,'userlevel'));
if isempty(ul)
  ul = 'novice';
end
hObject = findobj(handles.optionsgui,'tag',[ul 'menu']);

set(get(get(hObject,'parent'),'children'),'checked','off');
set(hObject,'Checked','on');

togglebutton_Callback('userlevel', eventdata, handles);

%Enable/Disable Tab buttons based on tab.
list = btnlist(handles,ul,1);%Get list of buttons that should be enabled.
list = [list {'allbutton'}]; %Add all button to list becuase it always should be enabled.
mybtnlist = findobj(handles.optionsgui,'userdata','tabbutton');
bnames = get(mybtnlist,'tag');
bnames = strrep(bnames,'tab_','');%Remove prefix.
bloc = ismember(bnames,list);%Get logical index.

set(mybtnlist(bloc),'enable','on')
set(mybtnlist(~bloc),'enable','off')

% --------------------------------------------------------------------
function userlevelmenu_Callback(hObject, eventdata, handles)

% --------------------------------------------------------------------
function allbutton_Callback(hObject, eventdata, handles)
remapopts(handles,getappdata(handles.optionsgui,'userlevel')); %Display all options.

% --------------------------------------------------------------------
function display_help_CreateFcn(hObject, eventdata, handles)

set(hObject,'BackgroundColor','white');

% --------------------------------------------------------------------
function display_help_Callback(handles)
dh = findobj(handles.optionsgui, 'tag', 'display_help');
set(dh,'String', 'Description');
% --------------------------------------------------------------------
function updategui(handles,varargin)
togglebutton_Callback('userlevel', [], handles);
resetgui(handles,varargin);
% --------------------------------------------------------------------
function resetgui(handles,varargin)
display_help_Callback(handles); %reset help.
updatefunction(handles); %reset function name.

% --- Executes during object creation, after setting all properties.
function optionsslider_CreateFcn(hObject, eventdata, handles)

usewhitebg = 1;
if usewhitebg
  set(hObject,'BackgroundColor',[.9 .9 .9]);
else
  set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on slider movement.
function optionsslider_Callback(hObject, eventdata, handles)

h = findobj(gcbf,'userdata','optctrl');
figh = gcbf;
if isempty(gcbf)
  figh = handles.optionsgui;
end
pnow = getappdata(figh,'pnow');
if isempty(pnow);
  pnow = 1;
end
val = 2-get(hObject,'value');

remapfig([1 pnow 1 1],[1 val 1 1],gcbf,h);

setappdata(figh,'pnow',val);
isvisible(handles);

% -------------------------------------------------------------------.
function sliderreset(handles)
set(handles.optionsslider,'value',1);
optionsslider_Callback(handles.optionsslider, [], handles);

% -------------------------------------------------------------------
function hlist = getoptsh(h)

srch = {'val_*', 'disp_*', 'description_*' 'label_*'};
hlist = [];
for i = srch
  hlist = [hlist; findobj(h,'-regexp','tag',i{:})];
end


% -------------------------------------------------------------------
function slidersetup(handles,varargin)
%Set the minimum value of the slider. Disable if controls don't reach
%bottom.

hbtns = findbtns(handles);%Get list of control handles.
if isempty(hbtns)
  set(handles.optionsslider,'enable','off')
else
  framepos = get(handles.optionsframe,'position');
  pos = get(hbtns,'position')';
  if ~iscell(pos)
    pos = {pos};
  end
  pos = [pos{:}];
  pos = reshape(pos,4,length(pos)/4)';
  sldrmin = 1-(framepos(2)-min(pos(:,2)))/framepos(4);

  scl = framepos(4)./(max(pos(:,2)+pos(:,4))-min(pos(:,2)));
  
  nrows = sum(pos(:,1)==min(pos(:,1)));
  nrows_visible = floor((nrows).*scl);
  sldrstp = [1./(1*nrows) (nrows_visible-1.5)./nrows];
  sldrstp = max(min(sldrstp,1),.001);
  
  set(handles.optionsslider,'value',1);
  if sldrmin>1
    set(handles.optionsslider,'enable','off')
  else
    set(handles.optionsslider,'min',sldrmin,'SliderStep',sldrstp);
    set(handles.optionsslider,'enable','on')
  end
end
isvisible(handles);
% -------------------------------------------------------------------
function isvisible(handles)
%Set visible property of controls in frame after slider step.
%hbtns = findobj(handles.optionsgui,'Userdata','optctrl');
hbtns = findbtns(handles);%Get list of control handles.
if isempty(hbtns)
  return
end
framepos = get(handles.optionsframe,'position');
bpos = get(hbtns,'position');%Button position.
if ~iscell(bpos)
  bpos = {bpos};
end
bpos = vertcat(bpos{:});
tbtns = hbtns(find(bpos(:,2)>framepos(2))');%get rid of ctrls that are below fig.
bbtns = hbtns(find(bpos(:,2)<framepos(2)+framepos(4)-27)'); %top of frame minus control height of 27 pixels.
%TODO: FIND VISIBLE CONTROLS

vbtns = intersect(tbtns,bbtns);
set(hbtns,'visible','off')
set(vbtns,'visible','on')

%Find buttons and displays so can change visibility as a pair.
btnlist = '';
btnlist = findobj(hbtns,'style', 'pushbutton');
for i = 1:length(btnlist)
  name = get(btnlist(i),'tag');
  name = name(strfind(name,'_')+1:end);%remove 'val_' from name.
  dispctrl = findobj(hbtns,'tag',['disp_' name]);
  if strcmp(get(dispctrl,'visible'),'off')
    set(btnlist(i),'visible','off');
  elseif strcmp(get(dispctrl,'visible'),'on')
    set(btnlist(i),'visible','on');
  end
end

% -------------------------------------------------------------------
function remapopts(handles, vlist)
%Displays 'vlist' subset of options in frame.
%Make all other controls visible = off but doesn't move them.
% vlist = cell array of stings containing names of options to be shown or

%List of all controls.
hctrls = findobj(handles.optionsgui,'Userdata','optctrl');
tctrls = get(hctrls,'tag'); %List of tag names.
set(hctrls,'units','pixels'); %Make sure units in pixels.
opts = getappdata(handles.optionsgui,'initialopts');

%Can't find any controls.
if isempty(hctrls)
  return
end

%Positions.
framepos = get(findobj(handles.optionsgui,'tag','optionsframe'), 'Position');
figpos   = get(handles.optionsgui,'Position');

%Change in position in pixels = height of control (27) plus separation (5).
curpos = framepos(2)+framepos(4)-29;

olist = '';%Orginal list, used to identify if list was keyword or cell array.
if ismember(vlist,{'advanced','intermediate','novice'})
  %If is member of user level then implies "All" tab is being used.
  usetab = 1;
else
  usetab = 0;
end

if ischar(vlist)
  olist = vlist;
  vlist = btnlist(handles,vlist);
end

%Get handles of controls that should be listed.
%vctrls cloumn 1 = handle, column 2 = row, column 3 = tab.
vctrls = [];
tablist = getappdata(handles.optionsgui,'tablist');

for i = 1:length(hctrls)
  %Reset visiblity to 0 (off).
  ad = getappdata(hctrls(i),'optinfo');
  ad.visible = 0;
  setappdata(hctrls(i), 'optinfo', ad);
  if isempty(vlist)
    continue
  end
  if usetab && ~isempty(strfind(ad.name,'_tabheader'))
    ad.visible = 1;
    setappdata(hctrls(i), 'optinfo', ad);
    continue
  end

  for j = 1:length(vlist)
    if strcmp(ad.name,vlist{j});%Each control in 'list' row will have 'name' in the tag.
      tnum = find(strcmp(ad.tab,tablist));%Get tab number.
      vctrls = [vctrls; hctrls(i) j tnum];
      ad.visible = 1;
      setappdata(hctrls(i), 'optinfo', ad);
    end
  end
end

set(hctrls,'visible','off');%Set all controls visible to off.

if ~isempty(vctrls)
  %Sort rows based on tabs if using "all".
  tabtag = strrep(tablist,' ','');
  %Including all tab numbers will cause tab headers with no items to appear
  %but with no controls listed. This is the designed behavior.
  tabnums = 1:length(tablist);
  
  %Test if header should be displayed.
  for j = tabnums
    rows = find(vctrls(:,3)==j);
    rows = unique(vctrls(rows,2));
    if ~isempty(olist) && usetab
      %Enable tab and move to correct position.
      tabh = findobj(hctrls,'tag',['tabheader_' tabtag{j}]);
      if isempty(rows)
        %No rows displayed under tab so turn visibility off.
        ad = getappdata(tabh,'optinfo');
        ad.visible = 0;
        setappdata(tabh, 'optinfo', ad);
        set(tabh,'visible','off');
      else
        mypos = get(tabh,'position');
        newpos = 1 + (curpos - mypos(2))/figpos(4);
        remapfig([1 1 1 1], [1 newpos 1 1],handles.optionsgui,tabh);
        set(tabh,'visible','on');
        curpos = curpos - 32;
      end
    end

    for i = 1:size(rows,1)
      %Remap rows (group) to new positions.
      group = vctrls(find(vctrls(:,2)==rows(i)));
      mypos = get(group(1),'position');
      newpos = 1 + (curpos - mypos(2))/figpos(4); %normalized change in distance.
      remapfig([1 1 1 1], [1 newpos 1 1],handles.optionsgui,group);
      set(group,'visible','on');
      curpos = curpos - 32;
    end
  end
end

slidersetup(handles)
isvisible(handles);

% -------------------------------------------------------------------
function indx = findbtns(handles)
%Returns index of controls that should be visible.
%Based on 'userlevel' and 'visible' setting for tabs.
%'visible' setting is set in remapopts.

bt = findobj(handles.optionsgui,'Userdata','optctrl');
indx = [];
ul = getappdata(handles.optionsgui,'userlevel');
for i = 1:length(bt)
  ad = getappdata(bt(i),'optinfo');
  if ad.visible
    if strcmp(ul, 'advanced')
      indx = [indx; bt(i)];
    elseif strcmp(ul, 'intermediate') & (strcmp(ad.userlevel,'intermediate') | strcmp(ad.userlevel,'novice'))
      indx = [indx; bt(i)];
    elseif strcmp(ul, 'novice') & strcmp(ad.userlevel,'novice')
      indx = [indx; bt(i)];
    end
  end
end

% -------------------------------------------------------------------
function list = btnlist(handles,keyword,returntab)
%Create a list of options based on keyword.
%Key word is a string of 'userlevel' or 'tab'.
%Input 'returntab' will return a list of tab names that are enabled.

if nargin<3
  returntab = 0;
end

opts  = getappdata(handles.optionsgui,'initialopts');
df    = opts.definitions;
vlist = {opts.definitions.name};

tabs = unique({opts.definitions.tab});
ul = unique({opts.definitions.userlevel});
currentul = getappdata(handles.optionsgui,'userlevel');

list = vlist(find(ismember({df.userlevel},'novice')))';
if strcmp(currentul,'intermediate')
  list = [list;vlist(find(ismember({df.userlevel},'intermediate')))'];
end
if strcmp(currentul,'advanced')
  list = vlist;
end

if returntab
  %Return list of tabs that associated with a userlevel.
  mytabs = {opts.definitions.tab};
  listloc = unique(find(ismember({df.name},list)));
  list = unique(mytabs(listloc));
  return
end

if ismember(keyword,tabs)
  klist = vlist(find(ismember({df.tab},keyword)))';
  list = intersect(list, klist);
  usingtab = 1;
end

% % if usingtab
% %   %Reorder list to reflect orginal order from definitions.
% %   list = vlist(find(ismember(vlist,list)))';
% % else
% %   %Reorder list based on tab.
% %   %Create sorted cell array of df.
% %   df = struct2cell(df)';
% %   dff = sortrows(df,2);
% %   %Use ismember to sort buildlist into tab sorted list.
% %   [junk, loc] = ismember(dff(:,1),list);
% %   loc = nonzeros(loc);
% %   list = df(loc,1);
% % end
list = vlist(find(ismember(vlist,list)))';
%Replace any cell data types with cell mode names.
cellinfo = getappdata(handles.optionsgui,'cellinfo');
if ~isempty(cellinfo)
  cellnames = unique({cellinfo.orgname});

  for i = 1:length(cellnames)
    pos1 = find(ismember(list,cellnames{i}));
    if isempty(pos1)
      continue
    end
    templist = '';
    for j = 1:length(cellinfo)
      if strcmp(cellinfo(j).orgname,cellnames{i})
        templist = [templist; {cellinfo(j).curname}];
      end
    end
    list = [list(1:pos1-1);templist;list(pos1+1:end)];
  end
end




% -------------------------------------------------------------------
function updatefunction(handles,keyword)
%Update function popup menu.
fname = getappdata(handles.optionsgui,'functionname');

if isempty(fname)
  fname = 'Function';
end

set(handles.functionpopupmenu, 'String', fname);

%-------------------------------------------------------------------
function linkwithfunctions
%placeholder function - this is just so that we'll make sure the compiler
%includes these functions when compiling

prefobjcb

%--------------------------------------------------------------
function resize_callback(h,eventdata,handles,varargin)

%Mac resize problem workaround.
handles = guihandles(h);
if ~ispc & checkmlversion('<','7.10')
  %Seems to be fixed in newer versions Matlab so don't run through this
  %code for 2010a and newer. This code causes problems in 2011b on Mac.
  count = 1;
  while 1
    figsize1 = get(handles.optionsgui,'Position');
    evripause(1);
    figsize2 = get(handles.optionsgui,'Position');
    if figsize1 == figsize2
      break
    elseif count == 100
      break
    end
    count = count + 1;
  end
end

optionsgui_resize(h,eventdata,handles,varargin)

%--------------------------------------------------------------
function optionsgui_resize(h,eventdata,handles,varargin)
%get current figure size/position
handles = guihandles(h);
set(handles.optionsgui,'units','pixels');
figpos = get(handles.optionsgui,'position');
oldsliderpos = get(handles.optionsslider,'value');
oldmin = get(handles.optionsslider,'min');
oldmax = get(handles.optionsslider,'max');

inioptions = getappdata(handles.optionsgui,'inioptions');
if isfield(inioptions,'allowsave') & strcmpi(inioptions.allowsave,'yes')
  saveoffset = 26;
else
  saveoffset = 0;
end

btfpos = get(handles.buttonframe,'position'); %Use button frame to determine position change.
heightchng = (figpos(4)-(6+btfpos(4))) - btfpos(2); %Find height change.

%Label always 30 from top.
setpos(handles.text5,'bottom',figpos(4)-30);
%All button always 50 from top.
setpos(handles.allbutton,'bottom',figpos(4)-50);

%Buttonframe height will be 200 or larger
bframeht = max([200 figpos(4)-11]);
setpos(handles.buttonframe,'height',bframeht)
setpos(handles.buttonframe,'top',figpos(4)-6)
%Buttonfram inlay is same minus 21.
bframeht = bframeht - 21;
setpos(handles.frame3,'height',bframeht)
setpos(handles.frame3,'top',figpos(4)-27)

%Reposition Tab buttons.
%Make visible 'off' if they're off the window so don't get on top of bottome edge of frame.
tablist = getappdata(handles.optionsgui,'tablist');
bh = findobj(handles.optionsgui,'userdata','tabbutton');

%First button should 'bottom' should be 75 from top.
btpos = figpos(4)-78; %Start position.
for j = tablist
  for i = bh'
    if strcmpi(get(i,'string'),j{:})
      setpos(i,'bottom',btpos)
      set(i,'visible','on')
      if figpos(4) > 211 && btpos < 6
        %The bottom of the button fram is showing but the row of buttons is
        %longer than the frame so turn visible off so a button doesn't
        %cover up the edge of the frame.
        set(i,'visible','off')
      end
      btpos = btpos - 21; %Button is 20 pixels high with 1 pixel spacing.
      continue
    end
  end
end

%Display help box should be 15% of window with min of 42 pixels high.
dispht = max([42 .15*figpos(4)]);
setpos(handles.display_help,'height',dispht)
setpos(handles.display_help,'top',figpos(4)-6)

%Set top of list headers 4 pixels from bottom of display help.
setpos(handles.optionname,'top',figpos(4)-(dispht+6+4))
setpos(handles.optionvalue,'top',figpos(4)-(dispht+6+4))
setpos(handles.text4,'top',figpos(4)-(dispht+6+4))

%Set top of options frame to 24 pixels from bottom of display help and 31
%pixesl from the bottom of the window.
optlistht = max([108 (figpos(4) - (dispht + 24 + 6 + 31))]);
setpos(handles.optionsframe,'height',optlistht)
setpos(handles.optionsframe,'top',figpos(4)-(dispht+24+6))
%Same for slider plus small margin (3 pixels on either end).
setpos(handles.optionsslider,'height',optlistht-6)
setpos(handles.optionsslider,'top',figpos(4)-(dispht+24+6+3))

%Controls that need to be moved.
mvctrls = {'okbutton' 'cancelbutton' 'resetbutton'};
for i = mvctrls
  if figpos(4) > 211
    setpos(handles.(i{:}),'bottom',4)
  else
    setpos(handles.(i{:}),'bottom',(figpos(4)-211)+4)
  end
end


%[left, bottom, width, height]
%Widths

if figpos(3) < 650
  %Limit of width is 650, spoof that size if smaller.
  %650 will keep the Description label from wrapping its text.
  figpos(3) = 650;
end

%Controls that need to be stretched/compacted.
setpos(handles.display_help,'width',(figpos(3)-131) - 1)
setpos(handles.optionsframe,'width',(figpos(3)-131) - 1)
setpos(handles.text4,'width',figpos(3)-417-39)

%Move buttons and slider left-right.
setpos(handles.optionsslider,'left',figpos(3)-28)
setpos(handles.okbutton','left',figpos(3)-382)
setpos(handles.cancelbutton','left',figpos(3)-254)
setpos(handles.resetbutton','left',figpos(3)-126)

%List items that need width changes.
bt = findobj(handles.optionsgui,'Userdata','optctrl');%all list items.
for i = 1:length(bt)
  tagnm = get(bt(i),'tag');
  if ~isempty(strfind(tagnm,'save_'))
    setpos(bt(i),'right',figpos(3)-39);
  elseif ~isempty(strfind(tagnm,'tabheader_'))
    setpos(bt(i),'right',figpos(3)-39,1)
  elseif ~isempty(strfind(tagnm,'description_'))
    cpos = get(bt(i),'position');
    setpos(bt(i),'right',figpos(3)-39-saveoffset,1)
    %Rewrap text string.
    dstr = getappdata(bt(i), 'optinfo');
    dstr = dstr.help;
    if ~iscell(dstr)
      dstr = {dstr};
    end
    dstr = textwrap(bt(i),dstr);
    %Adjust string to indicate more help than can be listed.
    %Text width factor.
    twfact = floor(0.1793*cpos(3));
    if length(dstr)>2 & length(dstr{2})>twfact
      dstr{2} = [dstr{2}(1:twfact) ' ...'];
      set(bt(i),'BackgroundColor',[1 0.92 .88])
    elseif length(dstr)>2
      dstr{2} = [dstr{2} ' ...'];
      set(bt(i),'BackgroundColor',[1 0.92 .88])
    else
      %Set back to orginal color.
      %Hard coded from prefobjplace.m.
      set(bt(i),'BackgroundColor',[0.98 0.98 .94]*.98)
    end
    set(bt(i),'string',dstr);
    
  end
end
drawnow

%Call toggle button callback with current button to rebuild the table.
%This will call remapopts to rebuild table and reconfigure the slider.
allbtns = findobj(handles.optionsgui,'userdata','tabbutton');
curbtn = findobj(allbtns, 'value', 1);
if isempty(curbtn)
  %Button hasn't been selected yet so make it the all button.
  curbtn = findobj(handles.optionsgui,'tag','allbutton');
  set(curbtn,'value',1)
end
togglebutton_Callback(curbtn, [],handles);

if strcmpi(get(handles.optionsslider,'enable'),'on')
  newmin = get(handles.optionsslider,'min');
  newmax = get(handles.optionsslider,'max');

  newsliderpos = (((oldsliderpos-oldmin)/(oldmax-oldmin))*(newmax-newmin))+newmin;

  set(handles.optionsslider,'value',newsliderpos);
  optionsslider_Callback(handles.optionsslider, [], guihandles(h));
end

%------------------------------------------------
function scrollWheelCallback(h,action,varargin)
%Scroll on figure.

handles = guidata(h);

sdir = action.VerticalScrollCount;%Positive or negative depending on direction.
%samount = action.VerticalScrollAmount;%Always one...
sval = get(handles.optionsslider,'value');
smin = get(handles.optionsslider,'min');
smax = get(handles.optionsslider,'max');
sstep = get(handles.optionsslider,'sliderstep');

newval = sval-sdir*sstep(1);

if sdir>0
  %Slide down.
  set(handles.optionsslider,'value',max(smin,newval));
else
  %Slide up to val=1
  set(handles.optionsslider,'value',min(smax,newval));
end

optionsslider_Callback(handles.optionsslider, [], handles)

%--------------------------------------------------------------
function setpos(h,dim,sz,stretch)

if nargin<4;
  stretch = 0;
end
set(h,'units','pixels');
uipos = get(h,'position');
switch dim
  case 'bottom'
    %uipos(2) = sz;
    if stretch
      uipos(4) = uipos(4)+uipos(2)-sz;
    end
    uipos(2) = sz;
  case 'top'
    if ~stretch
      uipos(2) = sz-uipos(4);
    else
      uipos(4) = sz-uipos(2);
    end
  case 'left'
    uipos(1) = sz;
    if stretch
      uipos(3) = uipos(3)+sz;
    end
  case 'right'
    if ~stretch
      uipos(1) = sz-uipos(3);
    else
      uipos(3) = sz-uipos(1);
    end

  case 'width'
    if ~stretch
      uipos(3) = sz;
    else
      uipos(1) = uipos(1)-sz;
    end
  case 'height'
    if ~stretch
      uipos(4) = sz;
    else
      uipos(2) = uipos(2)-sz;
    end
end
limit = (3:4);
uipos(limit(uipos(limit)<1)) = 1;
set(h,'position',uipos);

%--------------------------------------------------------------
function sz = getpos(h,dim)
set(h,'units','pixels');
uipos = get(h,'position');
switch dim
  case 'bottom'
    sz = uipos(2);
  case 'top'
    sz = uipos(2)+uipos(4);
  case 'left'
    sz = uipos(1);
  case 'right'
    sz = uipos(1)+uipos(3);
  case 'width'
    sz = uipos(3);
  case 'height'
    sz = uipos(4);
end

