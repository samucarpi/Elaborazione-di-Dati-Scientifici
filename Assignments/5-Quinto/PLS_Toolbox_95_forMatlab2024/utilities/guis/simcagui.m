function varargout = simcagui(varargin)
% SIMCAGUI M-file for simcagui.fig.
%      SIMCAGUI, by itself, creates a new SIMCAGUI or raises the existing
%      singleton*.
%
%      H = SIMCAGUI returns the handle to a new SIMCAGUI or the handle to
%      the existing singleton*.
%
%      SIMCAGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SIMCAGUI.M with the given input arguments.
%
%      SIMCAGUI('Property','Value',...) creates a new SIMCAGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before simcagui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to simcagui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
%See also: GUIDATA, GUIDE, GUIHANDLES

%Copyright Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Begin initialization code - DO NOT EDIT

if nargin == 0  | ~ischar(varargin{1})
  varargin = {'setup', varargin{:}};
end

switch varargin{1}
  case cat(2,evriio([],'validtopics'));
    options = [];
    if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return;
  otherwise
    if nargout == 0;
      feval(varargin{:});
    else
      [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    end;
end
%--------------------------
function fig = setup(varargin)

fig     = openfig(mfilename,'new');   %create gui
centerfigure(fig);
figbrowser('addmenu',fig);
handles = guihandles(fig);	      % Generate a structure of handles to pass to callbacks
guidata(fig,handles);             % and save in guidata
set(fig,'closerequestfcn',['try;' get(fig,'closerequestfcn') ';catch;delete(gcbf);end'])

%Create disable behavior for buttons with cdata images. Save original
%image and grey image to appdata. Can be time consuming so do once here in
%setup.
setappdata(handles.simcagui,'buildimg',get(handles.build,'cdata'))
setappdata(handles.simcagui,'saveimg',get(handles.save,'cdata'))

buildimg_grey = (double(get(handles.build,'cdata'))/255)./1.4;
buildimg_grey = uint8(round(buildimg_grey*255));
setappdata(handles.simcagui,'buildimg_grey',buildimg_grey)

saveimg_grey = (double(get(handles.save,'cdata'))/255)./1.4;
saveimg_grey = uint8(round(saveimg_grey*255));
setappdata(handles.simcagui,'saveimg_grey',saveimg_grey)

set(handles.editoptionsbutton,'cdata',gettbicons('options'),'string','');

setappdata(handles.simcagui,'simcasubmodels',[]);
setappdata(handles.simcagui,'simcamodel',[]);
setappdata(handles.simcagui,'test',[]);

set(handles.classlist,'string',{''},'value',1);

if nargin>0
  %prep GUI
  analhandles = guidata(varargin{1});
  setappdata(analhandles.AnalysisToolbar, 'simcagui', fig)
  setappdata(fig,'parenthandle',analhandles.analysis)
  
  populatelist(fig);
  
  modl = analysis('getobjdata','model',analhandles);
  if ~isempty(modl)
    if strcmp(lower(modl.modeltype),'simca');
      populatemodels(fig);
    end
  end

  classetmenu_update(handles);

  buttonstatus(handles.simcagui)%Enable correct button
end
set(fig,'resize','on','resizefcn',@resize_Callback)

% --- Executes just before simcagui is made visible.
function simcagui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to simcagui (see VARARGIN)

% Choose default command line output for simcagui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes simcagui wait for user response (see UIRESUME)
% uiwait(handles.simcagui);


% --- Outputs from this function are returned to the command line.
function varargout = simcagui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function classlist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to classlist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
  set(hObject,'BackgroundColor','white');
else
  set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% ----------------------------------------------
function resize_Callback(fig, eventdata)

handles = guidata(fig);

fpos  = get(fig,'position');
fpos  = max(fpos,[1 1 100 130]);
b1pos = get(handles.save,'position');
b2pos = get(handles.build,'position');
bsize = b2pos(3:4);
listwidth = (fpos(3)-bsize(1)-4)/2;

%class set chooser objs
clslbl = get(handles.classsetlabel,'position');
clsmnu = get(handles.classsetmenu,'position');
clslbl(2) = fpos(4)-2-clslbl(4);
clsmnu(2) = fpos(4)-2-clsmnu(4);
clsmnu(3) = fpos(3)-2-clsmnu(1);
set(handles.classsetlabel,'position',clslbl)
set(handles.classsetmenu,'position',clsmnu)

%frame 1 (first column)
f1pos = get(handles.frame1,'position');
f1pos(3) = listwidth-4;
f1pos(4) = fpos(4)-4-clsmnu(4)-2;
set(handles.frame1,'position',f1pos)

%middle buttons
b1pos(1) = f1pos(1)+f1pos(3)+3;
b2pos(1) = b1pos(1);
b2pos(2) = fpos(4)/2+8;
b1pos(2) = fpos(4)/2-8-b1pos(4);
set(handles.save,'position',b1pos);
set(handles.build,'position',b2pos);

%frame 2 (second column)
f2pos = get(handles.frame2,'position');
f2pos(1) = b1pos(1)+bsize(1)+3;
f2pos(3) = listwidth-2;
f2pos(4) = fpos(4)-2-f2pos(2)-clsmnu(4)-2;
set(handles.frame2,'position',f2pos)

f4pos = get(handles.frame4,'position');
f4pos(1) = f1pos(1)+f1pos(3)+2;
f4pos(3) = fpos(3)-f4pos(1)-2;
set(handles.frame4,'position',f4pos);

%first column items
tpos = get(handles.text1,'position');
tpos(2) = f1pos(2)+f1pos(4)-2-tpos(4);
tpos(1) = f1pos(1)+1;
tpos(3) = f1pos(3)-2;
set(handles.text1,'position',tpos);

%list
pos = get(handles.classlist,'position');
pos(1) = f1pos(1)+2;
pos(3) = f1pos(3)-4;
pos(4) = tpos(2)-pos(2)-2;
set(handles.classlist,'position',pos);

%label
set(handles.availablelable,'units','pixels')
pos = get(handles.availablelable,'position');
pos(3) = f1pos(3)-8;
set(handles.availablelable,'position',pos);

%second column items
tpos = get(handles.text2,'position');
tpos(2) = f2pos(2)+f2pos(4)-2-tpos(4);
tpos(1) = f2pos(1)+1;
tpos(3) = f2pos(3)-2;
set(handles.text2,'position',tpos);

%list
pos = get(handles.modellist,'position');
pos(1) = f2pos(1)+2;
pos(3) = f2pos(3)-4;
pos(4) = tpos(2)-pos(2)-2;
set(handles.modellist,'position',pos);

%buttons
buildwidth = 0.8;  %fraction of frame 4 that build button should use
delpos = get(handles.delete,'position');
buildpos = get(handles.buildsimca,'position');
delpos(1) = f2pos(1)+2;
delpos(3) = f2pos(3)-4;
buildpos(1) = f4pos(1)+f4pos(3)*(1-buildwidth);
buildpos(3) = f4pos(3)*buildwidth-12;
set(handles.delete,'position',delpos);
set(handles.buildsimca,'position',buildpos);

optspos = get(handles.editoptionsbutton,'position');
optspos(1) = (f4pos(1)+buildpos(1))/2-optspos(3)/2;
set(handles.editoptionsbutton,'position',optspos);

% --- Executes on selection change in classlist.
function classlist_Callback(hObject, eventdata, handles)
% hObject    handle to classlist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns classlist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from classlist

%Set statmodl = 'old' in analysis then update
%Change buttons, enable fit model button
buttonstatus(hObject)
if strcmp(get(handles.simcagui,'selectiontype'),'open');
  build_Callback(handles.simcagui,[],handles);
end

% --- Executes on button press in build.
function build_Callback(h, eventdata, handles)%Model Selected

%Clear model in Analysis
%Set appdata of classes in calc button
%Set focus to Analysis
handles = guidata(h);

%Get classes from "Available" list box.
% classindex = get(handles.classlist,'value');
% classstring = str2num(get(handles.classlist,'string'));
% classstring = classstring(classindex)';
classstring = getselectedclasses(handles);

analysis('clearmodel',getappdata(handles.simcagui,'parenthandle'),[],guidata(getappdata(handles.simcagui,'parenthandle')),[]);
calchandle = findobj(getappdata(handles.simcagui,'parenthandle'),'tag','calcmodel');
setappdata(calchandle,'modelclasses',classstring);
simca_guifcn('calcmodel_Callback',getappdata(handles.simcagui,'parenthandle'),[],guidata(getappdata(handles.simcagui,'parenthandle')),[]);

%Change buttons, enable fit model button
buttonstatus(h)

% --- Executes during object creation, after setting all properties.
function modellist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to modellist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
  set(hObject,'BackgroundColor','white');
else
  set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

% --- Executes on selection change in modellist.
function modellist_Callback(hObject, eventdata, handles)
%Load Analysis fig with simca or sub model.

h = guidata(hObject);
parent = getappdata(h.simcagui,'parenthandle');%analysis gui
index = get(h.modellist,'value');%index in model list
mlist = get(h.modellist,'string');

if isempty(mlist)
  updatebuttons(h.simcagui);
  return
end

modl = getappdata(h.simcagui,'simcamodel');
test = getappdata(h.simcagui,'test');
statdata = getappdata(parent,'statdata');
if isempty(modl);
  %no SIMCA model currently
  submodels = getappdata(h.simcagui,'simcasubmodels');
  if length(submodels)>=index;
    analysis('loadmodel',parent,[],guidata(parent),submodels{index});
  end
else
  %simca model exists, use it as reference
  if index == 1
    %This is the SIMCA mode - push into Analysis.
    if strcmp(statdata,'test') & ~isempty(test)
      %setappdata(parent,'test',test)
      analysis('setobjdata','prediction',parent,test)
      setappdata(parent,'statdata','test')
    else
      %setappdata(parent,'test',[])
      analysis('setobjdata','prediction',parent,[])
    end
    analysis('loadmodel', parent,[],guidata(parent),modl)
  else
    %one of the PCA models - push into analysis
    if strcmp(statdata,'test') & ~isempty(test)
      temp = test.submodel{index-1};
      temp.detail = test.detail;  %copy details for plotting
      %setappdata(parent,'test',temp)
      analysis('setobjdata','prediction',parent,temp)
      setappdata(parent,'statdata','test')
    else
      %setappdata(parent,'test',[])
      analysis('setobjdata','prediction',parent,[])
    end
    analysis('loadmodel',parent,[],guidata(parent),modl.submodel{index-1})
  end
end

% %Reflect loaded model classes in Available classes list.
% if strcmpi(mlist{index},'<simca model>');
%   val = [];
% else
%   val = str2num([strtok(mlist{index},']') ']']);
% end
classstring = get(handles.classlist,'string');
if ~isempty(classstring) & ~iscell(classstring)
  setclassselection(handles)
end

% if ~isempty(classstring) & ~iscell(classstring)
%   %but only if that list is actually populated
%   set(handles.classlist,'value',val);
% end

%Set analysis calc model button with new modelclasses appdata field.
calchandle = findobj(getappdata(handles.simcagui,'parenthandle'),'tag','calcmodel');
setappdata(calchandle,'modelclasses',getselectedclasses(handles));

buttonstatus(hObject)

%Clear model save timestamp so Analysis GUI doesn't think the model is
%saved when it really is not.
parenthandles = guidata(parent);
setappdata(parenthandles.savemodel,'timestamp','');

% --- Executes on button press in save.
function save_Callback(hObject, eventdata, handles)%Add Current Model
%Grabs model from Analysis figure and stores it.

h = guidata(hObject);
%modl = getappdata(getappdata(h.simcagui,'parenthandle'),'modl');
modl = analysis('getobjdata','model',getappdata(h.simcagui,'parenthandle'));

simcamodel = getappdata(h.simcagui,'simcamodel');
if ~isempty(simcamodel);
  %simca model existed, but they want to add another model
  setappdata(h.simcagui,'simcamodel',[]);
  simcasubmodels = simcamodel.submodel;
  setappdata(h.simcagui,'simcasubmodels',simcasubmodels);
  updatemodellist(h.simcagui);
end

%Check to see if data used for models has changed via datasource. Warn if has changed.
simcasubmodels = getappdata(h.simcagui, 'simcasubmodels');
% if isfieldcheck('modl.datasource', modl)
%   for i = 1:length(simcasubmodels)
%     emodl = simcasubmodels{i};
%     if isfieldcheck('emodl.datasource',emodl)
%       if modl.datasource{1}.moddate == emodl.datasource{1}.moddate
%       else
%         evriwarndlg('Model being added may use different data than existing models.','Model Data Warning');
%         break
%       end
%     end
%   end
% end

%add actual model to end of simcasubmodels
if isempty(simcasubmodels)
  simcasubmodels = {modl};
else
  simcasubmodels{end+1} = modl;
end
setappdata(h.simcagui,'simcasubmodels',simcasubmodels);

updatemodellist(h.simcagui);

%Change buttons, enable fit model button
buttonstatus(hObject)

% --- Executes on button press in delete.
function delete_Callback(hObject, eventdata, handles)
% hObject    handle to delete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h = guidata(hObject);
index = get(h.modellist,'value');
mlist = get(h.modellist,'string');
mcache = getappdata(h.simcagui,'simcasubmodels');

simcamodel = getappdata(h.simcagui,'simcamodel');
if ~isempty(simcamodel);
  index = index-1;
  setappdata(h.simcagui,'simcamodel',[]);  %clear simca model now
end

mcache(index) = [];
setappdata(h.simcagui,'simcasubmodels',mcache)

updatemodellist(h.simcagui);
modellist_Callback(hObject, eventdata, handles)

%-------------------------------
function populatelist(simcafig)
%Populate list of classes.

analhandles = guidata(getappdata(simcafig,'parenthandle'));
handles = guidata(simcafig);
%data = getappdata(analhandles.analysis,'dataset');
data = analysis('getobjdata','xblock',analhandles);

if ~isempty(data)
  clsset = getclassset(handles);
  if ~isempty(clsset)
    %Get lookup table.
    classlist = data.classlookup{1,clsset};
    if ~isempty(classlist)
      % Remove any trailing whitespace from classids
      clist2 =strtrim(classlist(:,2));
      hasemptyclassid = any(cellfun(@length, clist2)==0);
      if hasemptyclassid
        error('Calibration dataset contains a blank or empty sample class id')
      end
      classlist(:,2) = clist2;
      %Find classes actually used and only populate list with those.
      usedclasses = unique(data.class{1,clsset});
      [junk indx junk2] = intersect([classlist{:,1}],usedclasses);
    
      set(handles.classlist,'string',char(classlist{indx,2}));
    end
  end
end

%-------------------------------
function buildsimca_Callback(hObject, eventdata, handles, varargin)

parent = getappdata(handles.simcagui,'parenthandle');
%x      = getappdata(parent,'dataset');
x      = analysis('getobjdata','xblock',parent);
modls  = getappdata(handles.simcagui,'simcasubmodels');

if length(modls)<1;
  if nargin<4 || ~varargin{1}
    %no error message if called when closing GUI with no models added
    erdlgpls('You must first create and "Add" models to the Modeled Classes list','Build Model');
  end
  return
end

% modclasses = getmodeledclasses(handles, modls);

modl      = modelstruct('simca');

%creation date and time
modl.date = date;
modl.time = clock;

%copy models into submodel structure
modl.submodel = modls;

%copy class and datasource info from submodel 1 (same in all submodels)
modl.detail.classname = modl.submodel{1}.detail.classname;
modl.datasource       = modl.submodel{1}.datasource;

modl = copydsfields(x,modl);

%Get simca options from Analysis and add to model.
sopts = getsimcaoptions(handles);
sopts = reconopts(sopts,'simca',0);
modl.detail.options = sopts;

set(handles.simcagui,'pointer','watch');
set([handles.buildsimca handles.delete handles.build handles.save handles.classlist handles.modellist],'enable','off')
drawnow;
try
  %Add to model.
  modl = simcastats(modl);
  
  %Update the simca classes
  modl = setsimcaclasses(modl);
  
  
  modl = multiclassifications(modl);

  %%FROM HERE - Take MODL and store it in the main analysis GUI as modl and
  %%set modl status as "loaded"
  parenthandles = guidata(parent);
  analysis('loadmodel',parent,[],parenthandles,modl);
  simca_guifcn('updatessqtable',parenthandles);

  %Add model to cache.
  analysis('cachecurrent',parenthandles);
  analysis('calcmodel_Callback',parent,[],parenthandles);
  
  %Turn crossval off so user doesn't get confused (SIMCA doesn't allow
  %crossval yet).
  setappdata(parent,'enable_crossvalgui','off');
  analysis('updatestatusimage',parenthandles);

