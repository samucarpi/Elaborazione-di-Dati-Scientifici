echo on
%SAVGOLDEMOB Demo of the SAVGOL function
%  Also see: SAVGOLDEMO, WSMOOTHDEMO
 
echo off
%Copyright Eigenvector Research, Inc. 2019
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
echo on
 
% For a given signal and a filter of width, w, savgol calculates a
% polynomial fit of order o to the signal measurements in each filter
% window as the filter is moved across the signal. For example, load some
% data and show a few windows moving across the signal.
 
pause
 
load raman_dust_particles.mat
x          = raman_dust_particles.data([35 43 106],:);
z     = x(1,84:121)';
si    = 22:28;
figure, plot(z,'-o','color',[0.3 0.5 1],'markersize',8,'markerfacecolor',[0 0 1])
axis([0 39 2950 3900]), grid
echo off
    g     = gca;
    basis = polybasis(1:length(si),2);
    b     = basis\z(si,:);
    fit   = basis*b;       hold on
    xlabel('Spectral Channel')
    ylabel('Spectral Response'), figfont
    plot([ 1.5  1.5],[3010 3180],'k--','color',[0.8 0.8 0.8]) 
    plot([ 8.5  8.5],[3010 3480],'k--','color',[0.8 0.8 0.8])
    plot([ 1.5  8.5],[3010 3010],'k--','color',[0.8 0.8 0.8])
    plot([ 2.5  2.5],[3040 3240],'k--','color',[0.6 0.6 0.6]) 
    plot([ 9.5  9.5],[3040 3640],'k--','color',[0.6 0.6 0.6])
    plot([ 2.5  9.5],[3040 3040],'k--','color',[0.6 0.6 0.6])
    plot([ 3.5  3.5],[3060 3235],'k--','color',[0.4 0.4 0.4]) 
    plot([10.5 10.5],[3060 3860],'k--','color',[0.4 0.4 0.4])
    plot([ 3.5 10.5],[3060 3060],'k--','color',[0.4 0.4 0.4])
    annotation('arrow',[0.1461 0.4046],[0.14 0.14])
echo on
  
% This example shows three windows with w = 7: [1,8], [2,9] and [3,10].
% The signal is a spectrum at measured discrete spectral channels (blue
% line with measurements at the filled dots).

% The filter estimate at the center of each window is given by the
% polynomial fit at the center channel (w is typically an odd integer).
 
pause
 
echo off
    h     = plot(si,fit,'r');
    uistack(h,'bottom')
    plot([21.5 21.5],[3100 3375],'k--','color',[0.8 0.1 0]) 
    plot([28.5 28.5],[3100 3375],'k--','color',[0.8 0.1 0])
    plot([21.5 28.5],[3100 3100],'k--','color',[0.8 0.1 0])
    plot([21.5 28.5],[3375 3375],'k--','color',[0.8 0.1 0])
    plot([21   18.5],[3390 3445],'k--','linewidth',0.5)
    plot([29   37  ],[3390 3440],'k--','linewidth',0.5)
    g(2)  = axes('position',[0.5 0.55 0.4 0.815/2.25]);
    copyobj(get(g(1),'children'),g(2)), set(gca,'box','on')
    hold on, plot(25,fit(4),'x','color',[0.8 0.5 0],'markersize',16)
    axis([21.5 28.5 3100 3375]), grid
    text(25.4,3150,'signal','fontname','times new roman')
    text(26.2,3200,'quadradic fit','fontname','times new roman', ...
      'backgroundcolor',[1 1 1],'margin',0.1), figfont
    % saveas(gcf,'Savgol_Fit','fig')
    % print('Savgol_Fit','-dpng','-r300')
echo on

% An example fit for the window [22,28] in the top right of the figure.
% The filtered signal at the center channel, channel 25, is given by
% the 'X' in the subplot. The filter calculation is complete when the
% filter window moves across all the spectral channels one-at-a-time.

% Next, let's show example smoothing for three example Raman spectra.
 
pause
 
