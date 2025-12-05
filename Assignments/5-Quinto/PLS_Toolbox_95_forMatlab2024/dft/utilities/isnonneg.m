function tf = isnonneg(x)
%ISNONNEG verifies that X is nonnegative.
%  Returns a 1 if true and a 0 otherwise.
%  NaN and inf are not tested.
%
%Examples:
%  isneg([1 2.1 inf NaN])   returns 1
%  isneg([-1 -2.1 inf NaN]) returns 0
%
%I/O: tf = isnonneg(x);
%
%See also: ISINT, ISNEG, ISPOS, ISPROB, ISSCALAR

% Copyright © Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
% NBG 04/03

if any(x(find(isfinite(x))) < 0) 
	tf = 0 ;
else
	tf = 1 ;
end