catch
  set(handles.simcagui,'pointer','arrow');
  set([handles.buildsimca],'enable','on')
  buttonstatus(handles.simcagui)      %update buttons
  evrierrordlg({'Unable to build SIMCA model' lasterr},'Error Building Model');
  return;
end
set(handles.simcagui,'pointer','arrow');
drawnow;

%update local GUI
set(handles.classlist,'value',[]);  %disable selected classes
populatemodels(handles.simcagui);   %redraw model table based on full model
buttonstatus(handles.simcagui)      %update buttons

%Clear model save timestamp so Analysis GUI doesn't think the model is
%saved when it really is not.
setappdata(parenthandles.savemodel,'timestamp','');

%----------------------------------
function populatemodels(handle)
%takes SIMCA model from Analysis GUI and populates the SIMCA GUI with the
%appropriate information

h = guidata(handle);
parent = getappdata(h.simcagui,'parenthandle');

%Find and store model
%modl = getappdata(parent,'modl');
modl = analysis('getobjdata','model',parent);

setappdata(h.simcagui,'simcamodel',modl)
if ~isempty(modl) && isfield(modl,'submodel');
  %copy over sub-models for functions which use this to index into list
  setappdata(h.simcagui,'simcasubmodels',modl.submodel)
end

%Find and store test.
%test = getappdata(parent,'test');
test = analysis('getobjdata','prediction',parent);
setappdata(h.simcagui,'test',test);
updatemodellist(h.simcagui,1)

