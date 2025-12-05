echo on
%XGBDADEMO Demo of the XGBDA function
 
echo off
%Copyright Eigenvector Research, Inc. 2004 Licensee shall not recompile,
%translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
%XGBDA (XGB Discriminate Analysis) generates a XGB model which can be used
%to classify samples as belonging to one of at least two classes. Building
%an XGBDA model requires samples from at least two classes. XGBDA uses a
%sequence of decision trees (boosted trees) to predict which class a sample
%belongs to.
 
pause
%---------------------------------- 
% Here the use of xgbda will be demonstrated on the archeological dataset
% "arch"...

load arch
 
%----------------------------------
% The arch data consists of x-ray fluorescence measurements of ten
% elements. The samples are from four different quarries assigned to four
% different classes, plus a set of "unknowns". 
 
% Here is a plot of the intensity observed for one of the measured elements
% (Iron, Fe) for all the samples. Each quarry is assigned a different
% symbol. The unknown samples are given black circles.
pause
 
figure
plotgui(arch,'viewclasses',1)
 
pause
%----------------------------------
% To perform XGB-DA, we must provide a y-variable which identifies the
% classes of the samples. This has already been created in the dataset as
% arch.class{1}. In order to define our y-variable, some consideration of
% the goals of the model is required. One model could attempt to
% discriminate between all four classes. Alternatively, we could create
% separate models each of which would discriminate between one class and
% the other three. Depending on the data, either method may perform better.
%
% This demo will attempt to create a single model to discriminate between
% all four classes. This requires that we simply pass the XGBDA function
% the class assignments of each sample. These are stored in the arch.class
% dataset field.
 
pause
%----------------------------------
% The xgb function is called with the x and y data, plus any options, to build the model. 
% In this case, an xgb model is built from the calibration samples. 
% Here we build a model using mean center preprocessing on the x-block, 
% using default XGBDA options. These include ranges of the max tree depth 
% (max_depth), learning rate (eta) and number of trees to use (num_round),
% to search over for the best combination of parameters to use
pause
 
opts               = xgbda('options');
opts.preprocessing = {preprocess('default','mean center') []};
opts.plots         = 'none';
opts.max_depth     = 1:4;
opts.eta           = [0.1 0.3 0.5];
opts.num_round     = [100 300 500];

opts.cvi           = {'vet' 5};
  
% Split arch dataset into calibration and test sets
ical  = 1:63;  % All 4 classes
itst = setdiff(1:75, ical);

xcal = arch(ical,:);
xtst = arch(itst,:);

model = xgbda(xcal, opts);

% ---------------------------------
% The optimal parameters for the xgbda model has been found based on 
% cross-validation (CV) and the model built using these optimal parameters.
% This model will now be used to predict the class for all samples in the
% arch dataset
%
% Type "model" to examine the model struct. For example,
% model.detail.xgb.cvscan.best is a struct containing the optimal xgb parameters.
% 
% Type "modelstruct help" to get more general information about model struct fields.

pause
%-------------------------------------------------
% Show plot of the CV results over the first two parameter ranges
pause

xgbcvplot(model);
 
% Next, apply the XGB model to test data and view prediction. 
pause

prediction = xgbda(xtst, model);

%-------------------------------------------------
% And view predictions. Here we plot the predicted probability for each 
% sample to belong to each class. 
% The model variable prediction.classification.probability  is an 
% nsample x nclasses array 
% Its columns are in order prediction.classification.classnums/classids.
pause

figure;
plot(itst, prediction.classification.probability, '.', 'MarkerSize',20);
legend(model.classification.classids, 'Location', 'SouthEast')
title('Class Probabilities for Samples')

%-------------------------------------------------
% It appears that samples 65, 66 and 67 are class 'K', samples 68 and 69  
% are class 'BL', sample 64, 70-75 are class 'SH'.
% Note that sample 64 has a small gap between the highest probability and
% the next higher probability indicating that we might be less confident
% about the class prediction for this sample. In fact samples 64, 66 and 67
% do not have a large probability of belonging to any class.
pause

%-------------------------------------------------
% Looking at the probability values, however, we can pick the most likely
% class for each sample. This is saved as model.classification.mostprobable.
% See this wiki page for a full description of the classification results:
% wiki.eigenvector.com/index.php?title=Standard_Model_Structure#model
pause

predClass = model.classification.mostprobable;
ypred = nan(size(arch,1),1);
ypred(ical) = predClass;
ypred = dataset(ypred);
ypred.classid{1} = arch.classid{1};   %add class info (for plotting only)
ypred.label{2} = {'Predicted Class (most probable)'};   %add a label
plotgui(ypred,'viewclasses',1,'new')


%End of XGBDA demo
echo off
