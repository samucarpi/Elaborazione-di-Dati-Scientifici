
%PLOTOUTLIERS Plot and select potential outlier samples flagged by PLS/PCA.
%   Perform Robust PCA/PLS to identify potential outliers. User has the
%   choice to either include/exclude them. Narrow down to a single sample set.
%
%  INPUTS:
%        x_cal  = X-block (predictor block) class "double" or "dataset",
%        y_cal  = Y-block (predicted block) class "double" or "dataset",
%        model  = Robust PLS model,
%      flagpls  = boolean vector indicating inlier/outlier from PLS,
%      flagpca  = boolean vector indicating inlier/outlier from PCA.
%
%  OUTPUT:
%        x_cal  = Calibration X dataset with include field modified,
%        y_cal  = Calibration Y dataset with include field modified,
%     excluded = Array of indices of samples that were excluded.
%
% I/O: [x_cal,y_cal,excluded] = plotoutliers(x_cal,y_cal,model,flagpls,flagpca)
%
%See also: DIVINER PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
