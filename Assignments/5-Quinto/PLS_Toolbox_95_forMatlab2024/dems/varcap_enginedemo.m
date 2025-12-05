echo on
%VARCAP_ENGINEDEMO Demo of the VARCAP_ENGINE function
 
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
% The VARCAP function calcualtes the amount of variance
% captured by each PC for each variable. If the default
% for input (plots) is 1 it will also create a stacke bar
% plot of the variance captured information.
 
% For this demo, we'll construct a PCA model of the first
% 63 samples of the arch data set.
 
load arch
arch.includ{1} = 1:63; %keep only samples 1:63, 64:75 are test samples
 
pause
%-------------------------------------------------
% Turn off the display functions and pass a standard preprocessing
% structure (using the PREPROCESS function) to the PCA function so
% that the data will be autoscaled.
 
% This means that the preprocessing will become an explicit part of
% the PCA model.
 
options = pca('options')
 
options.display       = 'off';
options.plots         = 'none';
options.preprocessing = {preprocess('default','autoscale')};
 
% Construct a PCA model of the arch data set
 
model = pca(arch,4,options);
 
pause
%-------------------------------------------------
% Next apply the model's preprocessing to the data in arch.
 
datap   = preprocess('apply',model.detail.preprocessing{1},arch.data);
 
pause
%-------------------------------------------------
% Now call the VARCAP_ENGINE function to see which variables are
% captured by each factor.
 
% Note that we're passing only the calibration data. This is data
% that were used to determine the loadings of the PCA model. Also
% note that the data is preprocessed the same way that the calibration
% data were preprocessed.
 
pause
%-------------------------------------------------
[ssq,vc] = varcap_engine(datap.data(1:63,:), ...
                         model.loads{1,1}(model.detail.includ{1},:), ...
                         model.loads{2,1});
figure,h = bar(1:size(arch,2),vc(1:4,:)','stacked');
axis([0.25 10.75 0 119])
hline(100,'--k')
xlabel('Variable')
ylabel('Percent Variation Captured')
title('Variation Captured')
legend('Component 1','Component 2','Component 3','Component 4')
set(gca,'xticklabel',char(arch.label{2,1}))
figuretheme
 
% PC 1 is the lowest portion of each stacked bars. It has significant
% contributions from Fe, Ti, Ba, Ca, K, Mn, Rb, Sr and Zr.
 
% PC 2 is the second portion of the stacked bars. It has significant
% contributions from Ti, Ca, K, Rb, Sr and Zr.
 
% Variance captured by PC 3 is represented by the third portion of
% the stacked bars. This PC is mostly Y.
 
% PC 4 is the highest portion in the stacked bars. It has significant
% contributions from Ba, ~Y and ~Zr.
 
% The white space above the bars indicates the per cent variance of
% each variable in the residuals (i.e. the fraction not captured by
% the 4 PC model).
 
%End of VARCAP_ENGINEDEMO
 
echo off
