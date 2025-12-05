
echo on
% ALS_SITDEMO Demo of the ALS_SIT function
 
echo off
% Copyright © Eigenvector Research, Inc. 2023
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
 
% Load GC Wine data
load('gcwine.mat')
m       = size(gcwine); %'Mode 1 is elution time  - shifting mode 71 time points
                        %'Mode 2 is m/z fragments - 199 mass channels
                        %'Mode 3 is sample        - 72 samples
ncomp   = 5;            %Number of Factors to fit
 
% Set options for ALS_SIT, run the model and plot the results
optssit = als_sit('options');
optssit.plots           = 'none';
optssit.ittol           = 2e-4;
%  optssit.sitconstraint = []; %uses shift invariant tri-linarity on all factors
optssit.sitconstraint = [0 0 2 2 2]; %relaxes SIT on Factors 1 and 2
% optssit.sitconstraint = [0 0 1 1 2]; %forces trilinearity on Factors 3 nd 4
% optssit.shiftmap.ncomp  = [NaN NaN 1 1 2];  % use more components if shape changes
optssit.shiftmap.ncomp  = [NaN NaN 1 1 0.95]; % use more components if shape changes

% Factor 1 and 2 do not employ tri-linearity constraints (they are baselines)
% but Factors 3, 4 and 5 do not tri-linearity constraints.
% Factors 3 and 4 are constrained using SIT and
% Factor 5 is softly constrained using SIST.
 
% Next, call ALS_SIT and plot results ...
pause
 
tic
modsit  = als_sit(gcwine,ncomp,optssit); toc
 
% Plot (Factors 1 & 2 are background, Factors 3-5 are Chemical Analytes)
 
plotloads(modsit,struct('mode',1)) %These are elution profiles
plotloads(modsit)                  %These are the mass spectra
plotscores(modsit)


if false %true % test sits
  for i1=3:5
    figure("Name",['C Factor ',int2str(i1)])
    plot(reshape(tsit.data(:,i1),[71 72]));
    vv = axis; axis([0 71 vv(3:4)])
    xlabel('Elution Profile')
    title(get(gcf,"Name"))
  end

  disp('Plotting Additional Results w/ Power Spectra')
  ij      = 3;
  [z,r,a,xsit,xsits] = shiftmap(reshape(modsit.loads{1}(:,ij),[m(1) m(3)]));
  [~,~,p,t] = pcaengine(r',1,struct('display','off'));
  [~,i1]  = min(sum((r-p*t').^2)); %residuals
  csits   = real( ifft(spdiag(cos(a(:,i1)) + 1i*sin(a(:,i1)))*r) );
  figure('Name',['SITS Map for Factor ',int2str(ij)])
  subplot(2,1,1)
  plot(xsits)
  vv      = axis; axis([0.5 71.5 0 vv(4)])
  title('\itF\rm^{ -1}(\bfr\rm_1 .* \bfa\rm)','Interpreter','tex')
  subplot(2,1,2)
  plot(csits(1:m(1),:))
  axis([.5 71.5 0 vv(4)])
  title('\itF\rm^{ -1}(\bfr\rm .* (\bf1\rma_0))','Interpreter','tex')
  xlabel('Elution Time')

  figure('Name',['SIT FFT for Factor ',int2str(ij)])
  subplot(2,1,1)
  plot(r)
  vv      = axis; axis([0.5 64.5 0 vv(4)])
  title('\bfr\rm')
  subplot(2,1,2)
  plot(a(1:m(1),1:4))
  axis([0.5 64.5 -3.2 3.2])
  uistack(hline(0,'k'),'bottom')
  title('\bfa\rm (Samples 1 to 4)')
  xlabel('Frequency')
  clear vv
end
 
echo on
 
% ALS_SIT for GCWine.

 
%End of ALS_SITDEMO
 
echo off

if false %hard switch used for testing
  pred    = als_sit(gcwine,modsit);
  tsitp   = dataset(pred.loads{1});
  tsitp.label{2} = int2str((1:ncomp)');
  figure('Name','Elution Profiles')
  plotgui([tsit,tsitp],'plotby',2)
  rmse(tsit.data(:,1:5),tsitp.data(:,1:5))
end