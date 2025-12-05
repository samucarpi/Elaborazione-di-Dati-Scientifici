function ll = ltdis(p, x)
%LTDIS Utility function called by PARAMMLE for Student's t distribution.
%
%  Ref: Johnson and Kotz, Distributions in Statistics, 1994.
%
%I/O: ll = ltdis(p,x);

%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

n    = length(x) ;
ahat = p(1) ;
if ahat >= 1e6
	ahat = 1e6 ;
end
bhat = p(2) ;
xx   = tdf('density',x,ahat,bhat) ;
ll   = -sum(log(xx)) ;
