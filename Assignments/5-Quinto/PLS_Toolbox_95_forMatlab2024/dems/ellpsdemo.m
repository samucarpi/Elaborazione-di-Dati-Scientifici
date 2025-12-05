echo on
%ELLPSDEMO Demo of the ELLPS function
 
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
% Create data for plotting and plot an ellipse at the
% center 0,0 with major,minor axis 4,1 and another with 8,2
 
x = randn(100,1)*4;
t = randn(100,1);
figure
plot(x,t,'.')
hline, vline
ellps([0 0],[4,1],'--g')
ellps([0 0],[8,2],'--r')
 
pause
%-------------------------------------------------
% Try a rotated version
 
x = randn(100,1)*4;
t = randn(100,1)+x;
figure
plot(t,x,'.')
hline, vline
ellps([0 0],[4,1],'--g',pi/4)
ellps([0 0],[8,2],'--r',pi/4)
 
pause
%-------------------------------------------------
% And try a 3D version
 
z = randn(100,1)*0.01+2; z(1) = 0;
figure
plot3(t,x,z,'.'), grid
hline, vline, zline
ellps([0 0],[4,1],'--g',pi/4,3,2)
ellps([0 0],[8,2],'--r',pi/4,3,2)
 
%End of ELLPSDEMO
 
echo off
