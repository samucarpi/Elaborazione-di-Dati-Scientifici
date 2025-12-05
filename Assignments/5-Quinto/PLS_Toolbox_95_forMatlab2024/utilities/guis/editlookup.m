function varargout = editlookup(varargin)
%EDITLOOKUP Edit a class lookup table.
%  Input 'oldTable' is a lookup table (nx2 cell array), 'oldClass' is the
%  numeric class vector corresponding to 'oldTable', and 'targfig' is parent
%  figure to center on.
%
%I/O: [newTable,newClass] = editlookup(oldTable,oldClass,targfig);
%
%See also:

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Change first input to

if strcmp(getappdata(0,'debug'),'on');
  dbstop if all error
end

try
  if ischar(varargin{1})&& ismember(lower(varargin{1}),evriio([],'validtopics'))
    options = [];
    if nargout==0
      evriio(mfilename,varargin{1},options)
    else
      varargout{1} = evriio(mfilename,varargin{1},options);
    end
    return;
  else
    if iscell(varargin{1})
      %Initial call.
      [varargout{1:nargout}] = guirun(varargin{:});
    elseif nargout == 0;
      %normal calls with a function
      feval(varargin{:}); % FEVAL switchyard
    else
      [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    end
  end
catch
  if ~isempty(gcbf);
    set(gcbf,'pointer','arrow');  %no "handles" exist here so try setting callback figure
  end
  erdlgpls(lasterr,[upper(mfilename) ' Error']);
end

%--------------------------------------------------------------
function [newtbl,newcls] = guirun(oldtbl,oldcls,targfig)

%Check size.
if size(oldtbl,2)~=2
  error('Table must be size nx2.');
end

%TODO: Need two inputs for delete button to work.
if nargin < 2
  oldcls = [];
end

if nargin < 3
  targfig = [];
end

fig = figure( 'Name','Edit Class Lookup Table',...
  'MenuBar','none',...
  'Tag','editlookup',...
  'Units','pixels',...
  'Position',[200 200 500 200],...
  'Resize','on',...
  'NumberTitle','off');%'ResizeFcn','editlookup(''resize_callback'',gcbo,[],guidata(gcbo))',...%,...

%Save orginal data.
setappdata(fig,'originaltable',oldtbl);
setappdata(fig,'currenttable',oldtbl);

setappdata(fig,'originalclass',oldcls);
setappdata(fig,'currentclass',oldcls);

%Center figure over parent or use pos manager.
if ~isempty(targfig)
  centerfigure(fig,targfig)
else
  positionmanager(fig,'editlookup');
end

%Create list box.
hlst = uicontrol(fig,'Style', 'listbox',...
  'Tag','listtable',...
  'String', '',...
  'FontName','Courier',...
  'FontSize',getdefaultfontsize,...
  'Units','pixels',...
  'Callback', 'editlookup(''listtable_Callback'',gcbo,[],guidata(gcbo))',...
  'tooltip','Right click to display copy/paste menu.');

%Create Labels
lbls = {'listlabel' 'classnamelabel' 'classvaluelabel'};
lstr = {'Class        Members            Name' ...
  'Class Name:' ...
  'Class Value:'};
for i = 1:length(lbls)
  hlbl = uicontrol(fig,'Style', 'text',...
    'Tag',lbls{i},...
    'BackgroundColor',get(fig,'color'),...
    'HorizontalAlignment','left',...
    'Fontweight','bold',...
    'FontSize',getdefaultfontsize,...
    'String', lstr{i},...
    'Units','pixels');
  if strcmp(lbls{i},'listlabel')
    set(hlbl,'FontName', 'Courier')
  end
end

%Create Edit Boxes
lbls = {'classname' 'classvalue'};

for i = 1:length(lbls)
  hlbl = uicontrol(fig,'Style', 'edit',...
    'Tag',lbls{i},...
    'BackgroundColor',[1 1 1],...
    'HorizontalAlignment','left',...
    'Fontweight','normal',...
    'FontSize',getdefaultfontsize,...
    'Units','pixels',...
    'Callback', 'editlookup(''btn_callback'',gcbo,[],guidata(gcbo))',...
    'tooltip','Hit [return] or click update to make changes.');
end

%Create Buttons
lbls = {'updatebtn' 'deletebtn' 'okbtn' 'cancelbtn' 'resetbtn'};
lstr = {'Update' ...
  'Delete' ...
  'OK' ...
  'Cancel' ...
  'Reset'};
for i = 1:length(lbls)
  hlbl = uicontrol(fig,'Style', 'pushbutton',...
    'Tag',lbls{i},...
    'BackgroundColor',get(fig,'color'),...
    'Fontweight','normal',...
    'FontSize',getdefaultfontsize,...
    'String', lstr{i},...
    'Units','pixels',...
    'Callback', ['editlookup(''' lbls{i} '_Callback'',gcbo,[],guidata(gcbo))']);
end

%Add context menu.
cmenu = uicontextmenu('Parent',fig,'Position',[10 215]);
uimenu(cmenu, 'Label', 'Copy','Callback','editlookup(''copy_callback'',gcbo,[],guidata(gcbo))')
uimenu(cmenu, 'Label', 'Paste','Callback','editlookup(''paste_callback'',gcbo,[],guidata(gcbo))')
set(hlst,'UIContextMenu', cmenu);

updatelisttable(guihandles(fig))

%Set value of list table so isn't confusing with initial 0 value.
set(hlst,'value',1)
listtable_Callback(hlst, [], []);

%Set resize function here so doesn't get called on creation of figure
%before controls are created.
set(fig,'ResizeFcn','editlookup(''resize_callback'',gcbo,[],guidata(gcbo))')
resize_callback(fig,[],guidata(fig))

newtbl = [];

try
  uiwait(fig); %uiresume called in optionsgui.m
catch
  uiresume(fig)
end

if ishandle(fig)
  handles = guihandles(fig);
  %Save figure position.
  positionmanager(fig,'editlookup','set')
else
  handles = [];
end

if ~isempty(handles) && ishandle(handles.editlookup)
  if nargout > 0 && ishandle(handles.editlookup)
    newtbl = getappdata(handles.editlookup,'currenttable');
    newcls = getappdata(handles.editlookup,'currentclass');
  end
  delete(handles.editlookup)
else
  newtbl = [];
  newcls = [];
end

% if nargout == 0
clear fig

%--------------------------------------------------------------
function listtable_Callback(hObject, eventdata, handles)
%Update the edit boxes with selection.
val = get(hObject,'value');
mystr = get(hObject,'String');

handles = guihandles(hObject);

if val == length(mystr)
  %User creating new class.
  set(handles.classname,'String','');
  set(handles.classvalue,'String','');
  if checkmlversion('>','6.5')
    %Give focus to name field.
    uicontrol(handles.classname);
  end
else
  curtbl = getappdata(handles.editlookup,'currenttable');
  set(handles.classname,'String',curtbl{val,2});
  set(handles.classvalue,'String',num2str(curtbl{val,1}));
end
%--------------------------------------------------------------
function btn_callback(hObject, eventdata, handles)
%Callback for button click or [return] on edit box.

handles = guihandles(hObject);

%Get ctrl values.
newclsname = get(handles.classname,'String');
val = get(handles.classvalue,'String');
newclsnum = str2num(val);

if isempty(newclsname) || isempty(newclsnum)
  return
end

%Figure out if user is adding new class or updating an existing class.
curlistval = get(handles.listtable,'value');
curliststr = get(handles.listtable,'String');
if curlistval == length(curliststr)
  %User creating new class.
  action = 'add';
else
  %Edit existing class.
  action = 'update';
end

%Check for special actions.
ctrl = get(hObject,'tag');
if strcmp(ctrl,'deletebtn')
  %User delete.
  action = 'delete';
elseif strcmp(ctrl,'resetbtn')
  %Reset.
  action = 'reset';
end

%Current table and class.
curtbl = getappdata(handles.editlookup,'currenttable');
curcls = getappdata(handles.editlookup,'currentclass');

switch action
  case 'delete'
    %If deleting, need to assign a new class number in place of the class
    %that's being deleted.
    if ~isempty(curcls)
      if curlistval == length(curliststr)
        %User hit delete while adding new class so just clear values.
        set(handles.classname,'String','');
        set(handles.classvalue,'String','');
        return
      else
        if curtbl{curlistval,1}==0
          button = evriquestdlg(['Deleting class 0 (unknown) may affect '...
            'plotting and other behavior. Are you want to delete class 0?'],...
            'Delete Class 0','Yes','Cancel','Yes');
          if strcmp(button,'Cancel')
            return
          end
        end
        %If there are no members proceed straight to delete.
        mems = sum(curcls==curtbl{curlistval,1});
        if mems>0
          existingclsvals = updatelisttable(handles,1);%get list string
          %Remove current selection.
          existingclsvals = [existingclsvals(1:curlistval-1,:); existingclsvals(curlistval+1:end,:)];
          
          if isempty(existingclsvals)
            %If this is empty then user has emptied the list.
            curcls = [];
          else
            %Build temp table with selection removed.
            temptbl = [curtbl(1:curlistval-1,:); curtbl(curlistval+1:end,:)];
            %Show dialog.
            [slctindx,ok] = listdlg('PromptString','Merge class members into:',...
              'SelectionMode','single',...
              'ListString',existingclsvals);
            if ok
              %Reassign classes and save to appdata.
              curcls(curcls==newclsnum) = temptbl{slctindx,1};
            else
              %User cancel.
              return
            end
          end
        end
      end
    end

    curtbl = [curtbl(1:curlistval-1,:); curtbl(curlistval+1:end,:)];
    %Set list value.
    if curlistval - 1<=0
      curlistval = 1;
    else
      curlistval = curlistval-1;
    end
    set(handles.listtable,'Value',curlistval);

  case 'add'
    %Make sure numeric value doesn't already exist.
    if ismember(newclsnum,[curtbl{:,1}])
      evriwarndlg(['Unable to create numeric class: ' val '. Class already exists.'], 'Duplicate Numeric Class Warning');
      if checkmlversion('>','6.5')
        uicontrol(handles.classvalue); %Move focus to value edit box.
      end
      return
    end

    %Add the new class to the bottom of the list, will get sorted below.
    curtbl(end+1,:) = {newclsnum newclsname};

  case 'update'
    %Make sure a new numeric value doesn't already exist. Existing sting
    %is OK, may be updating name of class.
    if curtbl{curlistval,1}~=newclsnum && ismember(newclsnum,[curtbl{:,1}])
      evriwarndlg(['Unable to create numeric class: ' val '. Class already exists.'], 'Duplicate Numeric Class Warning');
      uicontrol(handles.classvalue); %Move focus to value edit box.
      return
    end

    if curtbl{curlistval,1}~=newclsnum 
      %Changing to new class number. Need to change members to new class.
      curcls(curcls==curtbl{curlistval,1}) = newclsnum;
    end
    
    %Update table with changes.
    curtbl(curlistval,:) = {newclsnum newclsname};

  case 'reset'
    %Reset to orginal data stored in appdata of figure.
    curtbl = getappdata(handles.editlookup,'originaltable');
    curcls = getappdata(handles.editlookup,'originalclass');
end

%Sort table by class number and save.
indx = cell2mat(curtbl(:,1));
[junk indx] = sort(indx);
curtbl = curtbl(indx,:);

%Save current data.
setappdata(handles.editlookup,'currenttable',curtbl);
setappdata(handles.editlookup,'currentclass',curcls);

%Update
updatelisttable(handles)

%Call table cb to update edit boxes.
listtable_Callback(handles.listtable, [], handles);
%--------------------------------------------------------------
function addnewbtn_Callback(hObject, eventdata, handles)
btn_callback(hObject, [], guihandles(hObject));

%--------------------------------------------------------------
function updatebtn_Callback(hObject, eventdata, handles)
btn_callback(hObject, [], guihandles(hObject));

%--------------------------------------------------------------
function deletebtn_Callback(hObject, eventdata, handles)
btn_callback(hObject, [], guihandles(hObject));

%--------------------------------------------------------------
function okbtn_Callback(hObject, eventdata, handles)

if isempty(handles)
  handles = guihandles(hObject);
end

% %Check if any numeric classes don't have IDs.
% missingcls = checkcls(handles);
%
% if ~isempty(missingcls)
%   %If numeric classes don't have id's in lookup table then need to handle.
%   button =  evriquestdlg('You have numeric classes without IDs. Do you wish to continue editing? If no, ','title','str1','str2','str3','default')
% else
uiresume(handles.editlookup);
%end

%--------------------------------------------------------------
function cancelbtn_Callback(hObject, eventdata, handles)

if isempty(handles)
  handles = guihandles(hObject);
end

%Save figure position.
positionmanager(handles.editlookup,'editlookup','set')

setappdata(handles.editlookup,'currenttable',[]);
uiresume(handles.editlookup)

if ishandle(handles.editlookup)
  delete(handles.editlookup)
end
%--------------------------------------------------------------
function resetbtn_Callback(hObject, eventdata, handles)
btn_callback(hObject, [], guihandles(hObject));

%--------------------------------------------------------------
function lstrtn = updatelisttable(handles,listreturn)
%Update list, 'listreturn' governs if and how to retrun the list. If
%listreturn = 1, return classnumber/classname list for use with listbox
%dialog.

if nargin<2
  %Normal update of list.
  listreturn = 0;
end

curtbl = getappdata(handles.editlookup,'currenttable');
curcls = getappdata(handles.editlookup,'currentclass');

%Create display string.
dispstr = '';
for i = 1:size(curtbl,1)
  %Class number
  cnum = num2str(curtbl{i,1});
  pad1 = repmat(' ', [1 12 - length(cnum)]);

  %Number of members.
  mems = num2str(sum(curcls==curtbl{i,1}));
  pad2 = repmat(' ', [1 19 - length(mems)]);

  if listreturn
    dispstr = [dispstr; {[cnum pad1 curtbl{i,2}]}];
  else
    dispstr = [dispstr; {[' ' cnum pad1 mems pad2 curtbl{i,2}]}];
  end
end

if listreturn
  lstrtn = dispstr;
else
  dispstr = [dispstr; {' New Class...'}];
  set(handles.listtable,'String',dispstr);
end


%--------------------------------------------------------------
function resize_callback(h,eventdata,handles,varargin)
%Resize behavior for gui. Only expand list box.

handles = guihandles(h);

figpos = get(handles.editlookup,'position');
%Min pos [200 200 450 300] [left bottom width height]

fwidth = figpos(3);
fheight = figpos(4);

if fwidth<500
  fwidth = 500;
end

if fheight<200
  fheight = 200;
end

%Area to right of listbox.
ctrlarea = 240;

set(handles.listtable,'position',[5 80 (fwidth-5) (fheight-102)])
set(handles.listlabel,'position',[5 (fheight-20) (fwidth-5) 16])

set(handles.classnamelabel,'position',[5 50 95 20])
set(handles.classvaluelabel,'position',[5 30 95 20])
set(handles.classname,'position',[101 50 (fwidth-103) 20])
set(handles.classvalue,'position',[101 30 (fwidth-103) 20])

%set(handles.addnewbtn,'position',[5 5 75 20])
set(handles.updatebtn,'position',[5 5 85 22])
set(handles.deletebtn,'position',[91 5 85 22])

set(handles.okbtn,'position',[(fwidth-260) 5 85 22])
set(handles.cancelbtn,'position',[(fwidth-174) 5 85 22])
set(handles.resetbtn,'position',[(fwidth-88) 5 85 22])

%--------------------------------------------------------------
function copy_callback(h,eventdata,handles,varargin)
%Copy current lookup table so can edit (in excel).

if isempty(handles)
  handles = guihandles(h);
end

curtbl = getappdata(handles.editlookup,'currenttable');
%Change numbers to strings and transpose so sprintf command will work.
ptbl = [str2cell(num2str([curtbl{:,1}]')) curtbl(:,2)]';
ptbl = sprintf('%s\t%s\n',ptbl{:});
clipboard('copy',ptbl);

%--------------------------------------------------------------
function paste_callback(h,eventdata,handles,varargin)
%Paste lookup table from clipboard.

if isempty(handles)
  handles = guihandles(h);
end

val      = clipboard('paste');
if isempty(val); return; end;  %nothing interpretable in clipboard

val = str2cell(val);

if size(val,2)~=2
  error('Unable to paste value. Check to see list is tab delimited and size nx2 (e.g., copied from Excel).')
end

clsnum = str2num(cell2mat(val(:,1)));
val(:,1) = num2cell(clsnum);

%TODO: Test incoming table.

%Set to curtable and display
setappdata(handles.editlookup,'currenttable',val)

%Update
updatelisttable(handles)

