function plotguiwindowbuttondown(fig)
%PLOTGUIWINDOWBUTTONDOWN - Clearinghouse for plotgui window button down command.
% This code is called in child_WindowButtonDownFcn of plotgui via evriaddon.
%
%I/O:   plotguiwindowbuttondown(fig)
%
%See also: EVRIADDON, PLOTGUIWINDOWBUTTONMOTION, PLOTGUIWINDOWBUTTONDOWN_RIGHTCLICK, UPDATEPLOTCOMMAND

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

% %Update drill tool.
% dtool_on = getappdata(fig,'drilltool_status');
% if ~isempty(dtool_on)
%   drilltool('wbd',fig);
% end
