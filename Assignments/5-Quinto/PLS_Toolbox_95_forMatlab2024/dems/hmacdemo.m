echo on
% HMACDEMO Demo of the HMAC function

echo off
% Copyright Eigenvector Research, Inc. 2004 Licensee shall not recompile,
% translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

echo on

%To run the demo hit a "return" after each pause
pause
%--------------------------------------------------------------------------

% HMAC (Hierarchical Model Auto Classifier) automatically generates a
%  hierarchical model to perform classification of samples.
%
% The use of HMAC will be demonstrated using the "iris" demo dataset.

pause
%--------------------------------------------------------------------------

load iris
x = iris;

% The iris data consists of measurements of 4 properties of iris flowers.
% The samples represent three different species of iris: 
% 'setosa', 'versicolor', and 'virginica'
%
% This demo will create a single model to discriminate between all three
% classes.
%
% To use HMAC either the calibration X-block must identify the class of 
% each sample or a y-variable must identify these.
% For the 'iris' dataset this is present as a classset: iris.class{1}.
%
% Split the dataset into calibration and test datasets:

pause
%--------------------------------------------------------------------------

m = size(x,1);
itst = 1:3:m;
ical = setdiff(1:m, itst);
xcal = x(ical,:);
xtst = x(itst,:);

% To build the classifier a HMAC object is created.
% Then the calibration x (and optionally y) data assigned, and some 
% options can be specified. 

pause
%--------------------------------------------------------------------------

hmac               = Hmac();
hmac.setX(xcal);
% hmac.setY(ycal);  % optional
opts               = hmac.getOptions;
opts.preprocessing = {preprocess('default','autoscale') preprocess('default','meancenter')};
opts.plots         = 'none';
hmac.setOptions(opts);

% Next a hierarchical model is built from the calibration samples. 

pause
%--------------------------------------------------------------------------

hmac = hmac.calibrate;
model = hmac.model;

% This is now a standard Hierarchical Model (HM) which can be used to make 
% predictions on test data. First set some options for the HM.

pause
%--------------------------------------------------------------------------

options = modelselector('options');
% Change error mode to struct so errors don't cause a stop when they occur:
options.errors = 'struct';
options.multiple = 'mostprobable';

% Now the classification model can be used to predict the class of samples 
% in a test dataset and the results summarized in a confusion table:

pause
%--------------------------------------------------------------------------

pred = modelselector(xtst, model, options);

ytrue = xtst.classid{1};
pred  = pred.classid{1,1};
confusiontable(pred, ytrue)

[confusiontab, classids, texttable] = confusiontable(pred, ytrue);

% The confusion table shows perfect classification of the test dataset.
%
% Finally, the hierarchical model can be opened in modelselectorgui to 
% provide a visual representation. 
% Dragging a dataset onto this window's canvas from the browser will apply 
% it to that dataset and the predictions shown in a new dataset editor 
% window:

pause
%--------------------------------------------------------------------------

modelselectorgui(model)
% end