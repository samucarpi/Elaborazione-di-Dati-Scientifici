
%UNIQUEPREPROCESSING Obtain unique preprocessings for Diviner.
%   Sift through the preprocessings for both X and Y to remove empties and
%   to return only the structures and descriptions for the unique ones.
%
%  INPUTS:
%     recipes          = full cell array of preprocessing structures for
%                        X and Y.
%
%  OUTPUT:
%     unqXpp           = unique X preprocessing structures,
%     unqXppD          = description of unique X preprocessing structures,
%     unqYpp           = unique Y preprocessing structures,
%     unqYppD          = description of unique D preprocessing structures,
%
% I/O: [unqXpp,unqXppD,unqYpp,unqYppD] = uniquepreprocessing(recipes)
%

%See also: DIVINER PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
