echo on
%STDGENDEMO Demo of the STDGEN and STDIZE functions
 
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
% Load data:
 
load nir_data
 
disp(readme)
 
pause
%-------------------------------------------------
% The objective is to make spectra from Instrument 2
% "look like" they were taken on Instrument 1.
 
% The first step is to select standarization samples
% i.e. a subset of spectra that is used to develop the
% standardization transform.
 
% Here we'll use the DISTSLCT function, but we could
% also use DOPTIMAL or STDSSLCT. We'll use 5 samples
% (out of 30).
 
isel = distslct(spec1.data,5); % (isel) are the sample indices
 
%[specsub,isel] = stdsslct(spec1.data,5);
 
pause
%-------------------------------------------------
% Generate the transform using piece-wise direct (PDS)
% standardization with a window width of 5 channels.
% (stdmatpds) is the transform matrix and (stdvectpds)
% is the offset vector.
 
[stdmatpds,stdvectpds] = stdgen(spec1.data(isel,:),spec2.data(isel,:),5);
 
pause
%-------------------------------------------------
% Generate the transform using double window piece-wise direct
% (DWPDS) standardization with a primary window width of 5
% and secondary window width of 3 channels. (stdmatdwpds) is
% the transform matrix and (stdvectdwpds) is the offset vector.
 
[stdmatdwpds,stdvectdwpds] = stdgen(spec1.data(isel,:),spec2.data(isel,:),[5 3]);
 
pause
%-------------------------------------------------
% Apply the two models to standardize the Instrument 2 spectra.
% (stdspecpds) are the standardized spectra using PDS and
% (stdspecdwpds) are from DWPDS.
 
stdspecpds   = stdize(spec2.data,stdmatpds,  stdvectpds);
stdspecdwpds = stdize(spec2.data,stdmatdwpds,stdvectdwpds);
 
% Compare the mean square error (reconstruction error).
% (errorb4std) is the error between the instruments
% before standardization, (errorpds) is the error after
% PDS standardization, and (errordwpds) is the error after
% DWPDS standardization.
 
errorb4std = sqrt(mean((spec1.data-spec2.data).^2));
errorpds   = sqrt(mean((spec1.data-stdspecpds).^2));
errordwpds = sqrt(mean((spec1.data-stdspecdwpds).^2));
figure
plot(spec1.axisscale{2},errorb4std,'r',spec1.axisscale{2},errorpds,'b', ...
  spec1.axisscale{2},errordwpds,'g')
ylabel('Reconstruction Error'), xlabel('Wavelength')
legend(char('Before Standardization','PDS','DWPDS'),'Location','NorthWest'), shg
 
%End of STDGENDEMO
%
%See also: STDDEMO
 
echo off
