echo on
%KNNDEMO Demo of the KNN function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%--------------------------------------------------- 
% KNN performs a k nearest neighbors classification in which the class of
% an unknown is identified by looking for the "k" most similar samples in a
% reference set (with known class assignments) and allowing those samples
% to "vote" for the class assignment of the unknown. Typically, k is odd
% and small (e.g. k=3 is the default)
%
% The following shows how to run a simple KNN analysis. First, load data of
% interest. In this case, we'll use the "arch" dataset which consists of
% four quarries and a group of unknonwn samples.
 
load arch
whos
 
pause
%--------------------------------------------------
% First, we'll split the data into reference samples (1-63) and unknown
% "test" samples (64-75). 
 
ref = arch(1:63,:);
test = arch(64:75,:);
 
pause
%-------------------------------------------------
% Note that the reference samles already have class numbers assigned in the
% dataset field "class" for samples:
 
ref.class{1}
 
pause
%-------------------------------------------------
% Next, we get the default options for KNN, and we set the preprocessing to
% "autoscaling"
 
opts = knn('options');
opts.preprocessing = {'autoscale'};
opts.display = 'off';
 
pause
%-------------------------------------------------

% Samples with class = 0 are of 'unknown' class. These will be the test set
ical  = find(arch.class{1}>0);
itest = find(arch.class{1}==0);

pause
%-------------------------------------------------
% Build a model using the calibration data, using = 3 nearest neighbors
k = 3;
model = knn(ref, k, opts);

% Type "model" to examine the model struct. 
% Type "modelstruct help" to get general information about model struct fields.
 
pause
%-------------------------------------------------

% This model will now be used to predict the class for the unknown samples
% in the arch dataset
 
prediction = knn(test, model, opts);
 
pause
%-------------------------------------------------
 
% prediction.classification.probability is an nsample x nclasses array 
% giving the predicted probability for each sample to belong to each class. 
% Its columns are in order prediction.classification.classnums/classids.
 
figure;
plot(itest, prediction.classification.probability, '.', 'MarkerSize',20);
legend(model.classification.classids, 'Location', 'SouthWest')
title('Class Probabilities for Samples')
 
% It appears that samples 65, 66 and 67 are class 'K', samples 68, 69 and 
% 70 are class 'BL', sample 64, 71-75 are class 'SH'.
 
pause
%-------------------------------------------------
 
% If two classes are similar then a sample may be assigned to both classes.
% Looking at the probability values, however, we can pick the most likely
% class for each sample. This is saved as model.classification.mostprobable.
% See this wiki page for a full description of the classification results:
% wiki.eigenvector.com/index.php?title=Standard_Model_Structure#model
%
 
predClass = model.classification.mostprobable;
ypred = dataset(predClass(1:63));
ypred.class{1} = arch.class{1}(1:63);   %add class info (for plotting only)
ypred.label{2} = {'Predicted Class (most probable)'};   %add a label
plotgui(ypred,'viewclasses',1)
  
% End of KNN Demo
echo off
