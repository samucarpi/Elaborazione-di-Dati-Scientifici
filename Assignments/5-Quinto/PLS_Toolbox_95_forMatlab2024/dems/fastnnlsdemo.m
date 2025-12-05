echo on
%FASTNNLSDEMO Demo of the FASTNNLS function
 
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
% Generate a regression data set where some true
% coefficients are negative
 
X = rand(20,7);
btrue = [-rand(2,1);rand(5,1)]
y = X*btrue + randn(20,1)*.1;
pause
%-------------------------------------------------
% Find the least squares solution and associated fit
% to the regression problem min||y-X*b||
 
b   = pinv(X)*y
fit1 = sum((y-X*b).^2)
pause
%-------------------------------------------------
% Set the negative regression coefficients to
% zero and check the fit
 
bzero = b;
bzero(bzero<0) = 0
fit2 = sum((y-X*bzero).^2)
pause
%-------------------------------------------------
% The fit is worse per definition, but is 
% the solution an optimal solution under 
% the constraint of having nonnegative
% regression coefficients?
%
% FASTNNLS will give the least squares 
% solution under this constraint
pause
%-------------------------------------------------
bnnls = fastnnls(X,y)
fit3 = sum((y-X*bnnls).^2)
pause
%-------------------------------------------------
 
% As seen, the solution is better than
% the ad hoc solution (but still worse
% than the unconstrained solution).
%
% If you run the demo several times
% you will also see that it is not 
% necessarily only the truly negative
% coefficients that turn zero in the 
% least squares solution
 
% See "help fastnnls" or "fastnnls help".
%
%End of FASTNNLSDEMO
 
echo off
