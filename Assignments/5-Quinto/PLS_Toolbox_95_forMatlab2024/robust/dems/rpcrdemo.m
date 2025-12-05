echo on
% RPCRDEMO Demo of the RPCR function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
 
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
% Normally we would remove some known outliers from xblock1 and examine its
% contents but robust PCR will take care of this for us.
 
%xblock1 = delsamps(xblock1,[73 278 279])
 
% Note that the data is 300x20, but includ{1} is now length 297
% since 3 samples have been "soft deleted".
 
pause
%-------------------------------------------------
% The PCR function will be used to construct the PCR model.
%
% To get the options for this function run
 
options = pcr('options')
 
pause
%-------------------------------------------------
% The options structure has the following settings:
%
%       display: [ 'off' | {'on'} ]      governs level of display to command window.
%         plots: [ 'none' | {'final'} ]  governs level of plotting.
% outputversion: [ 2 | {3} ]             governs output format.
% preprocessing: {[] []}                 preprocessing structures for x and y (see PREPROCESS).
%     algorithm: [{'svd'} | 'robustpcr'] governs which algorithm to use.
%  blockdetails: [ {'standard'} | 'all' ]   Extent of predictions and raw residuals  
%                 included in model. 'standard' = only y-block, 'all' x and y blocks
% 
% Turn off "display" and "plots"
% Set algorithm to "robustpcr"
 
options.display = 'off';
options.plots   = 'none';
options.algorithm = 'robustpcr';
 
pause
%-------------------------------------------------
% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the PLS function. Preprocessing
% can be performed explicitly at the command line, but this allows the
% PLS function to perform preprocessing automatically during calibration
% and application to new data. The standard preprocessing structure will
% become a part of the standard model structure output by PLS. Note that
% you must choose preprocessing methods appropriate to robust methods.
% **********************
 
pre = preprocess('default','median center');
options.preprocessing{1} = pre;   %x-block
options.preprocessing{2} = pre;   %y-block
 
% Note that a preprocessing structure is required for both the
% x-block and y-block.
 
pause
%-------------------------------------------------
% To perform cross-validation it might be called using the following:
% 
% [press,cumpress,rmsecv] = crossval(xblock1,yblock1,'pcr',{'con', 10},12,1,{pre pre});
%
% But we'll skip that for this demo. See LINMODELDEMO.
 
pause
%-------------------------------------------------
% Now call the PCR function to calibrate the model with 6 PC's
 
rmodel = pcr(xblock1,yblock1,6,options)
makeplot(rmodel.detail.robustpcr) 
pause 
%-------------------------------------------------
% Predictions for new data can be made by calling the PCR function
% with the model as an input. Note again that the preprocessing of
% the new data will be handled by the PCR function because it is now
% a part of the model.
 
% If the validation set did not have the known reference values (yblock2)
% and only had the x-block (xblock2) then the call to PCR would be
%
rpred  = pcr(xblock2,rmodel,options);
 
pause
%-------------------------------------------------
% However, we have both xblock2 and yblock2 so we can call PCR
% to validate the model
 
rvalid = pcr(xblock2,yblock2,rmodel,options);
 
pause
%-------------------------------------------------
% And plot the results
 
figure
plot(yblock2.data(:,1),'-b','linewidth',2), hold on
plot(rvalid.pred{2},'or','markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1]), hold off
xlabel('Sample Number (time)')
ylabel('Known and Estimated Y (inches)')
legend('Known','Estimated',2)
 
%End of PCRDEMO
%
%See also: ROBPCA
 
echo off
