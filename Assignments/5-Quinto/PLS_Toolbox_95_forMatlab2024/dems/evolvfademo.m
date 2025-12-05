echo on
%EVOLFADEMO Demo of the EVOLFA and EWFA functions
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Create data to test the EVOLVFA and EWFA algorithms:
 
w = [0:0.1:2*pi];
s = [sin(w-pi/4).^4; 2*(cos(w)).^4];              %pure analyte spectra
s(1,1:10)   = 0; %ensuring some selectivity between the spectra
s(2,46:end) = 0; 
t = [0:40]';
c = [exp(-((t-20).^2)/40) exp(-((t-25).^2)/30)];  %elution profiles
xdat = c*s + randn(length(t),length(w))*.01;      %outer product of elution and spectra
 
% Note that (xdat) has two factors with a little bit of noise.
% This will make it easy to understand the EVOLVFA and EWFA
% results, but first let's plot the data.
 
pause
%-------------------------------------------------
figure
subplot(2,1,1), plot(t,c),      axis([0 40 0 1.1])
xlabel('Time (t)'), ylabel('C')
subplot(2,1,2), plot(w,s),      axis([0 6.5 0 4.1])
xlabel('Channel'),  ylabel('S')
 
pause
%-------------------------------------------------
% Now try the EVOLVFA function to do evolving factor analysis (EFA).
 
[egf,egr] = evolvfa(xdat,1,t);
 
% The forward analysis shows that there is something significant
% entering the data at time 7 and 15. This agrees well the the
% plot of C vs T in the previous figure.
 
% The reverse analysis shows that there is something significant
% disappearing from the data at time 29 and 36. This also agrees
% well with the C vs T plot.
 
% However, note that in the C vs T plot the first analyte to enter
% is the first to leave (this is typical of GC and LC data). This
% is not apparent from the EFA results since it doesn't tell "what"
% enters and leaves - just that something significant did.
 
pause
%-------------------------------------------------
% EWFA can be used to localize estimates of "when" new sources of
% variance are present in a data set.
 
% From the EVOLVFA (EFA) results we now know that there are a
% total of 2 significant sources of variance in (xdat). Therefore,
% we need a minimum window size for EWFA of 3 (1 for each factor
% and 1 to provide an estimate of the noise level).
 
% Now we'll run the EWFA function.
 
pause
%-------------------------------------------------
 [eigs,skl] = ewfa(xdat,3,1,t);
 
% This shows a plot of the singular values in a window centered
% at each time in (t). The EWFA results show that there is only
% one significant source of variance in the two windows 5<t<15
% and 30<t<38, and there are two significant sources of variance
% in the window 15<t<30. This is consistent with the C vs T plot.
 
pause
%-------------------------------------------------
% Now let's try EVOLVFA and EWFA on some real data.
 
load oesdata
disp(oes1.description)
 
pause
%-------------------------------------------------
% This data is for metal etch on semi-conductor wafers.
% We'll just use one wafer's worth of data and try the 
% EVOLVFA and EWFA functions. But first let's plot it.
 
plot(oes1.data), xlabel('Time'), ylabel('OES Intensity')
 
% It is clear that some of the channels in the OES data
% show the 3 different regions of the etch: TiN, Al, Overetch. 
 
pause
%-------------------------------------------------
% First we'll use EVOLVFA to get an estimate of the total number
% factors and get a first estimate of when different sources of
% variance appear/disappear.
 
[egf,egr] = evolvfa(oes1.data);
 
% This plot suggests that there are 4 significant factors and
% one major source of variance is present over the entire etch.
% Something new comes in at times ~9, 11, and 18, and
% something disappears at times ~12, 17, and 25.
 
% Now let's try EWFA to try to localize what is when.
 
pause
%-------------------------------------------------
[eigs,skl] = ewfa(oes1.data,5);
 
% What this plot shows is that the following
% # of sources 
% of variance      region(s)
%     1            ~0<t<7 and ~27<t<46
%     2            ~7<t<9 and ~16<t<27
%     3            ~9<t<16
 
% Comparing the results from EVOLVFA and EWFA (recall that
% the window width is 5) suggests the following
% # of sources 
% of variance      region(s)
%     1            ~0<t<9 and ~25<t<46
%     2            ~9<t<11 and ~13<t<25
%     3            ~11<t<12
 
%End of EVOLVFADEMO and EWFADEMO
 
echo off
