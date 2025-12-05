echo on
%GASELCTRDEMO Demo of the GASELCTR function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% GASELCTR performs genetic algorithm variable selection in an attempt to
% improve the fit of a model. The following shows how to run a simple
% "default" Genetic Algorithm analysis. First, load data of interest.
 
load plsdata
whos
 
pause
%-------------------------------------------------
% To get accurate results, the data should be preprocessed as it would be
% for a final model. In some cases, preprocessing can be done before the
% GA. However, because GASELCTR uses cross-validation to determine the fit
% of each model, it is sometimes better to have genalg do the preprocessing
% on-the-fly (as it tests different models). Unfortunately, this slows the
% analysis. Here we'll preprocess in advance to speed up the example.
% Autoscale the xblock (USEFUL HINT: Even if you are not going to use
% autoscaling in your final model, using it before a GA run sometimes makes
% bad variables look REALLY bad!)
 
xblock1 = preprocess('calibrate','autoscale',xblock1);
 
pause
%-------------------------------------------------
% The default options for a GA run can be obtained by requesting them from
% the gaselctr routine.
 
options = gaselctr('options');
 
pause
%-------------------------------------------------
% This options structure contains many genetic algorithm settings. See the
% manual pages ('gasecltr help') for gaselctr and genalg for more
% information on these settings. You may also find the GENALG (see genalg)
% interface another useful resource for setting these options:
 
options
 
pause
%-------------------------------------------------
% The call to gaselctr is then simply to pass the data of interest and the
% options structure obtained previously:
 
model = gaselctr(xblock1,yblock1,options);
 
% The final figure shows the fit as a function of total number of included
% variables (top left plot), the most commonly selected variables (bottom
% right), as well as the improvement in fit with each generation (top
% right). 
pause
%-------------------------------------------------
% We can also see the final results in the output model
 
model
 
% The model.icol and model.rmsecv columns indicate the included variables
% and resulting fit of the final sets of selected variables. 
% model.rmsecv are sorted increasing from smallest RMSECV and the rows of
% model.icol are sorted correspondingly. Thus the final population member
% with the smallest RMSECV uses variables indicated by '1' in
% model.icol(1,:).  Note, however, that there usually isn't a clear single 
% best model. GA variable selection should be considered to suggest several 
% models which give good results. 
% See theGENALGPLOT demo for another way to view these results.
 
%End of GASELCTRDEMO
 
echo off
