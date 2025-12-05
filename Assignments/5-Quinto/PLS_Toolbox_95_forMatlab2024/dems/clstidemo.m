echo on
%CLSTIDEMO Demo of the CLSTI function.
 
echo off
%Copyright Eigenvector Research, Inc. 2023
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
echo on
 
%To run the demo hit a "return" after each pause
 
pause
 
% This demo uses the clsti demo data set. There are four DataSet 
% objects (DSOs) that contain pure spectra measured at different 
% temperatures (25, 40, 55, 70), for Acetone, Ethanol, Isopropanol, and
% Methanol. These four DSOs will be used to build a CLSTI model. There are 
% three DSOs corresponding to test samples measured at three different 
% temperatures (44, 67, and 75). Each of these DSOs have the temperatures
% in the axisscale{1,1} field.
 
% The fist step is to build the CLSTI model
 
pause
 
% Load the clsti demo data set.
 
load clsti_data.mat

% Confirm temperatures are in axisscale{1,1}
pureAcetone.axisscale{1,1};
 
% Build the CLSTI model

clstiModel = clsti({pureAcetone pureEthanol pureIsopropanol pureMethanol});
 
pause

% At this point, the model is built but CLSTI models are different in that
% there are scores or loadings to plot at this point. We need to apply the
% model to test data to plot the interpoloated spectra (loadings) and
% scores.
%
% We will use the sample 1, sample 2, and sample 3 DSOs as test data.

sample1_pred = clstiModel.apply(sample01_DSO);
 
pause

% Upon applying the model, the pure spectrum for each component will be 
% interpoloated at each test temperature. For example, our pure
% Temperatures are: 25, 40, 55, and 70. Our first test temperature is 44.
% Since 44 is between the pure temperatures, 40 and 55, these temperatures
% and the corresponding pure component spectra will be used to calculate
% the interpoloated spectrum at the test temperature. 

% We can look at the interpolated spectrum by plotting the loadings.

sample1_pred.plotloads;

% The interpoloated spectrum is then used to obtain a prediction, which we
% can view by plotting the scores.

sample1_pred.plotscores;
 
%End of CLSTIDEMO
 
echo off
