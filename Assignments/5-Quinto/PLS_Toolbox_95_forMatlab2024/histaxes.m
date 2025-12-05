function fig = histaxes(source,mode,options)
%HISTAXES Creates a histogram of the content of a given axes.
% Creates a multi-layer smoothed histogram of all line objects on a given
% axes. The histograms are interpolated for cleaner viewing and the order
% of the layers can be changed by clicking on the individual histogram
% layers (one click brings a layer to the front, another sends it to the
% back). Objects with two or fewer points are not included in the
% histogram.
%
%OPTIONAL INPUTS:
%   source = The figure or axes handle to histogram (default is the current
%             axes; if a figure is supplied, the current axes on that
%             figure is used)
%
%     mode = The mode of the axes to histogram (either 'x', 'y', 'z' or
%             'xy'; default is 'x'.) 'xy' creates histograms of both axes
%             (in separate windows.)
%
%  options = A structure with one or more of the following fields:
%     transparency : [60] Percent transparency for the layered histogram
%                     pieces.
%            nbins : [] The number of histogram bins to use (empty = choose
%                     the number of bins depending on the total number of
%                     points in the largest object on the axes. That number
%                     of points / 2 is the default.)
%         fraction : [ {false} | true ] Governs units of histogram between
%                     fractional units (true) and absolute count (false).
%                     When fractional units are shown, each region is
%                     plotted as the fraction of items at the given value.
%          usebars : [ {false} | true ] Governs if plot should be shown as
%                     bars or as a density (smoothed) histogram
%         showmean : [ false | {true} ] Governs if mean of each region
%                     should be shown on the plot.
%          showstd : [ false | {true} ] Governs if standard deviation of
%                     each region should be shown on the plot.
%          maxbins : [30] The maximum number of bins allowed in a histogram
%                     (overrides automatic selection of nbins.)
%           figure : [] Target figure for histogram. If empty, a new figure
%                     is created to contain the histogram.
%         targmode : [ 'x' | 'y' | '' ] Defines which axes the histogram
%                     should be drawn on. If empty, targmode will match the
%                     mode input (y or z goes to targmode 'y', x to 'x')
%            quiet : [ true | {false} ] If false, the source figure will be
%                     brought to front after histogram figure is generated.
%                     When true, the histogram figure remains on top.
%
%OUTPUTS:
%    fig = handle of the created histogram figure.
%
%I/O: histaxes
%I/O: fig = histaxes(source,mode,options)

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1
  source = [];
end
if ischar(source) & ismember(source,evriio([],'validtopics'))
  options = [];
  options.targmode = '';  
  options.transparency = 60;
  options.fraction = false;
  options.usebars = false;
  options.showmean = true;
  options.showstd  = false;
  options.nbins   = [];
  options.maxbins = 30;
  options.figure  = [];
  options.quiet   = false;
  options.usesourcelims = true;
  if nargout==0; evriio(mfilename,source,options); else; fig = evriio(mfilename,source,options); end
  return
end

%sout out inputs and give defaults
if nargin<3;
  options = [];
end
if nargin<2;
  mode = [];
end
if isstruct(mode)
  options = mode;
  mode = [];
elseif isstruct(source)
  options = source;
  source = [];
end
if ~isempty(source) & ischar(source)
  mode = source;
  source = [];
end
if isempty(source)
  cf = get(0,'currentfigure');
  if isempty(cf); return; end
  source = get(cf,'currentaxes');
  if isempty(source); return; end
end
if isempty(mode)
  mode = 'x';
end
options = reconopts(options,mfilename);

if strcmpi(mode,'xy')
  %do BOTH axes (recursive call)
  histaxes(source,'x',options);
  histaxes(source,'y',options);
  return
end

%validate source and get axes
if ~ishandle(source) | ~ismember(get(source,'type'),{'figure' 'axes'})
  error('Source is not a valid figure or axes handle.')
end
if strcmp(get(source,'type'),'figure')
  source = get(source,'currentaxes');
end
sourcefig = get(source,'parent');

%get children of the axes
obj = get(source,'children');
if isempty(obj); return; end
obj(~ismember(get(obj,'type'),{'line'})) = [];
if isempty(obj)
  error('Histogram works only with "line" objects and cannot be made from the content of this plot.');
end

