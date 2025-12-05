echo on
% PERCENTILEDEMO Demo of the PERCENTILE function
 
echo off
% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The PERCENTILE function is used to estimate the given percentile
% from a distribution given in the variable (x).
 
% Consider the following data table of random numbers x:
 
x = randn(1000,3);
 
% A histogram for each variable can be plotted
pause
%-------------------------------------------------
for ii=1:3, subplot(3,1,ii), hist(x(:,ii),200), ylabel(int2str(ii)), end
 
% Next we can put percentiles on each histogram. First we'll put
% on the 95th percentile. This is the point at which 95% of the
% data have lower values.
pause
%-------------------------------------------------
p95  = percentile(x,0.95);
for ii=1:3, subplot(3,1,ii), vline(p95(ii),'r'), end
 
% Note that the percentiles were determined from the data
% and not by assuming a specific distribution.
pause
%-------------------------------------------------
% And now we can put on the 90th percentile.
 
p90  = percentile(x,0.90);
for ii=1:3, subplot(3,1,ii), vline(p90(ii),'g'), end
pause
%-------------------------------------------------
% Note that the 50th percentile is the same as the median
 
p50  = percentile(x,0.50); disp(p50)
med  = median(x);          disp(med)
  
%End of PERCENTILEDEMO
 
echo off
