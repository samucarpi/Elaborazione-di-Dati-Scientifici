echo on
% RMEXCLD_2DEMO Demo of the RMEXCLD_2 function
 
echo off
% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The RMEXCLD_2 function is used to exclude pixels from images that can 
% adversely effect the signal included in spatial derivatives [and 
% subsequent covariance matrice(s)]. RMEXCLD_2 is called by SAVGOL_2 and
% MAXAUTOFACTORS..
 
% In this demo, a small image will be loaded to provide an example of how
% pixels are excluded. Hit "return" to load the image and plot it.
 
echo off
 
load aspirin
x           = aspirin; clear aspirin
 
% Exclude some pixels for the example.
x           = delsamps(x,[89 156:158 305:308 326:328],1);
 
% Create a PCA model for visualization
model       = pca(x,1,struct('display','off','plots','none'));
t           = plotscores(model);
t           = autocon(t.data(:,1));
 
% Plot the original image w/ excluded pixels
figure('Name','Original Image')
imagesc(reshape(t,x.imagesize)), axis image
iexc        = setdiff(1:prod(x.imagesize),x.include{1});
hidepixels(iexc,x.imagesize);
title('Original Image with a few excluded pixels.')
 
% Next, run RMEXCLD_2 to provide indices of excluded pixels
% across the rows and down the columns using the default
% window width, w = 3.
 
% Also plot the same image with pixels excluded down the columns of
% the image. Followed by an image across the rows.
 
pause
 
echo on
 
[iinc,jinc] = rmexcld_2(x.imagesize,x.include{1});
figure('Name','Down the Columns')
imagesc(reshape(t,x.imagesize)), axis image
iexc        = setdiff(1:prod(x.imagesize),iinc);
hidepixels(iexc,x.imagesize);
title('Image with a excluded pixels down the columns.')
 
pause
 
figure('Name','Across the Rows')
imagesc(reshape(t,x.imagesize)), axis image
iexc        = setdiff(1:prod(x.imagesize),jinc);
hidepixels(iexc,x.imagesize);
title('Image with a excluded pixels across the rows.')
 
echo on
 
% Now try the same example with a window width, w = 5.
 
pause
 
[iinc,jinc] = rmexcld_2(x.imagesize,x.include{1},5);
 
echo off
figure('Name','Down the Columns')
imagesc(reshape(t,x.imagesize)), axis image
iexc        = setdiff(1:prod(x.imagesize),iinc);
hidepixels(iexc,x.imagesize);
title('Image with a excluded pixels down the columns.')
 
pause
 
figure('Name','Across the Rows')
imagesc(reshape(t,x.imagesize)), axis image
iexc        = setdiff(1:prod(x.imagesize),jinc);
hidepixels(iexc,x.imagesize);
title('Image with a excluded pixels across the rows.')
 
%End of RMEXCLD_2DEMO
% See also: MAXAUTOFACTORS, SAVGOL_2DEMO
 
echo off
