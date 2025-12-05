echo on
% MNCNDEMO Demo of the MNCN function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002-2020
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%bmw
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The MNCN function is used to mean center data matrices, i.e. turn
% each column into a variable of zero mean. As an example, consider 
% the following data table x:
 
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
 
pause
%-------------------------------------------------
% A plot of the unscaled data follows
echo off
h = figure;
subplot(211)
plot(x','-o','linewidth',2), legend('Sample 1','Sample 2','Sample 3')
xlabel('Variable Number'), title('Unscaled Data')
echo on
 
% You can mean center x using the MNCN function as follows
 
[mcx,mx] = mncn(x);
 
% where mcx is the mean centered data, and mx is the mean
% of the original data. 
 
pause
%-------------------------------------------------
% We can plot the mean centered data
echo off
subplot(212)
plot(mcx','-o','linewidth',2), legend('Sample 1','Sample 2','Sample 3')
xlabel('Variable Number'), title('Mean Centered Data')
echo on
 
pause
%-------------------------------------------------
% It is now easily seen that each variable has zero mean.
 
% MNCN also handles the case of missing data (indicated by NaNs) by centering the 
% available data.
 
% See also: COMPAREMNCNDEMO
echo off
 