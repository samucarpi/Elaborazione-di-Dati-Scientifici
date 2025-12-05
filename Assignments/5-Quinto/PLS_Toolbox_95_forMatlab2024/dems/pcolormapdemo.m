echo on
%PCOLORMAPDEMO Demo of the PCOLORMAP function
 
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
% Construct some data for the demo
 
x  = [1:3];  x = x'*x
 
% and create lables for the plot
 
xlbl = char('one','two','three');
ylbl = char('A','B','C');
 
pause
%-------------------------------------------------
% generate the pseudocolor map of the data with labels.
 
pcolormap(x,xlbl,ylbl)
 
% Note that the color indicates level (the colormap was rwb)
 
pause
%-------------------------------------------------
% Load wine data (wine) for the demonstration:
 
load wine
wine.includ{2,1} = 1:3;   %use only the first 3 variables
 
pause
%-------------------------------------------------
% generate the pseudocolor map of the data with labels.
 
pcolormap(wine)
 
% Labels for the plot were extracted from the DataSet object.
 
%
%End of PCOLORMAPDEMO
 
echo off
