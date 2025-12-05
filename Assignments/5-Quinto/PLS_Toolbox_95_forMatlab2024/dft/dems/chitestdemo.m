echo on
%CHITESTDEMO Demo of the CHITEST function.
 
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
% This demo will show how to call the chitest function to assess how well a
% distribution fits sample data. Create sample data with the normaldf
% function:
% 
 
n = normdf('random',[1000 1],1,2);
 
pause
%-------------------------------------------------
% Now test several distributions with chitest to see how well they fit:
 
rslt_norm = chitest(n,'normal')
 
rslt_beta = chitest(n,'beta')
 
rslt_logis = chitest(n,'logistic')
 
% Notice how 'normal' has the strongest conclusion but we also can't reject
% 'logistic'. The p-value for 'beta' however does indicate that is not the
% parent distribution. See the reference and tutorial manuals for more
% information on the function and its other outputs.
%
%End of CHITESTDEMO
%
%See also: DISTFIT
 
echo off
