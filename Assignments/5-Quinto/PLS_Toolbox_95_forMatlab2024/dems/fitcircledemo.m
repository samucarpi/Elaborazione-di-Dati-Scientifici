echo on
% FITCIRCLEDEMO Demo of the FITCIRCLE function
 
echo off
% Copyright © Eigenvector Research, Inc. 2022
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The FITCIRCLE function fits a circle to input Mx2 data (class double)
% returning the circle center (xc) 1x2 and radius (a) scalar.
 
%Example data (exact circle)
a     = 2;                 % circle radius
t     = (0:0.1:2*pi+0.1)'; % angle radians
x     = a*cos(t);          % x-coordinates of a circle
y     = a*sin(t);          % y-coordinates of a circle
  figure, plot(x,y,'-'); grid, axis equal

%hit return to fit and plot the fitted results
 
  pause

[c,a] = fitcircle([x,y]);  %Call FITCIRCLE
  vline(c(1),'r'), hline(c(2),'r'), hold on
  plot([0 a],[0 0],'b'), title(['R = ',num2str(a)])
 
% Try a circle that is offset
 
pause
 
a     = 3.5/2;
xr    = a*x+0.5;
yr    = a*y+0.5;
  figure, plot(xr,yr,'-'); grid, axis equal
 
[xc,xa] = fitcircle([xr,yr]);  %Call FITCIRCLE
  vline(0,'k'), hline(0,'k')
  vline(xc(1),'r'), hline(xc(2),'r'), hold on
  plot([xc(1) xc(1)+xa],[xc(2) xc(2)],'b'), title(['R = ',num2str(xa)])
 
% FITCIRCLE can also be used to fit a sphere
 
pause
 
%create a unit sphere centered at 1,2,3
[xs,ys,zs]  = sphere(20);
[xc,a] = fitcircle([xs(:)+1,ys(:)+2,zs(:)+3]);
 
disp('Center'), disp(xc)
disp('and Radius'), disp(a)
 
%End of FITCIRCLEDEMO
 
echo off