%get x and y data from objects on axes
xdata = get(obj,'xdata');
ydata = get(obj,'ydata');
zdata = get(obj,'zdata');
if ~iscell(xdata)
  xdata = {xdata};
end
if ~iscell(ydata)
  ydata = {ydata};
end
if ~iscell(zdata)
  zdata = {zdata};
end

%filter out unwanted items
xlen = cellfun('length',xdata);
if max(xlen)>2;
  filter = find(xlen==2);
  obj(filter) = [];
  xdata(filter) = [];
  ydata(filter) = [];
end

%get mode-specific settings
pos = get(0,'defaultfigureposition');
sourcepos = get(sourcefig,'position');
if ~ischar(mode) | ~ismember(mode,{'x' 'y' 'z'})
  error('Mode must be ''x'', ''y'', ''z'', or ''xy''')
end
switch mode
  case 'x'
    data       = xdata;
    otherdata  = ydata;
    pos([1 3]) = sourcepos([1 3]);  %position below source figure
    pos(2) = sourcepos(1)-pos(4);
    scale  = get(source,'xscale');
    ylbl   = get(get(source,'xlabel'),'string');
    if isempty(options.targmode); options.targmode = 'x'; end
  case 'y'
    data       = ydata;
    otherdata  = xdata;
    pos([2 4]) = sourcepos([2 4]);  %position to right of source figure
    pos(1) = sourcepos(1)+sourcepos(3);
    scale  = get(source,'yscale');
    ylbl   = get(get(source,'ylabel'),'string');
    if isempty(options.targmode); options.targmode = 'y'; end
  case 'z'
    data       = zdata;
    otherdata  = xdata;
    pos([2 4]) = sourcepos([2 4]);  %position to right of source figure
    pos(1) = sourcepos(1)+sourcepos(3);
    scale  = get(source,'zscale');
    ylbl   = get(get(source,'zlabel'),'string');
    if isempty(options.targmode); options.targmode = 'y'; end
end
if options.fraction
  xlbl = 'Fraction of Items';
else
  xlbl   = 'Count of Items';
end

%determine the histogram range
len = cellfun('length',data);
alldata = cat(2,data{:});
if isempty(options.nbins)
  options.nbins = min(ceil(max(len)/2),options.maxbins);
end
if isempty(alldata);
  error('No data on mode "%s" for this plot',mode);
end
if strcmpi(scale,'log')
  alldata = real(log10(alldata));
  ylbl    = ['Log of ' ylbl];
end
[junk,bins] = hist(alldata,options.nbins);
step = mean(diff(bins));
bins = [bins(1)-step*(3:-1:1) bins bins(end)+step*(1:3)]; %add leading and trailing bins

%adjust position of bins to best match data positions
rounded = (round((alldata-bins(1))/step)*step + bins(1));
isfin = isfinite(alldata) & isfinite(rounded);
offset = polyfit(alldata(isfin),rounded(isfin),1);
bins = polyval(offset,bins);

%get individual xdata histograms
hy = [];
for j=1:length(data);
  data{j}(isnan(otherdata{j})) = nan;
  mydata = data{j};
  if strcmpi(scale,'log')
    mydata = real(log10(mydata));
  end
  [hy(j,:),hx] = hist(mydata,bins);
  if options.fraction
    hy(j,:) = hy(j,:)./sum(hy(j,:));
  end
end

%reorder to put lowest count on top
[mwhat,mwhere] = max(hy,[],1);
compare = find(mwhat<sum(hy,1));  %these are the only columns where we have overlap
if ~isempty(compare)
  %find out which rows are most frequently overlapped by others and
  %sort in increasing order (so most overlapped are in front)
  ny = size(hy,1);
  rowrank = zeros(ny,length(compare));
  v = 1:ny;
  voids = sum(hy==0);
  for j=1:length(compare);
    [swhat,swhere] = sort(hy(:,compare(j)));
    temp = zeros(ny,1);
    temp(swhere) = v;
    temp = max(temp - voids(compare(j)),0);
    temp = temp/max(temp);
    rowrank(:,j) = temp;
  end
  [junk,order]=sort(-sum(rowrank,2));
  
  hy  = hy(order,:);
  obj = obj(order);
  data = data(order);
end

