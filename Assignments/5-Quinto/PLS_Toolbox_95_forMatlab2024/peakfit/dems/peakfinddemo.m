echo on
% PEAKFINDDEMO Demo of the PEAKFIND function
 
echo off
% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%JMS
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The PEAKFIND function is used to automatically locate peaks in a vector
% response such as a spectrum or chromatogram. It supports several
% algorithms which work differently under different noise, sampling rates
% (resolution) and background conditions. In addition, the algorithm has
% several adjustable parameters that must be selected based on the data
% being analyzed. This demo will give you the general information for how
% these parameters are selected so that you can determine the most useful
% parameter settings for your data.
 
pause
%-------------------------------------------------
% The first example we'll give uses NIR data of pseudo-gasoline mixtures.
% We'll look for peaks in the first spectrum of this data set.
 
load nir_data
 
x = spec1.data(5,:);
[c]=peakfind(x,11,3,5,struct('algorithm','d0')); plot(x); vline(c{:}); shg; pause, hold off
[c]=peakfind(x,11,3,5,struct('algorithm','d2')); plot(x); vline(c{:}); shg; pause, hold off
[c]=peakfind(x,11,3,5,struct('algorithm','d2r')); plot(x); vline(c{:}); shg;pause, hold off
[c]=peakfind(x,5,3,5,struct('algorithm','d2r')); plot(x); vline(c{:}); shg; pause, hold off
[c]=peakfind(x,9,struct('algorithm','d2r')); plot(x); vline(c{:}); shg; pause, hold off
[c]=peakfind(x,9,struct('algorithm','d2')); plot(x); vline(c{:}); shg;  pause, hold off
[c]=peakfind(x,9,struct('algorithm','d2r')); plot(x); vline(c{:}); shg; pause, hold off
[c]=peakfind(x,9,struct('algorithm','d0')); plot(x); vline(c{:}); shg;  pause, hold off
 
load oesdata
x = oes1.data(1,:);
[c]=peakfind(x,11,1,3,struct('algorithm','d0')); plot(x); vline(c{:}); shg;  pause, hold off
[c]=peakfind(x,11,.4,3,struct('algorithm','d2')); plot(x); vline(c{:}); shg; pause, hold off
[c]=peakfind(x,11,.4,3,struct('algorithm','d2r')); plot(x); vline(c{:}); shg;pause, hold off
 
 
load raman_dust_particles_references
x = raman_dust_particles_references.data(1,:);
[c] = peakfind(x,9,1,struct('algorithm','d0')); plot(x); vline(c{:}); shg; pause, hold off
[c] = peakfind(x,9,1,struct('algorithm','d2')); plot(x); vline(c{:}); shg; pause, hold off
 
 
%End of PEAKFINDDEMO
%
%See also: PEAK2DEMO
 
echo off
