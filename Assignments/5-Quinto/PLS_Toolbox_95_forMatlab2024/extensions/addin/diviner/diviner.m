
%DIVINER Generate optimal PLS models with varying preprocessing and variable selection.
%   Automate the building of PLS models by cycling through different
%   preprocessings, variable selection, and removing outliers.
%
%   Diviner is broken down into 3 modules:
%   Module 1:
%             *) Load in data, set preprocessing recipes.
%             *) Perform Robust PCA/PLS to identify potential outliers.
%                User has the choice to either include/exclude them. Narrow
%                down to a single sample set. Keep track of samples that
%                were left out.
%
%   Module 2:
%             *) Do full gridsearch of PLS models based on preprocessing
%                recipes, variable selection, and Latent Variable
%                combinations. Cross-validate all models.
%
%   Module 3:
%             *) Apply to test set, if present. Create final table of models.
%                Show results. Ask user if they want to refine any of those
%                models based on preprocessing, variable selection, or
%                outlier reinclusion. If any refinement is chosen, circle
%                back to Module 2 with those models.
%
%  INPUTS:
%        x  = X-block (predictor block) class "double" or "dataset",
%        y  = Y-block (predicted block) class "double" or "dataset".
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%           alpha: [ {0.9} ] (1-alpha) measures the number of outliers the
%                  algorithm should resist. Any value between 0.5 and 1 may
%                  be specified (default = 0.75). Only used when
%                  outlierdetection is set to 'on'.
%             cvi: {{'vet' 5}} Standard cross-validation cell (see crossval)
%                  defining a split method, number of splits, and number
%                  of iterations.
%    preprocessing: {[] []} preprocessing structures or cells for x and y blocks
%                           (see PREPROCESS). The first column pertains to
%                           the X-block preprocesing, the second column
%                           pertains to the Y-block preprocessing.
%    outlierdetection: [ {'off'} 'on' ] Governs whether or not to perfrom
%                                       outlier detection.
%    outlierpreprocessing: {[]} preprocessing structures or cells for x
%                               block to use for outlier detection. Only
%                               used when outlierdetection is set to 'on'.
%           maxlvs: [ {10} ] The maximum number of LVs the PLS models will
%                            be built out to.
% exhaustivevarselect: [ {'no'} 'yes' ] Governs the amount of variable
%                                 selection is done in the first iteration
%                                 of building PLS models. If 'no', then
%                                 'automatic' will be used. If 'yes', then
%                                 {'automatic', 'iPLS'} will be used.
%         savemodels: [ {'yes'} 'no'] Determines whether all of the final
%                                    models will be saved in the workspace.
%            plots: [ 'none' | {'final'} ]  governs level of plotting.
%        createvalset: [ {'yes'} 'no' ] Determines whether or not the data
%                          will be split into a calibration and validation set. This is only
%                          1 X and 1 Y is passed into diviner.
%   splitcaltestoptions: options structure from splitcaltest. See
%                        splitcaltest. This is only used when createvalset
%                        is 'yes'.
%
%  OUTPUT:
%     allresults = struct of results with the following fields:
%                     - errordata: dataset object with error information
%                       for each model in Diviner. This also contains
%                       several class sets for the samples.
%                     - errortable: table object containing additional information
%                       about each of the Diviner models, such as
%                       preprocessing descriptions, and contains the actual
%                       models
%                     - calibrationoutliers: vector of indices from the
%                       calibration set the were excluded from calibration
%                     - preprocesslookup: lookup table for preprocessing
%                       classes
%
% I/O: [allresults] = diviner(x,y,options);
% I/O: [allresults] = diviner(x_cal,y_cal,x_val,y_val,options);
%
%See also: PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
