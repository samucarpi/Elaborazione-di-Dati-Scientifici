function varargout = doegui(varargin)
%DOEGUI Design of Experiments tool.
%
%I/O: doegui %Open gui.
%I/O: doegui(options) %Open w/ options.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if verLessThan('matlab','9.8')
  %Need MATLAB 2020a plus for icons on UIButtons to work from our icon mat
  %file.
  error('MATLAB 9.8 (2020a) or higher is required.')
end

if nargin==0 || ~ischar(varargin{1}) % LAUNCH GUI
  try
    fig = findobj(allchild(0),'tag','doegui');
    if ~isempty(fig);
      %fig already exists - only need to make visible and update (if
      %anything)
      figure(fig);
      
      if nargout>0;
        out = fig;
      end
      return;
    end
    %Start GUI
    h=waitbar(1,['Starting Experiment Designer...']);
    drawnow
    
    %need to create figure
    if nargin==1
      options = varargin{1};
    else
      options = [];
    end
    
    options = reconopts(options,'doegui');
    fig = uifigure(...
      'visible','on',...
      'tag','doegui',...
      'busyaction','cancel',...
      'integerhandle','off',...
      'CloseRequestFcn',{@closereq_callback},...
      'Toolbar','none',...
      'Menubar','none',...
      'NumberTitle','off',...
      'Name', 'Experiment Designer');
    
    handles = guihandles(fig);	%structure of handles to pass to callbacks
    guidata(fig, handles);      %store it.
    gui_enable(fig);            %add additional fields
    positionmanager(fig,'doegui');%Position gui from last known position.
    
    %Open figure and initialize.
    figbrowser('addmenu',fig); %add figbrowser link
    
    set(fig,'visible','on')
    drawnow
  catch
    myerr = lasterr;
    if ishandle(fig); delete(fig); end
    if ishandle(h); close(h);end
    erdlgpls({'Unable to start Experiment Designer' myerr},[upper(mfilename) ' Error']);
  end
  
  %Close waitbar.
  if ishandle(h)
    close(h);
  end
  
  if nargout>0
    varargout{1} = fig;
  end
  
else % INVOKE NAMED SUBFUNCTION OR CALLBACK
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = [];
        %options.definitions         = @optiondefs;
        
        if nargout==0
          evriio(mfilename,varargin{1},options)
        else
          varargout{1} = evriio(mfilename,varargin{1},options);
        end
        return;
      otherwise
        if nargout == 0;
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
  
end

%--------------------------------------------------------------------
function fig = gui_enable(fig)
%Initialize the the gui.

%Get handles and save options.
handles = guidata(fig);
gopts = doegui('options');

%Save options.
setappdata(fig,'gui_options',gopts);
set(fig,'visible','on')

fopts = doegen('options');
setappdata(fig,'fcn_options',fopts);

%Get position.
figpos = get(handles.doegui,'position');

%Set up defaults.
mydesigns = getdesign;
setappdata(fig,'doedesign',mydesigns{1});%
defaultdata = setdefaultdata(handles);%Set default data.

grid1 = uigridlayout(fig,[5 1],'RowHeight',{34 2 '2x' '1x' 30});

toolbargrid = uigridlayout(grid1,[1 11]);
toolbargrid.ColumnWidth = {30 30 30 30 30 60 150 50 30 30 30};
btnlist = toolbar_buttonsets('dogui');
btn1 = uibutton(toolbargrid,'Text','','Icon',gettbicons('evri'),...
  'Tooltip','Open workspace browser.','ButtonPushedFcn','browse');
btn2 = uibutton(toolbargrid,'Text','','Icon',gettbicons('calc'),...
  'Tooltip','Regenerate DOE (rerandomize).','ButtonPushedFcn',{@calcdoe_Callback handles});
btn3 = uibutton(toolbargrid,'Text','','Icon',gettbicons('addrow'),...
  'Tooltip', 'Add a new factor to design.','ButtonPushedFcn',{@addfactor_Callback handles});
btn4 = uibutton(toolbargrid,'Text','','Icon',gettbicons('deleterow'),...
  'Tooltip','Remove current factor from design.','ButtonPushedFcn',{@deletefactor_Callback handles});
btn5 = uibutton(toolbargrid,'Text','','Icon',gettbicons('table_export'),...
  'Tooltip','Export DOE dataset to MLR.','ButtonPushedFcn',{@exporttoanalysis_Callback handles});
lbl1 = uilabel(toolbargrid,'Text','Design:','FontSize',getdefaultfontsize+2);
drpd1 = uidropdown(toolbargrid,'Tag','designDropDown','Items',mydesigns(:,1),'BackgroundColor','white',...
  'Tooltip','Change DOE design.','ValueChangedFcn',{@setdesign, handles});
