function ll = lbeta(p, x)
%LBETA Utility function called by PARAMMLE for BETA
%
%I/O: ll = lbeta(p,x);

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

n    = length(x) ;
ahat = p(1) ;
bhat = p(2) ;
xx   = betadf('density',x,ahat,bhat) ;
ll   = -sum(log(xx)) ;
