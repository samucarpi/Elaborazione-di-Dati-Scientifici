function varargout = figbrowser(varargin)
%FIGBROWSER Browser with thumbnail icons of all MATLAB figures.
% The figbrowser function creates a figure containing thumbnail images of
% all visible MATLAB figures. Clicking on an icon will make that figure the
% current figure and bring it to the front. 
%
%INPUT(S):
%  varargin = stands for variable length input list. This list can have have
%  the following values.
%    empty             : (no input) Creates or updates current FIGBROWSER window.
%    ('focus')         : Brings the FIGBROWSER window to the front and updates
%                        if figures have been created or deleted since last
%                        update.
%    ('hide')          : Hides the FIGBROWSER window.
%    ('addmenu',h)     : Adds FIGBROWSER trigger menu to a figure with
%                        figure handle (h).
%    ('on')            : Turns on automatic addition of FIGBROWSER menu to all
%                        figures.
%             NOTE: menu addition can be permanently disabled by modifying the
%             'enableautoadd' option in FIGBROWSER. This option can be set using
%             SETPLSPREF. When set to 'off', FIGBROWSER will only show up on GUIs
%             that specifically add it themselves, no matter what FIGBROWSER
%             command is issued. This option can also be modified through the
%             "Figbrowser on All" menu item in all FIGBROWSER menus.
%    ('off')           : Removes FIGBROWSER menus from all figures.
%    ('autodock','on') : Turns on auto-docking of standard figures on
%                        creation. Auto-docking forces any standard figure to be
%                        opened in the Figure window.
%    ('autodock','off'): Turns off auto-docking.
%    ('centerall')     : Removes FIGBROWSER menus from all figures.
%
%I/O: figbrowser;           %no input (empty input)
%I/O: figbrowser(varargin); %non-empty input list
%
%See also: INITAXES, INITFIGURE

%hidden actions
%I/O: figbrowser('testforchange')
%       Tests for new/removed figures and updates figbrowser if necessary
%I/O: figbrowser('activate',target_figure)
%       Activates the indicated figure (brings it to the front)

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1;
  varargin = {'draw'};
end

