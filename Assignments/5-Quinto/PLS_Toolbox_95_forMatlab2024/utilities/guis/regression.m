function regression(varargin)
%REGRESSION Regression with graphical user interface.
%  Constructs linear regression models using a graphical user 
%  interface. Data, variable and sample scales, and variable
%  and sample labels can be loaded from the workspace or a file 
%  through the File menu. Choice of regression method, 
%  preprocessing, and cross validation options can be
%  selected in the Tools menu. Models can be calculated by
%  by pressing the calc button. Variance/cross-validation, 
%  scores, loadings, biplots and raw data can be viewed by 
%  clicking on the appropriate buttons.
%  Models can be saved and loaded through the File menu.
%  Previous models can thus be applied to new data. 
%
%I/O: regression
%
%See also: ANALYSIS, MODELSTRUCT, MODLRDER, PCR, PLS

%Copyright Eigenvector Research, Inc. 2001
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.


analysis pls
