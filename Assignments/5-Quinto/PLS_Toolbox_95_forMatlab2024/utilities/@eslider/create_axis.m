function obj = create_axis(obj)
%UPDATE_AXIS Create the object.

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~ishandle(obj.parent)
  return
end

%Create axis.
obj.axis = axes('parent',obj.parent,'tag','eslider_axes','units','pixels','position',obj.position,...
                'visible',obj.visible,'box','on','ButtonDownFcn','click(getappdata(gcf,''eslider''))');

%Clean the ticks off.
set(obj.axis,'XTickLabel','','YTickLabel','','ZTickLabel','','XTick',[],'YTick',[],'ZTick',[],'XColor','black','YColor','black')

%Add color.
set(obj.axis,'Color',obj.color);

%Scale y axis to units of range + height of patch so .value becomes an index (for e.g., a list).
axis(obj.axis,[1 obj.position(3) -obj.range 1])

%Create contextmenu.
vis = get(obj.parent,'handlevisibility');
set(obj.parent,'handlevisibility','on');  %on some figures, the handle is hidden and we have to make it visible for a moment to make this work
try
  set(0,'currentfigure',obj.parent);
  cmenu = uicontextmenu;
  set(cmenu,'tag','eslider_contextmenu');
catch
  le = lasterror;
  set(obj.parent,'handlevisibility',vis);  %reset handle visibility
  rethrow(le)
end
set(obj.parent,'handlevisibility',vis);  %reset handle visibility

itm = uimenu(cmenu,'Label','Clear Selection','callback','clear_selections(getappdata(gcf,''eslider''))');
itm = uimenu(cmenu,'Label','Select All','callback','select_all(getappdata(gcf,''eslider''))');
set(obj.axis,'uicontextmenu',cmenu);


%Will create patch and then call function update callback.
obj = subsasgn(obj,struct('subs','value'),obj.value);
