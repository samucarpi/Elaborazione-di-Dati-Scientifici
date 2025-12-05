echo on
% KENNARDSTONEDEMO Demo of the KENNARDSTONE function
 
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
% The KENNARDSTONE function is used to selected samples to split into 
% calibration and test sets. This method should provide uniform coverage of 
% the dataset and include samples on the boundary of the data set.
 
pause
%-------------------------------------------------
% First, we need a data set with 16 sample in the shape of a parallelogram.

% Generate the dataset
n = 16;
vertices = [0, 0; 3, 0; 4, 2; 1, 2];
v1 = vertices(2, :) - vertices(1, :);
v2 = vertices(4, :) - vertices(1, :);
rng(1);
r1 = rand(n, 1);
r2 = rand(n, 1);
data = vertices(1, :) + r1*v1 + r2*v2;

pause

% Now will split this data using the Kennard Stone algorithm and select 10 
% samples to be in our calibration set.

k = 10;  % Number of samples to select
selCal = kennardstone(data,k);

pause

% Now we will plot the data and selected samples

figure;
hold on;

% Plot all data points
%plot(data(:, 1), data(:, 2), 'ko');

% Plot selected samples for calibration set
calPoints = data(selCal, :);
plot(calPoints(:, 1), calPoints(:, 2), 'ro', 'MarkerSize', 10);

% Plot selected samples for test set
testPoints = data(~selCal, :);
plot(testPoints(:, 1), testPoints(:, 2), 'go', 'MarkerSize', 10);

% Compute and plot convex hull for calibration set
calConvHull = convhull(calPoints(:, 1), calPoints(:, 2));
plot(calPoints(calConvHull, 1), calPoints(calConvHull, 2), 'r--');

% % Compute and plot convex hull for test set
testConvHull = convhull(testPoints(:, 1), testPoints(:, 2));
plot(testPoints(testConvHull, 1), testPoints(testConvHull, 2), 'g--');

hold off;
xlabel('X 1');
ylabel('X 2');
title('Kennard-Stone Sample Selection');
axis equal;
legend('Calibration Set', 'Test Set');

% end of demo
 
echo off
