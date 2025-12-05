echo on
%PLSRSGCVDEMO Demonstrates PLSRSGCV for use in MSPC
%  This is a demonstration of the PLSRSGCV function
%  that shows how it can be used for multivariate statistical
%  process control (MSPC) purposes.
 
echo off
% Copyright © Eigenvector Research, Inc. 1992
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%Modified April 1994
%Checked BMW 3/98
%BMW 4/2003
echo on
 
% Lets start by loading the pcadata file.
 
load pcadata
 
% Before we use the PLSRSGCV function, lets do a little
% PCA modeling so we'll have something to compare the 
% results to.  First, of course we have to scale the data.
pause
%-------------------------------------------------
[apart1,part1means,part1stds] = auto(part1.data);
 
% Now we can calculate the PLS equivilent of the PCA (I - PP') 
% matrix using the 'plsrsgcv' function. Hit a key when you are ready.
pause
%-------------------------------------------------
coeff = plsrsgcv(apart1,4,10,150,0);
 
% Now that we have the coeficient matrix, lets calculate and
% plot the residuals. Ready?
pause
%-------------------------------------------------
echo off
plot(apart1*coeff)
title('PLS Model Residuals for Each Sample')
xlabel('Sample Number')
ylabel('Residual')
pause
%-------------------------------------------------
echo on
 
% For information on how to calculate the limits on these
% residuals and for a comparison to PCA, please see the 
% PLSRSGN demo.
