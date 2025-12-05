echo on
%KSTESTDEMO Demo of the KSTEST function.
 
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
% The KTEST function is the Kolmogorov-Smirnov test that a sample is from a
% given distribution. The smaller the value of the returned statistic, the
% less evidence to reject that candidate distribution. 
 
n = normdf('random',[1000 1],1,2);
 
kstest(n,'normal')
kstest(n,'logistic')
kstest(n,'exponential')
 
% We see that the smallest Dn value is for 'normal' and correctly conclude
% that the Normal distribution is the most likely parent of the data.
%
%End of KSTESTDEMO
%
%See also: CHITEST, DISTFIT
 
echo off
