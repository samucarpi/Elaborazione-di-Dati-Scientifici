echo on
% MED2TOPDEMO Demo of the MED2TOP function
 
echo off
% Copyright © Eigenvector Research, Inc. 2005
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The MED2TOP function is used to fit a line the top 
% or bottom of a data cloud. The line is the median
% of the bulk of the data.
 
% Consider the following data:
 
y   = randn(1000,1)*0.1 + abs(randn(1000,1));     %simulated data cloud
 
figure, plot(y,'.b'), title('Simulated Data Cloud'), hold on
 
% MED2TOP estimates the median of the data cloud and the sum of
% squared residuals about the median (yielding a robust estimate
% of the std). Then it throws away data with a residual/std above
% options.tsqst.
 
% This is typically faster than the LSQ2TOP algorithm, but is less
% flexible. (The LSQ2TOP least squares algorithm fits using an
% asymetric least squares to a polynomial).
 
% Our objective in this example is to fit a straight line through
% the bottom of the plotted data.
 
pause
%-------------------------------------------------
% In this case, the call to MED2TOP uses the following I/O:
% [yf,residual,options] = med2top(y,options);
 
options               = med2top('options')
options.trbflag       = 'bottom';
[yf,residual,options] = med2top(y,options);
 
hline(yf,'r')
i1                    = find(options.initwt);
hold on, plot(i1,y(i1),'.c')
legend('Data Cloud', 'Fit to Bottom','Samples in fit estimate','Location','NorthWest')
 
pause
%-------------------------------------------------
% The default limit for the fit was options.tsqlim = 0.99.
% Changing this to a lower number changes the estimate
% of (yf):
 
options.tsqlim = 0.9;
options.initwt = []; %reset the initial weights
[yf,residual,options] = med2top(y,options);
hline(yf,'b')
i1                    = find(options.initwt);
hold on, plot(i1,y(i1),'.m')
legend('Data Cloud', '1st fit','1st fit samples','2nd fit','2nd fit samples','Location','NorthWest')
  
%End of MED2TOPDEMO
 
echo off