lbl2 = uilabel(toolbargrid,'Text','Plots:','FontSize',getdefaultfontsize+2);
btn6 = uibutton(toolbargrid,'Text','','Icon',gettbicons('plot'),...
  'Tooltip','Plot DOE.','ButtonPushedFcn',{@plot_Callback handles 'data'});
btn7 = uibutton(toolbargrid,'tag','plotconfusion','Text','','Icon',gettbicons('table_confusion'),...
  'Tooltip','Plot confusion table.','ButtonPushedFcn',{@plot_Callback handles 'confusion'});
btn8 = uibutton(toolbargrid,'Text','','Icon',gettbicons('leverage'),...
  'Tooltip','Plot leverage.','ButtonPushedFcn',{@plot_Callback handles 'leverage'});

grid11 = uigridlayout(grid1);%Spacer
if ~verLessThan('matlab','9.9')
  %Background color not available in 2020a.
  set(grid11,'BackgroundColor', 'black')
end

grid2 = uigridlayout(grid1,[1 2]);
grid2.ColumnWidth = {'2x','1x'};

grid3 = uigridlayout(grid2,[2 1],'RowHeight',{22 '1x'});
doetablelabel = uilabel(grid3,'Text','Factors:','FontSize',getdefaultfontsize+2);

%DOE Table
doetable = uitable(grid3,'tag','doetable','data',defaultdata(:,1:5),...
  'CellSelectionCallback',{@doetable_mousepress_callback fig [] handles},...
  'CellEditCallback',{@doetable_edit_callback fig},...
  'ColumnEditable',[true true true true true],...
  'Tooltip','DOE Table','ColumnName',{'Factor Name' 'Levels' 'Min' 'Max' 'Categorical'});
setappdata(fig,'doe_table',doetable);

grid4 = uigridlayout(grid2,[2 1],'RowHeight',{22 '1x'});
doetablelabel = uilabel(grid4,'Text','Factor Categories/Levels:','FontSize',getdefaultfontsize+2);

%Factor table
factortable = uitable(grid4,'tag','factortable','data',defaultdata{1,6},'CellEditCallback',{@categorytable_edit_callback fig [] handles},...
  'Tooltip','Factor Table','ColumnName',defaultdata(1,1),'ColumnEditable',[true]);
setappdata(fig,'cat_table',factortable)

grid5 = uigridlayout(grid1,[1 2]);
grid5.ColumnWidth = {'2x','1x'};

grid6 = uigridlayout(grid5,[2 1],'RowHeight',{22 '1x'});
statslabel = uilabel(grid6,'Text','Design Statistics:','FontSize',getdefaultfontsize+2);

statstxta = uitextarea(grid6,'tag','statstxt','Editable','off');

%Response table.
grid7 = uigridlayout(grid5,[3 1],'RowHeight',{22 26 '1x' });
responselabel = uilabel(grid7,'Text','Response:','FontSize',getdefaultfontsize+2);
grid8 = uigridlayout(grid7,[1 2],'ColumnWidth',{'1x' '1x'});
addbutton = uibutton(grid8,'Text','Add','ButtonPushedFcn',{@responsebtn_callback,'add',handles});
removebutton = uibutton(grid8,'Text','Remove','ButtonPushedFcn',{@responsebtn_callback,'remove',handles});
responsetable = uitable(grid7,'tag','responsetable','data',{'Response 1'},...
  'Tooltip','Response Table','ColumnName',{'Response Variables'},'ColumnEditable',[true]);
setappdata(fig,'response_table',responsetable)

grid9 = uigridlayout(grid1,[1,4],'ColumnWidth',{'1x' 100 100 100});
grid10 = uigridlayout(grid9);%Spacer
runsheetbutton = uibutton(grid9,'Text','Run Sheet','ButtonPushedFcn', {@runsheet_callback handles});
savebutton = uibutton(grid9,'Text','Save','ButtonPushedFcn',{@save_callback handles});
closebutton = uibutton(grid9,'Text','Close','ButtonPushedFcn',{@cancel_callback handles});

set([grid1 grid2 grid3 grid4 grid5 grid6 grid7 grid9 toolbargrid],'RowSpacing',2,'ColumnSpacing',2,'Padding',[2 2 2 2])
set([grid8 grid10],'RowSpacing',0,'ColumnSpacing',0,'Padding',[0 0 0 0])

%Add file menu items.
h1 = uimenu(fig,'Label','File');
uimenu(h1,'Label','Load','Callback',{@load_callback handles});
uimenu(h1,'Label','Save','Callback',{@save_callback handles});
uimenu(h1,'Label','Close','Callback',{@cancel_callback handles});

%Add edit menu items.
h2 = uimenu(fig,'Label','Edit');
randomh = uimenu(h2,'tag','randomize','Label','Randomize','Callback',{@randomize_callback handles 'randomize'});
uimenu(h2,'Label','Reset Factor Table','Callback',{@reset_callback handles 'data'});

h3 = uimenu(fig,'Label','Design','Callback',{@designmenu_callback handles});

