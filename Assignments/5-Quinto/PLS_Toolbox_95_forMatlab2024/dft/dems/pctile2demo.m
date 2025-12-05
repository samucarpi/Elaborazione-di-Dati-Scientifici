echo on
%PCTILE2DEMO Demo of the PCTILE2 function.
 
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
% PCTILE2 is an alternate to PCTILE1 and returns the same output, a
% specified percentile of the sample.
%
 
n = normdf('random',[1000 1],1,2);
pctile2(n,1)
pctile2(n,50)
pctile2(n,99)
 
%End of PCTILE2DEMO
%
%See also: PCTILE1
 
echo off