figure('Name','Raman Dust Particles'), g = zeros(1,2);
title(get(gcf,'Name'))
plot(raman_dust_particles.axisscale{2},x(3,:)); hold on
echo off
    xlabel('Wavenumber (cm^{-1})'), grid
    y1         = savgol(x(3,:),7, 2,0);
    plot(raman_dust_particles.axisscale{2},y1);
    y2         = savgol(x(3,:),15,2,0);
    plot(raman_dust_particles.axisscale{2},y2);
    y2         = savgol(x(3,:),27,2,0);
    plot(raman_dust_particles.axisscale{2},y2);
    axis([180 525 0 1.65e4]), g(1) = gca;
    legend('Measured','\itw\rm = 7','\itw\rm = 15','\itw\rm = 27')

    g(2)  = axes('position',[0.28 0.52 0.42 0.38]);
    copyobj(get(g(1),'children'),g(2)), set(gca,'box','on')
    axis([202 238 -500 1.65e4]), grid
    set(hline('-k'),'linewidth',0.5)
    set(gca,'yticklabel',{'0','','',''}), figfont
    % saveas(gcf,'Savgol_Smooth','fig')
    % print('Savgol_Smooth','-dpng','-r300')
echo on
 
% Note that as the filter width, w, increases smoothing increases and
% the peaks are suppressed more. At higher smoothing, the peaks acquire
% an artifact seen as minima on either side of the peak.
 
% Next, the savgol filter will be used to estimate the first derivative of
% an example spectrum and compare it to the first difference.
 
pause
 
echo off
    figure('Name','Raman Dust Particles'), g = zeros(1,2);
    title(get(gcf,'Name'))
    g(1)       = subplot(2,1,1);
    plot(raman_dust_particles.axisscale{2},x(1,:)); grid, hold on
    axis([180 1084 2000 9000])
    ylabel('Raman Response')
    g(2)       = subplot(2,1,2);
    plot(raman_dust_particles.axisscale{2}(1:end-1),diff(x(1,:))); grid, hold on
    y1         = savgol(x(1,:),15, 2,1);            %First derivative
    plot(raman_dust_particles.axisscale{2},y1);
    axis([180 1084 -400 400])
    ylabel('1^{st} Derivative Raman Response')
    xlabel('Wavenumber (cm^{-1})'), figfont
    % saveas(gcf,'Savgol_1stD','fig')
    % print('Savgol_1stD','-dpng','-r300')
echo on
 
% The figure shows an example for a Raman spectrum (top graph) and
% estimates of the first derivative (bottom graph) using a first
% difference (blue) and savgo(15,2,1) (red).
 
% The first difference exaggerates noise in the spectrum while the
% savgol filter suppresses it. In addition, the significant broad signal
% in the original spectrum (top) has also been suppressed with the
% peak at 1008 cm-1 now dominating the signal for the filtered spectrum.
 
% Next examine a signal with a first derivative estimate and examine the
% ends. The ends are the windows that don't have a full set of channels
% corresponding to the p = (w-1)/2 channels at the left and right of the
% measured signal.

echo off
 
