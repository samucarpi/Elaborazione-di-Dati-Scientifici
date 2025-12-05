echo on
%POLYINTERPDEMO Demo of the POLYINTERP function
 
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
% POLYINTERP is a general polynomial interpolation function
% that can also be used to estimate derivatives. This function
% is similar to the SAVGOL function, except it can be used
% for interpolation and estimating derivatives for unevenly
% spaced points. If the data are evenly spaced see SAVGOL.
 
pause
%-------------------------------------------------
% Create data for interpolation:
 
t = 0:0.2:2*pi;
y = [sin(t); sin(t+pi/4)+2];
 
figure
plot(t,y,'-'), hold on
xlabel('time')
 
% This plot shows the underlying functions that we'll try to match.
% 
% Create new unevenly spaced time axis to interpolate to
 
ti = [0.1 0.5 1.03 2.11 pi pi+0.05 pi*3/2 5.53]; 
 
% Interpolate y to ti using a window of 3 and second order polynomials.
 
yi = polyinterp(t,y,ti,3,2);
 
plot(ti,yi,'or'), hold off
 
% The red circles show the interplated values.
 
pause
%-------------------------------------------------
% The known 1st derivative is given in yd
 
yd = [cos(t); cos(t+pi/4)];
 
% Interpolate to (ti) and estiamte the 2nd derivative
 
yid = polyinterp(t,y,ti,3,2,1);
 
figure
plot(t,yd,'-'), hold on
xlabel('time')
plot(ti,yid,'or'), hold off
 
pause
%-------------------------------------------------
% The known 2nd derivative is given in yd2
 
yd2 = [-sin(t); -sin(t+pi/4)];
 
% Interpolate to (ti) and estimate the 2nd derivative
 
yid2 = polyinterp(t,y,ti,5,3,2);
 
figure
plot(t,yd2,'-'), hold on
xlabel('time')
plot(ti,yid2,'or'), hold off
 
% Note that the window witdth and order of the derivative have
% been increased, and that the ends are not interpolated very well.
 
%End of POLYINTERPDEMO
 
echo off
