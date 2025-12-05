function obj = connectiongui(obj)
%EVRIDB/CONNECTIONGUI GUI for connection object.

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%TODO: Make changes instant so test button works correctly.

if isempty(obj)
  error('Need EVRIDB object as input.')
end

fig = figure('Name','EVRI Database Connection Settings','tag','conntool','Toolbar','none', 'visible','off', ...
  'Menubar','none','NumberTitle','off','units','pixels','ResizeFcn',@resize_fig);
fcolor = get(fig,'color');

setappdata(fig,'original_database_object',obj);
setappdata(fig,'database_object',obj);

%Type pulldown.
select_lbl = uicontrol(fig,'style','text','tag','dbtyp_label','string','Database Type:',...
  'HorizontalAlignment','left','units','pixels','backgroundcolor',fcolor);
select_drp = uicontrol(fig,'style','popupmenu','tag','dbtyp_list','string',obj.known_types,...
  'backgroundcolor','white','units','pixels','callback',@type_callback);

%Test, Save and close buttons.
save_btn = uicontrol(fig,'style','pushbutton','tag','ok_btn','string','OK',...
  'HorizontalAlignment','left','units','pixels','callback',@ok_callback);
close_btn = uicontrol(fig,'style','pushbutton','tag','cancel_btn','string','Cancel',...
  'HorizontalAlignment','left','units','pixels','callback',@cancel_callback);
test_btn = uicontrol(fig,'style','pushbutton','tag','test_btn','string','Test',...
  'HorizontalAlignment','left','units','pixels','callback',@test_callback);
help_btn = uicontrol(fig,'style','pushbutton','tag','help_btn','string','Help',...
  'HorizontalAlignment','left','units','pixels','callback',@help_callback);

%Add connection settings table.
type_callback(fig,'update')

%Set visible.
set(fig,'visible','on');

resize_fig(fig)

uiwait(fig)

if ishandle(fig)
  obj = getappdata(fig,'database_object');
end

close(fig)

%--------------------------------------------------------------------
function help_callback(varargin)

evrihelpdlg('Sorry, no help currently exists for this interface','No Help Available')

%--------------------------------------------------------------------
function type_callback(h,evnt)
%Change type callback.

handles = guihandles(h);

if nargin<2
  evnt = '';
end

%Get db object.
obj = getcurrentsettings(handles);

if ischar(evnt) && strcmp(evnt,'update')
  %Update the dropdown.
  thistype = get(handles.dbtyp_list,'string');
  set(handles.dbtyp_list,'value',find(ismember(thistype,obj.type)));
else
  %Update table.
  thistype = get(handles.dbtyp_list,'string');
  thistype = thistype{get(handles.dbtyp_list,'value')};
  
  if ~strcmp(obj.type,thistype)
    %Run through subsassign so driver field is updated.
    index.type = '.';
    index.subs = 'type';
    val = thistype;
    obj = subsasgn(obj,index,val);
  end
end

%Create settings table.
[required_settings, optional_settings, unused_settings] = getdbtypesettings(obj);
mydata = {};

defs = obj.definitions;
for i = 1:length(defs)
  if ~strcmpi(defs(i).name,'arguments') && ~strcmpi(defs(i).name,'type')
    mydata(end+1,1) = {''};
    switch defs(i).name
      case required_settings
        mydata{end,1} = 'r';
      case optional_settings
        mydata{end,1} = 's';
      otherwise
        mydata{end,1} = 'u';
    end
    mydata{end,2} = defs(i).tab;
    mydata{end,3} = obj.(defs(i).name);
  end
end
[mydata, idx] = sortrows(mydata,1);
mydata(:,1) = strrep(mydata(:,1),'s','o');
mydata(:,1) = strrep(mydata(:,1),'u','-');

mytbl = findobj(handles.conntool,'tag','settingstbl');
if isempty(mytbl)
  
  [t, container] = evritable(handles.conntool,{'R' 'Name' 'Value'},mydata);
  set(container,'tag','settingstbl','UserData',t,'Units','Pixels');

else
  t = get(mytbl,'UserData');
  if ~isempty(t)
    t.TableModel.setDataVector(mydata,{'O' 'Name' 'Value'});
  else
    set(mytbl,'data',mydata)
  end
