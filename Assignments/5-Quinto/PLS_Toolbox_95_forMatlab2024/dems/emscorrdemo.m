echo on
%EMSCORRDEMO Demo of the EMSCORR function

echo off
%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg

echo on

%To run the demo hit a "return" after each pause
pause
 
% First well load a data set of NIR spectra.
% These data are from Harald Martens and are described
% in detail in Martens H, Nielsen JP, Engelsen SB,
% Anal. Chem. 2003; 75(3): 394–404.
 
% Hit a return and we'll load and plot the spectra.
 
pause
 
load NIR_GlutenStarch
 
figure, plot(x.axisscale{2},x.data')
xlabel(x.axisscalename{2}), title(x.title{2}), ylabel('ln(1/T)')
 
% You'll note that these spectra of starch and gluten
% particles show quite a bit of scatter. This is due
% in large part to different packing of the material.
 
% Now estimate a reference spectrum:
 
ical = [1:20,41:60,81:100];  %indices for calibration data
iprd = setdiff(1:100,ical);  %indices for test data
xref = mean(x.data(ical,:)); %Reference spectrum for SC
 
pause
 
% Let's first try multiplicative scatter correction, MSC.
% MSC does not account for the fact that analytes are present
% in reference spectra, it doesn't account for scatter artifacts
% other than a baseline and offset, and it doesn't really work 
% very well for this problem.
 
sx            = mscorr(x.data,xref); %Conventional MSC
figure, plot(x.axisscale{2},sx')
xlabel(x.axisscalename{2}), title(x.title{2}), ylabel('MSC: log(1/T)')
 
pause
 
% What we know is that the first five samples are pure
% gluten and the last five are pure starch. A good estimate
% of a "good" spectrum to keep - a spectrum that accounts
% for the presence of analyte(s) - is the difference of two
% of these pure samples. So, this is something that we don't
% want to filter out! This difference spectrum will be
% assigned to the options.s field when we perform EMSC.

% Let's run EMSCORR and plot the scatter corrected results.
 
pause
 
options       = emscorr('options');             %default is 2nd order polynomial
options.s     = x.data(3,:)-x.data(93,:);       %spectra to not filter out
[esx,fx]      = emscorr(x.data,xref,options);
figure, plot(x.axisscale{2},esx')
xlabel(x.axisscalename{2}), title(x.title{2}), ylabel('EMSC: log(1/T)')
 
pause
 
% We can also plot the the scatter, i.e. what was filtered out...
 
pause
figure, plot(x.axisscale{2},fx')
xlabel('Wavelength (nm)')
ylabel('EMSC filtered out portion: log(1/T)') 
 
pause
 
% Now we'll try CLS with the MSC and EMSC results and
% compare to the known concentrations.
% The reference values are given in the variable y.
 
s0  = y.data(ical,:)\x.data(ical,:); %Estimated spectra for uncorrected data
sM  = y.data(ical,:)\sx(ical,:);     %Estimated spectra for MSC corrected data
sE  = y.data(ical,:)\esx(ical,:);    %Estimated spectra for EMSC corrected data
figure, plot(x.axisscale{2},s0,':'), hold on
plot(x.axisscale{2},sM,'-.')
plot(x.axisscale{2},sE,'-'), hold off
legend('Uncorrected Gluten','Uncorrected Starch', ...
       'MSC Gluten','MSC Starch', ...
       'EMSC Gluten','EMSC Starch')
xlabel(x.axisscalename{2})
 
% This shows 3 very different estimated spectra for the
% three preprocessing methods; none, MSC, and EMSC. We need
% to be careful how the preprocessed results are interpreted.
 
% Let's now try this in prediction.
 
pause
 
c0p = x.data(iprd,:)/s0;
cMp = x.data(iprd,:)/sM;
cEp = x.data(iprd,:)/sE;
figure, subplot(2,1,1), plot(y.data(iprd,1),c0p(:,1),'ob'), hold on
plot(y.data(iprd,1),cMp(:,1),'dm')
plot(y.data(iprd,1),cEp(:,1),'sr'), hold off, title('Predictions vs. Known')
legend('none','MSC','EMSC','location','northwest'), ylabel('Gluten'), dp
subplot(2,1,2), plot(y.data(iprd,2),c0p(:,2),'ob'), hold on
plot(y.data(iprd,2),cMp(:,2),'dm')
plot(y.data(iprd,2),cEp(:,2),'sr'), hold off, title('Predictions vs. Known')
legend('none','MSC','EMSC','location','northwest'), ylabel('Starch'), dp
 
rmsep0 = rmse(y.data(iprd,:),c0p);
rmsepM = rmse(y.data(iprd,:),cMp);
rmsepE = rmse(y.data(iprd,:),cEp);
 
echo off
disp(sprintf('Prepro-          RMSEP'))
disp(sprintf('cessing      Gluten  Starch'))
disp(sprintf('none          %5.2f   %5.2f',rmsep0))
disp(sprintf('MSC           %5.2f   %5.2f',rmsepM))
disp(sprintf('EMSC          %5.2f   %5.2f',rmsepE))
 
echo on
% This shows that, of the three preprocessing methods
% examined, EMSC has provided the best correction
% for this example, and MSC has really ruined our ability
% to calibrate and predict.
 
%End of EMSCORRDEMO
%
%See also: MSCORR, STDFIR, EMSCORRDEMO2
 
echo off
