echo on
% PEAK2DEMO Demo of BASELINEW, PEAKFIND, and FITPEAKS functions
 
echo off
% Copyright © Eigenvector Research, Inc. 2006
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.
%NBG
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The objective of this exercise is to find and fit a series of
% peaks in a set of elutions. The peaks are considered one dimensional
% even though the data are two dimensional.
 
% Note that the demo does not echo most of the code to the
% command window because of FOR loops. To see the code:
% >> edit peak2demo
pause 

% First create some synthetic data, add a baseline, and
% a little bit of noise.
 
echo off
m  = 20;    n = 100;
x  = 1:n;
y  = [1:m]';
z  = zeros(m,n);
c  = exp(-y/8); c = [c, 1.2-1.2*c];
for i1=1:20
  z(i1,:) = c(i1,1)*normaliz(normdf('density',x,41,10),0,1) + ...
            c(i1,2)*normaliz(normdf('density',x,61,8),0,1) + ...
            (y(i1)/1e4)*auto(x')' + 0.2;
end
z  = z + randn(m,n)*0.0005;
h1 = figure; plot(x,z), hline(mean(z(:,1)))
pause, echo on
 
% Next, estimate the noise in the spectra
y_a = savgol(z,7,2,0);               %Smooth the data
res = sqrt(mean(mean((z-y_a).^2)));  %Noise is ~ measured-smoothed
 
% Noise added was 0.0005 and the estiamted noise is
disp(res)
 
pause
 
% The baseline is removed using the estimated noise level
 
[y_b,b_b]= baselinew(z,[],[],1,res);
plot(x,y_b), hline, shg
pause
 
% First attempt at finding peak location in each trace
 
w    = 11; %Expected minimum distance between peaks
i0   = peakfind(y_b,21,2,w); echo off
for i1=1:m
  vline(x(i0{i1}),'r')
end, shg, echo on
pause
 
% What these figures show is that the smaller peak is not
% found when it's small or on the shoulder of a larger peak.
%
% However, knowledge of the 2-D nature of the data clearly
% indicates the presence of both peaks in more of the traces
% than our first attempt would suggest.
 
surfl(x,y,z), colormap bone, axis tight, shading interp, echo off
%waterfall(x,y,z)
for i1=1:m
  zline(x(i0{i1}),y(i1)*ones(length(i0{i1}),1),'r')
end, shg, echo on
pause
 
% In a second attempt, the tolerance is increased and peak
% locations from all the traces will be used to identify
% peak locations.
 
i0   = peakfind(y_b,21,4,w);
 
% Identify the unique locations
 
j0 = zeros(1,n);
for i1=1:length(i0), echo off
  j0(i0{i1}) = j0(i0{i1})+1;
end, echo on
j0 = savgol(j0,w+(w+1)/2,2,0); %filter to create maximums in the middle of plateaus
j0 = localmaxima(j0,w);
j0 = j0{1};
figure, plot(x,y_b), hline, vline(j0,'r')
pause
  
% Next the peak definitions structure (see PEAKSTRUCT) is
% defined and initialized. The result is then used to fit
% the peaks using FITPEAKS, and these results are plotted.
echo off
 
peakdef   = cell(m,1);
peakdefo  = cell(m,1);
y_bo      = zeros(m,n);
y_bp      = cell(1,length(j0));
for i1=1:length(j0)
  y_bp{i1} = zeros(m,n);
end
hwait     = waitbar(0,'Initializing and fitting peaks');
for i1=1:m
  peakdef{i1} = peakstruct('Gaussian',length(j0));
  for i2=1:length(j0)
    peakdef{i1}(i2).id = ['Trace ',int2str(i1),', Peak ',int2str(i2)];
    peakdef{i1}(i2).param(1) = max(y_b(i1,j0(i2)))*0.8;
    peakdef{i1}(i2).ub(1)    = max(y_b(i1,j0(i2)-(w-1)/2:j0(i2)+(w-1)/2));
    peakdef{i1}(i2).param(2) = x(j0(i2));
    peakdef{i1}(i2).lb(2)    = x(j0(i2))-w/4;
    peakdef{i1}(i2).ub(2)    = x(j0(i2))+w/4;
    %if i1==1
      peakdef{i1}(i2).param(3) = 5;
    %else
     % peakdef{i1}(i2).param(3) = peakdef{i1-1}(i2).param(3)*0.8;
    %end
    peakdef{i1}(i2).lb(3)    = 0.0001;
    peakdef{i1}(i2).ub(3)    = 40;
  end
  [peakdefo{i1},fval,extflg,out,y_bo(i1,:)] = fitpeaks(peakdef{i1},y_b(i1,:),x);
  waitbar(i1/m,hwait)
end
for i1=1:length(j0)
  for i2=1:m
    y_bp{i1}(i2,:) = peakfunction(peakdef{i2}(i1),x);
  end
end, close(hwait), clear hwait i1 i2

h1 = figure; surfl(x,y,y_b), colormap bone, axis tight, shading interp
title('Original Baselined Data')
i2 = get(h1,'position');
h2 = figure('position',[i2(1:2)-10, i2(3:4)]);
surfl(x,y,y_bo), colormap bone, axis tight, shading interp
title('Fit Data')
pause
for i1=1:length(j0)
  i2 = get(h2,'position');
  h2 = figure('position',[i2(1:2)-10, i2(3:4)]);
  surfl(x,y,y_bp{i1}), colormap bone, axis tight, shading interp
  title(['Peak ',int2str(i1)])
end
echo on
%End of PEAK2DEMO
 
echo off
