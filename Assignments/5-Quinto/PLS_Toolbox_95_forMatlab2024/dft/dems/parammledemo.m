echo on
%PARAMMLEDEMO Demo of the PARAMMLE function.
 
echo off
%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% PARAMMLE returns maximum likelihood parameter estimates for a
% distribution. Try using it on some sample data:
 
n = normdf('random',[1000 1],1,2);
 
params_norm = parammle(n,'normal')
params_logs = parammle(n,'logistic')
params_expo = parammle(n,'exponential')
 
% Notice the output is a structure array containing a field for each
% parameter estimate.
%
%End of PARAMMLEDEMO
%
%See also: CHITEST
 
echo off
