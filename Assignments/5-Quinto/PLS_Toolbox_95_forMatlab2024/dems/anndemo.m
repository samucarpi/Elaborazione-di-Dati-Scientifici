echo on
% ANNDEMO Demo of the ANN function

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

xblock1 = delsamps(xblock1,[73 278 279])

% Note that the data is 300x20, but includ{1} is now length 297
% since 3 samples have been "soft deleted".

pause
%-------------------------------------------------
% The ANN function will be used to construct the ANN model.
%
% To get the options for this function run

rng(1);
options = ann('options')
options.algorithm = 'bpn'; %'encog', 'bpn

pause
%-------------------------------------------------
% See "ann help" to get the valid settings for these options.
%
% Turn off "display" and "plots"

options.display = 'off';
options.plots   = 'none';

pause
%-------------------------------------------------
% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the ANN function. Preprocessing
% can be performed explicitly at the command line, but this allows the
% ANN function to perform preprocessing automatically during calibration
% and application to new data. The standard preprocessing structure will
% become a part of the standard model structure output by ANN.

pre = preprocess('default','mean center');
options.preprocessing{1} = pre;   %x-block
options.preprocessing{2} = pre;   %y-block

% Note that a preprocessing structure is required for both the
% x-block and y-block.

pause
%-------------------------------------------------
% Now call the ANN function to build the model using the default back
% propagation network with one hidden layer and the specified number of nodes

model = evrimodel('ann');
model.x = xblock1;
model.y = yblock1;
% Specify 3 nodes in one hidden layer. 
% nhid2 = 0 by default. This is a neural network with only one hidden layer
nhid = 3;   % or [2 1] for 2 hidden layers, 2 nodes in first, 1 in second
model.nhid = nhid;
model.options = options;
model = model.calibrate;

pause
%-------------------------------------------------
% Get cross-validation results. Use crossvalidate(x, cvi, ncomp)
model = model.crossvalidate(xblock1, {'con', 5}, nhid(1)); % slow for large nhidcv

% Cross-validation predictions are squeeze(model.detail.cvpred);

pause
%-------------------------------------------------
% Predictions for new data can be made by calling the ANN function
% with the model as an input. Note again that the preprocessing of
% the new data will be handled by the ANN function because it is now
% a part of the model.

% If the validation set did not have the known reference values (yblock2)
% and only had the x-block (xblock2) then the call to ANN would be
%

pred = model.apply(xblock2);

pause
%-------------------------------------------------
% However, we have both xblock2 and yblock2 so we can call ANN
% to validate the model

valid = model.apply(xblock2, yblock2);
pause
%-------------------------------------------------
% And plot the results, showing y known and y predicted for the validation data

figure
plot(yblock2.data(:,1),'-b','linewidth',2), hold on
plot(valid.pred{2},'or','markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1]), hold off
title(sprintf('ANN(%s):   RMSEP = %4.4g', valid.detail.ann.W.type, valid.detail.rmsep(nhid)))
xlabel('Validation Sample Number (time)')
ylabel('Known and Estimated Y (inches)')
legend('Known','Estimated','Location','northwest')

pause
%-------------------------------------------------
% Plot y known versus y predicted for the validation data

figure
plot(yblock2.data(:,1),valid.pred{2}, 'b.')
xlabel('test y')
ylabel('pred y')
title(sprintf('ANN(%s)    RMSEP = %4.4g', options.algorithm, valid.detail.rmsep(nhid)));
abline(1,0)

% %End of ANNDEMO
echo off
