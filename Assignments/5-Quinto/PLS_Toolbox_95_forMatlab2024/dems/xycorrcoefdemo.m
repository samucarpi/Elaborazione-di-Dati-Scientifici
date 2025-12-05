echo on
% Demo of the XYCORRCOEF function

echo off
% Copyright Eigenvector Research, Inc. 2002 Licensee shall not 
% re-compile, translate or convert "M-files" contained in PLS_Toolbox for 
% use with any software other than MATLAB®, without written permission from 
% Eigenvector Research, Inc.

echo on
% To run the demo hit a "return" after each pause
pause
% ------------------------------------------------------------------------
% XYCORRCOEF produces a plot (and if specified returns DataSet Object) of 
% correlation coefficients between the variables in X-block and the 
% variables in Y-block. We will be using the NIR demo data set in this example.
pause

load nir_data.mat

% The inputs to xycorrcoef are the x-block data and y-block data of class 
% "double" or "dataset". We will use spec1 as the x-block and conc as the 
% y-block. If no output is specified then the result is a plot with
% correlation coefficient on the Y-axis and variables on the X-axis. If an
% output is specified then the result will be a plot and DataSet Object.
% No output -> xycorrcoef(xblock, yblock)
% Output -> out = xycorrcoef(xblock, yblock)
pause

xycorrcoef(spec1, conc)

echo off
