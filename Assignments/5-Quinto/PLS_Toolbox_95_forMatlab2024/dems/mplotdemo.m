echo on
%MPLOT Demo of the MPLOT function
 
echo off
%Copyright Eigenvector Research, Inc. 2006
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%06/10/04 rsk
 
echo on
 
%To run the demo hit a "return" after each pause
 
pause
%---------------------------------- 
 
% MPLOT automatically creates subplots in a figure. This can be much quicker
% than using the Matlab 'subplot' command. 
%
% In this demo we will create a scores plot then subdivide it with mplot
% and create scores plots on the subplots of the figure.
%
% Load the 'arch' demo dataset.
 
load arch
 
pause
%-------------------------------------------------
% Create a pca model with 5 PCs using an options structure to turn off
% plots and displays.
 
opts = pca('options');
opts.display = 'off';
opts.plots   = 'none';
 
mod  = pca(arch,5,opts);
 
pause
%-------------------------------------------------
% Now create a scores plot using the 'plotscores' command. 
 
plotscores(mod);
 
% Instead of issuing 4 commands to the 'subplot' command, use the mplot
% command. This will add 4 empty subplots (2 x 2) to the scores figure.
 
pause
%-------------------------------------------------
mplot(4)
 
pause
%-------------------------------------------------
% The Scores figure should now have 4 blank subplots. To plot on one of the
% subplots, simply click on it then go the Plot Controls figure and select
% the data to be plotted. Continue doing this for each subplot.
%
% NOTE: If you choose to Select data points using Plot Controls, be
% careful to only select points on the subplot you're working with. The
% selection tool will allow you to select from more than one subplot
% thereby causing problems with plotgui.
%
% End of MPLOTDEMO
 
echo off