%---------------------------------
%Update list box for current list of submodels and simca model
function updatemodellist(h,forceselection)

handles = guidata(h);

simcamodel = getappdata(h,'simcamodel');
simcasubmodels = getappdata(h,'simcasubmodels');

%Construct listbox display.
if ~isempty(simcamodel);
  displaystring = {'<simca model>'};
  simcasubmodels = simcamodel.submodel;
else
  displaystring = {};
end
classset = getclassset(handles);
for i = 1:length(simcasubmodels)
  npcs = size(simcasubmodels{i}.loads{2},2);
  modeledclasses = unique(simcasubmodels{i}.detail.class{1,1,classset}(simcasubmodels{i}.detail.includ{1}));
  cnames = '';
  mytable = simcasubmodels{i}.detail.classlookup{1,1,classset};
  for j = 1:length(modeledclasses)
    row = find([mytable{:,1}]==modeledclasses(j));
    cnames = [cnames '+' mytable{row,2}];
  end
  cnames(1) = '';
  displaystring{end+1} = [' [ ' cnames ' ]  (' num2str(npcs) ' PCs)'];
end

if nargin>1
  val = forceselection;
else
  val = get(handles.modellist,'value');
end
set(handles.modellist,'string',displaystring,'val',min(length(displaystring),max(1,val)))


