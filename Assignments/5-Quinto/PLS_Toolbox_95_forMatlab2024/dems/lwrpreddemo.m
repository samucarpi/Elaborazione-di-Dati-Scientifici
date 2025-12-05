echo on
% LWRPREDDEMO Demo of the LWRPRED function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%bmw
 
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
 
load plsdata

%-------------------------------------------------
% Remove some known outliers from xblock1 and examine its contents
 
xblock1 = delsamps(xblock1,[73 278 279])  
yblock1 = delsamps(yblock1,[73 278 279])
 
% Note that the data is 300x20, but includ{1} is now length 297
% since 3 samples have been "soft deleted".

pause
%-------------------------------------------------

options           = lwrpred('options');
options.plots     = 'none';
options.display   = 'off';

pause
%-------------------------------------------------
% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the LWR function. Preprocessing
% can be performed explicitly at the command line, but this allows the
% LWR function to perform preprocessing automatically during calibration
% and application to new data. The standard preprocessing structure will
% become a part of the standard model structure output by LWR.
 
options.preprocessing = 1; % 0 = none, 1 = mean center, 2 = autoscale

ypred = lwrpred(xblock2,xblock1,yblock1,3,40, options);
 
echo off
figure
plot(yblock2.data,ypred,'ob'), dp
xlabel('Actual Melter Level')
ylabel('Predicted Melter Level (inches)')
title('Prediction from LWRPRED'), shg
rmsep = rmse(yblock2.data,ypred);
disp(sprintf('Root Mean Square Error of Prediction = %g Inch',rmsep));
pause
%-------------------------------------------------
echo on
 
% -- Part 2: LWR models with y-distance weighting --
% The alpha option of LWRPRED forces it to use its own predictions to
% iteratively update which samples are defined as local (samples which
% predict with significantly different y-values are not considered local).
% As an example, we'll use the same data but we'll need to set both (alpha)
% which is the weighting of the y value, and the number of iterations to
% run (iter). We'll use alpha of 0.4 and 2 interations in this case:
 
options.alpha = 0.4;
options.iter  = 2;
 
ypredxy = lwrpred(xblock2,xblock1,yblock1,3,40,options);
 
echo off
plot(yblock2.data,ypredxy,'or',yblock2.data,ypred,'ob'), dp
xlabel('Actual Melter Level')
ylabel('Predicted Melter Level (inches)')
title('Y-Distance Weighted Prediction from LWRPRED (red)'), shg
rmsep = rmse(yblock2.data,ypredxy);
disp(sprintf('Root Mean Square Error of Prediction = %g Inch',rmsep));

echo on

% The use of alpha slightly improves the predictability

pause
%-------------------------------------------------
 
% Note that LWRPRED accepts matrices or Dataset Objects as inputs. For more
% information see LWRPRED help.
 
echo off
