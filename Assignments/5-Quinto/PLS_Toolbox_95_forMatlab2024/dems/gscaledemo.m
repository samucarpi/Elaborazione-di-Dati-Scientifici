echo on
%GSCALEDEMO Demo of the GSCALE function
 
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
% Run GSCALE and examine the outputs.
 
[gxs,mxs,stdxs] = gscale(x,2);
 
% Display the scaled matrix
 
gxs
 
pause
%-------------------------------------------------
% Display the offset and scale factor.
 
mxs, stdxs
 
pause
%-------------------------------------------------
% Note that the relative variance w/in each block is retained
 
[std(x2(:,1))/std(x2(:,3)), std(gxs(:,4))/std(gxs(:,6))]
 
pause
%-------------------------------------------------
% But that the variance for each block is now the same
 
% Before GSCALE
 
[sqrt(sum(std(x1).^2)), sqrt(sum(std(x2).^2))]
 
% After GSCALE
 
[sqrt(sum(std(gxs(:,1:3)).^2)), sqrt(sum(std(gxs(:,5:6)).^2))]
 
%End of GSCALEDEMO
 
echo off
