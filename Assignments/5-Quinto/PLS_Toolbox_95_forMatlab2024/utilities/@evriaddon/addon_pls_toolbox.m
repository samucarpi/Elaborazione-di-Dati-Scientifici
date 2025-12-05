function out = pls_toolbox(obj)
%EVRIADDON/PLS_TOOLBOX Defines customizable entry points for PLS_Toolbox.

% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

out = evriaddon_connection('PLS_Toolbox');

out.priority = 1;
out.importmethods = @editds_importmethods;
out.preprocess    = @preprouser;
out.plotgui_plotcommand = @updateplotcommand;
out.plotgui_windowbuttonmotion = @plotguiwindowbuttonmotion;
out.plotgui_windowbuttondown = @plotguiwindowbuttondown;
out.plotgui_windowbuttondown_rightclick = @plotguiwindowbuttondown_rightclick;
out.plotgui_windowbuttondown_doubleclick = @plotguiwindowbuttondown_doubleclick;
out.analysis_pre_setobjdata_callback = @analysis_pre_setobj_commands;%Not used yet.
out.analysis_post_setobjdata_callback = @analysis_post_setobj_commands;%All pre and post setobj calls go to here.

function analysis_pre_setobj_commands(varargin)
%Place holder for pre setobj. See analysis_post_setobj_commands for syntax
%and create new function when needed.
