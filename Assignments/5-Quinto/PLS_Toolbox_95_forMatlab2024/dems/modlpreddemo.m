echo on
%MODLPREDDEMO Demo of the MODLPRED function
 
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
% MODLPRED can be used to get predictions, residuals, Hotelling's
% T^2 and scores for PLS and PCR models. The PLS and PCR functions
% are used when the entire model structure is desired.
 
% This demo will use NIR spectra to estimate concentration.
 
load nir_data
whos
pause
%-------------------------------------------------
% The DataSet object (spec1) contains NIR spectra measured on
% Instrument 1. This is the X-block. We'll model on the first
% 25 samples.
 
spec1.includ{1} = 1:25;
 
% The DataSet object (conc) contains the analyte concentrations
% for the 5 analytes in the pseudo-gasoline mixture. We'll just
% use the first analyte. This is the Y-block.
 
conc.includ{2} = 1;
 
pause
%-------------------------------------------------
% Next we'll construct a PLS model. The first step is to set up
% the options.
 
options         = pls('options');
options.display = 'off';
options.plots   = 'none';
 
% No preprocessing will be used. Note that without mean
% centering, the model will be a force fit through zero.
 
pause
%-------------------------------------------------
% The PLS model, with 5 latent variables, is constructed as follows:
 
model = pls(spec1,conc,5,options);
 
pause
%-------------------------------------------------
% (model) is a structure array that contains all the pieces
% of the PLS model. The PLS function calibrated on only the
% first 25 samples. This can be seen by examining the (includ)
% field.
 
model.detail.includ
 
% The cell model.detail.includ{1,1} is for the X-block rows and
% The cell model.detail.includ{1,2} is for the Y-block rows. Also,
% The cell model.detail.includ{2,1} is for the X-block columns and
% The cell model.detail.includ{2,2} is for the Y-block columns.
 
pause
%-------------------------------------------------
% Note, however that the PLS function applied the model to ALL
% the samples in the data set. This can be seen by looking at the
% (pred) field. 
 
model.pred
 
% The cell model.pred{2} contains predictions for the Y-block.
 
pause
%-------------------------------------------------
figure
plot(conc.data(1:25,1),model.pred{2}(1:25,1),'ob'), hold on
plot(conc.data(25:end,1),model.pred{2}(25:end,1),'rs'), hold off
xlabel('Known Concentration'), ylabel('Estimated Concentrations')
legend('Calibration','Test','Location','NorthWest'), dp
 
% The calibration samples are the blue circles, and the test
% samples are the red squares. (Not bad performance.)
 
% The good news is that all the data, predictions, and ancillary
% data for the model are in the single structure (model). However,
% that was a lot of typing to get at a plot of the predictions!
 
% So, let's try MODLPRED. But let's do it on the other data set
% contained in the DataSet object (spec2).
 
pause
%-------------------------------------------------
% The inputs to MODLPRED are the new data (spec1), the PLS [or PCR]
% model (model), and an optional variable (plots). We'll set (plots)
% to zero to supress plotting.
 
% The outputs are the Y-Block predictions (ypredn),
% The X-Block Q residuals and Hotelling T^2 (resn) and (tsqn), and
% The X-Block scores (scoresn).
 
plots = 0;
[yprdn,resn,tsqn,scoresn] = modlpred(spec2,model,plots);
 
pause
%-------------------------------------------------
plot(conc.data(:,1),yprdn,'rs'), dp
xlabel('Known Concentration'), ylabel('Estimated Concentrations')
 
% Those predictions don't look so hot. How about the
% Q and T^2?
 
pause
%-------------------------------------------------
loglog(tsqn,resn,'ob')
hline(model.detail.reslim{1}), vline(model.detail.tsqlim{1})
xlabel('Hotelling''s T^2'), ylabel('Q Residual')
title('X-Block Statistics with ~95% Limit Lines')
 
% The Q and T^2 are way outside our limits (that were extracted
% from the model to make the plots).
 
% So, what we see is that MODLPRED can quickly get our predictions
% and X-Block statistics. However, for this particular example the
% predictions are poor. Inspection of the X-Block statistics shows
% the the data in (spec2) don't really look like the data in (spec1).
 
% For more information about this data run STDDEMO (it'll tell you
% why the data are different and try to compensate for the difference).
 
%End of MODLPREDDEMO
 
echo off
