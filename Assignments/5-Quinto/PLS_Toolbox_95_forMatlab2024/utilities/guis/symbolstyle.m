function varargout = symbolstyle(varargin)
% SYMBOLSTYLE M-file for symbolstyle.fig
%      SYMBOLSTYLE, by itself, creates a new SYMBOLSTYLE or raises the existing
%      singleton*.
%
%      H = SYMBOLSTYLE returns the handle to a new SYMBOLSTYLE or the handle to
%      the existing singleton*.
%
%      SYMBOLSTYLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SYMBOLSTYLE.M with the given input arguments.
%
%      SYMBOLSTYLE('Property','Value',...) creates a new SYMBOLSTYLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before symbolstyle_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to symbolstyle_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Edit the above text to modify the response to help symbolstyle

% Last Modified by GUIDE v2.5 20-Sep-2010 16:41:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @symbolstyle_OpeningFcn, ...
                   'gui_OutputFcn',  @symbolstyle_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
  if ismember(varargin{1},evriio([],'validtopics'));
    options = [];
    options.coloronly = false;
    if nargout==0; clear out; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return;
  end
  gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before symbolstyle is made visible.
function symbolstyle_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to symbolstyle (see VARARGIN)

% Choose default command line output for symbolstyle
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

positionmanager(handles.symbolstyle,'symbolstyle');

%initialize symbol set
markerlist = getmarkerlist;

if ~isempty(varargin) & isstruct(varargin{1})
  options = varargin{1};
  varargin = varargin(2:end);
else
  options = [];
end
options = reconopts(options,mfilename);

if ~isempty(varargin) & ischar(varargin{1}) & strcmpi(varargin{1},'coloronly')
  options.coloronly = true;    %set color only flag
  varargin = varargin(2:end);  %and drop it from inputs
end
if ~options.coloronly
  %symbol and color
  setname = 'default';
  index   = 1;
else
  %color only
  setname = setfromcolors(classcolors);
  index = 1;
end

if length(varargin)>1
  index   = varargin{1};
  setname = varargin{2};
  if isempty(index)
    index = 1;
  end
elseif length(varargin)==1
  if ischar(varargin{1});
    setname = varargin{1};
  elseif isnumeric(varargin{1}) & numel(varargin{1})==1
    index = varargin{1};
  end    
end

if ischar(setname) | isempty(setname)
  %gave name to look up
  symbolset = classmarkers(setname);
else
  %gave actual symbol set
  symbolset = setname;
  setname = '';
end

if index>length(symbolset)
  %not enough symbols in the set for the index supplied? replicate to need 
  symbolset = repmat(symbolset,ceil(index/length(symbolset)),1);
end

setappdata(handles.symbolstyle,'oringialsymbolset',symbolset)
setappdata(handles.symbolstyle,'symbolset',symbolset)
setappdata(handles.symbolstyle,'setname',setname)
setappdata(handles.symbolstyle,'changed',false)

iscoloronly = getappdata(handles.symbolstyle,'iscoloronly');
if options.coloronly
  set([handles.marker handles.size handles.facecolor handles.noedge handles.noface handles.sizetext handles.markertext],'enable','off','visible','off');
  set(handles.edgecolor,'string','Set Color');
  set(handles.symboledittext,'String','Color Order')
  set(handles.symbolstyle,'Name','Set Color Order')
   if isempty(iscoloronly) | ~iscoloronly
     colorOrderPos = handles.symboledittext.Position(2);
     reorderTextPos = handles.reordertext.Position;
     set(handles.reordertext, 'Position', [reorderTextPos(1) ...
       colorOrderPos-71.64 reorderTextPos(3) reorderTextPos(4)]);
     
     moveUpPos = handles.moveup.Position;     
     set(handles.moveup, 'Position', [moveUpPos(1) ...
       colorOrderPos-74.64 moveUpPos(3) moveUpPos(4)]);
     
     moveDownPos = handles.movedown.Position;
     set(handles.movedown, 'Position', [moveDownPos(1) ...
       colorOrderPos-74.64 moveDownPos(3) moveDownPos(4)]);
     
     edgeColorPos = handles.edgecolor.Position;
     set(handles.edgecolor, 'Position', [158.500 ...
       colorOrderPos-34.64 edgeColorPos(3) edgeColorPos(4)]);
