function initaxes(h,action)
%INITAXES Adds callbacks to axes objects when created.
% Handles adding of right-click functionality to all axes allowing setting
% of axes limits, fonts, and grid on/off (plus other fucntionality) via the
% AdjustAxisLimits GUI (adjustaxislimitsgui). 
% 
% Functionality can be disabled by the command:
%    setappdata(0,'noinitaxes',true)
%
%I/O: initaxes()
%I/O: initaxes(axes_handle,'addcallback')
%I/O: initaxes(fig_handle,'trigger')
%
%See also: ADJUSTAXISLIMITSGUI, FIGBROWSER, INITFIGURE

% Copyright © Eigenvector Research, Inc. 2003
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%check for disable flag
disable = getappdata(0,'noinitaxes');
if ~isempty(disable) & disable
  return;
end

if nargin==0
  %with no inputs, integrate ourselves into the AxesCreateFcn so callback
  %is added to any axes
  dacf = get(0,'defaultaxescreatefcn');
  if ischar(dacf)% The dacf might be a function handle so don't try adding because strfind command will error
    if isempty(strfind(dacf,'initaxes'));
      set(0,'defaultaxescreatefcn',[dacf ';try;initaxes(gcbo,''addcallback'');catch;end;'])
    end
  end
  return
end
if nargin<2
  action = 'addcallback';
end

switch action
    
  case 'addcallback'
    %called when axes are created - adds the button down fcn to "trigger"
    %display of controls
    fig = get(h,'parent');
    if isprop(fig,'integerhandle') & strcmp(get(fig,'integerhandle'),'on') & strcmp(get(fig,'HandleVisibility'),'on'); %only do this for integer handled figures with full visibility
      set(h,'buttonDownFcn','try;initaxes(gcbf,''trigger'');catch;end;')
    end

  case 'trigger'
    %NOTE: input with 'trigger' is expected to be a FIGURE handle
    %check if this was a right-click and open axis limits controls if so
    fig = h;
    uic = get(get(fig,'currentaxes'),'uicontextMenu');
    if isempty(uic)
      uic = uicontextmenu;
      shownow = true;
    else
      shownow = false;
    end
    if ~isempty(uic)
      %check for adjust axis item:
      if isempty(findobj(uic,'tag','initaxes_adjust'))
        if ~isempty(get(uic,'children')); sep = 'on'; else sep = 'off'; end
        uimenu(uic,'tag','initaxes_adjust','label','Adjust Axes','callback','adjustaxislimitsgui(gcbf)','separator',sep);
      end
    end

    if strcmp(get(fig,'selectiontype'),'alt'); 
      if shownow
        set(uic,'position',get(fig,'currentpoint'))
        set(uic,'visible','on');
      end
    end
    
end

