function varargout = importtool(varargin)
%IMPORTTOOL GUI for designating column/row data types.
%  Allows user to identify data, class, axisscale, include, and ignore
%  fields (row and columns) in a data matrix.
%
%  OPTIONS
%    renderer : [opengl] renderer to use on figure.
%    fields   : [] Nx2 cell array, first column is field name, second column
%               is color to use.
%  OUTPUTS
%    ctypes   : Structure with fields for each field name indicated in
%               'fields' option. Each field contains indexes for the
%               column/row.
%    rtypes   : Same as above but for rows.
%
%I/O: [ctypes, rtypes] = importtool(data);
%I/O: [ctypes, rtypes] = importtool(data,options);
%
%See also: PARSEMIXED

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0 || ~ischar(varargin{1}) % LAUNCH GUI
  try
    %Start GUI
    drawnow
    %Open figure and initialize
    %fig = openfig('importtool.fig','new','invisible');
    
    varargout{1} = [];
    varargout{2} = [];
    
    fig = figure('Tag','importtool',...
      'NumberTitle', 'off', ...
      'HandleVisibility','callback',...
      'Integerhandle','off',...
      'Name', 'Import Tool',...
      'Renderer','OpenGL',...
      'MenuBar','none',...
      'ResizeFcn','importtool(''resize_callback'',gcbo,[],guihandles(gcbf))',...
      'CloseRequestFcn','try;importtool(''closereq_callback'',gcbo,[],guihandles(gcbf),0);catch;delete(gcbf);end',...
      'visible','off',...
      'Units','pixels');
    
    %Save data to fig here so it can be used to create tables in
    %gui_enable.
    if nargin>0 & ~isempty(varargin{1})
      loaddata(fig,[],guihandles(fig),'auto',varargin{1});
    end
    
    %Save options.
    if nargin<2
      gopts = importtool('options');
    else
      gopts = reconopts(varargin{2},'importtool');
    end
    setappdata(fig,'gui_options',gopts);
    
    %Undocumented passing column and row info.
    if nargin>2
      setappdata(fig,'column_data',varargin{3});
    end
    
    if nargin>3
      setappdata(fig,'row_data',varargin{4})
    end
    
    %Set up gui controls.
    gui_enable(fig)
    
    figbrowser('addmenu',fig); %add figbrowser link
    
    %Position gui from last known position.
    positionmanager(fig,'importtool');
    
    handles = guihandles(fig);
    fpos = get(handles.importtool,'position');
    
    pause(.1);drawnow
    set(fig,'visible','on');
    
    resize_callback(fig,[],handles);
    uiwait(fig);
    if ishandle(fig) & isempty(getappdata(fig,'usercancel'))
      coldata = getappdata(handles.importtool,'column_data');
      rowdata = getappdata(handles.importtool,'row_data');
      varargout{1} = coldata; 
      varargout{2} = rowdata;
      out = getappdata(fig,'imatrix');
    end
    closereq_callback(fig,[],handles)
  catch
    if ishandle(fig); delete(fig); end
    erdlgpls({'Unable to start IMPORTTOOL ' lasterr},[upper(mfilename) ' Error']);
  end
  
else % INVOKE NAMED SUBFUNCTION OR CALLBACK
  try
    switch lower(varargin{1})
      case evriio([],'validtopics')
        options = [];
        options.renderer            = 'opengl';%Opengl can be slow on Mac but it's the only renderer that displays alpha.
        options.fields              = {'Data' [1 1 1];'Label' [0.8928 0.8928 0.8928];'Class' [0.8928 0.75 0.9];...
                                       'Axisscale' [0.8928 0.8928 0.7];'Include' [0.7 0.8928 0.8928];'Ignore' [.75 .7 .72]};
        options.definitions         = @optiondefs;
        
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
function varargout = gui_enable(fig)
%Initialize the the gui.

%Get handles and save options.
handles = guihandles(fig);

%Get options.
gopts = getappdata(fig,'gui_options');

%Get position.
figpos = get(fig,'position');
figcolor = [1 1 1];
set(fig,'Color',figcolor,'Renderer',gopts.renderer,'visible','on',...
  'Toolbar','none','MenuBar','none');

