echo on
% WINDOWFILTERDEMO Demo of the WINDOWFILTER function
 
echo off
% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The WINDOWFILTER function is used to filter rows of a matrix using
% a number of possible filters: [ {'mean'} | 'median' | 'max' | 'min' | ...
% 'meantrimmed' | 'mediantrimmed' | 'despike' ].
 
% Consider the following Raman data and just pick three examples.
 
load('raman_dust_particles.mat')
isel    = exteriorpts(raman_dust_particles,3,struct('dismeasure','Mahalanobis','usepca','yes'));
x       = raman_dust_particles(isel,:);
  g1    = figure('Name','Example Spectra for Raman Dust Particles');
  plot(x.axisscale{2},x.data)
  xlabel('Raman Shift (cm^{-1})','interpreter','tex')
  ylabel('Raman Intensity')
  axis([178 1085 0 16000]), set(gca,'xdir','reverse'), grid, figfont
 
% These are nice clean spectra. For this example, a few spikes will be
% added so that the differences in the filters in WINDOWFILTER can be
% more easily seen.
%-------------------------------------------------
 
pause
 
x.data(1,[940,970]) = x.data(1,[940,970])+5000;
x.data(2,[940,970]) = x.data(2,[940,970])+5000;
x.data(3,[940,970]) = x.data(3,[940,970])+5000;
  figure(g1);
  plot(x.axisscale{2},x.data)
  xlabel('Raman Shift (cm^{-1})','interpreter','tex')
  ylabel('Raman Intensity')
  va    = [178 1085 0 16000];
  axis(va), set(gca,'xdir','reverse'), grid, figfont
%-------------------------------------------------
 
pause
 
% Next try fliter algorthim = 'mean', 'median' and 'despike' with a
% window width of 3.
 
win     = 3;
options           = windowfilter('options');
options.algorithm = 'mean'; %this is the default algorithm = boxcar average
xf_mean           = windowfilter(x,win,options);
options.algorithm = 'median';
xf_medn           = windowfilter(x,win,options);
options.algorithm = 'despike';
options.dsthreshold = 3;      
options.tol       = 1000;     %variance in all the windows 
options.trbflag   = 'middle'; 
xf_dspk           = windowfilter(x,win,options);

  figure(g1); g2  = zeros(1,3);
  for i1=1:3
    g2(i1)        = subplot(3,1,i1);
    plot(x.axisscale{2},x.data(i1,:)); hold on
    plot(x.axisscale{2},xf_mean.data(i1,:));
    plot(x.axisscale{2},xf_medn.data(i1,:));
    plot(x.axisscale{2},xf_dspk.data(i1,:));
    
    axis([178 1085 0 16000]), set(gca,'xdir','reverse'), grid('on')
    vline([210 235])
    if i1==1
      legend('Original','Mean Filtered','Median Filtered','Despiked','location','northwest')
    end
    if i1==2
      ylabel('Raman Intensity')
    end
  end
  xlabel('Raman Shift (cm^{-1})','interpreter','tex'), figfont
  gf    = get(gcf,'position');
  set(gcf,'position',[gf(1),gf(2),gf(3),gf(4)*1.5])
  
% The differences appear ~minor at this scale, so let's zoom in and show
% each spectrum in it's own subplot. The zoom is between 210 and 235 shown
% between the green vertical lines.
 
pause
  
  for i1=1:3
    axes(g2(i1))
    switch i1
    case 1
      axis([210 235 0 16000])
    case 2
      axis([210 235 0 5000])
    case 3
      axis([210 235 9000 9500])
    end
  end
   
% As expected, the mean filter suppresses the spikes and the peak (top
%   graph).
% The median filter also suppresses the peak but not as much as the
%   mean filter but the median filter eliminates the spike.
% The despike filter does not suppress the peak and also eliminates the
%   spikes - note that dsthreshold = 3 and tol = 1000 means that the despike
%   filter does not replace w/ the median for spikes < 3000 - only for values
%    |x-median(x)|>options.dsthreshold*options.tol .
% Also notice that the mean and median filters smooth out the noise (bottom
%   graph) but despike does not.
 
%End of WINDOWFILTERDEMO
 
echo off