%---------------------------------------------
function updatebuttons(h);

if ishandle(h);
  buttonstatus(h)
  classetmenu_update(guidata(h));
end

%---------------------------------------------
function exitsimcagui(hObject, eventdata, handles);

parent   = getappdata(handles.simcagui,'parenthandle');
modl     = getappdata(handles.simcagui,'simcamodel');

if isempty(parent) | ~ishandle(parent)
  delete(handles.simcagui);
  return
end

%analmodl = getappdata(parent, 'modl');
analmodl = analysis('getobjdata','model',parent);
%test     = getappdata(handles.simcagui,'test');
test     = analysis('getobjdata','prediction',parent);
statdata = getappdata(parent,'statdata');

%unlink from xblock
dataid = analysis('getobj','xblock',parent);
linkshareddata(dataid,'remove',handles.simcagui);

if ~isempty(modl) && ~isempty(analmodl) && ~strcmp(lower(analmodl.modeltype),'simca')
  %load SIMCA model into parent
  if strcmp(statdata,'test') & ~isempty(test)
    %setappdata(parent,'test',test)
    analysis('setobjdata','prediction',parent,test)
    setappdata(parent,'statdata','test')
  else
    %setappdata(parent,'test',[])
    analysis('setobjdata','prediction',parent,[])
  end
  analysis('loadmodel',parent,[],guidata(parent),modl);
