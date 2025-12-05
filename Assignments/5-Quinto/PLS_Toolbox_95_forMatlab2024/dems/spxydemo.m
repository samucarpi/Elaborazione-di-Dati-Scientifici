echo on
% SPXYDEMO Demo of the SPXY function
 
echo off
% Copyright © Eigenvector Research, Inc. 2023
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%jms
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% SPXY will select samples that provide uniform coverage of the dataset, 
% which takes into account X and Y data, and include samples on the 
% boundary of the data set.
 
pause
%-------------------------------------------------
% First, we need a data set with 16 sample in the shape of a parallelogram.
% And corresponding Y values.

n = 16;  % Number of points
vertices = [0, 0; 3, 0; 4, 2; 1, 2];
v1 = vertices(2, :) - vertices(1, :);
v2 = vertices(4, :) - vertices(1, :);
rng(1);
r1 = rand(n, 1);
r2 = rand(n, 1);
data = vertices(1, :) + r1*v1 + r2*v2;
ydata = rand(16,1);

pause

% Perform SPXY sample selection 
k = 10;  

% Now will split this data using the SPXY algorithm and select 10 
% samples to be in our calibration set.

selCal = spxy(data, ydata, k);
selTest = ~selCal;

pause

% Now we will plot the data and selected samples
figure;
hold on;

% Plot selected samples for calibration set
calPoints = data(selCal, :);
plot(calPoints(:, 1), calPoints(:, 2), 'ro', 'MarkerSize', 10);

% Plot selected samples for test set
testPoints = data(selTest, :);
plot(testPoints(:, 1), testPoints(:, 2), 'go', 'MarkerSize', 10);

% Compute and plot convex hull for calibration set
calConvHull = convhull(calPoints(:, 1), calPoints(:, 2));
plot(calPoints(calConvHull, 1), calPoints(calConvHull, 2), 'r--');

% Compute and plot convex hull for test set
testConvHull = convhull(testPoints(:, 1), testPoints(:, 2));
plot(testPoints(testConvHull, 1), testPoints(testConvHull, 2), 'g--');

hold off;
xlabel('X 1');
ylabel('X 2');
title('SPXY Sample Selection');
axis equal;
legend('Selected Calibration Set', 'Selected Test Set');

% end of demo
 
echo off
