function varargout = clickCallback(obj,event,varargin)
%CLICKCALLBACK Parse clicks on graph and display right-click menu.

%Copyright Eigenvector Research, Inc. 2017
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

mygraph = varargin{end};
eventdata = varargin{end-1};
fig = mygraph.ParentFigure;
figpos = get(fig,'position');
handles = guihandles(fig);
%mydata  = getappdata(handles.multiblocktool,'mbdata');

%Get any existing infobox.
infoh = obj.infoBoxHandle;
if ~ishandle(infoh)
  infoh = [];
end
%Trun off info display if any click detected.
visoff(infoh)

mycell = mygraph.GraphComponent.getCellAt(eventdata.getX,eventdata.getY);
if isempty(mycell)
  %Clicking in open space.
  return
end

if ~mycell.isVertex
  %Clicking on an edge.
  return
end

%Clicking on cell.
myid = char(mycell.getId);
if strfind(myid,'pool')
  %Clicking in pool but not on data/model cell.
  return
end

cm = findobj(fig,'tag','mcctcontextmenu');
set(allchild(cm),'visible','off','separator','off');

setappdata(fig,'current_clicked_cell',myid);

if ismember(myid(end-1:end),{'p1' 'p2'})
  %Preprocessing.
  %set([handles.cmenu_view], 'enable','on','visible','on')
  return
else
  %Data or model.
  switch myid
    case {'SlaveModel' 'ValidationResults'}
      %Not used yet but may need to adjust for data vs model.
      set([handles.cmenu_delete handles.cmenu_view handles.cmenu_save],...
        'enable','on','visible','on')
      if strcmp(myid,'ValidationResults')
        set([handles.cmenu_plot],...
        'enable','on','visible','on')
      end
    otherwise
      set([handles.cmenu_delete handles.cmenu_view handles.cmenu_save handles.cmenu_load],...
        'enable','on','visible','on')
  end
end

cmpos = getmouseposition(fig);
set(cm,'position',cmpos);
set(cm,'visible','on');

end

function visoff(h)
%Turn visible off.
if ishandle(h)
  set(h,'visible','off')
end
end
