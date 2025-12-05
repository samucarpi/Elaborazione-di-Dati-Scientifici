echo on
% LSQ2TOPBDEMO Demo of the LSQ2TOPB function
 
echo off
% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg, modified LSQ2TOPDEMO
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The LSQ2TOPB function is used to fit basis functions and/
% or polynomial through the top (or bottom) of a data cloud.
 
% Consider the following data:
 
x   = [0.1:0.1:50]; x = [x,x,x,x]';      %axis scale
y   = 0.5*x+2-2.0*rand(length(x),1);     %simulated data cloud
 
figure, plot(x,y,'.b'), title('Simulated Data Cloud')
 
% The LSQ2TOPB least squares algorithm uses an asymmetric fitting
% the cloud with asymmetric weighting. For example, points significantly
% below the a line fit through the data are given a zero weighting.
% Therefore these samples are not considered in the next least squares
% fit of the line to the data. The significance level is given by
% the TSQLIM field in the options structure for LSQ2TOPB, and the
% typical residual size is given by the input (res).
 
% Our objective in this example is to fit a straight line through
% the top of the plotted data.
pause
%-------------------------------------------------
% In this case, the call to LSQ2TOPB uses the following I/O:
% [yi,resnorm,residual] = lsq2topb([],y,order,res);
% The input (order) is set to 1 (polynomial order = 1), and
% the approximate noise level or residual (res) is given as 0.1.
pause
%-------------------------------------------------
[yi,resnorm,residual] = lsq2topb(x,y,1,0.01);
plot(x,y,'.b',x,yi,'r-')
legend('Data Cloud', 'Fit to Top','Location','NorthWest')
pause
%-------------------------------------------------
% The next example will fit to the bottom. The options structure for
% LSQ2TOPB will be changed so that we fit to the bottom of the data.
 
options = lsq2topb('options')
options.trbflag = 'bottom';
 
% In this case, the call to LSQ2TOPB uses the following I/O:
% [yi,resnorm,residual,options] = lsq2top([],y,order,res,options);
% The input (order) is set to 1, and the approximatenoise
% level (res) is given as 0.1.
 
[yi2,resnorm2,residual2] = lsq2topb(x,y,1,0.01,options);
 
plot(x,y,'.b',x,yi,'r-',x,yi2,'m-')
legend('Data Cloud', 'Fit to Top','Fit to Bottom','Location','NorthWest')
 
%End of LSQ2TOPBDEMO
 
echo off
