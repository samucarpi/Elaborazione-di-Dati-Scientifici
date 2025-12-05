echo on
%MS_BINDEMO Demo of the MS_BIN function
 
echo off
%Copyright Eigenvector Research, Inc. 2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%WWW
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
%Often raw Mass Spec data is output in its original profile format 
%(e.g., 14.5, 14.5, 14.6,...) and one requires "unit" mass resolution 
%(e.g., 14, 15, 16,...) in order to reduce the size of the data and or
%analyze the data properly. In its default form the MS_BIN function will
%bin at unit resolution and return the data in a DataSet Object. Using
%the two optional parameters (resolution and round_off_point) the function
%can be adjusted to meet different requirements. Let's try using the
%function:
 
pause
%-------------------------------------------------
%MS data is often given in xy form with the first column containing the
%mass values and the second column containing the masses. This data would
%typically be read from file but for demonstration purposes we'll created it
%below.
 
%Create demo data.
npoints = 9;
std = 1.5;
mean = 5;
nder = 0;

x=1:npoints;
c=1/(std*sqrt(2*pi));
p=(x-mean)/std;
peak=(c*exp(-.5.*p.*p))';

mass=[.6:.1:1.4]';
data{1}=[[mass+99;(mass+102)],[peak;peak*4]];%masses 100 and 103
data{2}=[mass+101,peak*3];%masses 100 and 103

%Show first (18x2) demo data set:
data{1}

%Show second (9x2) demo data set:
data{2}

pause
%-------------------------------------------------
%We will now plot the input data which have a resolution of 0.1 mass units.
%The first data file is displayed in the top plot and the second data file
%is displayed in the bottom plot.
 
subplot(221);bar(data{1}(:,1),data{1}(:,2),0);
axis tight;set(gca,'TickDir','out');v1=axis;v1(1:2)=[98 104];axis(v1);
title('input data, resolution 0.1');
subplot(223);bar(data{2}(:,1),data{2}(:,2),0);
axis tight;set(gca,'TickDir','out');axis(v1);
shg
 
pause
%-------------------------------------------------
%We will now create:
%a) a dataset object with unit resolution.
%b) a dataset object with unit resolution where the data is rounded up/down
%   around 0.8 instead of 0.5 which causes peaks to be split.
%c) a dataset object with a resolution of 0.2 (rounded at .5).
%
%Notice that each cell in the input 'data' is considered a "sample" and the
%resulting DSOs all have 2 rows (samples).
 
options.resolution = 1; %This is the default value.
options.round_off_point = .5; %This is the default value.
dso{1}=ms_bin(data,options);
 
options.resolution = 1;
options.round_off_point = .8;
dso{2}=ms_bin(data,options);
 
options.resolution = .2;
options.round_off_point = .5;
dso{3}=ms_bin(data,options);
 
pause
%-------------------------------------------------
%Now we will now plot the results next to the original data. 
 
% **** Click on the figure to display the next plot. **** 
 
title_string{1}='RoundOff(.5)  Resolution(1)';
title_string{2}='RoundOff(.8)  Resolution(1)';
title_string{3}='RoundOff(.5)  Resolution(.2)';
 
 
for i=1:3;
  d=dso{i};
  subplot(222);bar(d.axisscale{2},d.data(1,:),0);
  axis tight;set(gca,'TickDir','out');v=axis;v(1:2)=v1(1:2);axis(v);
  title(title_string{i});
  subplot(224);bar(d.axisscale{2},d.data(2,:),0);
  axis tight;set(gca,'TickDir','out');axis(v);
  waitforbuttonpress
end;
 
%End of MS_BINDEMO
 
echo off

