echo on
% RESIDUALLIMITDEMO Demo of the RESIDUALLIMIT function
 
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
% The RESIDUALLIMIT function calculates a confidence limit for sum squared
% residuals such as Q values in PCA models. It takes as input the matrix or
% arrary of residuals, i.e. differences between the model and the actual
% data. These residuals can also be from PARAFAC type models, or any other
% method that models matrices or n-way arrays. The second input to the
% function is the desired fractional confidence level (cl).
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
% Visualizing the sum squared residuals from each sample (they are stored in
% the ssqresiduals field of the model) in a histogram:
 
pause
%-------------------------------------------------
figure, hist(modl.ssqresiduals{1},50)
 
pause
%-------------------------------------------------
% We can generate the matrix of residuals using the DATAHAT
% function:
 
[xhat,resids] = datahat(modl,part1);
 
% Now, use these residuals to calculate the 95% confidence level
% (confidence level is given in fractional form = 0.95) using the
% method of Jackson and Mudholkar:
 
options.algorithm = 'jm';
reslim = residuallimit(resids,0.95,options)
 
pause
%-------------------------------------------------
% Plotting this limit on the histogram...
 
figure, hist(modl.ssqresiduals{1},50)
vline(reslim,'r--'), shg
 
pause
%-------------------------------------------------
% Counting the number of observed residual values below the given level and
% dividing by the number of samples in the data set (300) gives the
% fraction that were OBSEVERED below this level. Depending on the number of
% samples in the data and how well the residuals follow a chi-squared
% distirbution, this should be nearly equal to the confidence level
% fraction requested!
 
sum( modl.ssqresiduals{1} < reslim ) / 300
 
pause
%-------------------------------------------------
% The RESIDUALLIMIT function can also be used to get limits using the
% CHILIMIT function:
 
options.algorithm = 'chi2';
reslimc = residuallimit(resids,0.95,options)
 
pause
%-------------------------------------------------
% This limit is just slightly different than the one calculated using 'jm'.
% We can again check for the fraction OBSERVED below this level:
 
sum( modl.ssqresiduals{1} < reslimc ) / 300
 
% End of RESIDUALLIMIT demo   
 
echo off
