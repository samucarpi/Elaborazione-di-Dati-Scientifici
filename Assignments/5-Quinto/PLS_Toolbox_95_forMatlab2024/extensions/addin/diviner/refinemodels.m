
%REFINEMODELS Refine selected models from Diviner.
%   Refine selected models from Diviner with a few approaches: variable
%   selection, preprocessing refinement, and outlier reinclusion.
%   Additional variable selection will do iPLS on the selected models.
%   Preprocessing refinement is currently not supported. And outlier
%   reinclusion refinement aims to see if any excluded samples fit these
%   selected models within the 99% T^2 confidence limit, and if so then the
%   selected models will be built with the new sample set. Each refined
%   model will be added to the final results table, and will not replace
%   any of the selected models that were passed.
%
%  INPUTS:
%        resultstable  = results table object of models to refine,
%         refinements  = cell array of refinements to perform, can be any
%                        or all of {'variableselection' 'outliers'},
%              data    = cell array of calibration, validation and outlier
%                        data previously defined in Diviner,
%             options  = options structure for Diviner,
%                   t  = timestamp for Diviner run, identifier.
%
%  OUTPUTS:
%        resultstable  = final results table object of models to refine,
%         resultsdso   = final dataset object containing all model errors,
%     preprocesslookup = structure of preprocess lookup table for final
%                        models,
%                   t  = timestamp for Diviner run, identifier.
%
% I/O: [resultstable,resultsdso,preprocesslookup,t] = refinemodels(resultstable,refinements,data,options,t)
%
%See also: PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
