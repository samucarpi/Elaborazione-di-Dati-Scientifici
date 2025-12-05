echo on
%CLSDEMO Demo of the CLS function.
 
echo off
%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
echo on
 
%To run the demo hit a "return" after each pause
 
pause
 
% This demo uses the nir_data data set. The DataSet object (spec1)
% contains NIR spectra measured on Instrument 1. This is the X-block.
% the DataSet ojbect (conc) contains the corresponding concnetrations
% for five analytes present in the samples.
 
% The first step will estimate pure spectra for the five analytes
% using the first 24 samples.
 
pause
 
% Load the nir_data data set.
 
load nir_data
whos
disp(readme(1:6,:))
 
pause
 
% Next, get a copy of the options for the CLS function and
% set the options to estimate the pure target spectra from
% the concentrations using a non-negative least squares algorithm.
 
options = cls('options')
 
options.algorithm = 'snnls'; %Set to estimate spectra from concentrations
 
pause
 
% Call CLS and plot the results (use the Plot Controls to make desired
% plots). Note that the loadings plots are the estimates of the pure
% component spectra.
 
purespec = cls(spec1(1:24,:),conc(1:24,:),options);
 
% Note the plots of Y Predicted (FIT!) I versus Y Measured I suggest pretty
% good model fit to the calibration samples.

pause
 
% Because the CLS model is generally an oblique basis, the %fit for
% each component are only gross approximations.
 
% Next, the options will be changed to make a non-negative least
% squares estimate and CLS will be called to make predictions for
% the last six samples. The loaded concentrations [ conc(25:end,:) ]
% are now considered validation samples.
 
options.algorithm = 'cnnls'; %Set to estimate spectra from concentrations
concpred = cls(spec1(25:end,:),conc(25:end,:),options);
 
% Note the plots of Y Predicted I versus Y Measured I suggest pretty
% good predictions.
 
%End of CLSDEMO
 
echo off
