function prob = ensurep(prob)
%ENSUREP verifies that x contains only probabilities in [0,1].
%  The input is a real (x) and the output is (prob).
%    If x > 1, then prob = 1.
%    If x < 0, then prob = 0.
%    If x imaginary, inf, or NaN, then prob = NaN.
%
%I/O: prob = ensurep(x);
%
%See also: ISPROB

%Copyright (c) Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.

%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
%nbg 04/03

prob(find(prob>1 & ~isnan(prob) & ~isinf(prob))) = 1 ;
prob(find(prob<0 & ~isnan(prob) & ~isinf(prob))) = 0 ;
prob(find(imag(prob)~=0)) = NaN ;
