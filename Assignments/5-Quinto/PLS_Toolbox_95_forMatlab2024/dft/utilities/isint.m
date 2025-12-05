function tf = isint(x)
%ISINT verifies that X is an integer.
%  If all of the contents of input (x) are integers
%  ISINT returns a 1, and 0 otherwise.
%  NaN and inf are not tested.
%
%Examples:
%  isint([1 2.1 3 4.3]) returns 0
%  isint([1 2 3 4 NaN]) returns 1
%  isint([1 2 3 4 inf]) returns 1
%
%I/O: tf = isint(x);
%
%See also: ISNEG, ISNONNEG, ISPOS, ISPROB, ISSCALAR

% Copyright © Eigenvector Research, Inc. 2000
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%
%Acquired from TESS, Texas Environmental Software Solutions
% Version 1.0.0, January 1998
% NBG 04/03

r    = x-fix(x);
if any((r(find(~isnan(r)))) > 0)
	tf = 0 ;
else
	tf = 1 ;
end
