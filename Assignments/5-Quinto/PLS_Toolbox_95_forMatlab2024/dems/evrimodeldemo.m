echo on
% EVRIMODELDEMO Demo of the EVRIModel Object
 
echo off
% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% EVRIModel Objects (aka Model Objects) provide access to the Standard
% Model Structure content of all models and provide some easy-to-use
% methods and properties for building, manipulating, and reviewing models
% from Matlab's command line, scripts, and functions.
%
% This demo shows how to build (calibrate) a model, interrogate the
% calibrated model, and apply that model to new data (make a prediction)
% using only the EVRIModel object properties and methods.
 
pause
%-------------------------------------------------
% An empty model object can be created by calling the evrimodel command or
% the modelstruct command (both do the same thing). The only input is the
% string defining the model type to create. For example, here we will
% create a PLS model type.
 
model = evrimodel('pls');
 
pause
%-------------------------------------------------
% And we can look at this model...
 
model
 
pause
%-------------------------------------------------
% Note that there are 6 fields: x, y, ncomp, options, plots and display.
% To build a model, we need to assign values for x, y, and ncomp. Plus we
% can optionally assign values for the options (such as the preprocessing).
% Here we'll use the "plsdata" demo data which contains xblock1 and yblock1
% for the calibration x and y data. We'll ask for a 3 latent variable model
% and set the preprocessing to be 'autoscale' on both X and Y
 
load plsdata
model.x = xblock1;
model.y = yblock1;
model.ncomp = 3;
model.options.preprocessing = {'autoscale' 'autoscale'};
 
pause
%------------------------------------------------
% Now we're ready to build the model, which we do by simply using the
% "calibrate" method on the model object. If we wanted to keep a copy of
% the "uncalibrated" model around, we could give a new variable name to
% which the calibrated model would be assigned, or we can omit that and the
% calibrated model will simply take the place of the uncalibrated model.
 
model = model.calibrate;

pause
%------------------------------------------------
% We can see that "model" is now calibrated by simply looking at the
% .iscalibrated field:
 
model.iscalibrated
 
pause
%------------------------------------------------ 
% Or we could look at the entire model contents just giving the model name:
 
model
 
pause
%------------------------------------------------ 
% Note the description of the model now includes all of the calibration
% details indicating it is now "calibrated"
 
pause
%------------------------------------------------ 
% With this newly calibrated model, we can request things like scores
% plots:
 
model.plotscores
 
pause
%------------------------------------------------ 
% Or the Q residuals for the first 5 samples:
 
model.q(1:5)
 
pause
%------------------------------------------------ 
% Or the prediction (in this case, with a regression model, the
% "prediction" will be the y_hat values which are the y-block estimates)
 
model.prediction(1:5)
 
pause
%------------------------------------------------ 
% We can also "apply" this model to new data using the .apply method and
% passing the data we want to apply the model to (xblock2, in this case)
 
pred = model.apply(xblock2);
 
pause
%------------------------------------------------ 
% We can see this is a "prediction" by looking at the .isprediction
% property:
 
model.isprediction
pred.isprediction
 
pause
%------------------------------------------------ 
% If we are applying a regression model (as we are in this case), we can
% also pass the "measured" y-block values so that we can get RMSEP and
% other information in our plots/etc.
 
test = model.apply(xblock2,yblock2);
 
pause
%------------------------------------------------ 
% The contents of either of these two "predictions" can be interrogated and
% viewed just like the primary model, except that the returned plots and
% values will be for the prediction data (xblock2) instead of the
% calibration data. The one exception is that the scores plots will include
% BOTH the calibration and prediction data, and any property which is not
% recalculated by the prediction step (e.g. loadings) will also be
% unchanged after model application.
 
pause
%------------------------------------------------
 
pred.plotscores
 
pred.Q(1:5)
 
pred.prediction(1:5)
 
pause
%------------------------------------------------
% Model objects can have a large range of different properties that depend
% on the model type. These are described in the documentation pages of the
% different methods (e.g. see the help for pls), plus on the help page for
% modelstruct (an alternate entry point to build an EVRIModel object). See
% the documentation pages for those functions to get more information on
% the model structure and using EVRIModel objects.
 
evrihelp('evrimodel_objects');

%End of EVRIMODEL DEMO
echo off
