function obj = updatepatch(obj)
%MAGNIFY/UPDATEPATCH Update/create patch (magnification box) on axis to drag.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if isempty(obj.parent_figure)
  return
end

%Only update every tenth second.
t1 = getappdata(obj.parent_figure,'magnify_update_time');
t2 = now;
if (t2-t1)<.000001
  return
else
  setappdata(obj.parent_figure,'magnify_update_time',t2);
end

%Check target.
obj = checktarget(obj);

%Make sure patch data isn't outside of limits on target.
if obj.position_checking
  obj = check_position(obj);
end

if isempty(obj.patch_xdata)
  %Maybe user cancel.
  %If there's no display axis then make sure the toggle button is "up",
  %this can happen when a user cancels on first try.
  if isempty(obj.display_axis)
    bh = findobj(allchild(obj.parent_figure),'tag','pgtmagnify');
    if ishandle(bh)
      set(bh,'state','off')
    end
  end
  return
end

%Make sure there's only one patch around.
all_patch = findobj(obj.target_axis,'tag','magnifypatch');
if ~isempty(all_patch)
  my_patch = obj.patch_handle;
  if ~ishandle(my_patch)
    my_patch=[];
  end
  
  if length(all_patch)>1
    %More than on patch on the target, need to get rid of it.
    del_patch = setxor(all_patch,my_patch);
    delete(del_patch(ishandle(del_patch)));
  end
end

%Need drawnow here so gui objects get flushed. Otherwise delete occurs
%while patch is created below and we lose the handle which causes error
%later. This happens when lots of call come (arrow commands in plotgui y
%axis menu).
drawnow
%Make patch.
xdat = obj.patch_xdata;
ydat = obj.patch_ydata;
if isempty(obj.patch_handle)|~ishandle(obj.patch_handle)
  
  obj.patch_handle = patch(xdat,ydat,obj.patch_color,'parent',obj.target_axis,'tag','magnifypatch');
  %Need to make sure patch is created before calling moveobj, patch was not
  %draggable in some cases if we don't use drawnow here.
  %Don't think we need drawnow here becuase one above fixes problem.
  %drawnow
  moveobj(obj.moveobj_constraint,obj.patch_handle);
  
  %NOTE: On Chucks Vista box the graphics driver is messed up with respect
  %to OpenGL and flips the axis labels. This is a known problem and can be
  %ignored.
  %NOTE: Alpha causes drill point patch (from drill tool) to change line
  %width for some reason. This is an OPENGL problem and is not fixable as far
  %as I know (if we want to use alpha).
  alpha(obj.patch_handle,obj.patch_alpha);
  
  legendname(obj.patch_handle,'Magnify Region')
else
  %Update patch.
  set(obj.patch_handle,'xdata',xdat,'ydata',ydat)
end

%Use function handle (with object as input) because handles structure sometimes seem
%not ready because (I think) plotgui is still udpating them.
setappdata(obj.patch_handle,'buttonmotionfcn',{@update_magnify,obj.parent_figure})

%Add resize point to lower right corner.
if obj.show_resize
  hold([obj.target_axis],'on')
  if ishandle(obj.resize_handle)
    set(obj.resize_handle,'xdata',xdat(3),'ydata',ydat(3))
  else
    obj.resize_handle = plot(obj.target_axis,xdat(3),ydat(3),'s','LineWidth',1,...
      'MarkerSize',5,'MarkerFaceColor','black','MarkerEdgeColor','black','tag','magnify_resize');
    moveobj('on',obj.resize_handle);
  end
  hold([obj.target_axis],'off')
  setappdata(obj.resize_handle,'buttonmotionfcn',{@update_magnify_resize,obj.parent_figure})
  setappdata(obj.resize_handle,'buttonupfcn',{@update_magnify,obj.parent_figure})
  legendname(obj.resize_handle,'Magnify Resize')
end

%This will set object to appdata of display axis. Note, display axis might
%not exist yet if this is the first time through.
obj = updateplots(obj);
hideaxistext(obj.display_axis)

%---------------------------------------
function obj = update_magnify(functionhandle,fig,varargin)
%Update magnify view.

dax = finddisplayax(fig);
if isempty(dax)
  %No obj to find.
  return
end

obj = getappdata(dax,'magnifytool');
if isempty(obj)
  return
end

x = get(obj.patch_handle,'xdata');
y = get(obj.patch_handle,'ydata');
set(obj.display_axis,'xlim',[min(x) max(x)],'ylim',[min(y) max(y)])
hideaxistext(obj.display_axis)

set(obj.resize_handle,'xdata',x(3),'ydata',y(3))

%Save limits.
obj.patch_xdata = x;
obj.patch_ydata = y;

%Run any user motion code.
if ~isempty(obj.buttonmotion_fcn)
  feval(obj.buttonmotion_fcn{:})
end

%Save current state.
setobj(obj);

%---------------------------------------
function obj = update_magnify_resize(functionhandle,fig,varargin)
%Resize magnify region. Change patch size interactively but only update
%diplay on button-up of resize point.

dax = finddisplayax(fig);
if isempty(dax)
  %No obj to find.
  return
end

obj = getappdata(dax,'magnifytool');
if isempty(obj)
  return
end

%Get point new location.
xnew = get(obj.resize_handle,'xdata');
ynew = get(obj.resize_handle,'ydata');

x = get(obj.patch_handle,'xdata');
y = get(obj.patch_handle,'ydata');

x(3:4) = xnew;
y(2:3) = ynew;

%Save limits.
obj.patch_xdata = x;
obj.patch_ydata = y;

if ~isempty(obj.patch_handle)||ishandle(obj.patch_handle)
  %Update patch.
  set(obj.patch_handle,'xdata',x,'ydata',y)
end

%Save current state.
setobj(obj);

%---------------------------------------
function obj = check_position(obj)
%Check position of patch relative to xlim ylim of target axis. If plotgui
%updates the target the patch may be way off the screen.

myxlim = get(obj.target_axis,'xlim');
myylim = get(obj.target_axis,'ylim');

xdat = obj.patch_xdata;
ydat = obj.patch_ydata;

%Check total size so patch isn't bigger than target. If it's more than 50%
%or less than 5% the size of the target then assume target has changed and
%resize patch to 20%.
if max(xdat)-min(xdat)>.5*diff(myxlim)|max(xdat)-min(xdat)<.05*diff(myxlim)
  %Reduce x size to .5 of total xlim in target.
  xdata(xdat==max(xdat)) = min(xdat)+.2*diff(myxlim);
end

if max(ydat)-min(ydat)>.5*diff(myylim)|max(ydat)-min(ydat)<.05*diff(myylim)
  %Reduce x size to .5 of total xlim in target.
  ydat(ydat==max(ydat)) = min(ydat)+.2*diff(myylim);
end

%If off to the left or right, bring it back to left edge.
if min(xdat)<min(myxlim)|min(xdat)>max(myxlim)
  mydiff = min(myxlim)-min(xdat)+.01*diff(myxlim);%Add small amount to pull off bottom so resize corner doesn't go off axis.
  xdat = xdat+mydiff;
end

%If off to the top or bottom, bring it back to bottom edge.
if min(ydat)<min(myylim)|min(ydat)>max(myylim)
  mydiff = min(myylim)-min(ydat)+.01*diff(myylim);%Add small amount to pull off bottom so resize corner doesn't go off axis.
  ydat = ydat+mydiff;
end

obj.patch_xdata = xdat;
obj.patch_ydata = ydat;

%Check total size so patch isn't bigger than target.
%if max(xdat)-min(xdat)>diff(myxlim)
  






