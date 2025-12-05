echo on
% STDFIRDEMO Demo of the STDFIR function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load data:
 
load nir_data
 
disp(readme)
 
pause
%-------------------------------------------------
% The objective is to make spectra from Instrument 2
% "look like" they were taken on Instrument 1. The
% reference spectra will be the mean of the spectra
% from Instrument 1.
 
rspec = mean(spec1.data);
 
pause
%-------------------------------------------------
% Standardize the Instrument 2 spectra with a window
% size of 25 channels. Save the results in (sspec).
 
sspec = stdfir(spec2,rspec,43);
 
pause
%-------------------------------------------------
% Compare the mean square error (reconstruction error).
% (errorb4std) is the error between the instruments
% before standardization, and (errorafstd) is the
% error after standardization.
 
errorb4std = sqrt(mean((spec1.data-spec2.data).^2));
errorafstd = sqrt(mean((spec1.data-sspec).^2));
 
figure
plot(spec1.axisscale{2},errorb4std,'r',spec1.axisscale{2},errorafstd,'b')
ylabel('Reconstruction Error'), xlabel('Wavelength')
legend(char('Before Standardization','After Standardization'),'Location','NorthWest'), shg
 
%End of STDFIRDEMO
 
echo off
