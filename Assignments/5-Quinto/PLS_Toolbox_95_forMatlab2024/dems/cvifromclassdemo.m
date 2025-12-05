echo on
% CVIFROMCLASSDEMO Demo of the CVIFROMCLASS function
 
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
% The CVIFROMCLASS function is used to create a cross-validation index 
% vector for given class set in a Dataset Object and a given cross-val 
% method.
 
pause
%-------------------------------------------------
% First, we need a DataSet Object with class information in mode 1 (rows).
% This form of cross-validation is useful when there are many classes in
% your DataSet.
% Let's create a random dataset with 300 samples of 30 classes, so 10
% samples per class.

myDSO = dataset(rand(300,10));
classes = cellstr(strcat('Class ', num2str((1:30).')));
repetitions = 10;
resultCellArray = repmat(classes, repetitions, 1);
myDSO.class{1,1} = sort(resultCellArray);

pause

% now, we use cvifromclass to create a cross-validation vector using
% venetian blinds cross val method with 5 splits and blocksize of 1


cvinfo = {'vet' 5 1};
cvi = cvifromclass(myDSO,1,cvinfo);

pause

% Let's plot the resulting cross-val vector to visiualize how the data will
% be split.

colors = lines(5);
figure;
scatter(1:length(cvi), cvi, 50, colors(cvi, :), 'filled');
title('Cross-Val Visualization');
xlabel('Sample Index');
ylabel('CV Leave Out Group');
colormap(colors);

% end of demo
 
echo off