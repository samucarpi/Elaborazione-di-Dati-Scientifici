echo on
% EVRISHAPLEYDEMO Demo of the EVRISHAPLEY function

echo off
%Copyright Eigenvector Research, Inc. 2023
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%smr

clear ans
echo on

% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load data:
% The data consists of a x-block (Tecator, as a dataset object) and a
% y-block (Conc, as a dataset object). We will perform a random split to
% create a cal/val set. We will set a random seed for this, while also
% storing the first column of the Conc block as the y (fat content), since
% this is what we would like to predict.

load tecator
whos

pause
%-------------------------------------------------
% The ANN function will be used to construct the ANN model.
%
% To get the options for this function run

options = ann('options')
options.algorithm = 'bpn'; %'encog', 'bpn

pause
%-------------------------------------------------
% See "ann help" to get the valid settings for these options.
%
% Turn off "display" and "plots"

options.display = 'off';
options.plots   = 'none';

pause
%-------------------------------------------------
% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the ANN function. Preprocessing
% can be performed explicitly at the command line, but this allows the
% ANN function to perform preprocessing automatically during calibration
% and application to new data. The standard preprocessing structure will
% become a part of the standard model structure output by ANN.

pre = preprocess('default','mean center');
options.preprocessing{1} = pre;   %x-block
options.preprocessing{2} = pre;   %y-block

% Note that a preprocessing structure is required for both the
% x-block and y-block.

pause
%-------------------------------------------------
% Now call the ANN function to build the model using the default back
% propagation network with one hidden layer and the specified number of nodes

model = evrimodel('ann');
model.x = Xcal;
model.y = Ycal(:,2);
% Specify 3 nodes in one hidden layer. 
% nhid2 = 0 by default. This is a neural network with only one hidden layer
nhid = 3;   % or [2 1] for 2 hidden layers, 2 nodes in first, 1 in second
model.nhid = nhid;
model.options = options;
model = model.calibrate;

pause
%-------------------------------------------------
% And plot the results, showing y known and y predicted for the validation data

figure
plot(Ycal(:,2).data(:,1),'-b','linewidth',2), hold on
plot(model.pred{2},'or','markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1]), hold off
title(sprintf('ANN(%s):   RMSEC = %4.4g', model.detail.ann.W.type, model.detail.rmsec(nhid)))
xlabel('Sample Number')
ylabel('Known and Estimated Y (Fat Content)')
legend('Known','Estimated','Location','northwest')

pause
%-------------------------------------------------
% Plot y known versus y predicted for the validation data

figure
plot(Ycal(:,2).data(:,1),model.pred{2}, 'b.')
xlabel('Measured Y')
ylabel('Predicted Y')
title(sprintf('ANN(%s)    RMSEC = %4.4g', options.algorithm, model.detail.rmsec(nhid)));
abline(1,0)

pause
%-------------------------------------------------
% Now we can get an idea how the ANN is predicting so well by using Shapley
% Values. The Shapley Values will tell us which variables are contributing
% to the prediction. You can use Shapley Values to explain each individual
% sample. This will result in a 144x100 matrix in this example. 
% Normally, Shapley Values return a MxNxP matrix  (M samples, N
% variables, P predictors/outputs). First we will show how to use the
% function and then plot the explanations on all samples.

shapleyoptions = evrishapley('options');
shapleyoptions.int_width = 1; % one can group variables together by setting a number other than 1
shapleyoptions.random_state = 1 % reproducibility

pause
%-------------------------------------------------
% We can get explanation on all of the samples by passing in the full
% calibration set to the function:

results = evrishapley(Xcal,model,shapleyoptions);

pause
%-------------------------------------------------
% The Shapley Values explain the difference between the model's average
% prediction and the sample's prediction through variable contributions.
% Let's look at sample 1 to illustrate the example.
%
% The average prediction in the model is
results.baseprediction
%
% Sample 1's prediction is
model.pred{2}(1)
%
% Check Shapley Values and prediction on sample 1
sum(results.shap(1,:)) + results.baseprediction
%
% Plot the Shapley Values for Sample 1
sample = 1; % use 1, 2, ..., 144
figure; bar(results.shap(sample,:));
title(['Shapley Values on Sample ' num2str(sample)]);
xlabel('Variables')
ylabel('Shapley Values');

pause
%-------------------------------------------------
% It is also useful to get a sense on how the model works overall across
% all samples. One can do this by aggregating the Shapley Values for each
% of the model's outputs. There are a number of ways one can do the
% aggregating, the most popular is to take the mean of the absolute value
% of the Shapley Value matrix. This tells you overall if the variables contributed
% significantly or not towards the prediction, regardless of direction.
% This results in a 1xN vector that one can compare to tools like a 
% regression vector, VIP, Selectivity Ratio, and others. Here is the 
% Model summary on the calibration dataset.

figure; plot(mean(abs(results.shap)));
title('Shapley Value Model Explanation for ANN Calibrated on Tecator')
xlabel('Variables')
ylabel('Mean(|Shapley Values|)')


% %End of EVRISHAPLEYDEMO
echo off
