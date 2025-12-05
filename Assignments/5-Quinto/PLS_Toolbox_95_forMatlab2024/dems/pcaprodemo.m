echo on
%PCAPRODEMO Demo of the PCAPRO function
 
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
% For this demo we'll use the ARCH data set.
 
load arch
whos
 
pause
%-------------------------------------------------
% In this demonstration we'll autoscale the data
% for the first 63 samples (these are the samples
% where we know their origin). Then we'll project
% the last 12 samples (64:75) onto the model using
% the PCAPRO function.
 
% Note that the first 63 samples are from 4 different
% quarries and the last 12 samples are unknowns. This
% information is carried in the arch.class{1} vector
% where each class is numbered 0-4.
 
pause
%-------------------------------------------------
% Step 1 is to scale the data used to calibrate the
% PCA model.
 
[ax,mx,stdx] = auto(arch.data(1:63,:));    %scale the cal data
sx = scale(arch.data(64:75,:),mx,stdx);    %scale the test data
 
% Here (ax) is the autoscaled data,
% (mx) is a vector of means of (x), and
% (stdx) is a vector of standard deviations
% of (x). The output (sx) is the test data
% centered and scaled using the parameters
% from the calibration data.
 
pause
%-------------------------------------------------
% Step 2 is to construct a PCA model for the autoscaled
% data. Here we'll turn off the plotting in the PCA
% routine and use 4 PCs to model the data.
 
options       = pca('options');     %get the default options structure
options.plots = 'none';             %change the plotting options
model         = pca(ax,4,options);  %construct the PCA model
 
pause
%-------------------------------------------------
% Step 3 projects the test data onto the PCA model.
% Plotting is turned off as we'll make our own plots here. 
 
[scoresn,resn,tsqn] = pcapro(sx,model,0);
 
pause
%-------------------------------------------------
% Now let's put the scores from the model and the new
% data into a DataSet and pass it to PLOTGUI. The objective
% here is to use the class information stored in the
% arch.class{1} field to put different markers for each
% class.
 
allscores = dataset([model.loads{1};scoresn]);
allscores = copydsfields(arch,allscores,1);
plotgui(allscores)
 
% Plots can also be constructed manually for the new
% scores (scoresn), the new residuals (resn), and/or
% the new T^2 (tsqn).
 
%End of PCAPRODEMO
 
echo off
