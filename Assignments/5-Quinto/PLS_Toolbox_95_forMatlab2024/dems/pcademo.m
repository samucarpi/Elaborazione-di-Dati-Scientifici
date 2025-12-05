echo on
%PCADEMO Demo of the PCA function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load data:
 
load wine
 
disp(wine.description)
 
pause
%-------------------------------------------------
% To construct a 2 PC PCA model with plots and display
% to the command line, type >>model = pca(wine,2); .
%
% For this example we'll turn off the plots, but leave
% the display on.
%
 
options = pca('options');  % constructs a options structure for PCA
options.plots = 'none'
 
pause
%-------------------------------------------------
% We'll create a standard preprocessing structure to
% allow the PCA function to do autoscaling for us.
%
 
options.preprocessing = preprocess('default','autoscale'); %structure array
 
pause
%-------------------------------------------------
% Call the PCA function and create the model.
% (model) is a structure array that contains all
% the model parameters.
%
 
model   = pca(wine,2,options);
 
%
% The model has been constructed.
%
% You can type >>pca and load this model into the GUI to explore it.
%
% You might be interested to type >>model to see how the
% model structure is organized.
%
 
pause
%-------------------------------------------------
% Now we'll show how you might apply the model to new
% data, but we'll use the same data set.
%
 
options.plots = 'final';
options.display = 'off';
pred    = pca(wine,model,options);
 
 
%End of PCADEMO
 
echo off
