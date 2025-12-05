echo on
%SAVGOLCVDEMO Demo of the SAVGOLCV function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% SAVGOLCV performs cross-validation over Savitzky-Golay smoothing
% parameters (width, order, and deriv) and number of factors in the
% regression model. (See the SAVGOL function.) As a result, the 4D
% array is somewhat difficult to interpret.
%
% The first thing to do is load some data.
 
pause
%-------------------------------------------------
load nir_data
whos 
 
% The model of interest is a PLS model that will use the data in (spec1)
% (NIR spectra) and the first column of (conc) (analyte concentration).
 
%conc = delsamps(conc,2:5,2); %"soft delete" columns 2 to 5
 
pause
%-------------------------------------------------
% Create vectors to cross-validate over (we'll use the defaults,
% but this will show how to create the vectors for input.
 
width = [5 11 17]; %number of points in filter {default = [11 17 23]}.
order = [2 3];      %polynomial order {default = [2 3]}.
deriv = [0 1 2];    %derivative order {default = [0 1 2]}.
lv    = 12;          %total number of latent variables
 
% The cross-validation method will be venetion blinds with 3 data splits.
 
cvi   = {'vet' 6};
 
% Preprocessing will be mean centering for both x- and y-blocks.
 
pre = {preprocess('default','mean center') preprocess('default','mean center')};
 
pause
%-------------------------------------------------
% Now call SAVGOLCV (using regression method 'sim' for SIMPLS)
 
cumpress = savgolcv(spec1,conc,lv,width,order,deriv,[],'sim',cvi,pre);
 
% Next we need to examine the 4D array ...
 
pause
%-------------------------------------------------
% Each subplot has the 3 different derivatives in it
 

 % Since the Y block (conc) is multivariate, we will consider one column of Y 
 % at a time.  
iy =1;

figure
h  = min(min(min(min(cumpress))));
subplot(3,2,1), semilogy(squeeze(cumpress(:,:,1,1,iy))')
ylabel('Width=5'), title('Order = 2'), hline(h(:,:,1,1,iy))
subplot(3,2,3), semilogy(squeeze(cumpress(:,:,2,1,iy))')
ylabel('Width=11'), hline(h(:,:,1,1,iy))
subplot(3,2,5), semilogy(squeeze(cumpress(:,:,3,1,iy))')
xlabel('LV'),       ylabel('Width=17'), hline(h(:,:,1,1,iy))
subplot(3,2,2), semilogy(squeeze(cumpress(:,:,1,2,iy))')
title('Order = 3'), hline(h(:,:,1,1,iy))
subplot(3,2,4), semilogy(squeeze(cumpress(:,:,2,2,iy))'), hline(h(:,:,1,1,iy))
subplot(3,2,6), semilogy(squeeze(cumpress(:,:,3,2,iy))'), hline(h(:,:,1,1,iy))
xlabel('LV')
%  
% The horizontal line is at the global minima in the cumpress.
% There's no real distinct minima, but it looks like no derivative
% (blue line) and small width (Width=5) has a pretty good model
% at 11 LVs. (Note: considerations might lead you to select far
% few LVs e.g. 5.)
%
% Let's now just look at no derivative and Width=5.
 
pause
%-------------------------------------------------
figure
mesh([5:12],[1 2],squeeze(log(cumpress(1,5:12,1,:,iy)))'), xlabel('LV'), ylabel('Width=5')
 
% Use the rotate button on the toolbar to inspect the figures.
%
% This suggests that order doesn't have much of an effect and
% you might select 10 or 11 LV's.
 
%End of SAVGOLCVDEMO
 
echo off
