echo on
%MSCORRDEMO Demo of the MSCORR function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 

 
disp('There are two MSC demos available:')
disp('  1: demo of Muiltiplicative Scatter/Signal Correction, or')
disp('  2: a demo of MSC with robust fitting (MSCR).')
sd    = input('please input an integer for the demo: ','s');

echo on
 
%To run the demo hit a "return" after each pause
 
%-------------------------------------------------
switch lower(sd)
case '2'
load('OliveOilData.mat'), whos
% xcal is 36x518 but the xcal.include{2} has 182 elements
disp(xcal.description)
 
% set the include field to include all the variables
xcal.include{2} = 1:size(xcal,2);
xcal = xcal(:,446:480);
 
pause
 
% A create an MSC model
% The default uses MSC corrected to the mean spectrum. Therefore, the
% output (xref) will be the mean spectrum of the olive oil class.
 
xref    = mean(xcal.data(xcal.class{1}==3,:)); %Class 3 is Olive Oil
[sx0,alpha0,beta0] = mscorr(xcal,xref); % MSC with defaults
 
% The outputs (alpha0) and (beta0) are the offsets and slopes respectively
% and sx0 are the MSC corrected spectra.
 
% Next, create a MSCR (MSC - robust) correction.
 
pause

options = mscorr('options');
options.robust = 'lsq2top';  % robust algorithm
options.trbflag = 'bottom';  % fit the reference to the bottom of the spectrum
options.res    = 0.005;      % residuals considered large
 
[sx1,alpha1,beta1] = mscorr(xcal,xref,options);
 
% The outputs (alpha1) and (beta1) are the offsets and slopes respectively
% and sx1 are the MSCR corrected spectra.
 
% Make a plots of example spectra
 
pause
  
figure('Name','spectra'), subplot(2,1,1), ii=35; %corn margerine sample
plot(xcal.axisscale{2},xref), hold on
plot(xcal.axisscale{2},xcal.data(ii,:))
plot(xcal.axisscale{2},sx0.data(ii,:))
plot(xcal.axisscale{2},sx1.data(ii,:))
xlabel(xcal.axisscalename{2}), set(gca,'xdir','reverse')
title(['Example Spectrum ',int2str(ii),' Corn Margerine'])
legend('xref (mean spectrum)','xcal uncorrected','sx0 MSC corrected', ...
       'sx1 MSCR corrected','AutoUpdate','off')
set(hline(0,'k--'),'linewidth',0.5), grid
 
% pause
%  
% axis([2800 3100 0 3])

subplot(2,1,2)
plot(xref,xcal.data(ii,:),'o'), hold on
plot(xref,sx0.data(ii,:),'s')
plot(xref,sx1.data(ii,:),'d')
title('Spectra vs xref')
ylabel('Spectra')
xlabel('xref = (mean)')
legend('xcal uncorrected','sx0 MSC corrected', ...
       'sx1 MSCR corrected','location','northwest','AutoUpdate','off')
grid, dp('-k')
 
pause
 
figure('Name','corfficients'), subplot(2,1,1)
plot([beta0, beta1],'o-'), legend('MSC','MSCR','location','northwest','AutoUpdate','off')
ylabel('Slope (beta)'), grid
subplot(2,1,2)
plot([alpha0, alpha1],'o-'), legend('MSC','MSCR','location','northwest','AutoUpdate','off')
set(hline(0,'k--'),'linewidth',0.5)
ylabel('Offset (alpha)'), grid
xlabel('Spectrum Number')
 
% Samples 33 to 36 (corn margerine) have significantly different
% coef and offsets because they are biased by the 960 peak.
 
case '1'

% Create data:
 
t = 0:0.1:100;
x = [sin(t); sin(t)*2+3];
figure
plot(t,x), hold on
 
pause
%-------------------------------------------------
% Run MSCORR to "correct" spectra 2 to match spectra 1
% i.e. x(1,:) will be the reference spectra (xref), and
% x(2,:) will be corrected to match x(1,:).
 
pause
%-------------------------------------------------
[sx,alpha,beta] = mscorr(x,x(1,:));
 
plot(t,sx,'--r')
 
% Note now that both of the sx "spectra" lie on top of
% the original xref spectra.
 
pause
%-------------------------------------------------
% And the original offset (alpha) and scale factors (beta)
% have been recovered.
 
alpha, beta
otherwise
  disp('demo input not recognized.')
end
 
%End of MSCORRDEMO
 
echo off
