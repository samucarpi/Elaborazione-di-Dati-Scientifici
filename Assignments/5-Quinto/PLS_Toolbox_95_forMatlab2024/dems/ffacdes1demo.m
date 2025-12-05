echo on
%FFACDES1DEMO Demo of the FFACDES1 function
 
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
% Create a 3 factor, 2 level full factorial design and
% Compare it to a 3 factor, 3-1 fractional 2 level design 
%
 
desgnk = factdes(3)
desgnp = ffacdes1(3,1)
 
pause
%-------------------------------------------------
% Create a 4 factor, 2 level full factorial design and
% Compare it to a 4 factor, 4-1 fractional 2 level design 
%
 
desgnk = factdes(4)
desgnp = ffacdes1(4,1)
 
pause
%-------------------------------------------------
 
%End of FACTDESDEMO
 
echo off
