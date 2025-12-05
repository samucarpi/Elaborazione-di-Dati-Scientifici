echo on
%REPORTWRITERDEMO Demo of the REPORTWRITER function
 
echo off
%Copyright Eigenvector Research, Inc. 2014
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Creat a 2 PC model and allow default plots to be opened.
 
load wine

model  = pca(wine,2);

pause
%-------------------------------------------------
% Create simple report with all open figures.

allfigs = findobj(0,'type','figure');

myobjects = {model};

for i = 1:length(allfigs)
  myobjects = [myobjects {allfigs(i)}];
end

pause
%-------------------------------------------------
% Now call reportwriter.

reportwriter('html',myobjects,'Sample Report')

%End of REPORTWRITERDEMO
 
echo off