load data_mid_IR
    ii         = [57:74 100:121];
    ax         = data_mid_IR.axisscale{2}(ii);
    nn         = length(ax);
    xx         = data_mid_IR.data(2,ii) + sin(1:length(ax))*0.01 + ...
                 peakgaussian([1.5 20 3],1:nn);
    
    w          = [7 15];
    figure('Name','IR Signal')
    subplot(3,1,1)
    plot(xx','-o'); grid('on')
    p          = (w-1)/2;
    set(vline( p(1)+0.5,  'b'),'linewidth',1)
    set(vline(nn-p(1)+0.5,'b'),'linewidth',1)
    set(vline( p(2)+0.5,  'r'),'linewidth',1)
    set(vline(nn-p(2)+0.5,'r'),'linewidth',1)
    ylabel('Measured Signal')

    y1         = savgol(xx,w(1),2,1);
    y2         = savgol(xx,w(2),2,1);

    subplot(3,1,2)
    w1         = 1:p(1);
    w2         = nn-p(1)+1:nn;
    a          = plot(y1','-b'); hold('on'), grid('on')
    plot(w1,y1(w1),'o','markerfacecolor',get(a,'color'),'markeredgecolor',get(a,'color'),'markersize',8)
    plot(w2,y1(w2),'o','markerfacecolor',get(a,'color'),'markeredgecolor',get(a,'color'),'markersize',8)
    a          = hline('-k');
    set(a,'linewidth',1)
    uistack(a,'bottom')
    set(vline( p(1)+0.5,  'b'),'linewidth',1)
    set(vline(nn-p(1)+0.5,'b'),'linewidth',1)
    ylabel('\itw\rm = 7, \itp\rm = 3')
    title('savgol(7,2,1)')

    subplot(3,1,3)
    w1         = 1:p(2);
    w2         = nn-p(2)+1:nn;
    a          = plot(y2','-r'); hold('on'), grid('on')
    plot(w1,y2(w1),'o','markerfacecolor',get(a,'color'),'markeredgecolor',get(a,'color'),'markersize',8)
    plot(w2,y2(w2),'o','markerfacecolor',get(a,'color'),'markeredgecolor',get(a,'color'),'markersize',8)
    a          = hline('-k');
    set(a,'linewidth',1)
    uistack(a,'bottom')
    set(vline( p(2)+0.5,  'r'),'linewidth',1)
    set(vline(nn-p(2)+0.5,'r'),'linewidth',1)
    ylabel('\itw\rm = 15, \itp\rm = 7')
    title('savgol(15,2,1)')
    xlabel('Sample Point')
    figfont
    % saveas(gcf,'Savgol_ends','fig')
    % print('Savgol_ends','-dpng','-r300')
echo on
 
% The ends are the first and last p = (w-1)/2 points where a full window
% of channels is not available and the calculation of the filter can be
% unusual - this is called "end-effects."
 
% For example, a measured signal is shown in the top graph of the figure
% and the next two graphs show a savgol first derivative filter for two
% different filter widths where the ends have been highlighted with
% symbols. 
 
% The left end of the middle plot (w = 7) shows the estimated derivative
% significantly negative then positive whereas the signal (top plot) shows
% a flat signal with derivative ~0. The right end of the middle plot should
% all be <0 but the last point is > 0.
 
% Comparison of the bulk of the filtered signals (middle and bottom graphs)
% where a full set of channels is available shows general agreement in the
% estimated first derivative although, as expected, there are some
% differences. However, the ends of the two filtered signals do not agree.
 
% To avoid end-effects, it is typical to use the entire signal to calculate
% the filter then trim off the ends before further analysis.
 
 
% Next, a new example using a MidIR spectroscopy measurements will show
% the second derivative. 
 
pause
 
% The filter can also be calculated with less smoothing by using 1/d
% weighting. I.e., instead of fitting polynomials with each channel given
% an equal weight, the channels can be weighted by their distance from the
% center channel (e.g., 1/d, where d is the distance).
 
% Load the data, calculate the first and second derivative filters then
% plot the results
  
load data_mid_IR
figure, subplot(3,1,1)
plot(data_mid_IR.axisscale{2},data_mid_IR.data(2,:)); grid
ylabel('Absorbance')
title('Example IR Spectrum')
set(gca,'xdir','reverse')
 
opts       = savgol('options');
dspec      = savgol(data_mid_IR.data(1,:),7,2,1,opts);
opts.tails = 'weighted';
opts.wt    = '1/d';
espec      = savgol(data_mid_IR.data(1,:),7,2,1,opts);
subplot(3,1,2)
plot(data_mid_IR.axisscale{2},dspec,'b'), hold on, grid
plot(data_mid_IR.axisscale{2},espec,'r')
title('First Derivative of the IR Spectrum')
ylabel('Absorbance 1st D'), set(gca,'xdir','reverse')
legend('SavGol','SavGol 1/d weighted','location','southwest')
 
opts       = savgol('options');
dspec      = savgol(data_mid_IR.data(1,:),7,2,2,opts);
opts.tails = 'weighted';
opts.wt    = '1/d';
espec      = savgol(data_mid_IR.data(1,:),7,2,2,opts);
subplot(3,1,3)
plot(data_mid_IR.axisscale{2},dspec,'b'), hold on, grid
plot(data_mid_IR.axisscale{2},espec,'r')
title('Second Derivative of the IR Spectrum')
ylabel('Absorbance 2nd D'), set(gca,'xdir','reverse')
legend('SavGol','SavGol 1/d weighted','location','southwest')
xlabel('Wavenumber (cm^{-1})'), figfont
 
% It should be clear that smoothing for the 1/d weighted channels is not as
% strong as the traditional savgol filter. In fact, the user can define
% weightings if desired.
 
%End of SAVGOLDEMOB
%Also See: SAVGOLDEMO, WSMOOTHDEMO
 
echo off
