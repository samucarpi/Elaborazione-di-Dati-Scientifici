echo on
%PLOTLOADSDEMO Demo of the PLOTLOADS function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The PLOTLOADS function will produce a useful plot of loadings and other
% variable information given a standard regression or decomposition model
% structure. Such structures are output from, for example, the functions
% PCA, PLS, DECOMPOSE, or REGRESSION. Many of these functions use
% PLOTLOADS themselves to automatically produce loadings plots but it can
% also be called from the command line given the model structure or even a
% raw-loadings matrix.
%
% Here the use with a model structure will be demonstrated. 
% 
 
pause
%-------------------------------------------------
% First, data must be loaded and a model created from it. In this case, a
% PLS model will be created from the PLSDATA file using autoscaling (For
% more information on creating models, see, for example the PLS and PCA
% functions).
% 
 
load plsdata
options = [];
options.display       = 'off';   %don't display anything
options.plots         = 'none';  %don't plot anything - we'll do them ourselves
options.preprocessing = { preprocess('default','autoscale') preprocess('default','autoscale') };
 
model = pls(xblock1,yblock1,3,options);   %create PLS regression model
 
pause
%-------------------------------------------------
% The output model can be simply passed to plotloads to view the results.
% The Plot Controls figure allows selection of various information for
% either the x- or y-axes. Loadings, weights, and regression vectors can be
% plotted (note, only loadings would be available from a PCA model).
% Loadings vs. Loadings plots can be created by selecting one loading for
% the x-axis and another for the y-axis. 
%
 
plotloads(model);
 
%End of PLOTLOADSDEMO
 
echo off
