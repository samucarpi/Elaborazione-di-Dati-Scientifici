
%MODULE3 Evaluate models for Diviner.
% Take models from Diviner and report the errors. If provided a validation
% set, then the metrics on the validation set will be reported after
% applying the models.
%
%  INPUTS:
%     resultstable = table of results for each model,
%           x_val  = X-block (predictor block) class "double" or "dataset",
%           y_val  = Y-block (predicted block) class "double" or "dataset",
%              wb  = waitbar handle.
%
%  OUTPUT:
%     resultstable = table of results for each model with validation models
%                    and metrics
%
% I/O: [resultstable] = module3(resultstable,x_val,y_val,wb)
%
%See also: DIVINER PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
