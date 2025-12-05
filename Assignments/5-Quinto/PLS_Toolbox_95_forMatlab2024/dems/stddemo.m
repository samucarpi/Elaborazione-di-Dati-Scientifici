echo on
%STDDEMO Demo of the STDSSLCT, STDGEN, and OSCCALC functions
 
echo off
%Copyright Eigenvector Research, Inc. 1994
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%BMW 3/98, 3/99
%nbg 08/02
%nbg 03/03 "end of demo missing" - fixed it up
%nbg 03/05 end of demo messed up, fixed, "and added ridging"
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% This demo uses NIR spectrometer data from two instruments
% measured on the same samples.
 
% First the data will be loaded and plotted.
 
load nir_data
 
echo off
figure
plot(spec1.axisscale{2,1},spec1.data,'-r', ...
     spec1.axisscale{2,1},spec2.data,'-b')
title('NIR Spectra'), xlabel('Wavelength (nm)'), ylabel('Absorbance')
text(825,1.75,'Instrument 1 spectra shown in red','fontsize',14)
text(850,1.5,'Instrument 2 spectra shown in blue','fontsize',14)
 
echo on
% This plot shows both sets of spectra. Here they do not
% look all that different, so lets plot the difference.
pause
%-------------------------------------------------
echo off
plot(spec1.axisscale{2,1},spec1.data-spec2.data,'r'), hline
title('Difference between NIR Spectra from Instruments 1 and 2')
xlabel('Wavelength (nm)'), ylabel('Absorbance Difference')
 
echo on
% Now the difference is much more apparent.
 
% Next we'll calibrate PLS models to predict the concentration
% of each of the 5 analytes in the mixtures. We'll make 5 models.
% Each model will use the spectra from Instrument 1 as the
% predictor block i.e. the X-block. The 5 Y-blocks will consist
% of vectors of the known concentrations of the analytes.
 
% Later, we'll use the models along with the transformed spectra
% from Instrument 2. We will not attempt to optimize the models
% for this excercise. Instead, we will just use 5 LVs in each one,
% since we know the spectra should have a true rank of 5 beause
% there are 5 analytes varying in the mixture.
pause
%-------------------------------------------------
echo off
options         = pls('options');
options.display = 'off';
options.plots   = 'none';
pre             = preprocess('default','mean center');
options.preprocessing = {pre pre};
fit             = zeros(30,5);
 
for ii=1:5  % FOR loop to create models
  conc.includ{2,1} = ii;          %select only column ii of conc.data
  model{ii}     = pls(spec1,conc,5,options);
  fit(:,ii)     = model{ii}.pred{2};
end
 
echo on
% Now that we have the models, we can look at the actual
% concentrations and the fit based on the PLS model.
pause
%-------------------------------------------------
echo off
plot(conc.data,fit,'o'), dp, axis([0 50 0 50])
title('Fit vs Actual Concentrations Based on Instrument 1')
xlabel('Actual Analyte Concentration')
ylabel('Analyte Concentration Fit')
text(1,45,'Each analyte shown as different color','FontSize',14)
 
echo on
% You can see that our PLS models, all based on 5 LVs, fit the data
% quite well.  Now we will use the STDSSLCT function for selecting
% samples with high leverage to use for calibration transfer. We
% will select 5 samples out of the 30 available for calculating
% the transform between instruments.
pause
%-------------------------------------------------
% To select the samples, we'll estimate the leverage based on
% the pseudo-inverse used by the PLS model. We have five models to 
% choose from, lets just use the one for the first analyte.
 
rinv = rinverse(model{1},5);
 
% Now that we have the inverse we can select the subset.
pause 
%-------------------------------------------------
[specsub,ipds] = stdsslct(spec1.data,5,rinv); %ipds indices of selected spectra
 
% Oddly enough, direct standardization works better when the
% samples are chosen based on distance from the mean. Thus, we
% can use the subset selection function to choose transfer
% samples for the direct standardization method as follows:
 
[specsub,ids] = stdsslct(spec1.data,5); %ids indices of selected spectra
 
