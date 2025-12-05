function binary = isscal(x)
%ISSCAL verifies that (x) is a scalar.
%  Returns a 1 if true and a 0 otherwise.
%
%I/O: binary = isscal(x);

%Copyright (c) 2000 Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998

[r,c] = size(x) ;
if r*c > 1
	binary = 0 ;
else
	binary = 1 ;
end
