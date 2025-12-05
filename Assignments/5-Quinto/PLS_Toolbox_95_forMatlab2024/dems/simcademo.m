echo on
%SIMCADEMO Demo of the SIMCA function
 
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
% SIMCA is a classification technique based on PCA models.
% The idea is to construct PCA models for each class and then
% project new data onto the PCA models. Sample distances from
% each class are based on the Q and T^2 statistics. Samples close
% to a class (low Q and T^2) are considered belonging to (or in)
% that class. Large distances (high Q and T^2) suggest that a
% sample does not belong to that class. Therefore, in SIMCA it is
% possible for a sample to belong to one, none, or more than one class.
%
% Load data for the SIMCA demo:
load arch
whos
 
pause
%-------------------------------------------------
% Note that the arch data has a CLASS vector associated with
% Mode 1 (rows). This vector is used to identify which class
% each sample belong to. The plot shows that there are 4 classes
% (K, BL, SH and ANA) and a class "0" that corresponds to unknowns.
 
figure
plot(arch.class{1,1},'o-')
plot(1:10,arch.class{1,1}(1:10),'ob','markerfacecolor',[0 0 1]), hold on
plot(11:19,arch.class{1,1}(11:19),'sr','markerfacecolor',[1 0 0])
plot(20:42,arch.class{1,1}(20:42),'dg','markerfacecolor',[0 0.5 0])
plot(43:63,arch.class{1,1}(43:63),'^k','markerfacecolor',[0.1 0.1 0.1])
plot(64:75,arch.class{1,1}(64:75),'vm','markerfacecolor',[0.8 0 0.8]), hold off
text([2 12 21 44 65],[1.2 2.2 3.2 4.2 0.2],char('K','BL','SH','ANA','Unknowns'))
vline([10.5 19.5 42.5 63.5])
 
pause
%--------------------------------------------------
% First, we'll split the data into reference samples (1-63) and unknown
% "test" samples (64-75). 
 
ref = arch(1:63,:);
test = arch(64:75,:);

% Samples with class = 0 are of 'unknown' class. These will be the test set
ical  = find(arch.class{1}>0);  % this is 1:63, the indices of cal samples
itest = find(arch.class{1}==0); % this is 64:75, the indices of test samples
 
pause

%--------------------------------------------------
% SIMCA will be called so that no user interaction is required.
% Plotting and display are turned off using the OPTIONS structure
% and the preprocessing is set to AUTOSCALE using the PREPROCESS
% function (note that the proprocessing field is a 1 element cell).
 
options = simca('options');
options.display = 'off';
options.plots   = 'final';
options.preprocessing = {preprocess('default','autoscale')};
 
pause
%-------------------------------------------------
% The SIMCA function can now be called. The second input tells how
% many components to use for each model. If it is [] empty, then
% SIMCA will prompt the user to input the number of factors to use
% in each model.
 
model = simca(ref, 2, options);

pause

%-------------------------------------------------
% Now we'll test the 12 samples in the test dataset to
% see which groups they belong to. The default options.display
% is left = 'on' so that we can see the results.
 
prediction = simca(test,model);
 
% The reduced Q and T^2 (Q and T^2 divided by the class's approximatge
% 95% limit) are in the fields .rq and .rtsq respectively. The class
% predictions (closest to) are in .nclass.
 
pause
%-------------------------------------------------

% Note that not many of the unknowns belong to any class.
% This is due to the differences between the unknowns and
% the calibration data.
 
% These differences could be due to the fact that the unknowns
% are ancient samples that have been subjected to a number of
% events that could alter their chemistry (e.g. placed in a fire
% and exposure to weathering), and the calibration samples were
% freshly dug out of the quarry.
pause
%-------------------------------------------------
 
% prediction.classification.probability is an nsample x nclasses array 
% giving the predicted probability for each sample to belong to each class. 
% Its columns are in order prediction.classification.classnums/classids.
 
figure;
plot(itest, prediction.classification.probability, '.', 'MarkerSize',20);
legend(model.classification.classids, 'Location', 'NorthEast')
title('Class Probabilities for Samples')
ylabel('Probability')
xlabel('Sample Number')
 
pause
%-------------------------------------------------
 
% If two classes are similar then a sample may be assigned to both classes.
% Looking at the probability values, however, we can pick the most likely
% class for each sample. This is saved as model.classification.mostprobable.
% (Here we'll look at it for the CALIBRATION data, but the same thing can
% be done on PREDICTION data)
% See this wiki page for a full description of the classification results:
% http://wiki.eigenvector.com/index.php?title=Standard_Model_Structure#model
%
 
figure
predClass = model.classification.mostprobable;
ypred = dataset(predClass(1:63));
ypred.class{1} = arch.class{1}(1:63);   %add class info (for plotting only)
ypred.label{2} = {'Predicted Class (most probable)'};   %add a label
plotgui(ypred,'viewclasses',1)

 
pause
%-------------------------------------------------
% The user is encouraged to run SIMCA interactively using the
% following calls:

% >> load arch;
% >> ref = arch(1:63,:);
% >> test = arch(64:75,:);
% >> model = simca(ref);
 
% it is recommended that the scaling be set to "auto" 'A'
% and that 2, 1, 1, and 2 PCs be used for each class respectively.
 
% The use the following commands to make predictions on the test set.
 
% >> test = delsamps(arch,1:63,1,2);
% >> pred = simca(test,model);
  
% End of SIMCA Demo
echo off
