echo on
%PLOTSCORESDEMO Demo of the PCA function
 
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
% The PLOTSCORES function will produce a useful plot of scores and other
% sample information given a standard regression or decomposition model
% structure. Such structures are output from, for example, the functions
% PCA, PLS, DECOMPOSE, or REGRESSION. Many of these functions use
% PLOTSCORES themselves to automatically produce scores plots but it can
% also be called from the command line given the model structure or even a
% raw-scores matrix.
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
% The output model can be simply passed to plotscores to view the results.
% The Plot Controls figure allows selection of various information for
% either the x- or y-axes. Scores, statistics or predictions can be plotted
% and, for some of these, confidence limits can be added onto the figure by
% checking the Conf. Limits box. Additionally, plots of predicted vs.
% measured provide a 1:1 diagonal line for reference (right-click or
% control-click on this line for more details about the fit).
%
 
plotscores(model);
 
pause
%-------------------------------------------------
% If predictions from a regression or decomposition model exist, they can
% be viewed along with the original calibration data by passing both the
% model and the prediction. For example, here the prediction for "xblock2"
% are passed along with the original PLS model.
%
  
pred = pls(xblock2,yblock2,model,options);  %predict for xblock2 
 
pause
%-------------------------------------------------
% Now plot those predictions along with the original model. The original
% model points can be removed from the plots by un-checking the "Show Cal
% w/Test" box.
%
 
plotscores(model,pred);
 
%End of PLOTSCORESDEMO
 
echo off
