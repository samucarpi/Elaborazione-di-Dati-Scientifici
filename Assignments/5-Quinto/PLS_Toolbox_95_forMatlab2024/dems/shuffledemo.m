echo on
% SHUFFLEDEMO Demo of the SHUFFLE function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The SHUFFLE function randomly reorders the rows of a data matrix
% and is often used to intermix otherwise ordered samples.
% For example, consider the data:
 
echo off
x = [1 2 3;
  10 20 30;
  100 200 300;
  1000 2000 3000];
disp('  ')
x
 
echo on
pause
%-------------------------------------------------
% Passing x into shuffle returns:
 
xr = shuffle(x)
 
pause
%-------------------------------------------------
% If multiple matricies are passed to shuffle, it reorders
% each matrix the same way. This is useful when the rows of
% two matricies are related. Consider the x and y blocks:
 
echo off
y = [1;2;3;4];
disp('  ')
x
y
 
pause
%-------------------------------------------------
echo on
 
% Passing both of these into shuffle returns:
 
[xr,yr] = shuffle(x,y)
 
% Note that the "1" in the y block is still in the same row as the 1 in the
% x block.
 
pause
%-------------------------------------------------
% Remember that for the multi-block call to work, all matricies must have
% the same number of rows.
 
echo off
  
   
