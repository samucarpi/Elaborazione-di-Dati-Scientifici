echo on
% NLSTDDEMO A Demo of the NLSTD function
 
echo off
% Copyright Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
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
% "look like" they were taken on Instrument 1.
 
% The first step is to select standarization samples
% i.e. a subset of spectra that is used to develop the
% standardization transform.
 
% Here we'll use the DISTSLCT function, but we could
% also use DOPTIMAL or STDSSLCT. We'll use 12 samples
% (out of 30).

isel = distslct(spec1.data,12); % (isel) are the sample indices
noisel=spec1.include{1};
noisel(isel)=[];
 
pause
%-------------------------------------------------
% Generate the settings for transform using nonlinear standardization
% using Artificial Neural Network(ANN) with a window width of 41 channels,
% 10 nodes in the first hidden layer, 2 nodes in the second hidden layer.
% Press return to proceed with creating the ANN model, note that this may
% take a few minutes.

annopt=nlstd('options');
uopt=ann('options');
uopt.nhid1=10;
uopt.nhid2=2;
uopt.display='off';
annopt.useopts=uopt;
win=41;

pause
%-------------------------------------------------
% Generate the transform using nonlinear standardization using
% Artificial Neural Network(ANN).
% (annmodel) is the ANN model with 2 hidden layers.
% Please be paitent as this may take several minutes.

[annmodel] = nlstd(spec2.data(isel,:),spec1.data(isel,:),win,annopt); 

pause
%-------------------------------------------------
% Generate the settings for transform using nonlinear standardization
% using Locally Weighted Regression(LWR) with a window width of
% 5 channels, and using 6 points.
% Note that the algorithm field in the options structure is set to 'lwr'.

lwropt=nlstd('options');
lwropt.algorithm = 'lwr';
uopt=lwr('options');
uopt.display='off';
lwropt.useopts=uopt;

[lwrmodel] = nlstd(spec2.data(isel,:),spec1.data(isel,:),5,6,lwropt); 

pause
%-------------------------------------------------
% Apply the models to standardize the Instrument 2 spectra.

% ANN prediction
[annpred]  = nlstd(spec2.data(noisel,:),annmodel,win);
% LWR prediction
[lwrpred]  = nlstd(spec2.data(noisel,:),lwrmodel,5);

% Compare the mean square error (reconstruction error).
% (errorb4std) is the error between the instruments
% before standardization, (errorann) is the error after
% ANN standardization, and (errorlwr) is the error after
% LWR standardization.

errorb4std = sqrt(mean((spec1.data(noisel,:)-spec2.data(noisel,:)).^2));
errorann = sqrt(mean((spec1.data(noisel,:)-annpred).^2));
errorlwr = sqrt(mean((spec1.data(noisel,:)-lwrpred).^2));

figure
plot(spec1.axisscale{2},errorb4std,'r',spec1.axisscale{2},errorann,'b',spec1.axisscale{2},errorlwr,'g');
ylabel('Reconstruction Error'), xlabel('Wavelength')
legend(char('Before Standardization','ANN','LWR'),'Location','NorthWest'), shg

pause
%-------------------------------------------------

% End of NLSTDDEMO
 
echo off