mydesigns = getdesign;
for i = 1:length(mydesigns)
  uimenu(h3,'Label',mydesigns{i,1},'Callback',{@setdesign, handles});
end

%Add interaction menu.
h4 = uimenu(fig,'Label','Interactions','tag','interactionsmenu');
uimenu(h4,'tag','term0','Checked','On','Label','&None','Callback',{@interactions_callback handles 'data'});
uimenu(h4,'tag','term2','Label','&2-Term','Callback',{@interactions_callback handles 'data'});
uimenu(h4,'tag','term3','Label','&3-Term','Callback',{@interactions_callback handles 'data'});

h5 = uimenu(fig,'Label','Center Points','tag','centerpointsmenu');
uimenu(h5,'tag','cp_none','Checked','On','Label','&None','Callback',{@centerpoints_callback handles 0});
for i = [1:5 8 10]
  uimenu(h5,'tag',['cp_' num2str(i)],'Checked','Off','Label',['&' num2str(i)],'Callback', {@centerpoints_callback handles i});
end

h6 = uimenu(fig,'Label','Replicates','tag','replicatesmenu');
uimenu(h6,'tag','rep_none','Checked','On','Label','&None','Callback',{@replicates_callback handles 'none'});
for i = [1:5]%Update callback if this [1:5] changes.
  uimenu(h6,'tag',['rep_' num2str(i)],'Checked','Off','Label',['&' num2str(i)],'Callback',{@replicates_callback handles i});
end
uimenu(h6,'tag','rep_other','Checked','Off','Label','&Other','Callback',{@replicates_callback handles 'other'});

%Add menu items.
h6 = uimenu(fig,'Label','Help');
uimenu(h6,'Label','DOE Help','Callback',{@help_callback handles});
updatestats(handles);

%Set controls to default options.
set_options(handles,fopts)

%--------------------------------------------------------------------
function designmenu_callback(h,eventdata,handles,varargin)
%Update design menu item checked. Must be dynamic change because can be
%changed from toolbar.

chld = allchild(h);
set(chld,'checked','off');

mydesign = getappdata(handles.doegui,'doedesign');

dloc = ismember(get(chld,'Label'),mydesign);
set(chld(dloc),'checked','on');

%--------------------------------------------------------------------
function responsebtn_callback(h,eventdata,varargin)
%Add/remove reponse var.

handles = varargin{2};

action = varargin{1};
rtable = getappdata(handles.doegui,'response_table');
rdata = rtable.Data;

switch action
  case 'add'
    rdata(end+1,1) = {'New Response'};
  case 'remove'
    myrow = rtable.Selection(1);
    if isempty(myrow)
      myrow = 1;
    end
    myrow = myrow(1);
    if size(rdata,1)>1
      rdata(myrow,:) = [];
    end
end

rtable.Data = rdata;
updatestats(handles)

%--------------------------------------------------------------------
function setdesign(h,eventdata,varargin)
%Change design and sync with other control (menu or dropdown).

fig = varargin{1}.doegui;
handles = guihandles(fig);%Refresh handles struct so all object are listed.

if strcmp(class(h),'double') | strcmp(class(h),'matlab.ui.container.Menu')
  %Menu bar.
  newdesign = eventdata.Source.Text;
  handles.designDropDown.Value = newdesign;
else
  %Dropdown menu.
  newdesign = eventdata.Value;
end

doetbl = getappdata(handles.doegui,'doe_table');
olddesign = getappdata(fig,'doedesign');
if strcmp(olddesign,newdesign)
  return
end
  
setappdata(fig,'doedesign',newdesign);

dlist = getdesign;

oldlevel = dlist{ismember(dlist(:,1),olddesign),2};
newlevel = dlist{ismember(dlist(:,1),newdesign),2};
disablecol = 'on';
if isinf(newlevel)
  disablecol = 'off';
  if ~isinf(oldlevel)
    newlevel = oldlevel;
  else
    newlevel = 2;
  end
end

