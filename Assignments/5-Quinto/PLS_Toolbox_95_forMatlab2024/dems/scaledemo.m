echo on
% SCALEDEMO Demo of the SCALE function
 
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
% The SCALE function is used to scale data matrices using the specified
% offset (which is typically a previously determined mean from a calibration
% data set) and possibly a scale factor (which is typically a standard 
% deviation from a calibration set). As an example, consider the following 
% data table x:
 
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
 
mx = mean(x)
 
% and the standard deviations of the columns are
 
stdx = std(x)
 
pause
%-------------------------------------------------
% A plot of the unscaled data follows
echo off
h = figure;
subplot(211)
plot(x','-o','linewidth',2), legend('Sample 1','Sample 2','Sample 3')
xlabel('Variable Number'), title('Unscaled Data')
echo on
 
% You can scale x using the SCALE function and the means and standard
% deviations previously determined as follows
 
sx = scale(x,mx,stdx);
 
% where sx is the scaled data, and mx is the mean and stdx is the
% standard deviation of the original data. (In this case the result
% is autoscaled data since mx and stdx were calculated from the
% same matrix they are applied to.)
 
pause
%-------------------------------------------------
% We can plot the scaled data
echo off
subplot(212)
plot(sx','-o','linewidth',2), legend('Sample 1','Sample 2','Sample 3')
xlabel('Variable Number'), title('Scaled Data')
axis([1 3 -1.2 1.2])
echo on
 
pause
%-------------------------------------------------
% It is now easily seen that each variable has zero mean and unit variance.
%
% Note that SCALE is the inverse of the function RESCALE. SCALE subtracts
% an offset and divides by a scale factor, whereas RESCALE multiplies by
% a scale factor and adds an offset.
%
% SCALE also handles the case of missing data (indicated by NaNs) by scaling the 
% available data.
 
echo off
  
   
