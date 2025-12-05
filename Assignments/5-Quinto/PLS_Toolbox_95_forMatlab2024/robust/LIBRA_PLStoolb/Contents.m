% LIBRA_Toolbox for PLS_Toolbox
% Version/Date: See top-level PLS_Toolbox folder
% For use with MATLAB 6.5+
% Copyright (c) 1995-2006 Eigenvector Research, Inc.
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%
% Files
%   chiqqplot        - produces a Quantile-Quantile-plot of the vector y 
%   classSVD         - performs the singular value decomposition of a matrix with more
%   cpca             - performs a classical principal components analysis 
%   cpcr             - performs a classical principal components regression.
%   csimpls          - performs Partial Least Squares regression using the SIMPLS 
%   cvMcd            - calculates the robust cross-validated PRESS (predicted residual error sum of squares)
%   cvRobpca         - calculates the robust cross-validated PRESS (predicted residual error sum of squares) curve
%   cvRpcr           - calculates the robust RMSECV (root mean squared error of cross-validation) curve
%   cvRsimpls        - CVRIMPLS calculates the robust RMSECV (root mean squared error of cross-validation) curve
%   ddplot           - is the distance-distance plot as introduced by Rousseeuw and Van
%   distplot         - plots the vector y versus the index.
%   ellipsplot       - plots the 97.5% tolerance ellipse of the bivariate data set
%   extractmcdregres - is an auxiliary function for cross-validation with RPCR and RSIMPLS. 
%   greatsort        - sorts the vector x in descending order.
%   kernelEVD        - (kernel eigenvalue decomposition) performs a singular value decomposition
%   lsscatter        - makes a scatter plot with regression (LTS/LS) line
%   ltsregres        - carries out least trimmed squares (LTS) regression, introduced in
%   madc             - is a scale estimator given by the Median Absolute Deviation 
%   mahalanobis      - computes the distance of each observation in x
%   makeplot         - makes plots for the main functions. These figures can also be obtained 
%   mcdcov           - computes the MCD estimator of a multivariate data set.  This 
%   mcdregres        - is a robust multivariate regression method. It can handle multiple
%   mcenter          - mean-centers the data matrix x columnwise
%   mlr              - is the classical least squares estimator for multivariate multiple
%   normqqplot       - produces a Quantile-Quantile plot in which the vector y is plotted against 
%   ols              - is the classical least squares estimator for multiple
%   plotnumbers      - marks the points (x,y,z) on a plot with their index number.
%   putlabel         - plots user-specified labels to the observations in a two- or 
%   regresdiagplot   - makes a regression outlier map. 
%   regresdiagplot3d - is a 3D-outlier map which visualizes the orthogonal distance, 
%   removal          - deletes rows(r) or columns(k) from X
%   removeObsMcd     - is an auxiliary function to perform cross-validation with MCD 
%   removeObsRobpca  - is an auxiliary function to perform cross-validation with ROBPCA, 
%   residualplot     - plots the residuals from a regression analysis versus x
%   robpca           - is a 'ROBust method for Principal Components Analysis'. 
%   robpcaregres     - is a function for robust multivariate regression, based on
%   rpcr             - is a 'Robust Principal Components Regression' method based on ROBPCA.
%   rrmse            - calculates the robust RMSECV and/or the robust RMSEP-value 
%   rsimpls          - is a 'Robust method for Partial Least Squares Regression based on the
%   rsquared         - calculates the R-squared value of the robust or classical PCR/PLS analysis. This function  
%   scorediagplot    - plots the score outlier map. The score distances (SD) and 
%   screeplot        - draws the eigenvalues of the covariance matrix of the data in decreasing order.
%   unimcd           - computes the MCD estimator of a univariate data set.  This 
%   uniran           - is the uniform random generator used in mcdcov.m and ltsregres.m
%   updatecov        - This function updates the mean and covariance matrix of the full data 
%   weightmecov      - computes the reweighted mean and covariance matrix of multivariate data.
