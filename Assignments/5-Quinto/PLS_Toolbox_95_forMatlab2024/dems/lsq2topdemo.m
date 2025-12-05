echo on
% LSQ2TOPDEMO Demo of the LSQ2TOP function
 
echo off
% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The LSQ2TOP function is used to fit a line or polynomial through 
% the top (or bottom) of a data cloud.
 
% Consider the following data:
 
x   = [0.1:0.1:50]; x = sort([x,x,x,x]');      %axis scale
y   = 0.5*x+2-2.0*rand(length(x),1);     %simulated data cloud
m   = length(y);
figure, plot(1:m,y,'.b'), title('Simulated Data Cloud')
 
% Some algorithms rely on binning the y data into bins (windows)
% along the x-axis and then relying on a Kolomogorov-Smirnoff test.
% The LSQ2TOP least squares algorithm in stead relies on fitting
% the cloud with asymmetric weighting. For example, points significantly
% below the a line fit through the data are given a zero weighting.
% Therefore these samples are not considered in the next least squares
% fit of the line to the data. The significance level is given by
% the TSQLIM field in the options structure for LSQ2TOP, and the
% typical residual size is given by the input (res).
 
% Our objective in this example is to fit a straight line through
% the top of the plotted data.
pause
%-------------------------------------------------
% In this case, the call to LSQ2TOP uses the following I/O:
% [b,resnorm,residual] = lsq2top([],y,order,res);
% The input (order) is set to 1 (polynomial order = 1), and
% the approximate noise level or residual (res) is given as 0.1.
pause
%-------------------------------------------------
[b,resnorm,residual,opts] = lsq2top([],y,1,0.01);
plot(1:m,y,'.b',1:m,opts.px*b,'r-')
legend('Data Cloud', 'Fit to Top','Location','NorthWest')
pause
%-------------------------------------------------
% The next example will fit to the bottom. The options structure for
% LSQ2TOP will be changed so that we fit to the bottom of the data.
 
options = lsq2top('options')
options.trbflag = 'bottom';
 
% In this case, the call to LSQ2TOP uses the following I/O:
% [b,resnorm,residual,options] = lsq2top(x,y,order,res,options);
% The input (order) is set to 1, and the approximatenoise
% level (res) is given as 0.1.
 
[b2,resnorm2,residual2,opts2] = lsq2top(x,y,1,0.01,options);
plot(1:m,y,'.b',1:m,opts.px*b,'r-',1:m,opts2.px*b2,'m-')
legend('Data Cloud', 'Fit to Top','Fit to Bottom','Location','NorthWest')
 
%End of LSQ2TOPDEMO
 
echo off
