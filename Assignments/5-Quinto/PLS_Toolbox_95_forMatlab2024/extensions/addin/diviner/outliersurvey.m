
%OUTLIERSURVEY Create Robust PLS/PCA models to find outliers for Diviner.
%   For a given preprocessing in Diviner, this function creates both a
%   robust PLS and robust PCA model to try and find outliers to throw out
%   of the dataset.
%
%  INPUTS:
%           x_cal  = X-block (predictor block) class "double" or "dataset",
%           y_cal  = Y-block (predicted block) class "double" or "dataset",
%   divineroptions = options structure for Diviner run,
%       plsoptions = options structure for robust pls,
%       pcaoptions = options structure for robust pca.
%
%  OUTPUT:
%           plsmodel  = robust PLS model object,
%           pcamodel  = robust PCA model object,,
%   potentialoutliers = boolean vector indicating outlier status.
%
% I/O: [plsmodel,pcamodel,potentialoutliers] = outliersurvey(x_cal,y_cal,divineroptions,plsoptions,pcaoptions)
%
%See also: DIVINER PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
