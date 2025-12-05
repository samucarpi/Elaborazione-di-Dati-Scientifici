
%CREATEPPLOOKUP Create preprocessing lookup table for Diviner.
%   Generate a lookup table for all calibrated models in Diviner classed by
%   the different preprocessings.
%
%  INPUTS:
%     recipegrid            = full cell array of preprocessing structures from Diviner results table,
%     uniquepreprocessings  = cell array of just unique preprocessings in
%                             Diviner.
%
%  OUTPUT:
%     classnum         = preprocessing class number,
%     classdescription = description of preprocessing structure,
%     lookup           = lookup of preprocessing classes.
%
% I/O: [classnum,classdescription,lookup] = createpplookup(recipegrid,uniquerecipes)
%

%See also: DIVINER PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
