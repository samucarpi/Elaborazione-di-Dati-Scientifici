function varargout = scrollzoom(action,fig,varargin)
%SCROLLZOOM Enables scroll wheel zoom on a figure
% Manages zooming with the scroll wheel on a mouse.
% Input (action) can be any of the following:
%   'on'  = activate scroll zooming on the figure
%   'off' = deactivate scroll zooming on the figure
%   'disable' = turn off scroll zooming on ALL windows
%   'enable'  = turn on scroll zooming for any/all windows
% The 'enable'/'disable' options allow turning off all scroll-wheel zoom
% functionality (e.g. on systems where zooming happens accidentally due to
% hardware design.) 
% The optional second input (fig) can be used to specify which figure the
% 'on' and 'off' options are modifying. Default is the current figure.
%
% Several stored options (accessible only by setplspref) control behavior:
%   speed     = [0.05] Governs the fractional step size taken with each
%               roll of the scroll wheel.
%   outzoom   = [0.05] Governs the fraction that plots can be zoomed OUT
%               from their fully unzoomed state
%   edgefavor = [0.1] Governs the extent to which zooming in moves the plot
%                towards the edge (or away from the edge when zooming out)
%                when cursor is off-center
% Example:
%   setplspref('scrollzoom','speed',0.01)
%
%I/O: scrollzoom('on',fig)   
%I/O: scrollzoom('off',fig)  
%I/O: scrollzoom('disable')
%I/O: scrollzoom('enable')

%Copyright Eigenvector Research, Inc. 2015
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0
  action = 'on';
end
if nargin==1 & ischar(action) & ~ismember(action,{'on' 'off' 'enable' 'disable'})
  options = [];
  options.enable = 'on';
  options.speed = 0.05;
  options.outzoom = 0.05;
  options.edgefavor = 0.1;

  if nargout==0; evriio(mfilename,action,options); else varargout{1} = evriio(mfilename,action,options); end
  return
end
if nargin<2
  fig = gcf;
end

%Note: although options are defined above, actually calling reconopts in
%here would seriously effect the performance of this function. It is
%strongly recommended that options ONLY be checked as needed and then using
%persistent variables when possible to cache the results is recommended.
%See, for example, the "enable()" function below

switch action
  case 'on'
    if enable
      set(fig,'WindowScrollWheelFcn',@WindowScrollWheelFcn)
      set(fig,'WindowButtonUpFcn',@WindowButtonUpFcn)
      set(fig,'WindowButtonMotionFcn',@WindowButtonMotionFcn)
      set(fig,'WindowButtonDownFcn',@WindowButtonDownFcn)
      set(fig,'WindowKeypressFcn',@WindowKeyPressFcn)
      set(fig,'WindowKeyReleaseFcn',@WindowKeyReleaseFcn)
    end

  case 'off'
    set(fig,'WindowScrollWheelFcn',[])
    set(fig,'WindowButtonUpFcn',[])
    set(fig,'WindowButtonMotionFcn',[])
    set(fig,'WindowButtonDownFcn',[])
    
  case 'disable'
    enable('off')
    
  case 'enable'
    enable('on')
    
  otherwise
    if enable
      if nargout==0
        feval(action,fig,varargin{:});
      else
        [varargout{1:nargout}] = feval(action,fig,varargin{:});
      end
    else %disabled
      if nargout
        [varargout{1:nargout}] = deal([]);
      end
    end
    
end

%-------------------------------------------------------
function WindowKeyPressFcn(varargin)

fig = varargin{1};
fig = jumptofigure(fig,false);  %identify target UNLESS its plotgui
if isempty(fig); return; end
mykey = varargin{2}.Key;
setappdata(fig,'scrollzoomkey',mykey)
setappdata(fig,'scrollzoomkeytime',now)
axh = get(fig,'currentaxes');
switch mykey
  case 'control'
    set(axh,'xminortick','on');
  case 'shift'
    set(axh,'yminortick','on');
end

%-------------------------------------------------------
function WindowKeyReleaseFcn(varargin)