initmsg = uicontrol(fig,'style','text',...
  'BackgroundColor',[1 1 1],...
  'ForegroundColor',[0 0 .4],...
  'units','normalized',...
  'position',[0 0 1 .55],...
  'string','Initializing... Please Wait...',...
  'fontsize',14,...
  'fontname','Courier',...
  'fontweight','bold');


%File edit box.
uicontrol('parent', fig,...
  'tag', 'helptxt',...
  'style', 'text', ...
  'string', {'Data: Numeric    Label: Character/Numeric    Class: Character/Numeric    Axisscale: Numeric    Include: Boolean    Ignore: N/A'}, ...
  'units', 'pixels', ...
  'position',[0 0 1 1],...
  'fontsize',getdefaultfontsize,...
  'horizontalalignment','left',...
  'BackgroundColor',get(fig,'color'),...
  'tooltipstring','File location and name.',...
  'callback','importtool(''button_callback'',gcbo,[],guihandles(gcbf))');

%OK
uicontrol('parent', fig,...
  'tag', 'okbtn',...
  'style', 'pushbutton', ...
  'string', 'OK', ...
  'units', 'pixels', ...
  'position',[0 0 1 1],...
  'fontsize',getdefaultfontsize,...
  'tooltipstring','Import',...
  'callback','importtool(''button_callback'',gcbo,[],guidata(gcbf),''ok'')');

%Cancel
uicontrol('parent', fig,...
  'tag', 'cancelbtn',...
  'style', 'pushbutton', ...
  'string', 'Cancel', ...
  'units', 'pixels', ...
  'position',[0 0 1 1],...
  'fontsize',getdefaultfontsize,...
  'tooltipstring','Cance and close window.',...
  'callback','importtool(''button_callback'',gcbo,[],guihandles(gcbf),''cancel'')');

[tabledata, columndata, headdata] = get_table_data(handles);

set(fig,'visible','on')

%MAKE TABLES
t1 = etable('data',headdata,'column_labels',columndata,'parent_figure',fig,'tag','headertable',...
  'units','pixels','position',[0 0 1 1]);
t2 = etable('data',tabledata,'column_labels',columndata,'parent_figure',fig,'tag','datatable',...
  'units','pixels','position',[0 0 1 1]);

%Adjust scroll pane contol heights.
setscrollpanelsizing(t1,'hscroll',0);
t1.row_header_width = 30;
t2.row_header_width = 30;
t2.column_header_height = 0;

sp1 = t1.getscrollpane;
sp2 = t2.getscrollpane;
%Link scrolling.
sp1.getHorizontalScrollBar.setModel(sp2.getHorizontalScrollBar.getModel);

jt1 = t1.java_table;
jt2 = t2.java_table;

%Need to set custom cell editor for first column because standard table is
%buggy.
edit_cmb1 = javaObjectEDT('javax.swing.JComboBox', gopts.fields(:,1));
edit_cmb1.setBackground(java.awt.Color.WHITE)
%set(edit_cmb1,'itemStateChangedCallback',{@columntypechange,fig,t1});

%Set header table editor the same.
for i = 3:size(tabledata,2);
  %Java uses zero indexing so subtract one.
  jt1.getColumnModel.getColumn(i-1).setCellEditor(javax.swing.DefaultCellEditor(edit_cmb1))
end

edit_cmb2 = javaObjectEDT('javax.swing.JComboBox', gopts.fields(:,1));
edit_cmb2.setBackground(java.awt.Color.WHITE)
%set(edit_cmb2,'itemStateChangedCallback',{@columntypechange,fig,t2});
jt2.getColumnModel.getColumn(0).setCellEditor(javax.swing.DefaultCellEditor(edit_cmb2))

%Set callback on column resize so table stay in sync.
hcm = jt1.getColumnModel;
hcmh = handle(hcm,'callbackproperties');
set(hcmh,'ColumnMarginChangedCallback',{@columnchange,jt1,jt2})
drawnow
pause(2)
%Increase size of columns so text is visile.
setcolumnwidth(t1,[],100)
%Force resize of all columns so they match.
columnchange(jt1.getColumnModel,[],jt1,jt2,1)

