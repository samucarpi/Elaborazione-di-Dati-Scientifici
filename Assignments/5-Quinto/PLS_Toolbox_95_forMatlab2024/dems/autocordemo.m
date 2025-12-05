echo on
% AUTOCORDEMO Demo of the AUTOCOR function
 
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
% The AUTOCOR function is used to calculate the autocorrelation
% function of a time series, i.e. how correlated a signal is with
% itself as a function of time lag. To demo the function, we'll
% start with a totally random series:
 
 
x1 = randn(1000,1);
 
pause
%-------------------------------------------------
% We'll calculate the autocorrelation function of this random
% series. We expect that the signal should be totally uncorrelated
% with itself after only one time step.
 
autocor(x1,15); shg
shg
 
pause
%-------------------------------------------------
% If we filter or smooth the signal, we expect that the signal
% will be correlated with itself for small time shifts. As an
% example, we'll smooth the signal using the SAVGOL function over
% a 5 point window. We'd now expect the signal to be correlated
% with itself for shifts of up to 4 time units:
 
x1s = savgol(x1',5,0,0); shg
autocor(x1s,15);
 
 
echo off
  
   
