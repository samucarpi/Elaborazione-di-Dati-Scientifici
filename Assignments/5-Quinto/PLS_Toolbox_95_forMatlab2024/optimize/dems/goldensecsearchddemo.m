echo on
%GOLDENSECSEARCHDDEMO Demo of the GOLDENSECSEARCHD function
 
echo off
%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% This is a demonstration of a Golden Section search
% algorithm for discrete variables.
 
% The first example shows how to use the inline function
% for a quadradic function "g".
 
x = [-10:10];
g = inline('x.^2');
[d,fv] = goldensecsearchd(g,x);
 
pause
 
% Plot the results
figure
plot(x,g(x),'b'), vline(x(d))
title(sprintf('Minimum of %1.1f at x(%d)',fv,d))
 
pause
 
%-------------------------------------------------
% The second example shows what happens when the
% minimum is on the boundary. In this case, the function
% warns the user that the function does not appear to
% be convex, and returns the results at the smaller
% boundary.
 
x = [0:10];
[d,fv] = goldensecsearchd(g,x);
 
pause
 
% Plot the results
plot(x,g(x),'b'), vline(x(d))
title(sprintf('Minimum of %1.1f at x(%d)',fv,d))
 
%End of GOLDENSECSEARCHDDEMO
 
echo off
