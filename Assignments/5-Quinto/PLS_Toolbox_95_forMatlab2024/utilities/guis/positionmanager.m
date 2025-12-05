function varargout = positionmanager(fig,keyword,action)
%POSITIONMANAGER Manages stored figure position using keyword.
%  Figure positions are managed via keyword (e.g. "browse" or "analysis").
%  The 'action' input indicates wether to 'move' the figure to its previous
%  position, 'set' the keyword figure's position, 'get' the figures
%  previous position, or move/confirm the figure's position is 'onscreen'.
%
%  Option "dockall" (set only through preferences expert GUI) controls
%  overriding docking behavior and can be one of these three values:
%    [ 'always' | {'save'} | 'never' ]
%    'always' : All GUIs are opened docked, no matter what their last saved
%               position. In addition, no GUI positions are saved.
%    'save'   : the last docked/non-docked status of each GUI is saved and
%               used to determine the next docking position. {default}
%    'never'  : All GUIs are opened non-docked, no matter what their last
%               saved position. GUIs opened when this option is selected
%               will have their saved status reset to non-docked.
%
%I/O: positionmanager(fig,keyword,action);
%
%See also: CENTERFIGURE

% Copyright © Eigenvector Research, Inc. 2005
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%RSK 11/28/06 - Initial coding.

if nargin == 0; fig = 'io'; end 
if ischar(fig);
  options = [];
  options.saveposition = 'on';
  options.dockall = 'save';        % [ 'always' | 'save' | 'never' ]
  options.screensizepref = 'matlab'; %['default' | 'smaller' | 'larger' | 'matlab']
  if nargout==0; evriio(mfilename,fig,options); else; varargout{1} = evriio(mfilename,fig,options); end
  return;
end

if nargin < 2
  error(['Function (' mfilename ') requires at least 2 inputs.'])
end
  
if nargin == 2
  %Default action.
  action = 'move';
end

options = positionmanager('options');

%check for valid single handle
if isempty(fig) & ~ishandle(fig);
  return;
end
fig = fig(1);


switch action
  
  case 'move'
    %Move to stored position then verify it's onscreen.
    if isfield(options,keyword) && ~isempty(options.(keyword))
      pos = options.(keyword);
    else
      pos = [];
    end
    if isfield(options,[keyword '_isdocked']) && ~isempty(options.([keyword '_isdocked']))
      isdocked = options.([keyword '_isdocked']);
    else
      isdocked = 0;
    end
    if strcmp(options.dockall,'always')
      isdocked = true;
    elseif strcmp(options.dockall,'never')
      isdocked = false;
    end
    isdocked = isdocked(1);  %only use first value if multiple present
    if ~isdocked;
      if ~evriwindowstyle(fig) & ~isempty(pos);
        %numeric position (and window isn't docked) set position
        pos = pos(1,:);  %make sure its only one row
        set(fig,'position',pos)
      end
    else
      %force "docked" window
      if checkmlversion('>','7')
        evriwindowstyle(fig,1)
      end
    end
    onscreen(fig,options)
    
  case 'set'
    %Store position as preference to figure keyword.
    if strcmp(options.saveposition,'on') 
      isdocked = evriwindowstyle(fig);
      if ~isdocked;
        setplspref('positionmanager',keyword,get(fig,'Position'))
      end
      if ~strcmp(options.dockall,'always')
        %store docked status
        setplspref('positionmanager',[keyword '_isdocked'],isdocked)
      end
    end
    
  case 'get'
    if isfield(options,keyword)
      varargout{1} = options.(keyword);
    else
      varargout{1} = [];
    end
    
  case 'onscreen'
    %Put figure onscreen.
    onscreen(fig,options)
end
    
%-------------------------------------------
function onscreen(fig,options)
%Move fig onto screen [left, bottom, width, height]. If figure is wider or
%taller than screen size then resize with 20 pixle margin.

if evriwindowstyle(fig)
  %don't do this if window is docked!
  return
end

%Use screen size option because some screen resolutions seem to be
%different on some systems. The default (java) screen size seems too small
%and or big. Maybe using different size will help. In some instanes figure
%is resized way bigger than screen and user can't close.
scrn = getscreensize('pixels',options.screensizepref);
figunits = get(fig,'units');

set(fig,'units','pixels');
pos = get(fig,'position');

% Fix a position issue on >2K screens when rendering windows.
if ((scrn(3) < 2048) || (scrn(4) <= 1080))
  %Use -100 pixels in bottom position to pull off top of screen.
  pos = [max(min(pos(1),scrn(3)-pos(3)),scrn(1)) max(min(pos(2),scrn(4)-pos(4)-100),scrn(2)) min(scrn(3)-20,pos(3)) min(scrn(4)-20,pos(4))];
else
  scrn(3:4) = scrn(3:4)*0.4; % fig workaround (Java related).
  
  % Clamp gui within screen resolution
  if (pos(1) + pos(3) > scrn(1) + scrn(3))
    pos(1) = scrn(3) - pos(3); % - 1;
  end
  if (pos(2) + pos(4) > scrn(2) + scrn(4))
    pos(2) = scrn(4) - pos(4); % - 1;
  end
  if (pos(1) < scrn(1))
    pos(1) = scrn(1); % + 1;
  end
  if (pos(2) < scrn(2))
    pos(2) = scrn(2); % + 1;
  end
  
end

set(fig,'position',pos);
set(fig,'units',figunits)
