echo on
% COMPRESSMODELDEMO Demo of the COMPRESSMODEL function
 
echo off
%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Normally, most PLS_Toolbox models require that all variables present when
% a model is calibrated also be present when the model is applied to new
% data. 
%COMPRESSMODEL removes any references to soft-excluded (unused) variables
% from a model so that the model can be applied to data in which those
% excluded variables were either not measured or were hard-deleted
% (removed) beforehand. 
% This demo uses the Near-IR dataset which consists
% of spectra of 30 synthetic mixtures (containing 5 components) collected
% on two different instruments.
% First, we will soft-exclude most of the variables using the DataSet
% object's include field, then we'll build a model from that data and
% demonstrate the use of compressmodel so that the model can be applied to
% the data with those same variables hard-deleted.
pause
%-------------------------------------------------
%Load data:
% The data consists of two sets of spectra (x-blocks) and a set of
% concentrations of which we're going to use only one column (one component).
% We will use one set of spectra as a calibration set (spec1) and the other
% as a validation set. The data are in DataSet objects. [In reality, the
% two sets of spectra are from different instruments and require some
% calibration transfer to successfully apply this model, but this is not
% important for this demonstration. See stddemo]
 
load nir_data
 
whos
 
pause
%-------------------------------------------------
% If, during model development, we realized that no variable below #300 was
% useful in prediction, we would most likely soft-delete (exclude) these
% variables from the dataset. We do that using the "include" field of the
% spec1 dataset object (note that the include field always works in
% variable NUMBER which is usually different from any axes associated with
% these variables such as wavenumbers or wavelength). We'll pretend that
% sometime later, we knew of this decision and never collected these
% variables on instrument 2 (spec2).
 
spec1.include{2} = [300:401];  %soft-delete using include field
spec2 = spec2(:,300:401);      %hard-delete variables from spec2
 
whos
 
% Note the different sizes of spec1 and spec2
 
pause
%-------------------------------------------------
% Now we'll make a PLS model using only those variables listed (300-401)
 
options = pls('options');
options.preprocessing = {preprocess('default','meancenter') preprocess('default','meancenter')};
options.plots = 'none'; options.display = 'off';
model = pls(spec1,conc(:,1),3,options);
 
pause
%-------------------------------------------------
% Right now, to apply this model to future data, we would have to collect
% all 401 variables so that PLS could exclude the ones the model won't be
% using. If we didn't collect variables 1-299, we would get an error if we
% tried to apply this model to the smaller dataset. That is: 
%
%   pred = pls(spec2,model,options);
%
% would give an error saying there are an insufficient number of variables
% in the data to match the model. Instead, we can use compressmodel to have
% the model completely "forget" about the ones we discarded.
 
pause
%-------------------------------------------------
% To compress the model we simply call compressmodel:
 
cmodel = compressmodel(model);
 
% Now this model can be applied to the reduced data without problems:
 
pred = pls(spec2,cmodel,options);
 
% End of COMPRESSMODELDEMO
