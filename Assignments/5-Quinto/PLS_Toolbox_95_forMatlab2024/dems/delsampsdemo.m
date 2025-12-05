echo on
%DELSAMPSDEMO Demo of the DELSAMPS function
 
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
% Create data:
 
x = [1:4];
x = x'*x
 
pause
%-------------------------------------------------
% Delete row 3:
 
eddata1 = delsamps(x,3)
 
pause
%-------------------------------------------------
% Delete rows 2 and 4:
 
eddata2 = delsamps(x,[2 4])
 
pause
%-------------------------------------------------
% Delete columns 2 and 3:
 
eddata3 = delsamps(x',[2 3])'
 
pause
%-------------------------------------------------
% Note that DELSAMPS is an overloaded method for DATASETs.
 
%End of DELSAMPSDEMO
 
echo off
