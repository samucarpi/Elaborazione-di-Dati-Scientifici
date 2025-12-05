echo on
% ENSEMBLEDEMO Demo of the ENSEMBLE function
 
echo off
%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
clear ans
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load data:
% The data consists of two predictor x-blocks and two
% predicted y-blocks. The data are in DataSet objects.
% xblock1 and yblock1 will be used for calibration and
% xblock2 and yblock2 will be used for validation.
 
load plsdata
whos
 
pause
%-------------------------------------------------
% Remove some known outliers from xblock1 and examine its contents
 
xblock1 = delsamps(xblock1,[73 278 279]);
yblock1 = delsamps(yblock1,[73 278 279]);
 
% Note that the data is 300x20, but includ{1} is now length 297 since three
% samples have been "soft deleted".
 
pause
%-------------------------------------------------
% Ensembles are a collection of what's called child models. Child models
% are independently calibrated models and can be of any model type. In this
% demo, we'll explore building an ensemble by first generating three child
% models using PLS, MLR, and ANN. Child models can vary by model type, and
% also by different sets of variables that are used in each model. This
% demo uses ensemble 'fusion', which just takes the aggregation of the
% child model's predictions and requires that each child model is
% calibrated on the same sample set.

% To get the options for each of the child models run
 
options1 = pls('options');
options2 = mlr('options');
options3 = ann('options');
 
pause
%-------------------------------------------------
% Initialize options for each of these model types.
%
% Turn off "display" and "plots"
 
options1.display = 'off'; options1.plots   = 'none';
options2.display = 'off'; options2.plots   = 'none';
options3.display = 'off'; options3.plots   = 'none';
 
pause
%-------------------------------------------------
% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the each of the models.
 
pre = preprocess('default','mean center');
options1.preprocessing{1} = pre;   %x-block
options1.preprocessing{2} = pre;   %y-block
options2.preprocessing{1} = pre;   %x-block
options2.preprocessing{2} = pre;   %y-block
options3.preprocessing{1} = pre;   %x-block
options3.preprocessing{2} = pre;   %y-block
 
% Note that a preprocessing structure is required for both the
% x-block and y-block.
 
pause
%-------------------------------------------------
% Now calibrate each of the child models
 
model1 = pls(xblock1,yblock1,3,options1);
model2 = mlr(xblock1,yblock1,options2);
model3 = ann(xblock1,yblock1,2,options3);
 
pause
%-------------------------------------------------
% To perform cross-validation it might be called using the following:
% 
model1 = model1.crossvalidate(xblock1,{'vet' 5 1},10);
model2 = model2.crossvalidate(xblock1,{'vet' 5 1},1);
model3 = model3.crossvalidate(xblock1,{'vet' 5 1},2);

% Because all of the child models are cross-validated, the following ensemble(s)
% will have cross-validated predictions and RMSECV recorded in the model object.
 
pause
%-------------------------------------------------
% We have both xblock2 and yblock2 so we can validate each of the
% models. This will be handy to compare how each individual model performs
% on the test set against the ensembles made in this demo.
 
valid1 = pls(xblock2,yblock2,model1,options1);
valid2 = mlr(xblock2,yblock2,model2,options2);
valid3 = ann(xblock2,yblock2,model3,options3);

pause
%-------------------------------------------------
% Now we can assemble the ensemble of the three models

ensembleoptions = ensemble('options');
ensembleoptions.aggregation = 'mean'; % 'mean' 'median' 'jackknife'
models = {model1 model2 model3};
ensemblemodel = evrimodel('ensemble');
ensemblemodel.models = models;
ensemblemodel.options = ensembleoptions;
ensemblemodel = ensemblemodel.calibrate;

pause
%-------------------------------------------------
% We can call ENSEMBLE to validate the model

ensemblepred = ensemble(xblock2,yblock2,ensemblemodel,ensembleoptions)

pause
%-------------------------------------------------
% And plot the results
 
figure
scatter(yblock2.data,valid1.pred{2},90,'filled','MarkerFaceAlpha',0.6)
hold on
scatter(yblock2.data,valid2.pred{2},90,'filled','MarkerFaceAlpha',0.6)
hold on
scatter(yblock2.data,valid3.pred{2},90,'filled','MarkerFaceAlpha',0.6)
hold on
scatter(yblock2.data,ensemblepred.pred{2},90,'filled','MarkerFaceAlpha',0.6)
dp
legend({['Model 1: RMSEP= ' num2str(valid1.detail.rmsep(valid1.ncomp))] ...
        ['Model 2: RMSEP= ' num2str(valid2.detail.rmsep(valid2.ncomp))] ...
        ['Model 3: RMSEP= ' num2str(valid3.detail.rmsep(valid3.ncomp))] ...
        ['Ensemble: RMSEP= ' num2str(ensemblepred.detail.rmsep)]}, ...
      'Location','Southeast')
xlabel('Y Measured')
ylabel('Y Predicted')
title('Ensemble of PLS, MLR, and ANN')

pause
%-------------------------------------------------
% We can also automate the search of finding the best ensemble of models
% using a nchoosek approach with the ensemblesearch method.
% It finds the best ensemble from the provided child models. The algorithm
% uses an nchoosek approach to create and test the performance of every
% combination of ensembles from size mink to maxk. Ensemble ambiguities are
% also calculated for each ensemble, which is a measure of diversity within
% an ensemble. It is recommended to pick the ensemble with the lowest
% error, minimal overfitting, and high diversity.
 
results = ensemblesearch(models,2,3,'mean'); % can use 'mean' or 'median'
plotgui('viewlabels',1)
legend

pause
%-------------------------------------------------
% The best ensemble from ensemblesearch returns the model with the lowest
% RMSECV. However, this may not be the best option if either that model is
% high in overfit or has a low ambiguity score. For example, when doing the
% ensemble search with a mean aggregation, the 'best' model returned from
% the search uses all three models. However, by looking at the plot it 
% might be better to use an ensemble that just uses PLS and ANN (models 1 
% and 3) as this ensemble has lower overfit and almost the same ambiguity 
% as the ensemble using all three models. 

models = {model1 model3};
ensemblemodel_postSearch = evrimodel('ensemble');
ensemblemodel_postSearch.models = models;
ensemblemodel_postSearch.options = ensembleoptions;
ensemblemodel_postSearch = ensemblemodel_postSearch.calibrate;
ensemblemodel_postSearchPred = ensemblemodel_postSearch.apply(xblock2,yblock2);

% Below are all of the RMSEPs from every model in this demo:
echo off
disp('RMSEPs:')
disp(['PLS: ' num2str(valid1.detail.rmsep(valid1.ncomp))])
disp(['MLR: ' num2str(valid2.detail.rmsep(valid2.ncomp))])
disp(['ANN: ' num2str(valid3.detail.rmsep(valid3.ncomp))])
disp(['ENSEMBLE with all 3 models: ' num2str(ensemblepred.detail.rmsep(end))])
disp(['ENSEMBLE after ensemblesearch, using PLS and ANN: ' num2str(ensemblemodel_postSearchPred.detail.rmsep(end))])
echo on

pause
%-------------------------------------------------
%End of ENSEMBLEDEMO
 
echo off
