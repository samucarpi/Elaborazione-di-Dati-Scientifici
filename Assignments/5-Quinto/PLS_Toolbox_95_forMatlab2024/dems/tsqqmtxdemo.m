echo on
%TSQQMTXDEMO Demo of the TSQQMTX function
 
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
% The TSQQMTX function can be used to calculate the
% contributions to Hotelling's T^2+Q residual combined
% statistic for PCA models.
%
% First load data and construct a PCA model.
 
pause
%-------------------------------------------------
load wine
 
options = pca('options');
options.display = 'off';
options.plots   = 'none';
options.preprocessing = preprocess('default','autoscale');
 
model = pca(wine,2,options);
 
pause
%-------------------------------------------------
% Now get the combined contribution for Russia which is sample 7
  
tsqqmat = tsqqmtx(wine.data(7,:),model);  %use only one row of the DataSet object
 
figure
bar(tsqqmat);
set(gca,'xticklabel',char(wine.label{2,1}))
ylabel('T^2 + Q Contribution')
title(['T^2 + Q Contribution for ',char(wine.label{1,1}(7,:))])
 
pause
% Compare to just the T^2 contribution gives
 
tsqqmat = tsqqmtx(wine.data(10,:),model);
bar(tsqqmat,'r')
set(gca,'xticklabel',char(wine.label{2,1}))
ylabel('T^2 + Q Contribution')
title(['T^2 + Q Contribution for ',char(wine.label{1,1}(10,:))])
 
%End of TSQQMTXDEMO
 
echo off
