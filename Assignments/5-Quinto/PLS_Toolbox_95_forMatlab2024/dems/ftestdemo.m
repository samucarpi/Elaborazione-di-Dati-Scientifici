echo on
%FTESTDEMO Demo of the FTEST function
 
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
% The FTEST function can be called in two ways.
% First, estimate the appropriate F-statistic for
% at the 95% confidence limit (alpha = 1-0.95 =0.05)
% with 5 degrees of freedom in the numator and
% 8 degrees of freedom in the denomenator.
 
a = ftest(0.05,5,8)
 
pause
%-------------------------------------------------
% Second, use the inverse F-Test i.e. estimate the
% approximate alpha from the given F-statistic (a)
% with 5 degrees of freedom in the numator and
% 8 degrees of freedom in the denomenator. Note, that
% the fourth input is a flag set to (2) to indicate
% that this is an inverse test
 
a = ftest(a,5,8,2)
 
%End of FTESTDEMO
 
echo off
