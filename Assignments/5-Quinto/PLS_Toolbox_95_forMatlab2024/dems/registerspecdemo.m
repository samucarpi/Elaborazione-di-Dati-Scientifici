echo on
% REGISTERSPECDEMO Demo of the REGISTERSPEC function
 
echo off
% Copyright © Eigenvector Research, Inc. 2008
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%JMS

randn('seed',0);  %initialize seed so we get the shift vector we expect

echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The REGISTERSPEC function is used to correct spectra or other
% column-wise-correlated data for variable "shifting" (inaccuracy).
% It is common in some analytical instrumentation that the measured
% responses are "shifted" from one sample to another (do not maintain the
% same variable axis scale). Instead we observe a slight shifting of
% signals among variables due simply to instrumental artifacts.
%
% Such inaccuracies in axis scale cause models to appear to be invalid for
% the given data (increased residuals).
 
pause
%-------------------------------------------------
% A number of instrument standardization methods can be applied to solve
% this problem such as direct standardization and the windowed versions of
% that function (see STDGEN). The REGISTERSPEC function solves the problem by:
%  1) identifying "stable" peaks in a calibration set and then
%  2) correcting new spectra (with axisscale errors) by locating the same
%      peaks in the new spectrum and correcting the axisscale based on the
%      observed peak locations.
% Typically, this works well on data which has some narrow, consistent
% peaks whos position is not sensitive to the physics or chemistry of
% interest (i.e. good "reference peaks").
 
pause
%-------------------------------------------------
% We will demonstrate the function using Nuclear Magnetic Resonance (NMR)
% data. In this case, the data is 20 spectra measured at 1176 ppm shifts
% (i.e. the axisscale of NMR data is "Frequency Shift" in units of ppm).
% Here is a plot of the data with all the spectra "normalized" in intensity
% so you can see how well most of the peaks are aligned with each other.
% Note there are some shoulders and other peak changes which are occurring,
% for example, the shoulder at 1.28 ppm is changing intensity.
 
load nmr_data
figure
plot(nmrdata.axisscale{2},nmrdata.data(2:end,:));
xlabel('Frequency Shift (ppm)')
title('Original Data')
yscale(1)
 
pause
%-------------------------------------------------
% To begin using REGISTERSPEC, we must either manually select peaks to use
% as a reference or have REGISTERSPEC automatically choose peaks to use. We
% will demonstrate the automatic peak selection by asking REGISTERSPEC to
% identify the peaks it sees as "stable".
%
% To perform peak finding, we must first specify the maximum shift (in
% units of our axisscale, so ppm in this case) which we expect may occur in
% our data. In this case, we're going to limit our maximum expected shift
% to be 0.05 ppm. This is set in the "maxshift" option, so we start by
% getting options, and setting the maxshift option to be 0.05.
 
options = registerspec('options');
options.maxshift = .05;
 
pause
%-------------------------------------------------
% Next, we'll call REGISTERSPEC with the calibration data and these
% options. The function will search for stable peaks and return a vector of
% peak locations it recommends as good reference peaks:
 
peaks = registerspec(nmrdata,options);
  
pause
%-------------------------------------------------
% we can mark these located peaks on our plot using the vline function:
 
vline(peaks)
 
pause
%-------------------------------------------------
% Note that REGISTERSPEC assumes that the calibration data does NOT have
% any axis scale errors (does not need shift correction itself). If it
% does, you would want to repeat the peak finding process after correcting
% the calibration data for any shifts, for example, by using a known
% manually-selected reference peak.
 
pause
%-------------------------------------------------
% For this demo, we'll simulate an axisscale error in the calibratoin data
% using the MATLAB "interp1" function and some random small shifts... 
% Here's the code we're using:
%
% shift = randn(1,20)*.01
% nmrshifted = nmrdata; 
% for j=1:20; 
%   nmrshifted.data(j,:) = interp1(nmrdata.axisscale{2},nmrdata.data(j,:),...
%     nmrdata.axisscale{2}+shift(j),'spline',0); 
% end
 
echo off
shift = randn(1,20)*.01;
nmrshifted = nmrdata; 
for j=1:20; nmrshifted.data(j,:) = interp1(nmrdata.axisscale{2},nmrdata.data(j,:),nmrdata.axisscale{2}+shift(j),'spline',0); end
echo on
 
pause
%-------------------------------------------------
% Here's a plot of the original data (top) and the shifted data (middle).
% Note how the shift causes the peaks to be misaligned and in the resulting
% plot of the data, the overlaid spectra look "wide". (Note: we're dropping
% the first spectrum in these plots because it is so significantly
% different in intensity that it does not normalize such that you can
% compare peak positions)
 
