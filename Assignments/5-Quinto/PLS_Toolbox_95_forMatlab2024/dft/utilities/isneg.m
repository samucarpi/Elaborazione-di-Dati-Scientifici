function tf = isneg(x)
%ISNEG verifies that X is negative.
%  If all of the contents of input (x) are negative
%  ISNEG returns a 1 and 0 otherwise.
%  NaN and inf are not tested.
%
%Examples:
%  isneg([1 2.1 inf NaN])   returns 0
%  isneg([-1 -2.1 inf NaN]) returns 1
%
%I/O: tf = isneg(x);
%
%See also: ISINT, ISNONNEG, ISPOS, ISPROB, ISSCALAR

% Copyright © Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
% NBG 04/03

if any(x(find(isfinite(x))) >= 0) 
	tf = 0 ;
else
	tf = 1 ;
end
