echo on
% JMLIMITDEMO Demo of the JMLIMIT function
 
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
% The JMLIMIT function calculates a confidence limit for sum squared
% residuals such as Q values in PCA models. It takes as input the number
% of factors used in the model, a vector of eigenvalues of the covariance 
% matrix of the datas and a desired fractional confidence level (cl).
% The given fraction of the residuals will fall below the calculated limit.
% Only the fraction (1-cl) of the residuals should fall above this limit.
%
% For example, start with the data:
 
load pcadata
 
whos
 
pause
%-------------------------------------------------
% Now, create a 3 component PCA model for part1 of this data 
%  (using mean centering):
 
options               = [];
options.plots         = 'none';
options.preprocessing = {preprocess('default','mean center')};
 
modl = pca( part1, 3, options);
 
pause
%-------------------------------------------------
% Visualizing the sum squared residuals from the model (they are stored in
% the ssqresiduals field of the model) in a histogram:
 
pause
%-------------------------------------------------
figure
hist(modl.ssqresiduals{1},50)
 
pause
%-------------------------------------------------
close
 
% Now, use these residuals to calculate the 95% confidence level
% (confidence level is given in fractional form = 0.95):
 
reslimjm = jmlimit(3,modl.detail.ssq(:,2),0.95)
 
pause
%-------------------------------------------------
% Plotting this limit on the histogram...
 
pause
%-------------------------------------------------
figure
hist(modl.ssqresiduals{1},50)
vline(reslimjm,'r--')
shg
 
pause
%-------------------------------------------------
close
 
% Counting the number of observed residual values below the given level and
% dividing by the number of samples in the data set (300) gives the
% fraction that were OBSEVERED below this level. Depending on the number of
% samples in the data and how well the residuals follow a chi-squared
% distirbution, this should be nearly equal to the confidence level
% fraction requested!
 
sum( modl.ssqresiduals{1} < reslimjm ) / 300
 
 
% For an alternative method of calculating limits on residuals, see
% CHILIMIT. The RESIDUALLIMIT function uses both methods depending upon
% data set size.
%
% End of CHILIMIT demo   
 
echo off
  
