function varargout = adjustaxislimitsgui(varargin)
% ADJUSTAXISLIMITSGUI for given figure allows adjustment of current axis limits.
%   If second input 'updateonly' (boolean) given, function will only try to
%   update figure and will not create a new figture it doesn't exist.
%
%I/O: adjustaxislimitsgui(targetfigure)
%I/O: adjustaxislimitsgui(targetfigure,updateonly)
%
%See also: PLOTGUI

%Copyright © Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.
%rsk 08/31/06  Initial coding.

%Grab all objs so legend is not greyed.
%If figure off to right then center on top.

if nargin == 0
  varargin = {'io', varargin{:}};
elseif ishandle(varargin{1})
  %Passed a target figure, go to setup.
  varargin = {'setup', varargin{:}};
end

switch varargin{1}
  case cat(2,evriio([],'validtopics'));
    options = [];
    if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return;
  otherwise
    %    try
    if nargout==0
      feval(varargin{:});
    else
      [varargout{1:nargout}] = feval(varargin{:});
    end
    %     catch
    %       error(['Invalid input to function. ' lasterr])
    %     end
end

%--------------------------
function fig = setup(varargin)
%GUI Setup.

persistent expectedhandles

targfig = varargin{1};

createnew = 1;
if nargin>1
  createnew = varargin{2};
end

fig = findobj(allchild(0),'tag','axisadjust');
if ~isempty(fig);
  %If figure already exists, check if same targfig. If so, update and
  %bring to front.
  mytargfig = getappdata(fig,'targfig');
  if mytargfig==targfig
    update_Callback(fig)
    if ishandle(fig)
      %Figure will be deleted in update callback if target is lost.
      figure(fig)
    end
    return
  end
end

if ~createnew
  %If update call then just exit.
  return
end

%Get current axis.
myaxis = get(targfig,'CurrentAxes');
if isempty(myaxis)
  return
end

%Get all other axes.
myaxes = findobj(targfig,'type','axes');
myaxes = setdiff(myaxes, myaxis);

%Create figure.
if isempty(fig)
  drawnow;
  fig     = openfig(mfilename,'new','invisible');   %create gui
  drawnow
end
handles = guihandles(fig);% Generate a structure of handles to pass to callbacks
guidata(fig,handles);

%detect if the figure has problems opening (seems to be related to issues
%with number of handles available. Indication is when some of our objects
%don't get tags and thus don't show up in the guihandles output). Only
%thing to do is to stop using GUI. 
if ~isempty(expectedhandles)
  if length(fieldnames(handles))<expectedhandles
    delete(fig);
    evriwarndlg('Axis Limits Interface is not currently available due to handles limitation. Please close some figures or restart application and try again.','Axis Limits Not Available')
    return
  end
end

%Set button down function.
set(fig,'WindowButtonDownFcn','try;adjustaxislimitsgui(''btnlocate_Callback'',gcbo, [], guihandles(gcbo));catch;end')
set(fig,'closerequestfcn','try;adjustaxislimitsgui(''btncancel_Callback'',gcbo,[],guihandles(gcbo));catch;delete(gcbf);end');
%Add callback for seting apply all.
set(handles.checkbox9,'callback','adjustaxislimitsgui(''applyall_Callback'',gcbo, [], guihandles(gcbo));')

%Get default font size.
myfontsize = 10;
if ~ispc
  myfontsize = 12;
end

%Adjust font size on all controls.
myctrls = findobj(fig,'type','uicontrol');
set(myctrls,'fontsize',myfontsize,'fontname','arial');

%Get original colors.
mycolors = get(myaxes, 'Color');
if ~iscell(mycolors)
  %This is a cell if more than one axis is found but not if only one so
  %change to cell.
  mycolors = {mycolors};
end

fcolor = get(targfig,'color');
if all(fcolor<0.5)
  fcolor = get(0,'defaultfigurecolor');
end

%Set fig color and name.
set(fig,'Color',fcolor);
set(fig,'name','Axis Properties');

%Update color.
set([handles.text8 handles.uipanel1 handles.uipanel2 handles.text5 handles.text6 ...
  handles.text7 handles.checkbox4 handles.checkbox5 handles.checkbox6 handles.checkbox7...
  handles.checkbox9 handles.uipanel3 handles.checkbox10 handles.checkbox11 ],...
  'BackgroundColor',fcolor,'fontsize',myfontsize);

%Save object data.
setappdata(fig, 'targfig',targfig);
setappdata(fig, 'axishandle',myaxis);
setappdata(fig, 'otheraxes',myaxes);
setappdata(fig, 'othercolors',mycolors);

update_Callback(fig)

set(fig,'visible','on');

expectedhandles = length(fieldnames(handles));  %store this now - we're assuming the FIRST time we open, it works.

