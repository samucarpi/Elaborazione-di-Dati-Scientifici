echo on
%ALSDEMO Demo of the ALS function
 
echo off
%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% Create synthetic data to test the ALS algorithm:
 
w = [0:0.1:2*pi];
s = [sin(w-pi/4).^4; 2*(cos(w)).^4];              %pure analyte spectra
s(1,1:10)   = 0; %ensuring some selectivity between the spectra
s(2,46:end) = 0; 
t = [0:40]';
c = [exp(-((t-20).^2)/40) exp(-((t-25).^2)/30)];  %elution profiles
a = c*s + randn(length(t),length(w))*.01;         %outer product of elution and spectra
 
% Note that (a) has two factors with a little bit of noise.
% We'll decompse this matrix, but first let's plot it to see
% what we're hoping to extract.
 
pause
%-------------------------------------------------
figure
subplot(2,1,1), plot(t,c),      axis([0 40 0 1.1])
xlabel('Time (t)'), ylabel('C')
subplot(2,1,2), plot(w,s),      axis([0 6.5 0 4.1])
xlabel('Channel'),  ylabel('S')
 
pause
%-------------------------------------------------
figure
mesh(w,t,a),    axis([0 6.5 0 50 0 4]), title('Measured LC-NIR Matrix')
 
% Next, try a ALS model of matrix (a).
 
pause
%-------------------------------------------------
% Get the options structure and make a 2 factor ALS model.
% For this example we'll keep the defaults 
% 1) we'll apply non-negativity to both c and s, and
% 2) we'll change the number of iterations to 10.
 
options         = als('options');
options.ccon    = 'nonneg';
options.scon    = 'nonneg';
options.ittol   = 20;
 
pause
%-------------------------------------------------
% But first we need an estimate of the initial concentration
% profiles c0. Here we'll use the EWFA function, and show one
% example of how to get the initial guess for c0. Often, the
% tedious part of ALS is obtaining c0.
 
pause
%-------------------------------------------------
% The output from EWFA is not on the same axis as the original
% data, so we'll also call INTERP1. EWFA is called with a window
% of 4 and the plots are turned on. See EWFADEMO.
 
 [eigs,skl] = ewfa(a,4,1,t);          %perform EWFA
 
% This suggests that the range of existence for both is ~ 11<t<32.
% Assuming that the first analyte to appear is the first to leave
% suggests that the first analyte is present in the range ~ 5<t<32
% and that the second is present in the range ~11<t<39; So, ...
 
pause
%-------------------------------------------------
% the initial concentration estimate is (2 columns indicates we're
% creating a 2 factor model)
 
c0   = zeros(length(t),2);  %initialize the c0 matrix
c0(5:32,1)  = 1;            %range of existence for Analyte 1
c0(11:39,2) = 1;            %range of existence for Analyte 2
 
figure, plot(t,c0,'linewidth',2), axis([0 50 0 1.1])
xlabel('Time (t)'), ylabel('C_0')
 
% You can compare this plot to the original data and the EWFA results.
 
% Now, we can call the ALS function and compare it's results to the
% original data.
 
pause
%-------------------------------------------------
[ce,se] = als(a,c0,options);
 
pause
%-------------------------------------------------
% Note that since no non-zero equality constraints were applied
% that the spectra have been normalized to unit length. To compare
% to the original spectra we'll normalize the original spectra.
 
figure,  plot(w,normaliz(s)), ylabel('S')
hold on, plot(w,se,'r'), hold off
 
% This might be "close", but I bet we can do better.
 
% Another useful diagnostic examines the projection angle between
% both the known and estimated factors simultaneously.
 
for ii=1:2
  tmpvar = c(:,ii)*s(ii,:);   cs(:,ii)  = tmpvar(:);
  tmpvar = ce(:,ii)*se(ii,:); cse(:,ii) = tmpvar(:);
end
tmpvar = normaliz(cs')*normaliz(cse')';
tmpvar = acos(diag(tmpvar))*180/pi
 
% Here (tmpvar) is the angle in degrees between the known
% factors (cs) and and the estimated factors (cse).
 
pause
%-------------------------------------------------
% We'll add equality constraints for both analytes for the
% concentrations profiles by setting options.cc.
 
options.cc = c0*NaN;       % sets up a matrix of NaN
options.cc(36:end,1) = 0;  % this is where Analyte 1 is known absent
options.cc(1:11,2)   = 0;  % this is where Analyte 2 is known absent
 
% and for the spectra using options.sc
options.sc = se*NaN;       % sets up a matrix of NaN
options.sc(1,1:8)    = 0;
options.sc(2,48:end) = 0;
 
pause
%-------------------------------------------------
% Now call ALS again and compare the results.
 
[ce,se] = als(a,c0,options);
 
pause
%-------------------------------------------------
figure,  plot(w,normaliz(s),'linewidth',2), ylabel('S')
hold on, plot(w,se,'r'), hold off
 
% The estimates are in red.
 
% Again examine the angle between the factors.
 
for ii=1:2
  tmpvar = c(:,ii)*s(ii,:);   cs(:,ii)  = tmpvar(:);
  tmpvar = ce(:,ii)*se(ii,:); cse(:,ii) = tmpvar(:);
end
tmpvar = normaliz(cs')*normaliz(cse')';
tmpvar = acos(diag(tmpvar))*180/pi
 
% Addition of equality (selectivity) constraints should make
% the angles closer to 0.
 
%End of ALSDEMO
 
echo off
