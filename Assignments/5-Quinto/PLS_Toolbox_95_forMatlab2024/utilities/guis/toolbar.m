function [htoolbar, hbtns] = toolbar(h, analysis, btnlist, tagname)
%TOOLBAR Creates toolbar and assigns correct callback functions. 
% Creates a toolbar based on a default setting or through a cell
% array (btnlist).
%
% Note: The "uipushtool" is an undocumented Matlab object. 
%
% INPUTS:
%        h        = Handle of analysis figure or existing toolbar.
%        anaysis  = Type of default analysis.
%        btnlist  = (n x 7) cell array for buttons. 
%                     Column 1: Reference either name of image in default   
%                               .mat file (image tag), full path to button
%                               image, or handle to existing button.
%                     Column 2: Tag for each button.
%                     Column 3: Callback for each button.
%                     Column 4: Enable or disable button ('enable' or
%                               'disable')
%                     Column 5: Tooltip text.
%                     Column 6: Separator before button ('on' or 'off')
%                     Column 7: Toggle of Push button ('toggle' or 'push')
%                     Column 8: OnCallback for toggle button.
%                     Column 9: OffCallback for toggle button.
%                     Column 10: Optional - Userdata for item
%        tagname  = (optional) tag for toolbar being created/modified.
%                    Default is "AnalysisToolbar". Use tagname when more
%                    than one toolbar may be put onto a given figure.
% OUTPUT:
%        htoolbar = Handle to the toolbar.
%        hbtns    = Handles to buttons. 
%
% The names of the built-in icon images (for use in column 1 of the btnlist
% cell) can be determined by using the toolbar('icons') command. This will
% prepare an image showing all built-in icons. Click on an icon to get the
% name to use in column 1 of btnlist for that icon.
%
%I/O: [htoolbar, hbtns] = toolbar(h, '', btnlist,tagname);
%I/O: [htoolbar, hbtns] = toolbar(h, 'decompose');
%I/O: toolbar(h, 'disable');
%I/O: toolbar('icons');       %show all built-in icons
%I/O: iconname = toolbar('icons');  %allow user to select icon
%
%See also: GETTBICONS TOOLBAR_BUTTONSETS

%Copyright Eigenvector Research 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 02/04/04 initial coding
%rsk 06/16/04 Work around for Matlab separator/graphics bug.

if nargin==0;
  %return example cell input
  htoolbar = {'image' 'tag' 'callback' 'enable|disable' 'tooltip' 'separator on|off' 'toggle|push'};
  return
end

%single-string commands here
if ischar(h)
  switch h
    case 'icons'
      if nargout==0
        showicons
      else
        htoolbar = showicons;
      end
      return
    case 'cmenu'
      cmenu(analysis);
      return
    case 'savepng'
      savepng(analysis);
      return
  end
end

%Check input  
if nargin < 2,
  error('Need 2 inputs for toolbar.m.');
end
if nargin < 3;
  btnlist = {};
end
hType = get(h, 'Type');
if nargin < 4;
  tagname = 'AnalysisToolbar';
end

%Disable/enable buttons
if strcmp(hType, 'figure') & strcmp(lower(analysis), 'disable')
  %Defualt disable all buttons accept eigenvector and calc.
  existingbuttons = get(findobj(h,'tag',tagname),'children');
  set(existingbuttons, 'Enable', 'off');
  for j=1:length(existingbuttons);
    if getappdata(existingbuttons(j),'enable_default')
      %turn on those with default "on" values
      set(existingbuttons(j),'Enable','on');
    end
  end
%   set((findobj(existingbuttons,'Tag','evri')), 'Enable', 'on');
  return
elseif strcmp(hType, 'figure') & strcmp(lower(analysis), 'enable'),
  %Enable all buttons.
  existingbuttons = get(findobj(h,'tag',tagname),'children');
  set(existingbuttons, 'Enable', 'on');
  return
end 

