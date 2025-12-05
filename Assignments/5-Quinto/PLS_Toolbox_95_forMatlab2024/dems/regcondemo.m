echo on
% REGCONDEMO Demo of the REGCON function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%bmw
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The REGCON function is used to convert regression models into
% y = a*x + b form, i.e. a simple slope plus intercept formulation.
% Note that currently this only works with mean centering, autoscaling
% or no preprocessing. 
%
% To show how REGCON works, we'll start by loading some data:
 
load plsdata
 
pause
%-------------------------------------------------
% This file consists of two predictor blocks (xblock1 and xblock2) and
% their corresponding y values (yblock1 and yblock2). All of them are
% dataset objects. We'll build a PLS model that relates the blocks.
% First we need to specify all the options for building the model:
 
options = pls('options');
poptions = preprocess('default','autoscale');
options.preprocessing{2} = poptions;
options.preprocessing{1} = poptions;
options.display = 'off';
options.plots = 'none';
 
pause
%-------------------------------------------------
% Now we're ready to build the model. We'll choose 5 LVs:
 
mod = pls(xblock1,yblock1,5,options);
 
pause
%-------------------------------------------------
% We can now convert the model using REGCON:
 
[a,b] = regcon(mod);
 
pause
%-------------------------------------------------
% Lets plot the coefficients:
 
plot(a)
echo off
hline
title('Regression Coefficients in Original Units')
xlabel('Variable Number')
ylabel('Coefficient')
shg
echo on
 
pause
%-------------------------------------------------
% We can now make predictions on the second data block using the
% output of REGCON as follows:
 
y = xblock2.data*a' + b;
 
% And we'll plot the results:
 
plot(yblock2.data,y,'+b'), dp
echo off
title('Predictions for xblock2')
xlabel('Actual Y')
ylabel('Predicted Y')
shg
echo on
 
pause
%-------------------------------------------------
% There are exactly the same predictions that would be obtained from
% using the whole model in the PLS routine, i.e.
 
pred = pls(xblock2,mod,options);
 
% but without all the associated statistics, like Q and T^2, and the
% residuals, etc.
 
echo off
  
   
