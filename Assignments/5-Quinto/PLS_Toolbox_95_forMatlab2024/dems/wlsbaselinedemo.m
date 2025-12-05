echo on
% WLSBASELINEDEMO Demo of the WLSBASELINE function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002 Licensee shall not
%  re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
 
% WLSBASELINE is used to automatically subtract a known "interfering"
% signal from a mixture of several signals with the constraint that the
% end-result should contain as little negative signal as possible while
% having removed as much of the interfering signal as possible.
%
% Weighted Least Squares (WLS) is an iterative process in which
% negative-signed signal is penalized more than positive signal. The 
% results is that, if the algorithm subtracts too much of the interfering
% signal and the resulting spectrum goes negative, the subtraction is
% reduced until the signal approaches zero and positive values only.
 
pause
 
% The most frequent use of WLSBASELINE is to automatically subtract a broad
% background from a signal such as a spectrum or image. To demonstrat this,
% we will show the subtraction of a luminescent background out of a Raman
% signal.
% 
% Note in the spectra the broadly-shaped background which runs underneath
% the narrow signal bands of this Raman spectrum:
 
load raman_dust_particles
figure
subplot(2,1,1)
plot(raman_dust_particles.axisscale{2},raman_dust_particles.data')
title('Original Data with Background');
axis tight; yscale
 
pause
 
% To use WLSBASELINE to remove this background, we call the function with
% the data to baseline and the order of the polynomial to subtract (0 =
% offset only, 1 = linear background, 2 = second order polynomial, etc). In
% this case, we use a 3rd order polynomial to approximate the approximately
% gaussian-shaped background in these spectra.
% After calling wlsbaseline, we plot the baselined spectra on the bottom of
% the figure.
 
baselined   = wlsbaseline(raman_dust_particles.data,3);
  
subplot(2,1,2)
plot(raman_dust_particles.axisscale{2},baselined)
title('Baselined Data');
axis tight; yscale

pause
 
% Regions known to contain peaks can be manually initialized to NOT be
% included in the baseline estimation using options.wti.
 
options     = wlsbaseline('options');
options.wti = ones(1,1025);
options.wti(700:720)  = 0;
options.wti( 90:140)  = 0;
baselined   = wlsbaseline(raman_dust_particles.data,3);
subplot(2,1,2)
plot(raman_dust_particles.axisscale{2},baselined)
title('Baselined Data, refit');
axis tight; yscale
 
pause
 
% WLSBASELINE can also be used to subtract known interferents from a
% mixture spectrum. These interferents may be known background spectra or
% approximations of interfering spectral patterns.
 
pause
 
% To demonstrate this approach, we start by creating a synthetic spectrum
% containing three peaks, one ("a" centered at 40 on the x-axis) is the
% peak we want to see and two others ("b" and "c") are interferents which
% we want to subtract from the mixture. "b" is a narrow shoulder at 70 on
% the x-axis and "c" is a broad background:
 
ax = 1:100;
a  = normdf('density',ax,40,13); 
b  = normdf('density',ax,70,5)*.3; 
c  = normdf('density',ax,20,70);
x  = a+b+c+randn(1,100)*.0002;   %combine peaks and add some noise
 
figure
subplot(2,1,1)
plot(ax,[a;b;c;x])
title('Original Peaks and Combination');
legend({'A' 'B' 'C' 'Combined'})
axis tight; yscale
 
pause
 
% Next, we call wlsbaseline with the mixture spectrum, x, and the two known
% interferent spectra (b and c). WLSBASELINE will subtract b and c from x
% with the constraint that negative values should be pealized more than
% positive values. Thus, the result tends to be mostly positive while
% removing as much of the background spectra as possible.
 
xbl = wlsbaseline(x,[b;c]);
 
subplot(2,1,2)
plot(ax,a,ax,xbl)
title('Data After Subtraction and Actual Signal');
legend({'Actual A' 'Recovered A'})
axis tight; yscale

pause
 
% In this case, the shoulder is slightly over-subtracted (see the slightly
% negative-going dip on the right of the remaining "a" peak). This is
% because the constraint of a "mostly positive" spectrum doesn't consider
% peak shape. However, the subtraction is sufficient to greatly reduce the
% influence of the interferent.
%
% Note that WLSBASELINE is an iterative algorithm and may take some time
% for larger sets of spectra. It is often advantageous to perform the
% baselining and then save the baselined data so you do not have to repeat
% the process.
  
pause
 
% End of WLSBASELINEDEMO 
 
echo off
