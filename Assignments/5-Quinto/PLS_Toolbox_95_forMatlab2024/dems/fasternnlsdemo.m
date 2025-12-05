echo on
% FASTERNNLSDEMO Demo of the FASTERNNLS function
 
echo off
% Copyright © Eigenvector Research, Inc. 2002
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The FASTERNNLS function is used to obtain a non-negative (NN) constrained
% least squares solution (often used in the alternating least squares
% approach to multivariate curve resolution).

% In the first example, NIR spectroscopic data will be loaded and an
% estimate of the pure component spectra will be obtained using both
% unconstrained and NN constrained least-squares. This data has measured
% spectra for a mixture of five different analytes in the variable SPEC1
% with corresponding concentrations in variable CONC.
 
% The estimated spectra are obtained from the measured mixtures using the
% first 24 out of 30 samples. The last six will be used as a test set.
 
load nir_data
% The unconstrained solution is:
s0               = conc.data(1:24,:)\spec1.data(1:24,:);
% The NN constrained solution is:
s1               = fasternnls(conc.data(1:24,:),spec1.data(1:24,:));
 
% And the results are plotted. Note that there are differences for this
% example but they are small.
figure('Name','Pure Spectra')
subplot(2,1,1)
plot(spec1.axisscale{2},s0,'-','color',[0.5 0.5 0.5]); hold on
h = plot(spec1.axisscale{2},s0,'--');
g = plot(spec1.axisscale{2},s1,'-');
legend([h(1) g(1)],'Unconstrained','Constrained','location','northwest')
axis([800 1600 -0.0025 0.025])
subplot(2,1,2)
g = plot(spec1.axisscale{2},s1-s0,'-');
xlabel('Wavelength (nm)'), axis([800 1600 -1e-4 1e-4])
legend(g(1),'Constrained-Unconstrained')
pause
%-------------------------------------------------                             
 
% Next FASTERNNLS is used to estimate concentration for the calibration
% samples (1:24) and the test samples (25:30).
% The RMSEC and RMSEP are calculated for all five analytes combined and
% you'll notice that the fit (based on the calibration data) and the
% predictions (based on the test data) aren't too bad for this classical
% least squares (CLS) model.
 
c1               = fasternnls(s1',spec1.data')';
figure('Name','Cal and Test on Instrument 1')
h = plot(conc.data( 1:24,:),c1( 1:24,:),'o','markerfacecolor','auto'); hold on
g = plot(conc.data(25:30,:),c1(25:30,:),'d','markerfacecolor','auto'); dp
title('Cal and Test on Instrument 1')
xlabel('Known'), ylabel('Estimated')
legend([h(1) g(1)],'Cal','Test','location','northwest')
 
% Cal and Test on Instrument 1
['Total RMSEC 1 = ', num2str(sqrt(mean(rmse(conc.data( 1:24,:),c1( 1:24,:)).^2)))]
['Total RMSEP 1 = ', num2str(sqrt(mean(rmse(conc.data(25:30,:),c1(25:30,:)).^2)))]

pause
%-------------------------------------------------                             
 
% Now, try the NN constrained CLS model on data from Instrument 2
% (measurements are saved in SPEC2), and plot the results. You'll
% notice that the predictions are quite poor!
 
%c2a   = spec2.data/spure;  %unconstrained solution
c2a   = fasternnls(s1',spec2.data')';
figure('Name','Test on Instrument 2, not accounting for Inst Diff')
h = plot(conc.data( 1:24,:),c2a( 1:24,:),'o','markerfacecolor','auto'); hold on
g = plot(conc.data(25:30,:),c2a(25:30,:),'d','markerfacecolor','auto'); dp
title('Cal and Test data on Instrument 2 w/o accounting for instrument differences')
xlabel('Known'), ylabel('Estimated')
legend([h(1) g(1)],'Cal','Test','location','northwest')
' '
%Cal and Test data on Instrument 2 w/o accounting for instrument differences
['   Total RMSEP cal 2a = ', num2str(sqrt(mean(rmse(conc.data( 1:24,:),c2a( 1:24,:)).^2)))]
['   Total RMSEP tst 2a = ', num2str(sqrt(mean(rmse(conc.data(25:30,:),c2a(25:30,:)).^2)))]

pause
%-------------------------------------------------                             
 