if ~options.usebars
  %interpolate to get smooth curves in place of bins
  hxi = interp1(1:length(bins),bins,linspace(1,length(bins),length(bins)*8));
  hyi = interp1(bins',hy',hxi,'pchip')';
  if size(hyi,2)==1; hyi=hyi'; end
  hyi(hyi<0)=0;
else
  hxi = bins;
  hyi = hy;
end

%create figure
if isempty(options.figure) | ~ishandle(options.figure);
  fig = figure('position',pos);
else
  fig = options.figure;
  figure(fig);
  delete(findall(fig,'type','axes'))
end
set(fig,'name','Data Histogram');
setappdata(fig,'histogram_source',source)
setappdata(fig,'histogram_mode',mode)
setappdata(fig,'histogram_options',options)
set(fig,'closerequestfcn',@closefig)
figbrowser on

if ~options.usebars
  %add patches
  for j=1:size(hyi,1);
    switch options.targmode
      case 'x'
        onex = hxi;
        oney = hyi(j,:);
      case {'y' 'z'}
        oney = hxi;
        onex = hyi(j,:);
    end
    bh(j) = patch(onex,oney,'k');
    set(bh(j),'zdata',onex.*0+j);
  end
  edgeprop = 'edgecolor';
  faceprop = 'facecolor';
  set(bh,'facealpha',1-options.transparency/100)
else
  if strcmpi(options.targmode,'y')
    bh = barh(hxi',hyi');
  else
    bh = bar(hxi',hyi');
  end
  edgeprop = 'edgecolor';
  faceprop = 'facecolor';
end

%Get limits, new default is to match source.
if options.usesourcelims
  mylim = get(source,[options.targmode 'lim']);
else
  %adjust axisscales and add labels
  %this is the old default.
  mylim = [bins(2) bins(end-1)];
end
set(gca,[options.targmode 'lim'],mylim);

if strcmpi(options.targmode,'x')
  %if x mode, do labels in opposite order
  xlabel(ylbl);
  ylabel(xlbl);
else
  ylabel(ylbl);
  xlabel(xlbl);
end
box on

%add mean markers
mh = [];
switch options.targmode
  case 'x'
    stf = @vline;
  otherwise
    stf = @hline;
end
for j=1:size(hyi,1);
  jdata=data{j};
  jdata(isnan(jdata))=[];
  mymean = mean(jdata);
  mystd = std(jdata);
  if options.showmean
    mh(j,1) = stf(mymean);
  else
    mh(j,1) = nan;
  end
  if options.showstd
    mh(j,2:3) = [stf(mymean-mystd,'--') stf(mymean+mystd,'--')];
  else
    mh(j,2:3) = nan;
  end
end

%change bar colors to match objects on original plot
lbls = {};
for j=1:length(obj)
  if ~strcmpi(get(obj(j),'marker'),'none')
    if strcmpi(get(obj(j),'markerEdgeColor'),'auto')
      %use marker face color
      euse = 'Color';
      fuse = 'MarkerFaceColor';
    else
      euse = 'MarkerEdgeColor';
      fuse = 'MarkerFaceColor';
    end
  else
    euse = 'Color';
    fuse = 'Color';
  end
  
  eclr = get(obj(j),euse);
  fclr = get(obj(j),fuse);
  if ischar(fclr) & strcmpi(fclr,'none')
    fclr = eclr;
  end
  %add color and label to main object
  set(bh(j),edgeprop,eclr,faceprop,fclr);
  ln = legendname(obj(j)); 
  lbls{j} = ln{:};
  legendname(bh(j),ln);
  setappdata(bh(j),'stats',mh(j,:)); %and store stats associated with it
  
  %add color and labels to any existing stats
  set(mh(j,isfinite(mh(j,:))),'color',eclr);  
  if isfinite(mh(j,1))
    legendname(mh(j,1),['Mean ' ln{:}]);
  end
  if isfinite(mh(j,2))
    legendname(mh(j,2),['-Std ' ln{:}]);
    legendname(mh(j,3),['+Std ' ln{:}]);
  end
end
set(bh,'userdata','histobj','buttondownfcn',@tofront)

%create DSO of the data
dso = dataset(hyi);
dso.axisscale{2} = hxi;
dso.axisscalename{2} = xlbl;
dso.label{1} = lbls;
myid = getappdata(fig,'histogram_data');
if isempty(myid)
  myid = setshareddata(fig,dso,struct('itemType','histogram'));
