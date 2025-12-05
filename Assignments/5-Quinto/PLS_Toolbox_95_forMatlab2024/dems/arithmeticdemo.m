echo on
% ARITHMETICDEMO Demo of the ARITHMETIC function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%bmw
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The ARITHMETIC function is used to apply simple arithmetic operations to 
% all or part of an array or dataset. An input 'const' is used to define
% the operation.The default operation leaves the data unchanged. 
% The supported operations are to:
% 'add', 'subtract', 'multiply', 'divide', 'inverse', 'power', 'root',
% 'modulus', 'round', 'log', 'antilog', 'noop'.
%
% These are applied element-wise, so 'multiply' is applied as '.*' for 
% example, multiplying each element by the specified 'const' value.
% See 'help arithmetic' for more information on these operations.
 
pause
%-------------------------------------------------
%
% Create an example data array.
 
x = reshape(1:50, 5, 10)
 
% or x = dataset(x);
 
pause
%-------------------------------------------------
%
% We now apply the 'add' operation to all of x, adding a const value = 100.
%
const = 100; 
xnew = arithmetic(x, 'add', const)  
 
% Notice how all values are increased by the 'const' value.
 
pause
%-------------------------------------------------
%
% Next, we divide a selected sub-set of the array elements by a const value.
% Divide elements on rows 2 and 3, columns 3, 4 and 5 only.
%
indices = {[2:3] [3:5]};
xnew = arithmetic(x, 'divide', const, indices)
 
% This shows only those six elements have been changed.
 
pause
%-------------------------------------------------
%
% Next, apply the 'inverse' operation to all elements on column 4.
% This sets new elements x_ij = const/x_ij.
 
indices = {4};
modes     = 2;
xnew = arithmetic(x, 'inverse', const, indices, modes)
 
% See that all the elements in column 4 are changed.
 
pause
%-------------------------------------------------
%
% Finally, we can undo the operation by choosing the reverse operation,
% or by setting the option 'isundo'=true.
% Here we use the second method to undo our last operation:
 
options = arithmetic('options');
options.isundo = true;
xundone = arithmetic(xnew, 'inverse', const, indices, modes, options)
 
% This shows the 'inverse' operation's effects has been undone.
%
% End of demo.
 
echo off
  
   
