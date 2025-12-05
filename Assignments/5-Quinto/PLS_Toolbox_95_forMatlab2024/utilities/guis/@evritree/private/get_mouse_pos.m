function [mypos] = get_click_info(fh)
%EVRITREE/GET_CLICK_INFO - Get mouse position on figure.
%
% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Get awt screen position of click with x from right and y from top.
jpos = java.awt.MouseInfo.getPointerInfo.getLocation;
%Get figure postion.
fpos = get(fh,'position');
%Get screen size;
spos = getscreensize('pixels');

%Invert jpos because it uses pixels from the top of the screen (on Mac at least) and index for screen size.
mypos = [jpos.getX-fpos(1) spos(4)-jpos.getY-fpos(2)];
