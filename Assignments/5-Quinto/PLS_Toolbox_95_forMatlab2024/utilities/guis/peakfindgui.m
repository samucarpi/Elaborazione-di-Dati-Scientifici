function varargout = peakfindgui(action,varargin)
%PEAKFINDGUI Provides automatic peak finding to figures.
% Performs peak finding on a specified figure. The following actions are
% defined:
% 'settings' : opens window to allow changes to options/preferences.
%              Changes are saved to peakfindgui's plsprefs if and only if
%              peakfindgui is called with nargout=0. The options struct is
%              returned otherwise, e.g. opts = peakfindgui('settings')
% 'setup'    : adds sensitivity and OK/Cancel controls to figure and begins
%              peak location.
% 'update'   : updates peak location for currently plotted data. If no
%              controls are found, the appdata property "findpeakswidth" is
%              used to determine sensitivity. If it is undefined (empty),
%              then no peak fitting is done.
% 'fpok'     : when controls are on screen, saves current settings, removes
%              controls and updates display. If figure is a TrendTool
%              figure, markers are added at all found peaks. If figure is a
%              PlotGUI figure, markers are automatically updated as plot
%              changes.
% 'fpcancel' : hides all controls, clears settings, and discontinues peak
%                finding.
% Optional second input is the figure handle to work with (current figure
% is assumed).
%
%   options = structure array with the following fields:
%         display: [ 'off' | {'on'} ]      governs level of display to command window.
%       algorithm: [ {'d0'}| 'd2' | 'd2r' ]  select peakfinding algorithm
%          npeaks: [{'all'} | n] The maximum number of peaks to find.
%             com: [0] Center of Mass filter on peak positions. 0 = no
%                  Center of mass correction.
%   peakdirection: [{'positive'}| 'negative' | 'both' ] Whether peaks are upwards or downwards or both
%         nformat: [ {'g'} | 'f' | 'e' ] Governs format of numerical peak
%                  position values. 'g' = general, 'f' = fixed, 'e' =
%                  exponential.
%         ndigits: [0] The number of significant digits to show.
%    fillexcluded
%
%I/O: peakfindgui(action,fig)

% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin==0
  action = 'setup';
end
action = lower(action);

%check for evriio input
if nargin==1 && ischar(action) && ismember(action,evriio([],'validtopics'));
  options = [];
  options.algorithm = 'd0';  % interpolation used to match variables using axisscale
  options.com = 0;           % Center of Mass filter on peak positions
  options.peakdirection = 'positive';
  options.npeaks = 0;        % max number of peaks to show
  options.nformat = 'd';     % numerical format for peaks
  options.ndigits = 0;       % number of significant digits
  options.definitions   = @optiondefs;
  if nargout==0; evriio(mfilename,action,options); else varargout{1} = evriio(mfilename,action,options); end
  return;
end

if nargout == 0
  feval(action,varargin{:});
else
  [varargout{1:nargout}] = feval(action,varargin{:});
end

%--------------------------------------------------------------------------
% Only set plspref when peakfindgui's nargout=0, as indicated by numargout.
function opts = settings(varargin)

if nargin>0 & ishandle(varargin{1})
  %got a figure number as input? assign settings directly there and
  %update
  fig = varargin{1};
  while ~strcmp(get(fig,'type'),'figure')
    fig = get(fig,'parent');
  end
  opts = getappdata(fig,'findpeakssettings');
else
  fig = [];
end
if isempty(opts)
  opts = mfilename;
end
opts = optionsgui(opts);
if nargout==0 & ~isempty(opts)
  %no outputs? do something with changes
  if ishandle(fig)
    %got a figure number to update
    setappdata(fig,'findpeakssettings',opts)
    peakfindgui('update',fig);
  else
    %no figure number in? set in default settings
    setplspref(mfilename, opts);
  end
  clear opts
end

%--------------------------------------------------------------------------
function setup(fig)

if nargin<1 | isempty(fig)
  fig = gcf;
end

cah   = get(fig,'currentaxes');
datah = findobj(allchild(cah),'userdata','data');
if ~isempty(datah)
  ax   = get(datah,'xdata');
  smax = length(ax)/8;   %maximum value for width
else
  smax = 51;   %maximum value for width
end

width = getappdata(fig,'findpeakswidth');
if isempty(width) | width==0
  %peaks were NOT set
  cancelname = 'Cancel';
  okname = 'Set';
  width = 9;  %default value for width
else
  %peaks were already set
  cancelname = 'Clear';
  okname = 'Set';
end
if width>smax
  smax = width;
end
if width<3
  width = 3;
end
width = round((width-1)/2)*2+1;

svalue = smax-width+3;  %convert to sensitivity

