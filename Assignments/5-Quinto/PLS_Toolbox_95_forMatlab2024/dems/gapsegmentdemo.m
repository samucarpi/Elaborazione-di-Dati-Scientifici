echo on
% GAPSEGMENTDEMO Demo of the GAPSEGMENT function
 
echo off
% Copyright © Eigenvector Research, Inc. 2013
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The GAPSEGMENT function is a filtering approach based
% on allowing for "gaps" of 0 not used to calculate the
% filter between "segments" of signal used to calcualte
% the filter
% See, KH Norris, "Instrument Design. Interactions among instrument 
% bandpass, instrument noise, sample-absorber bandwidth and calibration 
% error" NIR news, 9(4) pp 3, 1998.
% KH Norris, "Applying Norris Derivatives. Understanding and correcting
% the factors which affect diffuse transmittance spectra," NIR news, 12(3)
% pp 6, 2001.
% KH Norris, "I Didn't See the Cows. More on the factors affecting diffuse
% transmittance and reflectance spectra," NIR news,13(3), pp 8, 2002.
 
pause
%-------------------------------------------------
% First load some data then run the filter for first order.

load nir_data spec1
x       = spec1.data(1,:);
order   = 1;
gap     = 5;
segment = 7;

[y_has,cl] = savgol(x,11,order,order,struct('tails','weighted'));
[y_hat,cm] = gapsegment(x,order,gap,segment);
[y_hau,cn] = gapsegment(x,order,gap,segment,struct('algorithm','savgol'));

figure('Name','First Order'), subplot(2,1,1)
plot(x,'b'), axis([0 401 0 1.8])
subplot(2,1,2), h = zeros(1,3);
h(1) = plot(y_hau,'k','linewidth',2); axis([0 401 -0.05 0.125]), hold on
set(hline,'color',[0.8 0.8 0.8])
h(2) = plot(y_hat,'b');
h(3) = plot(y_has,'r');
legend(h,'GapSegment savgol 1,5,7','GapSegment 1,5,7','SavGol 11,1,1','location','northwest')

pause
%-------------------------------------------------
% Run the filter for second order.
order   = 2;
gap     = 3;
segment = 5;

[y_has,cl] = savgol(x,9,order,order,struct('tails','weighted'));
[y_hat,cm] = gapsegment(x,order,gap,segment);
[y_hau,cn] = gapsegment(x,order,gap,segment,struct('algorithm','savgol'));
figure('Name','Second Order'), subplot(2,1,1)
plot(x,'b'), axis([0 401 0 1.8])
subplot(2,1,2)
h(1) = plot(y_hau*max(y_hat)/max(y_hau),'k','linewidth',2); hold on
axis([0 401 -0.003 0.005])
set(hline,'color',[0.8 0.8 0.8])
h(2) = plot(y_hat,'b');
h(3) = plot(y_has*max(y_hat)/max(y_has),'r');
legend(h, 'GapSegment savgol 2,3,5','GapSegment 2,3,5 ', ...
  'SavGol 9,2,2 [scaled]','location','northwest')

pause
%-------------------------------------------------
% Run the filter for third order.
order   = 3;
gap     = 3;
segment = 5;

[y_has,cl] = savgol(x,11,order,order,struct('wt','1/d','tails','weighted'));
[y_hat,cm] = gapsegment(x,order,gap,segment);
[y_hau,cn] = gapsegment(x,order,gap,segment,struct('algorithm','savgol'));
figure('Name','Third Order'), subplot(2,1,1)
plot(x,'b'), axis([0 401 0 1.8])
subplot(2,1,2)
h(1) = plot(y_hau*max(y_hat)/max(y_hau),'k','linewidth',2); hold on
axis([0 401 -6e-5 1e-4])
set(hline,'color',[0.8 0.8 0.8])
h(2) = plot(y_hat,'b');
h(3) = plot(y_has*max(y_hat)/max(y_has),'r');
legend(h, 'GapSegment savgol 3,3,5 [scaled]','GapSegment 3,3,5', ...
  'SavGol 11,3,3 (wted 1/d) [scaled]','location','northwest')
 
pause
%-------------------------------------------------
% Run the filter for fourth order.
order   = 4;
gap     = 5;
segment = 5;

[y_has,cl] = savgol(x,15,order,order,struct('wt','1/d','tails','weighted'));
[y_hat,cm] = gapsegment(x,order,gap,segment);
[y_hau,cn] = gapsegment(x,order,gap,segment,struct('algorithm','savgol'));
figure('Name','Fourth Order'), subplot(2,1,1)
plot(x,'b'), axis([0 401 0 1.8])
subplot(2,1,2)
h(1) = plot(y_hau*max(y_hat)/max(y_hau),'k','linewidth',2); hold on
axis([0 401 -5e-7 8e-7])
set(hline,'color',[0.8 0.8 0.8])
h(2) = plot(y_hat,'b');
h(3) = plot(y_has*max(y_hat)/max(y_has),'r');
legend('GapSegment savgol 4,5,5 [scaled]','GapSegment 4,5,5','SavGol 15,4,4 (wted 1/d) [scaled]','location','northwest')
 
%End of GAPSEGMENTDEMO
 
echo off
  
   
