function display(obj)
%MAGNIFYTOOL/DISPLAY Display magnify tool information.

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

disp('MAGNIFYTOOL:');
disp(['        version: ' num2str(obj.magnifytoolversion)]);
disp([' ']);
disp(['  parent_figure: ' num2str(obj.parent_figure)]);
disp(['    parent name: ' get(obj.parent_figure,'name')]);
disp([' ']);
disp(['    target_axis: ' num2str(double(obj.target_axis))]);
disp(['    target_xlim: ' num2str(obj.target_xlim)]);
disp(['    target_ylim: ' num2str(obj.target_ylim)]);
disp([' ']);
disp(['   display_axis: ' num2str(obj.display_axis)]);
disp([' ']);
disp(['   patch_handle: ' num2str(obj.patch_handle)]);
disp(['    patch_xdata: ' num2str(obj.patch_xdata')]);
disp(['    patch_ydata: ' num2str(obj.patch_ydata')]);
disp(['    patch_alpha: ' num2str(obj.patch_alpha)]);
disp(['    patch_color: ' num2str(obj.patch_color)]);
