echo on
%BATCHFOLDDEMO Demo of the BATCHFOLD function.
 
echo off
%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% BATCHFOLD Transform batch data into dataset for analysis. Based on
% 'method' type, fold/unfold data into suitable form for analysis.
%
%  Data is separated both by batch (experiments) and also optionally by
%  step number (sub-divisions of batch indicating processing segments or
%  other division of batches). Identification of batch and step can be from
%  class, label, axisscale, or variable. Steps can be manually identified
%  in the BSPCGUI interface.
%
%  Data input is assumed to be a two-way matrix consisting of samples by
%  variables.

% Load 'Dupont_BSPC' demonstration dataset. This data contains:
%  * 10 process variables (5 temperature, 3 pressure, and 2 flow)
%  * Each variable measured at 100 time intervals.
%  * 36 batches in the calibration dataset and 19 test batches.
%  * Each Batch is indicated in the "BSPC Batch" class (first set).
%  * Each batch has 8 steps indicated in the "BSPC Step" class (second set).

 
load Dupont_BSPC

dupont_cal
 
pause
%-------------------------------------------------
% Using the BATCHFOLD options you can indicate the source 'field' and 'set'
% for the Batch and Step information. By default, the Batch and Step
% information is presumed to be in the class field with default set names
% of "BSPC Batch" and "BSPC Step". The Dupont BSPC data has this
% information so it's not necessary to edit the batch and step location.
 
bopts = batchfold('options')
 
pause
%-------------------------------------------------
% To fold the data for Summary PCA we'll need to indicate the
% .step_selection_classes and summary methods. For this data, the first and
% last steps were "ramping" steps and can be left out. We'll choose mean,
% std, slope, and length for our summary variables.
 
bopts.step_selection_classes = [ 2:7 ];%Numeric classes only.
bopts.summary = { 'mean' 'std' 'slope' 'length' };%((10 variables x 3 stats) + length) x 6 steps = 186 variables
 
pause
 
%-------------------------------------------------
%Make batchfold model. Notice that the resulting dataset is 36 x 186.
%That's 36 batches by 186 summary variables. The 186 summary variables
%includes 31 stats per step. The 31 stats come from mean, std, and slope
%for each original variable and a single length (of steps) for each.
 
[batch_cal_data,batch_spca_modl] = batchfold('spca',dupont_cal,bopts);
 
pause
 
%-------------------------------------------------
%Make SPCA model.
 
pca_options = pca('options');
pca_options.preprocessing = preprocess('default','autoscale');
 
pca_cal_model = pca(batch_cal_data,3,pca_options);
 
pause
 
%-------------------------------------------------
%Make prediction on test data. Using the batchfold model from above we can
%apply the same folding settings to the test data and get a prediction from
%the pca model.

%Get folded test data with batfold model.
batch_test_data = batchfold(dupont_test,batch_spca_modl);

%Get prediction of test data.
pca_test_pred = pca(batch_test_data,pca_cal_model);
 
pause
 
%-------------------------------------------------
% The following observations can be made using the plot controls.
%
%  Batches 40, 41, 42, 50, 51, 53, 54 and 55 had the final quality measurement well outside the acceptable limit
%  Batches 38, 45, 46, 49 and 52 were above or very close to that limit.
%  Batches 38, 40, 41 and 42 cannot be identified as abnormal batches.*
%  Additional batches 37, 39, 43, 44, 47, 47 and 48 were identified as somewhat unusual and were not included in the calibration set.*
%  Described in: 
%    * Nomikos, P. and J.F. MacGregor, Multivariate SPC charts for monitoring batch processes, Technometrics, 37(1), 1995. 
% 
 
pause
 
%-------------------------------------------------
% Create an MPCA model using the same technique. Since MPCA requires
% alignment, these settings must be added to the options. In this data, the
% batches are all equal length but we're showing the code for example
% purposes.

bopts.alignment_batch_class = 3;%What to batch to align on.
bopts.alignment_variable_index = 5;%What variable to align on.

bopts.batch_align_options.method = 'cow';%Try using COW alignment.

%Fold cal data and get a model.
[batch_cal_data2,batch_mpca_modl] = batchfold('mpca',dupont_cal,bopts);
%Fold test data with model.
batch_test_data2 = batchfold(dupont_test,batch_mpca_modl);

%Run MPCA:
mpca_options = mpca('options');
mpca_options.preprocessing = preprocess('default','groupscale');

%MPCA Cal
mpca_cal_model = mpca(batch_cal_data2,3,mpca_options);
%MPCA Prediciton.
mpca_cal_pred  = mpca(batch_test_data2,mpca_cal_model);
 
pause
 
%-------------------------------------------------
% The same observations can be seen as above. Using the Plot Controls one
% can explore the model and observe outliers.


%End of BATCHFOLDDEMO
 
echo off


