function [mpos,screenratiox,screenratioy] = getmouseposition(fig)
%GETMOUSEPOSITION Get mouse position on a figure in pixel units.
%
%
%I/O: [mpos,screenratiox,screenratioy]  = getmouseposition(fig)

%Copyright Eigenvector Research, Inc. 2018
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin<1 | ~ishandle(fig)
  fig = gcf;
end

myunits = get(fig,'units');
set(fig,'units','pixels');
figpos = get(fig,'position');
set(fig,'units',myunits);

scrnL = getscreensize('pixels','larger');%Actual pixels
scrnS = getscreensize('pixels','smaller');%Matlab pixels

window_x = java.awt.MouseInfo.getPointerInfo.getLocation.x;
window_y = scrnL(4)-java.awt.MouseInfo.getPointerInfo.getLocation.y;%Need to correct for java orientation vs Matlab (top vs bottom).

screenratiox = 1;
if scrnL(3)~=scrnS(3)
  screenratiox = scrnS(3)/scrnL(3);
end

screenratioy =1;
if scrnL(4)~=scrnS(4)
  screenratioy = scrnS(4)/scrnL(4);
end

relx = (screenratiox * window_x) - figpos(1);
rely = (screenratioy * window_y) - figpos(2);

mpos = [relx rely];
