echo on
% SPLITHALFDEMO Demo of the SPLITHALF function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002203
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%bmw
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The SPLITHALF functions splits the data into two parts and compare
% PARAFAC models in each half. If they are similar and similar to the 
% model on the whole data set, a high splithalf similarity is obtained
% (measured by congruence). This indicates that the number of components
% used, is feasible.
 
load sugar
% remove outlier
sugar = sugar([1:70 72:end],:,:);
% As it is a time series data set, shuffle the data to make sure 
% that all phenomena occur evenly across samples
sugar = sugar(randperm(size(sugar,1)),:,:);


% run PARAFAC splithalf with appropriate number of components and look 
% at results plots
%
% To run the analysis hit a "return" 
%
pause
result = splithalf(sugar,3);

 
echo off
  
   
