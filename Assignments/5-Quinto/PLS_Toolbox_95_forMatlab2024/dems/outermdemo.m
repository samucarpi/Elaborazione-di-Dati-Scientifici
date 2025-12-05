echo on
%OUTERMDEMO Demo of the OUTERM function
 
echo off
%Copyright Eigenvector Research, Inc. 2003
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% OUTERM is used to create a multi-way matrix from original vectors and is
% an n-way extension of the simple outer product (x*y). For eaxmple, a
% three-way matrix of size (m by n by p) of rank (k) can be made from
% matricies a, b and c where a is (m by k), b is (n by k) and c is (p by
% k)
 
pause
%-------------------------------------------------
% Three-way rank 1 example:
a = [1 2 3]'
b = [.1 .3 0 .2]'
c = [180 pi]'
 
% The result is...
pause
%-------------------------------------------------
outerm({a b c})
 
pause
%-------------------------------------------------
% By adding extra columns to EACH mode, we get higher-rank results:
% Three-way rank 2 example
 
pause
%-------------------------------------------------
a = [1 2 3; 4 5 6]'
b = [.1 .3 0 .2; .3 .4 .1 .2]'
c = [180 pi; 360 pi*2]'
 
% The result is...
pause
%-------------------------------------------------
outerm({a b c})
 
pause
%-------------------------------------------------
% This extends to multiple dimenstions logically: Four-way rank 1 example
a = [1 2 3]'
b = [.1 .3 0 .2]'
c = [180 pi]'
d = [16 12]'
 
% The result is...
pause
%-------------------------------------------------
outerm({a b c d})
 
%End of OUTERMDEMO
%
echo off