fpslider = findobj(fig,'tag','fpslider');
if isempty(fpslider)
  if strcmp(get(fig,'toolbar'),'auto'); set(fig,'toolbar','figure'); end
  fppanel = uicontrol(fig,...
    'style','frame',...
    'tag','fppanel',...
    'units','normalized',...
    'visible','off');
  fplabel = uicontrol(fig,...
    'style','text',...
    'tag','fplabel',...
    'string','Sensitivity:',...
    'units','normalized',...
    'visible','off');
  fpslider = uicontrol(fig,...
    'style','slider',...
    'tag','fpslider',...
    'min',3,...
    'max',smax,...
    'value',svalue,...
    'units','normalized',...
    'visible','off',...
    'SliderStep',[2/max(1,smax-3) 4/max(1,smax-3)],...
    'callback','peakfindgui(''update'',gcbf)');
  fpok = uicontrol(fig,...
    'style','pushbutton',...
    'string',okname,...
    'callback','peakfindgui(''fpok'',gcbf);',...
    'tag','fpok',...
    'units','normalized',...
    'visible','off');
  fpcancel = uicontrol(fig,...
    'style','pushbutton',...
    'string',cancelname,...
    'callback','peakfindgui(''fpcancel'',gcbf);',...
    'tag','fpcancel',...
    'units','normalized',...
    'visible','off');
  fpsettings = uicontrol(fig,...
    'style','pushbutton',...
    'string','',...
    'callback','peakfindgui(''settings'',gcbf);',...
    'tag','fpsettings',...
    'cdata',gettbicons('options'),...
    'units','normalized',...
    'visible','off');
  
  %force fpsettings to be 21 x 21 pixels (to match icon)
  set(fpsettings,'units','pixels');
  setspos = get(fpsettings,'position');
  setspos(3:4) = 21;
  set(fpsettings,'position',setspos)
  set(fpsettings,'units','normalized');

  %get all default positions
  slpos     = get(fplabel,'position');
  spos      = get(fpslider,'position');
  okpos     = get(fpok,'position');
  cancelpos = get(fpcancel,'position');
  setspos   = get(fpsettings,'position');
  
  %and adjust
  slpos     = [.01 .02 slpos(3) slpos(4)];
  spos      = [slpos(3)+slpos(1)+.01 .02 .96-slpos(3)-okpos(3)-cancelpos(3)-setspos(3)-.02 spos(4)];
  okpos     = [ spos(3)+ spos(1)+.01 .02  okpos(3:4)];
  cancelpos = [okpos(3)+okpos(1)+.01 .02  cancelpos(3:4)];
  setspos   = [cancelpos(3)+cancelpos(1)+.01 .02 setspos(3:4)];
  
  set(fppanel,'position',[0 0 1 max([spos(4) okpos(4) cancelpos(4)])+0.04]);
  set(fplabel,'position',slpos);
  set(fpslider,'position',spos);
  set(fpok,'position',okpos);
  set(fpcancel,'position',cancelpos);
  set(fpsettings,'position',setspos);
  
  set([fplabel fpslider fpok fpcancel fpsettings fppanel],'visible','on','units','pixels');
  
end
update(fig);

%--------------------------------------------------------------------------
function update(fig)

if nargin<1 | isempty(fig)
  fig = gcf;
end

fpslider = findobj(fig,'tag','fpslider');
if ~isempty(fpslider)
  %get slider value and put in range
  sens = get(fpslider,'value');
  sens = round((sens-1)/2)*2+1;  %make it an even value
  sens = max(min(sens,get(fpslider,'max')),get(fpslider,'min'));  %within range of slider
  set(fpslider,'value',sens);
  
  %INVERT sensitivity to get width:
  width = (get(fpslider,'max')-sens+get(fpslider,'min'));
  
  setappdata(fig,'findpeakswidth',width);  %store width
else
  %no slider? look for width
  width = getappdata(fig,'findpeakswidth');  %store width
end
pfopts = getappdata(fig,'findpeakssettings');
if isempty(pfopts)
  pfopts = peakfindgui('options');
end

