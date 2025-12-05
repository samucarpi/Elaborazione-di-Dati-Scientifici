
%CREATEREFINEWINDOW Display GUI to select model refinements for Diviner.
%   Refine models built by Diviner with variable selection, preprocessing,
%   and outlier reinclusion. Additional variable selection will do iPLS on
%   the models to be refined. Preprocessing refinement is currently not
%   available. Outlier reinclusion will try to reinclude outliers and see
%   if they are in the 99% confidence interval for Hotelling's T^2.
%
%  INPUTS:
%     resultstable        = table object of results from model calibration,
%     calibrationoutliers = vector of calibration outlier indices.
%
%  OUTPUT:
%     uifig               = uifigure of refinement window.
%
% I/O: [uifig] = createrefinewindow(resultstable,calibrationoutliers)
%
%See also: DIVINER PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
