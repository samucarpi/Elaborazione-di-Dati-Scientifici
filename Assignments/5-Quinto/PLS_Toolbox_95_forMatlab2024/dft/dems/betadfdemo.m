echo on
%BETADFDEMO Demo of the BETADF function.
 
echo off
%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% This demo will demonstrate how to call the various methods of the BETADF
% function. The code presented in this demo is applicable to all other
% distribution function in the toolbox.
%
% Distribution functions have the general form of:
%
%      distribution = beatdf(method, x, parameterA, parameterB)
%
% Where 'method' descibes what function to use, 'x' is the sample data,
% 'parametereA' and 'parameterB' are the parameter inputs for a 2 parameter
% function.
%
% To see the I/O for betadf, issue the following command at the command
% line:
% 
 
betadf io
 
pause
%-------------------------------------------------
% You will see that four methods are available as the first input to the
% function. When calling the function you can use either the full name of
% the method or an abbreviation:
%
%   ('cumulative', 'c')      - Cumulative distribution (probability) function (CDF).
%   ('density', 'd')         - Probability density function (PDF).
%   ('quantile', 'q', 'inv') - Quantile (inverse probability) function.
%   ('random', 'r')          - Random number generator.
% 
 
pause
%-------------------------------------------------
% A simple call the 'cumulative' method might look like this:
% 
x = 0.1;
a = 2;
b = 2;
p = betadf('c',x,a,b)
 
pause
%-------------------------------------------------
% The same syntax can be used for the 'density' and 'quantile' methods. For
% instance:
%
 
y = betadf('d',x,a,b)
q = betadf('q',x,a,b)
 
pause
%-------------------------------------------------
% The sample input 'x', can be a vector or multi dimensional array as well.
% To create a plot of beta density using different parameters create a
% vector for 'x', try several different setting for the parameters, then
% plot the result:
% 
 
x = 0.01:0.01:0.99;
 
p1 = betadf('d',x,2,2);
p2 = betadf('d',x,2,4);
p3 = betadf('d',x,.5,1);
p4 = betadf('d',x,.5,.5);
 
subplot(2,2,1);plot(x,p1);title('a = 2    b = 2')
subplot(2,2,2);plot(x,p2);title('a = 2    b = 4')
subplot(2,2,3);plot(x,p3);title('a = .5    b = 1')
subplot(2,2,4);plot(x,p4);title('a = .5    b = .5')
 
pause
%-------------------------------------------------
% When calling the 'random' method the sample ('x') input describes the
% size of the output matrix requested. To generate a vector of numbers based
% on the beta distribution use code similar to the following:
 
br = betadf('r',[5000 1],2,4);
 
% Now create a histogram of the result:
 
hist(br,50);
 
pause
%-------------------------------------------------
% Again, in general, any of the code seen in this demo can be applied to
% all of the distribution functions in the toolbox.
%
%End of BETADFDEMO
 
 
echo off
