echo on
%GSCALERDEMO Demo of the GSCALER function
 
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
% Create two blocks of data to demostrate group/block scaling:
%
% Block 1
x1 = [1:4;1:2:8;1:3:12]'; disp(x1)
 
% Block 2
x2 = [0.1:0.1:0.4;11:2:18;110:10:140]'; disp(x2)
 
pause
%-------------------------------------------------
% Augment the blocks to create x.
 
x  = [x1, x2]
 
pause
%-------------------------------------------------
% Run GSCALE and examine the output.
 
[gxs,mxs,stdxs] = gscale(x,2);
 
% Display the scaled matrix
 
gxs
 
pause
%-------------------------------------------------
% Use GSCALER to apply the scaling to the same (or new) matrix
 
gys = gscaler(x,2,mxs,stdxs)
 
% (gxs) and (gys) should be the same. This shows that GSCALER
% can be used to apply scaling from a calibration matrix to a
% new test matrix as in testing new data in MPCA. In this example
% the calibration and test matrices were the same so the outputs
% from GSCALE and GSCALER are identical.
 
%End of GSCALERDEMO
 
echo off