elseif isempty(modl)
  %model not yet built
  if ~isempty(getappdata(handles.simcagui,'simcasubmodels'))
    try
      buildsimca_Callback(hObject, eventdata, handles, 1);  % "1" on end is for "silent mode" (no error when no models exist)
    catch
      %allow close if there were errors...
    end
  end
  %did that work?
  modl = getappdata(handles.simcagui,'simcamodel');
  if isempty(modl);
    %still no model? clear anything in the main gui before continuing
    analysis('clearmodel',parent,[],guidata(parent));
  end

end

%clear modelclasses so that calc will NOT be functional
calchandle = findobj(parent,'tag','calcmodel');
setappdata(calchandle,'modelclasses',[]);

delete(handles.simcagui)

%Clear model save timestamp so Analysis GUI doesn't think the model is
%saved when it really is not.
parenthandles = guidata(parent);
setappdata(parenthandles.savemodel,'timestamp','');

simca_guifcn('gui_updatetoolbar',parent,[],guidata(parent))

%---------------------------------------------
function buttonstatus(h);
%Change enable of buttons. Statbutton should be the tag of the button you
%want to enable. Have to creat grey image bucause using cdata on button.

if ~ishandle(h)
  return
end
handles = guidata(h);

%grab various button images (stored in GUI)
buildimg      = getappdata(handles.simcagui,'buildimg');
saveimg       = getappdata(handles.simcagui,'saveimg');
buildimg_grey = getappdata(handles.simcagui,'buildimg_grey');
saveimg_grey  = getappdata(handles.simcagui,'saveimg_grey');

parent = getappdata(handles.simcagui,'parenthandle');

%-------------------
% enable logic for build/save buttons

if isempty(parent);
  statbutton = 'disable_all';
  buildsimca = 'off';
  deletebtn  = 'off';
  classlist  = 'off';
  modellist  = 'off';
