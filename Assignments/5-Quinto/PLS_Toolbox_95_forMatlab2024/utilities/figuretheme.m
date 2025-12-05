function settings = figuretheme(fig,color)
%FIGURETHEME Resets a figure background and axes to a specified color.
% Automatically adjusts figure and axes colors, including objects on the
% axes, to have a particular background color scheme. Objects on the axes
% which might conflict with the background color scheme are automatically
% adjusted to a non-conflicting color.
%
% If called with only a figure handle, the last-applied color scheme is
% re-applied. This is useful after updating a plot with a standard plotting
% command.
%
%INPUTS:
%      fig = figure to modify (if empty or omitted, the current figure is
%             used)
%    color = color to set figure and axes background to. Can either be a
%            three-element RGB code:  [red green blue] or can be one of the
%            following strings:
%          'w' : white background (both figure and axes)
%          'k' : black background (both figure and axes)
%          'd' : default color scheme (usually gray figure, white axes)
%          'g' : gray figure, white axes (often the default, but useful if
%                the default is something else)
%          'next' : toggles bewteen 'w' -> 'k' -> 'd'
%
%          If color is omitted or empty, the last used colorscheme will be
%          re-applied to the figure (if not the default).
%OUTPUTS:
%  settings = a structure array containing the colors used for the
%             figure and axes in the fields 'color' and 'axescolor',
%             respectively.
%
%I/O: settings = figuretheme(fig,color)
%I/O: settings = figuretheme(fig)

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1 | isempty(fig);
  %default is to use the current figure
  fig = get(0,'currentfigure');
end

if ischar(fig)
  %evriio call
  options = [];
  options.lastused = [];
  if ~nargout; evriio(mfilename,fig,options); else; settings = evriio(mfilename,fig,options); end
  return
end

if ~ishandle(fig)
  return;
end

%Do settings need to be saved to prefs. This costs time so don't save if
%not needed.
need_to_save_settings = 1;

%parse inputs
axescolor = [];
isdefault = false;  %flag to say that these are the default settings and we shouldn't store them (when true)
if nargin<2 | isempty(color)
  % (fig) repeat previous color setting (if any)
  settings = getsettings(fig);
  if ~isempty(settings) & isfield(settings,'color');
    color = settings.color;
    axescolor = settings.axescolor;
    need_to_save_settings = 0;
  else
    %NO settings there? the user hasn't changed colors
    if ~strcmpi(get(fig,'handlevisibility'),'on');
      %do NOT change background on hidden (GUIs) unless user specifically
      %asks to
      if nargout==0
        clear settings
      end
      return;
    end
    settings = getplspref(mfilename,'lastused');
    if isempty(settings); 
      %nothing there? exit now
      if nargout==0
        clear settings
      end
      return;
    end  
    color = settings.color;
    axescolor = settings.axescolor;
  end
  
else
  %user passed specific color setting...
  if isempty(color)
    color = 'd';
  end
  if ischar(color)
    defaultfigurecolor = get(0,'defaultfigurecolor');
    defaultaxescolor = get(0,'defaultaxescolor');
    switch color
      case 'next'
        %cycle through
        settings = getsettings(fig);
        if isempty(settings) | all(settings.color==defaultfigurecolor)
          color = 'w';
        elseif all(settings.color==[1 1 1])
          color = 'k';
        else
          color = 'd';
        end
    end
    switch color
      case 'k'
        color = [0 0 0];
      case 'w'
        color = [1 1 1];
      case 'g'
        color = [.8 .8 .8];
        axescolor = [1 1 1];
      otherwise
        color = defaultfigurecolor;
        axescolor = defaultaxescolor;
        isdefault = true;
    end
  elseif length(color)~=3
    error('color must be either a single character string or an R G B color code')
  end
end

%defaults for inverted color and axes color
if all(color>.5)
  inverted = [0 0 0];
else
  inverted = [1 1 1];
end
if isempty(axescolor)
  axescolor = color;
end

%change primary figure and axes colors
set(fig,'color',color);
set(findobj(fig,'type','axes'),'color',axescolor,'xcolor',inverted,'ycolor',inverted,'zcolor',inverted);

%change colors on objects which are on those axes and might conflict with
%the primary colors
allaxes = allchild(findobj(fig,'type','axes'));
if iscell(allaxes); allaxes = cat(1,allaxes{:}); end
allaxes(~ishandle(allaxes)) = [];
cobjs = cat(1,findobj(allaxes,'color',axescolor),findobj(allaxes,'color',color),findobj(allaxes,'color',[1 1 1]),findobj(allaxes,'color',[0 0 0]));
set(cobjs,'color',inverted)

%store settings so we can re-apply them later
settings = [];
settings.color = color;
settings.axescolor = axescolor;
if ~isdefault
  setsettings(fig,settings);
else
  setsettings(fig,[]); %store empty to indicate default values
end

if need_to_save_settings
  setplspref(mfilename,'lastused',settings);  %store as last used
end

if nargout==0
  clear settings
end

%-------------------------------------------------
function settings = getsettings(fig)
settings = getappdata(fig,'figuretheme');

%-------------------------------------------------
function setsettings(fig,settings)
setappdata(fig,'figuretheme',settings);

