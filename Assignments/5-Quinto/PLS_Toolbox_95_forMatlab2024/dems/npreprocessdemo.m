echo on
%NPREPROCESSDEMO Demo of the NPREPROCESS function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rb
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Load three-way fluorescence data:
 
load aminoacids
 
% Note that the data are 5x201x61 in a DataSet object.
 
% Plot emission-spectra at specific wavelength. (Please maximize
% the window to have a better view of the subsequent plots.)
 
figure
subplot(3,3,1)
plot(X.axisscale{2,1},X.data(:,:,30),'linewidth',3), axis tight
title(['Emission (Exc.',num2str(X.axisscale{3,1}(30)),'nm)'],'fontweight','bold')
ylabel('Intensity')
 
pause
%-------------------------------------------------
% Different types of preprocessing will be illustrated by 
% plotting these spectra after transformation.
%
% First, center the data across samples (ordinary centering
% as performed in e.g. PCA). Note that the mean of each 
% column is zero.
 
settings = [1 0 0; 0 0 0];            %center across Mode 1
[prexc1,preparc1] = npreprocess(X,settings); 
 
subplot(3,3,2)
plot(X.axisscale{2,1},prexc1.data(:,:,30),'linewidth',3), axis tight
title(['Center 1. mode'],'fontweight','bold')
 
preparc1
 
mean(prexc1.data(:,50:50:201,30))
 
pause
%-------------------------------------------------
% Next, scale the raw data within each sample, but do not center
% (each sample has a sum-square of one). Note that the magnitude
% of each spectrum changes but the relative magnitude within each
% sample's spectra depends on the magnitude of the whole sample
% (i.e. all 61 emission spectra).
 
settings = [0 0 0; 1 0 0];            %scale within Mode 1
[prexs1,prepar] = npreprocess(X,settings); 
 
subplot(3,3,3)
plot(X.axisscale{2,1},prexs1.data(:,:,30),'linewidth',3), axis tight
title(['Scale 1. mode'],'fontweight','bold')
 
prepar
 
sum(sum(prexs1.data(1,:,:).^2))
 
pause
%-------------------------------------------------
% Next, scale AND center the raw data across Mode 1
% (the sample mode). Since the data are scaled first,
% the sum of squares is no longer 1.
 
settings = [1 0 0; 1 0 0];            %center across Mode 1 and scale within Mode 1
[prexc1s1,prepar] = npreprocess(X,settings); 
 
subplot(3,3,4)
plot(X.axisscale{2,1},prexc1s1.data(:,:,30),'linewidth',3), axis tight
title(['Scale and center 1. mode'],'fontweight','bold')
 
prepar
 
mean(prexc1s1.data(:,50:50:201,30))
sum(sum(prexc1s1.data(1,:,:).^2))
 
pause
%-------------------------------------------------
% Next, scale and center the raw data within the 
% second (emission) mode. The sum of each emission
% spectrum = 0.
 
settings = [0 1 0; 0 1 0];
[prexc2s2,prepar] = npreprocess(X,settings); 
 
subplot(3,3,5)
plot(X.axisscale{2,1},prexc2s2.data(:,:,30),'linewidth',3), axis tight
title(['Scale and center 2. mode'],'fontweight','bold')
ylabel('Intensity')
 
pause
%-------------------------------------------------
% Next, scale and center the raw data within the 
% third (excitation) mode.
 
settings = [0 0 1; 0 0 1];
[prexc3s3,prepar] = npreprocess(X,settings); 
 
subplot(3,3,6)
plot(X.axisscale{2,1},prexc3s3.data(:,:,30),'linewidth',3), axis tight
title(['Scale and center 3. mode'],'fontweight','bold')
 
pause
%-------------------------------------------------
% Next, scale and center the raw data within both the 
% second and third mode.
 
settings = [0 1 1; 0 1 1];
[prexc23s23,prepar] = npreprocess(X,settings); 
 
subplot(3,3,7)
plot(X.axisscale{2,1},prexc23s23.data(:,:,30),'linewidth',3), axis tight
title(['Scale and center mode 2&3'],'fontweight','bold')
 
pause
%-------------------------------------------------
% Scale and center the raw data within all modes, 
% but use scaling to standard deviations of one 
% rather than mean squares (which is the most 
% common to use in three-way analysis).
 
settings   = [1 1 1; 1 1 1];
opt        = npreprocess('options');
opt.usemse = 'off';
[prexc123s123,prepar] = npreprocess(X,settings,[],0,opt); 
 
subplot(3,3,8)
plot(X.axisscale{2,1},prexc123s123.data(:,:,30),'linewidth',3), axis tight
title(['Scale and center all modes'],'fontweight','bold')
 
pause
%-------------------------------------------------
% Do the same but allow for iterative preprocessing.
% Sometimes in rarely used combinations of centering
% and scaling, iterative preprocessing is necessary
% for convergence. This is particularly the case 
% when using standard deviations rather than mean
% squares (which is one of the reasons why standard
% deviation scaling is seldom used)
 
settings     = [1 1 1; 1 1 1];
opt          = npreprocess('options');
opt.usemse   = 'off';
opt.iterproc = 'on';
[prexc123s123,prepar] = npreprocess(X,settings,[],0,opt); 
 
subplot(3,3,9)
plot(X.axisscale{2,1},prexc123s123.data(:,:,30),'linewidth',3), axis tight
title(['Scale and center all modes (iteratively)'],'fontweight','bold')
 
pause
%-------------------------------------------------
% Note that the parameters change and another
% important problem is revealed by carefully looking 
% at the data. Even though all three modes are suggested
% to be scaled to unit standard deviation, only for the 
% last mode, is it achieved.
 
% unfold the data in all three directions
 
x1 = prexc123s123.data;
x1 = reshape(x1,size(x1,1),prod(size(x1))/size(x1,1));
 
x2 = prexc123s123.data;
x2 = permute(x2,[2 1 3]);
x2 = reshape(x2,size(x2,1),prod(size(x2))/size(x2,1));
 
x3 = prexc123s123.data;
x3 = permute(x3,[3 1 2]);
x3 = reshape(x3,size(x3,1),prod(size(x3))/size(x3,1));
 
pause
%-------------------------------------------------
% Calculate standard deviations
 
[std(x1')' std(x2(1:5,:)')' std(x3(1:5,:)')']
 
% Looking at the standard deviations of the first five
% variables in each mode, it is seen that only for the
% last mode, the desired result is obtained. 
 
% Thus, when complicated combinations of scaling
% and centering are performed it is necessary to 
% assure that the desired result is obtained. 
 
% The problematic preprocessings are primarily
% when scaling is wanted within several modes
% or when centering and scaling is wanted in
% the same mode.
 
pause
%-------------------------------------------------
% Calculate mean
 
[mean(x1(:,1:5))' mean(x2(:,1:5))' mean(x3(:,1:5))']
 
% The mean values are seen to be zero as expected
% but this is only so because the default options
% specify to center AFTER scaling during each
% iteration. As centering one mode does not affect
% centering in other modes, the resulting data 
% are assured to be centered. This is feasible
% e.g. if the data are to be used in a subsequent
% regression model.
 
pause
%-------------------------------------------------
% See "help npreprocess" or "npreprocess help" for more help
% e.g. on how to apply a certain preprocessing to new test
% data or how to transform preprocessed data (e.g. predictions)
% back to the original domain.
 
%End of NPREPROCESSDEMO
 
echo off
