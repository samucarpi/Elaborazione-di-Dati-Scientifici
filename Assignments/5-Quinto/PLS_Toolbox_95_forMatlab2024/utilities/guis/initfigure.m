function varargout = initfigure(varargin)
%INITFIGURE Initialization code for solo figures.
% Adds menus and objects to integer handle figures for use in compiled
% environment. Used in create figure callback as default.
%
% OPTIONS:
%   linestyle     = {'Solid' 'Dash' 'Dot' 'Dash-Dot' 'None'} Line style.
%   linestylecode = {'-' '--' ':' '-.' 'none'} Line style symbol code, must be in same order as .linestyle option. 
%   linewidth     = {'0.5' '1.0' '2.0' '3.0' '4.0' '5.0' '6.0' '7.0' '8.0' '9.0' '10.0'} Line width. 
%   markerstyle   = {'+','o','*','.','x','Square','Diamond','v','^','>','<','Pentagram','Hexagram','None'} Marker style. 
%   markersize    = {'2' '4' '5' '6' '7' '8' '10' '18' '24' '48'} Marker size. 
%
%I/O: initfigure()
%I/O: initfigure(h)
%
%See also: FIGBROWSER, INITAXES

% Copyright © Eigenvector Research, Inc. 2003
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%RSK 09/01/2006


%NOTE: The edit plot functionality isn't supported in compiled applications
%so use custom prop editor (ajustaxislimitsgui). When in edit mode in
%compiled app, right clicks add menus to figure not to context menu. We
%might be able to get this functionality back by hacking the figure to
%monitor when menus are added and swap them into a context menu... or spoof
%context menu to mimic native menu.

if nargin == 0
  h = gcbf;
  varargin = {'setup', gcbf};
elseif ishandle(varargin{1})
  %Passed a target figure, go to setup.
  varargin = {'setup', varargin{1}};
end

