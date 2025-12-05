echo on
%SUMMARYDEMO Demo of the SUMMARY function.
 
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
% The SUMMARY function displays eleven statistics about a given data
% vector. 
%
%    mean  = mean of x,
%    std   = standard deviation of x,
%    min   = minimum in x,
%    max   = maximum in x,
%    p10   = 10th percentile = pctile1(x,10),
%    p25   = 25th percentile = pctile1(x,25),
%    p50   = 50th percentile = pctile1(x,50),
%    p75   = 75th percentile = pctile1(x,75),
%    p90   = 90th percentile = pctile1(x,90),
%    skew  = skewness, and
%    kurt  = kurtosis.
 
pause
%-------------------------------------------------
% Create sample data and call SUMMARY:
% 
 
n = normdf('random',[1000 1],1,2);
 
summary(n)
 
%End of SUMMARYDEMO
%
%See also: MEANS
 
echo off