% One method used to account for instrument differernces uses the extended
% mixture model (ELS). This is a CLS model with additional "spectra" P that
% account for instrument differences. The P vectors are calculated here
% using the first 3 principal components of the differences based on the
% calibration data (P = loads).
 
ncomp            = 3;
[ssq,drnk,loads] = pcaengine(spec1.data(1:24,:)-spec2.data(1:24,:),ncomp);
 
pause
%-------------------------------------------------

% The NN constrained ELS model is now used to estimate the concentrations
% and plot the results. You'll note that the fit and predictions are much
% better, but ...
 
c2b   = fasternnls([s1', loads],spec2.data')';
figure('Name','Test on Instrument 2, scores NN constrained')
h = plot(conc.data( 1:24,:),c2b( 1:24,1:5),'o','markerfacecolor','auto'); hold on
g = plot(conc.data(25:30,:),c2b(25:30,1:5),'d','markerfacecolor','auto'); dp
title('Cal and Test data on Instrument 2 accounting for instrument differences')
xlabel('Known'), ylabel('Estimated')
legend([h(1) g(1)],'Cal','Test','location','northwest')
 
%Cal and Test data on Instrument 2 accounting for instrument differences
%  however the scores on the loadings that account for instrument differences
%  are ALL constrained to be non-negative
['   Total RMSEP cal 2b = ', num2str(sqrt(mean(rmse(conc.data( 1:24,:),c2b( 1:24,1:5)).^2)))]
['   Total RMSEP tst 2b = ', num2str(sqrt(mean(rmse(conc.data(25:30,:),c2b(25:30,1:5)).^2)))]
pause
%-------------------------------------------------

% ... is it correct to constrain the estimated scores on the P vectors to
% be non-negative? Physics might suggest no, and the plot of the scores 
% (the last three columns of the variable c2b shows that the scores are
% being actively constrained (note the scores at zero might actually be
% less than zero).
 
figure('Name','Test on Instrument 2, scores NN constrained')
h = plot(c2b( 1:24,6:8),'o','markerfacecolor','auto'); hold on
g = plot(c2b(25:30,6:8),'d','markerfacecolor','auto');
xlabel('Known'), ylabel('Constrained Scores on P')
legend([h(1) g(1)],'Cal','Test','location','northwest')
pause
%-------------------------------------------------

% This example shows how to relax the constraints using the input
% (nnconstr = [ones(1,5) zeros(1,ncomp)]'). The first five 1's indicate
% that the analyte concentrations are to be NN constrained and the last
% three 0's indicate that the scores on P are not to be constrained (the
% NN constraints are relaxed).
 
% Plots of the results (RMSEC and RMSEP) indicate better performance than
% in the previous example.
 
c2c   = fasternnls([s1', loads],spec2.data', ...
                   [],[],[],[ones(1,5) zeros(1,ncomp)]')';
figure('Name','Test on Instrument 2, scores relaxed')
h = plot(conc.data( 1:24,:),c2c( 1:24,1:5),'o','markerfacecolor','auto'); hold on
g = plot(conc.data(25:30,:),c2c(25:30,1:5),'d','markerfacecolor','auto'); dp
title('Cal and Test data on Instrument 2 accounting for instrument differences')
xlabel('Known'), ylabel('Estimated')
legend([h(1) g(1)],'Cal','Test','location','northwest')
 
%Cal and Test data on Instrument 2 accounting for instrument differences
%  where the scores on the loadings that account for instrument differences
%  are NOT constrained to be non-negative
['   Total RMSEP cal 2c = ', num2str(sqrt(mean(rmse(conc.data( 1:24,:),c2c( 1:24,1:5)).^2)))]
['   Total RMSEP tst 2c = ', num2str(sqrt(mean(rmse(conc.data(25:30,:),c2c(25:30,1:5)).^2)))]
 
pause
%-------------------------------------------------

% Plots of scores after relaxing the NN constraints show some negative scores
% on PCs 2 and 3.
 
figure('Name','Test on Instrument 2, scores not-NN constrained')
h = plot(c2c( 1:24,6:8),'o','markerfacecolor','auto'); hold on
g = plot(c2c(25:30,6:8),'d','markerfacecolor','auto');
hline
xlabel('Known'), ylabel('Unconstrained Scores on P')
legend([h(1) g(1)],'Cal','Test','location','northwest')
 
%End of FASTERNNLSDEMO
 
echo off