subplot(2,1,1)
plot(nmrdata.axisscale{2},nmrdata.data(2:end,:));
title('Original Data w/Selected Peaks')
vline(peaks);
 
subplot(2,1,2);
plot(nmrdata.axisscale{2},nmrshifted.data(2:end,:)); 
title('Shifted Data (simulated)')
yscale(1)
 
pause
%-------------------------------------------------
% This misalignment will cause misfit of a model to this data. We'll create
% a PCA model of the original data and apply that model to the shifted
% data. Finally, we'll plot the Q residuals of the original data (blue) and
% the shifted data (green). The dashed red line is the 95% confidence limit
% line. Above this line is considered unusual sample. Note that most of the
% shifted spectra (green) are showing residuals above the limit. Also note
% this is a log scale!
 
model = pca(nmrdata,2,struct('plots','none','display','off','preprocessing',{{'meancenter'}}));
shiftpred = pca(nmrshifted.data,model,struct('plots','none'));
clf
semilogy(1:20,model.ssqresiduals{1},'bo',1:20,shiftpred.ssqresiduals{1},'ro');
hline(model.detail.reslim{1},'r--')
 
pause
%-------------------------------------------------
% To correct the shift, we'll call REGISTERSPEC with our shifted data as
% input, plus the vector of selected peaks and our options. By default, the
% shift correction is done using a zero-order polynomial (i.e. offset of
% axis scale ONLY). If the axisscale error includes "stretching" or
% "rubber-banding" higher-order polynomials can be used (using the
% options.order option) or other non-polynomial correction functions can be
% used (using the options.algorithm option). Here we'll leave the options
% at the default values.
 
[nmralign,ax,foundat] = registerspec(nmrshifted,peaks,options);
 
% The outputs of the function include the corrected data (nmralign), the
% uniform axisscale (ax), and a matrix of peak "errors" found for each
% spectrum (foundat). The (foundat) matrix can be used to examine the
% details of how each spectrum's shift was calculated.
 
pause
%-------------------------------------------------
% Let's plot the corrected spectra (bottom) for comparison to the original
% and shifted. Note that the corrected spectra again look much like the
% original in terms of peak alignment.

echo off
subplot(3,1,1)
plot(nmrdata.axisscale{2},nmrdata.data(2:end,:));
title('Original Data w/Selected Peaks')
vline(peaks);
subplot(3,1,2);
plot(nmrdata.axisscale{2},nmrshifted.data(2:end,:)); 
title('Shifted Data (simulated)')
echo on
 
subplot(3,1,3);
plot(nmrdata.axisscale{2},nmralign.data(2:end,:)); 
title('REGISTERSPEC Corrected Data')
yscale(1)
 
pause
%-------------------------------------------------
% Now, we'll apply the PCA model to the corrected data and examine the new
% Q residuals (aligned data shown as green circles). There we see that all
% but the first spectrum have been brought down closer to the 95%
% confidence limit. Note we are no longer showing this on a log scale.
 
clf
alignpred = pca(nmralign.data,model,struct('plots','none'));
plot(1:20,model.ssqresiduals{1},'bo',1:20,alignpred.ssqresiduals{1},'ro');
hline(model.detail.reslim{1},'r--')
xlabel('Spectrum Number')
ylabel('Q Residuals')
 
pause
%-------------------------------------------------
% So what happened with the first spectrum? If we examine the (foundat)
% output from REGISTERSPEC for the first spectrum (first row of foundat
% corresponds to the first spectrum in the data), we see that reference
% peak #14 (which is at 4.6 ppm) was found shifted nearly -0.05 ppm. In
% contrast, the others were all closer to -0.012 ppm shifted. This
% indicates that this peak is probably not a good reference peak.
 
plot(foundat(1,:),'o')
xlabel('Reference Peak Number')
ylabel('Found Shift (ppm)')
 
pause
%-------------------------------------------------
% We can drop the peak (#14) from "peaks" and repeat the alginment
% procedure and reapply the PCA model. This time, spectrum #1 looks much
% better (albeit still above the 95% confidence limit). We could further
% refine the correction using chemical knowledge about the system and
% selection of peaks.
 
peaks(14) = [];  %drop peak #14
[nmralign,ax,foundat] = registerspec(nmrshifted,peaks,options);
alignpred = pca(nmralign.data,model,struct('plots','none'));
plot(1:20,model.ssqresiduals{1},'bo',1:20,alignpred.ssqresiduals{1},'ro');
hline(model.detail.reslim{1},'r--')
xlabel('Spectrum Number')
ylabel('Q Residuals')
 
pause
%-------------------------------------------------
%End of REGISTERSPECDEMO
 
echo off
  
   
