function ll = ltrdis(p, x)
%LTRDIS Utility function called by PARAMMLE for TRIANGLE
%
%I/O: ll = ltrdis(p,x);

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
chat = p(3) ;
xx   = triangledf('density',x,ahat,bhat,chat);
ll   = -sum(log(xx)) ;
