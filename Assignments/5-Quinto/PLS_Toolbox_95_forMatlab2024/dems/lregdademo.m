echo on
%LREGDADEMO Demo of the LREGDA function
 
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
%LREGDA (Logistic Regression Discriminate Analysis) generates a logistic
% regression model which can be used to classify samples as belonging to two 
% or more classes. Building an LREGDA model requires samples from at least 
% two classes

datacase = 'arch';  %'iris'; %'arch';
disp(sprintf('testlogreg using %s dataset', datacase))
switch datacase
  case 'arch'
    load arch
    x = arch;
    y = dataset(x.class{1}');
    ical  = find(x.class{1}>0);
    itest = find(x.class{1}==0);
  case 'iris'
    
    load iris
    x = iris;
    y = dataset(x.class{1}');
    m = size(x,1);
    itest = 1:10:m;
    ical = setdiff(1:m, itest);
  otherwise
    disp(sprintf('Unknown datacase (%s)', datacase))
end

xcal = x(ical,:);
ycal = y(ical,:);
xtest = x(itest,:);
ytest = y(itest,:);

pause
%---------------------------------- 
% LREGDA will be demonstrated on the archeological dataset "arch"...
% The arch data consists of x-ray fluorescence measurements of ten
% elements. The samples are from four different quarries assigned to four
% different classes, plus a set of "unknowns". 
 
% Here is a plot of the intensity observed for one of the measured elements
% (Iron, Fe) for all the samples. Each quarry is assigned a different
% symbol. The unknown samples are given black circles.
 
figure
plotgui(xcal,'viewclasses',1)
 
pause
%----------------------------------
% The LREGDA function is called with the x and y data, plus any options, 
% to build the model. An LREGDA model is built from the calibration samples. 
% We use autoscaling on the x-block and mean-centering on the y-block. 
% We'll also turn off plotting.
 
opts               = lregda('options');
opts.preprocessing = {preprocess('default','autoscale') preprocess('default','meancenter')};
% opts.preprocessing = {preprocess('default','mean center') preprocess('default','meancenter')};
opts.plots         = 'none';
opts.algorithm     = 'ridge';   %'elastic net'; %'lasso'; %'ridge'; %'none';
 
model = lregda(xcal, ycal, opts);  % x and y datasets
% model = lregda(xcal, opts);  % x datasets with classset
% model = lregda(xcal.data, ycal.data, opts);  % x and y datasets

 
pause
%---------------------------------- 
% There is one predicted y-value for each class for each sample (i.e. in
% this case, we had four classes so there are four predicted y-values for
% each class) Here are the values for all samples for class 1 predicted-y
% using the same class symbols as before.
 
ypred = dataset(model.pred{2}(:,1));        %get the predicted values (in a dataset)
ypred.class{1} = ycal.data;                 %add class info (for plotting only)
ypred.label{2} = {'Estimated Y Class 1'};   %add a label
plotgui(ypred,'viewclasses',1)
 
pause 
%----------------------------------
% model.classification.probability has one column for each class in the
% original calibration set. Plotting this for class 1, we see that all the
% true class 1 samples (red triangles) have high probability of being
% class 1. Likewise, so do two of the unknown (black circle) samples.
 
ypred = dataset(model.classification.probability(:,1));
ypred.class{1} = ycal.data;            %add true class info (for plotting only)
ypred.label{2} = {'Probability of Class 1'};   %add a label
plotgui(ypred,'viewclasses',1)

% 
predClass = model.classification.classnums(model.classification.mostprobable)';
ypred = dataset(predClass);   % dataset(predClass(ical));
ypred.class{1} = ycal.data;   % add class info (for plotting only)
ypred.label{2} = {'Predicted Class (most probable)'};   %add a label
plotgui(ypred,'viewclasses',1)

pause
%----------------------------------
% Apply cross-validation (CV) to add CV details to the model

model = model.crossvalidate(xcal, {'vet' 6 1}, 10);
% model = model.crossvalidate(xcal.data, {'vet' 6 1}, 10); % if model built using xcal.data

pause
%----------------------------------
% Apply to new test data
%
pred = model.apply(xtest);

pause
%----------------------------------
% Looking at ONLY the unknowns and all probabilities, we can begin to
% assign the unknowns to the four classes. 

pause
echo off
disp(' '); disp(['    Sample     P(1)      P(2)      P(3)      P(4)  ']);
disp([itest' pred.classification.probability ]);
echo on
 
% It appears that samples 65, 66 and 67 are class 1, samples 68, 69 and 70
% are class 2, samples 64, and 71-75 are class 3

pause
predClass = pred.classification.classnums(pred.classification.mostprobable)';
ypred = dataset(predClass); %dataset(predClass(ical));
% ypred.class{1} = ytest.data(:,1);               %add class info (for plotting only)
ypred.label{2} = {'Predicted Class (most probable)'};   %add a label
plotgui(ypred,'viewclasses',1)

% As also shown by plotting the most probable class for the test samples
pause
%----------------------------------
% View the classification results on the calibration data show that this is
% a fairly easily classified example:

confusiontable(model)

% and the cross-validation results:

confusiontable(model, true)
 
%End of LREGDA demo
echo off
 