fig = varargin{1};
fig = jumptofigure(fig);
if isempty(fig); return; end
axh = get(fig,'currentaxes');
set(axh,'xminortick','off');
set(axh,'yminortick','off');
setappdata(fig,'scrollzoomkey',[])
setappdata(fig,'scrollzoomkeytime',[])

%-------------------------------------------------------
function WindowButtonUpFcn(varargin)

fig = jumptofigure(gcbf);
if isempty(fig); return; end
buttonUp(fig);

%------------------------------------------------------
function WindowButtonMotionFcn(varargin)


fig = jumptofigure(gcbf);
if isempty(fig); return; end
buttonMotion(fig);

% --------------------------------------------------------------------
function WindowButtonDownFcn(varargin)

fig = jumptofigure(gcbf);
if isempty(fig); return; end

axh     = get(fig,'currentaxes');
switch get(fig,'selectiontype')    
  case {'extend'}
    buttonDown(fig);
    return;    
end
setappdata(axh,'oldpanpoint',[]);


%--------------------------------------------------------------------
function WindowScrollWheelFcn(varargin)

scrollWheel(varargin{:});


%==============================================================
function scrollWheel(varargin)

persistent speed edgefavor outzoom

if isempty(speed)
  %get values the first time
  opts = scrollzoom('options');
  edgefavor = opts.edgefavor;
  speed = opts.speed;
  outzoom = opts.outzoom;
end

sinfo = varargin{2};
vsc = double(sinfo.VerticalScrollCount);
vsa = double(sinfo.VerticalScrollAmount);
sdir = sign(vsc.*vsa);
samt = abs(vsc.*vsa);

fig = jumptofigure(gcbf);
if isempty(fig); return; end

%get figure properties
axh = get(fig,'currentaxes');
fpos = get(fig,'currentpoint');
fsz  = get(fig,'position');
if any(fpos<0) | fpos(1)>fsz(3) | fpos(2)>fsz(4)
  %not actually OVER the figure? don't zoom
  return;
end
ax  = axis;
pos = get(axh,'currentpoint');

if length(ax)>4
  %don't scroll wheel on 3D plots (yet!)
  return;
end

%get the original axis scale limits (if not there, set whatever is current
%- this is the first call to scrollzoom for these axes)
swax = getappdata(axh,'unzoomedaxisscale');
if isempty(swax)
  swax = ax;
  setappdata(axh,'unzoomedaxisscale',ax);
end

%calculate zoom based on mouse position over axes
rpos = (pos(1,1:2)-ax([1 3]))./(ax([2 4])-ax([1 3])); %position relative to middle
rpos = min(max(rpos,-outzoom),1+outzoom);  %don't zoom outside of axes
shiftamt = [rpos(1) rpos(1)-1 rpos(2) rpos(2)-1]; %converted to shift amount for each axis limit
shiftamt = shiftamt + [-1 1 -1 1]*edgefavor*-sdir; %zoom slightly favoring edges
szax  = [ax(2)-ax(1) ax(4)-ax(3)];
szax  = szax([1 1 2 2]);
newax = (ax-szax.*samt.*sdir.*shiftamt*speed);


lastkey = getappdata(fig,'scrollzoomkey');
lastpress = getappdata(fig,'scrollzoomkeytime');
if (now-lastpress)*60*60*24<.5
  switch lastkey
    case 'control'
      newax(3:4) = ax(3:4);
    case 'shift'
      newax(1:2) = ax(1:2);
  end
end

if sdir>0
  %don't zoom out beyond original range
  newax([1 3]) = max([newax([1 3]);swax([1 3])-szax([1 3])*outzoom]);
  newax([2 4]) = min([newax([2 4]);swax([2 4])+szax([2 4])*outzoom]);
  newax(1:2) = sort(newax(1:2));
  newax(3:4) = sort(newax(3:4));
end

%if valid, apply it
if all(isfinite(newax)) & newax(1)<newax(2) & newax(3)<newax(4)
  axis(newax)
  zoomchangecallback(fig,axh);
end

%-------------------------------------------------------------------
function buttonDown(fig)

fig = jumptofigure(fig);
if isempty(fig); return; end

