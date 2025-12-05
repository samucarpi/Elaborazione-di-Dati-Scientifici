echo on
%SAVGOLDEMO Demo of the SAVGOL function
 
echo off
%Copyright Eigenvector Research, Inc. 1992
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%bmw April 1994
%nbg modified from sgdemo 8/02, 3/13 1/d
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Imagine for that you measure the signal shown on the plot.
 
scl = (0:0.1:20);      yt = scl.*sin(scl)/20;  %the "true" signal
y   = yt + scl.*randn(size(scl))/100;
plot(scl,y,'-','color',[0 0.5 0]),  hold on,    text(5,1.35,'Measured Signal')
plot([2 4],[1.35 1.35],'-','color',[0 0.5 0]),  xlabel('Time in Seconds')
ylabel('Signal'), title('Example of Savitzky-Golay Smoothing')
 
pause
%-------------------------------------------------
% It is apparent that there is a general sinusoidal trend
% to this signal with superimposed noise. We can use
% Savitzky-Golay smoothing to get an estimate of the
% "true" signal. We will use a window of 21 points and
% a second order polynomial for the smooth of the signal, y
% and plot the results.
 
opts = savgol('options');
opts.tails = 'polyinterp';
y0 = savgol(y,21,2,0,opts);
 
plot(scl,y0,'-b'),               text(5,1.15,'Smoothed Signal')
plot([2 4],[1.15 1.15],'-b')
 
% You can see that the true signal and the smooth are fairly close.
 
pause
%-------------------------------------------------
% This looks  better, and because we created the data,
% we can compare it to the "true" signal.
 
plot(scl,yt,'-r'),               text(5,0.95,'True Signal')
plot([2 4],[.95 .95],'-r')
 
pause
%-------------------------------------------------
% We might also be interested in taking the derivative of
% such a signal. Savitzky-Golay can be used to estimate the
% derivative of the smoothed signal. Here we will use the
% SAVGOL routine to calculate the first derivative based
% on fitting a second order polynomial to 21 point windows
% and plot the results.
 
y1 = savgol(y,21,2,1,opts);
 
figure
plot(scl,y1,'-b'), hold on,     text(5,.08,'First Derivative of Smoothed Signal')
plot([2 4],[.08 .08],'-b'),     xlabel('Time in Seconds')
ylabel('Derivative of Signal'), title('Example of Savitzky-Golay Derivatives')
 
pause
%-------------------------------------------------
% Again, since we created the "true" signal, we can compare.
% The true signal was
%   y    = t*sin(t)/20,             therefore
%  dy/dt = (sin(t) + t*cos(t))/20.
%
% The Savitzky-Golay routine assumes that the points are given
% at unit distances apart (and are evenly spaced), and our sample
% was taken at increments of 0.1, so the calculated derivative
% must be divided by 10 to match the Savitzky-Golay estimate.
% We can compare this to our calculated derivative.
 
dy = (sin(scl) + scl.*cos(scl))/200;
plot(scl,dy,'-r'); text(5,0.06,'True Derivative')
plot([2 4],[0.06 0.06],'-r'), hold off
 
% So the calculated derivative is reasonably close to the true
% derviative. We can compare this to what we would have obtained
% by taking the first difference of the data.
 
pause
%-------------------------------------------------
plot(scl,y1,'-b',scl,dy,'-r',scl,[0 diff(y)],'color',[0 0.5 0]), hold on
plot([2 4],[.5 .5],'-b'), text(5,.5,'First Derivative of Smoothed Signal')
plot([2 4],[.4 .4],'-r'), text(5,.4,'True Derivative')
plot([2 4],[.3 .3],'-','color',[0 0.5 0]), text(5,.3,'First Difference')
xlabel('Time in Seconds'), ylabel('Derivative of Signal')
title('Example of Savitzky-Golay Derivatives'), hold off
 
% As you can see, the Savitzky-Golay estimate is much better
% than the first difference estimate.
 
pause
%-------------------------------------------------
% The SAVGOL routine can also be used with matrices. It assumes
% that each row is a series so that dy/dt is calculated for each row.
% As an example, we'll use the NIR data shown here.
% (We'll use only the first 5 samples.)
 
load nir_data
plot(spec1.axisscale{2},spec1.data(1:5,:)), title('NIR Spectra')
ylabel('Absorbance'), xlabel('Wavelength')
 
pause
%-------------------------------------------------
% Now calculate the second derivative of the smoothed NIR spectra
% using a 7 point window and a cubic polynomial and plot it.
 
dspec = savgol(spec1.data(1:5,:),7,3,2,opts);
 
plot(spec1.axisscale{2},dspec),  title('Second Derivative of NIR Spectra')
xlabel('Wavelength'), ylabel('Absorbance Second Derivative')
 
% It's difficult to tell the difference between each of
% the second derivative spectra.
 
pause
%-------------------------------------------------
% The differences can be made more apparent by plotting
% the mean centered 2nd derivative spectra (see MNCN).
 
mdspec = mncn(dspec); 
 
plot(spec1.axisscale{2},mdspec)
title('Second Derivative Difference of NIR Spectra')
xlabel('Wavelength'), ylabel('Absorbance Second Derivative Difference')
 
% This "second derivative difference" spectra is often used
% in cases where there is a problem of baseline drift.

pause
%-------------------------------------------------
% The filter can also be calculated with less smoothing by
% using 1/d weighting. First load the data and plot it.
 
load data_mid_IR
figure, plot(data_mid_IR.axisscale{2},data_mid_IR.data(1:2,:));
set(gca,'xdir','reverse')
xlabel('Wavenumber (cm^{-1})')
 
pause
%-------------------------------------------------
% Next calculate the derivatives and plot them.
 
dspec      = savgol(data_mid_IR.data(1:2,:),7,2,2,opts);
opts.tails = 'weighted';
opts.wt    = '1/d';
espec      = savgol(data_mid_IR.data(1:2,:),7,2,2,opts);
 
figure, subplot(2,1,1)
plot(data_mid_IR.axisscale{2},dspec(1,:),'b'), hold on
plot(data_mid_IR.axisscale{2},espec(1,:),'r')
title('Second Derivative of NIR Spectrum 1')
ylabel('Absorbance 2nd D'), set(gca,'xdir','reverse')
legend('SavGol','SavGol 1/d weighted','location','southwest')
subplot(2,1,2)
plot(data_mid_IR.axisscale{2},dspec(2,:),'b'), hold on
plot(data_mid_IR.axisscale{2},espec(2,:),'r')
title('Second Derivative of NIR Spectrum 2')
ylabel('Absorbance 2nd D'), set(gca,'xdir','reverse')
legend('SavGol','SavGol 1/d weighted','location','southwest')
xlabel('Wavenumber (cm^{-1})')
 
%End of SAVGOLDEMO
%Also See: SAVGOLDEMOB, WSMOOTHDEMO
 
echo off
