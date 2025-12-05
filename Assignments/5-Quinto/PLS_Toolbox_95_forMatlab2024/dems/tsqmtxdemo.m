echo on
%TSQMTXDEMO Demo of the TSQMTX function
 
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
% The TSQMTX function can be used to calculate the
% contributions to Hotelling's T^2 statistic for PCA
% models.
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
% Now get the T^2 contribution for Russia which is sample 7
  
tsqmat = tsqmtx(wine.data(7,:),model);  %use only one row of the DataSet object
 
figure
bar(tsqmat);
set(gca,'xticklabel',char(wine.label{2,1}))
ylabel('T^2 Contribution')
title(['T^2 Contribution for ',char(wine.label{1,1}(7,:))])
 
pause
%-------------------------------------------------
% To call it using loadings and ssq table use the following e.g.
% (here the appropriate parts of the model are extracted). Note
% that first I must scale my data.
 
dat7   = preprocess('apply',model.detail.preprocessing{1},wine.data(7,:)); %output is a DataSet
tsqmat = tsqmtx(dat7.data,model.loads{2,1},model.detail.ssq)
 
figure
bar(tsqmat);
set(gca,'xticklabel',char(wine.label{2,1}))
ylabel('T^2 Contribution')
title(['T^2 Contribution for ',char(wine.label{1,1}(7,:))])
 
%End of TSQMTXDEMO
 
echo off
