echo on
%AXISCAL0DEMO Demo of the AXISCAL0 function
 
echo off
%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
 
%First Start with some simulated data
 ax  = 1:100; %X-Axis scale of standard instrument
 
pause
 
% Create simulated spectra from two instruments
echo off
 %Location of peaks on the standard spectrum
 x0  = [5.5 21 44.5 75.8 91];

 %Location of peaks on the measured spectrum for
 % the field instrument to be standardized
 a   = -0.0025; b   = 0.1; c   = 0.2;
 x1  = x0+x0.^2*a + x0*b + c;
peakdef0 = peakstruct('',length(x1));
peakdef1 = peakdef0;
for i1=1:length(x1)
   peakdef0(i1).param(1) = cos(x1(i1)).^2;
   peakdef0(i1).param(2) = x0(i1);
   peakdef0(i1).param(3) = 2;
   peakdef1(i1).param(1) = cos(x1(i1)).^2;
   peakdef1(i1).param(2) = x1(i1);
   peakdef1(i1).param(3) = 2;
end, echo on
y0   = peakfunction(peakdef0,ax);
y1   = peakfunction(peakdef1,ax);
h    = figure;
plot(ax,y0,'b','linewidth',2); hold on
plot(ax,y1,'-','color',[0 0.5 0]);
legend('Standard Spectrum','Measured Spectrum','Location','East')
xlabel('X-Axis')
 
pause
  
%Calibrate the wavelength axis for the field instrument
% The window width = 25 is set large enough such that there's
% a peak (or more) in each window of channels.
% The maximum shift of the window is set to 7.
 
[s,y10a]  = alignspectra(ax,y0,y1,25,7);
 
%And apply it to the spectrum y1
 
y10  = alignspectra(s,y1);
figure(h)
plot(ax,y10,'r--','linewidth',2); hold off
legend('Standard Spectrum','Measured Spectrum','Standardized Spectrum', ...
  'Location','East')
 
%Note that the fit to the left end of the spectrum isn't
% as good as the rest of the calibration.

%End of AXISCALDEMO
 
%See also: AXISCAL0
 
echo off
