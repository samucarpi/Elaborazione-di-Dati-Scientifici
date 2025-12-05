echo on
% POLYTRANSFORMDEMO Demo of the POLYTRANSFORM function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
clear ans
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Demonstrate the use of polytransform to augment a dataset with
% transformed x-block variables before doing regression on the dataset.
% The 'plsdata' dataset is loaded, and is then augmented with squared 
% variables. Regression is applied to the augmented dataset using mlr.
%
% Load data:
% The data consists of two predictor x-blocks and two
% predicted y-blocks. The data are in DataSet objects.
% xblock1 and yblock1 will be used for calibration and
% xblock2 and yblock2 will be used for validation.
 
load plsdata
% Note that the x-block data is 300x20.

pause
%-------------------------------------------------

% Apply POLYTRANSFORM to add the squared variables to the x-block dataset
% The POLYTRANSFORM function will be used to construct the POLYTRANSFORM model.
polyopts = polytransform('options');
polyopts.preprocessingtype = 'auto';
polyopts.squares = 'on';        % Add squared variables to dataset
polyopts.cubes   = 'off';
polyopts.quartics = 'off';
polyopts.crossterms = 'off';
polyopts.preprocessoriginalvars = 0;
[xblock1, polymodel] = polytransform(xblock1, polyopts);

% Apply POLYTRANSFORM to new data using the polymodel
xblock2 = polytransform(xblock2, polymodel);
% POLYTRANSFORM is completed now. 
% Note that the x-block data is 300x40.

% Next, the data will be analyzed using MLR
pause
%-------------------------------------------------
% First remove some known outliers from xblock1 and examine its contents
 
xblock1 = delsamps(xblock1,[73 278 279]);
 
% Note that the data is 300x40, but includ{1} is now length 297
% since 3 samples have been "soft deleted".
 
pause
%-------------------------------------------------
% The MLR function will be used to do regression on the augmented data
%

options = mlr('options');
options.display = 'off';
options.plots   = 'none';
pre = preprocess('default','mean center');
options.preprocessing{1} = pre;   %x-block
options.preprocessing{2} = pre;   %y-block
 
% Now call the MLR function to calibrate the model
model = mlr(xblock1,yblock1,options);
 
%-------------------------------------------------
% We have both xblock2 and yblock2 so we can call MLR to validate the model
 
valid = mlr(xblock2,yblock2,model,options);
 
pause
%-------------------------------------------------
% And plot the results

figure
plot(yblock2.data(:,1),'-b','linewidth',2), hold on
plot(valid.pred{2},'or','markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1]), hold off
xlabel('Sample Number (time)')
ylabel('Known and Estimated Y (inches)')
legend('Known','Estimated','Location','NorthWest')
title(['Test data. rmsep = ' num2str(valid.detail.rmsep(end))])
 
disp(sprintf('rmsec = %f, rmsep = %f', valid.detail.rmsec, valid.detail.rmsep));

% Using polytransform to add squared variables to the dataset does not improve the mlr 
% prediction for these data since rmsep for un-augmented dataset = 0.149386. 
% Polytransform should be more helpful for datasets with more nonlinearity.

%End of POLYTRANSFORMDEMO
echo off
