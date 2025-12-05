echo on
%TESTROBUSTNESSDEMO Demo of the testrobustness function.

echo off;

%Copyright Eigenvector Research, Inc. 1992
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

 
echo on;  

% To run the demo hit a "return" after each pause
pause

%-------------------------------------------------
% This demo will demonstrate how to to use the testrobustness function.  
% To evauluate the robustness of a model, we evaluate the prediction error
% given by the model in the presence of increasingly large perturbations to
% the xblock data on which the model was trained.  
% The testrobustness function perturbs the input xblock data in one of two
% ways.  The first perturbation method shifts & broadens the xblock data, 
% while the second perturbation method of adds a Gaussian peak of varrying 
% width and position.  
 
% The testrobustness function will produce a plot which shows the magnitude of
% prediction error vs the magnitude of the perturbation to the xblock data.  

pause 

% Set the options and preprocessing methods to be passed to the PLS model.  
options.display = 'off';
options.plots   = 'none';
 
%---------------------------------------------------------------  
% PREPROCESS will be called to construct a standard preprocessing
% structure that can be used by the pls function.  
pre = preprocess('default','autoscale');
options.preprocessing{1} = pre;   %x-block
options.preprocessing{2} = pre;   %y-block

pause 

%---------------------------------------------------------------  
% Build a PLS model using the nir dataset
%  

load nir_data
model = pls(spec1,conc(:,1),3,options);


%---------------------------------------------------------------  
%   Call the testrobustness function and pass it 'options' to return the
%   defualt options structure for the interference and shift tests.  

opts = testrobustness('options');

pause

%---------------------------------------------------------------  
% Now we are ready to call the testrobustness function, passing it the PLS
% model we have built, as well the xblock and yblock data.  We will first test
% the robustness of the model in the presence of shifts and broadening.  
% The output plot shows the  the prediction error vs two variables; the 
% amount shifted as well as the width of the broadening filter.  We
% observe that the model is highly sensitive to the effects of broadening,
% and to a much lesser degree sensitive to the amount shifted.  We also see
% that this model is more sensitive to shifts in the positive x direction
% compared to shifts and the negative x direction.  
   
testtype = 'shift';
[results] = testrobustness(model, spec1, conc(:,1), testtype,opts);

pause 

%---------------------------------------------------------------  
% Next we will test the robustness of the model in the presence of Gaussian
% perturbations.  In this case The magnitude of the prediction error
% for this model is highly dependent upon the wavenumber at which the
% Guassian interference is added, and shows little sensitivity to the width
% of the Gaussian peak.  These results may be difficult to interpret.  
% Further exploration of the data may be needed to interpret this.    

testtype = 'interference';

[results] = testrobustness(model, spec1, conc(:,1), testtype,opts);

% type "testrobustness help" for more information.

%End of TESTROBUSTNESS demo
echo off

