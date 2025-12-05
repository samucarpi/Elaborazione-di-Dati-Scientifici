
%SELECTBESTMODELS Select best models from Diviner for refinement.
%   Select the best performing models to save or to refine. User has the
%   option to select the models from a plotgui plot of the errors of each
%   of the models.
%
%  INPUTS:
%     results            = table object of results from model calibration,
%     resultsdso         = dataset object of model results, indices
%                          correspond to the indices in the results variable,
%     data               = cell array of calibration, validation, and
%                          excluded data,
%     options            = structure of options for Diviner,
%     preprocesslookup   = cell array of X and Y preprocessings,
%     t                  = timestamp for Diviner session
%
%  OUTPUT:
%     results            = final table object of results from model refinement,
%     resultsdso         = final dataset object of model results, indices
%                          correspond to the indices in the results variable,
%     preprocesslookup   = final cell array of X and Y preprocessings,
%     t                  = timestamp for Diviner session
%
% I/O: [resultstable,resultsdso,preprocesslookup,t] = selectbestmodels(results,resultsdso,data,options,preprocesslookup,t)
%
%See also: DIVINER PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
