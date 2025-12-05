echo on
% ANNDLDEMO Demo of the ANNDL function

echo off
%Copyright Eigenvector Research, Inc. 2021
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
% The data consists of a x-block (Tecator, as a dataset object) and a
% y-block (Conc, as a dataset object). We will perform a random split to
% create a cal/val set. We will set a random seed for this, while also
% storing the first column of the Conc block as the y (fat content), since
% this is what we would like to predict.

load tecator
whos

pause
%-------------------------------------------------
% The ANN function will be used to construct the ANN model.
%
% To get the options for this function run


options = anndl('options');
options.algorithm = 'sklearn'; % 'sklearn' or 'tensorflow'
%options.warnings = 'on';       % 'on' or 'off'

pause
%-------------------------------------------------
% See "anndl help" to get the valid settings for these options.
%

% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the ANNDL function. Preprocessing
% can be performed explicitly at the command line, but this allows the
% ANN function to perform preprocessing automatically during calibration
% and application to new data. The standard preprocessing structure will
% become a part of the standard model structure output by ANN.

options.preprocessing{1} = {'derivative' 'snv' 'mean center'};   %x-block
options.preprocessing{2} = {'autoscale'};                        %y-block

pause
%-------------------------------------------------
% Now call the ANN function to build the model using the default back
% propagation network with one hidden layer and the specified number of nodes

model = evrimodel('anndl');
model.x = Xcal;
model.y = Ycal(:,2);
switch options.algorithm
  case 'sklearn'
    options.sk.solver = 'lbfgs';
    options.sk.hidden_layer_sizes = {10 10 10};
    options.sk.activation = 'tanh';
    %options.sk.tol = 1e-5;
    nhid1 = options.sk.hidden_layer_sizes{1};
  case 'tensorflow'
    options.tf.hidden_layer{1} = struct('type','Dense','units',100);
    nhid1 = options.tf.hidden_layer{1}.units;
end
model.options = options;
model = model.calibrate;

pause
%-------------------------------------------------
% Get cross-validation results. Use crossvalidate(x, cvi, ncomp)
model = model.crossvalidate(Xcal, {'con', 5}, nhid1); % slow for large nhidcv

% Cross-validation predictions are squeeze(model.detail.cvpred);

pause
%-------------------------------------------------
% Predictions for new data can be made by calling the ANNDL function
% with the model as an input. Note again that the preprocessing of
% the new data will be handled by the ANNDL function because it is now
% a part of the model.

% If the validation set did not have the known reference values (y_val)
% and only had the x-block (x_val) then the call to ANNDL would be
%

pred = model.apply(Xtest);

pause
%-------------------------------------------------
% However, we have both xblock2 and yblock2 so we can call ANN
% to validate the model

valid = model.apply(Xtest, Ytest(:,2));
pause
%-------------------------------------------------
% And plot the results, showing y known and y predicted for the validation data

figure
plot(Ytest(:,2).data(:,1),'-b','linewidth',2), hold on
plot(valid.pred{2},'or','markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1]), hold off
title(sprintf('ANNDL(%s):   RMSEP = %4.4g', options.algorithm, valid.detail.rmsep(nhid1)))
xlabel('Validation Sample Number')
ylabel('Known and Estimated Y')
legend('Known','Estimated','Location','northwest')

pause
%-------------------------------------------------
% Plot y known versus y predicted for the validation data

figure
plot(Ytest(:,2).data(:,1),valid.pred{2}, 'b.')
xlabel('test y')
ylabel('pred y')
title(sprintf('ANNDL(%s)    RMSEP = %4.4g', options.algorithm, valid.detail.rmsep(nhid1)));
abline(1,0)

% %End of ANNDLDEMO
echo off

