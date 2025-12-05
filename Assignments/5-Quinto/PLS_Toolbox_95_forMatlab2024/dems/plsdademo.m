echo on
%PLSDADEMO Demo of the PLSDA function
 
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
%PLSDA (PLS Discriminate Analysis) generates a PLS model which can be used
%to classify samples as belonging to one of at least two classes. Building
%a PLSDA model requires samples from at least two classes. PLSDA attempts
%to identify characteristic latent variables which can be used to segregate
%the samples into a single given class. For a comparison of PLSDA to Linear
%Discriminate Analysis - LDA - see: 
%   M. Barker and W. Rayens, J. Chemometrics 2003; 17: 166-173.
 
pause
%---------------------------------- 
% Here the use of plsda will be demonstrated on the archeological dataset
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
% To perform PLS-DA, we must provide a y-variable which identifies the
% classes of the samples. This has already been created in the dataset as
% arch.class{1}. In order to define our y-variable, some consideration of
% the goals of the model is required. One model could attempt to
% discriminate between all four classes. Alternatively, we could create
% separate models each of which would discriminate between one class and
% the other three. Depending on the data, either method may perform better.
%
% This demo will attempt to create a single model to discriminate between
% all four classes. This requires that we simply pass the PLSDA function
% the class assignments of each sample. These are stored in the arch.class
% dataset field.
 
y = arch.class{1};

% Samples with class = 0 have unknown class
ical  = find(arch.class{1}>0);
itest = find(arch.class{1}==0);
 
pause
%----------------------------------
% The PLSDA function is called with the x and y data, the number of
% components to use, plus any options, to build the model. In this case, To
% build a PLSA model is built from the calibration samples. Here we build a
% simple 4-component model using autoscaling on the x-block and
% mean-centering on the y-block. We'll also turn off plotting.
 
opts               = plsda('options');
opts.preprocessing = {preprocess('default','autoscale') preprocess('default','meancenter')};
opts.plots         = 'none';
 
model = plsda(arch,y,3,opts);
 
pause
%---------------------------------- 
% The "predicted y-values" of the PLSDA model are actually values around and
% between zero and one and are stored in the ".pred" field of the model.
% There is one predicted y-value for each class for each sample (i.e. in
% this case, we had four classes so there are four predicted y-values for
% each class) Here are the values for all samples for class 1 predicted-y
% using the same class symbols as before.
 
ypred = dataset(model.pred{2}(:,1));        %get the predicted values (in a dataset)
ypred.class{1} = y;                         %add class info (for plotting only)
ypred.label{2} = {'Estimated Y Class 1'};   %add a label
plotgui(ypred,'viewclasses',1)

pause
%---------------------------------- 
% Ideally, each sample which is a member of the class would predict as a
% value of 1 (one) and each sample not a member would predict as 0 (zero)
% and the discrimination between the two would be simple. As this is often
% not the case, a threshold of "predicted y" must be determined above which a
% sample is considered to be a member of the class. The PLSDA function
% calculates these thresholds for each of the classes and stores them in
% the detail.threshold field of the model:
 
model.detail.threshold
 
%in particular, we want the threshold for class 1
 
threshold = model.detail.threshold(1);
 
pause
%-------------------------------------------------
% and we can add that threshold to our plot. Any predicted value above that
% line is considered a member of the class.
 
hline(threshold,'r--');
 
pause
%----------------------------------
% The threshold is calculated using the observered distribution of
% predicted values and Bayesian statistics. These statisics can also tell
% us what the probability is of observing a specific predicted y value if
% we have a sample which is (or is not) a member of the class. 
% The predicted probability that each sample belongs to each class is
% calculated by PLSDA and stored in the model.classification.probability 
% field. (For more information on the PLSDA prediction probabilities see
% PLSDTHRES)
 
pause 
%----------------------------------
% model.classification.probability has one column for each class in the
% original calibration set. Plotting this for class 1, we see that all the
% true class 1 samples (red triangles) have high probability of being
% class 1. Likewise, so do three of the unknown (black circle) samples.
 
ypred = dataset(model.classification.probability(:,1));
ypred.class{1} = y;            %add true class info (for plotting only)
ypred.label{2} = {'Probability of Class 1'};   %add a label
plotgui(ypred,'viewclasses',1)
 
pause
%----------------------------------
% Looking at ONLY the unknowns and all probabilities, we can begin to
% assign the unknowns to the four classes. Also shown are the reduced
% residuals (Q) and Hotellings T^2. The larger these values, the less
% certain the class assignment.
echo off 
disp(' '); disp(['    Sample     P(1)      P(2)      P(3)      P(4)     Q(red)   T^2(red)']);
disp([itest' model.classification.probability(itest,:) model.ssqresiduals{1}(itest)./model.detail.reslim{1} model.tsqs{1}(itest)./model.detail.tsqlim{1}]);
echo on 

% It appears that samples 65, 66 and 67 are class 1, samples 68 and 69 are
% class 2, sample 70 is either class 2 or class 3, sample 71-74 are class
% 3, and sample 75 is a tentative class 3 (note high Q residuals bringing
% the prediction into question).
 
pause
%----------------------------------
% If two classes are similar then a sample may be assigned to both classes.
% Looking at the probability values, however, we can pick the most likely
% class for each sample. This is saved as model.classification.mostprobable.
% See this wiki page for a full description of the classification results:
% wiki.eigenvector.com/index.php?title=Standard_Model_Structure#model

predClass = model.classification.mostprobable;
ypred = dataset(predClass(ical));
ypred.class{1} = y(ical);               %add class info (for plotting only)
ypred.label{2} = {'Predicted Class (most probable)'};   %add a label
plotgui(ypred,'viewclasses',1)

%End of PLSDA demo
echo off
 