else  
  calchandle     = findobj(getappdata(handles.simcagui,'parenthandle'),'tag','calcmodel');
  modellist = 'on';
  
  %get decision information
  statmodl       = getappdata(parent,'statmodl');
  %analmodl       = getappdata(parent,'modl');
  analmodl       = analysis('getobjdata','model',parent);
  
  simcamodel     = getappdata(handles.simcagui,'simcamodel');
  simcasubmodels = getappdata(handles.simcagui,'simcasubmodels');
  
  selectedmodel  = get(handles.modellist,'value');

  classesinsimca = getselectedclasses(handles);
  
  classesinanal  = getappdata(calchandle,'modelclasses');

  %set some defaults
  classlist  = 'on';
  buildsimca = 'on';
  deletebtn = 'on';

  if ~isempty(simcamodel);
    %SIMCA model already exists?
    buildsimca = 'off';  %assume off unless we decide otherwise
  end

  %check status for delete button
  if strcmp(statmodl,'loaded') | isempty(simcasubmodels) | (~isempty(simcamodel) & selectedmodel==1)
    deletebtn = 'off';
  end
  
  %decide what should be done with buttons
  switch statmodl
    case 'loaded'
      %model is loaded
      statbutton = 'disable_all';
      buildsimca = 'off';
      classlist  = 'off';
      
    case {'calnew','none'}
      if isempty(classesinsimca)
        %no classes selected - can't build
        statbutton = 'disable_all';
      else
        %model needs to be rebuilt
        statbutton = 'build';
      end

    otherwise
      %model 'calold' (up to date)
      if strcmpi(analmodl.modeltype,'simca')
        if isempty(classesinsimca)
          %SIMCA model - can't do anything
          statbutton = 'disable_all';
          buildsimca = 'off';
        else
          %SIMCA model, but user has selected some clases in GUI
          statbutton = 'build';
        end
      elseif isempty(setxor(classesinsimca,classesinanal))
        %PCA model with same classes in SIMCA and ANALYSIS
        %check date of model in Analysis (see if already saved)
        timediff = zeros(length(simcasubmodels),6);
        for j=1:length(simcasubmodels);
          timediff(j,1:6) = simcasubmodels{j}.time-analmodl.time;
        end
        if any(all(timediff==0,2));
          %already saved
          statbutton = 'disable_all';
        else
          statbutton = 'save';
        end
      else
        %PCA model but classes do NOT match (user has changed list in SIMCA)
        statbutton = 'build';
      end
  end
end

set(handles.buildsimca,'enable',buildsimca)
set(handles.classlist,'enable',classlist)
set(handles.modellist,'enable',modellist);
set(handles.delete,'enable', deletebtn);

if strcmp(statbutton,'build')
  %Enable fit button, disable add button.
  set(handles.build, 'cdata', buildimg)
  set(handles.build, 'enable', 'on');
  set(handles.save,  'cdata', saveimg_grey)
  set(handles.save,  'enable', 'off');
elseif strcmp(statbutton,'save')
  %Endable add button, disable fit button.
  set(handles.build, 'enable', 'off');
  set(handles.build, 'cdata', buildimg_grey)
  set(handles.save,  'cdata', saveimg)
  set(handles.save,  'enable', 'on');
elseif strcmp(statbutton,'disable_all')
  set(handles.build, 'enable', 'off');
  set(handles.build, 'cdata', buildimg_grey)
  set(handles.save,  'enable', 'off');
  set(handles.save,  'cdata', saveimg_grey)
end

sclass = getselectedclasses(handles,'string');

%---------------------------------------------
function reloadmodel(h);
%Load simca model into main gui and clear time stamp so Analysis doesn't
%think it's saved. Currently only used in exitpca in analysis.

parent = getappdata(h.simcagui,'parenthandle');
modl = getappdata(h.simcagui,'simcamodel');
%analmodl = getappdata(parent, 'modl');
analmodl = analysis('getobjdata','model',parent);
test = getappdata(h.simcagui,'test');

if ~isempty(modl) & ~strcmp(lower(analmodl.modeltype),'simca')
  button = evriquestdlg('Your SIMCA model is not the current model in Analysis. Do you want to reload it?',...
    'SIMCA Reload','Yes','No','Yes');
  if strcmp(button,'Yes')
    analysis('loadmodel',parent,[],guidata(parent),modl);

    if ~isempty(test)
      %setappdata(parent,'test',test)
      analysis('setobjdata','prediction',parent,test);
      setappdata(parent,'statdata','test')
    end
  elseif strcmp(button,'No')
  end
elseif isempty(modl)
  simcagui('buildsimca_Callback', '', '', h);
end

parenthandles = guidata(parent);
setappdata(parenthandles.savemodel,'timestamp','');

%---------------------------------------------
function sclass = getselectedclasses(handles,type)
%Returns the selected classes from the classlist control. Input 'type'
%describes which class info is to be returned.
% type = 'numeric' returns selected numeric classes as a vector.
% type = 'string' returns a cell array of stings of classids.

if nargin < 2
  type = 'numeric';
end

sclass = {};

analhandles = guidata(getappdata(handles.simcagui,'parenthandle'));
data = analysis('getobjdata','xblock',analhandles);
if isempty(data)
  return
end

classindex     = get(handles.classlist,'value');
classstring    = get(handles.classlist,'string');
if isempty(classstring)
  return;
end
try
  classstring    = str2cell(classstring(classindex,:));
catch
  classstring = [];
  return
end
if strcmp(type,'numeric')
  classset = getclassset(handles);
  if isempty(classset); return; end
  %Get lookup table.
  classlist = data.classlookup{1,classset};
  if isempty(classlist); return; end
  % Remove any trailing whitespace from classids
  clist2 =strtrim(classlist(:,2));
  for i = 1:length(classindex)
    ind=find(ismember(clist2, classstring{i,:}));
    item = classlist(ind,1);
    if ~isempty(item);
      sclass(end+1) = item;
    end
  end
  sclass = cell2mat(sclass);
