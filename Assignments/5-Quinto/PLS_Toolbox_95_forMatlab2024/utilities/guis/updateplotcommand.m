function updateplotcommand(fig)
%UPDATEPLOTCOMMAND - Clearinghouse for post plotgui plot command.
% This code is called after a plotgui plot command (plotgui/plotds) via
% addon_pls_toolbox.
%
%I/O:   updateplotcommand(fig)
%
%See also: EVRIADDON, PLOTGUIWINDOWBUTTONDOWN, PLOTGUIWINDOWBUTTONMOTION

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

dtool_on = getappdata(fig,'drilltool_status');
if ~isempty(dtool_on) & ~strcmp(dtool_on,'off')
  %Drill tool will call magnify tool update.
  drilltool('update',fig);
else
  %Update magnify tool only.
  bh = findobj(allchild(fig),'tag','pgtmagnify');
  if length(bh)>1
    %Can sometimes get more than one toolbar on same fig so check here
    %otherwise contionals below error out.
    %TODO: Make this an appdata so doesn't rely on button.
    bh = bh(1);
  end
  if ~isempty(bh) & length(bh)==1 & ishandle(bh) & strcmp(get(bh,'state'),'on')
    magnifytool('update',fig);
  end
end

ctool_on = getappdata(fig,'crosstool_status');
if ~isempty(ctool_on) & ~strcmp(ctool_on,'off')
  crosstool('update',fig);
end

%Update searchbar.
searchb = getappdata(fig,'PlotguiSearchBar');
if ~isempty(searchb)
  plotgui_searchbar('update_source_list',fig)
end
