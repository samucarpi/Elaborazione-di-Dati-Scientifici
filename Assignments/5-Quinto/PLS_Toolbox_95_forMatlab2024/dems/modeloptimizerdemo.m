echo on
%MODELOPTIMIZERDEMO Demo of the MODELOPTIMIZER function
 
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
% MODELOPTIMIZER - Create model for iterating over analysis models.
% When called with figure handle snapshots will be taken from figure.
% After several snapshots are taken a list of unique combinations can be
% generated in the .combinations field. Combinations can then be used to
% create a list of unique snapshots know as "model runs", that will then
% be calculated.
%
% In this demo modeloptimizer will be called from the command line. The
% following code can be used as a template for creating a custom function.
% 
 
% Load a sample dataset.
load plsdata
 
pause
%-------------------------------------------------
% Let's see the impact of removing outlier samples in the PLSDATA xblock1
% dataset over a couple of different modeling conditions. 
% 
% Remove some known outliers from xblock1 and examine its contents:
 
xblock1_rm = delsamps(xblock1,[73 278 279]);
yblock1_rm = delsamps(yblock1,[73 278 279]);
 
xdata = {xblock1 xblock1_rm};
ydata = {yblock1 yblock1_rm};

%xdata = {xblock1 xblock1};
%ydata = {yblock1 yblock1};
 
% Note that the data is 300x20, but include{1} is now length 297
% since 3 samples have been "soft deleted".
 
pause
%-------------------------------------------------
 
%Clear the optimizer.
modeloptimizer('clear')
 
%Let's also look at 2 diffent kinds of preprocessing.
 
%preprocess: {xpp ypp}.
pp1 = preprocess('default', 'normalize');
pp2 = preprocess('default', 'meancenter');
mypp  = {{pp1 []} {pp2 []}};
 
%We'll also look at 2 different LVs.
ncomp = {3 4};
 
pause
%-------------------------------------------------
% Loop through 2 scenarios that will create combinations of data,
% preprocessing, and number of components for a total of 8 unique
% combinations. Note that different sizes of [included] data can not be
% combined so although there are 16 unique combinations, only 8 of those
% are valid given the data sizing.
% 
 
for i = 1:length(xdata);
  %Create a model object.
  mymodl = evrimodel('pls');
  %Add LVs (number of components).
  mymodl.ncomp = ncomp{i};
  %Add data to object.
  mymodl.x = xdata{i};
  mymodl.y = ydata{i};
  %Set preprocessing.
  mymodl.options.preprocessing = mypp{i};
  %Set crossval.
  mymodl.detail.cv = 'vet';
  mymodl.detail.split = 10;
  mymodl.iter = 1;
  %Calibrate the model.
  mymodl = mymodl.calibrate;
  %Crossvalidate the model.
  mymodl = mymodl.crossvalidate(xdata{i},{'vet' 10 1},ncomp{i});
  %Add model to cache so we can snapshot it with the data.
  modelcache(mymodl,{xdata{i} ydata{i}});
  %Add a snapshot of model to modeloptimizer.
  modeloptimizer('snapshot',mymodl);
  %Clear model.
  mymodl = [];
end

pause
%-------------------------------------------------
% Open Model Optimizer window, assemble the unique combinations, then calculate
% all models.
 
%Open the window and get its handles.
fig = modeloptimizergui;
handles = guihandles(fig);
drawnow;
 
%Add all combinations and update window.
modeloptimizer('assemble_combinations');
modeloptimizergui('update_callback',handles)
 
%Calculate models and update window again.
modeloptimizer('calculate_models')
modeloptimizergui('update_callback',handles)

pause
%-------------------------------------------------
% You can manually loop through the Model Optimizer structure and pull
% models out for further manipulation. Below is an example of pulling scores
% from each model calculated above.

mymodel = getappdata(0,'evri_model_optimizer');
myiterator    = mymodel.optimizer;%Model optimizer structure of results.

%TODO: Iterate through and add snapshots to models.
for i = 1:length(myiterator.modelrun.snapshots)
  thismodelid = myiterator.modelrun.snapshots(i).modelID;
  thismodel = modelcache('get',thismodelid);
  thismodel_scores = thismodel.scores;
end

%Other information that can be obtained from appdata:
% mytable   = getappdata(handles.modeloptimizergui,'comparetable');
% mytree    = getappdata(handles.modeloptimizergui,'modeltree');
% thistable = mytable.data;
% thiscols  = mytable.column_labels;

%Apply models to new data. 
[preds, flag1] = modeloptimizer('calculate_preds', xblock2, yblock2, {myiterator.modelrun.snapshots.modelID}');
 
%End of MODELOPTIMIZERDEMO
 
echo off

