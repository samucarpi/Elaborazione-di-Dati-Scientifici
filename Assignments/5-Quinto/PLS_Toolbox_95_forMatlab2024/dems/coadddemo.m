echo on
%COADDDEMO Demo of the COADD function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% COADD reduces the size of a matrix by co-adding adjacent variables
% (columns), samples (rows), or slabs in a matrix. This is often useful to
% reduce spectral resolution using a "boxcar" integration approach (see
% also DERESOLV for a method which does not reduce the total number of
% variables) or to reduce the total number of samples for highly
% overdetermined systems. Such reductions can speed up some analyses
 
% For example, suppose (hrspec) is a high resolution spectrum.
pause
%-------------------------------------------------
x       = 0:0.1:4*pi;
hrspec  = exp(-(x-2*pi).^2/4).*cos(x).^8;
hrspec  = hrspec + randn(1,length(x))*0.01;
 
figure, plot(x,hrspec,'.-'), hold on, title('High Resolution Spectrum')
pause
%-------------------------------------------------
% COADD will be called to construct a lower resolution spectrum
% (lrspec) at reduced sampling. The reduction will be a factor of 8 (i.e.
% bins=8) and the default method is to return the mean of the co-added
% points (so that intensity scale is maintained).
pause
%-------------------------------------------------
lrspec  = coadd(hrspec,8);
lrx     = coadd(x,8);       %do same for x-axis
 
plot(lrx,lrspec,'r.-'), title('Both Spectra')
legend('High Resolution','COADD Low Resolution')
 
pause
%-------------------------------------------------
% DERESOLV works similarly, except that the sampling of the original
% high resolution spectrum is maintained.
 
lr2spec = deresolv(hrspec,8);
 
plot(x,lr2spec,'g.-'), title('Multiple Spectra')
legend('High Resolution','COADD Low Res.','DERESOLV Low Res.')
 
%End of COADDDEMO
 
echo off
