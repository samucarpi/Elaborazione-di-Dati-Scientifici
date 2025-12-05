echo on
% XGBDEMO Demo of the XGB function

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
% The XGB function will be used to construct the XGB model.
%
% To get the options for this function run

options = xgb('options')

%-------------------------------------------------
% See "xgb help" to get the valid settings for these options.
%
% Turn off "display" and "plots"
pause
options.display               = 'off'; %'off';
options.plots                 = 'none';

%-------------------------------------------------
% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the XGB function. Preprocessing
% can be performed explicitly at the command line, but this allows the
% XGB function to perform preprocessing automatically during calibration
% and application to new data. The standard preprocessing structure will
% become a part of the standard model structure output by XGB.
% Preprocessing can be applied to the x and/or y-block in XGB.

pre = preprocess('default','mean center');
options.preprocessing{1} = pre;   %x-block

%-------------------------------------------------
% Now call the XGB function to calibrate the model.
% This will perform cross-validation to determine the best XGB parameters to use
pause
model = xgb(xblock1,yblock1,options);

%-------------------------------------------------
% CV was used, searching over a range of parameter values to find the optimal XGB parameters
% Show plot of the CV results over the first two parameter ranges
% 'X' marks the optimal parameters on the plot
% If the 'X' appears next to a parameter range boundary you might extend
% that parameter range (use the options parameter) in that direction.
pause

xgbcvplot(model)

%-------------------------------------------------
% And plot the model of calibration data
pause
figure
% plot(yblock1.data(:,1),'-b','linewidth',2), hold on
if ~isempty(model.pred{2})
    plot(xblock1index, yblock1.data(:,1),'-','linewidth',2), hold on        % plot known Y
else
    disp('Prediction is not plotted because model.pred{2} is empty.');
end

plot(xblock1index, model.pred{2}(:,1),'--g','linewidth', 2)             % plot predicted Y
legend('Actual','Predicted', 'Location','NorthWest')
hold off
title('Calibration data. Actual versus predicted Y');
xlabel('Sample Number (time)')
ylabel('Actual and Predicted Y (inches)')

%------------------------------------------------
% The optimal XGB parameters used to build the XGB model are:
pause

if ~isempty(model.detail.xgb.cvscan)
  disp( 'Optimal XGB parameters:'), disp(model.detail.xgb.cvscan.best)
end

pause
%-------------------------------------------------
% Predictions for new data can be made by calling the XGB function
% with the model as an input. Note again that the preprocessing of
% the new data will be handled by the XGB function because it is now
% a part of the model.

% If the validation set did not have the known reference values (yblock2)
% and only had the x-block (xblock2) then the call to XGB would be
%
pause
% pred  = xgb(xblock2,model,options);   

%-------------------------------------------------
% However, we have both xblock2 and yblock2 so we can call XGB to validate the model

pause
valid = xgb(xblock2,yblock2,model,options);

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

% %End of XGBDEMO
 echo off
