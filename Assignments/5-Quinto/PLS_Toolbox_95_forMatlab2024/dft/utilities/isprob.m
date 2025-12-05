function tf = isprob(x)
%ISPROB verifies that all of the contents of x are in [0,1].
%  Returns a 1 if true and a 0 otherwise.
%  NaN and inf are not tested.
%
%Examples:
%  isprob([0.4 2.1 inf NaN]) returns 0
%  isprob([0.4 0.8 inf NaN]) returns 1
%
%I/O: tf = isprob(x);
%
%See also: ENSUREP, ISINT, ISNEG, ISNONNEG, ISPOS, ISSCALAR

% Copyright © Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
% NBG 04/03

k = find(isfinite(x)) ;
if min(x(k)) < 0 | max(x(k)) > 1
	tf = 0 ;
else
	tf = 1 ;
end
