echo on
%ANNDADEMO Demo of the ANNDA function
 
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
%ANNDA (ANN Discriminate Analysis) generates an ANN model which can be used
%to classify samples as belonging to one of at least two classes. Building
%a ANNDA model requires samples from at least two classes. ANNDA attempts
%to identify characteristic latent variables which can be used to segregate
%the samples into a single given class. 
 
pause
%---------------------------------- 
% Here the use of annda will be demonstrated on the archeological dataset
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
% To perform ANN-DA, we must provide a y-variable which identifies the
% classes of the samples. This has already been created in the dataset as
% arch.class{1}. In order to define our y-variable, some consideration of
% the goals of the model is required. One model could attempt to
% discriminate between all four classes. Alternatively, we could create
% separate models each of which would discriminate between one class and
% the other three. Depending on the data, either method may perform better.
%
% This demo will attempt to create a single model to discriminate between
% all four classes. This requires that we simply pass the ANNDA function
% the class assignments of each sample. These are stored in the arch.class
% dataset field.
 
y = arch.class{1};

ical  = find(arch.class{1}>0);
itest = find(arch.class{1}==0);
 
pause
%----------------------------------
% The ANNDA function is called with the x and y data, plus any options, 
% to build the model. An ANNDA model having a single hidden layer with 3 
% nodes is built from the calibration samples. 
% We use autoscaling on the x-block and mean-centering on the y-block. 
% We'll also turn off plotting.
 
opts               = annda('options');
opts.preprocessing = {preprocess('default','autoscale') preprocess('default','meancenter')};
opts.plots         = 'none';
opts.algorithm     = 'bpn';   % 'bpn' or 'encog'
nhid = 3;   % or [2 1] for 2 hidden layers, 2 nodes in first, 1 in second
opts.nhid1         = nhid;
opts.algorithm = 'bpn'; %'encog';
 
model = annda(arch, y, opts);
 
pause
%---------------------------------- 
% The "predicted y-values" of the ANNDA model are actually values around and
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
% sample is considered to be a member of the class. The ANNDA function
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
% calculated by ANNDA and stored in the model.classification.probability 
% field. (For more information on the ANNDA prediction probabilities see
% PLSDTHRES)
 
pause 
%----------------------------------
% model.classification.probability has one column for each class in the
% original calibration set. Plotting this for class 1, we see that all the
% true class 1 samples (red triangles) have high probability of being
% class 1. Likewise, so do two of the unknown (black circle) samples.
 
ypred = dataset(model.classification.probability(:,1));
ypred.class{1} = y;            %add true class info (for plotting only)
ypred.label{2} = {'Probability of Class 1'};   %add a label
plotgui(ypred,'viewclasses',1)
 
pause
%----------------------------------
% Looking at ONLY the unknowns and all probabilities, we can begin to
% assign the unknowns to the four classes. 
 
disp(' '); disp(['    Sample     P(1)      P(2)      P(3)      P(4)  ']);
disp([itest' model.classification.probability(itest,:) ]);
 
% It appears that samples 64, 65, 66 and 67 are class 1, samples 68, 69 and
% 70 are class 2, samples 71-75 are class 3
 
pause
%----------------------------------
% If two classes are similar then a sample may be assigned to both classes.
% Looking at the probability values, however, we can pick the most likely
% class for each sample. This is saved as model.classification.mostprobable.
% See this wiki page for a full description of the classification results:
% wiki.eigenvector.com/index.php?title=Standard_Model_Structure#model

predClass = model.classification.mostprobable;
ypred = dataset(predClass(ical)); %dataset(predClass(ical));
ypred.class{1} = y(ical);               %add class info (for plotting only)
ypred.label{2} = {'Predicted Class (most probable)'};   %add a label
plotgui(ypred,'viewclasses',1)

pause
%----------------------------------
% Apply cross-validation
%

model = model.crossvalidate(arch, {'vet' 6 1}, 10);

pause
%----------------------------------
% Apply to new test data
%

xt = arch(itest,:);
pred = model.apply(xt);

%End of ANNDA demo
echo off
 
