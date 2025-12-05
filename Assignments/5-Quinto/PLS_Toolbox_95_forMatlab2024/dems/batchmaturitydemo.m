echo on
%BATCHMATURITYDEMO Demo of the BATCHMATURITY function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% BATCHMATURITY determines limits on normal ranges of processing variables,
% viewed as PC scores, over the finite length (number of steps) of a batch
% process. When applied to new batch data it flags samples where scores fall
% outside the expected score range.
%
% We will use a batch process dataset which contains 36 batches, with 100
% samples per batch. Each batch is further sub-divided into 8 "steps".
 
% Load a batch dataset
load Dupont_BSPC;
 
pause
%---------------------------------------------------
 
dupont_cal
 
pause
%---------------------------------------------------
% The dataset consists of 3600 samples of 10 process variables. The sample
% number and step number of a sample are given by class sets 'BSPC Batch' 
% and 'BSPC Step'.
% The traces of each process variable through the first batch are shown 
% above, with the trace for the first variable shown in red:
 
tmp = dupont_cal(1:100, :);
figure;
plot(tmp.data, 'b')
xlabel('Sample Number');
title('Process Variables, First Batch. Variable 1 (red)')
hold on
plot(tmp.data(:,1), 'r')
 
pause
%---------------------------------------------------
% The first process variable will be used to represent the "batch maturity", y.
 
x = dupont_cal;
y = x(:,1);       
 
pause
%---------------------------------------------------
% Next, we'll set the meta parameters and options for the batchmaturity
% function. The opts.cl specifies the 2-sided confidence limit (= 1 -
% expected fraction of outliers). The ncomp variables define the number of
% components to use in PLS and PCA (both use 2 components here). Upper and
% lower limits for each PC score are calculated for batchmaturity using
% the number of equally spaced points specified in opts.bmlookuppts. The
% limit values vary for different stages of batch maturity. 
 
nvar                  = size(x,2);
ncomp_pca             = 2; 
ncomp_reg             = [];
opts                  = batchmaturity('options');
pre                   = preprocess('default','mean center');
opts.preprocessing{1} = pre;   %x-block
opts.preprocessing{2} = pre;   %y-block
opts.cl               = 0.95; % confidence limit
opts.nearestpts       = 101;
opts.smoothing        = 0.05;
opts.bmlookuppts      = 1001;
opts.plots            = 'detailed'; % Show plots of the scores and limits
 
 
pause
%---------------------------------------------------
% batchmaturity is run to calculate the upper and lower limits on scores 
% for normal conditions. The results are contained in the returned 'model'.
% model.limits contains low and high limits for each batch maturity value
% These are shown in plots created by the batchmaturity function if
% option.plots = 'final' ('none' is the default). 
 
%choose a subset of steps and batches to analyze from this data...
usesteps    = 2;
usecalbatches  = 1:36;
ibatch = x.class{1,1};
istep  = x.class{1,2};
iis = ismember(istep, usesteps);
iib = ismember(ibatch, usecalbatches);
x   = x(iis & iib, :);
y   = y(iis & iib, :);
 
nbatch = length(usecalbatches);
 
% Run the calculation to build the model. 
% If options.plots = 'detailed' this shows plots of the PCA scores against 
% batchmaturity, and the upper and lower limit lines for the specified
% confidence limit. 95% of the points should be between the lines if
% option.cl = 0.95.
%
model = batchmaturity(x,y,ncomp_pca,ncomp_reg,opts);  % if y is available.
% Use the following version instead if y is not available. In this case 
% y is generated, ranging from 0 to 100 in each batch).
% model = batchmaturity(x,ncomp_pca,opts);            
 
pause
%---------------------------------------------------
% This 'model' is next applied to a new batch dataset which was gathered
% from the same process. The PCA scores for a sample from the test dataset 
% should fall within the calculated limits for that sample to represent
% normal processing.
 
xtest = dupont_test;
usetestbatches = [50:55]; 
ibatch = xtest.class{1,1};
istep = xtest.class{1,2};
iis = ismember(istep, usesteps);
iib = ismember(ibatch, usetestbatches);
xtest = xtest(iis & iib, :);
 
pause
%---------------------------------------------------
% 
% Next, the model is applied to a test dataset and produces a pred 
% structure which contains:
% pred.inlimits        : Is sampple within limits (nsample x ncomp)
% pred.scores          : Scores (nsample x ncomp)
% pred.scores_reduced  : Reduced scores (nsample x ncomp)
% pred.limits.cl       : The confidence level fraction
%
% The scores are again plotted against batchmaturity, and the model's upper 
% and lower score limit lines are shown. Samples which are outlier are 
% colored green. The reduced scores are also plotted, with outliers colored 
% red.
%
 
pred = batchmaturity(xtest, model);
 
pause
%---------------------------------------------------
% Finally we add a classset to xtest called 'Outliers' where we require 
% that the sample score must be within limits for each PC for the class 
% value to be true. This is fairly strict requirement. The plot shows the 
% samples' scores versus sample index. Samples which are within limits for 
% all PCs, "Inliers", are colored black, "Outliers" are red.
%
xtest.classname{1,3} = 'Outliers';
xtest.class{1,3} = double(~all(pred.inlimits,2));  % Inliers require all scores are within limits
plotgui('new', xtest, 'viewclassset', 3, 'viewclasses', 1);
title(sprintf('Dataset Dupont_BSPC, Confidence Limit = %2.2g', model.limits.cl))
legend('inlier', 'outlier') 
echo off
