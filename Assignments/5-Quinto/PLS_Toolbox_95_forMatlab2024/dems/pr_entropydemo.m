echo on
% PR_ENTROPYDEMO Demo of the PR_ENTROPY function
 
echo off
% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The PR_ENTROPY function is used to calculate the pattern recognition
% entropy (PRE) or Shannon entropy .
 
load StandardWireTest
 
% Calculate the PRE on the image with a small offset:
 
ax    = pr_entropy(data,1e-6,true);     %Class DataSet
 
% Next,make an image of the results versus the original (data).
 
pause
 
figure('Name','PRE of StandardWireTest');
imagesc(reshape(ax.data,data.imagesize)), axis image
colorbar
title('PRE of StandardWireTest')
 
% Next, run PCA on the image for comparison
 
pause
 
% PCA of PRE Spectrum
axs     = pr_entropy(data,1e-6);
modpre  = pca(axs,3);
 
pause
 
% PCA of Poisson Scaled Data
options = pca('options');
options.preprocessing = {preprocess('default','sqmnsc')};
modpsc  = pca(data,3,options);
 
% It is interesting to compare these results to PCA using Poisson scaling.
 
%End of PR_ENTROPYDEMO
 
% See also: ASINHX, ASINSQRT, AUTO, MNCN, POISSONSCALE
 
echo off
