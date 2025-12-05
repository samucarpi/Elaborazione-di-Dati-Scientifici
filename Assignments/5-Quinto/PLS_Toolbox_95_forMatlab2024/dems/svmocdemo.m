% echo on
% %SVMOCDEMO Demo of the SVMOC function
%  
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

echo on
 
%To run the demo hit a "return" after each pause
pause 
%-------------------------------------------------
% Load data. 
% A 2-D dataset is used because it is easier to view than higher
% dimensional data.
% xcal has dim (400,2), xtest has dim (400, 2)
  
load svmocdemo;  % synthetic 2-D dataset
 
% pause
%-------------------------------------------------
% One-class SVM assumes all the calibration data belong to the one class
% View the data

figure;scatter(xcal(:,1), xcal(:,2), 2^4, 'k', 'o', 'filled');
xlabel('x1');ylabel('x2');
axis([0 40 0 40]);
title('Calibration data');
cmap = jet; colormap(cmap(6:end-10,:));
 
pause
%-------------------------------------------------
% For this example we turn off the SVMOC plots, but leave the display on.
 
opts               = svmoc('options');
opts.plots         = 'none';

% We specify an outlier fraction for the training dataset based on our 
% prior familiarity with the dataset. Set the outlier fraction to be 5%.
% We chose to use the SVM Radial Basis Kernel function and search over the
% default range for the best gamma value to use. 
% We could alternatively specify a single value of gamma to use here as:
% opts.gamma = [0.1];

opts.nu            = 0.05;
opts.kerneltype    = 'rbf'; % rbf is default, or 'linear'
 
pause
%-------------------------------------------------
% We'll create a standard preprocessing structure to
% allow the PCA function to do autoscaling for us.
%

opts.preprocessing = {preprocess('default','autoscale') []};
 
pause
%-------------------------------------------------
% Call the SVMOC function and create the model.
% (model) is a structure array that contains all
% the model parameters.
%

model = svmoc(xcal, opts);
 
%
% The model has been constructed.
%
% Type >>model to see how the model structure is organized.
%
 
pause
%-------------------------------------------------

% Plot calibration data (blue) and outliers (red)
opts.title = 'One-class SVM decisions';
opts.minmaxx = [0 40];
opts.minmaxy = [0 40];

figure; scatter(xcal(:,1), xcal(:,2), 2^4, 'b', 'o', 'filled'); hold on
% Get the support vectors 
if isfieldcheck(model,'.detail.svm.svindices') & ~isempty(model.detail.svm.svindices)
  svindices = model.detail.svm.svindices;
  scatter(xcal(svindices, 1), xcal(svindices, 2), 2^4, 'r', 'o', 'filled')
else
  disp('No optimal SVM was found. Try running again or change the parameter ranges')
end
xlabel('x1');ylabel('x2')

axis([opts.minmaxx opts.minmaxy])
param = model.detail.svm.model.param;
legend( 'inlier', 'SV', 'Location', 'SouthWest');

title(sprintf('%s: Nu = %5.4g, Gamma = %5.4g, #SV = %d', opts.title, ...
  param.nu, param.gamma, model.detail.svm.model.l));

cmap = jet; colormap(cmap(6:end-10,:));

pause
%-------------------------------------------------
% Next, use the model to identify outliers in a new test dataset by calling 
% SVMOC and passing the model as a parameter
% 

pause
%-------------------------------------------------

newoptions.b = 0; % no class probabilities
newoptions.q = 0; % quiet mode (no outputs, default 1)

% Make predictions for test dataset, xtest
prediction = svmoc(xtest, model, newoptions);

% The prediction structure is similar to the model and contains the
% predictions in its 'pred' field
 
% Now plot the predictions for test dataset, xtest, showing outliers in red
 
pause
%-------------------------------------------------
opts.title = 'One-class SVM predictions';
pred = prediction.pred{2};  
outliers = pred < 0;  % outliers are pred < 0

figure;
scatter(xtest(~outliers,1), xtest(~outliers,2), 2^4, 'b', 'o', 'filled')
hold on
scatter(xtest(outliers,1), xtest(outliers,2), 2^4, 'r', 'o', 'filled')
xlabel('x1');ylabel('x2')
axis([opts.minmaxx opts.minmaxy])

param = prediction.detail.svm.model.param;
legend('inlier', 'outlier','Location', 'SouthWest')
title(sprintf('%s: Nu = %5.4g, Gamma = %5.4g, #SV = %d', opts.title, param.nu, ...
  param.gamma, prediction.detail.svm.model.l));

pause
%-------------------------------------------------

% Finally, note that the results may vary slightly from run to run of this
% demo. This is related to the randomisation involved in sample assignments
% to groups during cross-validation when optimizing the gamma parameter
% value.

%End of SVMOCDEMO
 
echo off
