echo on
% NIPPLSDEMO Demo of the NIPPLS function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
%nbg 8/02 slight mod
 
clear ans
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load data:
% This data consists of two predictor x-blocks
% and two predicted y-blocks.
 
 
load plsdata
xblock1 = xblock1.data;
yblock1 = yblock1.data;
xblock2 = xblock2.data;
yblock2 = yblock2.data;
 
whos
 
pause 
%-------------------------------------------------
% We will use the NIPPLS function to build a PLS model 
%  from xblock1 and yblock1. First, we need to preprocess
%  the inputs appropriately. We'll use mean centering here.
 
[xblock1,mnx] = mncn(xblock1);
[yblock1,mny] = mncn(yblock1);
 
pause
%-------------------------------------------------
%Now we do the models, asking all models up to 5 
% latent variables (LVs).
 
[b,ssq,p,q,r,t,u,v] = nippls( xblock1, yblock1, 5);
 
pause
%-------------------------------------------------
% Each row of "b" represents a regression vector 
%  for one of the models using from 1 LV to 5 LVs.
 
size(b)
 
% We can make predictions for new data by multiplying
%  our new x-block by the transpose of any of the rows 
%  of the b array.
 
pause
%-------------------------------------------------
% Lets do that with our validation x-block (xblock2) 
%  for all the models.
%
% Note that the xblock2 needs to be scaled the same as
%  the original xblock1 and we need to "rescale" (undo
%  the scaling) the predictions back to the original 
%  units.
 
xblock2 = scale(xblock2, mnx);            %scale new x-block like old one
pred2   = xblock2 * b';                   %do predictions for all 5 models
pred2   = rescale(pred2, mny*ones(1,5));  %un-scale predicted y
 
pause
%-------------------------------------------------
% and then calculate Root Mean Standard Error of Prediction
%  (RMSEP) using the measured y-block and the prediction results:
 
rmsep = sqrt(mean(( pred2 - yblock2*ones(1,5) ).^2))
 
pause
%-------------------------------------------------
%and do a plot of RMSEV:
 
figure
plot(1:5,rmsep,'-s');
xlabel('Number of Latent Variables')
ylabel('RMSEP')
shg
 
%
%End of NIPPLSEMO
 
echo off
