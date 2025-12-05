echo on
% MLRDEMO Demo of the MLR function
 
echo off
%Copyright Eigenvector Research, Inc. 2022
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms - modified from plsdemo
 
clear ans
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load data:
% The data consists of two predictor x-blocks and two
% predicted y-blocks. The data are in DataSet objects.
% xblock1 and yblock1 will be used for calibration and
% xblock2 and yblock2 will be used for validation.
 
load plsdata
whos
 
pause
%-------------------------------------------------
% Remove some known outliers from xblock1 and examine its contents
 
xblock1 = delsamps(xblock1,[73 278 279])
 
% Note that the data is 300x20, but includ{1} is now length 297
% since 3 samples have been "soft deleted".
 
pause
%-------------------------------------------------
% The MLR function will be used to construct the MLR model.
%
% To get the options for this function run
 
options = mlr('options')
 
pause
%-------------------------------------------------
% See mlr help to get the valid settings for these options.
%
% Turn off "display" and "plots"
 
options.display = 'off';
options.plots   = 'none';
 
pause
%-------------------------------------------------
% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the MLR function. Preprocessing
% can be performed explicitly at the command line, but this allows the
% MLR function to perform preprocessing automatically during calibration
% and application to new data. The standard preprocessing structure will
% become a part of the standard model structure output by MLR.
 
pre = preprocess('default','mean center');
options.preprocessing{1} = pre;   %x-block
options.preprocessing{2} = pre;   %y-block
 
% Note that a preprocessing structure is required for both the
% x-block and y-block.
 
pause
%-------------------------------------------------
% To perform cross-validation it might be called using the following:
% 
% [press,cumpress,rmsecv] = crossval(xblock1,yblock1,'mlr',{'con', 10},12,1,{pre pre});
%
% But we'll skip that for this demo. See LINMODELDEMO.
 
pause
%-------------------------------------------------
% Now call the MLR function to calibrate the model
 
model = mlr(xblock1,yblock1,options)

pause
%-------------------------------------------------
% Predictions for new data can be made by calling the MLR function
% with the model as an input. Note again that the preprocessing of
% the new data will be handled by the MLR function because it is now
% a part of the model.
 
% If the validation set did not have the known reference values (yblock2)
% and only had the x-block (xblock2) then the call to MLR would be
%
% pred  = mlr(xblock2,model,options);
 
pause
%-------------------------------------------------
% However, we have both xblock2 and yblock2 so we can call MLR
% to validate the model
 
valid = mlr(xblock2,yblock2,model,options)
 
pause
%-------------------------------------------------
% And plot the results
 
