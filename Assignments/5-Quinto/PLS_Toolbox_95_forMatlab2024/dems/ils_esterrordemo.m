echo on
% ILS_ESTERRORDEMO Demo of the ILS_ERROR, ERRORBARS and PCR functions
% Modified version of PCRDEMO
 
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
 
% Remove known outliers from xblock1.
% Although the data is 300x20, the includ{1} is length 297
% since 3 samples are "soft deleted".
 
load plsdata
xblock1 = delsamps(xblock1,[73 278 279]);
whos
 
pause

%-------------------------------------------------
% The PCR and PLS functions will be used to construct regression models.
 
opts_pcr = pcr('options'); % Gets an options structure for this the PCR function
opts_pls = pls('options'); % Gets an options structure for this the PLS function
opts_cv  = crossval('options'); %options structure for crossval
 
% See "pcr help" and "pls help" to get the valid settings for these
% options.
% Turn off "display" and "plots"
 
opts_pcr.display = 'off';   opts_pls.display = 'off';
opts_pcr.plots   = 'none';  opts_pls.plots   = 'none';
opts_cv.display  = 'off';
opts_cv.plots    = 'none';
 
pause
%-------------------------------------------------
% PREPROCESS will be used to construct a standard proprocessing
% structure that is used directly by the PCR and PLS functions.
% Preprocessing can be performed explicitly at the command line, but
% including as part of modeling allows the PCR and PLS
% functions to perform preprocessing automatically during calibration
% and application to new data. The standard preprocessing structure
% becomes a part of the standard model structure output by PCR and PLS.
 
pre = preprocess('default','mean center');
opts_pcr.preprocessing{1} = pre; opts_pls.preprocessing{1} = pre;  %x-block
opts_pcr.preprocessing{2} = pre; opts_pls.preprocessing{2} = pre;  %y-block
opts_cv.preprocessing = {pre pre};  
 
% Note that a preprocessing structure is required for both the
% x-block and y-block.
 
pause
%-------------------------------------------------
% To perform cross-validation it might be called using the following:
 
[press,cumpress,pcr_rmsecv] = crossval(xblock1,yblock1,'pcr',{'con', 10},12,opts_cv);
[press,cumpress,pls_rmsecv] = crossval(xblock1,yblock1,'pls',{'con', 10},12,opts_cv);
 
pause
%-------------------------------------------------
% Now call the PCR and PLS function to calibrate the model with
% 6 PC's and 3 LV's respectively.
 
mod_pcr = pcr(xblock1,yblock1,6,opts_pcr);
mod_pcr.detail.rmsecv = pcr_rmsecv;
mod_pls = pls(xblock1,yblock1,3,opts_pls);
mod_pls.detail.rmsecv = pls_rmsecv;
 
pause
%-------------------------------------------------
% Predictions for new data can be made by calling the PCR and PLS
% functions with the model as an input. Note again that the
% preprocessing of the new data will be handled by the function
% because it is now a part of the model.
 
val_pcr = pcr(xblock2,yblock2,mod_pcr,opts_pcr);
val_pls = pls(xblock2,yblock2,mod_pls,opts_pls);
err_pcr = ils_esterror(mod_pcr,val_pcr);
err_pls = ils_esterror(mod_pls,val_pls);
 
pause
%-------------------------------------------------
% And plot the results
figure
axis([19.8 21 19.8 21]), set(gca,'box','on')
hold on, set(dp,'linewidth',2,'color',[0 0 1])
plot(yblock2.data(:,1),val_pcr.pred{1,2},'or', ...
  'markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1])
errorbars(yblock2.data(:,1),val_pcr.pred{1,2},0.01,err_pcr), hold off
xlabel('Known Y (inches)'), ylabel('Estimated Y (inches)'), title('PCR Results')

figure
axis([19.8 21 19.8 21]), set(gca,'box','on')
hold on, set(dp,'linewidth',2,'color',[0 0 1])
plot(yblock2.data(:,1),val_pls.pred{1,2},'or', ...
  'markerfacecolor',[1 0 0],'markeredgecolor',[1 1 1])
errorbars(yblock2.data(:,1),val_pls.pred{1,2},0.01,err_pls), hold off
xlabel('Known Y (inches)'), ylabel('Estimated Y (inches)'), title('PLS Results')
 
%End of ILS_ESTERRORDEMO
 
echo off
