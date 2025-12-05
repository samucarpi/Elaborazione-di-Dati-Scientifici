echo on
%DISTFITDEMO Demo of the DISTFIT function.
 
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
% The distfit function reports the results from most likely to least
% likely parent distribution using the chi-squared test. Create sample data
% then call distfit:
 
n = normdf('random',[1000 1],1,2);
 
rslt = distfit(n);
 
pause
%-------------------------------------------------
% The results correctly show the most likely parent distribution as
% 'normal'. You can turn off the plot (figure) by using options.
%
%End of DISTFITDEMO
%
%See also: CHITEST
 
echo off
