echo on
%DERESOLVDEMO Demo of the DERESOLV function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% DERESOLV lowers a spectrum's resolution, by 1) taking the
% FFT, 2) convolving with a triangular line shape based on
% the desired resolution, and then 3) taking the inverse FFT.
 
% For example, suppose (hrspec) is a high resolution spectrum.
pause
%-------------------------------------------------
x       = 0:0.1:4*pi;
hrspec  = exp(-(x-2*pi).^2/4).*cos(x).^8;
hrspec  = hrspec + randn(1,length(x))*0.01;
 
figure, plot(x,hrspec), hold on, title('High Resolution Spectrum')
pause
%-------------------------------------------------
% DERESOLV will be called to construct a lower resolution spectrum
% (lrspec) at the same sampling as (hrspec). The convolution will
% be over 8 channels (i.e. a=8).
pause
%-------------------------------------------------
lrspec  = deresolv(hrspec,8);
 
plot(x,lrspec,'r-'), title('Both Spectra')
legend('High Resolution','Low Resolution'), hline
 
% DERESOLV can be used to smooth (remove some noise).
 
%End of DERESOLVDEMO
 
echo off
