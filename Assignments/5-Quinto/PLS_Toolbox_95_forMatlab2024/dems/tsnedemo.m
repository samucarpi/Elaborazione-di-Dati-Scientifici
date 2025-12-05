echo on
%TSNEDEMO Demo of the TSNE function

echo off
%Copyright Eigenvector Research, Inc. 2021
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%smr

echo on

%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load data:
 
load arch
 
disp(arch.description)
 
pause
%-------------------------------------------------
% To construct a 2 Component TSNE model with plots and display
% to the command line, type >>options = tsne('options');model = tsne(arch,options); .
%
% For this example we'll turn off the plots, but leave
% the display on.
%
 
options = tsne('options');  % constructs a options structure for TSNE
options.perplexity = 10;
%options.warnings  = 'on';       % 'on' or 'off'

 
pause
%-------------------------------------------------
% We'll create a standard preprocessing structure to
% allow the TSNE function to do autoscaling for us.
%
 
options.preprocessing = preprocess('default','autoscale'); %structure array
 
pause
%-------------------------------------------------
% Call the TSNE function and create the model.
% (model) is a structure array that contains all
% the model parameters.
%

model = evrimodel('tsne');
model.options = options;
model.x = arch;
calibrated_model = model.calibrate;
embeddings = calibrated_model.detail.tsne.embeddings;
embdso = dataset(embeddings);
embdso.class{1} = arch.class{1};


pause
%-------------------------------------------------
% Examine the plot of the embeddings
% Take a look at Column 1 against Column 2. This is how TSNE decomposed the
% data into the new lower-dimensional space. Ideally, we hope the classes
% cluster amongst themselves tightly and the classes are well separated
% from other classes. Notice, the samples with a unassigned class were able
% to cluster nicely into a few of the known classes.


plotgui(embdso,'viewclasses',1);

%End of TSNE demo
echo off







 