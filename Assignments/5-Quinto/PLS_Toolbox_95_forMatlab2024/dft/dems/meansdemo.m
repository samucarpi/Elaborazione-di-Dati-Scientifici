echo on
%MEANSDEMO Demo of the MEANS function.
 
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
% MEANS calculates the algebraic, harmonic, and geometric mean of a vector.
% Create some sample data and call MEANS:
 
n = normdf('random',[1000 1],1,2);
 
rslt = means(n)
 
% Notice result is returned as a structure with each mean and the number of
% observations used for the calculation.
%
%End of MEANSDEMO
%
%See also: SUMMARY
 
echo off
