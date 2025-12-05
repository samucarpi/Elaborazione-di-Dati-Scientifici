echo on
%SVMDADEMO Demo of the SVMDA function
 
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
%SVMDA (SVM Discriminate Analysis) generates a SVM model which can be used
%to classify samples as belonging to one of at least two classes. Building
%a SVMDA model requires samples from at least two classes. SVMDA attempts
%to identify characteristic latent variables which can be used to segregate
%the samples into a single given class. 
 
pause
%---------------------------------- 
% Here the use of svmda will be demonstrated on the archeological dataset
% "arch"...

load arch
 
% The arch data consists of x-ray fluorescence measurements of ten
% elements. The samples are from four different quarries assigned to four
% different classes, plus a set of "unknowns". 
 
% Here is a plot of the intensity observed for one of the measured elements
% (Iron, Fe) for all the samples. Each quarry is assigned a different
% symbol. The unknown samples are given black circles.
 
figure
plotgui(arch,'viewclasses',1)
 
pause
%----------------------------------
% To perform SVM-DA, we must provide a y-variable which identifies the
% classes of the samples. This has already been created in the dataset as
% arch.class{1}. In order to define our y-variable, some consideration of
% the goals of the model is required. One model could attempt to
% discriminate between all four classes. Alternatively, we could create
% separate models each of which would discriminate between one class and
% the other three. Depending on the data, either method may perform better.
%
% This demo will attempt to create a single model to discriminate between
% all four classes. This requires that we simply pass the SVMDA function
% the class assignments of each sample. These are stored in the arch.class
% dataset field.
 
pause
%----------------------------------
% The svm function is called with the x and y data, plus any options, to build the model. 
% In this case, an svm model is built from the calibration samples. Here we build a
% simple model using autoscaling on the x-block, using default C-SVC
% classification and radial basis function, with a search for optimal
% parameter values for cost and gamma.
% We'll also turn off plotting.
 
opts               = svmda('options');
opts.preprocessing = {preprocess('default','autoscale') []};
opts.plots         = 'none';

% to use 'linear' svm kernel instead of the default Gaussian radial basis function
% opts.kerneltype = 'linear';

% opts.display       = 'off';

% to perform nu-classification instead of the default c-classification:
% opts.svmtype = 'nu-svc';
  
% Samples with class = 0 have unknown class
ical  = find(arch.class{1}>0);
itest = find(arch.class{1}==0);

model = svmda(arch(ical,:), opts);

% ---------------------------------
% The optimal parameters for the svmda model has been found based on cross-validation
% and the model built using these optimal parameters. This model
% will now be used to predict the class for all samples in the arch dataset
%
% Type "model" to examine the model struct. For example,
% model.detail.svm.cvscan.best is a struct containing the optimal SVM parameters.
% 
% Type "modelstruct help" to get more general information about model struct fields.

pause
%-------------------------------------------------
% svmda used CV on the calibration data to find the optimal SVM parameters
% Show plot of the CV results over the first two parameter ranges
svmcvplot(model); 
 
pause
% SVM prediction. 
prediction = svmda(arch(itest,:), model);

pause

% prediction.classification.probability  is an nsample x nclasses array 
% giving the predicted probability for each sample to belong to each class. 
% Its columns are in order prediction.classification.classnums/classids.
figure;
plot(itest, prediction.classification.probability, '.', 'MarkerSize',20);
legend(model.classification.classids, 'Location', 'SouthWest')
title('Class Probabilities for Samples')

% It appears that samples 65, 66 and 67 are class 'K', samples 68, 69 and 
% 70 are class 'BL', sample 64, 71-75 are class 'SH'.
% Note that sample 67 has a smaller gaps between the highest probability 
% and the next higher probability indicating that we might be less 
% confident about the class prediction for this sample.

pause

% If two classes are similar then a sample may be assigned to both classes.
% Looking at the probability values, however, we can pick the most likely
% class for each sample. This is saved as model.classification.mostprobable.
% See this wiki page for a full description of the classification results:
% wiki.eigenvector.com/index.php?title=Standard_Model_Structure#model

predClass = model.classification.mostprobable;
ypred = dataset(predClass(1:63));
ypred.class{1} = arch.class{1}(1:63);   %add class info (for plotting only)
ypred.label{2} = {'Predicted Class (most probable)'};   %add a label
plotgui(ypred,'viewclasses',1)

%End of SVMDA demo
echo off
 
