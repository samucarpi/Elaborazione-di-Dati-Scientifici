echo on
% MANROTATEDEMO Demo of the MANROTATE function
 
echo off
% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%jms

echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The MANROTATE function is used to graphically rotate a model to
% investigate the loadings responsible for given directions in a
% score vs. score scatter plot. Given a model, MANROTATE creates a GUI in
% which the user can view the Score/Score plot and rotate the loadings
% to investigate which variable loadings are responsible for, and
% orthogonal to, a given direction in the scores plot.
%
% The user clicks on the heavy lines in the scores plot and "drags" them to
% point in a selected direction. The loadings (shown on the right in the
% figure) are automatically updated to show the loading which accounts for
% the new direction in the scores plot. The rotated loading vectors can be
% saved to the workspace using the toolbar save button.
 
pause
%-------------------------------------------------
% To demonstrate the use of MANROTATE, we will first create a PCA model of
% the ARCH dataset. This data contains several classes of samples and the
% PCA scores/scores plot shows interesting clustering of the different
% classes. 
 
load arch
 
pause
%-------------------------------------------------
% And now we'll create a 4 PC model of the data using autoscaling
% preprocessing: 
 
opts = pca('options');
opts.preprocessing = {'autoscale'};
opts.plots = 'none';
opts.display = 'off';
 
model = pca(arch,4,opts);
 
pause
%-------------------------------------------------
% Finally, all we have to do to use MANROTATE is to call it with the model
% as input. Once the GUI appears, try clicking on the heavy "vectors" in
% the left-side axes and drag them to point towards a cluster. The colored
% lines in the right-side axes show which variables are responsible for
% that direction. 
  
pause
%-------------------------------------------------
 
manrotate(model)
 
pause
%-------------------------------------------------
% If you want to save the rotated loadings (as a raw matrix), use the save
% button in the toolbar of the figure.
 
pause
%-------------------------------------------------
% You may have noticed that, by default, MANROTATE shows the first two PCs
% in the figure. You can also show PCs other than the first two by simply
% providing which PCs you wanted as the second input to manrotate. For
% example, the following command will present the 2nd and 4th PCs:
 
manrotate(model,[2 4])
 
%End of MANROTATEDEMO
 
echo off