else
  myid.object = dso;
end
setappdata(fig,'histogram_data',myid);

%add toolbar
if isempty(findobj(fig,'tag','histaxestb'))
  tb = {
    'edit'         'editdata'        @editdata         'enable'    'Save Histogram Data'       'off'    'push'
    'Transpose'    'transposeimg'    @transposehist    'enable'    'Swap X & Y (rotate)'       'on'    'push'
    'bglayer'      'transparency'    @showtransmenu    'enable'    'Change Layer Transparency' 'off' 'push'
    'options'      'options'         @viewoptions      'enable'    'View Plot Options'         'off' 'push'
    'undo'         'reloadplot'      @reload           'enable'    'Update Histogram'          'on'  'push'
    'minus'        'decbinning'      @decbinning       'enable'    'Decrease Binning'          'off'  'push'
    'plus'         'incbinning'      @incbinning       'enable'    'Increase Binning'          'off'  'push'
    'help'         'histhelp'        @givehelp         'enable'    'Get Help on Histograms'    'on'  'push'
    };
  tbh = toolbar(fig,[],tb);
  set(tbh,'tag','histaxestb');
  
  %add menus
  mh = uicontextmenu('tag','transparencymenu');
  for alpha = [1:-.2:0];
    if 100-alpha*100==options.transparency
      checked = {'checked','on'};
    else
      checked = {};
    end
    uimenu(mh,'tag',sprintf('settrans%i',100-alpha*100),'label',sprintf('&%i%%',100-alpha*100),'callback',@settransparency,'userdata',alpha,checked{:});
  end
  setappdata(fig,'transparencymenu',mh);
  
  %pseduo-context menu
  pcontext = uicontextmenu('tag','patchmenu');
  uimenu(pcontext,'tag','hideobject','callback',@hideobject,'label','Remove Item');
  setappdata(fig,'patchmenu',pcontext);
  
  %store transparency
  setappdata(fig,'histogram_transparency',options.transparency)
  
  %Figure out if we should be adopted by an analysis window (so this gets
  %included in reports and gets closed on exit)
  if strcmpi(getappdata(sourcefig,'figuretype'),'plotgui')
    src = plotgui('getlink',sourcefig);
    if (src.source~=sourcefig) & strcmpi(get(src.source,'tag'),'analysis')
      analysis('adopt',guidata(src.source),fig,'modelspecific')
    end
  end
end

if ~options.quiet
  %bring SOURCE figure to front
  figure(sourcefig);
end
if nargout==0
  clear fig
end
%----------------------------------------------------
function reload(varargin)

fig = gcbf;
source  = getappdata(fig,'histogram_source');
mode    = getappdata(fig,'histogram_mode');
options = getappdata(fig,'histogram_options');
options.quiet = true;
options.figure = fig;
options.transparency = getappdata(fig,'histogram_transparency');

if ~ishandle(source)
  evriwarndlg('Source data for histogram no longer exists.','Source Missing')
  return;
end

try
  histaxes(source,mode,options);
catch
  evrierrordlg(lasterr,'Histogram Refresh Error');
end

%----------------------------------------------------
function closefig(varargin)
fig = gcbf;
myid = getappdata(fig,'histogram_data');
if ~isempty(myid);
  removeshareddata(myid,'standard');
end
delete(fig);

%----------------------------------------------------
function editdata(varargin)
fig = gcbf;
myid = getappdata(fig,'histogram_data');
h = editds(myid);
editds('noedit',h,1);

%----------------------------------------------------
function decbinning(varargin)
fig = gcbf;
options = getappdata(fig,'histogram_options');
options.nbins = max(2,options.nbins-1);
setappdata(fig,'histogram_options',options);
reload(varargin{:});

%----------------------------------------------------
function incbinning(varargin)
fig = gcbf;
options = getappdata(fig,'histogram_options');
options.nbins = options.nbins+1;
setappdata(fig,'histogram_options',options);
reload(varargin{:});

%----------------------------------------------------
function toggleval(field,varargin)
fig = gcbf;
options = getappdata(fig,'histogram_options');
options.(field) = ~options.(field);
setappdata(fig,'histogram_options',options);
reload(varargin{:});

