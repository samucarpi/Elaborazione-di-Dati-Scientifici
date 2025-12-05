function plotguiwindowbuttonmotion(fig)
%PLOTGUIWINDOWBUTTONMOTION - Clearinghouse for plotgui window button motion command.
% This code is called in child_WindowButtonMotionFcn of plotgui via evriaddon.
%
%I/O:   plotguiwindowbuttonmotion(fig)
%
%See also: EVRIADDON, PLOTGUIWINDOWBUTTONDOWN, UPDATEPLOTCOMMAND

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Update drill tool.
%Disable this feature to make more stable and consistant.
dtool_on = getappdata(fig,'drilltool_status');
if ~isempty(dtool_on) && strcmpi(dtool_on,'on')
  drilltool('wbm',fig);
end