%Set level.
if oldlevel~=newlevel
  %Force level change.
  mydata = getappdata(fig,'master_table');
  iscat = [mydata{:,5}];
  mydata(~iscat,2) = repmat({newlevel},sum(~iscat),1);%Force level to change.
  for i = 1:size(mydata,1)
    mytbl = mydata{i,6};
    oldsz = size(mytbl,1);
    newsz = mydata{i,2};
    if ~mydata{i,5}
      %If is numeric category then update numeric cat table.
      mytbl = getcattable(getappdata(handles.doegui,'doedesign'), mydata{i,2}, mydata{i,3}, mydata{i,4});
    else
      %If categorical then adjust table.
      %(NOTE: in reality, newsz and oldsz should NEVER be different for
      %categorical variables because we don't limit them (currently).
      %However, I'm leaving the following code should we discover a
      %situation when we do want to resize on design change
      if oldsz>newsz
        %Truncate existing table.
        mytbl = mytbl(1:newsz);
      elseif oldsz<newsz
        %Add extra cells with character indicators
        mytbl = [mytbl; num2cell(char('@'+(oldsz+1:newsz))')];
      end
    end
    mydata{i,6} = mytbl;
  end
  %mydata(:,6) = repmat({repmat({''},newlevel,1)},size(mydata,1),1);
  
  setappdata(fig,'master_table',mydata);
  
  update_table_data_silent(handles)
else
  updatestats(handles);
end

%--------------------------------------------------------------------
function out = getdesign
%Get default design types.

%n x 3 table
%  Column One: Type
%  Column Two: Level/s Allowed
%  Column Three: Doegen Code

out = {'Full Factorial' inf 'full';...
  '1/2 Fractional Factorial'  2 '2';...
  '1/4 Fractional Factorial'  2 '4';...
  '1/8 Fractional Factorial'  2 '8';...
  '1/16 Fractional Factorial' 2 '16';...
  'Box-Behnken'   3 'boxbehnken';...
  'Spherical CCD' 5 'sphere';...
  'Face-Centered CCD'      3 'face'};

%--------------------------------------------------------------------
function closereq_callback(h,eventdata,handles,varargin)
%Save figure position.
fig = ancestor(h,'figure');
positionmanager(fig,'doegui','set')

children = getappdata(fig,'childplot');
close(children(ishandle(children)));

if ishandle(fig)
  delete(fig)
end

%--------------------------------------------------------------------
function runsheet_callback(h,eventdata,handles,varargin)
%Make runsheet.

%NOTE: Used to update stats to be sure all data was current but that
%re-randomized samples and caused miss-match between runsheet and exported
%data. So, make sure any changes cause update of DOE so we can just grab it
%here without having to re-update.

mydoe = getappdata(handles.doegui,'doe_ds');

if isempty(mydoe)
  return
end

doerunsheet(mydoe);

%--------------------------------------------------------------------
function load_callback(h,eventdata,handles,varargin)
%Load an existing DOE dataset.

%FIXME: Fix this code.

mydoe = lddlgpls('dataset','Load DOE DataSet');

if isempty(mydoe)
  return
end

if ~isfield(mydoe.userdata,'DOE')
  evriwarndlg('Not a DOE DataSet, userdata.DOE field is missing.','Not a DOE DataSet')
  return
end

%DOE factors.
doefact = ismember(mydoe.classid{2,1},{'Numeric' 'Categorical'});
doeclassid = mydoe.classid{2,1};
doeclassid = doeclassid(doefact);
doedata = mydoe.data;
doedata = doedata(:,doefact);

%Parse DOE DSO back into cell table for GUI.
factor_col = str2cell(mydoe.label{2});
factor_col = factor_col(doefact);

%Size of each lookup table will indicate number of levels per factor.
level_col = {};
for i = 1:size(doedata,2)
  level_col{i,1} = length(unique(doedata(:,i)));
end

%Min max will be available via data columns.
min_col = num2cell(min(doedata)');
max_col = num2cell(max(doedata)');

%Category column.
cat_col = false(size(doedata,2),1);
cat_col(ismember(doeclassid,'Categorical')) = true;

%Look out for interaction column, will always be at end?
mycats = {};
for i = 1:size(doedata,2)
  %Numeric cats.
  mycats = [mycats; {unique(doedata(:,i))}];
end

lu_count = 1;
for i = find(cat_col')
  mylu = mydoe.classlookup{1,lu_count};
  mycats{i,1} = mylu(:,2);
  lu_count = lu_count+1;
end

mydata = [factor_col level_col min_col max_col num2cell(cat_col) mycats];

%Set table.
setappdata(handles.doegui,'master_table',mydata);
update_table_data_silent(handles)

%Set options.
opts = mydoe.userdata.DOE.options;
setappdata(handles.doegui,'fcn_options',opts)
set_options(handles,opts)

%Set desgin.
dlist   = getdesign;
mytype  = mydoe.userdata.DOE.type;
if length(mytype)>2 & strcmp(mytype(1:2),'1/')
  mytype = mytype(3:end);
end
typematch = ismember(dlist(:,3),mytype);
if sum(double(typematch))==1
  mydesign = dlist{typematch,1};
  jc = getappdata(handles.doegui,'design_jcombo');
  jc.setSelectedItem(mydesign);
  setdesign(jc,[],handles);
end

%--------------------------------------------------------------------
function set_options(handles,opts)
%Set menus and controls to options values.

%Need to refresh handles.
handles = guihandles(handles.doegui);

%Set interactions menu.
set(allchild(handles.interactionsmenu),'Checked','off');
switch opts.interactions
  case 2
    set(handles.term2,'Checked','On')
  case 3
    set(handles.term3,'Checked','On')
  otherwise 
    set(handles.term0,'Checked','On')
end

%Set randomimze menu.
if strcmp(opts.randomize,'yes')
  set(handles.randomize,'Checked','On')
else
  set(handles.randomize,'Checked','Off')
end

%Set replicates with spoof call.
myreps = opts.replicates;
if myreps==0
  myreps = 'none';
end
replicates_callback(handles.rep_other,[],handles,myreps)

%Add response variables.
if ~isempty(opts.response_variables)
  rtable = getappdata(handles.doegui,'response_table');
  rtable.Data = opts.response_variables;
end

%Update centerpoints by spoofing call to menu.
centerpoints_callback(handles.cp_1,[],handles,opts.centerpoints)

%--------------------------------------------------------------------
function save_callback(h,eventdata,handles,varargin)
%OK button pres.

doe = getappdata(handles.doegui,'doe_ds');
if isempty(doe)
  evrimsgbox('A DOE has not been created, correct any errors inidcated and try again.','DOE Not Created')
else
  [name,location]=svdlgpls(doe,'Design of Experiments (DOE) DataSet object.','doe');
end

%--------------------------------------------------------------------
function cancel_callback(h,eventdata,handles,varargin)
%Cancel button press.

closereq_callback(h,eventdata,handles,varargin)

%--------------------------------------------------------------------
function help_callback(h,eventdata,handles,varargin)
%Help button press.

myhelp = which('doegui.html');
if ~isempty(myhelp)
  doc('doegui')
end

%--------------------------------------------------------------------
function calcdoe_Callback(h,eventdata,handles,varargin)
%Create a DOE dataset.

updatestats(handles)

%--------------------------------------------------------------------
function plot_Callback(h,eventdata,handles,varargin)
%Run ffacconfusion for new desing.

key = varargin{1};

doedso = getappdata(handles.doegui,'doe_ds');
if isempty(doedso)
  return
end

switch key
  case 'confusion'
    fig = ffacconfusion(doedso);
  case 'data'
    fig = plotgui('new',doedso,'noinclude',1,'noload',1);
  case 'leverage'
    x = auto(doedso.data);
    x_lev = dataset(diag(x*inv(x'*x)*x'));
    x_lev = copydsfields(doedso,x_lev,1);
    x_lev.label{2} = 'Leverage';
    fig = plotgui(x_lev,'colorby',x_lev.data,'new','name','DOE Leverage Plot');
end

adopt(handles,fig);

%--------------------------------------------------------------------
function adopt(handles,child)
%Add plot to appdata.
children = getappdata(handles.doegui,'childplot');
children = union(children,child);
setappdata(handles.doegui,'childplot',children);

%--------------------------------------------------------------------
function doetable_mousepress_callback(h,eventdata,handles,varargin)
%Click on DOE Table so update category table.

if ishandle(handles)
  %Figure passed as 3rd input.
  handles = guihandles(handles);
end

mytbl = getappdata(handles.doegui,'doe_table');
%Get current row.
if isempty(eventdata)||isempty(eventdata.Indices)
  if isempty(mytbl.Selection)
    mytbl.Selection = [1 1];
  end
  myrow = mytbl.Selection(1);
else
  myrow = eventdata.Indices(1);
end

%Get category data for current row and display it.
mydata = getappdata(handles.doegui,'master_table');
cdata = mydata{myrow,6};
cattbl = getappdata(handles.doegui,'cat_table');
%Set table data silently.

cattbl.ColumnName = mydata(myrow,1);%Column label.
cattbl.Data = cdata;

%--------------------------------------------------------------------
function doetable_edit_callback(h,eventdata,fig)
%User changed factor table data.
% If min/max/cat and cat = numerical then update cat table.

handles = guidata(fig);

doetbl    = getappdata(fig,'doe_table');
mycol    = eventdata.Indices(2);
myrow    = eventdata.Indices(1);
mydata   = getappdata(fig,'master_table');
mydesign = getappdata(fig,'doedesign');

try
  newdata = doetbl.Data;%Need to use get() for ML 7.0.4.
  newdata = cell(newdata);%Get current jtable data, data in object not updated yet.
  %Have to loop through and change datatype to numeric. Can't use cellfun
  %because not backward compatible.
  numdata = newdata(:,[2:end-1]);

  newdata = [newdata(:,1) numdata newdata(:,end)];%Convert to correct data type.
  
  %If column 2 and not Full Fac then change back to old value, can't change
  %levels for anything other than Full Fac and can't disable a single
  %column right now.
  if ~strcmp(mydesign,'Full Factorial') & mycol==2
    evriwarndlg(['Levels cannot be changed with design type: ' mydesign '.'],'Level Reset');
    newdata(:,2) = mydata(:,2);
  end
  
  %If changing something other than name.
  if (strcmp(mydesign,'Full Factorial') & mycol>1) | (~strcmp(mydesign ,'Full Factorial') & mycol>2)
    if ~newdata{myrow,5}
      %is a numeric factor
      if mycol==5
        %changed from category to numeric - make sure levels are allowed for this design
        dlist = getdesign;
        design = getappdata(handles.doegui,'doedesign');
        lvl = dlist{ismember(dlist(:,1),design),2};
        if isfinite(lvl)
          newdata{myrow,2} = lvl;
        end
      end
      %If is numeric category then update numeric cat table.
      mydata(myrow,6) = {getcattable(getappdata(handles.doegui,'doedesign'), newdata{myrow,2}, newdata{myrow,3}, newdata{myrow,4})};
      %Reset levels, may have been changed when using categories.
      newdata(myrow,2) = {size(mydata{myrow,6},1)};
    else
      %If non numeric category and changed number of levels then update cat
      %table.
      switch mycol
        case 2
          oldsz = mydata{myrow,2};
          newsz = newdata{myrow,2};
          mytbl = mydata{myrow,6};
          %Change levels so adjust table size.
          if oldsz>newsz
            %Truncate existing table.
            mytbl = mytbl(1:newsz);
          else
            %Add extra empty cells.
            mytbl = [mytbl; num2cell(char('@'+(oldsz+1:newsz))')];
          end
          mydata{myrow,6} = mytbl;
        case 5
          %Changed cat so just make place holder.
          catd = str2cell(char([65:90])');
          mydata(myrow,6) = {catd(1:newdata{myrow,2})};
      end
      
    end
  end
  
  mydata(:,1:5) = newdata;
  
  %If factor name is empty need to change to empty string.
  for i = 1:size(mydata,1)
    if isempty(mydata{i,1})
      mydata{i,1} = '';
    end
  end
  
  setappdata(handles.doegui,'master_table',mydata);
  update_table_data_silent(handles);
  updatestats(handles);

  %If edit comes from column 5, it's categorical checkbox and might not
  %trigger selection of that cell so need to manually do that here so
  %Factor table gets updated.
  if myrow==5
    doetbl.Selection = [myrow mycol];
    doetable_mousepress_callback(handles.doegui,[],handles)
  end
catch
  evrierrordlg({'Unable to update table, check value being edited.' lasterr},'Table Reset')
  update_table_data_silent(handles)
end

%--------------------------------------------------------------------
function addfactor_Callback(h,eventdata,handles,varargin)
%Add row to table.

mydata  = getappdata(handles.doegui,'master_table');

%Get design info
mydesign = getappdata(handles.doegui,'doedesign');
dlist = getdesign;

mylevel = dlist{ismember(dlist(:,1),mydesign),2};
if isinf(mylevel)
  %Full factor can be any level so use default of 2.
  mylevel = 2;
end

%Addnew record.
mydata(end+1,:) = {['Factor ' num2str(size(mydata,1)+1)] mylevel 0 mylevel-1 false getcattable(mydesign, mylevel, 0, mylevel-1)};
setappdata(handles.doegui,'master_table',mydata);

update_table_data_silent(handles)

%--------------------------------------------------------------------
function deletefactor_Callback(h,eventdata,handles,varargin)
%Remove factor.

mydata  = getappdata(handles.doegui,'master_table');
if size(mydata,1)<2
  return
end

myrows = getrow(handles);

%Addnew record.
mydata(myrows,:) = [];
if isempty(mydata)
  reset_callback(h,eventdata,handles,'data')
else
  setappdata(handles.doegui,'master_table',mydata);
  update_table_data_silent(handles);
end

%--------------------------------------------------------------------
function exporttoanalysis_Callback(h,eventdata,handles,varargin)
%Send current DOE DSO to MLR.
% Send design as-is if factors are categorical
% If factors are numeric (non-categorical) then only send the data

mydesign = getappdata(handles.doegui,'doe_ds');
iscategorical = all(contains(mydesign.classid{2},{'Categorical', 'Interaction'}));
mylabels = {};
mycatclass = 1;

if ~iscategorical
  set =[];
  % make a new dso with expanded logical instead of (catagorical) classes
  for i = 1:size(mydesign.classid{2,1},2)
    if (strcmp(lower(mydesign.classid{2,1}{i}), 'categorical'))
      [y,nonzero] = class2logical(mydesign.data(:,i)',[]);
      set = [set (y.data + 0)];
      %Build mode 2 label for categorical variable.
      thislabel = {};
      for j = 1:size(mydesign.classlookup{1,mycatclass},1)
        thislabel = [thislabel; [strtrim(mydesign.label{2}(i,:)) '_' mydesign.classlookup{1,mycatclass}{j,2}]];
      end
      mylabels = [mylabels; thislabel];
      mycatclass = mycatclass+1;
    else
      set = [set mydesign.data(:,i)];
      mylabels = [mylabels; mydesign.label{2}(i,:)];
    end
    
  end
  moddesign = dataset(set);
  moddesign.name = mydesign.name;
  moddesign.author = mydesign.author;
  moddesign.label{2,1} = mylabels;
else
  moddesign = mydesign;
end

hh = analysis;
analysis('enable_method',hh,[],guidata(hh),'mlr')
analysis('drop',hh,[],guidata(hh),moddesign);

%--------------------------------------------------------------
function update_table_data_silent(handles)
%Updatedate doe table data with 'data_changed' callback turned off. 
% NOTE: This is an old function name, don't need to worry about
% data_changed callback anymore since we're using ML uitable instead of
% custom Java.

doetbl  = getappdata(handles.doegui,'doe_table');
mydata  = getappdata(handles.doegui,'master_table');

%Update factor table.
doetbl.Data = mydata(:,[1:5]);

%Update category table.
doetable_mousepress_callback(handles.doegui,[],handles)
updatestats(handles);

%--------------------------------------------------------------------
function categorytable_edit_callback(h,eventdata,handles,varargin)
%Add data edit to appdata category table.

handles = guihandles(h);
doetbl  = getappdata(handles.doegui,'doe_table');
cattbl  = getappdata(handles.doegui,'cat_table');
mydata  = getappdata(handles.doegui,'master_table');

drow = find(ismember(doetbl.Data(:,1),cattbl.ColumnName{1,1}));
newdata  = eventdata.Source.Data;%Get data from cat table.
olddata  = mydata{drow,6};
needupdate = 0;

%If data is not categorical update min/max.
if ~mydata{drow,5}
  try
    newdata = cell2mat(newdata);
    olddata = cell2mat(olddata);

    if min(olddata)~=min(newdata)
      %Update min.
      mydata{drow,3} = min(newdata);
      needupdate = 1;
    elseif max(olddata)~=max(newdata)
      %Update max.
      mydata{drow,4} = max(newdata);
      needupdate = 1;
    end
  catch
    evrierrordlg({'Unable to update table, check value being edited.' lasterr},'Table Reset')
    %Set cat table to old data.
    newdata = olddata;
    doetable_mousepress_callback(h,eventdata,handles,varargin);%Reset the table back to original data.
  end
end

if isnumeric(newdata)
  newdata = num2cell(newdata);
end
mydata{drow,6} = newdata;
setappdata(handles.doegui,'master_table',mydata);

if needupdate
  update_table_data_silent(handles);
else
  updatestats(handles);
end


%--------------------------------------------------------------
function reset_callback(h,eventdata,handles,varargin)
%Clear the categories table.

rtype = varargin{1};

switch rtype
  case 'data'
    %Clear response table.
    rtable = getappdata(handles.doegui,'response_table');
    rtable.Data = {'Response 1'};
    %Set default factor table.
    setdefaultdata(handles);
    update_table_data_silent(handles)
end

%--------------------------------------------------------------
function randomize_callback(h,eventdata,handles,varargin)
%Toggle randomize option.

mychk = get(h,'Checked');

if strcmp(mychk,'on')
  myrand = 'no';
  set(h,'Checked','off');
else
  myrand = 'yes';
  set(h,'Checked','on');
end

fopts = getappdata(handles.doegui,'fcn_options');
fopts.randomize = myrand;
setappdata(handles.doegui,'fcn_options',fopts)

updatestats(handles)

%--------------------------------------------------------------
function interactions_callback(h,eventdata,handles,varargin)
%Set appdata for interactions.
mylbl = get(h,'Tag');
myinteraction = 1;

switch mylbl
  case 'term2'
    myinteraction = 2;
  case 'term3'
    myinteraction = 3;
end

set(allchild(get(h,'parent')),'checked','off');
set(h,'checked','on')

fopts = getappdata(handles.doegui,'fcn_options');
fopts.interactions = myinteraction;
setappdata(handles.doegui,'fcn_options',fopts)

updatestats(handles)

%--------------------------------------------------------------
function centerpoints_callback(h,eventdata,handles,varargin)
%Center point menu callback.

handles = guihandles(h);

mycp = varargin{1};%Should always be numeric.

set(allchild(get(h,'parent')),'checked','off');
if isfield(handles,['cp_' num2str(mycp)])
  set(handles.(['cp_' num2str(mycp)]),'checked','on');
else
  %Must be none.
  set(handles.('cp_none'),'checked','on');
end

fopts = getappdata(handles.doegui,'fcn_options');
fopts.centerpoints = mycp;
setappdata(handles.doegui,'fcn_options',fopts)

updatestats(handles)

%--------------------------------------------------------------
function replicates_callback(h,eventdata,handles,varargin)
%Replicates point menu callback.

handles = guihandles(h);

myreps = varargin{1};
myval = [];

if isnumeric(myreps) & myreps>5
  %Probably loading a DOE with "other" replicate value so spoof here.
  myval = myreps;
  myreps = 'other';
end

if strcmp(myreps,'other')
  if isempty(myval)
    %If other then ask user.
    myval = inputdlg('Enter number of replicates desired:','Number of Replicates',1);
  end
  
  if isempty(myval)
    %User cancel, don't change anything. 
    return
  else
    if ~isnumeric(myval)
      myreps = str2num(myval{:});
    else
      myreps = myval;
    end
  end
  
  set(allchild(get(h,'parent')),'checked','off');
  set(handles.(['rep_other']),'checked','on');
else
  set(allchild(get(h,'parent')),'checked','off');
  
  if strcmp(myreps,'none')
    set(handles.(['rep_none']),'checked','on');
    myreps = 0;
  end
  
  if isfield(handles,['rep_' num2str(myreps)])
    %Turn rep number on if it's there.
    set(handles.(['rep_' num2str(myreps)]),'checked','on');
  end
end

fopts = getappdata(handles.doegui,'fcn_options');
fopts.replicates = myreps;
setappdata(handles.doegui,'fcn_options',fopts)

updatestats(handles)

%--------------------------------------------------------------
function myrow = getrow(handles)
%Get current row, use 1 if no selection found.

doetbl  = getappdata(handles.doegui,'doe_table');
myrow = unique(doetbl.Selection(:,1));
if isempty(myrow)
  myrow = 1;
end

%--------------------------------------------------------------
function tbl = getcattable(mydesign, mylevel, min, max)
%Get category table for given info.

switch mydesign
  case 'Spherical CCD'
    val = [-1 1]';
  case 'Face-Centered CCD'
    val = ccdface(1);
  case 'Box-Behnken'
    val = boxbehnken(1);
  otherwise
    val = factdes(1,mylevel);
end

tbl = num2cell(doescale(val,{[min max]}));

%--------------------------------------------------------------
function updatestats(handles)
%Update stats info.

mydata   = getappdata(handles.doegui,'master_table');
mydesign = getappdata(handles.doegui,'doedesign');
handles = guihandles(handles.doegui);

designtable = getdesign;
myloc       = ismember(designtable(:,1),mydesign);

%Get response vars so they're added to doegen options.
rtable = getappdata(handles.doegui,'response_table');
rdata  = rtable.Data;

opts                    = getappdata(handles.doegui,'fcn_options');
opts.response_variables = rdata;

try
  [doe,msg] = doegen(designtable{myloc,3},mydata(:,1),mydata(:,6)',opts);
catch
  doe = [];
  msg = lasterr;
end

setappdata(handles.doegui,'doe_ds',doe);%Save doe to appdata.

if isempty(doe)
  txt = {msg};
else
  %generate interaction description string
  switch opts.interactions
    case 1
      myinterdesc = 'None';
    otherwise
      switch opts.interactions
        case 2
          %         powers = sprintf('2-Term and Squared Terms');
          powers = sprintf('2-Term');
        case 3
          %         powers = sprintf('2- and 3-Term, Squared and Cubed Terms');
          powers = sprintf('2- and 3-Term');
        otherwise
          %         powers = sprintf('up to %i-Term and up to %ith-Power Terms',myinter,myinter);
          powers = sprintf('up to %i-Term',opts.interactions);
      end
      ninter = sum(doe.class{2,1}>2);
      myinterdesc = sprintf('%i (%s)',ninter,powers);
  end

  txt = {['Design: ' doe.name]};
  txt = [txt {['Factors: ' num2str(size(mydata,1))]}];
  txt = [txt {['Interactions: ' myinterdesc]}];
  mysz = size(doe);
  txt = [txt {['Experiments: ' num2str(mysz(1))]}];
  %Get number of center points.
  stclass = doe.classname(1,:);
  cloc = strmatch('Sample Type',stclass);
  txt = [txt {['Additional Center Points: ' num2str(opts.centerpoints)]}];
  mtypes = doe.classid{1,cloc};
  cpcount = sum(ismember(mtypes,'Center Point'));
  txt = [txt {['Total Center Points: ' num2str(cpcount)]}];
  txt = [txt {['Response Variables: ' num2str(length(rdata))]}];
  txt = [txt {['Randomize: ' upper(opts.randomize)]}];
  txt = [txt {['Replicates: ' num2str(opts.replicates)]}];
  txt = [txt {doe.description}];
end

handles.statstxt.Value = txt;

%Set plot button enalbe.
if ~isempty(strfind(lower(mydesign),'fractional'))
  set(handles.plotconfusion,'enable','on')
else
  set(handles.plotconfusion,'enable','off')
end

%--------------------------------------------------------------
function defaultdata = setdefaultdata(handles)
%Set default data.

defaultdata = {
  'Factor 1' 2 0 1 false {0;1}
  'Factor 2' 2 0 1 false {0;1}
  };

%Need to maintian master data matrix in appdata so that factor table and
%category table maintain in sync. It was too easy for table to become out
%of sync without master. 6 Columns [factor level min max use_cat cat_table]
setappdata(handles.doegui,'master_table',defaultdata)