%----------------------------------------------------
function toggleusebars(varargin)
toggleval('usebars',varargin{:});
%----------------------------------------------------
function togglemeanview(varargin)
toggleval('showmean',varargin{:});
%----------------------------------------------------
function togglestdview(varargin)
toggleval('showstd',varargin{:});
%----------------------------------------------------
function togglefraction(varargin)
toggleval('fraction',varargin{:});

%----------------------------------------------------
function viewoptions(varargin)
fig = gcbf;

mh = findobj(fig,'tag','optionsmenu');
if isempty(mh)
  mh = uicontextmenu(fig,'tag','optionsmenu');
  uimenu(mh,'label','View as Density','tag','viewdensity','callback',@toggleusebars);
  uimenu(mh,'label','View as Fraction','tag','viewfraction','callback',@togglefraction);
  uimenu(mh,'label','View Mean','tag','viewmean','separator','on','callback',@togglemeanview);
  uimenu(mh,'label','View Standard Deviation','tag','viewstd','callback',@togglestdview);
end
options = getappdata(fig,'histogram_options');
if options.usebars
  chk = 'off';
else
  chk = 'on';
end
set(findobj(mh,'tag','viewdensity'),'checked',chk);
if options.showmean
  chk = 'on';
else
  chk = 'off';
end
set(findobj(mh,'tag','viewmean'),'checked',chk);
if options.showstd
  chk = 'on';
else
  chk = 'off';
end
set(findobj(mh,'tag','viewstd'),'checked',chk);
if options.fraction
  chk = 'on';
else
  chk = 'off';
end
set(findobj(mh,'tag','viewfraction'),'checked',chk);

figpos = get(fig,'position');
set(mh,'position',[0 figpos(4)],'visible','on');

%----------------------------------------------------
function mh1 = showtransmenu(varargin)

fig = gcbf;
mh1 = getappdata(fig,'transparencymenu');
figpos = get(fig,'position');
set(mh1,'position',[0 figpos(4)],'visible','on')

%----------------------------------------------------
function settransparency(varargin)

if nargin>1 & ~isempty(varargin{2}) & ishandle(varargin{2})
  mo = findobj(varargin{2},'tag',sprintf('settrans%i',varargin{1}));
else
  mo = varargin{1};
end
parent = get(mo,'parent');
fig    = get(parent,'parent');
alpha  = get(mo,'userdata');
set(get(parent,'children'),'checked','off');
set(mo,'checked','on');
ho = findobj(allchild(fig),'userdata','histobj');
if isempty(strfind(lower(class(ho(1))),'bar'))
  set(ho,'facealpha',alpha);
end
setplspref(mfilename,'transparency',100-alpha*100);
setappdata(fig,'histogram_transparency',100-alpha*100);

%----------------------------------------------------
function transposehist(varargin)
%transpose the histogram

if nargin<1 | ~ishandle(varargin{1}) | ~strcmp(get(varargin{1},'type'),'figure')
  fig = [];
else
  fig = varargin{1};
end
if isempty(fig)
  fig = gcf;
end

handles = guihandles(fig);

set(0,'currentfigure',fig);
axh = get(fig,'currentaxes');

options = getappdata(fig,'histogram_options');
switch options.targmode
  case 'x'
    options.targmode = 'y';
  otherwise
    options.targmode = 'x';
end
setappdata(fig,'histogram_options',options)

%Most buttons will goof up the plot when it's transposed (this is a
%lightweight transpose, just moveing the items orientation) and not fully
%transposing the entire plot. 
mymode = getappdata(fig,'histogram_mode');
mybtns = [handles.incbinning,handles.decbinning,handles.reloadplot,...
  handles.options,handles.transparency];
if strcmpi(mymode,options.targmode)
  set(mybtns,'Enable','On')
else
  set(mybtns,'Enable','Off')
end

if options.usebars
  %using bars? can't do the fast transpose - have to redraw
  reload
  return;
end

ax  = axis;
children = get(axh,'children');
for ci = 1:length(children);
  [xd,yd] = deal(get(children(ci),'ydata'),get(children(ci),'xdata'));
  set(children(ci),'xdata',xd,'ydata',yd);
end
axis([ax(3:4) ax(1:2)])
xlbl = get(get(axh,'xlabel'),'string');
ylbl = get(get(axh,'ylabel'),'string');
xlabel(ylbl);
ylabel(xlbl);

%-----------------------------------------------------
function tofront(varargin)
%move object to front

