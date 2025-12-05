echo on
%OSCCALCDEMO Demo of the OSCCALC and OSCAPP functions
 
echo off
%Copyright Eigenvector Research, Inc. 2003 
% Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%------------------------------------ 
% Orthogonal Signal Correction (OSC) is a data preprocessing method that
% can be used prior to PLS modelling. In situations where the a PLS model
% captures a very large amount of predictor block (X) variance in the first
% factor but gets very little of the predicted variable (y or Y) it can be
% very helpful. In these cases it is useful to remove extraneous variance
% from X that is unrelated to y. OSC does this by finding directions in X
% that describe large amounts of variance while being orthogonal to y.
 
pause
%------------------------------------ 
% OSC can also be used for standardization purposes to remove variation
% between instruments that is not related to the variables to be predicted.
% An example of this is shown here with the NIR data. The NIR data consists
% of Near Infra-red spectra collected of gasoline samples on two different
% intstruments (spec1 and spec2). 
 
load nir_data
who
 
pause
%------------------------------------ 
% Here is the difference in the spectra of the same set of samples measured
% on the two instruments:
 
figure
subplot(2,1,1)
plot(spec1.axisscale{2},spec1.data,'g',spec1.axisscale{2},spec2.data,'m')
hline('k--')
ylabel('Absorbance')
xlabel('Wavelength (nm)')
title('Gasoline Spectra Measured on Two Different Instruments')
 
subplot(2,1,2)
plot(spec1.axisscale{2},spec1.data-spec2.data,'r')
hline('k--')
ylabel('Absorbance Difference')
xlabel('Wavelength (nm)')
title('Difference Between Instruments Before OSC')
 
pause
%------------------------------------ 
% To remove these differences, we first use the STDSLCT function to select
% a subset of 5 fairly unique samples to use in the OSC.
 
[specsub,specnos] = stdsslct(spec1.data,5);  %select 5 unique samples
 
pause
%------------------------------------ 
% Next, we take those samples measured on both instruments and "augment"
% them together into a single set of spectra. OSC will help us remove the
% differences in this data which is not correlated with the y-block
% (concentrations):
 
x1 = spec1.data(specnos,:); x2 = spec2.data(specnos,:);
y1 = conc.data(specnos,:);
 
x = [x1; x2]; y = [y1; y1];
 
pause
%------------------------------------ 
% Use the OSCCALC function on the subset of spectra from the two
% instruments to calculate the necessary correction factors (weights, nw, and
% loadings, np) necessary to remove the undesired variance:
 
[nx,nw,np,nt] = osccalc(x,y,2);
 
% and use OSCAPP applies these correction factors to the full set of all spectra
 
newx1 = oscapp(spec1.data,nw,np);
newx2 = oscapp(spec2.data,nw,np);
 
pause
%------------------------------------ 
% To see how well OSC did at making the two instruments more similar, we
% look at the plot of differences again
 
plot(spec1.axisscale{2},spec1.data-spec2.data,'r',spec1.axisscale{2},newx1-newx2,'b')
 
ylabel('Absorbance Difference')
xlabel('Wavelength (nm)')
title('Difference Between Instruments Before (red) and After (blue) OSC')
 
pause
%------------------------------------ 
% After correction, very few differences remain in the dataset.
 
pause
%-------------------------------------------------
% End of OSCCALCDEMO
 
echo off
close
 
