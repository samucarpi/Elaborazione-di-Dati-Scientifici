echo on
%DATAHATDEMO Demo of the DATAHAT function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Create data:
 
w = [0:10];
s = [sin(w); cos(w)*2].^2;                        %pure analyte spectra
t = [1:35]';
c = [exp(-((t-20).^2)/40) exp(-((t-25).^2)/30)];  %elution profiles
x = c*s + randn(length(t),length(w))*.01;         %xcal: outer product of elution and spectra
 
% This creates two matrices with similar factors.
% (a) will be used to calibrate a PCA model and
% (b) will be used as a test matrix.
 
figure, mesh(x)
 
% Next, construct a PCA model of matrix (a).
 
pause
%-------------------------------------------------
% Turn off the display options and make a 2 factor PCA model.
 
options         = pca('options');
options.display = 'off';
options.plots   = 'none';
model = pca(x,2,options);
 
pause
%-------------------------------------------------
% Now call DATAHAT
 
[xhat,resids] = datahat(model,x);
 
% for x=TP'+E: xhat = TP' and resids = E
% (xhat) can be considered a "noise-filtered" estimate of (x)
%
% Could also just get (xhat) from
% xhat = datahat(model);
 
pause
%-------------------------------------------------
% Plot the results
 
figure
subplot(3,1,1), mesh(x),      title('Original Data Matrix')
subplot(3,1,2), mesh(xhat),   title('Esimated Data Matrix')
subplot(3,1,3), mesh(resids), title('Residuals (a-ahat)')
 
 
% DATAHAT can be used with other model forms such as PLS and PARAFAC.
% See "help datahat" or "datahat help".
%
%End of DATAHATDEMO
 
echo off