%     remapfig([0 0 1 1],[0 .2 1 1],handles.symbolstyle,[handles.reordertext handles.moveup handles.movedown])
%     remapfig([0 0 1 1],[.13 .2 1 1],handles.symbolstyle,[handles.edgecolor])
   end
else
  if ~isempty(iscoloronly) & iscoloronly
    erdlgpls('Dialog must be closed to switch back to symbol edit mode','Color Only Mode Locked')
    options.coloronly = true;
  end
end
setappdata(handles.symbolstyle,'iscoloronly',options.coloronly)
setappdata(handles.symbolstyle,'options',options)

%initialize controls
set(handles.marker,'string',markerlist(:,2));
set(handles.size,'string',[{'auto'} str2cell(num2str([1:20]'))'])
selectsymbol(handles.symbolstyle,[],handles,index)

set(handles.symbolstyle,'keypressfcn','symbolstyle(''symbolstyle_keypressfcn'',gcbf,[],guidata(gcbf))')

set(handles.symbolstyle,'closerequestfcn',@mycloserequestfcn)


% --- Outputs from this function are returned to the command line.
function varargout = symbolstyle_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure

if nargout>0
  %output requested, wait for OK, Cancel, or close
  setappdata(handles.symbolstyle,'waiting',true);
  uiwait(handles.symbolstyle);  
  if isstruct(handles) & ishandle(handles.symbolstyle)
    varargout = {getappdata(handles.symbolstyle,'symbolset')};
    symbolstyle_CloseFcn(handles.symbolstyle)
  else
    %figure was closed
    varargout = cell(1,nargout);
  end
else
  %no ouputs - flag that exit should handle closing themselves
  setappdata(handles.symbolstyle,'waiting',false);
end

%--------------------------------------------------------
function symbolstyle_CloseFcn(fig)
%handle close actions

positionmanager(fig,'symbolstyle','set');
close(fig);


%--------------------------------------------------------
function list = getmarkerlist

list = {
  '.' 'Point'
  'o' 'Circle  o'
  'x' 'X-mark  x'
  '+' 'Plus  +'
  '*' 'Star  *'
  's' 'Square'
  'd' 'Diamond'
  'v' 'V Triangle (down)'
  '^' '^ Triangle (up)'
  '<' '< Triangle (left)'
  '>' '> Triangle (right)'
  'p' 'Pentagram'
  'h' 'Hexagram'};

%-------------------------------------------------------
function plotsymbols(handles)
%plot current set of symbols and colors

sym = getappdata(handles.symbolstyle,'symbolset');
selectedsymbol = getappdata(handles.symbolstyle,'selectedsymbol');

ax = get(handles.symbollist,'ylim');
options = getappdata(handles.symbolstyle,'options');

cla
hold on
for j=0:length(sym)-1;
  eclr = sym(j+1).edgecolor;
  fclr = sym(j+1).facecolor;
  if isempty(eclr) & isempty(fclr)
    %both empty? black w/white face
    fclr = [1 1 1];
    eclr = [0 0 0];
  elseif isempty(eclr) & ~isempty(fclr)
    %no edge color? same as face
    eclr = fclr;
  elseif isempty(fclr)
    %no face color? white face
    fclr = [1 1 1];
  end
  sz = sym(j+1).size;
  mkr = sym(j+1).marker;
  
  if options.coloronly
    mkr = 's';
    sz = 10;
    fclr = eclr;
  end
  
  try
    h = plot(.5,j,'marker',mkr,'MarkerFaceColor',fclr,'MarkerEdgeColor',eclr);
  catch
    h = plot(.5,j,'marker','o','MarkerFaceColor',[1 1 1],'MarkerEdgeColor',[0 0 0]);
  end
  set(h,'userdata',j+1,'buttondownfcn','symbolstyle(''selectsymbol'',gcbf,[],guidata(gcbf),get(gcbo,''userdata''),gcbo)')
  if ~isempty(sz)
    set(h,'markersize',sz)
  end
  
  if ismember(j+1,selectedsymbol)
    plot(.1,j,'marker','>','markersize',8,'markeredgecolor','k','MarkerFaceColor','k');
    plot(.9,j,'marker','<','markersize',8,'markeredgecolor','k','MarkerFaceColor','k');
  end  
end
hold off
set(handles.symbollist,'ydir','reverse','ytick',0:length(sym)-1);
axis([0 1 max(-1,ax(1)) length(sym)-1]);
set(handles.symbollist,'buttondownfcn','symbolstyle(''selectsymbol'',gcbf,[],guidata(gcbf),[],gcbo)')
updatescroll(handles)

%--------------------------------------------
function updatescroll(handles)
%make sure axes doesn't show too many items (add up/down scroll as
%necessary)

axpos = get(handles.symbollist,'position');
sym   = getappdata(handles.symbolstyle,'symbolset');
nsym  = length(sym);
maxsize = [];
if ~isempty(sym)
  %get symbol sizes
  maxsize = max([10 max([sym.size])]);
end
if isempty(maxsize)
  %no symbols yet (or no sizes), use default
  maxsize = 10;
end
maxsymbols = round(axpos(4)/(maxsize+7));
if maxsymbols == 0
  maxsymbols = 1;
end

ax = get(handles.symbollist,'ylim');
ax = ax+1;   %correction for zero-index
if ax(2)-ax(1)>maxsymbols
  ax(2) = ax(1)+maxsymbols;
end

%now check if selected symbol is in range
index = getappdata(handles.symbolstyle,'selectedsymbol');
if ~isempty(index) & ( (index(1)+2)>ax(2) | (index(1)-2)<ax(1) | (ax(2)-ax(1))<maxsymbols )
  ax(1) = index(1)-(maxsymbols/2);
  ax(2) = index(1)+(maxsymbols/2);
end
 
%make sure everything is on-scale
if ax(2)>nsym
  ax = nsym-[maxsymbols+1 -1];
end
if ax(1)<0
  ax = [0 maxsymbols];
end

ax = ax-1;  %correct for zero-index
set(handles.symbollist,'ylim',ax);

%add up and down arrows at top or bottom if more are present
h = findobj(handles.symbollist,'tag','moreindicator');
if ~isempty(h); delete(h); end
hold on
if ax(1)+1>1
  h = plot(0.05,ax(1)+.05,'r^');
  set(h,'buttondownfcn','symbolstyle(''selectsymbol'',gcbf,[],guidata(gcbf),[],gcbo)','tag','moreindicator','markerfacecolor','r')
end
if ax(2)+1<nsym
  h = plot(0.05,ax(2)-.05,'rv');
  set(h,'buttondownfcn','symbolstyle(''selectsymbol'',gcbf,[],guidata(gcbf),[],gcbo)','tag','moreindicator','markerfacecolor','r')
end
hold off

%--------------------------------------------
function selectsymbol(hObject, eventdata, handles, varargin)
%select a given symbol in the list

symset = getappdata(handles.symbolstyle,'symbolset');
if nargin>3 & ~isempty(varargin{1});
  index = varargin{1};
else
  pos = round(get(gca,'currentpoint'));
  index = pos(1,2)+1;
end
index(index>length(symset)) = length(symset);
index(index<1) = 1;
index = unique(index);

if nargin>4
  %passed in object they clicked on? Check for 'extend' action
  switch get(handles.symbolstyle,'selectiontype')
    case 'alt'
      %just add the last click to the set
      oldindex = getappdata(hObject,'selectedsymbol');
      index = union(index,oldindex);
    case 'extend'
      %extend from nearest selected item to where they clicked
      oldindex = getappdata(hObject,'selectedsymbol');
      [fwhat,fwhere] = min(abs(oldindex-index));  %find closest item
      toadd = sort([index oldindex(fwhere)]);     %put in order to create vector
      index = union(toadd(1):toadd(2),oldindex);    %add from that item to one clicked
  end
end
%store new index
setappdata(hObject,'selectedsymbol',index);

%update plot
plotsymbols(handles);

%update marker pulldown menu
sym = getsymbolstyle(handles);
if isempty(sym)
  return
end
sym = sym(1);  %make sure we look at only the FIRST selected item

markerlist = getmarkerlist;
mindex = find(ismember(markerlist(:,1),sym.marker));
if length(mindex)~=1
  mindex = 1;
end
set(handles.marker,'value',mindex);
updatefacebutton(handles);

if isempty(sym.size)
  sindex = 1;
else
  sindex = sym.size+1;
  if sindex>21
    sindex = 21;
  end
end
set(handles.size,'value',sindex)


%check for non-colors
if isempty(sym.facecolor) | all(sym.facecolor==[1 1 1])
  noface = 1;
else
  noface = 0;
end
set(handles.noface,'value',noface)

if isempty(sym.edgecolor) | (length(sym.facecolor)==length(sym.edgecolor) & all(sym.facecolor==sym.edgecolor))
  noedge = 1;
else
  noedge = 0;
end
set(handles.noedge,'value',noedge)

%-----------------------------------------------------------
function sym = getsymbolstyle(handles,index)

sym = getappdata(handles.symbolstyle,'symbolset');
if nargin<2
  index = getappdata(handles.symbolstyle,'selectedsymbol');
end
if index>length(sym) | index<1
  sym = struct([]);
  return
end
sym = sym(index);

%-----------------------------------------------------------
function sym = setsymbolstyle(handles,newsym)

sym = getappdata(handles.symbolstyle,'symbolset');
index = getappdata(handles.symbolstyle,'selectedsymbol');
if index<1
  return
end
sym(index) = newsym;
setappdata(handles.symbolstyle,'symbolset',sym);
setappdata(handles.symbolstyle,'changed',true)

%---------------------------------------------------------
function updatefacebutton(handles)

mindex = get(handles.marker,'value');
markerlist = getmarkerlist;
options = getappdata(handles.symbolstyle,'options');
if ismember(markerlist{mindex,1},['.x+*']) | options.coloronly
  %these markers do NOT allow face colors
  enable = 'off';
else
  %otherwise, enable button as normal
  enable = 'on';
end
set([handles.facecolor handles.noface],'enable',enable);

% --- Executes on selection change in marker.
function marker_Callback(hObject, eventdata, handles)
% hObject    handle to marker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns marker contents as cell array
%        contents{get(hObject,'Value')} returns selected item from marker

sym = getsymbolstyle(handles);
markerlist = getmarkerlist;
mindex = get(handles.marker,'value');
[sym(:).marker] = deal(markerlist{mindex,1});
setsymbolstyle(handles,sym);
plotsymbols(handles)
updatefacebutton(handles)


% --- Executes during object creation, after setting all properties.
function marker_CreateFcn(hObject, eventdata, handles)
% hObject    handle to marker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in facecolor.
function facecolor_Callback(hObject, eventdata, handles)
% hObject    handle to facecolor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns facecolor contents as cell array
%        contents{get(hObject,'Value')} returns selected item from facecolor

sym = getsymbolstyle(handles);

clr = sym.facecolor;
if isempty(clr)
  clr = [1 1 1];
end
clr = uisetcolor(clr);

if all(clr==[1 1 1])
  %white? same as "no color"
  clr = [];
elseif ~isempty(clr) & ~isempty(sym(1).edgecolor) & all(clr==sym(1).edgecolor)
  %edge matches new face value? drop edge setting
  [sym(:).edgecolor] = deal([]);
  set(handles.noedge,'value',1);
end
[sym(:).facecolor] = deal(clr);
setsymbolstyle(handles,sym);

plotsymbols(handles)
set(handles.noface,'value',isempty(clr));

% --- Executes during object creation, after setting all properties.
function facecolor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to facecolor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in edgecolor.
function edgecolor_Callback(hObject, eventdata, handles)
% hObject    handle to edgecolor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns edgecolor contents as cell array
%        contents{get(hObject,'Value')} returns selected item from edgecolor


sym = getsymbolstyle(handles);

clr = sym.edgecolor;
if isempty(clr)
  if isempty(sym(1).facecolor)
    clr = [0 0 0];
  else
    clr = sym(1).facecolor;
  end
end
clr = uisetcolor(clr);
if ~isempty(clr) & all(clr==[1 1 1]);
  clr = [];
end
[sym(:).edgecolor] = deal(clr);

setsymbolstyle(handles,sym);
plotsymbols(handles)
set(handles.noedge,'value',isempty(clr));


% --- Executes during object creation, after setting all properties.
function edgecolor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edgecolor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in symbolstyle.
function okbtn_Callback(hObject, eventdata, handles)
% hObject    handle to symbolstyle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(getappdata(gcbf,'closerequested')); 
  close(gcbf); 
else
  if ~getappdata(handles.symbolstyle,'iscoloronly')
    savesymbolset(handles)
  else
    savelinecolors(handles)
  end
  
  if getappdata(handles.symbolstyle,'waiting')
    uiresume(gcbf)
    setappdata(gcbf,'closerequested',1)
  else
    symbolstyle_CloseFcn(handles.symbolstyle)
  end

end

% --- Executes on button press in cancelbtn.
function cancelbtn_Callback(hObject, eventdata, handles)
% hObject    handle to cancelbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%discard all changes
setappdata(handles.symbolstyle,'symbolset',getappdata(handles.symbolstyle,'oringialsymbolset'))
setappdata(handles.symbolstyle,'changed',false)  %do NOT ask to confirm (cancel is assumed NOT saving)
if ~isempty(getappdata(gcbf,'closerequested')); 
  close(gcbf); 
else
  
  if getappdata(handles.symbolstyle,'waiting')
    uiresume(gcbf)
    setappdata(gcbf,'closerequested',1)
  else
    symbolstyle_CloseFcn(handles.symbolstyle)
  end
  
end

% --- Executes on button press in loadset.
function loadset_Callback(hObject, eventdata, handles)
% hObject    handle to loadset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~confirmdiscard(handles); return; end

index = getappdata(handles.symbolstyle,'selectedsymbol');

%create a list of markers
sets = classmarkers('options');
systemsets = fieldnames(classmarkers('factoryoptions'));
list = fieldnames(sets);
list = setdiff(list,'functionname');
list = list(:);

%sort into predefined sets and user-defined
if checkmlversion('<','7.0')
  colorseparator  = '--- Color Sets ---';
  systemseparator = '--- System ---';
  userseparator   = '--- User-Defined ---';
else
  colorseparator  = '<html><font color="#550022"><b>--- Color Sets ---</b></font></html>';
  systemseparator = '<html><font color="#000099"><b>--- System ---</b></font></html>';
  userseparator   = '<html><font color="#009900"><b>--- User-Defined ---</b></font></html>';
end
predefinedsets = ismember(list,systemsets);
list = [{systemseparator};list(predefinedsets);{userseparator};list(~predefinedsets)];
separator  = [1 sum(predefinedsets)+2];  %indicate that "user defined" line is bad

if getappdata(handles.symbolstyle,'iscoloronly')
  %color only? add color sets at top
  [junk,nsets] = classcolors(inf);
  clrlist      = str2cell(sprintf('Color Set %i\n',1:nsets));
  clrlist{end} = [clrlist{end} ' (default)'];
  list         = [{colorseparator};clrlist;list];
  separator    = [1 separator+1+nsets];
end

desc = list;
for j=1:length(desc)
  if checkmlversion('>=','7.0')
    if ismember(desc{j},systemsets)
      desc{j} = sprintf('<html><font color="#000099">%s</font></html>',desc{j});
    else
      desc{j} = sprintf('<html><font color="#009900">%s</font></html>',desc{j});
    end
  end
  desc{j}(desc{j}=='_') = ' ';
end

%let user choose
choice = [];
while isempty(choice) | ismember(choice,separator)
  choice = listdlg('ListString',desc,'Name','Load Set','PromptString','Choose symbol set to load:','SelectionMode','single');
  if isempty(choice)
    return
  end
end
setname = list{choice};

%sort out if this was a color-only set
if getappdata(handles.symbolstyle,'iscoloronly') & choice>1 & choice<=nsets+1
  %one of the color sets
  choice = choice-1;
  symbolset = setfromcolors(classcolors(choice));
else
  %get set and store
  symbolset = classmarkers(setname);
  if index>length(symbolset)
    %not enough symbols in the set for the index supplied? replicate to need
    symbolset = repmat(symbolset,ceil(index/length(symbolset)),1);
  end
end
setappdata(handles.symbolstyle,'symbolset',symbolset)
setappdata(handles.symbolstyle,'changed',false)

%update plot and controls
selectsymbol(handles.symbolstyle,[],handles,1)

%-------------------------------------------------
function   setname = setfromcolors(clrs)

clrs = mat2cell(clrs,ones(size(clrs,1),1),3);
setname = struct('marker','s','edgecolor',clrs,'facecolor',clrs,'size',1);


% --- Executes on button press in saveset.
function saveset_Callback(hObject, eventdata, handles)
% hObject    handle to saveset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

oldsetname = char(getappdata(handles.symbolstyle,'setname'));

%create a list of markers
sets = classmarkers('options');
systemsets = fieldnames(classmarkers('factoryoptions'));
list = fieldnames(sets);
list = setdiff(list,'functionname');

%get user-defined sets only
predefinedsets = ismember(list,systemsets);
list = list(~predefinedsets);
if ~ismember('default',list);
  list = union(list,'default');
end

%convert list into readable format
desc = list(:);
for j=1:length(desc)
  desc{j}(desc{j}=='_') = ' ';
end
if checkmlversion('>=','7.0')
  desc = [desc;{'<html><em>Create New Set...</em></html>'}];
else
  desc = [desc;{'Create New Set...'}];
end

%ask user to choose set to save as (or create new)
choice = listdlg('ListString',desc,'Name','Save Set','PromptString','Save symbol set as:','SelectionMode','single');
if isempty(choice)
  return
end

if choice<=length(list)
  %chose one of the real items (not create new)
  newsetname = list{choice};
else
  %get new set name from user
  for j=1:length(systemsets)
    systemsets{j}(systemsets{j}=='_') = ' ';
  end
  if ismember(oldsetname,systemsets)
    %don't offer system set name as default
    oldsetname = '';
  end
  newsetname = '';
  while isempty(newsetname) | ismember(newsetname,systemsets)
    newsetname = inputdlg({'Enter name for new symbol set'},'Name New Symbol Set',1,{oldsetname});
    if ~isempty(newsetname)
      newsetname = newsetname{1};
    else
      return
    end
    if ismember(newsetname,systemsets)
      evrierrordlg(sprintf('Cannot overwrite system set "%s". Please choose a different name.',newsetname),'Cannot overwrite set');
    end
  end
end

if ~isempty(newsetname)
  try
    savesymbolset(handles,newsetname)
  catch
    evrierrordlg(['Unable to save set as "' newsetname '".' 10 lasterr],'Cannot Save Symbols');
  end
end

% --- Executes on button press in noedge.
function noedge_Callback(hObject, eventdata, handles)
% hObject    handle to noedge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of noedge

sym = getsymbolstyle(handles);
noedge = get(handles.noedge,'value');
if noedge
  [sym(:).edgecolor] = deal([]);
  setsymbolstyle(handles,sym);
  plotsymbols(handles)
else
  edgecolor_Callback(handles.facecolor, [], handles);
end

% --- Executes on button press in noface.
function noface_Callback(hObject, eventdata, handles)
% hObject    handle to noface (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of noface

sym = getsymbolstyle(handles);
noface = get(handles.noface,'value');
if noface
  [sym(:).facecolor] = deal([]);
  setsymbolstyle(handles,sym);
  plotsymbols(handles)
else
  facecolor_Callback(handles.facecolor, [], handles);
end

% --- Executes during object creation, after setting all properties.
function noface_CreateFcn(hObject, eventdata, handles)
% hObject    handle to noface (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(gcbo,'backgroundcolor',get(gcbf,'color'));

% --- Executes during object creation, after setting all properties.
function noedge_CreateFcn(hObject, eventdata, handles)
% hObject    handle to noedge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
set(gcbo,'backgroundcolor',get(gcbf,'color'));


%---------------------------------------------------------------
function confirm = confirmdiscard(handles)
%have user confirm discarding of changes (if changes have been made - if
%not, just return as if they had confirmed discard)

confirm = true;
if getappdata(handles.symbolstyle,'changed')
  isok = evriquestdlg('Discard all changes to current symbol set?','Confirm Discard Changes','Discard','Cancel','Discard');
  if ~ischar(isok) | ~strcmp(isok,'Discard')
    confirm = false;
  end
end

%------------------------------------------------------
function mycloserequestfcn(varargin)
%replacement function for figure close requests - allows interception if
%the user clicks to close the window before results have been saved

handles = guidata(varargin{1});
if confirmdiscard(handles)
  closereq
end

%------------------------------------------------------
function savesymbolset(handles,setname)
%save current symbol set to specified setname

sym = getappdata(handles.symbolstyle,'symbolset');
if nargin<2
  setname = getappdata(handles.symbolstyle,'setname');
end
if ~isempty(setname)
  try
    classmarkers(setname,sym);
    setappdata(handles.symbolstyle,'changed',false)
  catch
    evrierrordlg(['Unable to save to specified set name.' 10 lasterr],'Cannot Save Symbols');
  end
else
  setappdata(handles.symbolstyle,'changed',false)
end

%-----------------------------------------------------
function savelinecolors(handles)

try
  sym = getappdata(handles.symbolstyle,'symbolset');
  setplspref('classcolors','userdefined',cat(1,sym.edgecolor));
  setappdata(handles.symbolstyle,'changed',false)
catch
  evrierrordlg(['Unable to save default colors.' 10 lasterr],'Cannot Save Colors');
end


% --- Executes when symbolstyle is resized.
function symbolstyle_ResizeFcn(hObject, eventdata, handles)
% hObject    handle to symbolstyle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

moveonly = [handles.marker
  handles.instructionstext
  handles.symboledittext
  handles.cancelbtn
  handles.okbtn
  handles.helpbtn
  handles.noedge
  handles.edgecolor
  handles.noface
  handles.facecolor
  handles.saveset
  handles.loadset
  handles.setasdefault
  handles.deleteset
  handles.size
  handles.sizetext
  handles.markertext
  handles.reordertext
  handles.moveup
  handles.movedown
  ];

set([handles.symbolstyle; handles.symbollist; moveonly],'units','pixels')
figpos = get(handles.symbolstyle,'position');
axpos = get(handles.symbollist,'position');

%adjust axis height
delta = figpos(4)-axpos(4)-axpos(2)*2;
axpos(4) = axpos(4)+delta;
if isneg(axpos(4))
  axpos(4) = 2;
end
set(handles.symbollist,'position',axpos)

%adjust all other objects to match top of axes
hpos = get(moveonly,'position');
for k=1:length(hpos)
  hpos{k}(2) = hpos{k}(2) + delta;
end
set(moveonly,{'position'},hpos);

%readjust figure width
figpos(3)=350;  %fixed width
set(handles.symbolstyle,'position',figpos);

%adjust axes display
updatescroll(handles);


% --- Executes on button press in setasdefault.
function setasdefault_Callback(hObject, eventdata, handles)
% hObject    handle to setasdefault (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

  try
    sym = getappdata(handles.symbolstyle,'symbolset');
    classmarkers('default',sym);
    evrihelpdlg('Current symbol set stored as default.','Default Symbols Set');
  catch
    evrierrordlg(['Unable to save as default set.' 10 lasterr],'Cannot Save Symbols');
  end


% --- Executes on button press in moveup.
function moveup_Callback(hObject, eventdata, handles)
% hObject    handle to moveup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

sym = getappdata(handles.symbolstyle,'symbolset');
index = getappdata(handles.symbolstyle,'selectedsymbol');
if min(index)<2
  return
end
sym([min(index)-1 index]) = sym([index min(index)-1]);
setappdata(handles.symbolstyle,'symbolset',sym);
setappdata(handles.symbolstyle,'changed',true)

%replot and switch to moved item
selectsymbol(handles.symbolstyle, [], handles, index-1)

% --- Executes on button press in movedown.
function movedown_Callback(hObject, eventdata, handles)
% hObject    handle to movedown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


sym = getappdata(handles.symbolstyle,'symbolset');
index = getappdata(handles.symbolstyle,'selectedsymbol');
if max(index)>length(sym)-1
  return
end
sym([index max(index)+1]) = sym([max(index)+1 index]);
setappdata(handles.symbolstyle,'symbolset',sym);
setappdata(handles.symbolstyle,'changed',true)

%replot and switch to moved item
selectsymbol(handles.symbolstyle, [], handles, index+1)


% --- Executes on selection change in size.
function size_Callback(hObject, eventdata, handles)
% hObject    handle to size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns size contents as cell array
%        contents{get(hObject,'Value')} returns selected item from size

sym = getsymbolstyle(handles);
sz = get(handles.size,'value');
sz = sz-1;
if sz==0
  sz = [];
end
[sym(:).size] = deal(sz);
setsymbolstyle(handles,sym);
plotsymbols(handles)

% --- Executes during object creation, after setting all properties.
function size_CreateFcn(hObject, eventdata, handles)
% hObject    handle to size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

%-------------------------------------------------
function symbolstyle_keypressfcn(hObject, eventdata, handles, varargin)

char = double(get(handles.symbolstyle,'CurrentCharacter'));
if isempty(char)
  return
end

sym = getappdata(handles.symbolstyle,'symbolset');
index = getappdata(handles.symbolstyle,'selectedsymbol');

switch char
  case 1  %ctrl-a  
    %select all
    index = 1:length(sym);
    selectsymbol(hObject, eventdata, handles, index);
  case 30  %up arrow
    %select previous item
    if min(index)>1
      selectsymbol(handles.symbolstyle,[],handles,index-1)
    end

  case 31  %down arrow
    %select next item
    if max(index)<length(sym)
      selectsymbol(handles.symbolstyle,[],handles,index+1)
    end
    
  case {28 29}  %left/right arrow
    %switch marker type
    markerlist = getmarkerlist;
    mindex = get(handles.marker,'value');
    switch char
      case 29
        if mindex==length(markerlist)
          mindex = 0;
        end
        mindex = mindex+1;
      case 28
        if mindex==1
          mindex = length(markerlist)+1;
        end
        mindex = mindex-1;
    end
    set(handles.marker,'value',mindex);
    marker_Callback(handles.marker,[],handles);    
    
end
drawnow

% --- Executes on button press in deleteset.
function deleteset_Callback(hObject, eventdata, handles)
% hObject    handle to deleteset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%create a list of markers
sets = classmarkers('options');
systemsets = fieldnames(classmarkers('factoryoptions'));
list = fieldnames(sets);
list = setdiff(list,'functionname');

%get user-defined sets only
predefinedsets = ismember(list,systemsets);
list = list(~predefinedsets);

if isempty(list)
  evrihelpdlg('No user-defined symbol sets exist.','Cannot Delete');
  return
end

desc = list(:);
for j=1:length(desc)
  desc{j}(desc{j}=='_') = ' ';
end

%ask user to choose set to save as (or create new)
choice = listdlg('ListString',desc,'Name','Delete Set','PromptString','Delete symbol set:','SelectionMode','single');
if isempty(choice)
  return
end

%chose one of the real items (not create new)
isok = evriquestdlg(sprintf('Delete symbol set "%s" (this cannot be undone)?',desc{choice}),'Delete Set','Delete','Cancel','Delete');
if strcmp(isok,'Delete')
  setplspref('classmarkers',list{choice},'factory');
end


% --- Executes on button press in helpbtn.
function helpbtn_Callback(hObject, eventdata, handles)
% hObject    handle to helpbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


evrihelp('set_symbol_styles_window')
