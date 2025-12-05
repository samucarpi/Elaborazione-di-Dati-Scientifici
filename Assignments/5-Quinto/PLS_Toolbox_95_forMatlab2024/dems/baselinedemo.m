echo on
% BASELINEDEMO Demo of the BASELINE function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002 Licensee shall not
%  re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%jms
 
clear ans
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The BASELINE function calculates and removes an n-th order baseline
%  from each row of a data matrix. The user supplies the data along with the
%  ranges of the spectrum which should be fit to the baseline function.
% The default order is 1st order (linear trend) but any order can be set.
pause
%-------------------------------------------------
% An example uses some Near IR data with a simulated baseline:
 
load nir_data
lamda = spec1.axisscale{2};
spec1 = spec1.data;
 
whos
% spec1 is the actual data, lamda is the wavelength vector corresponding to
% the columns of spec1. spec2 will not be used here.
 
pause
%-------------------------------------------------
% Introduce a simulated linear baseline for each spectrum
 
bl = .001*rand(30,1)*[1:401] + rand(30,1)*ones(1,401)*.2;
spec1 = spec1 + bl;
 
% Plot those spectra
figure
subplot(3,1,1)
plot(lamda,spec1)
 
pause
%-------------------------------------------------
% Select the wavelength ranges which will be used to fit the baseline
% function. These are specified as [start end] wavelength pairs in rows of
% the "range" input.
 
range = [850 980; 1120 1180; 1330 1430] 
 
pause
%-------------------------------------------------
% Here are the three ranges indicated on the plot as pairs of vertical
% dashed lines.
 
vline(range(1,:),'r--')
vline(range(2,:),'g--')
vline(range(3,:),'b--')
shg
 
pause
%-------------------------------------------------
% Now, pass the spectra, the wavelength vector and the ranges to baseline.
% First, we will do just an offset baseline (order = 0):
 
options = [];
options.order = 0;   %define the order of polynomial to use
 
newspec = baseline(spec1,lamda,range,options); 
 
subplot(3,1,2); 
plot(lamda,newspec)
 
pause
%-------------------------------------------------
% Next, using the same wavelength ranges, we will try a linear baseline:
 
options.order = 1;
 
newspec = baseline(spec1,lamda,range,options); 
 
subplot(3,1,3); 
plot(lamda,newspec)
 
% End of BASELINEDEMO 
 
echo off