if ~isempty(width) & width>0
  %get data
  found = [];
  cah   = get(fig,'currentaxes');
  datah = findobj(allchild(cah),'userdata','data');
  if ~isempty(datah)
    ax   = get(datah,'xdata');
    data = get(datah,'ydata');
    if iscell(ax)
      ax = ax{1};
    end
    try
      if iscell(data)
        data = cat(1,data{:});
      end
      if size(data,1)>1
        data = mean(data,1);
      end
      i1     = find(isnan(data));
      if ~isempty(i1)
         i2  = setdiff(1:length(data),i1);
         data(i1) = interp1(i2,data(i2),i1,'linear','extrap');
      end

      %do peakfind
      sens   = max(3,min(width,floor(size(data,2)/4)*2-1));
      win    = 3;
      tolfac = 3;
      width  = sens;

      p = peakfind(data,width,tolfac,win,pfopts);
      found = interp1(1:length(ax),ax,[p{:}]);
    catch
      lasterr
      found = [];
    end
  end
  
  %drop old markers
  delete([findobj(cah,'userdata','foundpeak');findobj(cah,'userdata','foundpeaklabel')]);
  
  if ~isempty(found)
    %add new ones
    set(0,'currentfigure',fig);
    ph = vline(found);
    set(ph,'userdata','foundpeak','tag','');
    ylim = get(cah,'ylim');
    ypos = ylim(2)+(ylim(2)-ylim(1))*.01;
    if pfopts.ndigits<=0
      convertfn = @num2str;
      fmt = {};
    else
      convertfn = @sprintf;
      fmt = {sprintf('%%4.%d%s', pfopts.ndigits, pfopts.nformat)};
    end
    for j=1:length(found)
      str = convertfn(fmt{:}, found(j));
      th(j) = text(found(j),ypos,str);
    end
    moveobj(th);
    set(th,'Rotation',90);
    set(th,'userdata','foundpeaklabel');
    
    uic = findobj(fig,'tag','findpeakcontext');
    if isempty(uic)
      uic = uicontextmenu('tag','findpeakcontext','callback',@clickpeaklabel);
    end
    set(th,'uicontextmenu',uic);
  end
  
else
  %width not defined and no slider found
  delete([findobj(fig,'userdata','foundpeak');findobj(fig,'userdata','foundpeaklabel')]);
  
end

%---------------------------------------------------------
function clickpeaklabel(varargin)

settings(varargin{:})

%--------------------------------------------------------------------------
function fpdelete(fig)

if nargin<1 | isempty(fig)
  fig = gcf;
end
delete([findobj(fig,'tag','fpslider');
  findobj(fig,'tag','fpok');
  findobj(fig,'tag','fpcancel');
  findobj(fig,'tag','fppanel');
  findobj(fig,'tag','fplabel');
  findobj(fig,'tag','fpsettings');
  findobj(fig,'userdata','foundpeaklabel');
  findobj(fig,'userdata','foundpeak')])

%--------------------------------------------------------------------------
function fpcancel(fig)

if nargin<1 | isempty(fig)
  fig = gcf;
end
setappdata(fig,'findpeakswidth',[]);  %clear sensitivity
fpdelete(fig);  %clear all markers

%--------------------------------------------------------------------------

function fpok(fig)

if nargin<1 | isempty(fig)
  fig = gcf;
end

TrendLinkData = getappdata(fig,'TrendLinkData');
if ~isempty(TrendLinkData)
  %trend tool figure?
  ph = findobj(fig,'userdata','foundpeak');
  pos = get(ph,'xdata');
  if ~isempty(pos)
    %got peaks?
    if iscell(pos)
      pos = cat(1,pos{:});
    end
    for j=1:size(pos,1)
      trendmarker('addmarker',fig,pos(j,1))  %add a marker for each
    end
  end
  fpdelete(fig);  %clear all markers and objects
  setappdata(fig,'findpeakswidth',[]);  %clear sensitivity (or PlotGUI will keep marking peaks!)
  trendmarker('update');
  trendmarker('docallback',fig);
  
elseif strcmp(getappdata(fig,'figuretype'),'PlotGUI')
  %not a trend-tool figure? skip creation of markers
  fpdelete(fig);  %clear all markers and objects
  plotgui('update','figure',fig);
  
else
  fpdelete(fig);  %clear all markers and objects
  
end

%--------------------------------------------------------------------------
function out = optiondefs()

defs = {
  'nformat'        'Formatting'  'select'  {'f' 'g' 'e'}                   'novice'  'Governs format of numerical peak position values. "g" = general, "f" = fixed, "e" = exponential.'
  'ndigits'        'Formatting'  'double'  'int(0:inf)'                    'novice'  'Number of significant digits to show. 0 means unformatted general display.';
  'peakdirection'  'Searching'  'select'  {'positive' 'negative' 'both'}  'novice'  'Direction of expected peaks: upward, downward, or both.';
  'npeaks'         'Searching'  'double'  'int(0:inf)'                    'novice'  'Max number of peaks to find. 0 means ''all''';
  'algorithm'      'Advanced'  'select'  {'d0' 'd2' 'd2r'}               'novice'  'd0 = find local maxima, d2 = local maxima of 2nd deriv, d2r = d2, and relative heights';
  'com'            'Advanced'  'double'  'float(0:inf)'                  'novice'  'Center of Mass filter on peak positions. Relocates peaks to their "power-weighted" center of mass. That is, the intensity taken to the specified power is used to reloate the peak to its center of mass. Note this may not be an even interval. A value of zero (0) disables the center of mass correction. A value of 1 corresponds to a standard center of mass calculation. Higher values recalculate to the specified power before calculating center of mass.';
  };

out = makesubops(defs);