% Delete existing toolbar and create new one.
if strcmp(hType, 'figure'),
  %Delete existing toolbar
  existingtoolbars = findobj(h,'Type','uitoolbar','tag',tagname);
  oldbuttons = get(existingtoolbars,'children');
  %Matlab bug leaves separators on toolbar after button is gone, turn off
  %and redraw before delete.
  set(oldbuttons,'tag','','separator','off','visible','off');
  drawnow
  if ~ishandle(h)
    %figure may have closed while we were drawing
    htoolbar = [];
    hbtns = [];
    return; 
  end
  if isempty(existingtoolbars)
    htoolbar = uitoolbar(h);
  else
    htoolbar = existingtoolbars(1);
  end
  set(htoolbar, 'Tag', tagname);
  
  if isempty(analysis)
    %Call custom.
    hbtns = customtb(htoolbar, btnlist);
  elseif isempty(btnlist) 
    %Call defualt.
    hbtns = defaultbutton(htoolbar, analysis);
    toolbar(h, 'disable');
  else 
    %Call defualt
    hbtnsd = defaultbutton(htoolbar, analysis);
    %Call custom
    hbtnsc = customtb(htoolbar, btnlist);
    hbtns = [hbtnsc hbtnsd];
  end

  %now, delete the old buttons from the toolbar
  oldbuttons = oldbuttons(ishandle(oldbuttons));
  delete(oldbuttons);
  pause(0.01);
  drawnow;%Use drawnow because of some latency problems where two sets of toolbar buttons were available.
  
  le = lasterror;
  retry = true;
  count = 0;
  while retry & count<5
    count = count+1;
    try
      %update handles structure to reflect new items
      guidata(h,guihandles(h));
      retry = false;
    catch
      retry = true;
      lasterror(le);
    end
  end

else
  error('This function only accepts handles to figures.');
end
%------------------------------------------------
function [hbtnscust] = customtb(htoolbar, btnlist)
iconscust = gettbicons;
for ind = 1 : size(btnlist,1),
  
%   %Take care of spacer buttons, no functions and disabled.
%   if strcmp(btnlist{ind,1},'space')
%     hbtnscust(ind)=feval('uipushtool', htoolbar);
%     set(hbtnscust(ind),'enable','off','tag', btnlist{ind,2})
%     continue
%   end
  
  %Button type
  switch lower(btnlist{ind,7})
    case {'toggle' 'togglebutton'}
      buttontype = 'uitoggletool';
    otherwise %Defualt pushbutton.
      buttontype = 'uipushtool';
  end

  %Set icon image and tag.
  hbtnscust(ind)=feval(buttontype, htoolbar);
  if isnumeric(btnlist{ind,1})
    %numeric value? assume actual image for button
    try
      set(hbtnscust(ind),'cdata',btnlist{ind, 1});
    catch
      %error? use empty box
      z=[ones(2,21); ones(17,2) ones(17,17)*.4 ones(17,2);ones(2,21)]*.8;
      z = repmat(z,[1 1 3]);
      set(hbtnscust(ind),'cdata',z);
    end
  elseif isfield(iconscust, btnlist(ind, 1))
    %Using an existing icon in tbimg.mat file.
    set(hbtnscust(ind),'cdata',getfield(iconscust, char(btnlist(ind, 1)))); 
  elseif exist(btnlist{ind, 1},'file')
    %Using image file. 
    set(hbtnscust(ind),'cdata',imread(btnlist{ind, 1})); 
  else
    %unknown/missing, use empty box
    z=[ones(2,21); ones(17,2) ones(17,17)*.4 ones(17,2);ones(2,21)]*.8;
    z = repmat(z,[1 1 3]);
    set(hbtnscust(ind),'cdata',z); 
  end
  
  %Set tag.
  set(hbtnscust(ind),'tag', btnlist{ind,2});
  
  %Set callback.
  set(hbtnscust(ind),'ClickedCallback', btnlist{ind,3});
  
  %Set enable.
  switch lower(btnlist{ind,4})
    case 'enable'
      set(hbtnscust(ind),'Enable', 'on');
      setappdata(hbtnscust(ind),'enable_default',1);
    otherwise  %Defualt enable = off.
      set(hbtnscust(ind),'Enable', 'off');
      setappdata(hbtnscust(ind),'enable_default',0);
  end
  
  %Set tooltip.
  set(hbtnscust(ind),'TooltipString', btnlist{ind,5});
  
  %Set separator.
  set(hbtnscust(ind),'Separator', btnlist{ind,6});
  
  if strcmp(lower(btnlist{ind,7}),'toggle') & size(btnlist,2)>7
    try
      set(hbtnscust(ind),'OnCallback', btnlist{ind,8})
      set(hbtnscust(ind),'OffCallback', btnlist{ind,9})
    catch
      %error? don't do anything - just skip setting these values
    end
  end
  
  %10th item in list (optional) is userdata
  if size(btnlist,2)==10
    set(hbtnscust(ind),'userdata', btnlist{ind,10});
  end
  
end
%------------------------------------------------
function [hbtnsdef] = defaultbutton(htoolbar, analysis)

btnlist = toolbar_buttonsets(analysis);
hbtnsdef = customtb(htoolbar, btnlist);
%Make toolbar buttons uninterruptible so cant make changes in GUI while
%running long analysis actions.
set(hbtnsdef, 'Interruptible', 'off');





