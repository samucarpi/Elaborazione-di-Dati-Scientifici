echo on
%UNFOLDMDEMO Demo of the UNFOLDM function
 
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
% Create two blocks of data to demostrate the reshaping.
% Each submatrix has 4 samples, i.e. Nsamp = 4;
 
% Block 1
 
x1 = [1:4;1:2:8;1:3:12]'; disp(x1)
 
% Block 2
 
x2 = [11:14;11:2:18;110:10:140]'; disp(x2)
 
pause
%-------------------------------------------------
% Augment the blocks to create xaug.
 
xaug  = [x1; x2]
 
pause
%-------------------------------------------------
% Run UNFOLDM and examine the output
 
xmpca = unfoldm(xaug,2)
 
%End of UNFOLDMDEMO
 
echo off
