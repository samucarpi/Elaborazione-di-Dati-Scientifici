echo on
%CORECALC Demo of the CORECALC function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rb
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load amino acid data set:
 
load aminoacids
 
% Fit a three-component PARAFAC model (reasonable
% number of components). 
pause
%-------------------------------------------------
model = parafac(X,3);
 
% PARAFAC can be considered a special Tucker3 model
% where the core has been fixed to a superdiagonal
% of ones. We will check if this assumption is 
% reasonable for this three-component model by
% calculating the core associated with the data
% and the PARAFAC loadings
pause
%-------------------------------------------------
 
core = corecalc(X,model);
 
 
% Looking at the elements in this core, we should
% have a 3x3x3 core which should be approximately
% zero at all elements except core(1,1,1), 
% core(2,2,2) and core(3,3,3) which should be one.
pause
%-------------------------------------------------
format bank
core
format
 
% As can be seen, the calculated core fits well 
% with expectations. The exploratory use of the core
% is used more quantitatively in CORCONDIA to
% find the right dimensionality of a PARAFAC model
%
 
% See "help corecalc" or "corecalc help".
%
%End of CORECALCDEMO
 
echo off
