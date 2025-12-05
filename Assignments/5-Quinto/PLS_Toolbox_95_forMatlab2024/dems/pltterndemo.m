echo on
%PLTTERNDEMO Demo of the PLTTERN function
 
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
% PLTTERN is a plotting utility for making ternary diagrams.
%
% Construct some "concentrations" to plot and call PLTTERN.
 
conc = rand(25,3);
plttern(conc)
 
pause
%-------------------------------------------------
% Now call PLTTERN with labels
 
conc = rand(25,3)
plttern(conc,'A','B','C')
 
%End of PLTTERNDEMO
 
echo off
