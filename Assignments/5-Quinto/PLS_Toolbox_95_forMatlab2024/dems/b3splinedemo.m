echo on
%B3SPLINEDEMO Demo of the B3SPLINE function
 
echo off
%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% B3SPLINE is a curve fitting function. First
% some example data to be fit are created.
 
% Note that the I/O will be: modl  = b3spline(x,y,t,options);
% where (x) is the independent variable and (y) is
% the dependent variable.
 
x = [1:50]';    
y = [1 + x/50 + sin(2*pi*x)/4 + randn(50,1)*0.1];
 
pause
%-------------------------------------------------
% Next, fit the data with t=5 uniformly spaced knots
% and let B3SPLINE plot the results.
 
t    = 5; %integer scalar of the number of uniformly spaced knots
modl = b3spline(x,y,t); %Call to B3SPLINE
 
% Output (modl) is a structure array that includes the
% fitting parameters and other model information.
 
pause
%-------------------------------------------------
% Next, fit the data with 4 non-uniformly spaced knots
% and let B3SPLINE plot the results.
 
% t = vector of non-uniformly spaced knot locations.
% Note that the knot locations must be interior to the set
% defined by input (x), i.e. min(x)<tk<max(x),
% for k = 1,...,length(t); [min(x) is 1 and max(x) is 50];
% However, t(1) and t(end) define the endpoint of the 
% support region and are not true knots. In the previous
% example the endpoints were
%   t(1) = min(x) and
%   t(end) = max(x).
% In this example, t(1) and t(end) are clearly exterior
% to the data (x), and can be used to "spread out" the
% splines on the ends of the support region.
 
t    = [min(x)-0.8 5.2 21.3 28.5 33.1 max(x)+0.4]';
modl = b3spline(x,y,t); %Call to B3SPLINE
  
% Fit results at each point in (x) are in modl.pred{2},
% so fit is plot(x,modl.pred{2},'-') and raw data are
% hold on, plot(x,y,'.'). The red dots are the locations
% of the knots.
pause
 
%-------------------------------------------------
% In some instances, there is an interest for the fit
% to be 0 outside the region defined by x. For instance,
% this can provide well-behaved predictions when extrapolating.
% The 'b3_0' algorithm provides this functionality by constraining
% the fit to be 0 at t1 and tK.
% The 'b3_01' algorithm also constrains
% the derivative to be 0 at t1 and tK.
% For this demo it should be clear that the data do not
% go to zero at the ends, but the functions are constrained
% to do so.
 
x = [[-1:0.01:1]'; [-0.9:0.2:0.9]'];                  %New X
y = 1-x.^2 + cos(2*pi*x).^2 + randn(length(x),1)*0.1; %New Y

opts = b3spline('options');
opts.algorithm = 'b3_0';      %change from default that is 'b3spline'
modl = b3spline(x,y,11,opts); %Calibration of B3SPLINE model
xp   = [-1.25:0.05:1.25]';           %New X requiring extrapolation
pred = b3spline(xp,modl);            %Make predictions
hold on, plot(xp,pred.pred{2},'xr'); %Plot predictions
text(-0.75,0.1,'x = predictions from b3_0','interpreter','none')
pause
 
opts.algorithm = 'b3_01';
modl = b3spline(x,y,11,opts);
pred = b3spline(xp,modl);
hold on, plot(xp,pred.pred{2},'+m')
text(-0.75,0.1,'+ = predictions from b3_01','interpreter','none')
 
%End of B3SPLINEDEMO
 
echo off
