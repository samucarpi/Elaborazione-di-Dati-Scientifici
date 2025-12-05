echo on
%MCCTOBJECTDEMO Demo of the MCCTObject object
 
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
% MCCTOBJECT - Model Centric Calibration Transfer Object, an object to
% create and test multiple calibration transfer scenarios for a given
% "primary" model. Each calibration transfer scenario consists of:
% 
% * A calibration transfer model (see caltransfer.m) as a preprocessing
%   step.
% * Insert location in the preprocessing steps of the primary model. 
%
% A given calibration method (DS, PDS, PWDS, SST) may have one or more
% parameters to "tune" for a given instrument. For example, window size in
% the case of PDS.
% 
% The ultimate goal is to produce a new "secondary" model based on the "primary"
% model with a calibration transfer preprocessing step inserted to account
% for instrument variation. 
 
 
% Load a sample dataset.
load corn_dso;

% This data set consists of 80 samples of corn measured on   
% 3 different NIR spectrometers. 

pause
%------------------------------------------------- 
% Create a PLS model using the mp6spec spectrometer (Xblock) and the moisture
% measurement (Yblock). Use 3 preprocessing steps to better linearize the
% data before the model. 
 
moisture_ds = conc(:,1);
options = pls('options');
options.display = 'off';
options.plots   = 'none';
mypp_x = preprocess('default','derivative','GLS Weighting','mean center');
 
%Add additional parameters to GLSW.
mypp_x(2).userdata.a = 1.5e-05;
mypp_x(2).userdata.source = 'gradient';
mypp_x(2).userdata.meancenter = 'yes';
mypp_x(2).userdata.applymean = 'yes';
mypp_x(2).userdata.classset = 1;
 
mypp_y = preprocess('default','autoscale');
 
options.preprocessing = {mypp_x mypp_y};
masterpls_model = pls(mp6spec,moisture_ds,6,options);
 
pause
%------------------------------------------------- 
% Create MCCTObject with model and data from above. Use a subset of the
% data as the "transfer samples" to mimic a real world situation.
 
specnos = [ 77 27 79 72 54 60 32 68 ];
conctrans = moisture_ds(specnos);
mp6trans = mp6spec(specnos);
mp5trans = mp5spec(specnos);

% Create the MCCTObject with given model and data.

mobj = MCCTObject('CalibrationMasterXData',mp6trans,'CalibrationSlaveXData',mp5trans,...
            'CalibrationYData', conctrans,'ValidationMasterXData',mp6spec,'ValidationSlaveXData',mp5spec,...
            'ValidationYData',moisture_ds, 'MasterModel',masterpls_model);
 
%NOTE: Entire sample range is being used as validation data.
 
pause
%------------------------------------------------- 
% Create combinations of transfer methods and parameters to test. Try
% Direct Standardization, Piecewise Direct Standardization,  Spectral
% Subspace Transformation with varying ranges of parameter values.
% 
% Combinations are specified with an nx5 cell array:
%      {modelType, parameterName, min, step, max}
%
 
mycombos = {'pds' 'win' 5 2 17;'sst' 'ncomp' 2 1 5;'ds' '' [] [] []};

mobj.CalibrationTransferCombinations = mycombos;
 
pause
%------------------------------------------------- 
% Create secondary models with each transfer preprocessing step in 3 positions
% in the preprocessing structure:
%  0 - Before all preprocessing.
%  1 - After derivative.
%  2 - After GLSW.
% 
%  Note: By default, the calibration transfer models automatically created
%  in the object will include the preprocessing steps prior to the insert
%  point. For example, with the insert location at 1, when secondary data is
%  preprocessed in the following order:
%    * Derivative
%    * Calibration Transfer
%    * GLSW
%    * Mean Center
 
% Tell object to show waitbar to follow progress.
mobj.UseWaitbar = true;
 
% Calculate all secondary models, apply them to validation data,
% and compile results for given prepro insert indicies.
mobj.makeSlaveModelInd([0 1 2]);
 
pause
%------------------------------------------------- 
% Look at the results. Use the calibration and validation difference ratios
% for a general guide to how much variation has been accounted for between
% the instruments. Smaller ratios indicate small difference between
% machines. 
%
% For regression models (that use a y-block) various RMSE values
% are calculated. The abbreviations for RMSE comparisons are:
% 
%   CalM - Primary Model Prediction of Primary Calibration Data
%   CalS - Secondary Model Prediction of Secondary Calibration Data
%   CalY - Calibration Y Data
%   
%   ValM - Primary Model Prediction of Primary Validation Data
%   ValS - Secondary Model Prediction of Secondary Validation Data
%   ValY - Validation Y Data
 
myresultstable = mobj.ResultsTable

% Sort for the minimum value for "RMSE(ValS,ValY)" as an indicator of the
% better performing models.

[val myidx] = sort([myresultstable{2:end,9}]);

% Show in sorted order (account for labels in first row by adding 1).
myidx = myidx+1;
myidx = [1 myidx];

myresultstable(myidx,:);
 
pause
%------------------------------------------------- 
% Use the Model ID to retrieve the top secondary model from the sort above. The
% model is PDS with window of 5 inserted after the first preprocessing step
% (derivative).
 
% A good performing model.
modelrow = myresultstable(myidx(2),:)
modelid = myresultstable{myidx(2),end}
% The new PLS model for the secondary instrument.
slavemodel = mobj.getSlaveModelAt(modelid)
 
pause
%------------------------------------------------- 
% Further inspect results by getting the saved record for the model and
% opening the validation results in the DataSet Editor and Plotgui:
 
myrecord = mobj.lookupModelResults(modelid)
editds(myrecord.ValResultsData)
plotgui('new',myrecord.ValResultsData,'plotby',2,'viewdiag',1);
 
pause
%-------------------------------------------------
% NOTE: An accompanying interface can be started using the MCCTTool:

mtobj = MCCTTool('CalibrationMasterXData',mp6trans,'CalibrationSlaveXData',mp5trans,...
            'CalibrationYData', conctrans,'ValidationMasterXData',mp6spec,'ValidationSlaveXData',mp5spec,...
            'ValidationYData',moisture_ds, 'MasterModel',masterpls_model);


% End of MCCTOBJECTDEMO
echo off





