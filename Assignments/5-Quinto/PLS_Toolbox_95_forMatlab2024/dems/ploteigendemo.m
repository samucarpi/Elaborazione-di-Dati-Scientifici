echo on
%PLOTEIGENDEMO Demo of the PLOTEIGEN function.
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 06/21/04
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The PLOTEIGEN function produces a plot of Eigenvalues, Variance Captured,
% and other Model statistics from a standard regression or decomposition
% model. PLOTEIGEN is the command line call of a function that is regularly
% called by PLS_Toolbox graphical user interfaces. 
 
pause
%-------------------------------------------------
% First, data must be loaded and a model created from it. In this case, a
% PCA model will be created from the WINE file using autoscaling (For
% more information on creating models, see, for example the PLS and PCA
% functions).
% 
 
load wine
options = [];
options.display       = 'off';   %don't display anything
options.plots         = 'none';  %don't plot anything - we'll do them ourselves
options.preprocessing = { preprocess('default','autoscale') preprocess('default','autoscale') };
 
model = pca(wine,5,options);   %create PLS regression model
 
pause
%-------------------------------------------------
% The output model can be simply passed to PLOTEIGEN to view the results.
% The Plot Controls figure allows selection of various information for
% either the x- or y-axes. To view PC's vs. Eigenvalues select Principal
% Component Number for the x-axis and Eigenvalues for the y-axis.
%
 
ploteigen(model);
 
%End of PLOTEIGENDEMO
 
echo off
