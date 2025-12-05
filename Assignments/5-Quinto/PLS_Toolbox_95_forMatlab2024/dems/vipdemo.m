echo on
% VIPDEMO Demo of the VIP function
 
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
 
xblock1 = delsamps(xblock1,[73 278 279]);
 
% Note that the data is 300x20, but includ{1} is now length 297
% since 3 samples have been "soft deleted".
 
pause
%-------------------------------------------------
% The PLS function will be used to construct the PLS model.
%
% To get the options for this function run
 
options = pls('options');
 
pause
%-------------------------------------------------
% See "pls help" to get the valid settings for these options.
%
% Turn off "display" and "plots"
 
options.display = 'off';
options.plots   = 'none';
 
pause
%-------------------------------------------------
% PREPROCESS will be used to construct a standard proprocessing
% structure that can be used directly by the PLS function. Preprocessing
% can be performed explicitly at the command line, but this allows the
% PLS function to perform preprocessing automatically during calibration
% and application to new data. The standard preprocessing structure will
% become a part of the standard model structure output by PLS.
 
pre = preprocess('default','mean center');
options.preprocessing{1} = pre;   %x-block
options.preprocessing{2} = pre;   %y-block
 
% Note that a preprocessing structure is required for both the
% x-block and y-block. See PLSDEMO for more information on
% inverse least squares regression with PLS.
 
pause
%-------------------------------------------------
% Now call the PLS function to calibrate the model with 3 LV's
 
model = pls(xblock1,yblock1,3,options);
 
pause
%-------------------------------------------------
% The Variable Importance in Projection (vip) is calculated using the
% calibration X-block and corresponding model as

[vip_s] = vip(model);
 
pause
%-------------------------------------------------
% And plot the results
 
figure
plot(1:20,vip_s,'-bo'),hold on
text((1:20)+0.2,vip_s,xblock1.label{2})
xlabel('Variable Number (thermocouple number)')
ylabel('Variable Importance')
 
% The importance is plotted for each variable.
 
%End of VIPDEMO
 
echo off
