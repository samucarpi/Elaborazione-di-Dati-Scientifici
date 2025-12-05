echo on
%FACTDESDEMO Demo of the FACTDES function
 
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
% Create a 3 factor, 2 level full factorial design
%
 
desgn = factdes(3)
 
pause
%-------------------------------------------------
% Create a 2 factor, 3 level full factorial design
%
 
desgn = factdes(2,3)
 
figure
plot(desgn(:,1),desgn(:,2),'o'), hold on
axis([-2 2 -2 2]), axis square, hline, vline
 
%End of FACTDESDEMO
 
echo off
