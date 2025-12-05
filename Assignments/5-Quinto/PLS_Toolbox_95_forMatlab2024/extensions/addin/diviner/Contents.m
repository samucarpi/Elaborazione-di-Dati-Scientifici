% Diviner
% Version 1.0 (Trunk) 22-August-2024
% For use with PLS_Toolbox version 9.5+
% Copyright (c) 2024 Eigenvector Research, Inc.
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%
% Help and information
%   Contents         - This file.
% Files
%   checkdivinerlogs        - Find any errors with current Diviner run.
%   createpplookup          - Create preprocessing lookup table for Diviner.
%   createprogresswindow    - Create progress window for Diviner.
%   createrefinewindow      - Display GUI to select model refinements for Diviner.
%   diviner                 - Generate optimal PLS models with varying preprocessing and variable selection.
%   evrirelease             - Returns Eigenvector product release number.
%   genresultsdataset       - Create Dataset Object of Diviner results.
%   getreconciledvalidation - get the validation X and Y data with reconcilliation with the model
%   getselection            - Turn off outlier plots to grab selection in Diviner.
%   makegrid                - Make full factorial grid of input 1xN cell arrays.
%   module1                 - Module1 Perform Robust Analysis to detect outliers in Diviner.
%   module2                 - Module2 Perform model calibration for Diviner.
%   module3                 - Evaluate models for Diviner.
%   outliersurvey           - Create Robust PLS/PCA models to find outliers for Diviner.
%   plotoutliers            - Plot and select potential outlier samples flagged by PLS/PCA.
%   preprocesslookuptable   - Display Preprocessing lookup table for Diviner.
%   prettyprintpp           - Display preprocessing structure description with commas.
%   recreatemodel           - Recreate calibration model from a Diviner run.
%   refinemodels            - Refine selected models from Diviner.
%   regv_smoothnessV2       - regv_smoothness: The regression vector smoothness
%   repstructs              - Replicate a structure M times for parallelization.
%   runbenchmarks           - Run benchmarks for Diviner across several spectral datasets.
%   selectbestmodels        - Select best models from Diviner for refinement.
%   summarizedivinerlog     - Generate wordclouds to summarize Diviner errors.
%   uniquepreprocessing     - Obtain unique preprocessings for Diviner.
%   updateprogresswindow    - Update progress of Diviner.
%   variablecompare         - Compare included variables in models from Diviner results.
%
% See also the contents for diviner/interface folder