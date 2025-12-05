echo on
% CROSSCORDEMO Demo of the CROSSCOR function
 
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
% The CROSSCOR function is used to calculate the cross-correlation
% function of two time series, i.e. how correlated one signal is with
% another as a function of time lag. To demo the function, we'll
% start with a totally random series:
 
y = randn(10010,1);
 
pause
%-------------------------------------------------
% Then we'll create another random time series that contains a small
% amount of the first signal shifted by 10 time steps (and we'll trim
% off the first series):
 
x = randn(10000,1) + y(11:end,1)*.2;
y = y(1:10000,:);
 
pause
%-------------------------------------------------
% We'll calculate the cross-correlation function of these random
% series. We expect that the one signal should be totally uncorrelated
% with the other except for at a time lag of 10 units:
 
crosscor(x,y,15); shg
shg
 
pause
%-------------------------------------------------
% The function will return the cross-correlation coefficients. It can
% also be set to supress the plots, and calculate the cross covariance
% instead of correlation. 
 
echo off
  
   