end
resize_fig(handles.conntool)

% %--------------------------------------------------------------------
% function out = update_connection_tbl(h,evnt)
% %Update connection table.
% 
% if ~isstruct(evnt)
%   if evnt.getEvent.getFirstRow<0
%     %If there's no row affected then
%     return
%   else
%     %Java zero indexing.
%     myrow = evnt.getEvent.getFirstRow;
%   end
% else
%   myrow = evnt.Indices(1);
% end
% 
% %Update db object with new values.
% if ~strcmp(class(h),'double')
%   %h can come in as java table object.
%   h = get(h,'UIContainer');
% end
% handles = guihandles(h);
% 
% %Get existing object.
% obj = getappdata(handles.conntool,'database_object');
% 
% %Get definiitions.
% defs = obj.definitions;
% tabs = {defs.tab};
% 
% if ~isstruct(evnt)
%   %Get table data.
%   t = get(handles.settingstbl,'UserData');
%   tbldata = t.getData;
%   tbldata = reshape(str2cell(char(tbldata)),length(tbldata),[]);
% else
%   tbldata = get(handles.settingstbl,'data');
% end
% 
% %Map back to field.
% fieldname = tbldata(myrow,2);
% myfield = defs(ismember(tabs,fieldname)).name;
% obj.(myfield) = tbldata{myrow,3};
% 
% setappdata(handles.conntool,'database_object',obj)

%--------------------------------------------------------------------
function out = resize_fig(h,evnt)
%Resize callback.

handles = guihandles(h);
obj = getappdata(handles.conntool,'database_object');

fp = get(h,'position');

set(handles.dbtyp_label,'position',[8 fp(4)-25 120 22])
set(handles.dbtyp_list,'position',[144 fp(4)-25 150 22])
set(handles.settingstbl,'position',[4 40 fp(3)-8 fp(4)-70])

%Set column width leftover.
mtbl = get(handles.settingstbl,'UserData');
colwidt = {20 170 max(50,fp(3)-250)};
if ~isempty(mtbl)
  jtbl = mtbl.getTable;
  for i = 0:2
    col = jtbl.getColumnModel.getColumn(i);
    col.setPreferredWidth(colwidt{i+1});
  end
else
  set(handles.settingstbl,'ColumnWidth',colwidt);
end

set(handles.test_btn,'position',[max(fp(3),540)-308 4 100 25])
set(handles.ok_btn,'position',[max(fp(3),540)-204 4 100 25])
set(handles.cancel_btn,'position',[max(fp(3),540)-100 4 100 25])
set(handles.help_btn,'position',[4 4 100 25])

%--------------------------------------------------------------------
function out = test_callback(h,evnt)
%Test db connection.
handles = guihandles(h);
%Get updated object.
obj = getcurrentsettings(handles);
[out, myerr] = testconnection(obj);
evripause(.3);%Give time for connection to be made.
if ~out
  evrierrordlg(myerr,'Database Connection Error')
else
  evrimsgbox('Connection successful!','Database Connection Successful')
end

%--------------------------------------------------------------------
function out = cancel_callback(h,evnt)
%Cancel and return original object.
uiresume

%--------------------------------------------------------------------
function out = ok_callback(h,evnt)
%Get current settings and retrun them.

handles = guihandles(h);
%Get updated object.
obj = getcurrentsettings(handles);
setappdata(handles.conntool,'database_object',obj)

uiresume

%--------------------------------------------------------------------
function obj = getcurrentsettings(handles)
%Get current object from uitable

%Get existing object.
obj = getappdata(handles.conntool,'database_object');

%Get definiitions.
defs = obj.definitions;
tabs = {defs.tab};

%Make sure table is there.
if isfield(handles,'settingstbl')
  %Get table data.
  t = get(handles.settingstbl,'UserData');
  tbldata = t.getData;
  tbldata = reshape(str2cell(char(tbldata)),length(tbldata),[]);
  
  %Map back to field.
  fieldnames = tbldata(:,2);
  defs = obj.definitions;
  for i = 1:length(fieldnames)
    obj.(defs(ismember({defs.tab},fieldnames{i})).name) = tbldata{i,3};
  end
end