%--------------------------------------------------
function update_Callback(fig)
%Update control values.

handles = guihandles(fig);

myaxis  = getappdata(fig, 'axishandle');
myaxes  = getappdata(fig, 'otheraxes');
targfig = getappdata(fig, 'targfig');

if isempty(myaxis) | ~ishandle(myaxis)
  %Missing axis so delete.
  delete(fig)
  return
end

curaxis = get(targfig,'CurrentAxes');

if curaxis~=myaxis
  %Switch axis if it has changed. This will only occur is we're still on
  %same figure because of code in setup. Record and store color.
  oc = getappdata(fig, 'othercolors');
  
  %Restore new axis color from saved colors.
  set(curaxis,'color',oc{myaxes==curaxis})
  
  %Get old axis color and add handle and color to other axes list.
  mycolor = get(myaxis,'color');
  oc{myaxes==curaxis} = mycolor;
  myaxes(myaxes==curaxis) = myaxis;
  
  myaxis = curaxis;
  %Set info back out to appdata.
  setappdata(fig, 'axishandle',myaxis);
  setappdata(fig, 'otheraxes',myaxes);
  setappdata(fig, 'othercolors',oc);

end

if ~isempty(myaxes) & ~ishandle(myaxes)
  myaxes = [];
  setappdata(fig, 'otheraxes',myaxes);
end

if ~isempty(myaxes)
  mycolor = get(targfig,'color');
  if all(mycolor<0.5)
    mycolor = get(0,'defaultfigurecolor');
  end
  set(myaxes, 'Color', mycolor);
end

%Axis values.
myval = axis(myaxis);

%Set axis values.
set(handles.adjxone, 'String', num2str(myval(1)));
set(handles.adjxtwo, 'String', num2str(myval(2)));
set(handles.adjyone, 'String', num2str(myval(3)));
set(handles.adjytwo, 'String', num2str(myval(4)));

%set callbacks on axes limits to automatically "apply" the changes
set([handles.adjxone handles.adjxtwo handles.adjyone handles.adjytwo],...
  'callback','adjustaxislimitsgui(''btnapply_Callback'',gcbo, [], guihandles(gcbo));');

%Grid status.
gridstatus = get(myaxis,'xgrid');
setappdata(fig,'gridstatus',gridstatus);
set(handles.gridcheckbox,'value',strcmp(gridstatus,'on'));

%Y Grid
yg = get(myaxis,'ygrid');
ygm = get(myaxis,'yminorgrid');
if strcmpi(yg,'on')
  set(handles.checkbox4,'value',1);
else
  set(handles.checkbox4,'value',0);
end

%X Grid
xg = get(myaxis,'xgrid');
xgm = get(myaxis,'xminorgrid');
if strcmpi(xg,'on')
  set(handles.checkbox6,'value',1);
else
  set(handles.checkbox6,'value',0);
end

%Z Grid, not shown.
zg = get(myaxis, 'zgrid');
zgm = get(myaxis, 'zminorgrid');

%If any minor grid on check box.
if strcmpi(xgm,'on') | strcmpi(ygm,'on')
  set(handles.checkbox3,'value',1);
else
  set(handles.checkbox3,'value',0);
end

%Y Tick
ytck = get(myaxis,'YTick');
if ~isempty(ytck)
  set(handles.checkbox5,'value',1)
else
  set(handles.checkbox5,'value',0);
end

%X Tick
xtck = get(myaxis,'XTick');
if ~isempty(xtck)
  set(handles.checkbox7,'value',1)
else
  set(handles.checkbox7,'value',0);
end


%Y Reverse
myydir = get(myaxis,'YDir');
if strcmpi(myydir,'reverse')
  set(handles.checkbox11,'value',1)
else
  set(handles.checkbox11,'value',0);
end

%X Reverse
myxdir = get(myaxis,'XDir');
if strcmpi(myxdir,'reverse')
  set(handles.checkbox10,'value',1)
else
  set(handles.checkbox10,'value',0);
end



%Title
tstr = get(get(myaxis,'Title'),'String');
set(handles.edit5,'String',tstr);

%Y Label
ystr = get(get(myaxis,'Ylabel'),'String');
set(handles.edit6,'String',ystr);

%X Label
xstr = get(get(myaxis,'Xlabel'),'String');
set(handles.edit7,'String',xstr);

set(fig,'WindowButtonMotionFcn','try;adjustaxislimitsgui(''motion_Callback'',gcbo,[],guihandles(gcbo));catch;end')
btnlocate_Callback([], [], handles)

myapply = getappdata(targfig,'applyall');
if ~isempty(myapply) & myapply
  set(handles.checkbox9,'value',1)
else
  set(handles.checkbox9,'value',0)
end