h = varargin{1};
parent   = get(h,'parent');
fig      = get(parent,'parent');
children = findobj(allchild(parent),'userdata','histobj');

if strcmpi(get(fig,'selectiontype'),'alt')
  mh1 = getappdata(fig,'patchmenu');
  clickpos = get(fig,'currentpoint');
  set(mh1,'position',clickpos,'visible','on')
  return
end

if length(children)==1
  %only one child? just exit
  return;
end
isbar = ~isempty(strfind(lower(class(children(1))),'bar'));

if isbar
  istop = getappdata(h,'istop');
  setappdatas(children,'istop',false);
  if istop
    uistack(h,'bottom')
  else
    uistack(h,'top')
    setappdata(h,'istop',true)
  end
else
  
  allzd = get(children,'zdata');
  
  allzd = cat(1,allzd{:});
  if isempty(allzd);
    bottom = 0;
    top = 0;
  else
    top = max(allzd);
    bottom = min(allzd);
  end
  
  zd = get(h,'zdata');
  if isempty(zd);
    zd = get(h,'xdata').*0+top;
  end
  
  if max(zd)==top
    zd = zd.*0+bottom-1;
  else
    zd = zd.*0+top+1;
  end
  
  set(h,'zdata',zd);
end

%-----------------------------------------------------------
function hideobject(varargin)

stats = getappdata(gco,'stats'); %and store stats associated with it
delete(stats(isfinite(stats)&ishandle(stats)));
delete(gco);

%-----------------------------------------------------------
function givehelp(varargin)
%give help on how to use these histograms

doit = evriquestdlg('Do you want a quick demonstration of the features of this interface?','Histogram Help','Demo','Cancel','Demo');
if ~ischar(doit) | ~strcmp(doit,'Demo')
  return
end

fig = gcbf;
evrihelpdlg('Change the layer transparency through the Transparency toolbar menu','Histogram Help');
transh = findobj(fig,'tag','transparency');
cdata = get(transh,'cdata');
for j=1:4;
  set(transh,'cdata',cat(3,cdata(:,:,1),cdata(:,:,2)*.3,cdata(:,:,3)*.3));
  pause(.25);
  set(transh,'cdata',cdata);
  pause(.25);
end
trans = getplspref(mfilename,'transparency'); %to reset when done
showtransmenu(fig); drawnow;
pause(1);
settransparency(20,fig);
showtransmenu(fig); drawnow;
pause(2);
settransparency(80,fig);
h = showtransmenu(fig); drawnow;
pause(2);
set(h,'visible','off');
settransparency(trans,fig);


evrihelpdlg('Change the layering of the histograms by clicking on any item to bring it to the front or send it to the back.','Histogram Help');
u = get(gca,'units');
set(gca,'units','pixels');
axp = get(gca,'position');
set(gca,'units',u)
ax = axis;

bh = findobj(allchild(gca),'userdata','histobj');
datapos = [mean(get(bh(1),'xdata')) mean(get(bh(1),'ydata'))];
offsetpos = round([(datapos(1)-ax(1))/(ax(2)-ax(1)) * axp(3) - axp(3)/2 (datapos(2)-ax(3))/(ax(4)-ax(3)) * axp(4) - axp(4)/2]);
moveto(bh(1),offsetpos);
set(fig,'selectiontype','normal');
for j=1:length(bh);
  tofront(bh(j));
  pause(.5);
end

evrihelpdlg('Remove any of the histograms by right-clicking it and asking to "remove" it.','Histogram Help');
drawnow;
moveto(bh(1),offsetpos);
clickpos = axp(1:2) + axp(3:4)./2 + offsetpos;
set(fig,'selectiontype','alt','currentpoint',clickpos);
tofront(bh(1));
pause(3);

evrihelpdlg('Change the orientation of the histogram through the Swap X & Y toolbar button','Histogram Help');
transh = findobj(fig,'tag','transposeimg');
cdata = get(transh,'cdata');
for k=1:2;
  for j=1:4;
    set(transh,'cdata',cat(3,cdata(:,:,1),cdata(:,:,2)*.3,cdata(:,:,3)*.3));
    pause(.25);
    set(transh,'cdata',cdata);
    pause(.25);
  end
  transposehist(fig);
  pause(1);
end

evrihelpdlg('(End of Histogram Demo)','Histogram Help');
