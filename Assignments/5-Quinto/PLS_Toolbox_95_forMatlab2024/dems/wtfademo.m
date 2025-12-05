echo on
%WTFADEMO Demo of the WTFA function
 
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
% Create a set of time varying spectra (e.g. LC-NIR)
% then test one of the pure analyte spectra using WTFA.
 
w = [0:0.1:50];
s = [sin(w); cos(w)*2].^2;                        %pure analyte spectra
t = [0:40]';
c = [exp(-((t-20).^2)/40) exp(-((t-25).^2)/30)];  %elution profiles
a = c*s + randn(length(t),length(w))*.01;         %outer product of elution and spectra
 
figure
plot(t,c(:,1),'r','linewidth',2), hold on
plot(t,c(:,2),'color',[0 0.5 0]), vline([6.5 33.5],'r')
text(8,0.9,'Approximate range of existence for Analyte 1 (thick red)')
xlabel('Elution Time')
 
pause
%-------------------------------------------------
% Get the options structure and set the plotting options.
 
options         = wtfa('options')
 
options.plots   = 'angle'; % this is the default
options.scale   = t;       % this is a scale to plot the target angles against
 
pause
%-------------------------------------------------
% Now call WTFA. The meaured spectra are in (a), the target
% spectra is (s(1,:)) which was used to construct (a), the
% window width is 5, and input (p) is set to 2 i.e. 2 PCs
% will be used to model each window of 5 spectra in (a).
 
[rho,angl,q,skl] = wtfa(a,s(1,:),5,2,options);
 
pause
%-------------------------------------------------
% Now compare this to the original profile for Analyte 1.
 
hold on
plot(t,c(:,1)*90,'r','linewidth',2), vline([6.5 33.5],'r')
xlabel('Elution Time')
 
% Note that the areas where WTFA has the smallest angles
% are the areas where Analyte 1 is distinctly present.
%
%End of WTFADEMO
 
echo off