%--------------------------------------------------
function resize_Callback(hObject, eventdata, handles)
%Resize figure. 
%NOTE: Figure is not currently resizeable but could be useful if more
%controls are added.

%--------------------------------------------------
function motion_Callback(hObject, eventdata, handles)
%Mouse-over. Make sure target figure exists.

fig = handles.axisadjust;
axh = getappdata(fig,'axishandle');
if ~ishandle(axh);
  %figure is gone, delete this GUI
  delete(fig);
  return
end

%----------------------------------------------------
function btnapply_Callback(hObject, eventdata, handles)
%Apply button, apply new axis limits to axes.

fig = handles.axisadjust;
targfig = getappdata(fig, 'targfig');

axh = getappdata(fig,'axishandle');

if ~ishandle(axh);
  %figure is gone, delete this GUI
  delete(fig);
  return
end

%Apply to all axes if needed.
axh = getaxes(handles);

mytag = get(hObject,'tag');

switch mytag
  case {'adjxone' 'adjxtwo' 'adjyone' 'adjytwo'}
    x1 = str2double(get(handles.adjxone, 'String'));
    x2 = str2double(get(handles.adjxtwo, 'String'));
    y1 = str2double(get(handles.adjyone, 'String'));
    y2 = str2double(get(handles.adjytwo, 'String'));
    
    %test and correct for inverted order and/or equal values
    if x1>x2;
      temp = x1;
      x1 = x2;
      x2 = temp;
    elseif x1==x2;
      x2 = x1+1;
    end
    if y1>y2;
      temp = y1;
      y1 = y2;
      y2 = temp;
    elseif y1==y2;
      y2 = y1+1;
    end
    set(handles.adjxone,'String',num2str(x1));
    set(handles.adjxtwo,'String',num2str(x2));
    set(handles.adjyone,'String',num2str(y1));
    set(handles.adjytwo,'String',num2str(y2));
    
    axis(axh,[x1 x2 y1 y2]);
  case {'checkbox6' 'checkbox4' 'checkbox3' 'gridcheckbox'}
    %Deal with grid, use main checkbox first then turn on minor/xy if
    %requested.
    if get(handles.gridcheckbox,'value')
      genb = 'on';
    else
      genb = 'off';
    end
  
    %Minor grid.
    if get(handles.checkbox3,'value')
      menb = 'on';
    else
      menb = 'off';
    end
    
    %Ygrid.
    if get(handles.checkbox4,'value')
      ygenb = 'on';
    else
      ygenb = 'off';
      if strcmpi(genb,'on')
        %If main grid on then let it take precedence.
        ygenb = 'on';
      end
    end
    
    %Xgrid.
    if get(handles.checkbox6,'value')
      xgenb = 'on';
    else
      xgenb = 'off';
      if strcmpi(genb,'on')
        %If main grid on then let it take precedence.
        xgenb = 'on';
      end
    end
    
    switch mytag
      case 'gridcheckbox'
        set(axh,'xgrid',genb,'ygrid',genb,'zgrid',genb);
      case 'checkbox3'
        set(axh,'xminorgrid',menb,'yminorgrid',menb,'zminorgrid',menb);
      case 'checkbox4'
        set(axh,'ygrid',ygenb);
      case 'checkbox6'
        set(axh,'xgrid',xgenb);
    end
    
  case {'edit5' 'edit6' 'edit7'}
    %Title/Label
    mylbls = {'Title' 'YLabel' 'XLabel'};
    myctrl = {'edit5' 'edit6' 'edit7'};
    idx = ismember(myctrl,mytag);
    hh = get(axh,mylbls{idx});
    if iscell(hh)
      hh = [hh{:}];
    end
    set(hh,'String',get(handles.(myctrl{idx}),'String'));

  case 'checkbox5'
   %Y Tick
    yt = get(handles.checkbox5,'value');
    if yt
      set(axh,'YTickMode','auto')
    else
      set(axh,'YTick',[]);
    end   
  case 'checkbox7'
    %XTick
    xt = get(handles.checkbox7,'value');
    if xt
      set(axh,'XTickMode','auto')
    else
      set(axh,'XTick',[]);
    end
  case 'checkbox10'
    %XDir
    xd = get(handles.checkbox10,'value');
    if xd
      set(axh,'XDir','reverse')
    else
      set(axh,'XDir','normal');
    end
  case 'checkbox11'
    %XTick
    yd = get(handles.checkbox11,'value');
    if yd
      set(axh,'YDir','reverse')
    else
      set(axh,'YDir','normal');
    end
end

%----------------------------------------------------
function btnok_Callback(hObject, eventdata, handles)
%OK button, apply new axis limits to axis and close.

fig = handles.axisadjust;
%btnapply_Callback(hObject, eventdata, handles);

