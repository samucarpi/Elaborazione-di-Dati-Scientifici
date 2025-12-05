echo on
% WSMOOTHDEMO Demo of the WSMOOTH function
 
echo off
% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The WSMOOTH function uses a Whittaker smoother that fits the data (y)
% with a curve (z) using a penalty function on a measure of the 'roughness'.
 
% To examine how to use the fuction, load some data and make a plot.
 
pause
 
load oesdata
 
h    = figure; g = zeros(1,3);
v    = [245 455  0 600;
        300 320 25  75;
        390 404 50 560];
for i1=1:3
  g(i1) = subplot(3,1,i1);
  plot(oes1.axisscale{2},oes1.data(1,:)); hold on
  axis(v(i1,:))
end, xlabel('Wavelength (nm)')
 
% The OES spectrum is fairly noisy around the baseline.
% It is more clear if the figure height is increased.
 
pause
 
% The smoother is called w/ it's default parameters using
 
z  = wsmooth(oes1);
%  ssq0 = pcaengine(oes1.data,1);
%  ssq1 = pcaengine(z.data,1);
 
figure(h), g2 = zeros(1,3);
for i1=1:3
  axes(g(i1))
  g2(i1) = plot(oes1.axisscale{2},z.data(1,:),'r');
  if i1==1
    legend('Original Signal','Smoothed Signal, \lambda_s\rm = 0.1','location','north')
  end
end
 
% The smoothing is fairly reasonable but not very strong.
% The small peak at 309 nm is preserved and the noise is slightly suppressed.
% The larger peak at 396 nm was also slightly suppressed.
 
pause
 
% The smoothness can be enhanced by increasing the roughness penalty.
 
opts        = wsmooth('options');
opts.lambda = 10; %increase the roughness penalty from 0.1 to 10.
z2 = wsmooth(oes1,opts);         %call wsmooth with new options
%  ssq2 = pcaengine(z2.data,1);
 
figure(h), g2 = zeros(1,3);
for i1=1:3
  axes(g(i1))
  g2(i1) = plot(oes1.axisscale{2},z2.data(1,:),'color',[0 0.5 0]);
  if i1==1
    legend('Original','Smoothed, \lambda_s\rm = 0.1','Smoothed , \lambda_s\rm = 10','location','north')
  end
end
 
% The smoothing is fairly strong now.
% The small peak at 309 nm is more suppressed and
% the larger peak at 396 nm was also highly suppressed.
 
% Next, the roughness penalty for specific channels will be reduced.
 
pause
 
opts.ws   = ones(1,size(oes1,2)); %initalize local wt's for roughness penalty
opts.ws(oes1.axisscale{2}>258 & oes1.axisscale{2}<280) = 0.01; %drop wt's for
opts.ws(oes1.axisscale{2}>307 & oes1.axisscale{2}<311) = 0.01; %selected 
opts.ws(oes1.axisscale{2}>393 & oes1.axisscale{2}<397) = 0.01; %regions
z3 = wsmooth(oes1,opts);         %call wsmooth with new options
%  ssq3 = pcaengine(z3.data,1);
 
figure(h), g3 = zeros(1,3);
for i1=1:3
  axes(g(i1))
  g3(i1) = plot(oes1.axisscale{2},z3.data(1,:),'k');
  if i1==1
    legend('Original','Smoothed, \lambda_s\rm = 0.1','Smoothed , \lambda_s\rm = 10', ...
      '\lambda_s\rm = 10 w/ low penalty on peaks',...
      'location','north')
  end
end
 
% This shows strong smoothing away from the peaks while
% doing a better job of preserving the peaks.
 
%End of WSMOOTHDEMO
 
echo off