switch varargin{1}
  case {'options' 'io'} %cat(2,evriio([],'validtopics'));
    options = [];
    options.linestyle   = {'Solid' 'Dash' 'Dot' 'Dash-Dot' 'None'};
    options.linestylecode = {'-' '--' ':' '-.' 'none'};
    options.linewidth   = {'0.5' '1.0' '2.0' '3.0' '4.0' '5.0' '6.0' '7.0' '8.0' '9.0' '10.0'};
    options.markerstyle = {'+','o','*','.','x','Square','Diamond','v','^','>','<','Pentagram','Hexagram','None'};
    options.markersize  = {'2' '4' '5' '6' '7' '8' '10' '18' '24' '48'};
    if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return;
  otherwise
    try
      if nargout == 0;
        feval(varargin{:});
      else
        [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
      end;
    catch
      error(['Invalid input to function. ' lasterr])
    end
end
%---------------------------------------------------
function on

addcmd = ';try;drawnow;initfigure(gcf);catch;end;';
createfcn = get(0,'defaultfigurecreatefcn');
pos = findstr(addcmd,createfcn);
if isempty(pos)
  set(0,'defaultfigurecreatefcn',[createfcn addcmd]);
end

%---------------------------------------------------
function setup(h)
%Initial add of menus to figures.

%turn on dockable status (note: all figures)
evriwindowstyle(h);

if ~strcmp(get(h,'integerhandle'),'on')
  %Only add menus to integer handle figures.
  return
end

if ~isempty(findobj(h,'tag','evrieditmenu'));
  %don't add if already there.
  return;
end

%Add edit menu.
edith = uimenu(h,'Label','Edit','tag','evrieditmenu',...
  'CallBack', 'initfigure(''editmenucb'',gcbf)');
%Add edit menu sub menus.
uimenu(edith,'Label','&Axes Properties','tag','adjustmenu','CallBack',...
  'adjustaxislimitsgui(gcbf)');
h2=uimenu(edith,'Label','&Axes Font Settings','tag','editfont','CallBack',...
  '');
uimenu(h2,'Label','&Current Axes','tag','editfontcurrent','Callback',...
  'initfigure(''setfont'')');
uimenu(h2,'Label','&All Axes','tag','editfontall','separator','on','CallBack',...
  'initfigure(''setfont'',''all'')');
%Make this menu not visible, editing in compiled app is not supported.
uimenu(edith,'Label','&Edit Figure Objects','tag','editplotmenu','separator','on','CallBack',...
  'initfigure(''editplotmenucb'',gcbo,gcbf)','visible','off');

%Make this menu not visible, editing in compiled app is not supported.
uimenu(edith,'Label','&Add Line Edit Menus','tag','editaddplotmenu','separator','on','CallBack',...
  'initfigure(''editaddmenucb'',gcbo,gcbf)','visible','on');

%---------------------------------------------------
function editmenucb(figureh)
%Enable/disable menu items if axis present.

handles = guihandles(gcbf);

childmenush = get(handles.evrieditmenu,'children');
set(childmenush,'enable','off');

%Enable submenus that ajust axis objects if figure has an axis.
myaxis = get(figureh,'CurrentAxes');
if ~isempty(myaxis)
  set(handles.adjustmenu,'enable','on');
  set(handles.editfont,'enable','on');
  set(handles.editfontcurrent,'enable','on');
  if length(findobj(gcbf,'type','axes'))>1
    enb = 'on';
  else
    enb = 'off';
  end
  set(handles.editfontall,'enable',enb);
  
  if isappdata(gcbf,'scribeActive') & strcmp(getappdata(gcbf,'scribeActive'),'on');
    ch = 'on';
  else
    ch = 'off';
  end
  set(handles.editplotmenu,'enable','on','checked',ch);
end

set(handles.editaddplotmenu,'enable','on');

%---------------------------------------------------
function editaddmenucb(menuh, figureh)
%Find all child axes and child lines and add cmenu to them.

h0 = findobj(figureh,'tag','ploteditmenu');

if isempty(h0)
  %create menu if it doesn't exist
  options = initfigure('options');
  h0 = uicontextmenu('parent',figureh,'tag','ploteditcontextmenu');
  makelineediemenu(h0,options);
end

h1 = get(h0,'Children');
myax = findobj(figureh,'type','axes');

for i = 1:length(myax)
  %Get line objects
  mylns = findobj(myax(i),'type','line');
  for j = 1:length(mylns)
    thismenu = get(mylns(j),'UIContextMenu');
    if isempty(thismenu);
      %Add menu.
      set(mylns(j),'UIContextMenu',h0);
    else
      %Add submenu if not already there.
      menutags = get(allchild(thismenu),'tag');
      if ~any(ismember(menutags,'edit_linecolor'))
        evricopyobj(h1,thismenu);
      end
    end
    
  end
end

%---------------------------------------------------
function makelineediemenu(h0,options)
%Make line edit menu.
% Use MATLAB/toolbox/matlab/graph2d/@editline/editline.m
% Use MATLAB/toolbox/matlab/scribe/private/createScribeUIMenuEntry.m


%Color
ls = uimenu(...
  'Label','Line Color',...
  'Callback', 'initfigure(''editLineCallback'',gcbo,gcbf,''color'',''color'')',...
  'Parent',h0,...
  'Separator','On',...
  'Tag','edit_linecolor');

%Line style.
lbls = options.linestyle;
ls = uimenu(...
  'Label','Line Style',...
  'Callback', 'initfigure(''editLineCallback'',gcbo,gcbf,''linestyle'',''parent'')',...
  'Parent',h0,...
  'Tag','edit_linestyle');

makesubmenus(ls,'linestyle',lbls)

%Line size.
lbls = options.linewidth;
ls = uimenu(...
  'Label','Line Width',...
  'Callback', 'initfigure(''editLineCallback'',gcbo,gcbf,''linewidth'',''parent'')',...
  'Parent',h0,...
  'Tag','edit_linewidth');

makesubmenus(ls,'linewidth',lbls)

%Maker style.
lbls = options.markerstyle;
ls = uimenu(...
  'Label','Marker Style',...
  'Callback', 'initfigure(''editLineCallback'',gcbo,gcbf,''markerstyle'',''parent'')',...
  'Parent',h0,...
  'Tag','edit_markerstyle');

makesubmenus(ls,'markerstyle',lbls)

%Marker size.
lbls = options.markersize;
ls = uimenu(...
  'Label','Marker Size',...
  'Callback', 'initfigure(''editLineCallback'',gcbo,gcbf,''markersize'',''parent'')',...
  'Parent',h0,...
  'Tag','edit_markersize');

makesubmenus(ls,'markersize',lbls)
%----------------------------------------------------------------------%
function makesubmenus(pm,pname,lbls)
%Add sub menus to parent.

for i=1:length(lbls)
  uimenu(pm,...
    'Label',lbls{i},...
    'Separator','off',...
    'Visible','on',...
    'Tag', [pname '_item' num2str(i)], ...
    'Callback',['initfigure(''editLineCallback'',gcbo,gcbf,''' pname ''',''' lbls{i} ''')']);
end

%---------------------------------------------------
function editplotmenucb(menuh, figureh)
%Edit Plot menu item callback.

%Update menu checked property.
if isappdata(figureh,'scribeActive') & strcmp(getappdata(figureh,'scribeActive'),'on');
  set(menuh,'Checked','off')
  plotedit(figureh,'off')
else
  set(menuh,'Checked','off')
  plotedit(figureh,'on')
end

%---------------------------------------------------
function setfont(mode,stat)

if nargin<1;
  mode = 'one';
end

axh = gca;
if nargin<2
  stat = uisetfont(axh);
end
if isstruct(stat);
  %if they didn't cancel out of uisetfont, apply to all other items
  if strcmp(mode,'all')
    targ = findobj(gcbf,'type','axes');
  else
    targ = axh;
  end
  for j=1:length(targ);
    set([targ(j); findobj(allchild(targ(j)),'type','text')],...
      'fontname',stat.FontName,...
      'fontunits',stat.FontUnits,...
      'fontsize',stat.FontSize,...
      'fontweight',stat.FontWeight,...
      'fontangle',stat.FontAngle);
  end
end

%---------------------------------------------------
function editLineCallback(menuh,fig,varargin)
%Switchyard callback for editing of line objects.

mode  = varargin{1};
style = varargin{2};
opts  = initfigure('options');
handles = guihandles(fig);

lnobj = gco;
if isempty(lnobj)
  try
    set(0,'showhiddenhandles','on')
    lnobj = gco;
    set(0,'showhiddenhandles','off')
  catch
    set(0,'showhiddenhandles','off')
  end
end

if isempty(lnobj) | ~strcmpi(get(lnobj,'type'),'line')
  return
end

%If doing a parent menu update of children check all off here so we don't
%have to repeat a lot of code.
if strcmp(style,'parent')
  chlds = allchild(menuh);
  set(chlds,'checked','off');
end

switch mode
  case 'color'
    c = uisetcolor(lnobj,'Line Color');
  case 'linestyle'
    if strcmp(style,'parent')
      myval = find(ismember(opts.linestylecode,get(lnobj,'LineStyle')));
      set(handles.(['linestyle_item' num2str(myval)]),'checked','on');
    else
      newval = opts.linestylecode(ismember(opts.linestyle,style));
      set(lnobj,'LineStyle',newval{:});
    end
  case 'linewidth'
    if strcmp(style,'parent')
      myval = find(str2double(opts.linewidth)==get(lnobj,'LineWidth'));
      set(handles.(['linewidth_item' num2str(myval)]),'checked','on');
    else
      set(lnobj,'LineWidth',str2double(style));
    end
  case 'markerstyle'
    if strcmp(style,'parent')
      myval = find(ismember(lower(opts.markerstyle),get(lnobj,'Marker')));
      set(handles.(['markerstyle_item' num2str(myval)]),'checked','on');
    else
      set(lnobj,'Marker',lower(style));
    end
  case 'markersize'
    if strcmp(style,'parent')
      myval = find(str2double(opts.markersize)==get(lnobj,'MarkerSize'));
      set(handles.(['markersize_item' num2str(myval)]),'checked','on');
    else
      set(lnobj,'MarkerSize',str2double(style));
    end
    
end





