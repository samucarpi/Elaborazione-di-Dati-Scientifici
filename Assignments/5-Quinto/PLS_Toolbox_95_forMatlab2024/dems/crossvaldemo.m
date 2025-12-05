echo on
%CROSSVALDEMO Demo of the CROSSVAL function
 
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
% Crossval is a very powerful cross-validation routine. Here the basic
% regression cross-validation use will be shown. It should be noted that
% crossval can do PCA decomposition cross-validation as well as
% discriminate analysis and user-defined cross-validation designs as well.
 
pause 
%-------------------------------------------------
% First, load some data to cross-validate:
 
load plsdata
whos
 
pause
%-------------------------------------------------
% The basic call to crossval requires various inputs:
%   crossval(x, y, rm, cvi, ncomp, options)
% Here it will be called using the following for each of these inputs:
%  rm = 'sim'            %PLS using simpls algorithm
%  cvi = {'con' 5}       %contiguous block cross-validation, 5 splits
%  ncomp = 8             %models up to 8 components
%  options = (set below) %preprocessing and display settings to use
 
pause
%-------------------------------------------------
% the options structure input contains a large number of different options
% which can be set. In many cases, the default values are fine. You can
% view all default option values by requesting 'options' from crossval:
 
options = crossval('options');
 
pause
%-------------------------------------------------
% Here are the defaults:
 
options
 
pause
%-------------------------------------------------
% Here the only option we will change is the preprocessing options.
% preprocessing can be a "0" to indicate no preprocessing at all, "1" to
% indicate mean-centering for both x and y, or it can be a cell containing
% two preprocessing structures (see PREPROCESS). Here we want to use
% autoscaling so we'll set preprocessing using two calls to preprocess:
 
options.preprocessing = {preprocess('default','autoscale') preprocess('default','autoscale')};
 
pause
%-------------------------------------------------
% Putting all this together, the call to crossval can be done:
 
results = crossval(xblock1,yblock1,'sim',{'con' 5},8,options);
 
pause
%-------------------------------------------------
% Outputs can be requested individually or as a single output structure.
% The structure output contains even more information than the
% individual outputs offer.
% Both outputs formats include the predictive residual error sum of squares
% for all test blocks, for all models, and all y-columns (press),
% cumulative PRESS for all models and y-columns (cumpress), root-mean
% squared error of cross-validation (RMSECV), root-mean squared error of
% calibration (RMSEC), and the y-values predicted for each sample when it
% was left out in a test set (cvypred).
 
pause
%-------------------------------------------------
% Here are the numeric results from the cross-validation:
 
results 
 
% type "crossval help" for more information.

%End of CROSSVAL demo
echo off
