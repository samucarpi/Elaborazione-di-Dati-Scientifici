echo on
%HLINEDEMO Demo of the DP, HLINE, VLINE and ZLINE functions
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% HLINE, VLINE and ZLINE are plotting aids. So, first
% create some data for plotting.
 
t = -2*pi:0.1:2*pi;
x = cos(t);
y = sin(t);
 
pause
%-------------------------------------------------
% Now do a 2D plot
 
figure
plot(t,x)
xlabel('Time, t'), ylabel('Cos(t)')
axis([-6.5 6.5 -1.5 1.5])
 
pause
%-------------------------------------------------
% Now add some horizontal and vertical lines to the plot
 
hline, pause
%-------------------------------------------------
vline, pause
%-------------------------------------------------
hline([-1 1],'r'), pause
%-------------------------------------------------
vline([-pi pi -2*pi 2*pi],'k'), pause
%-------------------------------------------------
% And add a diagonal 45 degree line (this is useful for
% comparing estimates to known values in regression).
 
dp
  
% Note that this line passed through (-1,-1) and (1,1).
 
pause
%-------------------------------------------------
% Now do a 3D plot
 
figure
plot3(x,y,t), grid on
xlabel('Cos(t)'), ylabel('Sin(t)'), zlabel('Time (t)')
axis([-1.5 1.5 -1.5 1.5 -6.5 6.5])
 
pause
%-------------------------------------------------
%Now make some horizontal and vertical lines
 
hline, vline, pause
%-------------------------------------------------
zline, pause
%-------------------------------------------------
zline([1.5 0 -1.5 0],[0 1.5 0 -1.5],'r')
 
%End of HLINEDEMO
 
echo off
