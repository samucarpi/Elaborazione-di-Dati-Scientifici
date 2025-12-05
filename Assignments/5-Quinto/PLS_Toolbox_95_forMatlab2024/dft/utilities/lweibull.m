function ll = lweibull(p, x)
%LWEIBULL Utility function called by PARAMMLE for WEIBULL
%
%I/O: ll = lweibull(p,x);

%Copyright (c) 2000 Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

n    = length(x) ;
ahat = p(1) ;
bhat = p(2) ;
xx   = weibulldf('density',x,ahat,bhat);
ll   = -sum(log(xx)) ; 
