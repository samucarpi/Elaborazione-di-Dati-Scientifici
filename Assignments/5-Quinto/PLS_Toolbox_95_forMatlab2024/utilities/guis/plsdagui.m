function varargout = plsdagui(varargin)
% PLSDAGUI M-file for plsdagui.fig
%      PLSDAGUI, by itself, creates a new PLSDAGUI or raises the existing
%      singleton*.
%
%      H = PLSDAGUI returns the handle to a new PLSDAGUI or the handle to
%      the existing singleton*.
%
%      PLSDAGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLSDAGUI.M with the given input arguments.
%
%      PLSDAGUI('Property','Value',...) creates a new PLSDAGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plsdagui_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plsdagui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


% Edit the above text to modify the response to help plsdagui

% Last Modified by GUIDE v2.5 03-Apr-2020 18:17:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
  'gui_Singleton',  gui_Singleton, ...
  'gui_OpeningFcn', @plsdagui_OpeningFcn, ...
  'gui_OutputFcn',  @plsdagui_OutputFcn, ...
  'gui_LayoutFcn',  [] , ...
  'gui_Callback',   []);
if nargin & isstr(varargin{1})
  gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
  [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
  gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before plsdagui is made visible.
function plsdagui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plsdagui (see VARARGIN)

% Choose default command line output for plsdagui
handles.output = hObject;

if ismac
  %Spacing and colors are messed up by default on mac.
  set([handles.classlist handles.grouplist],'backgroundcolor','white')
%   set(handles.frame5,'units','pixels','position',[3 5 156 31])
  set(handles.default,'units','pixels','position',[11 36 142 25])
  set(handles.newbtn, 'units', 'pixels', 'position', [169 34 142 25])
%   set(handles.frame4,'units','pixels','position', [163 5 156 31])
  set(handles.ok,'units','pixels','position',[170 4 69 23])
  set(handles.cancel,'units','pixels','position',[242 4 69 23])
  set(handles.helpbtn, 'units', 'pixels', 'position', [4 4 69 23])
  set(handles.renamebtn, 'units', 'pixels', 'position', [170 62 142 25])
end
  
figbrowser('addmenu',handles.plsdagui);

% Update handles structure
guidata(hObject, handles);

if nargin<4 || isempty(varargin{1});
  erdlgpls('PLSDA GUI Requires an input of either a dataset object with classes, a vector of classes, or a classlookup table to select from.','Invalid Classes');
  close(handles.plsdagui);
  return
end

classset = 1;
if nargin>5
  %got specified class set to start with
  classset = varargin{3};
end

if nargin>6
  %got current analysis passed in
  curanal = varargin{4};
end

cls = varargin{1}(:);
if isdataset(cls)
  myds = cls;
  setappdata(handles.plsdagui,'mydataset',myds);
  
  %get all class set names
  classsets = myds.classname(1,:);
  for j=find(cellfun('isempty',classsets))
    classsets{j} = sprintf('Class Set %i',j);
  end
  use = find(~cellfun('isempty',myds.class(1,:)));
  classsets = classsets(use);
  classindex = use;
  
  if isempty(classindex)
    erdlgpls('No Classes are defined in this data. Add classes by editing the X-block.','Invalid Classes');
    close(handles.plsdagui);
    return
  end

  %validate classset
  if ~ismember(classset,classindex)
    classset = classindex(1);
  end
  set(handles.classsetmenu,'string',classsets,'userdata',classindex,'value',find(classindex==classset));
  
  %Pull class out of table into vector.
  cls = unique(myds.class{1,classset})';
  cls(~isfinite(cls)) = []; %drop non-finite values
  
  mytbl = myds.classlookup{1,classset};
  mytbl = mytbl(ismember([mytbl{:,1}],cls),:);
  
  cls_str = char(mytbl{:,2});
elseif ~isnumeric(cls)
  [cls_str,cls] = unique(cls,'rows');
else
  cls = unique(cls(:));
  cls_str = num2str(cls);
end

if isempty(cls);
  erdlgpls('Class Grouping requires an input of either a dataset object with classes or a vector of classes to select from.','Invalid Classes');
  close(handles.plsdagui);
  return
end

setappdata(handles.plsdagui,'classdesc',cls_str);
setappdata(handles.plsdagui,'uniqueclass',cls);
setappdata(handles.plsdagui,'classset',classset)


groups = zeros(1,size(cls,1));
if nargin>4 & iscell(varargin{2})
  for j=1:length(varargin{2})
    groups(ismember(cls,varargin{2}{j})) = j;
  end
end

setappdata(handles.plsdagui,'defaultgroups',groups);
setappdata(handles.plsdagui,'groups',groups)
setappdata(handles.plsdagui, 'curanal', curanal);
%   default_groups(hObject, eventdata, handles, 1);

update_gui(hObject, eventdata, handles);

centerfigure(handles.plsdagui)

% UIWAIT makes plsdagui wait for user response (see UIRESUME)
uiwait(handles.plsdagui);


% --- Outputs from this function are returned to the command line.
function varargout = plsdagui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isfield(handles,'plsdagui') & ishandle(handles.plsdagui)
  groups                  = getappdata(handles.plsdagui,'groups');
  classindex              = get(handles.classsetmenu,'userdata');
  classset                = classindex(get(handles.classsetmenu,'value'));
  modifiedDSO             = getappdata(handles.plsdagui, 'modDSO');
  classSetToUseForKNN     = getappdata(handles.plsdagui, 'classSetForKNN');
  classGroupCreatedForKNN = getappdata(handles.plsdagui, 'classGroupCreatedForKNN');
  
  infoForKNN.classSetToUse           = classSetToUseForKNN;
  infoForKNN.classGroupCreatedForKNN = classGroupCreatedForKNN;
  
  if ~isempty(groups);
    cls = getappdata(handles.plsdagui,'uniqueclass');
    cls = cls(:)';  %row-vectorize
    
    grpcell = {};
    for j=1:max(groups);
      grpcell{j} = cls(groups==j);
    end
    varargout  = {grpcell classset modifiedDSO infoForKNN};
  else
    varargout = {0 classset modifiedDSO infoForKNN};
  end
  
  close(handles.plsdagui);
else
  varargout = {[] [] [] []};
end

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
% parent = getappdata(gcf,'parent');
% data = getappdata(parent,'dataset');
% classlist = unique(data.class{1});
set(hObject,'string','');


% --- Executes on selection change in classlist.
function classlist_Callback(hObject, eventdata, handles)
% hObject    handle to classlist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns classlist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from classlist

if strcmp(get(handles.plsdagui,'selectiontype'),'open');
  group_Callback(handles.group,[],handles);
end


% --- Executes on button press in group.
function group_Callback(hObject, eventdata, handles)
% hObject    handle to group (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

sel    = get(handles.classlist,'value');
lookup = getappdata(handles.classlist,'lookup');
groups = getappdata(handles.plsdagui,'groups');

if ~isempty(sel) & ~isempty(lookup);
  if length(sel)==length(groups);
    erdlgpls('One group cannot contain all classes. Group not created.','Single Group Error');
    return
  end
  
  %Note in groups list
  sel = lookup(sel);
  groups(sel) = max(groups)+1;
  setappdata(handles.plsdagui,'groups',groups);
  
  update_gui(hObject,eventdata,handles);
  
end

% --- Executes during object creation, after setting all properties.
function grouplist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to grouplist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
  set(hObject,'BackgroundColor','white');
else
  set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end

set(hObject,'min',0,'max',2)

% --- Executes on selection change in grouplist.
function grouplist_Callback(hObject, eventdata, handles)
% hObject    handle to grouplist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns grouplist contents as cell array
%        contents{get(hObject,'Value')} returns selected item from grouplist


if strcmp(get(handles.plsdagui,'selectiontype'),'open');
  ungroup_Callback(handles.ungroup,[],handles);
end


% --- Executes on button press in ungroup.
function ungroup_Callback(hObject, eventdata, handles)
% hObject    handle to ungroup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

group_text = get(handles.grouplist,'string');
if ~isempty(group_text);
  sel = get(handles.grouplist,'value');
  groups = getappdata(handles.plsdagui,'groups');
  %drop selected group(s)
  groups(ismember(groups,sel)) = 0;
  
  %renumber remaining groups 
  [usedgroups,i,j] = unique(groups);
  if any(usedgroups==0)
    j = j-1;
  end
  groups = j;
  
  %store
  setappdata(handles.plsdagui,'groups',groups);
  
  update_gui(hObject,eventdata,handles);
end

% --- Executes on button press in ok.
function ok_Callback(hObject, eventdata, handles)
% hObject    handle to ok (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

curanal = getappdata(handles.plsdagui, 'curanal');
curGroup = getappdata(handles.plsdagui, 'groups');
setappdata(handles.plsdagui, 'classGroupCreatedForKNN', false);
defaultGroup = [1:length(curGroup)];
classSetToUseForKNN = getappdata(handles.plsdagui, 'classSetForKNN');
if strcmp(curanal, 'knn') && ~sum(curGroup)==0 && isempty(classSetToUseForKNN)
  if iscolumn(curGroup)
    curGroup =  curGroup';
  end
  groupSameAsDefault = all(curGroup==defaultGroup);
  if ~groupSameAsDefault
    newbtn_Callback(hObject, eventdata, handles, 1);
    setappdata(handles.plsdagui, 'classGroupCreatedForKNN', true);
  else
    default_groups(hObject, eventdata, handles);
  end
end
uiresume(handles.plsdagui);

% --- Executes on button press in cancel.
function cancel_Callback(hObject, eventdata, handles)
% hObject    handle to cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% groups = getappdata(handles.plsdagui,'defaultgroups');
% setappdata(handles.plsdagui,'groups',groups)
setappdata(handles.plsdagui,'groups',[])
setappdata(handles.plsdagui, 'classGroupCreatedForKNN', false);
uiresume(handles.plsdagui);


% --- Executes on button press in default.
function default_Callback(hObject, eventdata, handles)
% hObject    handle to default (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

groups = getappdata(handles.plsdagui,'groups');
if ~all(groups==1:length(groups))
  if ~all(groups==0)
    %if user has something selected other than the default... make sure it's OK to overwrite
    ans = evriquestdlg('Reset Class Groups list to individual classes?','Reset Groups','Yes','Cancel','Yes');
    if strcmp(ans,'Cancel')
      return
    end
  end
  default_groups(hObject, eventdata, handles);
end

% ------------------------------------------------------
%set default classlist to contain all classes as individual groups
function default_groups(hObject, eventdata, handles, varargin)

groups = getappdata(handles.plsdagui,'groups');
if length(groups)>1;
  groups = [1:length(groups)];
else
  groups = zeros(1,length(groups));
end
setappdata(handles.plsdagui,'groups',groups);
update_gui(hObject,eventdata,handles);

%-------------------------------------------------
%update all GUI objects based on current group settings
function update_gui(hObject, eventdata, handles)

groups = getappdata(handles.plsdagui,'groups');
classdesc = getappdata(handles.plsdagui,'classdesc');

mydsT = getappdata(handles.plsdagui,'mydataset');
% cls_strT = getappdata(handles.plsdagui,'classdesc');
% clsT = getappdata(handles.plsdagui,'uniqueclass');
classsetT = getappdata(handles.plsdagui,'classset');

desc = {};
usedgroups = setdiff(unique(groups),0);
for j=1:length(usedgroups);
  %create text to describe this group
  sel = find(groups==usedgroups(j));
  sel_text = str2cell(classdesc(sel,:));
  sel_text = ['[ ' sprintf('%s ',sel_text{:}) ']'];
  desc{j} = sel_text;
end
val = get(handles.grouplist,'value');
set(handles.grouplist,'string',desc,'value',max(1,min(length(desc),val)));

lookup = find(groups==0);
unused = classdesc(lookup,:);
setappdata(handles.classlist,'lookup',lookup);
set(handles.classlist,'string',unused,'value',min(val,size(unused,1)));

%set button status
if isempty(lookup)
  en = 'off';
else
  en = 'on';
end
set(handles.group,'enable',en)

if isempty(usedgroups)
  en = 'off';
else
  en = 'on';
end
set(handles.ungroup,'enable',en)
set(handles.renamebtn, 'enable', en)
set(handles.newbtn,'enable',en)

% --------------------------------------------------------------------
function help_Callback(hObject, eventdata, handles)
% hObject    handle to help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

evrihelp('plsda_class_groups_interface')


% --- Executes on selection change in classsetmenu.
function classsetmenu_Callback(hObject, eventdata, handles)
% hObject    handle to classsetmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns classsetmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from classsetmenu

classindex  = get(handles.classsetmenu,'userdata');
classset    = classindex(get(handles.classsetmenu,'value'));
myds        = getappdata(handles.plsdagui,'mydataset');
oldclassset = getappdata(handles.plsdagui,'classset');

%Pull class out of table into vector.
cls = unique(myds.class{1,classset})';
cls(~isfinite(cls)) = []; %drop non-finite values

mytbl = myds.classlookup{1,classset};
mytbl = mytbl(ismember([mytbl{:,1}],cls),:);

cls_str = char(mytbl{:,2});

setappdata(handles.plsdagui,'classdesc',cls_str);
setappdata(handles.plsdagui,'uniqueclass',cls);
setappdata(handles.plsdagui,'classset',classset)

groups = zeros(1,size(cls,1));
setappdata(handles.plsdagui,'defaultgroups',groups);
setappdata(handles.plsdagui,'groups',groups)

update_gui(hObject, eventdata, handles);


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


% --- Executes on button press in newbtn.
function newbtn_Callback(hObject, eventdata, handles, varargin)
% hObject    handle to newbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

mydsT = getappdata(handles.plsdagui,'mydataset');
class_strT = getappdata(handles.plsdagui,'classdesc');
classT = getappdata(handles.plsdagui,'uniqueclass');
grps = getappdata(handles.plsdagui,'groups');
%fromOKButton = varargin{1};
if ~iscolumn(grps)
  grps = grps';
end
classSet = getappdata(handles.plsdagui,'classset');
newClassNames = get(handles.grouplist, 'string');
if ~isempty(varargin)
  numberofClassSets = length(mydsT.class(1,:));
  newClassSetName = ['Class Set ' num2str(numberofClassSets + 1) ' for KNN'];
else
  newClassSetName = inputdlg(['Enter name for new Class Set:'], 'Create New Class Set', [1 50], {''});
  if isempty(newClassSetName)
    return
  end
  if isempty(newClassSetName{1})
    evriwarndlg('Please enter a new class set name.', 'Class Set Name');
    return
  end
end

mydsT.classname{1,end+1} = newClassSetName;

newClassNames_cell = cell(size(mydsT,1),1);

for bb = 1:size(classT,1)
  clsNumOG = classT(bb,1);
  clsIndsOG = find(mydsT.class{1,classSet}==clsNumOG);
  clsNumNew = grps(bb,1);
  if clsNumNew == 0
    clsNameNew = 'Class 0';
  else
    clsNameNew = newClassNames{clsNumNew,:};
  end
  newClassNames_cell(clsIndsOG) = repmat({clsNameNew},size(clsIndsOG,1),1);
end
mydsT.classid{1,end} = newClassNames_cell;
curanal = getappdata(handles.plsdagui, 'curanal');
if strcmp(curanal, 'knn')
  classSetToUseForKNN = length(mydsT.class(1,:));
else
  classSetToUseForKNN = [];
end
setappdata(handles.plsdagui, 'modDSO', mydsT);
setappdata(handles.plsdagui, 'classSetForKNN', classSetToUseForKNN);

% --- Executes on button press in renamebtn.
function renamebtn_Callback(hObject, eventdata, handles)
% hObject    handle to renamebtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

group_text = get(handles.grouplist,'string');
sel = get(handles.grouplist,'value');
newName = inputdlg(['Enter new name for group:'], 'New Name for Group', [1 50], {''});
if isempty(newName)
  return
end
if isempty(newName{1})
  evriwarndlg('Please enter a new group name.', 'Group Name');
  return
end
group_text{sel} = newName{1};
set(handles.grouplist, 'string', group_text);

% --- Executes on button press in helpbtn.
function helpbtn_Callback(hObject, eventdata, handles)
% hObject    handle to helpbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

evrihelp('plsda_class_groups_interface')
