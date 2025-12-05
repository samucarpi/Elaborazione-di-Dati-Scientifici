echo on
% AUTODEMO Demo of the AUTO function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The AUTO function is used to autoscale data matrices, i.e. turn
% each column into a variable of zero mean and unit variance. As
% an example, consider the following data table x:
 
echo off
x = [15 5 10 
     30 4 15 
     45 6  5 ];
echo off
disp('  ')
disp(x)
 
pause
%-------------------------------------------------
echo on
 
% The means of the columns of x are:
 
mean(x)
 
% and the standard deviations of the columns are
 
std(x)
 
pause
%-------------------------------------------------
% A plot of the unscaled data follows
echo off
h = figure;
subplot(211)
plot(x','-o','linewidth',2), legend('Sample 1','Sample 2','Sample 3')
xlabel('Variable Number'), title('Unscaled Data')
echo on
 
% You can autoscale x using the AUTO function as follows
 
[ax,mx,stdx] = auto(x);
 
% where ax is the autoscaled data, mx is the mean and stdx is the
% standard deviation of the original data. 
 
pause
%-------------------------------------------------
% We can plot the autoscaled data
echo off
subplot(212)
plot(ax','-o','linewidth',2), legend('Sample 1','Sample 2','Sample 3')
xlabel('Variable Number'), title('Autoscaled Data')
axis([1 3 -1.2 1.2])
echo on
 
pause
%-------------------------------------------------
% It is now easily seen that each variable has zero mean and unit variance.
%
% AUTO also handles the case of missing data (indicated by NaNs) by autoscaling the 
% available data.
 
%End of AUTODEMO
 
echo off
  
   
