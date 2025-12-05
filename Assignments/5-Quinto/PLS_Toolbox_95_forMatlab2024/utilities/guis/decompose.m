function decompose(varargin)
%DECOMPOSE Principal Components Analysis with graphical user interface.
%  Performs principal components analysis using a graphical user 
%  interface. Data, variable and sample scales, and variable and sample 
%  lables can be loaded from the workspace into the tool through the
%  File menu. Preprocessing and cross-validation options can be set
%  through the Tools menu. The "Calc" button calculates a model. 
%  Eigenvalues/cross-validation, scores, loadings, biplots and raw 
%  data can be viewed by clicking on the appropriate buttons.
%  Models can be saved and loaded through the File menu.
%  Previous models can thus be applied to new data. 
%
%I/O: decompose
%
%See also: ANALYSIS, MODELSTRUCT, MODLRDER, PCA, PLOTGUI

%Copyright © Eigenvector Research, Inc. 1996
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

analysis pca
