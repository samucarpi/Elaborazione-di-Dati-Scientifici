echo on
% RIDGECVDEMO Demo of the RIDGECV function
 
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
% The RIDGECV function is used to develop ridge regression
% models using cross-validation. We'll use our PLS data set
% that was taken from Liquid Fed Ceramic Melter operation.
 
load plsdata
 
% Because RIDGECV is a base level function taking only matrix
% inputs, we'll need to scale the data. In this case we'll use
% autoscaling:
 
[ax,mx,stdx] = auto(xblock1.data);
[ay,my,stdy] = auto(yblock1.data);
 
% As a first step, we can use the ridge function
 
pause
%-------------------------------------------------
[b,theta] = ridge(ax,ay,0.05,20);
 
pause
%-------------------------------------------------
% It is also possible to determine the optimum value of
% theta through cross-validation using the ridgecv function.
 
[b,theta] = ridgecv(ax,ay,0.02,20,4);
 
pause
%-------------------------------------------------
% So you see that in this case the value of theta that we
% get from cross-valadation (0.0110) is almost exactly the
% the same as the value we get from the method of Hoerl, 
% Kennard and Baldwin (0.0104).
 
pause
%-------------------------------------------------
% We can make prediction on the second block of data and see
% how we did:
 
sx     = scale(xblock2.data,mx,stdx);
ypred  = sx*b;
sypred = rescale(ypred,my,stdy);
 
figure, plot(yblock2.data,sypred,'+b'), dp
xlabel('Actual Value'),ylabel('Predicted Value')
title('Predicted versus Actual Value for RIDGECVDEMO')
 
%End of RIDGECVDEMO
 
echo off
