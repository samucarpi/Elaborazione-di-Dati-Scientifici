
%GENRESULTSDATASET Create Dataset Object of Diviner results.
%   Compile results from Diviner with model errors. This dataset object
%   will also contain several class sets to divide the models into groups
%   based on # Lvs, preprocessing, variable selection, and more. The
%   numeric data in the dataset is the RMSEC, RMSECV, RMSEC/RMSECV, and
%   RMSEP (if validation data is provided).
%
%  INPUTS:
%     results = table object of Diviner results,
%    unqXppD  = unique Xblock preprocessing descriptions used in Diviner,
%    unqYppD  = unique Yblock preprocessing descriptions used in Diviner.
%
%  OUTPUT:
%        dso  = dataset object of Diviner results.
%
% I/O: [dso] = genresultsdataset(results,unqXppD,unqYppD)
%
%See also: DIVINER PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