%Add datachange callbacks to update output data and coloring.
m  = jt2.getModel;
mh = handle(m,'callbackproperties');
set(mh,'TableChangedCallback',{@columntypechange,fig,t2})

m  = jt1.getModel;
mh = handle(m,'callbackproperties');
set(mh,'TableChangedCallback',{@columntypechange,fig,t1})

handles = guihandles(fig);
guidata(fig,handles);
update_table(handles)
if ishandle(initmsg);
  delete(initmsg);
end

%--------------------------------------------------------------
function resize_callback(h,eventdata,handles,varargin)
%Resize callback.

%Sometimes handles aren't updated so get them manually.
handles = guihandles(h);

if isempty(handles)
  %On some platforms resize is called by openfig before all of controls are
  %created in gui init so just return until handles are available.
  return
end

fpos = get(handles.importtool,'position');

if isfield(handles,'datatable')
  set(handles.datatable,'position',[2,34,fpos(3)-4,fpos(4)-122])
  set(handles.headertable,'position',[2,fpos(4)-90,fpos(3)-4,54])
else
  return
end

set(handles.helptxt,'position',[4 fpos(4)-28 fpos(3)-8 25]);
set(handles.okbtn,'position',[fpos(3)-208 4 100 30])
set(handles.cancelbtn,'position',[fpos(3)-104 4 100 30])

%-----------------------------------------------------------------
function columnchange(cm,ev,jt1,jt2,forceall)
%Update column widths.

if nargin<5
  forceall = 0;
end
cm2 = jt2.getColumnModel;
mycols = cm.getSelectedColumns;

if forceall
  mycols = 0:cm.getColumnCount-1;
elseif mycols==cm.getColumnCount-1
  %Don't go past end.
elseif mycols>1
  mycols = [mycols-1:mycols+1];
else
  mycols = [0 1];
end

for i = 1:length(mycols);
  cm2.getColumn(mycols(i)).setPreferredWidth(cm.getColumn(mycols(i)).getPreferredWidth)
  cm2.getColumn(mycols(i)).setWidth(cm.getColumn(mycols(i)).getWidth)
end

%Set both spacer columns.
cspace = 6;
cm1 = jt1.getColumnModel;
cm1.getColumn(1).setPreferredWidth(cspace)
cm1.getColumn(1).setWidth(cspace)

cm2.getColumn(1).setPreferredWidth(cspace)
cm2.getColumn(1).setWidth(cspace)

%-----------------------------------------------------------------
function columntypechange(obj,ev,fig,tblobj,varargin)
%Column data change callback.

update_table(guidata(fig));

%-----------------------------------------------------------------
function button_callback(h,eventdata,handles,varargin)

mybutton = varargin{1};
switch mybutton
  case 'ok'
    
  case 'cancel'
    setappdata(handles.importtool,'usercancel',1)
end
uiresume(handles.importtool)
%--------------------------------------------------------------------
function openhelp_ctrl_Callback(hObject, eventdata, handles)
%Open help page.
evrihelp('importtool')

%--------------------------------------------------------------------
function closereq_callback(h,eventdata,handles,varargin)
%Close gui.

if isempty(handles)
  handles = guihandles(h);
end

if ishandle(handles.importtool)
  %Save figure position.
  positionmanager(handles.importtool,'importtool','set')

  %Weird rendering of jtable getting deleted so make visible off first.
  set(handles.importtool,'visible','off')
  delete(handles.importtool)
end

%--------------------------------------------------------------------
function loaddata(h,eventdata,handles,varargin)
%Load data.

%TODO: Add warning for more than 3D data.
opts   = getappdata(handles.importtool, 'gui_options');

mode = varargin{1};%Type of load dialog to run.
name = '';
switch mode
  case 'import'
    %Import single image.
    aopts.importmethod = 'editds_defaultimportmethods';
    mydata = autoimport([],[],aopts);
  case 'load'
    %Load single image from mat.
    [mydata,name,location] = lddlgpls({'double' 'dataset' 'cell' 'uint8'},['Select Data']);
  case 'auto'
    %Data provided in varargin.
    mydata = varargin{2};