switch lower(varargin{1})
  case {'addmenu'}
    feval(varargin{:}); % FEVAL switchyard
  case evriio([],'validtopics')
    options = [];
    options.name   = 'options';
    options.docked = 'off';
    options.autoadd = 'on';
    options.autodock = 'off';
    options.enableautoadd = 'on';
    
    if nargout==0
      evriio(mfilename,varargin{1},options)
    else
      varargout{1} = evriio(mfilename,varargin{1},options);
    end
    return;
  otherwise
    %     if nargout == 0;
    %normal calls with a function
    feval(varargin{:}); % FEVAL switchyard
    %     else
    %       [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    %     end
end

%---------------------------------------
function addmenu(varargin)

if isempty(varargin)
  varargin{1} = get(0,'currentfigure');
  if isempty(varargin{1}); return; end
end
figbrowserhandle = findobj(allchild(0),'tag','figbrowser');

evriwindowstyle(varargin{1});

if strcmp(get(varargin{1},'integerhandle'),'on')
  opts = figbrowser('options');
  if strcmp(opts.autodock,'on');
    evriwindowstyle(varargin{1},1);
  end
end

has_no_menus = [isempty(findobj(varargin{1},'type','uimenu')) & strcmp(get(varargin{1},'menubar'),'none')];
if has_no_menus;
  return;
end

nmenus = length(findobj(varargin{1},'type','uimenu'));
nblankmenus = length(findobj(varargin{1},'type','uimenu','label',''));
if nmenus>0 && nmenus==nblankmenus
  %   disp('denied - empty menus')
  %   beep
  return
end

% scrollzoom;
if (isempty(figbrowserhandle) | varargin{1}~=figbrowserhandle) & isempty(findobj(varargin{1},'tag','figbrowsermenu'));
  h1 = uimenu(varargin{1},'label','FigBrowser','callback','figbrowser menuupdate','tag','figbrowsermenu');
  
  h2 = uimenu(h1,'label','E&xport Figure','tag','figbroexportfigure');
  uimenu(h2,'label','&HTML','callback','reportwriter(''html'',gcbf)','tag','figbroexporthtml');
  if ispc
    uimenu(h2,'label','MS &Power Point','callback','exportfigure(''powerpoint'',gcbf)','tag','figbroexportppt');
    uimenu(h2,'label','MS &Word','callback','exportfigure(''word'',gcbf)','tag','figbroexportword');
  end
  
  %Add clipboard flyout.
  h3 = uimenu(h2,'label','&Clipboard','tag','figbroexportclipboard');
  uimenu(h3,'label','&Default','callback','exportfigure(''clipboard'',gcbf)','tag','figbroexportclipboarddefault');
  if ispc
    uimenu(h3,'label','&Windows Meta','callback','exportfigure(''clipboard_meta'',gcbf)','tag','figbroexportclipboardmeta');
  elseif ismac
    uimenu(h3,'label','&ScreenCaptuer','callback','exportfigure(''clipboard_macscreencapture'',gcbf)','tag','figbroexportclipboardscreencapture');
    uimenu(h3,'label','&BuiltIn (Matlab 2013a and Older)','callback','exportfigure(''clipboard_macold'',gcbf)','tag','figbroexportclipboardoldmac');
  end
  uimenu(h3,'label','&BitMap','callback','exportfigure(''clipboard_bitmap'',gcbf)','tag','figbroexportclipboardbitmap');
  uimenu(h3,'label','&GetFrame','callback','exportfigure(''clipboard_getframe'',gcbf)','tag','figbroexportclipboardgetframe');
  uimenu(h3,'label','&PDF','callback','exportfigure(''clipboard_pdf'',gcbf)','tag','figbroexportclipboardpdf');
  
  if evriio('mia')
    uimenu(h2,'label','&Export Current Image Axis','callback','figbrowser(''exportgcaimage'',gcbf)','tag','exportgcaasimage','separator','on');
  end
  
  uimenu(h2,'label','&Open Report Folder','callback','analysis(''report_callback'',[],[],[],''open'')','tag','figbroexportopen','separator','on');
  h2 = uimenu(h1,'label','Spawn Static &View','tag','spawnstaticview','callback','plotgui(''spawn'',gcbf)');
  
  uimenu(h1,'label','Workspace Browser','callback','browse','tag','figbrowserbrowser','separator','on');
  uimenu(h1,'label','Figure Thumbnails','callback','figbrowser focus','tag','updatefigbrowser');
  
  h2 = uimenu(h1,'label','Find Figure','callback','figbrowser listfigs','tag','figbrowserShowFig');
  h3 = uimenu(h2,'label','Command Window','callback','figbrowser hide; commandwindow','tag','cmdwindow');
  if ismac
    h4 = uimenu(h2,'label','Launch Mission Control','callback',@mac_windows,'tag','launchexpose');
  end
  if checkmlversion('<','7') | solo;
    set(h3,'visible','off');
  end
  
  h3 = uimenu(h1,'label','Copy Figure Size','callback','figbrowser copysize','separator','on','tag','figbrowsercopysize');
  h3 = uimenu(h1,'label','Paste Figure Size','callback','figbrowser pastesize','separator','off','tag','figbrowserpastesize');
  
  h3 = uimenu(h1,'label','Set Figure Theme','tag','figbrowsertheme','callback','figbrowser(''figbrowsertheme'')');
  h4 = uimenu(h3,'label','White','tag','figbrowserthemewhite','callback','figuretheme(gcbf,''w'')');
  h4 = uimenu(h3,'label','Black','tag','figbrowserthemeblack','callback','figuretheme(gcbf,''k'')');
  h4 = uimenu(h3,'label','Default','tag','figbrowserthemedefault','separator','on','callback','figuretheme(gcbf,''d'')');
  
  %   if ~solo | checkmlversion('<=','7.6')
  %not deployed or deployed in earlier version than R2008a, add dock
  %options (not available in R2008a+ when deployed)
  if ~solo
    %not deployed? give this menu item
    h3 = uimenu(h1,'label','Figbrowser on All','callback','figbrowser togglemenu','separator','on','tag','figbrowsertogglemenu');
    opts = figbrowser('options');
    if strcmp(opts.enableautoadd,'on')
      set(h3,'checked','on');
      allowautodock = 1;
    else
      allowautodock = 0;
    end
    sep = 'off';  %define separator for next item
  else
    %deployed in earlier Matlab
    opts = figbrowser('options');
    sep = 'on';  %define separator for next item
    allowautodock = 1;
  end
  h2 = uimenu(h1,'label','Dock This Window','callback','figbrowser dockfigure','separator',sep,'tag','forcedockmenu');
  h2 = uimenu(h1,'label','All Figures On Screen','callback','figbrowser centerall','separator','off','tag','allfiguresonscreen');
  h2 = uimenu(h1,'label','Auto-dock User Figures','callback','figbrowser toggleautodockmenu','separator','off','tag','autodockmenu');
  if strcmp(opts.autodock,'on') & allowautodock;
    set(h2,'checked','on');
  end
end
updateautoadd
% end

%---------------------------------------
function draw(varargin)

%find/create browser figure
figbh = findobj(allchild(0),'tag','figbrowser');
opts = figbrowser('options');

if isempty(figbh);
  
  figbh = figure('integerhandle','off','visible','off','tag','figbrowser');
  
  %set position and optional docking
  pos = [.1 .1 .8 .8];
  set(figbh,'units','normalized','position',pos);
  if strcmp(opts.docked,'on')
    evriwindowstyle(figbh,1);  %dock window
  end
  
  %create context menu
  conmenu = uicontextmenu;
  set(conmenu,'tag','maincontext');
  uimenu(conmenu,'label','Refresh','callback','figbrowser draw');
  
  %Menus
  h2 = uimenu(figbh,'label','File');
  uimenu(h2,'label','Refresh','callback','figbrowser draw');
  uimenu(h2,'label','Print...','callback','printdlg');
  uimenu(h2,'label','Close','separator','on','callback','close(gcbf)');
  h2 = uimenu(figbh,'label','Window','tag','figbrowsermenu','callback','figbrowser listfigs');
  if checkmlversion('>=','7')
    uimenu(h2,'label','Command Window','callback','figbrowser hide; commandwindow','tag','cmdwindow');
  else
    uimenu(h2,'label','Hide Figure Browser','callback','figbrowser hide','tag','windowhide');
  end
  
else
  updatedockstatus;
end
setappdata(figbh,'busy',1)    %set busy lockout
updateautoadd;

%find context menu and set up figure browser display settings
conmenu = findobj(figbh,'tag','maincontext');
set(figbh,...
  'color',[1 .99 .95],...
  'numbertitle','off',...
  'name','Figure Browser',...
  'menubar','none',...
  'toolbar','none',...
  'windowbuttonmotionfcn','figbrowser testforchange',...
  'BusyAction','cancel',...
  'uicontextmenu',conmenu,...
  'tag','figbrowser',...
  'visible','on');

%locate other figures
figs = double(findobj(allchild(0),'type','figure','visible','on'));
figs = setdiff(figs,figbh);

%reorder putting non-integer (i.e. GUI figures) first
intfigs = figs==fix(figs);
figs = figs([find(~intfigs);find(intfigs)]);

%run through list of figures grabbing image of each
figinfo = [];
for j=1:length(figs);
  figure(figs(j));
  pause(.1);
  
  if strcmp(opts.autoadd,'on')
    addmenu(figs(j));
  end
  figinfo(j).image = getframe(figs(j));
  figinfo(j).prop  = get(figs(j));
end
setappdata(figbh,'fig',figs);
setappdata(figbh,'figinfo',figinfo);

redrawfigure;

setappdata(figbh,'busy',0)    %set busy lockout
set(figbh,'handlevisibility','callback');
set(figbh,'resizefcn','figbrowser resize');

%-------------------------------------
function redrawfigure

figbh = findobj(allchild(0),'tag','figbrowser');
figs = getappdata(figbh,'fig');
figinfo = getappdata(figbh,'figinfo');

%get windows menu handle and remove figure items (will add again later)
% winmenuhandle = findobj(figbh,'tag','window');
% delete(findobj(winmenuhandle,'tag',''));

if isempty(figs);
  figs = [];
end

%create icons of each figure
figure(figbh); %drawnow;

%figure out how many plots we need (and fill in extra positions with
%blank placeholders)
if length(figs)<4;
  figs(end+1:4) = -1;
end

%calculate number of plots
number = length(figs);
pos    = get(figbh,'position');
sizeratio = min(pos(3:4))./max(pos(3:4));
sizeratio = min(0.5,sizeratio);
sn = round(number.^(sizeratio));
sm = ceil(number./sn);
if length(figs)<sm*sn;
  figs(end+1:sm*sn) = -1;
end

%wide figure? swap width/height
if pos(3)>pos(4);
  temp = sm;
  sm = sn;
  sn = temp;
end

%calculate spacing of axes
gutter = .01;
titlepad = .05;
axw = ((1-gutter)./sn-gutter);
axh = ((1-gutter)./sm-gutter-titlepad);

%create icon of each figure
delete(findobj(figbh,'type','axes'));
for j=1:length(figs);
  %   subplot(sm,sn,j);
  h = axes('parent',figbh);
  row = floor((j-1)./sn)+1;
  col = mod((j-1),sn)+1;
  pos = [(gutter+axw)*(col-1)+gutter  1-(gutter+axh+titlepad)*(row)  axw   axh];
  set(h,'position', pos)
  
  if figs(j)==-1;
    delete(h);
    continue
  end
  h = imagesc(uint8(figinfo(j).image.cdata));
  %   h = imagesc(uint8(coadd(coadd(double(figinfo(j).image.cdata),2,1),2,2)));
  axis image
  set(gca,'xtick',[],'ytick',[]);
  if figs(j)>0;
    set(h,'buttondownfcn','figbrowser(''activate'',getappdata(gcbo,''target''))');
    setappdata(h,'target',figs(j));
  else
    set(h,'buttondownfcn','figbrowser hide; commandwindow;');
  end
  
  ttl=[];
  if strcmp(figinfo(j).prop.NumberTitle,'on');
    ttl = ['Figure ' num2str(figs(j))];
  end
  if ~isempty(figinfo(j).prop.Name)
    if ~isempty(ttl);
      ttl = [ttl ': '];
    end
    ttl = [ttl figinfo(j).prop.Name];
  end
  h = title(ttl);
  if checkmlversion('>','6.1'); set(h,'backgroundcolor',[1 1 1]); end
  set(h,'interpreter','none');
  
  %add item to windows menu
  %   wh2 = uimenu(winmenuhandle,'label',ttl,'callback','figbrowser(''activate'',getappdata(gcbo,''target''))');
  %   if j==1;
  %     set(wh2,'separator','on');
  %   end
  %   setappdata(wh2,'target',figs(j));
  
end

%--------------------------------------
function resize(varargin)

if ~evriwindowstyle(gcbf)
  redrawfigure;
end

%--------------------------------------
function hide(varargin)

figbh = findobj(allchild(0),'tag','figbrowser');
if ~evriwindowstyle(figbh)
  set(figbh,'visible','off');
end

%---------------------------------------
function testforchange(varargin)

figbh = findobj(allchild(0),'tag','figbrowser');

if isempty(figbh)
  draw  %no figure? create one
else
  if getappdata(figbh,'busy')
    return; %do not start multiple test loops
  end
  
  setappdata(figbh,'busy',1)    %set test loop lockout
  try
    %look for change in figures
    fig = double(findobj(allchild(0),'type','figure','visible','on'));
    fig = setdiff(fig,figbh);  %remove browser itself from list
    
    oldfig = getappdata(figbh,'fig');
    
    if ~isempty(setdiff(oldfig,fig)) | ~isempty(setdiff(fig,oldfig))
      draw
    end
  catch
  end
  
  setappdata(figbh,'busy',0)  %clear test loop lockout
  
end

%----------------------------------------
function focus(varargin)

figbh = findobj(allchild(0),'tag','figbrowser');
if isempty(figbh);
  draw
else
  testforchange
  figure(figbh);
  drawnow
end

%---------------------------------------
function activate(varargin)

updatedockstatus
updateautoadd
hide
if ~isempty(varargin)
  figure(varargin{1});
end

%---------------------------------------
function updatedockstatus(varargin)

figbh = findobj(allchild(0),'tag','figbrowser');

%check if the user has docked/undocked the controls and remember that for next time
opts = figbrowser('options');
if evriwindowstyle(figbh) & strcmp(opts.docked,'off')
  setplspref('figbrowser','docked','on');
elseif ~evriwindowstyle(figbh) & strcmp(opts.docked,'on')
  setplspref('figbrowser','docked','off');
end

%---------------------------------------
function updateautoadd(varargin)

tempopts = figbrowser('options');
if nargin<1;
  opts = tempopts;
else
  opts = varargin{1};
end
addcmd = ';try;figbrowser(''addmenu'');catch;end;';
createfcn = get(0,'defaultfigurecreatefcn');

if ~solo
  %not deployed? use enableautoadd setting
  if strcmp(tempopts.enableautoadd,'off')
    %if enableautoadd is "off" force autoadd to "off"
    opts.autoadd = 'off';
    setplspref('figbrowser','autoadd','off');
  end
end

if ischar(createfcn)%User might have function handle in defaultfigurecreatefcn
  pos = findstr(addcmd,createfcn);
  if ~solo
    if ~isempty(pos)
      %Remove default fig create fcn for Matlab, it causes to many problems
      %for customers doing own development. Big problems with AppDesigner.
      %It's also not used. 
      thisfunc = strrep(createfcn,addcmd,'');
      set(0,'defaultfigurecreatefcn',thisfunc);
    end
  else
    if strcmp(opts.autoadd,'on')
      if isempty(pos)
        set(0,'defaultfigurecreatefcn',[createfcn addcmd]);
      end
    else
      if ~isempty(pos)
        createfcn(pos:(pos+length(addcmd)-1)) = [];  %remove command
        set(0,'defaultfigurecreatefcn',createfcn);
      end
    end
  end
  
end

initaxes;  %add right-click sensing for axes

%--------------------------------------
function togglemenu
%turn enableautoadd on/off by menu

opts = figbrowser('options');

switch opts.enableautoadd
  case 'off'
    en = 'on';
  otherwise
    en = 'off';
end
setplspref('figbrowser','enableautoadd',en);
setplspref('figbrowser','autoadd',en);
opts.autoadd = en;
opts.enableautoadd = en;
updateautoadd(opts);

if strcmp(en,'on');
  figbrowser on
end

%--------------------------------------
function toggleautodockmenu
%turn autodock on/off by menu

opts = figbrowser('options');

switch opts.autodock
  case 'off'
    en = 'on';
  otherwise
    en = 'off';
end
autodock(en);
if strcmp(en,'on');
  figbrowser on
end

%--------------------------------------
function on(varargin)

updateautoadd(struct('autoadd','on'));
if ~nargin | ~ishandle(varargin{1})
  %add for ALL figures
  for fig = findobj(allchild(0),'type','figure')';
    addmenu(fig);
  end
else
  %add for a SPECIFIC figure
  addmenu(varargin{1})
end

%--------------------------------------
function off(varargin)

updateautoadd(struct('autoadd','off'));
figbh = findobj(allchild(0),'tag','figbrowser');
if ishandle(figbh)
  delete(figbh);
end
figbh = findobj(allchild(0),'tag','figbrowsermenu');
if ~isempty(figbh);
  delete(figbh);
end

%-------------------------------------
function autodock(varargin)
%controls auto-dock feature (force figures into docking window)

if nargin<1;
  varargin = {'factory'};
end
setplspref('figbrowser','autodock',varargin{1});

%-------------------------------------
function menuupdate

figuretheme(gcbf);

opts = figbrowser('options');
if ~solo
  set(findobj(gcbo,'tag','figbrowsertogglemenu'),'checked',opts.enableautoadd);
end
if checkmlversion('==','6.5')
  set(findobj(gcbo,'tag','autodockmenu'),'checked','off','visible','off');
  set(findobj(gcbo,'tag','forcedockmenu'),'checked','off','visible','off');
elseif (strcmp(opts.enableautoadd,'on') | solo)
  %7.x matlab or higher + deployed OR Enable Auto Add is on
  set(findobj(gcbo,'tag','autodockmenu'),'checked',opts.autodock,'enable','on','visible','on');
  if evriwindowstyle(gcbf)
    ch = 'on';
  else
    ch = 'off';
  end
  set(findobj(gcbo,'tag','forcedockmenu'),'checked',ch,'visible','on','enable','on');
else
  set(findobj(gcbo,'tag','autodockmenu'),'checked','off','enable','off','visible','on');
  set(findobj(gcbo,'tag','forcedockmenu'),'checked','off','visible','off','enable','off');
end

%-------------------------------------
function listfigs
%Create submenu of open windows.

if ismac & checkmlversion('>=','7.12')
  %Mac 2011a will use Expose menu item.
  return
end

h = gcbo;
figs = unique(findobj(findall(0),'type','figure','visible','on'));
inthandle = ismember(get(figs,'integerhandle'),{'on'});

figs = [figs(find(~inthandle));figs(find(inthandle))];

names = get(figs,{'name'});
numtitle = ismember(get(figs,'numbertitle'),{'on'});

temph = uimenu('label','temp','tag','temp');
delete(findobj(h,'tag',''))
for j=1:length(figs);
  if numtitle(j);
    lbl = ['Figure ' num2str(double(figs(j)))];
    if ~isempty(names{j});
      lbl = [lbl ': ' names{j}];
    end
    names{j} = lbl;
  end
  h1 = uimenu(h,'label',names{j},'callback',['figure(get(gcbo,''userdata''));'],'userdata',figs(j));
  if j==1 & checkmlversion('>=','7') & ~solo
    set(h1,'separator','on');
  end
end
delete(temph);

%--------------------------------------------
function dockfigure(varargin)

switch get(gcbo,'checked')
  case 'off'
    style = 1;
  case 'on'
    style = 0;
end
evriwindowstyle(gcbf,style)

%--------------------------------------------
function out = solo

if ~exist('isdeployed') | ~isdeployed;
  out = 0;
else
  out = 1;
end

%---------------------------------------
function copysize(varargin)

if isempty(varargin)
  varargin{1} = gcf;
end
sz = get(varargin{1},'position');
clipboard('copy',sz(3:4));

%---------------------------------------
function pastesize(varargin)

if isempty(varargin)
  varargin{1} = gcf;
end
fig = varargin{1};
sz = get(fig,'position');
newsz = str2num(clipboard('paste'));
try
  set(fig,'position',[sz(1:2) newsz]);
  positionmanager(fig,'onscreen')
catch
  evrierrordlg('Invalid figure size on clipboard.','Paste Figure Size Error');
end

%----------------------------------------
function figbrowsertheme(varargin)

menu = gcbo;
fig = gcbf;
settings = figuretheme(fig);
clr = 'default';
if ~isempty(settings)
  if all(settings.color==[1 1 1])
    clr = 'white';
  elseif all(settings.color==[0 0 0])
    clr = 'black';
  end
end
set(allchild(menu),'checked','off')
if ~isempty(clr);
  set(findobj(menu,'tag',['figbrowsertheme' clr]),'checked','on')
end

%----------------------------------------
function mac_windows(varargin)
%Open windows viewer (expose or Mission Control).

if exist('/Applications/Mission Control.app/Contents/MacOS/Mission Control','file')
  %OS X 10.7 to 10.9.
  try;system('/Applications/Mission\ Control.app/Contents/MacOS/Mission\ Control 2');end
elseif exist('/Applications/Utilities/Expose.app/Contents/MacOS/Expose 2','file')
  %Old version, pre OS X 10.7.
  try;system('/Applications/Utilities/Expose.app/Contents/MacOS/Expose 2');end
end

%--------------------------------------
function centerall(varargin)

figs = unique(findobj(findall(0),'type','figure'));
for i = 1:length(figs)
  positionmanager(figs(i),'onscreen');
end

%--------------------------------------
function exportgcaimage(varargin)
%If GCA is am image the try an export. Menu item that calls this funciton
%doesn't get displayed unless MIA Toolbox installed.

myax = gca;
myimg = findobj(myax,'type','image');
if isempty(myimg)
  evriwarndlg('Image not found on current axes. Try clicking on axes then returning to export menu.','No Image Found');
  return
end
mycdata = scaletouint8(get(myimg,'cdata'));
mymap = get(gcf,'colormap');
RGBdata = ind2rgb(mycdata,mymap);

myfilter = {'*.gif', 'Graphics Interchange Format (*.gif)';...
  '*.jpg','Joint Photographic Experts Group (*.jpg)';...
  '*.png','Portable Network Graphics (*.png)';...
  '*.tif','Tagged Image File Format (*.tif)'};

[filename, pathname, filterindex] = uiputfile(myfilter);

if filename == 0
  %User cancel.
  return
end

imwrite(RGBdata,fullfile(pathname,filename));

