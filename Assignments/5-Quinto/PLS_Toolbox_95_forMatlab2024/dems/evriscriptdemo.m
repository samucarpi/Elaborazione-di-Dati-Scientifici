echo on
% EVRISCRIPTDEMO Demo of the evriscript functionality
 
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
% Demonstrate the use of evriscripts.

% Get an input dataset
load plsdata;

% An evriscript is a chain of steps where each step applies a single 
% pls_toolbox function. This demo will show how to create a simple 
% single-step script 'script_pca', and then a more realistic four-step 
% script 'script_pls'.

pause
%-------------------------------------------------

% The list of pls_toolbox functions available for 
% use in scripting is available by entering:

evriscript_module('showall')

pause
%-------------------------------------------------

% A script can be created in one command:
script_pca = evriscript('pca');

% or in stages:
script_pca = evriscript;
script_pca = script_pca.add('pca');

pause
%-------------------------------------------------

% 'script_pca' is an evriscript object. The script steps are evriscript_step
% objects which can be accessed by indexing, 'script_pca(1)', for example.
%
% The individual steps' options are then configured. Most steps have more
% than one 'step_mode', for example 'calibrate', 'apply' or 'test'. 
% You can see which modes are avaialable for a step by entering
script_pca(1).step_module

pause
%-------------------------------------------------
% Here we want to build a PCA model so we chose the 'calibrate' mode
% and use 5 PCs
ncomp                        = 5;
script_pca(1).step_mode      = 'calibrate';
script_pca(1).options.plots  = 'none';
script_pca(1).x              = xblock1;
script_pca(1).ncomp          = ncomp;

% Now run the script
script_pca = script_pca.execute;  

pause
%-------------------------------------------------

% The input and output variables for this step are found in
% 'script_pca(1).variables'. 
pca_model = script_pca(1).variables.model;

% The creation of a more realistic four-step script is shown next

pause
%-------------------------------------------------
% This longer script will 
% 1. calibrate a PLS model using the 'plsdata' dataset, then
% 2. use crossvalidation to calculate the error, rmsecv. 
% 3. use 'choosecomp' to determine what is an optimal number of latent
%      variables (ncomp) to use, and finally
% 4. calibrate a new PLS model using the suggested ncomp value.

script_pls = evriscript( 'pls', 'crossval', 'choosecomp', 'pls');

pause
%-------------------------------------------------

% First step builds a PLS model with ncomp LVs
j = 1;
%  I/O: model = pls(x,y,ncomp,options);  %identifies model (calibration step)    
script_pls(j).step_mode              = 'calibrate';
script_pls(j).options.display        = 'on';
script_pls(j).options.plots          = 'none';
script_pls(j).options.preprocessing  = {'autoscale'};
script_pls(j).x                      = xblock1;
script_pls(j).y                      = yblock1;
script_pls(j).ncomp                  = ncomp;

pause
%-------------------------------------------------

% Second step applies crossval. 
% This shows an important feature of scripting, namely the use of
% evriscript_reference variables to refer to an output variable of an
% earlier step in the script. evriscript_reference takes two arguments,
% first is the name of the output variable, and second is the script step
% which outputs this variable.
% Note also that the PLS model is being passed into crossval's 'rm' parameter.
% This new feature of crossval (since pls_toolbox 6.0) allows crossval to
% update an existing model with crossvalidation details, rmsec, rmsecv. 
% In this usage the updated model is output as the first output variable,
% 'press', and is the only output from crossval.
j = 2;
%  I/O: [press,cumpress,rmsecv,rmsec,cvpred,misclassed] = crossval(x,y,rm,cvi,ncomp,options);
cvi                 = {'vet' 5 1};
script_pls(j).step_mode      = 'apply';
script_pls(j).options.plots  = 'none'; %'final';
script_pls(j).options.preprocessing = {preprocess('default','mean center') preprocess('default','mean center')};
script_pls(j).x              = xblock1;
script_pls(j).y              = yblock1;
script_pls(j).rm             = evriscript_reference('model', script_pls(1)); % index!
script_pls(j).cvi            = cvi;
script_pls(j).ncomp          = 10;

% Note that references can also be assigned in the form:
%  script.reference(1,'outputvar',2,'inputvar');
% Example:
%  script_pls.reference(1,'model',2,'rm');

pause
%-------------------------------------------------

% Since the model has crossvalidation information it can be input to
% choosecomp to suggest what the best number of LVs to use would be.
j = 3;
% I/O: lvs = choosecomp(model,options)
script_pls(j).step_mode              = 'apply';
script_pls(j).model                  = evriscript_reference('cvresults', script_pls(2)); % index!

pause
%-------------------------------------------------

% Finally, use the number of LVs suggested by choosecomp to build a new PLS
% model.
j = 4;
%  I/O: model = pls(x,y,ncomp,options);  %identifies model (calibration step)    
script_pls(j).step_mode              = 'calibrate';
script_pls(j).options.display        = 'on';
script_pls(j).options.plots          = 'none';
script_pls(j).options.preprocessing  = {'autoscale'};
script_pls(j).x                      = xblock1;
script_pls(j).y                      = yblock1;
script_pls(j).ncomp                  = evriscript_reference('lvs', script_pls(3)); % index!

pause
%-------------------------------------------------

% Validate all reference variables in the chain are resolvable to known variables
isChainValid = script_pls.validate;

pause
%-------------------------------------------------

% Print summary of chain steps at increasing levels of detail
script_pls.summarize;            % same as script_pls.summarize(0)
% script_pls.summarize(2);         % most detail

pause
%-------------------------------------------------

if isChainValid
  script_pls = script_pls.execute; 
else
  disp('Chain is not valid because of unresolvable reference variable');
end

pause
%-------------------------------------------------

% The final model is accessible as:
final_model = script_pls(4).variables.model;

%End of EVRISCRIPTDEMO
echo off
