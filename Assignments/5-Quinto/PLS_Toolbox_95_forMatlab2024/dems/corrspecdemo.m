echo on
%CORSPECDEMO Demo of the corrspec function.
 
echo off
%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%ww
 
echo on
 
%To run the demo hit a "return" after each pause
 
pause
 
%-------------------------------------------------
%The program resolves correlation spectroscopy maps of mixtures into the
%correlation maps of the separate components. Familiarity with the purity 
%approach is assumed. For more information about this technique see:
%W. Windig, D.E. Margevich, W.P. McKenna,
%A novel tool for two-dimensional (2D) correlation spectroscopy,
%Chemometrics and Intelligent Laboratory Systems, 28, 1995, 108-128
%We will analyze a mid-IR and a near-IR data set of the same mixtures.
%
%The data will be loaded and plotted.
 
pause
 
%Load and plot the demonstration data:
 
load data_mid_IR
load data_near_IR
subplot(211);plot(data_mid_IR.axisscale{2},data_mid_IR.data);
corrspecutilities('setxdir');title('mid IR');ylabel('absorbance');
subplot(212);plot(data_near_IR.axisscale{2},data_near_IR.data);
corrspecutilities('setxdir');title('near IR');xlabel('wavenumber');
 
pause
 
%-------------------------------------------------
 
close
 
%The mid-IR and near_IR data set of the same samples will be analyzed with 
%correlation spectroscopy. We will use the program corrspec to calculate
%the correlations between the two data sets. Since we need to plot only
%this map (for the purposes of this demo) and not the other plots corrspec
%will generate we will turn the plots off using the 'options' and than plot
%only the map of our interest using plot_corr plotting utility. 
%
%We also need to set the offset to zero in order to get a regular
%correlation map.
 
pause
 
options=corrspec('options');
options.plots_spectra= 'off';
options.plots_maps= 'off';
options.offset=0;

%-------------------------------------------------
%Now we will call corrspec with the first two inputs being our data. The
%third input is the number of pure components, in the case we choose 1. The
%last input is our options structures created above.

pause

model = corrspec(data_mid_IR,data_near_IR,1,options);
 
image2plot=model.detail.matrix{1}{2};
image2plot(image2plot<0)=0;%only plot positive correlations
 
plot_corr(data_mid_IR.axisscale{2},data_near_IR.axisscale{2},image2plot,...
    copper(64),0,3);
 
echo on
 
pause
 
%-------------------------------------------------
%This plot is the positive part of the correlations between the
%variables of the two data sets. The plot is very complex.
%A noise correction factor as the one in the purity program makes this map
%much simpler. By setting the offset to three, variables with a low noise
%level intensity will get a lower weight in the results. As a consequence,
%less noise is present in the correlation map.
%
%We'll replot the same data with an offset of 3:
 
pause

options.offset=3;
 
model = corrspec(data_mid_IR,data_near_IR,1,options);
 
image2plot=model.detail.matrix{1}{2};
image2plot(image2plot<0)=0;%only plot positive correlations
 
plot_corr(data_mid_IR.axisscale{2},data_near_IR.axisscale{2},image2plot,...
    copper(64),0,3);
  
pause
 
%-------------------------------------------------
 
close
 
%We will now use the corrspec program to resolve the data into 4
%components. By default, this will produce several images and plots. The
%list below summarizes the images and plots that will be produced and the
%order they will appear:
%
%a) A series of correlation maps where the cursor shows the point with the
%   highest co-purity: the variables are pure (or the purest available for 
%   each of the components AND they are correlated. Clicking on the first
%   map will result in a second map where the first component is 
%   eliminated. This goes on until all four components have been eliminated
%   and no information is present anymore.
%b) The four resolved spectra of the x data set (mid-IR).
%c) The four resolved contribution profiles of the x data set (mid_IR).
%d) The four resolved spectra of the y data set (near-IR).
%e) The four resolved contribution profiles of the x data set (near_IR).
%f) The resolved contributions of x versus y. They should be correlated,
%   since that is the way they were determined.
%g) A series of 4 correlation maps:
%   1) the original correlation matrix
%   2) the correlation matrix reconstructed from the resolved data
%   3) the sum of the 4 resolved components. Should be similar, but there 
%       are differences because correlations between components are not
%       present.
%   4) an overlay plot of the 4 resolved correlation maps, each indicated
%      with a separate color.
%h) The four resolved correlation maps for each of the resolved components.
 
pause
 
corrspec(data_mid_IR,data_near_IR,4);
 
%When we establish the relations between two data sets it is possible to
%predict a near-IR spect from a mid_IR spectrum. We will exclude spectra
%8 from the data and build a model.
 
pause

%-------------------------------------------------
 
close
 


 
data_mid_IR_reduced=data_mid_IR([1:7,9:end]);
data_near_IR_reduced=data_near_IR([1:7,9:end]);
 
model = corrspec(data_mid_IR_reduced,data_near_IR_reduced,4,options);
 
 
pause
 
%-------------------------------------------------
 
close
 
%Now we will take the near-IR spectrum we took out and predict its associated
%mid-IR spectrum and plot the results.
 
pause
 
model2=corrspec([],data_near_IR(8,:),model);
 
plot(data_mid_IR.axisscale{2},model2.loads{2},...
    data_mid_IR.axisscale{2},data_mid_IR.data(8,:))

legend('mid-IR predicted from near IR','actual mid-IR');
 
%End of CORRSPECDEMO
 
echo off
 
 
