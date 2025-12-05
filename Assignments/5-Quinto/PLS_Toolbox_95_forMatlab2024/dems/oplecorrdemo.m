echo on
%OPLECORRDEMO Demo of the OPLECORR function

echo off
%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg

echo on

%To run the demo hit a "return" after each pause
pause
 
% First well load a data set of NIR spectra.
% These data are from Harald Martens and are described in detail in 
% Martens H, Nielsen JP, Engelsen SB, Anal. Chem. 2003; 75(3), 394-404.
% and used in Z-P Chen, J Morris, E Martin, Anal. Chem. 2006, 78, 7674-7681.
 
% The units for the reflectance measurements are ln(1/T).
 
% Hit a return and we'll load and plot the spectra.
 
pause
 
load NIR_GlutenStarch
ical  = [1:20,41:60,81:100];          %indices for calibration data
iprd  = setdiff(1:100,ical);          %indices for test data
 
figure('Name','No Preprocessing')
plotgui(x,'PlotBy','1','AxisMenuValues',{0 1:100})
 
% You'll note that these spectra of starch and gluten particles show quite
% a bit of scatter. This is due, in large part, to different packing of
% the material.
 
% The next step will set up preprocessing for MSC, EMSCorr and OPLECorr so
% that we can make comparisons between the different preprocessings. The
% hope is that OPLEC will provide something very similar to EMSC w/ far
% less effort.
 
pause
 
smsc  = preprocess('default','msc');  % MSC (default preprocessing structure)
semsc = preprocess('default','emsc'); %EMSC (default preprocessing structure)
% soplc = preprocess('default','oplec');%OPLEC (default preprocessing structure)
 
% Next, the preprocessing structures will be calibrated on the calibration
% data [based on the indices (ical)], and plotted.
 
pause
 
% In their default state, MSC and EMSC both correct to the mean spectrum.
% The default behavior is kept for this demo.
[xmsc, smsc]  = preprocess('calibrate',smsc, x(ical,:)); % MSC
xmsc          = preprocess('calibrate',smsc, x);        % MSC
 
% It is known that the first five samples are pure gluten and the last
% five are pure starch. This gives a useful piece of information i.e.,
% a good estimate of a "good" spectrum to not filter out. This can be
% handled in two ways:
switch 2
case 1
  % Because the reference is, by default, the mean spectrum it is important
  % that the set of "good" spectra be augmented to the mean be a full rank
  % matrix. The difference spectrum satisfies this requirement and is
  % assigned to the semsc.userdata.s field (options.s in EMSCORR) for EMSC.
  semsc.userdata.s     = mean(x.data(1:5,:))-mean(x.data(96:100,:)); %spectrum to not filter out
case 2
  % Another way to handle this is to tell the algorithm that the
  % reference spectrum includes the targets (and will likely result in
  % an ill-conditioned problem. Then, the ill-conditioning is handled automatically
  semsc.userdata.s     = [mean(x.data(1:5,:));mean(x.data(96:100,:))]; %spectrum to not filter out
  semsc.userdata.xrefS = 'yes';
end
[xemsc,semsc] = preprocess('calibrate',semsc,x(ical,:)); %EMSC
xemsc         = preprocess('calibrate',semsc,x);         %EMSC

% [xoplc,soplc] = preprocess('calibrate',soplc,x(ical,:)); %OPLEC
% [xbplc,sbplc] = preprocess('calibrate',sbplc,x(ical,:)); %OPLECB
 
figure('Name','MSC'),   plotgui(xmsc, 'plotby','1','AxisMenuValues',{0 1:100})
figure('Name','EMSC'),  plotgui(xemsc,'plotby','1','AxisMenuValues',{0 1:100})
% figure('Name','OPLEC'), plotgui(xoplc,'plotby','1','AxisMenuValues',{0 1:100})
 
pause
 
    % And now OPLECORR. But this will be removed once oplec is put into
    % preprocess
    optople       = oplecorr('options');             %default is 2nd order polynomial
    oplcmod       = oplecorr(x(ical,:),y(ical,1),2,optople); %creates an OPLECORR model
    xoplc         = oplecorr(x,oplcmod);              %applies the model
    figure('Name','OPLEC'), plotgui(xoplc,'plotby','1','AxisMenuValues',{0 1:100})

pause
 
% How do the OPLECORR and EMSCORR processed data compare? The main
% difference is expected to be due to orthogonalizing to the background
% basis. So, let's do that to the EMSCORR results.

osxp = xemsc.data - (xemsc.data/oplcmod.p')*oplcmod.p'; %orthogonalization of EMSC data
figure, plot(x.axisscale{2},osxp')
xlabel(x.axisscalename{2}), title(x.title{2}), ylabel('EMSC Orthog: log(1/T)')
 
% They look similar but they aren't identical. This is likely due to
% differences in the choice of vectors in the respective bases.
   
% Let's now try this in prediction.
   
pause
 
% Model calibrations (the number of LVs were chosen previously using
% cross-validation).
optspls       = pls('options');
optspls.plots = 'none';
 
%No scatter correction, just mean-centering
optspls.preprocessing = {preprocess('default','meancenter'), preprocess('default','meancenter')};
modl_none     = pls(x(ical,:),y(ical,1),3,optspls);

  modl_ople   = pls(xoplc(ical,:),y(ical,1),4,optspls); %OPLEC  not in prprocess yet
%   modl_bple   = pls(xbplc(ical,:),y(ical,1),5,optspls); %OPLECB not in prprocess yet

%MSC on the X-block, then mean-centering
optspls.preprocessing{1}(2) = optspls.preprocessing{1}(1);
optspls.preprocessing{1}(1) = smsc;
modl_msc      = pls(x(ical,:),y(ical,1),6,optspls);

%EMSC on the X-block, then mean-centering
optspls.preprocessing{1}(1) = semsc;
% optspls.preprocessing{1}(1).userdata.s = x.data(3,:)-x.data(93,:);  %spectra to not filter out
modl_emsc     = pls(x(ical,:),y(ical,1),6,optspls); %6 LVs

%Model predictions
optspls       = pls('options');
optspls.plots = 'none';
optspls.display = 'off';
pred_none     = pls(x(iprd,:),y(iprd,1),modl_none,optspls);
pred_msc      = pls(x(iprd,:),y(iprd,1),modl_msc ,optspls);
pred_emsc     = pls(x(iprd,:),y(iprd,1),modl_emsc,optspls);

  pred_ople   = pls(xoplc(iprd,:),y(iprd,1),modl_ople,optspls); %OPLEC  not in prprocess yet
%   pred_bple   = pls(xbplc(iprd,:),y(iprd,1),modl_bple,optspls); %OPLECB not in prprocess yet
   
echo off
disp(sprintf('Prepro-      RMSEP'))
disp(sprintf('cessing      Gluten '))
disp(sprintf('none         %5.3f',pred_none.rmsep(1,end)))
disp(sprintf('MSC          %5.3f',pred_msc.rmsep(1,end)))
disp(sprintf('EMSC         %5.3f',pred_emsc.rmsep(1,end)))
disp(sprintf('OPLEC        %5.3f',pred_ople.rmsep(1,end)))
% disp(sprintf('OPLECB       %5.3f',pred_bple.rmsep(1,end)))
 
echo on
% This shows that, of the preprocessing methods examined,
% MSC has really ruined our ability to calibrate and predict
% and OPLEC has provided the best correction for this example.
 
%End of OPLECORRDEMO
%
%See also: EMSCORR, MSCORR, OPLECORR, STDFIR
 
echo off
