
%Module1 Perform Robust Analysis to detect outliers in Diviner.
%   Perform Robust PCA/PLS to identify potential outliers. User has the
%   choice to either include/exclude them. Narrow down to a single sample set.
%
%  INPUTS:
%        x_cal  = X-block (predictor block) class "double" or "dataset",
%        y_cal  = Y-block (predicted block) class "double" or "dataset",
%        x_val  = X-block (predictor block) class "double" or "dataset",
%        y_val  = Y-block (predicted block) class "double" or "dataset",
%
%  OPTIONAL INPUT:
%   options = structure array from diviner
%
%  OUTPUT:
%        x_cal  = Calibration X dataset with include field modified,
%        y_cal  = Calibration Y dataset with include field modified,
%        x_val  = Validation X dataset with include field modified,
%        y_val  = Validation Y dataset with include field modified,
%     cal_excluded = Array of indices of samples that were excluded,
% compressionmodel = evri compression model for upfront compression,
%    cancelled = boolean indication if user cancelled the prompt,
%           wb = waitbar handle
%
% I/O: [x_cal,y_cal,cal_excluded,compressionmodel,cancelled,wb] = module1(x_cal,y_cal,options)
%
%See also: DIVINER PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
