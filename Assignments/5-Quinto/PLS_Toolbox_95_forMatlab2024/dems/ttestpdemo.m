echo on
%TTESTPDEMO Demo of the TTESTP function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The TTESTP function can be called in two ways.
% First, use TTESTP to estimate the approximate alpha from
% the given T-statistic (x = 1.9606) with 5000 degrees of freedom.
% (The flag (z=1) {default})
 
y = ttestp(1.9606,5000)
 
% For a two sided test this corresponds to the 95% confidence level, and
% for a one sided test this corresponds to the 97.5% confidence level.
 
pause
%-------------------------------------------------
% Second, estimate the T-statistic for at the 99% confidence limit
% for a two-sided test (alpha = (1-0.99)/2 =0.005) with 5000 degrees
% of freedom.
 
y = ttestp(0.005,5000,2)
 
%End of TTESTPDEMO
%
%See also: STATDEMO
 
echo off
