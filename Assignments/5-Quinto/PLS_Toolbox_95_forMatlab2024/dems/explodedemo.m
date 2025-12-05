echo on
%EXPLODEDEMO Demo of the EXPLODE function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
clear ans
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load the DataSet wine and extract it's contents (shows
% that EXPLODE is an overloaded method for DataSet object).
%
 
load wine
whos
 
pause
%-------------------------------------------------
explode(wine)
whos
 
% Note that the contents of (wine) are now in the workspace.
 
pause
%-------------------------------------------------
 
% Create matrix (a) that can be modeled using PCA. Then the
% model contents will be extracted.
 
w = [0:0.1:50];
s = [sin(w); cos(w)*2].^2;                        %pure analyte spectra
t = [0:40]';
c = [exp(-((t-20).^2)/40) exp(-((t-25).^2)/30)];  %elution profiles
a = c*s + randn(length(t),length(w))*.01;         %outer product of elution and spectra
 
options         = pca('options');
options.display = 'off';
options.plots   = 'none';
amodel = pca(a,2,options);                        %PCA model
 
pause
%-------------------------------------------------
% Now extract contents from "amodel"
 
explode(amodel,'pca1')
whos
 
% Note that the model contents have 'pca1' agumented to the end.
%
%End of EXPLODEDEMO
 
echo off
