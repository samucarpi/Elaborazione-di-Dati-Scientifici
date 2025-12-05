echo on
% FLUCUTDEMO Demo of the FLUCUT function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The FLUCUT function is used to modify EEMs prior to analysis to ensure
% that the data more closely follows a trilinear PARAFAC model structure. 
% Without the FLUCUT modification, the results can be hampered by artifacts.
 
% FLUCUT is used to remove scatter from fluorescence EEM data by
% inserting a NaN where the data should be treated as missing, or a 0
% where the EEM should be 0 (e.g., for emissions << excitations).
% The area of interest (the region expected to follow a trilinear model
% in an EEM is where emission is > excitation. However, scatter where
% excitation == emission can creep into neighboring channels around
% the emi == exci line.
 
% Alternatively, FLUCUT can be used to enter weightings to de-weight 
% regions that are not of interest. Low weights indicate regions where
% the data are not used to fit the model.
 
pause
 
% The first step in the demo is to load some data and plot it.
 
load flucuttest
whos
 
% The data matrix is 2 samples by by 15 emission wavelengths 
% 23 excitation wavelengths (and is simulated data for the example) . 
% For this example, the wavelengths are unrealistic but easy to explore
% 11:25 and 1:23 respectively.
% Hit a return to plot the data.
 
pause
 
% Note that the plotting code is a hard to decipher since image displays
% are flipped but the picture can be easily interpreted.
 
% The white diagonal corresponds to the emi == exci line.
 
figure, imagesc(z.axisscale{3},z.axisscale{2}, ...
  squeeze(z.data(1,:,:))), axis('image','xy')
abline(1,0,'color',[1 1 1])
xlabel('Emission (nm)')
ylabel('Excitation (nm)')
figfont
 
pause
 
% Next, FLUCUT is used to set all the points where emission<(excitation+3)
% to zero, and the band emi==exci-3 & emi==exci+3) to missing (NaN).
%  >> Xnew = flucut(X,LowZero,LowMiss,TopZero,TopMiss,MakeWts,plots);

opt = flucut('options');
opt.plots = 'off';%Turn off plottnig.

znew = flucut(z,[3 3],NaN,opt);
 
figure, imagesc(znew.axisscale{3},znew.axisscale{2}, ...
  squeeze(znew.data(1,:,:))), axis('image','xy')
abline(1,0,'color',[1 1 1])
abline(1,-3,'color',[1 0.4 0.4])
abline(1,3,'color',[1 0.4 0.4])
xlabel('Emission (nm)')
ylabel('Excitation (nm)')
figfont
 
% The lower right hand lighter blue patch corresponds to zeros and the
% dark blue band around emi==exci is set to missing. The red diagonals
% show the band +-3 around the emi==exci white diagonal.
 
% pause

% load dorrit
% figure
% h = surf(EEM.axisscale{3},EEM.axisscale{2},squeeze(EEM.data(1,:,:)));%,18*~isnan(xusedarea));
% set(h,'cdatamapping','direct')
% xlabel(EEM.axisscalename{1})
% ylabel(EEM.axisscalename{2})
%       zlabel('Blue used for interpolating red line area')
 
%End of FLUCUTDEMO
 
echo off
  
