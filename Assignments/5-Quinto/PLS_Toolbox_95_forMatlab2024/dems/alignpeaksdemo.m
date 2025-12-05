echo on
%ALIGNPEAKSDEMO Demo of the ALIGNPEAKS function
 
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
%Location of peaks on the standard spectrum
 x0  = [5.5 21 44.5 75.8 91];

%Location of peaks on the measured spectrum for
% the field instrument to be standardized
 a   = -0.0025; b   = 0.1; c   = 0.2;
 x1  = x0+x0.^2*a + x0*b + c;
 
% ax+ax.^2*a + ax*b + c is the true axis of instrument 2, but
% ax  is the axis that is reported by the instrument.
 
pause
 
% Create simulated spectra from two instruments
echo off
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
s    = alignpeaks(x0,x1,ax);
%And apply it to the spectrum y1
y10  = alignpeaks(s,y1);
figure(h)
plot(ax,y10,'r--','linewidth',2); hold off
legend('Standard Spectrum','Measured Spectrum','Standardized Spectrum', ...
  'Location','East')

%Note that the wavelength registration has changed the
% peak shapes a bit due to the fact that the difference
% in axis scales is more than a simple shift.

%End of ALIGNPEAKSDEMO
 
%See also: ALIGNSPECTRA
 
echo off