else
  sclass = classstring;
end


%---------------------------------------------
function setclassselection(handles)
%Set values in classlist to those listed in selection on modellist.
mlist = get(handles.modellist,'string');
mval  = get(handles.modellist,'value');

rem = strtok(mlist{mval},']');
rem = strtrim(strrep(rem,'[',''));

mlist = {};
while true
  [tok rem] = strtok(rem,'+');
  mlist = [mlist; tok];
  if isempty(rem)
    break
  end
end

clist = get(handles.classlist,'string');

clist = str2cell(clist);

nval = find(ismember(clist,mlist));
set(handles.classlist,'value',nval);


%----------------------------------------------
function classset = getclassset(handles)

simcaopts = getsimcaoptions(handles);
if isfield(simcaopts,'classset')
  classset = simcaopts.classset;
else
  classset = 1;
end
data = analysis('getobjdata','xblock',guidata(getappdata(handles.simcagui,'parenthandle')));
if ~isempty(data)
  %make sure this class set exists
  goodsets = find(~cellfun('isempty',data.class(1,:)));
  classset = goodsets(findindx(goodsets,classset));
  if isempty(classset)
    %no classes? use class set 1
    classset = 1;
  end
else
  %no data?? Always use class set 1
  classset = 1;
end

%---------------------------------------------
function setclassset(handles,classset)
%update class set menu to match the given class set #

sets = getappdata(handles.simcagui,'classsetinds');
set(handles.classsetmenu,'value',findindx(sets,classset));

%---------------------------------------------
function opts = getsimcaoptions(handles)

parent = getappdata(handles.simcagui,'parenthandle');
opts = getappdata(parent,'analysisoptions');
if ~issimcaopts(opts)
  %check for last set SIMCA options in Analysis
  opts = analysis('getoptshistory',guidata(parent),'simca');
end
if ~issimcaopts(opts)
  %check for options stored in simcagui
  opts = getappdata(handles.simcagui,'simcaoptions');
end
if ~issimcaopts(opts)
  %get default options!!
  opts = simca('options');
end
if issimcaopts(opts)
  %got options - save those in simcaoptions
  setappdata(handles.simcagui,'simcaoptions',opts);
end

%---------------------------------------------
function out = issimcaopts(opts)

if isempty(opts) | ~isfield(opts,'functionname') | ~strcmpi(opts.functionname,'simca')
  out = false;
else
  out = true;
end

%---------------------------------------------
function clearmodel(h)

handles = guidata(h);
setappdata(handles.simcagui,'simcasubmodels',[]);
setappdata(handles.simcagui,'simcamodel',[]);
setappdata(handles.simcagui,'test',[]);

set(handles.classlist,'string',{''},'value',1);

parent = getappdata(handles.simcagui,'parenthandle');
calchandle = findobj(parent,'tag','calcmodel');
setappdata(calchandle,'modelclasses',[]);

populatelist(handles.simcagui);
updatemodellist(handles.simcagui);
buttonstatus(handles.simcagui)%Enable correct button

%----------------------------------------------
function analysiseditoptions(h,eventdata,handles)
%ANALYSIS window click of the edit options button - handle differently

sgh = getappdata(handles.AnalysisToolbar,'simcagui');
if isempty(sgh) | ~ishandle(sgh)
  %make sure modelbuilder is OPEN (so we can rebuild model automatically)
  sgh = simcagui(handles.analysis);
end
%then call normal editoptions
editoptions(sgh)

%----------------------------------------------
function editoptions(h,outopts)
%editoptions button on SIMCA Model builder - gives us more freedom

handles = guidata(h);
opts = getsimcaoptions(handles);
if nargin<2
  rmlist = analysis('optionsdisablelist','simca');
  o.disable = '';
  o.remove  = rmlist;
  outopts = optionsgui(opts,o);
end

if isempty(outopts) | comparevars(opts,outopts)
  %User cancel optionsgui.
  return
end

%check if we're changing settings which will cause clearing of model
parent = getappdata(handles.simcagui,'parenthandle');
if outopts.classset~=opts.classset & (~isempty(getappdata(handles.simcagui,'simcamodel')) | analysis('isloaded','model',guidata(parent)))
  ok = evriquestdlg('Changing the class set will cause any current models to be cleared. OK to clear models?','Clear Models?','Clear Models','Cancel','Clear Models');
  if isempty(ok) | strcmpi(ok,'Cancel')
    setclassset(handles,opts.classset);
    return;
  end
end

%store in simcagui (backup, but probably not used)
setappdata(handles.simcagui,'simcaoptions',outopts);