axh = get(fig,'currentaxes');
setappdata(axh,'oldpanpoint',get(axh,'currentpoint'));
setappdata(axh,'waspanned',[]);

%------------------------------------------------------
function out = buttonMotion(fig)

out = false;

fig = jumptofigure(fig);
if isempty(fig); return; end

axh = get(fig,'currentaxes');
if isempty(axh); return; end
oldp = getappdata(axh,'oldpanpoint');

if ~isempty(oldp)
  out = true;
  newp = get(axh,'currentpoint');
  delta = oldp(1,1:2)-newp(1,1:2);
  ax = axis;
  if length(ax)>4
    %don't scroll wheel on 3D plots (yet!)
    return;
  end
  swaxis = getappdata(axh,'unzoomedaxisscale');
  if ax(1)<swaxis(1) & delta(1)<0; delta(1) = 0; end
  if ax(2)>swaxis(2) & delta(1)>0; delta(1) = 0; end
  if ax(3)<swaxis(3) & delta(2)<0; delta(2) = 0; end
  if ax(4)>swaxis(4) & delta(2)>0; delta(2) = 0; end
  ax = ax+delta([1 1 2 2]);
  axis(ax);
  zoomchangecallback(fig,axh)
  setappdata(axh,'waspanned',true);
end
  
%-------------------------------------------------------
function buttonUp(fig)

fig = jumptofigure(fig);
if isempty(fig); return; end

axh = get(fig,'currentaxes');
waspanned = getappdata(axh,'waspanned');
if isempty(waspanned) & strcmpi(get(fig,'selectiontype'),'extend')
  swaxis = getappdata(axh,'unzoomedaxisscale');
  if ~isempty(swaxis)
    axis(swaxis)
  else
    axis auto
  end
  zoomchangecallback(fig,axh)
end
setappdata(axh,'waspanned',[]);
setappdata(axh,'oldpanpoint',[]);

%--------------------------------------------------------------
function fig = jumptofigure(fig,jump)

if nargin<2
  jump = true;
end
fig = ancestor(fig,'figure');
if ~strcmp(get(fig,'handlevisibility'),'on')
  if ~jump
    %if we aren't ALLOWED to jump, return empty
    fig = [];
    return;
  end
  %callback figure doesn't have standard visibility?
  fig = getappdata(fig,'target');
  %is it a plotgui figure (or other that has "target" as a property)
  if isempty(fig) | ~ishandle(fig)
    fig = [];
    return;
  end
  %make the target the current figure
  set(0,'currentfigure',fig)
  figure(fig);
end

%--------------------------------------------------------------
function zoomchangecallback(fig,axh)

dodatetick = false;  %don't do old datetick code unless the zoom callback isn't set or fails
try
  cb = get(zoom,'ActionPostCallback');
  if ~isempty(cb)
    %do the set zoom action callback with info from this figure/axes
    cb(fig,struct('Axes',axh));
  else
    dodatetick = true;
  end
catch
  dodatetick = true;
end
switch dodatetick
  case true
    if getappdata(axh,'xidateticks'); idateticks('x'); end
    if getappdata(axh,'yidateticks'); idateticks('y'); end
end

%-------------------------------------------------------------
function out = enable(mode)
%manage the enable flag. Stores a persisent copy of the enable option to
%speed up checking. Also allows direct setting of the enable option by a
%call:
%  enable('on')
%  enable('off')
% these calls directly assign the persistent variable AND the option stored
% in plspref

persistent storedmode

if isempty(storedmode)
  storedmode = getplspref('scrollzoom','enable');
  if isempty(storedmode)  %STILL empty? no overload set
    opts = scrollzoom('options');
    storedmode = opts.enable;
    setplspref('scrollzoom','enable',opts.enable);
  end
end

if nargin>0
  %assigning mode
  mode = lower(mode);
  if ~ismember(mode,{'on' 'off'})
    error('Invalid setting for enable')
  end
  setplspref(mfilename,'enable',mode)
  storedmode = mode;
else
  %asking for current mode
  out = strcmpi(storedmode,'on');
end
