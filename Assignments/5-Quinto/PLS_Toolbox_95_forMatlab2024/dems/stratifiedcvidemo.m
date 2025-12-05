echo on
% STRATIFIEDCVIDEMO Demo of the STRATIFIEDCVI function
 
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
% The STRATIFIEDCVI function is used to create a stratified 
% cross-validation index vector for given class set in a Dataset Object and
% a given cross-val method. This method will apply the cross-val method to
% each class individually and then combine the resulting cross-val index
% vectors into a single vector.
 
pause
%-------------------------------------------------
% First, we need a DataSet Object with class information in mode 1 (rows).
% This form of cross-validation is useful when there are unbalanced classes
% in your DataSet.
% Let's create a random dataset with 100 samples of 3 classes, where the
% samples 1-60 belong to class 1, samples 61-90 belong to class 2, and 
% samples 91-100 belong to class 3.

myDSO = dataset(rand(100,10));
classVec = [ones(1,60) ones(1,30)*2 ones(1,10)*3];
myDSO.class{1,1} = classVec;

pause

% now, we use cvifromclass to create a cross-validation vector using
% venetian blinds cross val method with 5 splits and blocksize of 1


cvinfo = {'con' 4};
cvi = stratifiedcvi(myDSO,1,cvinfo);

pause

% Let's plot the resulting cross-val vector to visiualize how the data will
% be split.

colors = lines(4);

figure;

% Fill the area between 1-60 with transparent red
fill([1 60 60 1], [max(cvi) max(cvi) min(cvi) min(cvi)], 'r', 'FaceAlpha', 0.3);
hold on;

% Fill the area between 61-90 with transparent blue
fill([61 90 90 61], [max(cvi) max(cvi) min(cvi) min(cvi)], 'b', 'FaceAlpha', 0.3);

% Fill the area between 91-100 with transparent green
fill([91 100 100 91], [max(cvi) max(cvi) min(cvi) min(cvi)], 'g', 'FaceAlpha', 0.3);

scatter(1:length(cvi), cvi, 50, colors(cvi, :), 'filled');
title('Cross-Val Visualization');
xlabel('Sample Index');
ylabel('CV Leave Out Group');
legend('Class 1', 'Class 2', 'Class 3', 'Data Points');
colormap(colors);

% end of demo
 
echo off