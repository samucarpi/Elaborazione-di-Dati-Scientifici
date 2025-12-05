echo on
% LWRDEMO Demo of the LWR function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

echo on

% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% -- Part 1: Locally Weighted Regression models --
% The LWRPRED function uses a locally weighted regression model
% to make predictions from a new data set given an existing
% reference (calibration) data set. As an example, we'll use the 
% process data in the PLSDATA file. The reference data is xblock1
% and yblock1. We'll make new y-block predictions from xblock2
% and plot them up. Additional inputs are the number factors to
% use in the models (3) and the number of points to call local (40):
 
pause
%-------------------------------------------------
% Load data:
 
load plsdata

%-------------------------------------------------
% Remove some known outliers from xblock1 and examine its contents
 
xblock1 = delsamps(xblock1,[73 278 279])  
 
% Note that the data is 300x20, but includ{1} is now length 297
% since 3 samples have been "soft deleted".
 
pause
%-------------------------------------------------
% The LWR function will be used to construct the LWR model.
%
% To get the options for this function run
 
options = lwr('options')
 
pause
%-------------------------------------------------
% See "lwr help" to get the valid settings for these options.
%
% Turn off "display" and "plots"
 
options.display = 'off';
options.plots   = 'none';
 
pause
%-------------------------------------------------
% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the LWR function. Preprocessing
% can be performed explicitly at the command line, but this allows the
% LWR function to perform preprocessing automatically during calibration
% and application to new data. The standard preprocessing structure will
% become a part of the standard model structure output by LWR.
 
pre = preprocess('default','mean center');
options.preprocessing{1} = pre;   %x-block
options.preprocessing{2} = pre;   %y-block
 
% Note that a preprocessing structure is required for both the
% x-block and y-block.

pause
%-------------------------------------------------
% Use 40 local points and 3 principal components
ncomp                     = 3;
npts                      = 40;
 
pause
%-------------------------------------------------
% Now call the LWR function to calibrate the model. This uses the
% 'globalpcr' default method, with 40 points and 3 principal components.
 
model = lwr(xblock1,yblock1, ncomp, npts, options);
 
pause
%-------------------------------------------------
% Predictions for new data can be made by calling the LWR function
% with the model as an input. Note again that the preprocessing of
% the new data will be handled by the LWR function because it is now
% a part of the model.
 
% If the validation set did not have the known reference values (yblock2)
% and only had the x-block (xblock2) then the call to LWR would be
%
% pred = lwr(xblock2, model);
 
pause
%-------------------------------------------------
% However, we have both xblock2 and yblock2 so we can call LWR
% to validate the model
 
valid = lwr(xblock2, yblock2, model);

pause
echo off

%-------------------------------------------------
% And plot the results
 
figure
plot(yblock2.data(:,1),'-b','linewidth',2), hold on
plot(valid.pred{2},'or','markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1]), hold off
xlabel('Sample Number (time)')
ylabel('Known and Estimated Y (inches)')
title('Locally Weighted Regression (LWR)');
legend('Known','Estimated','Location','NorthWest')
disp(sprintf('rmsec = %g, rmsep = %g Units', model.detail.rmsec(end), valid.detail.rmsep(end)));

echo on
pause
%-------------------------------------------------
 
% -- Part 2: LWR models with y-distance weighting --
% The alpha option of LWRPRED forces it to use its own predictions to
% iteratively update which samples are defined as local (samples which
% predict with significantly different y-values are not considered local).
% As an example, we'll use the same data but we'll need to set both (alpha)
% which is the weighting of the y value, and the number of iterations to
% run (iter). We'll use alpha of 0.4 and 2 interations in this case:
 
options.alpha = 0.4;
options.iter  = 2;

model = lwr(xblock1,yblock1, ncomp, npts, options); 
valid = lwr(xblock2, yblock2, model);

pause
%-------------------------------------------------
% And plot the results
 
echo off

figure
plot(yblock2.data(:,1),'-b','linewidth',2), hold on
plot(valid.pred{2},'or','markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1]), hold off
xlabel('Sample Number (time)')
ylabel('Known and Estimated Y (inches)')
title(['Locally Weighted Regression (LWR), alpha = ' num2str(options.alpha)]);
legend('Known','Estimated','Location','NorthWest')

disp(sprintf('Using alpha = %g, iter = %d', options.alpha, options.iter));
disp(sprintf('rmsec = %g, rmsep = %g Inches', model.detail.rmsec(end), valid.detail.rmsep(end)));

echo on

% The use of alpha slightly improves the predictability

pause
echo on
%-------------------------------------------------
% Finally, add cross-validation statistics to the model:

modelcv = crossval(xblock1,yblock1, model,{'con' 5},8);

pause
%-------------------------------------------------

%End of LWRDEMO
 
echo off
