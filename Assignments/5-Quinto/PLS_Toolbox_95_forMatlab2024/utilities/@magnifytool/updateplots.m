function output_args = updateplots(obj)
%UPDATEPLOTS Update plots on plotgui.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Find existing display axis if possible.
dax = finddisplayax(obj.parent_figure);

if isempty(dax)
  %Display axis could have been manually added.
  dax = obj.display_axis;
end

%Make display axis if needed.
if isempty(dax) || ~ishandle(dax)
  if exist('crosstool','file')
    crosstool('delete',obj.parent_figure);%Make sure crosstool is not being used.
  end
  dtax = findobj(obj.parent_figure,'tag','drill_display');
  if isempty(dtax)
    fpos = get(obj.parent_figure,'position');
    obj.parent_figure_oposition = fpos;%Save original position.
    if strcmp(obj.display_orientation,'bottom')
      subplot(2,1,1,obj.target_axis);
      dax = subplot(2,1,2);
    else
      %Assume display is to the right.
      %Double width of plot.
      cpos = getscreensize;
      %Expend the width but don't go off the screen or shrink. Bob had
      %trouble with this position using 2 monitors.
      fpos(3) = max(fpos(3),min(2*fpos(3),cpos(3)-fpos(1)));
      set(obj.parent_figure,'position',fpos);
      %Assume one target axis.
      subplot(1,2,1,obj.target_axis);
      dax = subplot(1,2,2);
    end
  else
    %Only one orientation when drill tool is there.
    subplot(2,2,[1 3],obj.target_axis);
    subplot(2,2,2,dtax);
    dax = subplot(2,2,4);
  end
  
  set(dax,'tag','magnify_display')
  %It appears that sometimes tag and get modified by plotgui so add dummy
  %delete fcn as second identifier.
  set(dax,'DeleteFcn','%magnify_display')
end

%Update objects.
delete(allchild(dax));
set(dax,'xdir',get(obj.target_axis,'xdir'),'ydir',get(obj.target_axis,'ydir'));
%Copy all objects over to display except patch or context menu.
cpobjs = findall(obj.target_axis);
nocopy = [obj.target_axis obj.patch_handle obj.resize_handle findall(cpobjs,'type','contextmenu')'];
cpobjs = cpobjs(~ismember(cpobjs,nocopy));
evricopyobj(cpobjs,dax);

%Set lims to magnification box.
set(dax,'xlim',[min(obj.patch_xdata) max(obj.patch_xdata)],'ylim',[min(obj.patch_ydata) max(obj.patch_ydata)])
%Add dax to obj.
obj.display_axis = dax;

%Set gca back to plotgui axes.
if ishandle(obj.target_axis)
  set(obj.parent_figure,'CurrentAxes',obj.target_axis)
end

%Save object to display axis since it's the only object that plotgui won't
%try to manipulate.
setobj(obj);

%Make cmenu if needed.
if obj.show_menu
  cm = findobj(obj.parent_figure,'tag','magnify_contextmenu');
  if isempty(cm)
    cm = uicontextmenu('parent',obj.parent_figure,'tag','magnify_contextmenu');
    h1 = uimenu(cm,'Label','Re-draw Magnification Area','Callback',{@setpatch_overload,obj});
    h2 = uimenu(cm,'Label','Close magnifier','Callback',{@delete_overload,obj});
    pause(.1)
  end
  set(obj.display_axis,'uiContextMenu',cm)
  set(obj.patch_handle,'uiContextMenu',cm)
end

output_args = obj;

%-------------------------
function setpatch_overload(varargin)
%Can't seem to call method directly so add overload here.
setpatch(varargin{end})

%-------------------------
function delete_overload(varargin)
%Can't seem to call method directly so add overload here.
delete(varargin{end})

