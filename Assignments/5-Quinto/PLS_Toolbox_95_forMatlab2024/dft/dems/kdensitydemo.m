echo on
%KDENSITYDEMO Demo of the KDENSITY function.
 
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
% The KDENSITY function produces the kernel density estimate
% of sample data. 
% 
 
n = normdf('random',[1000 1],1,2);
kkde = kdensity(n,2,22.4,50);
 
%End of KDENSITYDEMO
%
%See also: KTOOL
 
echo off
