echo on
%PCTILE1DEMO Demo of the PCTILE1 function.
 
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
% PCTILE1 returns the specified percentile of the sample. 
% 
 
n = normdf('random',[1000 1],1,2);
pctile1(n,1)
pctile1(n,50)
pctile1(n,99)
 
%End of PCTILE1DEMO
%
%See also: PCTILE2
 
echo off
