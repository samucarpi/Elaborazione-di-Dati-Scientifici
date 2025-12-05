function plotguiwindowbuttondown_doubleclick(fig)
%PLOTGUIWINDOWBUTTONDOWN_RIGHTCLICK - Clearinghouse for plotgui window button down right click command.
% This code is called in child_WindowButtonDownFcn of plotgui via evriaddon.
%
%I/O:   plotguiwindowbuttondown(fig)
%
%See also: EVRIADDON, PLOTGUIWINDOWBUTTONDOWN, PLOTGUIWINDOWBUTTONDOWN_RIGHTCLICK, PLOTGUIWINDOWBUTTONMOTION, UPDATEPLOTCOMMAND

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Update drill tool.
dtool_on = getappdata(fig,'drilltool_status');
if ~isempty(dtool_on)
  drilltool('addpoint',fig);%Add current point.
end
