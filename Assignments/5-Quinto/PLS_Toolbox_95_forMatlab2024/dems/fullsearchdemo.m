echo on
%FULLSEARCHDEMO Demo of the FULLSEARCH function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% FULLSEARCH can be used for variable selection. In this example
% synthetic data will be created that obviously has only 2 variables
% relevant to prediction.
%
% Create data:
 
x = [0:10]';
x = [x x.^2 randn(11,1)*10];
y = x*[1 1 0]';
 
figure
subplot(3,1,1), plot(x(:,1),y,'o'), title('y vs. x_1')
subplot(3,1,2), plot(x(:,2),y,'o'), title('y vs. x_2')
subplot(3,1,3), plot(x(:,3),y,'o'), title('y vs. x_3')
 
% Note that x(:,3) is clearly not relevant to predicting y.
 
pause
%-------------------------------------------------
% Next create an objective function that is to be minimized.
% We'll use the INLINE function to create a "one-liner".
% The function I want to minimize is the sum of squared error
%   O(isel) = sum( (y-x*b).^2 )
% where (isel) will be the indices of the columns of (x), and
% (b) is the regression vector from MLR b = x\y.
%
 
g = inline('sum((y-x*(x\y)).^2)')
 
% When FULLSEARCH is called ( [d,fv] = fullsearch(g,x,2,y); )
% sub-matrices of (x) will be used so that the objective function
% evaluated at each step is
%   O(isel) = sum( (y-x(:,isel)*b(isel)).^2 )
% where b(isel) = x(isel)\y;
 
pause
%-------------------------------------------------
% Call FULLSEARCH, where (d) is a matrix of 1's (variable used)
% and 0's (variable not used), and (fv) is the objective function
% values. Note that each row of (d) is a new MLR model and each
% row of (fv) is the value of the objective function for that model.
%
 
[d,fv] = fullsearch(g,x,2,y);
 
% Next, we'll plot the results.
 
pause
%-------------------------------------------------
figure
subplot(2,1,1), bar(double(d(1,:))), title('Variables at Minimum')
subplot(2,1,2), plot(fv,'-o'), title('Sum of Squares for each model')
 
% Note that Variable 1 and 2 of (x) were selected as relevant
% for prediction of (y).
%
%End of FULLSEARCHDEMO
 
echo off
