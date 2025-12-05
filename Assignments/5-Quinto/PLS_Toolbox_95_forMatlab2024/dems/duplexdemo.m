echo on
% DUPLEXDEMO Demo of the DUPLEX function
 
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
% Selected samples should provide uniform coverage of the dataset and
% include samples on the boundary of the data set. Duplex starts by
% selecting the two samples furthest from each other and assigns these to
% the calibration set. Then finds the next two samples furthest from each
% other assigns these to the test set. Then iterates over the rest of the
% samples alternating between assigning the furthest sample to the 
% calibration set and then the test set.
 
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

% Now will split this data using the Duplex algorithm and select 10 
% samples to be in our calibration set.

k = 10;
[selCal, selTest] = duplex(data,k);

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
title('Duplex Sample Selection');
axis equal;
legend('Calibration Set', 'Test Set');

% end of demo
 
echo off
