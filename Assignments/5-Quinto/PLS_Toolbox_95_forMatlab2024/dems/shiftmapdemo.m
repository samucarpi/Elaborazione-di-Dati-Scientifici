echo on
% SHIFTMAPDEMO Demo of the SHIFTMAP function
 
echo off
% Copyright © Eigenvector Research, Inc. 2022
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
 
% The SHIFTMAP function calculates a shift invariant tri-linear factor 
% matrix for the columns of input (x). It also returns z = fft(x),
% r = |fft(x)| and phase spectrum (a).
 
% I/O: [z,r,a,p,xsit] = shiftmap(x,options);
% For options.ncomp = 1 {default}, SHIFTMAP calculates the the FFT power
% spectra (r) for the columns of (x). It then calculates a 1 PC PCA model
% of the power spectra (p = loadings) and the 
% output (xsit) is the IFFT of r.*a.

% Next, an example of shifted peaks of similar shape is shown.
 
pause
 
echo off
prf4  = 'trpl'; %'gaussiandbl'; %'gaussian';

%% 1) Shape similar example
ax    = 1:100;
switch lower(prf4)
case 'gaussian'
  echo on
  x     = [peakgaussian([1 22 4],ax);
           peakgaussian([1 45 4],ax);
           peakgaussian([1 55 4],ax)]'; 
  echo off
case 'gaussiandbl'
  echo on
  x     = [peakgaussian([1 22 4],ax)+peakgaussian([0.5 30 4],ax);
           peakgaussian([1 45 4],ax)+peakgaussian([0.5 53 4],ax);
           peakgaussian([1 55 4],ax)+peakgaussian([0.5 63 4],ax)]';
  echo off
case 'trpl'
  echo on
  x     = [peakgaussian([1 22 4],ax)+peaklorentzian([1.25 30 4],ax)+peakgaussian([0.5 36 4],ax);
           peakgaussian([1 45 4],ax)+peaklorentzian([1.25 53 4],ax)+peakgaussian([0.5 59 4],ax);
           peakgaussian([1 55 4],ax)+peaklorentzian([1.25 63 4],ax)+peakgaussian([0.5 69 4],ax)]';
  echo off
end
 
echo on
% Call SHIFTMAP and make plots
 
options       = shiftmap('options');
options.algorithm = 'sits';
[~,r,a,xsit]  = shiftmap(x);
np      = 2.^nextpow2(size(x,1));
 
echo off
shiftmapdemoplot1(r,a,np,ax,x)
set(gcf,'Name','Similar Signal Shapes')
 
echo on
% This plot shows the original signals as three similar peaks at different
% locations in the top graph.
% The middle graph shows the one-sided power spectra for the three signals
% lying on top of one-another (showing shift invariance). 
% The bottom graph shows the one-side phase spectra for the three signals
% not lying on top of one another.
 
pause
 
echo off
shiftmapdemoplot2(ax,x,xsit)
set(gcf,'Name','Similar Signal Shapes')
 
echo on
% This plot shows the original signals as three similar peaks at different
% locations with the SHIFTMAP reconstructed signal. As expected, the
% reconstruction lies on top of the original signal.
 
% The next example shows the results for dissimilar signal shapes.
 
pause
 
echo off
%% 2) Shape different example
switch lower(prf4)
case 'gaussian'
  echo on
  x     = [peakgaussian([1 22 4],ax);
           peakgaussian([1 45 6],ax);
           peakgaussian([1 55 8],ax)]';
  echo off
case 'gaussiandbl'
  echo on
  x     = [peakgaussian([1 22 4],ax)+peakgaussian([0.5 30 4],ax);
           peakgaussian([1 45 6],ax)+peakgaussian([0.5 53 6],ax);
           peakgaussian([1 55 8],ax)+peakgaussian([0.5 63 8],ax)]';
  echo off
case 'trpl'
  echo on
  x     = [peakgaussian([1 22 4],ax)+peaklorentzian([1.25 18 4],ax)+peakgaussian([0.5 36 4],ax);
           peakgaussian([1 45 4],ax)+peaklorentzian([1.25 47 8],ax)+peakgaussian([0.5 59 6],ax);
           peakgaussian([1 55 4],ax)+peaklorentzian([1.25 61 6],ax)+peakgaussian([0.5 69 8],ax)]';
  echo off
end
 
echo on
% Call SHIFTMAP with 2 PCs and make plots
 
options       = shiftmap('options');
options.ncomp = 2;
[~,r,a,xsit,p]  = shiftmap(x,options);

echo off
  % if false %true %hard switch for testing
  %   [~,r,a,xsitp]     = shiftmap(x,p);
  %   figure("Name","Test Pred SIT")
  %   plot(xsit), hold on
  %   plot(xsitp,'--')
  % else
  %   options.algorithm = 'sits';
  %   [~,r,a,xsit,p,a0] = shiftmap(x,options);
  %   [~,r,a,xsitp]     = shiftmap(x,p,a0);
  %   figure("Name","Test Pred SITS")
  %   plot(xsit), hold on
  %   plot(xsitp,'--')
  % end
 
echo off
shiftmapdemoplot1(r,a,np,ax,x)
set(gcf,'Name','Dissimilar Signal Shapes')
 
echo on
% This plot shows the original signals as three dissimilar peaks at
% different locations in the top graph.
% The middle graph shows the one-sided power spectra for the three signals
% not lying on top of one-another. 
% The bottom graph shows the one-side phase spectra for the three signals
% not lying on top of one another.
 
pause
 
echo off
shiftmapdemoplot2(ax,x,xsit)
set(gcf,'Name','Disimilar Signal Shapes')
 
echo on
% This plot shows the original signals as three dissimilar peaks at
% different locations with the SHIFTMAP reconstructed signal. As expected,
% the reconstruction nearly lies on top of the original signal.
 
%-------------------------------------------------
% SHIFTMAP accounts for signal shifting and works very well when the
% signal shapes are identical. The approximation for dissimilar shapes is
% not as good but still a reasonable reproduction when 2 PCs are used to
% model the power spectra.
 
%End of SHIFTMAPDEMO
 
echo off
  
function [] = shiftmapdemoplot1(r,a,np,ax,x)
figure
subplot(3,1,1)
plot(ax,x)
vv    = axis; axis([0 size(x,1)+0.5 vv(3:4)])
ylabel('Signal, x')
title('Original Signal')
xlabel('"Time"')
subplot(3,1,2)
plot(r)
vv    = axis; axis([0 (np+1)/2 vv(3:4)])
title('z = \itF\rm(x) = |z|e^{\iti\theta}','Interpreter','tex','FontWeight','normal')
ylabel('One-side |z|')
xlabel('"Frequency"')
subplot(3,1,3)
plot(a)
title('Angle, \it\theta','Interpreter','tex')
ylabel('One-side \it\theta','Interpreter','tex')
xlabel('"Frequency"')
vv    = hline('k'); vv.Color = [1 1 1]*0.8;
uistack(vv,'bottom')
vv    = axis; axis([0 (np+1)/2 -pi pi])
end %shiftmapdemoplot1

function [] = shiftmapdemoplot2(ax,x,xsit)
figure
for i1=1:3
  subplot(3,1,i1)
  plot(ax,x(:,i1)), hold on
  plot(ax,xsit(:,i1),'--')
  title(['Signal ',int2str(i1)])
  if i1==1
    legend('Original Signal','SHIFTMAP Reconstructed Signal')
  end
  if i1==3
    xlabel('"Time"')
  end
end
% disp(rmse(x,xsit))

end %shiftmapdemoplot2