end

if ~iscell(mydata);  %canceled out of import?
  warning('EVRI:ImporttoolCellArray','Data must be a cell array.')
  return;
else
  %Clear existing data.
  clear_Callback(h,eventdata,handles,'data');
end

setappdata(handles.importtool,'data',mydata)

%--------------------------------------------------------------------
function clear_Callback(h,eventdata,handles,varargin)
%Clear one or more items in gui.

item = varargin{1};

switch item
  case 'data'
    setappdata(handles.importtool,'data',[]);
end


%--------------------------------------------------------------------
function update_callaback(handles)
%Update GUI.


%--------------------------------------------------------------------
function [tabledata, columndata, headdata] = get_table_data(handles)
%Get data for main table and header table.

tabledata = getappdata(handles.importtool,'data');
if isempty(tabledata)
  %Make empty dummy table.
  tabledata = repmat({''},10,10);
end

tabledata = [repmat({'Data'},size(tabledata,1),1) repmat({''},size(tabledata,1),1) tabledata];%11 columns
ncols = size(tabledata,2);
headdata = ['Data Type' ' ' repmat({'Data'},1,size(tabledata,2)-2)];
columndata = {};
for i = 1:ncols-2;
  columndata{i} = ['C ' num2str(i)];
end
columndata = [{' ' ' '} columndata];

%This is a bit of a hack to pre set columns and rows if there are any
%labels found.
coldata = getappdata(handles.importtool,'column_data');
if ~isempty(coldata) & isfield(coldata,'Label') & ~isempty(coldata.Label)
  lableposition = [coldata.Label]+2;%Need to account for empty rows offset.
  headdata(lableposition) = repmat({'Label'},1,length(coldata.Label));
end

rowdata = getappdata(handles.importtool,'row_data');
if ~isempty(rowdata) & isfield(rowdata,'Label') & ~isempty(rowdata.Label)
  tabledata(rowdata.Label,1) = repmat({'Label'},length(rowdata.Label),1);
end


%--------------------------------------------------------------------
function update_table(handles)
%Update table color and save column and row info.

gopts  = getappdata(handles.importtool,'gui_options');
myfields = gopts.fields;

htable = getappdata(handles.importtool,'headertable');
dtable = getappdata(handles.importtool,'datatable');

hdata = getdata(htable,1);
ncols = size(hdata,2);
ddata = getdata(dtable,1);

for i = 1:size(myfields,1)
  mycols.(myfields{i,1}) = [];
  myrows.(myfields{i,1}) = [];
end

%Set tables to white (data color).
if ncols<50
  setbackground(dtable,'table',[],[1 1 1])
  setbackground(htable,'table',[],[1 1 1])
end

%Set column color first the overlay row color since this is how parsemixed
%works (in general).
for i = 3:size(hdata,2)
  %Columns
  thisfield = ismember(myfields(:,1),hdata{i});
  mycolor = myfields{thisfield,2};
  mycols.(myfields{thisfield,1}) = [mycols.(myfields{thisfield,1}) i-2];
  if ncols<50
    setbackground(dtable,'column',i,mycolor)
    setbackground(htable,'column',i,mycolor)
  end
end

for i = 1:size(ddata,1)
  %Rows
  thisfield = ismember(myfields(:,1),ddata{i,1});
  if strcmp(myfields{thisfield,1},'Data')
    continue
  end
  mycolor = myfields{thisfield,2};
  myrows.(myfields{thisfield,1}) = [myrows.(myfields{thisfield,1}) i];
  if ncols<50
    setbackground(dtable,'row',i,mycolor)
  end
end

%Set spacer column back to white.
setbackground(dtable,'column',2,'white')
setbackground(htable,'column',2,'white')

setappdata(handles.importtool,'column_data',mycols)
setappdata(handles.importtool,'row_data',myrows)

%-----------------------------------------------------------------
function out = optiondefs()
defs = {
  %name                    tab              datatype        valid                            userlevel       description
  'renderer'               'Image'          'select'        {'opengl' 'zbuffer' 'painters'}  'novice'        'Figure renderer (selection will affect alpha and performance).';
  
  };
out = makesubops(defs);






