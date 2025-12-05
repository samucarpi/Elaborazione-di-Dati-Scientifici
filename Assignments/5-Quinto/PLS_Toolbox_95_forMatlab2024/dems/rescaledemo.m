echo on
% RESCALEDEMO Demo of the RESCALE function
 
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
% The RESCALE function is used to rescale data matrices using the specified
% offset (which is typically a previously determined mean from a calibration
% data set) and possibly a scale factor (which is typically a standard 
% deviation from a calibration set). RESCALE is the inverse of the function 
% SCALE. RESCALE multiplies by a scale factor and adds an offset, in contrast
% to SCALE, which subtracts an offset and divides by a scale factor. As an 
% example, consider the following data table x:
 
echo off
x = [-1 0 0 
     0 -1 1 
     1 1  -1 ];
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
 
% In other words, this data set is already autoscaled.
 
pause
%-------------------------------------------------
% A plot of the original data follows
echo off
h = figure;
subplot(211)
plot(x','-o','linewidth',2), legend('Sample 1','Sample 2','Sample 3')
xlabel('Variable Number'), title('Original Data')
axis([1 3 -1.2 1.2])
echo on
 
% You can rescale x using the RESCALE function and an offset (mean) and
% scale factor (standard deviation). We'll choose
 
mx = [30 5 10];
 
% and
 
stdx = [15 1 5]
 
% and apply it as follows:
 
rsx = rescale(x,mx,stdx);
 
% where rsx is the rescaled data, and mx is the offset (mean) and stdx 
% is the scale factor (standard deviation) of some original data matrix.
 
pause
%-------------------------------------------------
% We can plot the rescaled data
echo off
subplot(212)
plot(rsx','-o','linewidth',2), legend('Sample 1','Sample 2','Sample 3')
xlabel('Variable Number'), title('Rescaled Data')
echo on
 
pause
%-------------------------------------------------
% Note that SCALE is the inverse of the function RESCALE. Scale subtracts
% an offset and divides by a scale factor, whereas RESCALE multiplies by
% a scale factor and adds an offset. RESCALE can also be used without a
% scale factor to simply add an offset.
%
% RESCALE also handles the case of missing data (indicated by NaNs) by rescaling the 
% available data.
 
echo off
  
   
