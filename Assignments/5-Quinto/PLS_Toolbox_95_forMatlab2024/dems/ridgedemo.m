echo on
% RIDGEDEMO Demo of the RIDGE function
 
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
% The RIDGE function is used to develop ridge regression
% models. The data set we'll be using to start here is taken from
% Applied Regression Analysis by Draper and Smith.  It is 
% known as the Hald data set.
 
pause
%-------------------------------------------------
load halddata
 
% Because RIDGE is a base level function taking only matrix
% inputs, we'll need to scale the data.  In this case we'll
% choose mean centering, mostly because that is
% what Draper and Smith did.
pause
%-------------------------------------------------
[mcx,xmns] = mncn(xblock.data);
[mcy,ymns] = mncn(yblock.data);
 
% Now we can use the ridge regression function to form a
% model.  Here we'll choose a maximum value of theta to
% be thetamax = 1 and we'll look at 50 increments of theta
% from 0 to 1.
pause
%-------------------------------------------------
[b,theta] = ridge(mcx,mcy,1,50);
pause
%-------------------------------------------------
% The plot that you see is the values of the regression
% coefficients as a function of theta, the ridge parameter.
% The numbers key the lines to each of the coeficients.
% The vertical line is drawn at the optimum theta as 
% determined by the method of Hoerl, Kennard and Baldwin
% as given in Draper and Smith (p 317).  Compare to figure
% 6.4 of Draper and Smith.
 
pause
%-------------------------------------------------
% We may wish to zoom in on the area near the optimum theta.
% To do this we just change the input arguments.
 
[b,theta] = ridge(mcx,mcy,.03,50);
pause
%-------------------------------------------------
% It is also interesting to use ridge regression on our pls
% data set.  
 
load plsdata
 
% This time we'll autoscale the data.
 
ax = auto(xblock1.data);
ay = auto(yblock1.data);
 
% As a first step, we can use the ridge function
pause
%-------------------------------------------------
[b,theta] = ridge(ax,ay,.05,20);
pause
%-------------------------------------------------
% It is also possible to determine the optimum value of
% theta through cross-validation using the ridgecv function.
 
[b,theta] = ridgecv(ax,ay,.02,20,4);
pause
%-------------------------------------------------
% So you see that in this case the value of theta that we
% get from cross valadation (.0110) is almost exactly the
% the same as the value we get from the method of Hoerl, 
% Kennard and Baldwin (.0104)
 
echo off   