allfigcolorchange = getappdata(fig,'AllFigColorChange');
if isempty(allfigcolorchange)
  myaxes  = getappdata(fig, 'otheraxes');
  mycolors = getappdata(fig, 'othercolors');
  if ~isempty(myaxes) & ~isempty(mycolors)
    for i = 1:size(myaxes,1);
      set(myaxes(i,:),'Color',mycolors{i});
    end
  end
end
delete(fig);

%----------------------------------------------------
function btncancel_Callback(hObject, eventdata, handles)
%OK button, apply new axis limits to axis and close.

btnok_Callback(hObject, eventdata, handles)

%----------------------------------------------------
function btnlocate_Callback(hObject, eventdata, handles)
%Bring figure to front and move gui to upper right edge.

targfig = getappdata(handles.axisadjust,'targfig');
tu = get(targfig, 'units');

set(handles.axisadjust,'units','pixels');
set(targfig,'units','pixels');

scrsize = getscreensize;
mfp = get(handles.axisadjust,'position');
tfp = get(targfig,'position');

if (tfp(1)+tfp(3)+mfp(3)+8) > scrsize(3)
  centerfigure(handles.axisadjust,targfig);
else
  %Reposition to right side of figure.
  mfp(1) = (tfp(1) + tfp(3)+8); %Plus 8 for window boundry.
  mfp(2) = (tfp(2) + tfp(4) - mfp(4));
  set(handles.axisadjust,'position',mfp);
  set(targfig, 'units',tu);
end

figure(targfig);
figure(handles.axisadjust);


%----------------------------------------------------
function gridcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to gridcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of gridcheckbox

btnapply_Callback(hObject, [], handles);  %automatically apply changes

%----------------------------------------------------
function applyall_Callback(hObject, eventdata, handles)
%Apply to all checkbox. Keep track of apply all status in appdata so
%switching figures doesn't setting.

fig = handles.axisadjust;
targfig = getappdata(fig, 'targfig');
if get(handles.checkbox9,'value')
  setappdata(targfig,'applyall',1);
else
  setappdata(targfig,'applyall',0);
end

%----------------------------------------------------
function pushbutton9_Callback(hObject, eventdata, handles)
%Set background color.

a = uisetcolor;%a=0 if user cancel.
if length(a)~=1
  hdls = getaxes(handles);
  set(hdls,'Color',a)
  if length(hdls)>1
    %If color is set on all axes then need to set flag so we don't restore
    %color to orginal when closing.
    setappdata(handles.axisadjust,'AllFigColorChange',1)
  end
end

%----------------------------------------------------
function allfont_Callback(hObject, eventdata, handles)
%Set background color.

fnt = uisetfont;
if ~isstruct(fnt)
  %user cancel
  return
end
axh = getaxes(handles);%Get selected handles.

%If multiple axes returned then cells are created with get command.
th = get(axh,'Title');
if ~iscell(th)
  th = {th};
end

yh = get(axh,'YLabel');
if ~iscell(yh)
  yh = {yh};
end

xh = get(axh,'XLabel');
if ~iscell(xh)
  xh = {xh};
end

switch get(hObject,'tag')
  case 'pushbutton6'
    %Title
    hndls = [th{:}];
  case 'pushbutton7'
    %Y label
    hndls = [yh{:}];
  case 'pushbutton8'
    %X label
    hndls = [xh{:}];
  case 'allfont'
    %Everything.
    hndls = [th{:} yh{:} xh{:} axh];
end


setfont(hndls,fnt)

% if isstruct(fnt)
%   set([get(getappdata(handles.axisadjust,'axishandle'),'Title'),...
%     get(getappdata(handles.axisadjust,'axishandle'),'YLabel'),...
%     get(getappdata(handles.axisadjust,'axishandle'),'XLabel')],...
%     'FontName',fnt.FontName,'FontSize',fnt.FontSize,'FontWeight',fnt.FontWeight)
% end

%----------------------------------------------------
function setfont(hh,fnt)
%Set fonts for given handles.

set(hh,'FontName',fnt.FontName,'FontSize',fnt.FontSize,'FontWeight',fnt.FontWeight)

%----------------------------------------------------
function axh = getaxes(handles)
%Get axes to use.

targfig = getappdata(handles.axisadjust, 'targfig');

%Apply to all axes.
if get(handles.checkbox9,'value')
  axh = findobj(targfig,'type','axes');
else
  axh = getappdata(handles.axisadjust,'axishandle');
end

%----------------------------------------------------
function myaxes = getotheraxes(handles)
%Get non target axes.

targfig = getappdata(handles.axisadjust, 'targfig');
myaxis = getappdata(handles.axisadjust,'axishandle');

myaxes = findobj(targfig,'type','axes');
myaxes = setdiff(myaxes, myaxis);