%store in Analysis as...
parent = getappdata(handles.simcagui,'parenthandle');
curanal = lower(char(getappdata(parent,'curanal')));
analhandles = guidata(parent);
if strcmpi(curanal,'simca')
  %simca model is currently loaded, use standard setopts routine
  analysis('setopts',analhandles,curanal,outopts);
else
  %not SIMCA model, store in analysis options history
  optionshistory = getappdata(parent, 'analysisoptions_history');
  optionshistory.simca = outopts;
  setappdata(parent, 'analysisoptions_history',optionshistory);
end

if outopts.classset~=opts.classset
  clearmodel(handles.simcagui);
  analysis('clearmodel',parent,[],guidata(parent));
  setclassset(handles,outopts.classset);
end
autorebuild(handles.simcagui)

%----------------------------------------------
function autorebuild(sgh)

%check if a model is built and, if so, rebuild using new options
simcamodel = getappdata(sgh,'simcamodel');
if ~isempty(simcamodel);
  %simca model existed, but they want to add another model
  setappdata(sgh,'simcamodel',[]);
  simcasubmodels = simcamodel.submodel;
  setappdata(sgh,'simcasubmodels',simcasubmodels);
  updatemodellist(sgh);
  buildsimca_Callback(sgh, [], guidata(sgh), 1);  % "1" on end is for "silent mode" (no error when no models exist)
end


% --- Executes on selection change in classsetmenu.
function classsetmenu_Callback(hObject, eventdata, handles)
% hObject    handle to classsetmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns classsetmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from classsetmenu

ind = get(handles.classsetmenu,'value');
sets = getappdata(handles.simcagui,'classsetinds');
opts = getsimcaoptions(handles);
opts.classset = sets(ind);
editoptions(handles.simcagui,opts);

% --- Executes during object creation, after setting all properties.
function classsetmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to classsetmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%---------------------------------------------------
function classetmenu_update(handles)

%populate the class set menu
classset = getclassset(handles);
parent = getappdata(handles.simcagui,'parenthandle');
analhandles = guidata(parent);
dataid = analysis('getobj','xblock',analhandles);
if isempty(dataid);
  delete(handles.simcagui);
  return;
end
linkshareddata(dataid,'add',handles.simcagui,'simcagui');
data = dataid.object;
clsnames = [];
if ~isempty(data)
  clsnames = data.classname(1,:);
  clsind   = find(~cellfun('isempty',data.class(1,:)));
  clsnames = clsnames(clsind);
  for j = find(cellfun('isempty',clsnames))
    clsnames{j} = sprintf('Set #%i',j);
  end
end
if isempty(clsnames)
  clsind   = 1;
  classset = 1;
  clsnames = {''};
end
set(handles.classsetmenu,'string',clsnames,'value',findindx(clsind,classset))
setappdata(handles.simcagui,'classsetinds',clsind);

%--------------------------------------------------
function updateshareddata(varargin)
if isempty(varargin{1}) | ~ishandle(varargin{1});
  return
end
handles = guidata(varargin{1});
classetmenu_update(handles)
populatelist(handles.simcagui);
% inds = cellfun(@(x)strcmpi(class(x), 'char'), varargin);

%if ~strcmpi(char(varargin(inds)), 'include')
if ~strcmpi(varargin{3}, 'include')
  % if the include field is changed on the dataset, don't clear everything
  clearmodel(handles.simcagui);
end

%--------------------------------------------------
function propupdateshareddata(varargin)

%--------------------------------------------------
function modeledclasses = getmodeledclasses(handles, modls)
% Get cell array of class nums associated with each sub-model
nsubmodels = length(modls);  
classset = getclassset(handles);  % Or use modls{1}.detail.option.classset

modeledclasses = {};
for i=1:nsubmodels
modeledclasses{i} = unique(modls{i}.detail.class{1,1,classset}(modls{i}.detail.includ{1}));  
end

%--------------------------------------------------
function modl = setsimcaclasses(modl)
% set classlookup for the simca model
modl.detail.modeledclasslookup = modl.detail.classlookup;

classset = modl.detail.options.classset;
clookup  = modl.detail.classlookup{1,1,classset};

oclookupnums=[clookup{:,1}];

zpos = ismember(oclookupnums,0);  
haszero = any(zpos);

modls = modl.submodel;
nsimcaclasses = length(modls);      % include Class 0 if there
zclasslookup = cell(nsimcaclasses+haszero,2);
if haszero
  zclasslookup(1,:) = clookup(zpos,:);
end

for iclass=1:nsimcaclasses
  zclasslookup{iclass+haszero,1} = iclass;  
  modeled      = ismember(oclookupnums,modl.detail.submodelclasses{iclass});
  oclookupvals = clookup(modeled,2);
  cname        = [sprintf('%s+',oclookupvals{1:end-1}), oclookupvals{end}];
  zclasslookup{iclass+haszero,2} = cname;
end

modl.detail.modeledclasslookup{1} = zclasslookup;


