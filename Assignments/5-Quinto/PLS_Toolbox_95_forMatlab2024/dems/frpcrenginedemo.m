echo on
% FRPCRENGINEDEMO Demo of the FRPCRENGINE function
 
echo off
%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
clear ans
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% FRPCRENGINE calculates the basic parts of a full-ratio PCR model.  These
% models use a special inner-relation equation which removes the effect of
% multiplicative scaling of samples. Erroneous scaling is often observed
% with emission and scattering technqiues due to changes in throughput or
% incident intensity. FRPCR can generally be used instead of
% PCR when scaling effects are suspected as long as there are no
% "unobserved" components (That is, all components must contribute to the
% signal in the x-block and not simply "dilute" the observed signal)
%
% For more information regarding the use of full-ratio models, see FRPCRDEMO. 
pause
%-------------------------------------------------
% Load data:
% Although the plsdata does not have inherent sample scaling problems, the
% samples can be randomly scaled to show the effect of using a FRPCR model.
% The data consists of two predictor x-blocks and two
% predicted y-blocks. The data are in DataSet objects.
% xblock1 and yblock1 will be used for calibration and
% xblock2 and yblock2 will be used for validation.
 
load plsdata
 
echo off
whos
echo on
 
pause
%-------------------------------------------------
% Create a FRPCR model from the randomly scaled xblock1:
% To decrease the sensitivity of the model to scaling, FRPCRENGINE will
% automatically randomly scale the samples based on the value of the
% "pathvar" option:
 
options = frpcrengine('options');
 
options.pathvar    %what is the current fractional scaling to be used?
 
% This indicates that random 20% scaling will be used during the
% calibration.
pause
%-------------------------------------------------
% For best results, the y-block should be mean-centered. Do that now.
 
[yblock1.data,ymn] = mncn(yblock1.data);
 
pause
%-------------------------------------------------
% FRPCR models usually require at least two components
 
[b,ssq,u,sampscales,msg,options] = frpcrengine(xblock1.data,yblock1.data,3);
pause
%-------------------------------------------------
% Note that the output regression vector (b) is not a standard PCR
% regression vector but is, instead, a regression matrix which contains two
% columns used in the ratioed prediction equation.
 
size(b)
 
% To predict, we can either manually predict using these two vectors
% (followed by ratioing the resulting predictions) or we can use
% FRPCRENGINE itself to do a prediction.
 
pause
%-------------------------------------------------
% To predict for new data, FRPCRENGINE is simply called with the new data
% and the output regression vector "b". We'll then undo our mean centering
% and plot the results vs. the actual measured y-values.
 
pred2  = frpcrengine(xblock2.data,b);
pred2 = pred2 + ymn;    %"undo" mean centering for real values
 
figure
plot(yblock2.data,pred2,'.');
xlabel('Measured y-value');
ylabel('Predicted y-value');
 
% End of FRPCRENGINE demo
 
echo off
