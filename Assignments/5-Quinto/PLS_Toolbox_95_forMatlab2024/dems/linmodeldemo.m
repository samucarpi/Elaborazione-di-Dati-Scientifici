echo on
% LINMODELDEMO Demo of the CROSSVAL, MODLRDER, PCR, PLS, PREPROCESS and SSQTABLE functions
 
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
%
% Note also that the outliers do not need to be deleted from the
% y-block (they could if desired). This is because the PCR and PLS
% functions will use the intersection of the .includ fields for
% mode 1 from the x- and y-blocks during the calibration step.
 
pause
%-------------------------------------------------
% The PCR and PLS functions will be used to construct linear regression models.
%
% To get the options for these functions run
 
optionspcr = pcr('options');
optionspls = pls('options');
 
pause
%-------------------------------------------------
% The options structure for PLS (optionspls) has the following settings:
%
%       display: [ 'off' | {'on'} ]      governs level of display to command window.
%         plots: [ 'none' | {'final'} ]  governs level of plotting.
% outputversion: [ 2 | {3} ]             governs output format.
% preprocessing: {[] []}                 preprocessing structures for x and y (see PREPROCESS).
%     algorithm: [ 'nip' | {'sim'} ]     PLS algorithm to use: NIPALS or SIMPLS
%  blockdetails: [ {'standard'} | 'all' ]   Extent of predictions and raw residuals  
%                 included in model. 'standard' = only y-block, 'all' x and y blocks
 
% and the options structure for PCR (optionspcr) has the following settings:
%
%       display: [ 'off' | {'on'} ]      governs level of display to command window.
%         plots: [ 'none' | {'final'} ]  governs level of plotting.
% outputversion: [ 2 | {3} ]             governs output format.
% preprocessing: {[] []}                 preprocessing structures for x and y (see PREPROCESS).
%  blockdetails: [ {'standard'} | 'all' ]   Extent of predictions and raw residuals  
%                 included in model. 'standard' = only y-block, 'all' x and y blocks
 
pause
%-------------------------------------------------
% Turn off "display" and "plots"
 
optionspcr.display = 'off';   optionspls.display = 'off';
optionspcr.plots   = 'none';  optionspls.plots   = 'none';
 
pause
%-------------------------------------------------
% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the PCR and PLS functions.
% Preprocessing can be performed explicitly at the command line prior
% to calculating the regression models (e.g. using the AUTO and MNCN
% functions), but using the preprocessing structure allows the PCR and
% PLS functions to perform preprocessing automatically during calibration
% and application to new data.
%
% The standard preprocessing structure will become a part of the standard
% model structures output by PCR and PLS.
 
pre = preprocess('default','mean center')
 
optionspcr.preprocessing{1} = pre; optionspls.preprocessing{1} = pre;   %x-block
optionspcr.preprocessing{2} = pre; optionspls.preprocessing{2} = pre;   %y-block
 
% Note that a preprocessing structure is required for both the
% x-block and y-block.
 
pause
%-------------------------------------------------
% Perform cross-validation for both PCR and PLS. The I/O for CROSSVAL is:
%
% [press,cumpress,rmsecv,rmsec,cvpred,misclassed] = crossval(x,y,rm,cvi,ncomp,out,pre);
%
% but the interest is in the first three outputs.
 
pause
%-------------------------------------------------
% First cross-validate for PCR splitting the data into contiguous blocks
% (this is time series) with 10 data subsets i.e. cvi = {'con', 10}, and
% up to 12 principal components i.e. nocomp = 15. To make plots use out = 1
% and the preprocessing structure, for each block, is included so that each
% subset is preprocessed during the cross-validation.
  
[presspcr,cumpresspcr,rmsecvpcr] = crossval(xblock1,yblock1,'pcr',{'con', 10},15,1,{pre pre});
 
% This suggests 6 PCs.
 
pause
%-------------------------------------------------
% Now cross-validate for PLS (using the SIMPLS algorithm) splitting the data
% into contiguous blocks with 10 data subsets i.e. cvi = {'con', 10}, and
% up to 12 latent variables i.e. nocomp = 15. Again make plots i.e. out = 1,
% and the preprocessing structure, for each block, is included so that each
% subset is preprocessed during the cross-validation.
 
[presspls,cumpresspls,rmsecvpls] = crossval(xblock1,yblock1,'sim',{'con', 10},15,1,{pre pre});
 
% This suggests 3 LVs.
 
pause
%-------------------------------------------------
% Now call the PCR and PLS functions to calibrate the linear regression
% models with 6 PCs and 3 LVs.
 
modelpcr = pcr(xblock1,yblock1,6,optionspcr);
modelpls = pls(xblock1,yblock1,3,optionspls);
 
pause
%-------------------------------------------------
% Now let's examine the sum of squares captured table using the
% SSQTABLE function. The table will be printed for up to the number
% of factors retained in the PCR and PLS models.
 
ssqtable(modelpcr)
ssqtable(modelpls)
 
pause
%-------------------------------------------------
% Predictions for new data can be made by calling the PCR function
% with the model as an input. Note again that the preprocessing of
% the new data will be handled by the PCR function because it is now
% a part of the model.
 
% If the validation set did not have the known reference values (yblock2)
% and only had the x-block (xblock2) then the call to PCR and PLS would be
%
% predpcr  = pcr(xblock2,modelpcr,optionspcr);
% predpls  = pls(xblock2,modelpls,optionspls);
 
pause
%-------------------------------------------------
% However, we have both xblock2 and yblock2 so we can call PCR and PLS
% to validate the model
 
validpcr = pcr(xblock2,yblock2,modelpcr,optionspcr);
validpls = pls(xblock2,yblock2,modelpls,optionspls);
 
pause
%-------------------------------------------------
% And plot the results
 
figure
plot(yblock2.data(:,1),'-b','linewidth',2), hold on
plot(validpcr.pred{2},'or','markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1])
plot(validpls.pred{2},'sm','markerfacecolor',[1 0 1],'markeredgecolor',[1 1 1]), hold off
xlabel('Sample Number (time)')
ylabel('Known and Estimated Y (inches)')
legend('Known','PCR Estimate','PLS Estimate','Location','NorthWest')
 
% The RMSEP for each validation model is:
 
disp([validpcr.detail.rmsep(1,6), validpls.detail.rmsep(1,3)])
 
%End of LINMODELDEMO
 
echo off
