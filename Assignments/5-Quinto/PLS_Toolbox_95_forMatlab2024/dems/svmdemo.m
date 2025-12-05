echo on
% SVMDEMO Demo of the SVM function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
clear ans
echo on
 
% To run the demo hit a "return" after each pause
% pause
%-------------------------------------------------
% Load data:
% The data consists of two predictor x-blocks and two
% predicted y-blocks. The data are in DataSet objects.
% xblock1 and yblock1 will be used for calibration and
% xblock2 and yblock2 will be used for validation.
 
load plsdata
whos
 
% pause
%-------------------------------------------------
% Remove some known outliers from xblock1 and examine its contents
 
xblock1 = delsamps(xblock1,[73 278 279]);

xblock1index = 1:size(xblock1,1);

% Note that the data is 300x20, but includ{1} is now length 297
% since 3 samples have been "soft deleted".
pause 
%-------------------------------------------------
% The SVM function will be used to construct the SVM model.
%
% To get the options for this function run
 
options = svm('options')
 
%-------------------------------------------------
% See "svm help" to get the valid settings for these options.
%
% Turn off "display" and "plots"
pause
options.display               = 'off'; %'off';
options.plots                 = 'none';
 
%-------------------------------------------------
% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the SVM function. Preprocessing
% can be performed explicitly at the command line, but this allows the
% SVM function to perform preprocessing automatically during calibration
% and application to new data. The standard preprocessing structure will
% become a part of the standard model structure output by SVM.
% Preprocessing can be applied to the x and/or y-block in SVM.
 
pre = preprocess('default','mean center');
options.preprocessing{1} = pre;   %x-block

pause
%-------------------------------------------------
% Perform epsilon regression (default):
options.svmtype = 'epsilon-svr';
 
options.kerneltype='rbf';
options.cost    = [0.1 0.3 1 3 10];          % or use default range
options.gamma   = [0.0000316 0.0001000 0.000316 0.001000 0.00316 0.01000];
options.epsilon = [0.003 0.01 0.03 .1]; 

%-------------------------------------------------
% Now call the SVM function to calibrate the model. 
% This will perform cross-validation to determine the best SVM parameters to use
pause 
model = svm(xblock1,yblock1,options);

%-------------------------------------------------
% CV was used, searching over a range of parameter values to find the optimal SVM parameters
% Show plot of the CV results over the first two parameter ranges
% 'X' marks the optimal parameters on the plot
% Any blank (white) areas appearing on the plot indicate parameter choices
% where the SVM model run time exceeded the limit options.cvtimelimit. If
% If the 'X' appears next to a parameter range boundary you might extend
% that parameter range (in options) in that direction.
% If the 'X' appears next to a blank/white are try increasing the value of
% options.cvtimelimit
  svmcvplot(model, {'cost', 'epsilon'} ); % over cost/epsilon 
  svmcvplot(model, {'cost', 'gamma'} ); % over cost/gamma
  svmcvplot(model, {'epsilon', 'gamma'} ); % over epsilon/gamma
  
pause
%-------------------------------------------------
% And plot the model of calibration data
figure
% plot(yblock1.data(:,1),'-b','linewidth',2), hold on
if ~isempty(model.pred{2})
plot(xblock1index, yblock1.data(:,1),'-','linewidth',2), hold on        % plot known Y
else
  disp('Prediction is not plotted because model.pred{2} is empty.');
end

plot(xblock1index, model.pred{2}(:,1),'--g','linewidth', 2)             % plot predicted Y

% Plot the support vectors as filled red circles 
if isfieldcheck(model,'.detail.svm.svindices') & ~isempty(model.detail.svm.svindices)
  svindices = model.detail.svm.svindices;
  plot(xblock1index(svindices),model.detail.data{2}.data(svindices),'o','markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1], 'markersize',5)
else
  disp('No optimal SVM was found. Try running again or change the parameter ranges')
end

legend('Actual','Predicted', 'SV', 'Location','NorthWest')
hold off
title('Calibration data. Actual versus predicted Y');
xlabel('Sample Number (time)')
ylabel('Actual and Predicted Y (inches)')
 
pause
% The optimal SVM parameters, the number of support vectors, and the number of samples used 
% to build the SVM model are:
disp( 'Optimal SVM parameters:'), disp(model.detail.svm.cvscan.best)
disp( 'Number of support vectors:'), disp(model.detail.svm.model.l)
disp( 'Number of calibration samples:'), disp(size(xblock1,1))

pause
%-------------------------------------------------
% Predictions for new data can be made by calling the SVM function
% with the model as an input. Note again that the preprocessing of
% the new data will be handled by the SVM function because it is now
% a part of the model.
 
% If the validation set did not have the known reference values (yblock2)
% and only had the x-block (xblock2) then the call to SVM would be
%
pause
pred  = svm(xblock2,model,options);

%-------------------------------------------------
% However, we have both xblock2 and yblock2 so we can call SVM to validate the model
 
pause
valid = svm(xblock2,yblock2,model,options);

% And plot the results
pause
xblock2index = 1:size(xblock2,1);
figure
plot(xblock2index, yblock2.data(:,1),'-b','linewidth',2), hold on   % plot known Y
if ~isempty(valid.pred{2})
plot(xblock2index, valid.pred{2},'--g','linewidth',2)               % predicted Y
  hold on
else
  disp('Prediction is not plotted because valid.pred{2} is empty.');
end
legend('Actual','Predicted','Location','NorthWest')
hold off
title('Test data. Actual versus predicted y');
xlabel('Sample Number (time)')
ylabel('Actual and Predicted Y (inches)')
 
disp( 'Optimal SVM parameters, used in building the model:'), disp(model.detail.svm.cvscan.best)
disp( 'Number of support vectors in model:'), disp(model.detail.svm.model.l)
disp( 'Number of calibration samples used in building model:'), disp(length(xblock1.include{1}))
%End of SVMDEMO
echo off
