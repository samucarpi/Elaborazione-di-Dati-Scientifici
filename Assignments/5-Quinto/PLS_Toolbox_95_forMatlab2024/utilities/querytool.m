function varargout = querytool(varargin)
%QUERYTOOL Database connection and query tool.
%
%I/O: querytool
%I/O: querytool(evridbObject)
%
%See also: @EVRIDB

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1
  obj = evridb;
elseif nargin==1
  obj = varargin{1};
else
  if nargout == 0;
    feval(varargin{:}); % FEVAL switchyard
  else
    [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
  end
  return
end

%Displayed name lookup.
%Default values.
fig = figure('Name','EVRI Database','tag','querytool','Toolbar','none', 'visible','on', ...
  'Menubar','none','NumberTitle','off','units','pixels','ResizeFcn',@resize_fig);
setappdata(fig,'database_object',obj);

getplspref(mfilename);  %FORCE getplspref to load (will assure javaclasspath is set up)
pos = get(fig,'position');

import java.awt.*;
import javax.swing.*;

import org.fife.ui.rtextarea.*;
import org.fife.ui.rsyntaxtextarea.*;

%Create menu.
hmenu = uimenu(fig,'Label','&File','tag','FileMenu');
uimenu(hmenu,'label','&Save DB Object','callback','querytool(''save_callback'',guihandles(gcf));');
uimenu(hmenu,'label','&Save Raw Data To File','callback','querytool(''savetofile_callback'',guihandles(gcf));');
uimenu(hmenu,'label','&Quit','callback','querytool(''close_callback'',guihandles(gcf));');

%Create jpanels.
%sqlPanel = javaObjectEDT('javax.swing.JPanel',BorderLayout);
%tblPanel = javaObjectEDT('javax.swing.JPanel',BorderLayout);
%setappdata(fig,'table_panel',tblPanel);%Save table panel for use when updating query table.

%Create text area.
if checkmlversion('>','7.6')
  sqlPanel = javaObjectEDT('javax.swing.JPanel',BorderLayout);
  tblPanel = javaObjectEDT('javax.swing.JPanel',BorderLayout);
  
  sqlText = javaObjectEDT('org.fife.ui.rsyntaxtextarea.RSyntaxTextArea');
  sqlText.setSyntaxEditingStyle(SyntaxConstants.SYNTAX_STYLE_SQL);
  %This will add line numbers.
  %sqlScrollPane = javaObjectEDT('org.fife.ui.rtextarea.RTextScrollPane',sqlText,1);
else
  sqlPanel = javax.swing.JPanel(BorderLayout);
  tblPanel = javax.swing.JPanel(BorderLayout);

  sqlText = org.fife.ui.rsyntaxtextarea.RSyntaxTextArea;
  sqlText.setSyntaxEditingStyle(SyntaxConstants.SYNTAX_STYLE_SQL);
  %sqlScrollPane = awtcreate('org.fife.ui.rtextarea.RTextScrollPane');
  %set(sqlScrollPane,'TextArea',sqlText);
  pause(.2)
end

setappdata(fig,'table_panel',tblPanel);%Save table panel for use when updating query table.
[sqt_j,sqt_h] = javacomponent(sqlText,[],fig);%(component, position, parent, callback)
pause(.4);drawnow
%set(sqlText,'parent',fig)

%Save text obj to appdata so we can easily access it later.
set(sqt_j,'KeyPressedCallback',{@keypress_monitor fig})
setappdata(fig,'sqltext',sqt_j);

%Add scroll pane to panel.
sqlPanel.add(sqt_j);%Doesn't work with awt object.

%Make table.
opts.tag = 'query_table';
[jtable, tcontainer] = evritable(fig,repmat({' '},1,5) ,repmat({' '},1,5),opts);
setappdata(fig,'query_table',jtable)

pause(.1);drawnow
%set(tcontainer,'Position',[1 1 1 1]);
tableScrollPane = get(jtable,'TableScrollPane');
tblPanel.add(tableScrollPane);

%Make top/bottom tree split pane.
topPane =  JSplitPane(JSplitPane.VERTICAL_SPLIT);
topPane.setTopComponent(sqlPanel);
topPane.setBottomComponent(tblPanel)
topPane.setOneTouchExpandable(true);
topPane.setContinuousLayout(true);
topPane.setResizeWeight(0.1);
%Make global panel.
gp = JPanel(BorderLayout);
gp.add(topPane, BorderLayout.CENTER);
%Use javacomponent to put on EDT.
[obj, hcontainer] = javacomponent(gp, [0,0,pos(3),pos(4)], fig);
set(hcontainer,'units','pixels','tag','mainpanel','userdata',obj);
assignin('base','jcomp',obj);
assignin('base','hcomp',hcontainer);


btnlist = {
  'options'    'dbconn'      'querytool(''toolbar_callback'',guihandles(gcf),''dbconn'');'           'enable' 'Open Connection Window'     'off'   'push'
  'play'       'runquery'    'querytool(''toolbar_callback'',guihandles(gcf),''runquery'');'         'enable' 'Run Query'                  'on'    'push'
  'edit'       'todataset'   'querytool(''toolbar_callback'',guihandles(gcf),''todse'');'            'enable' 'Export to DataSet Editor'   'off'   'push'
  'new'        'toworkspace' 'querytool(''toolbar_callback'',guihandles(gcf),''tofig'');'            'enable' 'Export to New Figure'       'off'   'push'
  'viewmodl'   'accesstables' 'querytool(''toolbar_callback'',guihandles(gcbo),''accesstables'');'   'enable' 'Query MS Access Tables'     'off'   'push'
  %'open'       'tbwsload'   'browse(''workspace'',''load'')'                        'enable' 'Load workspace'             'on'    'push'
  %'save'       'tbwssave'   'browse(''workspace'',''save'')'                        'enable' 'Save workspace'             'off'   'push'
  };  
toolbar(fig,'',btnlist);
if nargout > 0;
  varargout{1} = fig;
end
%--------------------------------------------------------------------
function out = toolbar_callback(handles,mode)
%Toolbar callback switchyard.

switch mode
  case 'dbconn'
    dbobj = getappdata(handles.querytool,'database_object');
    dbobj = connectiongui(dbobj);
    setappdata(handles.querytool,'database_object',dbobj);
  case 'runquery'
    query_callback(handles)
  case 'todse'
    mydata = getappdata(handles.querytool,'query_data');
    mycols = getappdata(handles.querytool,'column_names');
    if isempty(mydata)
      return
    end
    if ~isempty(mycols)
      mydata = [mycols{:}';mydata];
    end
    options.labelrows = 1;
    mydse = parsemixed(mydata,options);
    myname = ['query_data_' encodedate];
    assignin('base',myname,mydse);
    evalin('base',['editds(' myname ');']);
  case 'tofig'
    newtable_callback(handles)
  case 'newwin'
    
  case 'undo'
    
  case 'redo'
    
  case 'accesstables'
    dbobj = getappdata(handles.querytool,'database_object');
    atbls = dbobj.get_access_tables;
    setappdata(handles.querytool,'query_data',atbls);
    setappdata(handles.querytool,'column_names',{'Tables'});
    update_query_tbl(handles)
end

%--------------------------------------------------------------------
function out = update_query_tbl(handles)
%Update table.

mydata = getappdata(handles.querytool,'query_data');
mycols = getappdata(handles.querytool,'column_names');

if isempty(mydata)
  return
end

jtbl = getappdata(handles.querytool,'query_table');
jtbl.setData(mydata);
if ~isempty(mycols)
  jtbl.setColumnNames(mycols);
end

%--------------------------------------------------------------------
function out = save_callback(handles)
%Save database object to workspace.

%Get existing object.
obj = getappdata(handles.querytool,'database_object');

svdlgpls(obj,'Save Database Connection Object','DBObject');

%--------------------------------------------------------------------
function out = savetofile_callback(handles)
%Save data and column to file.

mydata = getappdata(handles.querytool,'query_data');

if isempty(mydata)
  return
end

svdlgpls(mydata,'Save Database Data','db_data');

%--------------------------------------------------------------------
function out = close_callback(handles)
%Close gui.
close(handles.querytool);

%--------------------------------------------------------------------
function out = newtable_callback(handles)
%Put copy of table into new figure.
f = figure;
mydata = getappdata(handles.querytool,'query_data');
mycols = getappdata(handles.querytool,'column_names');
if ~iscell(mycols)
  mycols = {mycols};
end
[jtable, tcontainer] = evritable(f,mycols{1}',mydata);
setappdata(f,'query_table',jtable)

%--------------------------------------------------------------------
function out = closedatatab_callback(h,evnt)

delete(get(h,'parent'));

%--------------------------------------------------------------------
function out = queryhistory_callback(h,evnt)
%Run selected query in query tab.
handles = guihandles(h);
allqry = get(handles.history_txt,'string');
if isempty(allqry)
  return
end
myqry = strtrim(allqry(get(handles.history_txt,'value'),:));
if ~isempty(myqry)
  set(handles.query_txt,'string',myqry);
  query_callback(h);
end

set(handles.evridb_tg,'SelectedIndex',2)
resize_fig(handles.querytool);

%--------------------------------------------------------------------
function out = keypress_monitor(obj,evnt,fig)

if evnt.getKeyCode==10 && evnt.getModifiers==evnt.SHIFT_MASK
  %Run query.
  query_callback(guihandles(fig))
end

%--------------------------------------------------------------------
function out = query_callback(handles)
%Run query.

%Get existing object.
obj = getappdata(handles.querytool,'database_object');

txtobj = getappdata(handles.querytool,'sqltext');
qrystr = char(txtobj.getText);

%Since query text area allows multiline, need to make character array into
%single line before calling (for Derby anyhow), will leave a bunch of spaces.
qrystr = sprintf('%s',qrystr');
if isempty(qrystr)
  return
end

gdata = [];
[qdata, cols] = obj.runquery(qrystr);
setappdata(handles.querytool,'query_data',qdata);
setappdata(handles.querytool,'column_names',cols);
update_query_tbl(handles)

historyc = getappdata(handles.querytool,'query_history');
historyc{end+1} = qrystr;
setappdata(handles.querytool,'query_history',historyc);%query history
setappdata(handles.querytool,'query_history_pos',1);%history position

%--------------------------------------------------------------------
function out = resize_fig(h,evnt)
%Resize callback.

handles = guihandles(h);

figpos = get(handles.querytool,'Position');

try
  set(handles.mainpanel,'position',[2 2 figpos(3)-4 figpos(4)-4])
  %set(handles.mainpanel,'position',[2 2 2 2])
end




