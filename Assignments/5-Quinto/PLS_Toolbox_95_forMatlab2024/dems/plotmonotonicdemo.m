echo on
% PLOTMONOTONICDEMO Demo of the PLOTMONOTONIC function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The PLOTMONOTONIC function is used to create a plot from data which
% contains multiple segments or "runs" (e.g. batches) of continuous data
% all within a single vector of y-values and corresponding x-values. That
% is, the x-values of each segment repeat (or at least overlap).
%
% Such x,y data, when plotted using the traditional PLOT command would
% result in a single line which "doubles-back" on itself each time the
% x-values repeated. PLOTMONOTONIC recognizes these splits and shows each
% as a separate line with separate colors for the lines. These are the
% "mononically increasing" portions of the data (thus PLOTMONOTONIC).
 
pause
 
%-------------------------------------------------
% To demonstrate this function, we'll use the Metal Etch machine data.
% We'll grab one of the process variables (End Point A, the first variable)
% and the first 10 wafers (batches) in that process. There are 80 time
% points in each batch, so the data we'll be looking at will be 80 x 10
% (unfolded into a 1 x 800 long vector)
 
load etchdata
 
d = squeeze(EtchCal(:,1,1:10));  %batches 1-10 for variable 1
 
pause
%-------------------------------------------------
% Now we'll unfold the data into a long vector and view that:
 
y = d.data(:)';         %vector of EndPtA values
x = repmat(1:80,1,10);  %vector of x-axis values from 1 to 80
 
figure
plot(y)
 
% Note that the vector is just repeating itself for each batch
 
pause
%-------------------------------------------------
% Next, we create an x-vector that describes how the values in y should be
% grouped (i.e. what their corresponding x values should be on the plot)
% and we'll plot that on the top of the figure using the standard PLOT
% command.
 
x = repmat(1:80,1,10);  %vector of x-axis values from 1 to 80
 
subplot(211)
plot(x,y)
 
pause
% Note how the line doubles-back at the end of each wafer... Next we'll
% plot the same data using plotmonotonic on the lower portion of the
% figure...
 
subplot(212)
plotmonotonic(x,y)
 
% Each wafer is now shown as a separate line...

pause
%End of PLOTMONOTONICDEMO
 
echo off
  
