echo on
%FIGMERITDEMO Demo of the FIGMERIT function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% FIGMERIT Calculates analytical figures of merit for PLS and PCR models.
% This demo will use NIR spectra to estimate concentration.
 
load nir_data
whos
pause
%-------------------------------------------------
% The DataSet object (spec1) contains NIR spectra measured on
% Instrument 1. This is the X-block.
 
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
% of the PLS model. We'll extract a couple of those pieces
% for use in the FIGMERIT function.
 
% The data (not a DataSet object) are passed to FIGMERIT.
 
[nas,nnas,sens,sel] = figmerit(spec1.data, conc.data(:,1), model.reg);
 
% The inputs are the spectra ( spec1.data ),
% the concentrations ( conc.data(:,1) ), and
% the PLS regression vector ( model.reg ).
 
pause
%-------------------------------------------------
% The first output is the matrix of net analyte signals (nas) for each
% row of (x)
 
plot(spec1.axisscale{2},nas(1,:)), hline
title('Net Analyte Signal for Sample 1')
pause
%-------------------------------------------------
% The second output is the norm of the net analyte signal for each row
% (nnas). However, it includes the sign of the prediction. The sign indicates
% if the projection onto the regression vector is positive or negative. In
% this example, all of the signs are positive because we did a force-fit
% through zero by not mean-centering.
 
bar(nnas), hline
title('Norm (w/ sign) of the Net Analyte Signal for all Samples')
pause
%-------------------------------------------------
% The third output is a matrix of sensitivities for each sample (sens).
% This is the NAS divided by the concentration.
 
plot(spec1.axisscale{2},sens(1,:)), hline
title('Sensitivity for Sample 1')
pause
%-------------------------------------------------
% The last output is a vector of selectivities for each sample (sel).
% The selectivity is positive regardless of the sign of (nnas). The
% selectivity is abs(nnas)/norm(x(i,:));
 
bar(sel)
title('Selectivity for all Samples')
 
%End of FIGMERITDEMO
 
echo off
