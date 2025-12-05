echo on
%UMAPDEMO Demo of the UMAP function
 
echo off
%Copyright Eigenvector Research, Inc. 2021
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%smr
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load data:
 
load arch
% Split into cal/val
echo off

val_indices = 1:6:size(arch, 1);
cal_indices = setdiff(1:size(arch, 1),val_indices);

echo on

x_cal  = arch(cal_indices, :);
x_val  = arch(val_indices, :);
% y_cal  = x_cal.class{1,1};  % only needed for supervised UMAP
% y_val  = x_val.class{1,1};  % only needed for supervised UMAP


disp(arch.description)
 
pause

%-------------------------------------------------
% We'll create a standard preprocessing structure to
% allow the UMAP function to do autoscaling for us.
%
 
myPrepro = preprocess('default','autoscale'); %structure array
 
pause
%-------------------------------------------------
% Create an UMAP model using the object oriented syntax
% for building evrimodels.  We will use 10 nearest neighbors
% and a two component model

model = evrimodel('umap');
model.options.preprocessing = {myPrepro};
model.options.n_neighbors = 10;
model.options.n_components = 2;
model.x = x_cal;
calibrated_model = model.calibrate;
pred = calibrated_model.apply(x_val);

pause
%-------------------------------------------------
% Examine the plot of the unsupervised UMAP Model
%

pred.plotscores,fh = gcf;
plotgui('update', 'figure', fh, 'axismenuvalues', {1 2});
legend('show', 'Location', 'Best');


%-------------------------------------------------
% For context we'll show the results for the corresponding PCA model
%

pause

newModel = evrimodel('pca');
newModel.x = x_cal;
newModel.ncomp = 2;
newModel.options.preprocessing = {myPrepro};
newModel = newModel.calibrate;
newPred = newModel.apply(x_val);
newPred.plotscores, fhNew = gcf;
plotgui('update', 'figure', fhNew, 'axismenuValues', {1 2});
legend('show', 'Location', 'Best');

%End of UMAP demo
echo off


