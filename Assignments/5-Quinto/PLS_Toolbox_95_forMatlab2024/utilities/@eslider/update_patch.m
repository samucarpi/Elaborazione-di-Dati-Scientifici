function obj = update_patch(obj,newval)
%UPDATE_PATCH Update/create patch position and axis scale.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~isvalid(obj); return; end

%Don't allow values past range.
if newval<1
  newval = 1;
elseif newval > obj.range
  newval = obj.range;
end

%Set new val.
obj.value = newval;

%Get new y positions.
ht = patch_height(obj);
bt = patch_bottom(obj);
ydata = [-bt+ht -bt+ht -bt -bt]+1;

%Get x position.
patch_width = obj.position(3);
xdata = [1 patch_width patch_width 1];

%Create or set patch.
if ~isempty(obj.patch) & ishandle(obj.patch)
  set(obj.patch,'ydata',ydata,'xdata',xdata);
else
  grey = .9;
  obj.patch = patch(xdata,ydata,[grey grey grey],'parent',obj.axis,'ButtonDownFcn','moveobj;');%,'facealpha',.7);
  set(obj.patch,'uicontextmenu',findobj(obj.parent,'tag','eslider_contextmenu'));
  %Set moveobj info.
  setappdata(obj.patch,'MOVEOBJ_mode','y');
  setappdata(obj.patch,'buttonmotionfcn','drag(getappdata(gcf,''eslider''))');
end





