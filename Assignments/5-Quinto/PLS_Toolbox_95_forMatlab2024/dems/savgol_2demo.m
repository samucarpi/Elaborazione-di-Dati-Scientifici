echo on
% SAVGOL_2DEMO Demo of the RMEXCLD_3 function
 
echo off
% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The SAVGOL_2 function is used to calculate spatial derivatives across
% images. SAVGOL_2 calls the RMEXCLD_2 function to remove edges and 
% excluded pixels that can adversely effect the signal included in spatial
% derivatives [and subsequent covariance matrice(s) of the resulting
% derivative matrices]. SAVGOL_2 is called by MAXAUTOFACTORS.
 
% Savgol_e operators operate both down the columns and across the rows of 
% an image. It can also be used across spectral modes in N-way data.
 
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
t           = t.data(:,1);
 
% Plot the original image w/ excluded pixels
figure('Name','Original Image')
imagesc(reshape(t,x.imagesize)), axis image
iexc        = setdiff(1:prod(x.imagesize),x.include{1});
hidepixels(iexc,x.imagesize); colorbar
title('Original Image with a few excluded pixels.'), figfont
 
% Next, run SAVGOL_2 with a window size of w=3 and obtain 1st derivative
% images.
 
pause
 
[xc,xh]     = savgol_2(x,3,2,1);
 
echo off
 
model       = pca(xc,1,struct('display','off','plots','none'));
t           = plotscores(model);
t           = t.data(:,1);
figure('Name','Down the Columns')
imagesc(reshape(t,xc.imagesize)), axis image
iexc        = setdiff(1:prod(xc.imagesize),xc.include{1});
hidepixels(iexc,xc.imagesize); colorbar
title('First derivative image with excluded pixels down the columns.'), figfont
 
pause
 
% surf(reshape(t,xc.imagesize))
% title('First derivative surface down the columns.'), figfont
%  
% pause
%  
model       = pca(xh,1,struct('display','off','plots','none'));
t           = plotscores(model);
t           = t.data(:,1);
figure('Name','Across the Rows')
imagesc(reshape(t,xh.imagesize)), axis image
iexc        = setdiff(1:prod(xh.imagesize),xh.include{1});
hidepixels(iexc,xh.imagesize); colorbar
title('First derivative image with a excluded pixels across the rows.'), figfont
 
pause
 
% surf(reshape(t,xh.imagesize)), axis image
% title('First derivative surface across the rows.'), figfont
%  
% pause
 
echo on
 
% Now try the same example with a window width, w = 5.
% The scores are smoother across the image.
 
pause
 
[xc,xh,covc,covh] = savgol_2(x,5,2,1);
 
echo off
model       = pca(xc,1,struct('display','off','plots','none'));
t           = plotscores(model);
t           = t.data(:,1);
figure('Name','Down the Columns')
imagesc(reshape(t,xc.imagesize)), axis image
iexc        = setdiff(1:prod(xc.imagesize),xc.include{1});
hidepixels(iexc,xc.imagesize); colorbar
title('First derivative image with excluded pixels down the columns.'), figfont
 
pause
 
% surf(reshape(t,xc.imagesize))
% title('First derivative surface down the columns.'), figfont
%  
% pause
%  
model       = pca(xh,1,struct('display','off','plots','none'));
t           = plotscores(model);
t           = t.data(:,1);
figure('Name','Across the Rows')
imagesc(reshape(t,xh.imagesize)), axis image
iexc        = setdiff(1:prod(xh.imagesize),xh.include{1});
hidepixels(iexc,xh.imagesize); colorbar
title('First derivative image with a excluded pixels across the rows.'), figfont
 
%End of SAVGOL_2DEMO
%See also: MAXAUTOFACTORS, RMEXCLD_2DEMO
 
echo off
