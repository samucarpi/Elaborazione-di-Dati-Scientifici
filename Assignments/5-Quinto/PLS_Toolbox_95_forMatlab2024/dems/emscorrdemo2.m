echo on
%EMSCORRDEMO2 Demo of the EMSCORR function

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
% These data are from Harald Martens and are described in detail in
% Martens H, Nielsen JP, Engelsen SB, Anal. Chem. 2003; 75(3): 394–404.
 
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
options.algorithm = 'cls';
[esx,fx,xrf,reg,res] = emscorr(x.data,xref,options);
figure, plot(x.axisscale{2},esx')
xlabel(x.axisscalename{2}), title(x.title{2}), ylabel('EMSC: log(1/T)')
 
pause
 
% Next let's examine the regression coefficients (reg).
% Output (reg) is 5x100; 5 coefficients by 100 measured spectra.
% The coefficients correspond to the following basis
%     xbase = [xref 1 x x^2 ... options.p options.s] i.e.
% multiplicative ^  ^ ^ ^            ^         ^  
%       polynomials | | | ...        |         |
%         spectra to be filtered out |         |
%              spectra not to be filtered out  |
 
% For this example
%  reg(1,:) corresponds to the multiplicative effect
% for each of the 100 measured spectra; it is the coef
% multiplied by xref.
% The polynomial order was 2 {default} so that
%  reg(2,:) corresponds to the offset,
%  reg(3,:) corresponds to the linear term, and
%  reg(4,:) corresponds to the quadradic term.
% The "bad" spectra (options.p) was empty, and the
% last regression coefficient corresponded to (options.s).
%  reg(5,:) corresponded to the 1x100 "good spectrum".
 
figure, plot(reg','.-')
xlabel('Sample Index')
legend('Mutiplicative','Offset','Linear','Quadradic','Good Spectrum')
 
pause

% Now try the same correction with extended inverse
% multiplicative scatter correction
 
options.algorithm = 'ils';
[esxi,fxi,xrfi,regi,resi] = emscorr(x.data,xref,options);
 
figure, plot(regi','.-')
xlabel('Sample Index')
legend('Mutiplicative','Offset','Linear','Quadradic','Good Spectrum', ...
  'Location','SouthEast')

%End of EMSCORRDEMO2
%
%See also: MSCORR, STDFIR, EMSCORRDEMO
 
echo off
