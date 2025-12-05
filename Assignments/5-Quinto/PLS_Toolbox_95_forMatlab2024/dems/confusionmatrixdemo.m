echo on
%CONFUSIONMATRIXDEMO Demo of the confusion matrix and table functions
%
echo off
% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------

% Get the confusion matrix and table for known true and predicted classes.
 
% Consider the case of twelve samples: 4 each of class 1, 2 and 3:
trueclass = [1 1 1 1 2 2 2 2 3 3 3 3];
 
% All sample classes are predicted correctly except for sample #12 which is 
% predicted to be class 2 instead of class 3:
predclass = [1 1 1 1 2 2 2 2 3 3 3 2];
 
pause
%-------------------------------------------------

% The confusion matrix summarizes the true positive, false positive, true
% negative, and false negative rates, where these rates are defined as:
% TPR: proportion of positive cases that were correctly identified
% FPR: proportion of negatives cases that were incorrectly classified as positive
% TNR: proportion of negatives cases that were classified correctly
% FNR: proportion of positive cases that were incorrectly classified as negative
%
% confusionmatrix can be called with or without return values.
% [confusionmat, classnames] = confusionmatrix(model);
% calling confusionmatrix with no return values prints the confusion matrix:
 
pause
%-------------------------------------------------

confusionmatrix(trueclass,predclass);
 
% Next, look at the Confusion Table.
 
pause
%-------------------------------------------------
 
% The confusion table summarizes how many of each class were predicted as
% each class.
% confusiontable can be called with or without return values.
% [confusiontab, classnames] = confusiontable(model);
% calling confusiontable with no return values prints the confusion table:

 
confusiontable(trueclass,predclass);

% This shows all 4 class 1 samples were predicted correctly as class 1,
% similarly for all 4 class 2 samples, whereas only 3 class 3 samples were
% predicted as class 3, with one being predicted as class 2.
 
pause
%-------------------------------------------------
 
% Next, using a model as input.
% It is also possible to get a confusion matrix and table by inputting a
% classification model or pred (PLSDA, SVMDA or KNN) since these models
% contain the details of the true and predicted classes of the samples
 
% Build a PLSDA model from the arch dataset and get a confusion matrix 
% and confusion table from a PLSDA model

pause
%-------------------------------------------------
load arch
y = arch.class{1}; 
 
% Create plsda model
opts               = plsda('options');
opts.preprocessing = {preprocess('default','autoscale') preprocess('default','meancenter')};
opts.plots         = 'none';
opts.display       = 'off';
ncomp = 3;                            % Number of PLS latent variables to calculate
model = plsda(arch,y, ncomp,opts);    % Build plsda model (using arch's classid string class name)

% Show Confusion matrix:

pause
%-------------------------------------------------

% Rows are classes ordered as unique(y), excluding class 0; Columns are: TP FP TN FN rates
[confusionmat, classnames] = confusionmatrix(model);
confusionmatrix(model);               % Prints output if there are no returned values

% Show Confusion table:
 
pause
%-------------------------------------------------

% Confusion table
% (i,j) is number predicted to be class  with index i which actually are class with index j
[confusiontab, classnames] = confusiontable(model);
confusiontable(model);                % Prints output if there are no returned values

% These show that PLSDA perfectly predicts the class of each calibration
% sample.
 
%End of CONFUSIONMATRIX demo
echo off

% Identifying misclassified samples:
% % misclassifiedIndex = 1 indicates sample was misclassified
% theclass = 2;                         % Get misclassification status for this class
% [misclassifiedIndex, status] = getmisclassifieds(model, theclass);
% % Prints output if there are no returned values
% y(misclassifiedIndex);                % These are the misclassified samples 
