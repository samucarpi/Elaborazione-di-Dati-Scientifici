echo on
%UNHISTDEMO Demo of the UNHIST function
 
echo off
%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The unhist function is used to create a vector of values that follow an
% empirical distribution described by two vectors, x and y. The output
% vector can be used to either summarize the empirical distribution, or as a
% source for values which follow the empirical distribution.
 

pause
%-------------------------------------------------
% The first example will generate a normal distribtion, then show how the
% unhist function can be used to create a vector of values following this
% distribtion.
%
% First, we create a density profile for a normal distribution, centered at
% a value of 45 with a width of 15 (in x-units):
 
x = 1:100;   %range of x-values
y = normdf('density',x,45,15);
 
figure
plot(x,y);
ylabel('Sacled Frequency of Appearance');
xlabel('Value of X');
 
pause
%-------------------------------------------------
% Next, we use unhist to get a vector of values whose distribution matches
% this density profile with a total of 1000 points in the vector
 
d = unhist(x,y,1000);
 
pause
%-------------------------------------------------
% The histogram of this vector is the same as the density profile (with the
% exception that the number values has been scaled because of the finite
% length of d)
 
hist(d,x);
hold on
plot(x,y/sum(y)*1000,'r','linewidth',2);
hold off
ylabel('Frequency of Appearance');
xlabel('Value of X');
 
pause
%-------------------------------------------------
% We can also look at the summary statistics of this (transposed) vector
% and see that, because it is a normal distribution, it gives the expected
% mean and standard deviation (we have to transpose d because it is a
% ROW vector and summary gives a result for each column of the input).
%
% Note that the mean and standard deviation are very close to what we built
% the distribution from, but not exactly because of the approximate nature
% (number of samples we evaluated the distribution at).
 
summary(d')
 
pause
%-------------------------------------------------
% Next, we will show how unhist can be used to generate a random vector of
% values which follow some odd empirical distribution. Here we will create
% an odd distribution using a couple of the distribution fitting functions.
% Specifically, we will add a gamma distribution to a rayleigh distribution
% and a normal distribution:
 
h = gammadf('density',x,2,7)*.2...
  +raydf('density',x,30)...
  +normdf('density',x,10,20);
subplot(2,1,1)
plot(x,h)
ylabel('Scaled Frequency of Appearance');
xlabel('Value of X');
 
pause
%-------------------------------------------------
% Now, we will use unhist to get a vector of values which follow this
% distribution and get the summary statistics for this odd distribution.
 
d = unhist(x,h,1000);
summary(d')
 
pause
%-------------------------------------------------
% Next, we'll take the output values, shuffle them and plot them a couple
% of ways... First, as a random time series plot. You can see that the
% number of points observed at values above 50 is fewer than the number of
% points below 50... 
 
d = shuffle(d');
 
subplot(2,1,2)
plot(d,1:length(d),'.');
ylabel('Randomized Order');
xlabel('Value of X');
 
pause
%------------------------------------------------
% ... then we'll plot them as a histogram, building with time. Here we will
% add a random group of points from the generated vector at a time,
% building the histogram as we go.
 
subplot(2,1,2)
for j=1:5:length(d); 
  hist(d(1:j),x); 
  shg; 
  ylabel('Scaled Frequency of Appearance');
  xlabel('Value of X');
  pause(.02); 
  echo off
end
hist(d,x); 
echo on
 
%End of UNHISTDEMO
 
echo off
