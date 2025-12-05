
%REPSTRUCTS Replicate a structure M times for parallelization.
%   Replicate a MATLAB struct to preallocate a design of experiments for
%   parallelization.
%
%  INPUTS:
%        mystruct = structure with any fields,
%        m        = number indicating how many times the structure should
%                   be copied.
%
%  OUTPUT:
%        structs  = cell array of copied structures.
%
% I/O: [structs] = repstructs(mystruct,10)
%
%See also: DIVINER PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
