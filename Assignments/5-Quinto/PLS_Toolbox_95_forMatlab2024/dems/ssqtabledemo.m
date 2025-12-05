echo on
%SSQTABLEDEMO Demo of the SSQTABLE function
 
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
% Create data that can be used in PCA. Then call SSQTABLE
 
w = [0:0.1:50];
s = [sin(w); cos(w)*2].^2;                        %pure analyte spectra
t = [0:40]';
c = [exp(-((t-20).^2)/40) exp(-((t-25).^2)/30)];  %elution profiles
a = c*s + randn(length(t),length(w))*.01;         %outer product of elution and spectra
 
% Now, construct a PCA model of the matrix (a).
 
pause
%-------------------------------------------------
% Turn off the display options and make a 2 factor PCA model.
 
options         = pca('options');
options.display = 'off';
options.plots   = 'none';
amodel = pca(a,2,options);
 
%Now call SSQTABLE and print info on all the factors.
 
pause
%-------------------------------------------------
ssqtable(amodel)
 
pause
%-------------------------------------------------
% Now call SSQTABLE and print info on only 2 factors.
 
ssqtable(amodel,2)
 
%End of SSQTABLEDEMO
 
echo off
