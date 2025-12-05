echo on
%LDADEMO Demo of the LDA function
 
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
%LDA (Linear Discriminate Analysis) generates a linear discriminant
%analysis model which can be used to classify samples as belonging to two 
% or more classes. Building an LDA model requires samples from at least 
% two classes

datacase = 'arch';  %'iris'; %'arch';
disp(sprintf('Test LDA using %s dataset', datacase))
switch datacase
  case 'arch'
    load arch
    x = arch;
    ytst = dataset(x.class{1}');
    ical  = find(x.class{1}>0);
    itest = find(x.class{1}==0);
  case 'iris'
    
    load iris
    x = iris;
    ytst = dataset(x.class{1}');
    m = size(x,1);
    itest = 1:10:m;
    ical = setdiff(1:m, itest);
  otherwise
    disp(sprintf('Unknown datacase (%s)', datacase))
end

xcal = x(ical,:);
ycal = ytst(ical,:);
xtst = x(itest,:);
ytst = ytst(itest,:);

pause
%---------------------------------- 
% LDA will be demonstrated on the archeological dataset "arch"...
% The arch data consists of x-ray fluorescence measurements of ten
% elements. The samples are from four different quarries assigned to four
% different classes, plus a set of "unknowns". 
 
% Here is a plot of the intensity observed for one of the measured elements
% (Iron, Fe) for all the samples. Each quarry is assigned a different
% symbol. The unknown samples are given black circles.
 
figure
plotgui(x,'viewclasses',1)
 
pause
%----------------------------------
% The LDA function is called with the x and y data, plus any options, 
% to build the model. An LDA model is built from the calibration samples. 
% We use autoscaling on the x-block and mean-centering on the y-block. 
% We'll also turn off plotting.
 
opts               = lda('options');
opts.preprocessing = {preprocess('default','autoscale') preprocess('default','meancenter')};
opts.plots         = 'none';
% opts.algorithm     = 'ridge';   %'elastic net'; %'lasso'; %'ridge'; %'none';
 
% Build the LDA model
% model = lda(xcal, opts);                 % x datasets with classset
% model = lda(xcal, ycal, opts);           % x and y datasets
% model = lda(xcal.data, ycal.data, opts); % x and y datasets
model = evrimodel('lda');
model.x = xcal;
model.y = ycal;
model.ncomp = 3;
model.options = opts;
model = model.calibrate;

pause
%---------------------------------- 
% LDA calculates the probability of each sample belonging to each modeled
% class. The most-probable class for each sample is reported in the 
% model.pred{2} field. This is an index value into the class names, as
% recorded in model.classification.classids.
% There is one predicted y-value for each class for each sample (i.e. in
% this case, we had four classes so there are four predicted y-values for
% each class) Here are the values for all samples for class 1 predicted-y
% using the same class symbols as before.
 
% ypred = dataset(model.pred{2}(:,1));        %get the predicted values (in a dataset)
ypred = dataset(model.pred{2});        %get the predicted values (in a dataset)
% ypred.classid{1} = model.classification.classids(ycal.data); %add class info (for plotting only)
ypred.classid{1} = model.classification.classids(model.pred{2}); %add class info (for plotting only)
ypred.label{2} = {'Most Probable Class'};   %add a label
plotgui(ypred,'viewclasses',1)
legend(model.classification.classids, 'Location','NorthWest')
 
pause 
%----------------------------------
% model.classification.probability has one column for each class in the
% original calibration set. Plotting this for class 1, we see that all the
% true class 1 samples (red triangles) have high probability of being
% class 1. Likewise, so do two of the unknown (black circle) samples.
 
ypred = dataset(model.classification.probability(:,1));
% ypred.class{1} = ycal.data;            %add true class info (for plotting only)
ypred.classid{1} = model.classification.classids(ycal.data); %add class info (for plotting only)
ypred.label{2} = {'Probability of Class 1'};   %add a label
plotgui(ypred,'viewclasses',1)
legend(model.classification.classids, 'Location','NorthEast')

pause
%----------------------------------
% Apply cross-validation (CV) to add CV details to the model

model = model.crossvalidate(xcal, {'vet' 6 1}, 10);

% The CV classification results are in model.detail.cvclassification

pause
%----------------------------------
% Apply to new test data
%
pred = model.apply(xtst);

pause
%----------------------------------
% Looking at ONLY the unknowns and all probabilities, we can begin to
% assign the unknowns to the four classes. 

pause
echo off
disp(' '); disp(['    Sample     P(1)      P(2)      P(3)      P(4)  ']);
disp(cell2str(cellfun(@(x) ['    ' x], pred.classification.classids, 'UniformOutput', false)))
disp(['    Sample  ' cell2str(pred.classification.classids, '  ')])
disp([itest' pred.classification.probability ]);
echo on
 
% It appears that samples 64-67 are class 1, samples 68-70 are class 2, and
% samples 71-75 are class 3

mprob = pred.classification.mostprobable;
ypred = dataset(mprob); %get most probable values (as a dataset)
ypred.classid{1} = model.classification.classids(mprob); %add class info (for plotting only)
ypred.label{2} = {'Most Probable Class'};   %add a label
plotgui(ypred,'viewclasses',1)
legend(pred.classification.classids, 'Location','NorthWest')
% As also shown by plotting the most probable class for the test samples
pause
%----------------------------------
% View the classification results on the calibration data show that this is
% a fairly easily classified example:

confusiontable(model)

% and the cross-validation results:

confusiontable(model, true)
 
%End of LDA demo
echo off
 
