echo on
% CHOOSECOMPDEMO Demo of the CHOOSECOMP function
 
echo off
%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk
 
clear ans
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% PCA Example:
%
% Load the ARCH demo dataset and create a simple 2 component model.
 
load arch

options = pca('options');  % constructs a options structure for PCA
options.plots = 'none';
options.preprocessing = preprocess('default','autoscale'); % add preprocessing
 
pcamodel   = pca(arch,2,options);% build model
 
pause
%-------------------------------------------------
% CHOOSECOMP can now be called to make a selection based on looking for a
% "knee" (drop) in eigenvalue. With PCA, the PC just before the drop is 
% selected. Note that crossvalidation is not needed with PCA models but can
% improve results when used.

pcs = choosecomp(pcamodel)
 
% We can see that choosecomp selected 4 PCs.
 
pause
%-------------------------------------------------
% If we plot the eigenvalues of our model we see there is a "knee" at 5 PCs
% so 4 PCs looks like a good choice.
 
ploteigen(pcamodel)
 
pause
%-------------------------------------------------
% PLS Example:
% 
% PLS requires cross validation results be present in the model before
% using choosecomp. 
%
% Load the PLSDATA demo dataset and create a PLS model.
 
load plsdata

%To get the options for this function run
options = pls('options');

%Turn off "display" and "plots" 
options.display = 'off';
options.plots   = 'none';

%Set preprocessing. 
pre = preprocess('default','mean center');
options.preprocessing{1} = pre;   %x-block
options.preprocessing{2} = pre;   %y-block

%Call PLS function to calibrate the model with 3 LV's 
plsmodel = pls(xblock1,yblock1,3,options);
 
pause
%-------------------------------------------------
% Add Crossvalidation to the model. 
 
plsmodel = crossval(xblock1, yblock1, plsmodel, {'loo',[],1}, 10);
 
% Now that crossval results are in the model we can call CHOOSECOMP.
 
lvs = choosecomp(plsmodel)
 
pause
%-------------------------------------------------
%  The algorithm locates the lowest RMSECV with the fewest latent
%  variables. Additional LVs are added only if they improve the RMSECV by a
%  significant amount (>~5%).
 
%End of CHOOSECOMP demo
echo off

