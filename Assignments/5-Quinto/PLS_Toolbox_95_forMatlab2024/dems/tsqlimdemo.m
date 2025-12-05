echo on
%TSQLIMDEMO Demo of the TSQLIM function
 
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
% The TSQLIM function can be called to get estimates
% of the confidence limit line for Hotelling's T^2
% statistic for PCA models. (See Jackson, A User's Guide
% to Principal Components Analysis, Wiley, 1991).
 
pause
%-------------------------------------------------
% For a PCA model calibrated on 25 samples and using 2 PCs
% the 99% limit line is estimated as:
 
tsqcl = tsqlim(25,2,0.99)
 
pause
%-------------------------------------------------
% For a PCA model calibrated on 100 samples and using 4 PCs
% the 95% limit line is estimated as:
 
tsqcl = tsqlim(100,4,0.95)
 
% Note that this estimate is not valid when the number of
% PCs is >= the number of samples.
 
%End of FTESTDEMO
%
%See also: STATDEMO
 
echo off
