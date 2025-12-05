echo on
%PLTTERNFDEMO Demo of the PLTTERNF function
 
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
% PLTTERNF is a plotting utility for making ternary diagrams
% with frequency of occurrence in bars.
%
% Construct some "concentrations" to plot and call PLTTERNF.
 
conc = [0   0   1;
        1   0   0;
        0   1   0;
        0.3 0.3 0.3;
        0.5 0.5 0];
 
pause
%-------------------------------------------------
% And a frequency of occurence for each concentration
 
conc(:,4) = [1:5]'
 
pause
%-------------------------------------------------
% and now call PLTTERNF with labels
  
pltternf(conc,'A','B','C')
 
%End of PLTTERNFDEMO
 
echo off