pause
%-------------------------------------------------
% We can now use these subsets of samples to calculate the intrument
% transform. (In this example, all the samples have already
% been measured on both instruments. If only the Instrument 1
% samples had been measured, STDSSLCT would tell you which samples
% should be measured on Instrument 2.)
 
% Now we can use the STDGEN function to obtain transforms that
% converts the response of Intrument 2 to look like that of
% Instrument 1. STDGEN can be used to generate direct (DS) and
% piecewise direct (PDS) standardization transforms with or without
% additive background correction. STDGEN can also be used in a
% double window approach to form piecewise direct models (SWPDS). In
% this example, additive background correction will be used for all
% 3 transform models (DS, PDS, and DWPDS) and the results will be compared.
 
% For PDS we will use a window of 3 channels and a tolerance of 1e-3.
% For DWPDS we will use an inner window of 5 channels, an outer window
% of 3 channels, and a tolerance of 1e-4. These window widths and tolerances
% were chosen because we know (since we've done this before) that they
% optimize the performance of the transforms.
pause
%-------------------------------------------------
[stdmatd,stdvectd] = stdgen(spec1.data(ids,:),spec2.data(ids,:)); %DS
optionsstd         = stdgen('options');
optionsstd.tol     = 1e-2;
[stdmatp,stdvectp] = stdgen(spec1.data(ipds,:),spec2.data(ipds,:),3,optionsstd);
optionsstd.tol     = 1e-2;
[stdmatdw,stdvectdw] = stdgen(spec1(ipds,:),spec2.data(ipds,:),[3 5],optionsstd);
%optionsstd.condn   = 1e4;
%[stdmatr,stdvectr] = stdgen(spec1(ipds,:),spec2.data(ipds,:),3,optionsstd); %if [3 5] use condn=1e-5
 
% Now we can convert the second spectra by multiplying by the
% transform matrices, and adding the background correction
% using the STDIZE function as follows:
pause
%-------------------------------------------------
cspec2d  = stdize(spec2.data,stdmatd, stdvectd);  %DS transformed spectra
cspec2p  = stdize(spec2.data,stdmatp, stdvectp);  %PDS transformed spectra
cspec2dw = stdize(spec2.data,stdmatdw,stdvectdw); %DWPDS transformed spectra
%cspec2r  = stdize(spec2.data,stdmatr, stdvectr);  %PDS w/ Ridging
 
% We'll look at these shortly.
pause
%-------------------------------------------------
% Transforms can also be developed using Orthogonal Signal
% Correction (OSC). To do this we'll use the same 5 samples
% that selected for developing the PDS transform.
 
% The 5 samples from each of the instruments will be put
% into one matrix, then the OSC factors will be determined.
% The objective is to find the part of the difference between
% the instruments that is orthogonal to the concentrations,
% and subtract it out of the data.
 
% First we will make the matrices with the samples from both
% instruments then we'll call the OSCCALC function to find
% the factors to remove from the data:
 
[augspec,augsmns] = mncn([spec1.data(ipds,:); spec2.data(ipds,:)]);
[augconc,augcmns] = mncn([conc.data(ipds,:);  conc.data(ipds,:) ]);
[nx,nw,np,nt]     = osccalc(augspec,augconc,3,20,96);
 
pause
%-------------------------------------------------
% Note that we calculated 3 OSC factors, iterated 20 times
% to find the direction of maximum variance orthogonal to Y
% and calculated a PLS model to reproduce the factor scores
% which captured at least 96% of the variance in the scores.
% These are parameters that must be determined in order to 
% optimize the transform.
  
% Now we can use the OSC transform we developed and apply it
% to our two instruments:
 
oscspec1 = scale(spec1.data,augsmns)-scale(spec1.data,augsmns)*nw*inv(np'*nw)*np';
oscspec2 = scale(spec2.data,augsmns)-scale(spec2.data,augsmns)*nw*inv(np'*nw)*np';
 
pause
%-------------------------------------------------
% We now need to calculate PLS models that will be used with the
% OSC corrected data. Note that, unlike PDS and DS, when OSC is
% used both data sets are changed and new models are required for
% the standard instrument.
 
% options = pls('options');  %options not changed
% options.display = 'off';
% options.plots   = 'none';
% pre             = preprocess('default','mean center');
% options.preprocessing = {pre pre};
 
echo off
fitosc  = zeros(30,5);
for ii=1:5 % Make models on OSC'ed spec
  conc.includ{2,1} = ii;          %select only column ii of conc.data
  modelosc{ii}     = pls(oscspec1,conc,5,options);
  fitosc(:,ii)     = modelosc{ii}.pred{2};
end
 
echo on
% Lets look at the difference between Instrument 1 spectra
% and the corrected Instrument 2 spectra. Note that PDS and
% DWPDS are very similar, so we'll only show PDS.
pause
%-------------------------------------------------
echo off
plot(spec1.axisscale{2,1},spec1.data-spec2.data,'-r')
axis([800 1600 -0.2 0.1]), hold on, 
title('Difference between NIR Spectra from Instruments 1 and 2')
xlabel('Wavelength (nm)')
ylabel('Absorbance Difference')
text(810,0.09,'Difference before correction shown in red','FontSize',14)
 
pause
%-------------------------------------------------
plot(spec1.axisscale{2,1},spec1.data-cspec2d,'-g')
text(810,0.07,'Difference after direct correction shown in green','FontSize',14)
 
pause
%-------------------------------------------------
plot(spec1.axisscale{2,1},spec1.data-cspec2p,'-b')
text(810,0.05,'Difference after piecewise correction shown in blue','FontSize',14)
 
pause
%-------------------------------------------------
plot(spec1.axisscale{2,1},oscspec1-oscspec2,'-m')
text(810,-0.04,'Difference after OSC shown in magenta','FontSize',14), hold off
 
echo on
 
% You can see that the differences are much smaller after standardization.
% Now let's see how the predictions look based on the Instrument 1 models
% and the standardized Instrument 2 spectra.
 
% First, look at the fit ...
 
echo off
 
plot(conc.data,fit,'o'), dp
axis([0 50 0 50])
title('Fit vs. Actual Concentrations Based on Instrument 1')
xlabel('Actual Analyte Concentration')
ylabel('Analyte Concentration Fit to Model')
text(2,46,'Each analyte shown as a different color','FontSize',14)
echo on
 
% Recall that this is how good the fit was based on Intrument 1.'
pause
%-------------------------------------------------
% Lets look at some predictions based on the UNSTANDARDIZED
% Instrument 2 spectra using the Instrument 1 models.
pause
%-------------------------------------------------
echo off
preds2   = zeros(30,5);
% FOR loop for predictions.
for ii=1:5  %column ii of conc.data slected
  pred             = pls(spec2.data,model{ii},options); %Unstandardized
  preds2(:,ii)     = pred.pred{1,2};
end, clear pred ii
plot(conc.data,preds2,'o'), dp, axis([0 50 0 50])
title('Predictions vs. Actual Concentrations Based on Instrument 2')
xlabel('Actual Analyte Concentration')
ylabel('Analyte Concentration Predicted by Model')
text(2,46,'Each analyte shown as a different color','FontSize',14)
pause
%-------------------------------------------------
echo on
 
% As you can see, this doesn''t look great.
% Now we can look at predictions for instrument 2 based
% on the STANDARDIZED spectra.
 
% First, we'll make predictions on all the models using the different
% standardized spectra.
pause
%-------------------------------------------------
echo off
preds2d  = zeros(30,5);
preds2p  = preds2d;
preds2dw = preds2d;
%preds2r  = preds2d;
predsosc = preds2d;
% FOR loop for predictions.
for ii=1:5  %column ii of conc.data slected
  pred             = pls(cspec2d,model{ii},options);     %DS transformed spectra
  preds2d(:,ii)    = pred.pred{1,2};
  pred             = pls(cspec2p,model{ii},options);     %PDS transformed spectra
  preds2p(:,ii)    = pred.pred{1,2};
  pred             = pls(cspec2dw,model{ii},options);    %DWPDS transformed spectra
  preds2dw(:,ii)   = pred.pred{1,2};
  %pred             = pls(cspec2r,model{ii},options);    % transformed spectra
  %preds2r(:,ii)    = pred.pred{1,2};
  pred             = pls(oscspec2,modelosc{ii},options); %OSC
  preds2osc(:,ii)  = pred.pred{1,2};
end, clear pred ii
plot(conc.data,preds2p,'o'), hold on, axis([0 50 -10 50]), dp, hline(0)
title('Actual Concentrations vs. Predictions Based on Standardized Instrument 2');
xlabel('Actual Analyte Concentration')
ylabel('Predicted Analyte Concentration')
text(1,47,'Each analyte shown as different color','FontSize',14)
text(3,44,'o Piecewise direct standardized','FontSize',14)
 
pause
%-------------------------------------------------
plot(conc.data,preds2d,'*')
text(3,41,'* Direct standardized samples','FontSize',14)
 
pause
%-------------------------------------------------
plot(conc.data,preds2osc,'+'), hold off
text(3,38,'+ OSC standardized samples','FontSize',14)
 
pause
%-------------------------------------------------
% plot(conc.data,preds2r,'d')
% text(3,35,'d PDS w/ ridging standardized samples','FontSize',14)
%  
% pause
 
echo on
 
% I think you will agree that the predictions from the piecewise
% direct method are pretty good. The predictions using direct
% standardization are not as good.
 
% Lets put some numbers on the difference by calculating the
% root mean sum of squares errors.
 
echo off
 
ssq1    = rmse(rmse(conc.data,fit));
ssq2    = rmse(rmse(conc.data,preds2));
ssq2p   = rmse(rmse(conc.data,preds2p));
ssq2d   = rmse(rmse(conc.data,preds2d));
ssq2dw  = rmse(rmse(conc.data,preds2dw));
%ssq2r   = rmse(rmse(conc.data,preds2r));
ssqo    = rmse(rmse(conc.data,preds2osc));
 
disp('Root Mean Sum of Squares Error for:')
disp(sprintf('Instrument 1 Fit Error              = %2.2f',ssq1));
disp(sprintf('Unstandardized Instrument 2         = %2.2f',ssq2));
disp(sprintf('Piecewise Standardized Instrument 2 = %2.2f',ssq2p));
disp(sprintf('DWPDS Standardized Instrument 2     = %2.2f',ssq2dw));
%disp(sprintf('PDS w/ Ridging Stdized Instrument 2 = %2.2f',ssq2r));
disp(sprintf('Direct Standardized Instrument 2    = %2.2f',ssq2d));
disp(sprintf('OSC Standardized Instrument 2       = %2.2f',ssqo));
disp(' ')
pause
%-------------------------------------------------
disp('So things did get quite a bit better with standardization!')
disp('How much better?')
disp(' ')
disp(sprintf('By a factor of %2.1f for PDS,',                ssq2/ssq2p));
disp(sprintf('by a factor of  %2.1f for DWPDS,',              ssq2/ssq2dw));
disp(sprintf('by a factor of  %2.1f for direct standardization', ssq2/ssq2d));
%disp(sprintf('by a factor of  %2.1f for PDS w/ ridging, and', ssq2/ssq2r));
disp(sprintf('by a factor of  %2.1f for OSC standardization.',ssq2/ssqo));
disp(' ')
 
echo on
% Note that the PDS and DWPDS models have the same form, i.e. they produce')
% a transfer function matrix that is a banded diagonal. Here the DWPDS model')
% has a band width of 5, while the PDS model had a band width of 3. DWPDS')
% was actually developed to use on spectra with very sharp features such as')
% FTIR, rather than NIR. Thus, it isn''t surprising that it does not')
% out perform PDS in this application. Our work indicates that DWPDS does')
% work better in FTIR applications.')
 
%End of STDDEMO
%
%See also: BASELINE, DISTSLCT, MSCORR, STDFIR, STDSSLCT, STDGEN, STDIZE
 
echo off
