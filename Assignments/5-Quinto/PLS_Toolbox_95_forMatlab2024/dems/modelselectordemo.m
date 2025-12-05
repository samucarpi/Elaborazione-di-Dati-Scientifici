echo on
% MODELSELECTORDEMO Demo of the MODELSELECTOR function
 
echo off
%Copyright Eigenvector Research, Inc. 2016
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
% To run the demo hit a "return" after each pause
 
pause
 
% Model Selector models (also referred  to as a Hierarchical Model) are used
% to perform decision tree operations on data. They are typically created
% using the Hierarchical Model Builder (see modelselectorgui). Building
% these models can be done from the command line. This script demonstrates
% this functionality.
 
pause
 
% A model selector model uses a "trigger" model (aka rule or decision node)
% to follow a path to either another model or an output (end point). The
% trigger can also be a simple logical test. Created below is a very simple
% test model to see if dataset with a column labeled "Column 1" has values
% equal to 1.
 
% Make a simple dataset.
 
mydata = dataset([1 0 1; 0 1 1; 1 1 1; 0 0 1; 0 0 0; 1 0 1]);
mydata.label{2} = {'Column 1' 'Column 2' 'Column 3'};
 
% Use the string "Column 1" to indicate we're looking for a label in the
% dataset and the logical argument ==1 as the test condition:
 
modelstring = {{'"Column 1"==1'} 'Col1 == 1' 'Col1 ~= 1'};
 
% Build the model:
 
mymodel = modelselector(modelstring{:});
 
% Run the model: 
 
sample_output = modelselector(mydata,mymodel);
 
% Add second rule.
 
modelstring = {{'"Column 1"==1' '"Column 2"==1'} 'Col1 == 1' 'Col2 == 1' 'Neither Column Has A One'};
mymodel = modelselector(modelstring{:});
 
sample_output = modelselector(mydata,mymodel);
  
pause
 
% Build a more complicated set of rules. The build starts from the "outer"
% or "last" rules to be applied and builds up to the first.
 
% Example data.
 
mydata = dataset(rand(100,4));
mydata.label{2} = {'A' 'B' 'C' 'D'};
 
% Outer-most rule.
 
modelstring = {{'"D">0.5'} 'D>.5' 'Otherwise 4'};
model4 = modelselector(modelstring{:});
 
% Next rule.
 
modelstring = {{'"C"<0.2' '"C">0.4' } 'C<.2' model4 'Otherwise 3'};
model3= modelselector(modelstring{:});
 
% New rule for this level.
 
modelstring = {{'"B">0.5'} 'B>.5' 'Otherwise 2'};
model2 = modelselector(modelstring{:});
 
% Combine it all.
 
modelstring = {{'"A">0.5' '"B">0.4' '"C">.5' '"D">.5'} 'A>.5' model2 'C>.5' model3 'Otherwise 1'};
model4= modelselector(modelstring{:});
 
sample_output = modelselector(mydata,model4);
 
% NOTE: The rules are applied in order so the "A">0.5 will be applied first
% followed by "B">0.4... etc.
 
pause
 
% Until now we've only had text output so the result we get is a cell array
% of strings. If we change the output to include both text and numeric data
% then the output will be a dataset object with text data included in the
% class fields. Try the last model but with a numeric output in the first
% rule ('A>.5' becomes 1):
 
% Combine it all.
 
modelstring = {{'"A">0.5' '"B">0.4' '"C">.5' '"D">.5'} 1 model2 'C>.5' model3 'Otherwise 1'};
model4= modelselector(modelstring{:});
 
sample_output = modelselector(mydata,model4);
 
% The single column of numeric data with a 1 where A is > than .5 and an NaN
% if not.
 
sample_output.data
 
% Text data will be located in the classid field. This is based on the class
% and classlookup fields. 
 
% Text results:
sample_output.classname{1}
sample_output.classid{1}'
 
% Path taken in decision tree:
 
sample_output.classname{1,2}
sample_output.classid{1,2}'
 
% Source of result, in our case this is just datatype. If the numeric source
% was a model, this would contain the modelID (unique ID string for the
% model):
 
sample_output.classname{1,3}
sample_output.classid{1,3}'
 
pause
 
% Build the hierarchical model from the online video tutorial. 
% 
%   http://www.eigenvector.com/eigenguide.php
% 
% This example will use several models and logical triggers to classify
% samples in the arch dataset.
 
load arch;
 
% Make a test dataset with the unknown samples:
 
test = arch(end-11:end,:);
 
% Create pca model of just "AN" quarry.
 
arch.classlookup{1,1}

% The "AN" quarry is class number 4 so we'll include only those samples:
 
arch.include{1,1} = find(arch.class{1}==4);
 
% Build PCA model with 2 PCs and proper options.
 
opts               = pca('options');
opts.preprocessing = {preprocess('default','autoscale')};
opts.plots         = 'none';
opts.display      = 'off';
 
an_pca_mod = pca(arch,2,opts);
 
% As a simple exercise, create a single rule model with just the PCA
% model to find AN samples:
 
modelstring = {{an_pca_mod '"Q">12'} 'Not AN' 'Is AN'};
mymodel = modelselector(modelstring{:});
sample_output = modelselector(arch,mymodel)
 
% Continue to create the models used by the video, make PLSDA models
% between quarries. 
 
arch.include{1,1}  = 1:size(arch,1);%Re-include everything.
opts               = plsda('options');
opts.preprocessing = {preprocess('default','autoscale')};
opts.plots         = 'none';
opts.display       = 'off';
 
% Build 1 LV model for BL vs K+SH. 
% NOTE: The order of the classes used to create this model is critical.
%       Below the outputs of the classification will be in the order used to
%       create this model.
 
BLvsKSH_mod        = plsda(arch,{2 [1 3]},2,opts);
 
% Build 2 LV model for K vs SH:
 
KvsSH_mod          = plsda(arch,{1 3},1,opts);
 
% Since we have error conditions defined by a structure, we'll need to pass
% modelselector options. Otherwise our error condition will be interpreted
% as options.
 
modelselector_options = modelselector('options');
 
% Change error mode to struct so errors don't cause a stop when they occur:
 
modelselector_options.errors = 'struct';
 
% K vs SH model:
 
modelstring = {KvsSH_mod 'Is K' 'Is SH' struct('error','Out of K SH MOD')};
ksh_msmod = modelselector(modelstring{:},modelselector_options);
 
% BL vs K SH model:
%  NOTE: The order of output from BLvsKSH_mod was determined above when
%  building the PLSDA model.
 
modelstring = {BLvsKSH_mod 'Is BL' ksh_msmod struct('error','Out of BL, K SH MOD')};
blksh_msmod = modelselector(modelstring{:},modelselector_options);
 
% The final (first level) model will classify all data using the PCA
% model to classify the AN quarry:
 
modelstring = {{an_pca_mod '"Q">12'} blksh_msmod 'Is AN'};
mymodel = modelselector(modelstring{:});
 
% Run this on our test ("unknown") data:
 
sample_output = modelselector(test,mymodel,modelselector_options)
 
% The output should be:
%     'Is SH'
%     'Is K'
%     'Is K'
%     'Is K'
%     'Is BL'
%     'Is BL'
%     'Is BL'
%     'Is SH'
%     'Is SH'
%     'Is SH'
%     'Is SH'
%     'ERROR: Out of BL, K SH MOD'

% Also note the model can be opened in modelselectorgui to provide a visual
% representation:
 
modelselectorgui(mymodel)
 
% End of MODELSELECTORDEMO
 
echo off