figure
plot(yblock2.data(:,1),'-b','linewidth',2), hold on
plot(valid.pred{2},'or','markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1]), hold off
xlabel('Sample Number (time)')
ylabel('Known and Estimated Y (inches)')
legend('Known','Estimated','Location','NorthWest')



pause


% Now let's examine a case where adding regularization to MLR can be
% helpful. Load in the tecator demo dataset.
% The data consists of a x-block (Tecator, as a dataset object) and a
% y-block (Conc, as a dataset object). A cal/val set is provided for us. 
% In this example we are predicting the amount of fat content in each
% sample.
 
load tecator
whos
 
pause

%-------------------------------------------------
% The MLR function will be used to construct the MLR model.
%
% To get the options for this function run
 
options = mlr('options')
 
pause
%-------------------------------------------------
% See mlr help to get the valid settings for these options.
%
% Turn off "display" and "plots"
 
options.display = 'off';
options.plots   = 'none';
 
pause
%-------------------------------------------------
% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the MLR function. Preprocessing
% can be performed explicitly at the command line, but this allows the
% MLR function to perform preprocessing automatically during calibration
% and application to new data. The standard preprocessing structure will
% become a part of the standard model structure output by MLR.
 
pre1 = {'mean center'};
pre2 = {'autoscale'};
options.preprocessing{1} = pre1;   %x-block
options.preprocessing{2} = pre2;   %y-block
 
% Note that a preprocessing structure is required for both the
% x-block and y-block.
 
pause
%-------------------------------------------------
% To perform cross-validation it might be called using the following:
% 
% [press,cumpress,rmsecv] = crossval(xblock1,yblock1,'mlr',{'con', 10},12,1,{pre pre});
%
% But we'll skip that for this demo. See LINMODELDEMO.
 
pause
%-------------------------------------------------
% Now call the MLR function to calibrate the model WITHOUT regularization
 
modelNoReg = mlr(Xcal,Ycal(:,2),options)

pause
%-------------------------------------------------
% Predictions for new data can be made by calling the MLR function
% with the model as an input. Note again that the preprocessing of
% the new data will be handled by the MLR function because it is now
% a part of the model.
 
% If the validation set did not have the known reference values (Ytest(:,2))
% and only had the x-block (Xtest) then the call to MLR would be
%
% pred  = mlr(Xtest,model,options);
 
pause
%-------------------------------------------------
% However, we have both Xtest and Ytest(:,2) so we can call MLR
% to validate the model
 
validNoReg = mlr(Xtest,Ytest(:,2),modelNoReg,options)
 
pause
%-------------------------------------------------
% And plot the results
 
figure
plot(Ytest(:,2).data(:,1),'-b','linewidth',2), hold on
plot(validNoReg.pred{2},'or','markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1]), hold off
xlabel('Sample Number (meat sample)')
ylabel('Known and Estimated Y (fat content)')
legend('Known','Estimated','Location','NorthWest')
title(sprintf('Tecator no regularization - RMSEC = %4.4g, RMSEP = %4.4g',validNoReg.detail.rmsec,validNoReg.detail.rmsep))
pause
%-------------------------------------------------
% Adding regularization to an MLR model may be helpful when the x-block is 
% ill-conditioned and can also be used as a variable selection tool. The available 
% regularization methods are RIDGE, RIDGE_HKB, OPTIMIZED_RIDGE, OPTIMIZED_LASSO, 
% AND ELASTICNET via the 'algorithm' field in the options structure. 
% Ridge regularization based upon the standard formulation from Hoerl 
% and Kennard (1970), B = (X'X + I*theta)^-1 * X'Y, may be selected by 
% setting options.algorithm = ‘ridge’ and setting a positive scalar value 
% for theta (regularization parameter) in options.ridge; the regression 
% vector B is calculated directly through matrix inversion.  
% An estimate of an optimal value for  and the corresponding regression 
% vector may be determined using the method of Hoerl, Kennard, 
% and Baldwin (1975) by setting options.algorithm = ‘ridge_hkb’.  No other 
% parameters are used for this option and the resulting optimal value of 
% theta is calculated by matrix inversion. Ridge regularization can also be
% cast as an optimization (in this case, the L2 norm of B) and is included 
% for completeness.  For this case, options.algorithm = ‘optimized_ridge’ 
% and the optimal value of theta is obtained from the range in 
% options.optimized_ridge (vector).  This mode may be used to place bounds 
% around the value of theta.  
 
% Lasso regularization minimizes the L1 norm of B and uses the settings 
% options.algorithm = ‘optimized_lasso’ and supplying a vector of values 
% for the appropriate parameter in options.optimized_lasso.

% Elastic net regularization seeks to minimize the L2 and L1 norms of B 
% simultaneously using the initial estimates for the parameters in 
% options.optimized_ridge and optimized_lasso, respectively.  The 
% appropriate value for options.algorithm is ‘elasticnet` for this scenario.


options.algorithm = 'ridge'  % 'ridge', 'ridge_hkb' 'optimized_ridge' 'optimized_lasso', or 'elasticnet'

% set regularization value(s):
switch options.algorithm
  case 'ridge'
    options.ridge = 1e-6;
    t = 'ridge';
  case 'ridge_hkb'
    t = 'ridge\_hkb';
  case 'optimized_ridge'
    options.optimized_ridge = [1e-10 1e-9 1e-8];
    t = 'optimized\_ridge';
  case 'optimized_lasso'
    options.optimized_lasso = [1e-20 1e-15 1e-10];
    t = 'optimized\_lasso';
  case 'elasticnet'
    options.optimized_ridge = [1e-10 1e-9 1e-8];
    options.optimized_lasso = [1e-20 1e-15 1e-10];
    t = 'elasticnet';
end

rng(1);
modelReg = mlr(Xcal,Ycal(:,2),options)

pause
%----------------------------------------------
% This naturally decreases performance on the calibration set while
% increasing performance on the validation set.

validReg = mlr(Xtest,Ytest(:,2),modelReg,options)

pause
%-------------------------------------------------
% And plot the results
 
figure
plot(Ytest(:,2).data(:,1),'-b','linewidth',2), hold on
plot(validReg.pred{2},'or','markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1]), hold off
xlabel('Sample Number (meat sample)')
ylabel('Known and Estimated Y (fat content)')
legend('Known','Estimated','Location','NorthWest')



title(sprintf('Tecator with %s regularization - RMSEC = %4.4g, RMSEP = %4.4g',t,validReg.detail.rmsec,validReg.detail.rmsep))

%End of MLRDEMO
 
echo off
