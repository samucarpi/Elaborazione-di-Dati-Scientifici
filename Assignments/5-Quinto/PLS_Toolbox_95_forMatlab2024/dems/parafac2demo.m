echo on
%PARAFAC2DEMO Demo of the PARAFAC2 function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% PARAFAC2 is capable of handling deviations from trilinearity in a 
% simple manner.
%
% We will use a chromatographic GC-MS dataset with retention time shifts 
% to illustrate what PARAFAC2 can do compared to PARAFAC. Below the part of
% the chromatogram that we are using will be shown. The peaks are
% quite small and also shifted. In fact, there are only two analytes 
% (plus baseline) in this area so a three-component model should work well.
% If there are no shifts, PARAFAC would be able to model the data, but 
% based on the plot, it is expected that PARAFAC2 will be more adequate.
%
% Note that the samples are typically held in the last mode in PARAFAC2 
% while the 'varying' mode is held in the first one
 
load gcwine 

% Press key to continue
pause

gcwine
%
% The data is measured on 24 samples of red wine with a dynamic headspace 
% GC-MS system. Only a small part of the GC mode is included here. It
% contains acetic-acid hexyl ester and 3-hydroxy-2-butanone that 
% overlap and shift in their retention time. 

% Press key to continue
pause

% Plot the TIC
figure
plot(gcwine.axisscale{1},squeeze(sum(gcwine.data,2)))
title('Chromatograms')
xlabel('Scans')
ylabel('Summed intensity')
axis tight

% Now fit both a PARAFAC and a PARAFAC2 model to these data using three 
% components and investigate the models to see which looks most appropriate

% Press key to continue
pause

% Make nonnegativity options for PARAFAC
op=parafac('options');
for i=1:3,
    op.constraints{i}.type = 'nonnegativity';
end
 
% Fit PARAFAC model
modelnn=parafac(gcwine,3,op);
 
% Make nonnegativity options for PARAFAC2 (note they are different from
% PARAFAC)
op2=parafac2('options');
for i=2:3,
    op2.constraints{i}.type = 'nonnegativity';
end
 
% Fit PARAFAC2 model
modelnn2=parafac2(gcwine,3,op2);

% Press key to continue
pause
close all

% If you want to look at the elution time loadings in PARAFAC2, they 
% have to be calculated from the model in the following way.

P = modelnn2.loads{1}.P;
H = modelnn2.loads{1}.H;
L(:,:,1)=P{1}*H; % Elution mode loadings for the first sample
L(:,:,2)=P{2}*H; % Elution mode loadings for the second sample
% etc ..

echo off

for i = 1:length(P)
    L(:,:,i)=P{i}*H;
end
echo on


% Press key to continue
pause




% To plot the loadings do the following

el=gcwine.axisscale{1}; % Extract elution time scales for convenience
mz=gcwine.axisscale{2}; % Extract mz scale for convenience
 
plot(el,L(:,:,1)),
hold on
plot(el,L(:,:,2)),
plot(el,L(:,:,3)),

echo off

for i=1:size(L,3),
    plot(el,L(:,:,i)),
end,
hold off
echo on

%
% As can be seen, the PARAFAC2 elution mode loadings seem to be able to
% handle the shifts in retention time quite nicely. And the baseline is
% also handled by one component.

% Press key to continue
pause


P = modelnn2.loads{1}.P;
H = modelnn2.loads{1}.H;
A = modelnn2.loads{3};
for i = 1:length(P)
  L(:,:,i)=P{i}*H;
  for f=1:size(A,2)
     L(:,f,i) = L(:,f,i)*A(i,f);
  end
  echo off
end
echo on
 
% Plot the elution mode loadings scaled by the score 
%
% for i=1:size(L,3),
%    plot(el,L(:,:,i)),
%    hold on,
% end,


echo off
for i=1:size(L,3),
    plot(el,L(:,:,i)),
    hold on,
end,
hold off
echo on

%
% Notice that some of the loadings look at little noisy. But there is a 
% good reason for that which is important to know when you interpret 
% PARAFAC2 models. Imagine that one sample does not contain one particular 
% analyte. In PARAFAC2, the loadings (elution profiles in this case) are 
% estimated for each sample separately, so even the absent analyte would 
% have a loading associated with it. Clearly, this profile can look very 
% peculiar but in the final model, the profile is multiplied with the 
% corresponding sample score (the concentration). And the concentration 
% of an absent analyte will be approximately zero, so the actual 
% contribution will be negligible.
%
% For this reason, it is sometimes better to look at the loadings after 
% multiplication with the scores:



% Press key to continue
pause


% Calculate models for three component models
[mnn] = datahat(modelnn);
[mnn2] = datahat(modelnn2);

% Plot the TIC
subplot(2,1,1)
plot(el,squeeze(sum(gcwine.data,2)),'b','linewidth',2)
hold on
plot(el,squeeze(sum(mnn,2)),'r','linewidth',2)
title('Blue: raw data; red: PARAFAC estimates','fontweight','bold')
hold off
xlabel('Scans')
ylabel('Summed intensity')
 
subplot(2,1,2)
plot(el,squeeze(sum(gcwine.data,2)),'b','linewidth',2)
hold on
plot(el,squeeze(sum(mnn2,2)),'r','linewidth',2)
title('Blue: raw data; red: PARAFAC2 estimates','fontweight','bold')
hold off
xlabel('Scans')
ylabel('Summed intensity')


% Let us also try to see which of the two models actually describe the 
% whole dataset best. We use the function datahat to get the model 
% estimate of the data. As can be seen from the plot, PARAFAC2 does a much
% better job at modelling the data than PARAFAC does. 



% Press key to continue
pause
 
%End of PARAFAC2DEMO
 
 
echo off
