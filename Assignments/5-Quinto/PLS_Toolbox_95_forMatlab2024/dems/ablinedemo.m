echo on
%ABLINEDEMO Demo of the ABLINE function
 
echo off
%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% ABLINE is a plotting aid. So, first
% create some data for plotting.
 
x = 1:100;
y = 3.*x + 0.01*x.^2 + .2;
 
pause
%-------------------------------------------------
% Now do a 2D plot
 
figure
plot(x,y,'.')
xlabel('Time'), ylabel('Response')
 
pause
%-------------------------------------------------
% We can calculate the linear fit of this data and use abline to quickly
% plot it on the figure 
 
fit = polyfit(x,y,1)
abline(fit(1),fit(2))
 
pause
%-------------------------------------------------
% The slope and intercept could also be taken from expected values, for
% example, lets say here we expected a slope of 3 and intercept of zero. We
% could plot another line on the axes showing the expected slope using a
% black dashed line.
 
abline(3,0,'color','k','linestyle','--')
 
%End of ABLINEDEMO
 
echo off
