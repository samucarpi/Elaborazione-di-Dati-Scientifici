echo on
%FINDINDXDEMO Demo of the FINDINDX
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%ww 06/11/04 Initial coding.
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%FINDINDX finds the index of the array element closest to a value r.
%As an example of an application we will plot a Raman data set.
%The goal of this demo is to define a wavenumber and plot the intensities,
%for which we need the FINDINDX function
%After hitting return a plot will appear. Click the mouse at a certain
%cursor position to define the wavenumber intensities you want to plot.
pause
%-------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
load raman_time_resolved
figure
subplot(211);plot(raman_time_resolved.axisscale{2},raman_time_resolved.data);
title('select x-position with mouse cursor');
 
[wavenumber2plot,dummy]=ginput(1); 
 
%The value defined by the cursor position is:
disp(wavenumber2plot);
%If we want to plot the intensities at that wavenumber we need to now the
%index of that variable in data.axisscale{2}. We can try the matlab
%function FIND as follows:
find(raman_time_resolved.axisscale{2}==wavenumber2plot)
pause
%-------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%The result is most likely empty, since it is not likely that the cursor is
%exactly at a certain wavenumber. So in this case we can not use the FIND
%command. For this reason the FINDINDX function was developed. It will
%find the index of the wavenumber in raman_time_resolved.axisscale{2} closest to the
%cursor position.
index=findindx(raman_time_resolved.axisscale{2},wavenumber2plot);
%This index corresponds to the following wavenumber on
%raman_time_resolved.exisscale{2}:
disp(raman_time_resolved.axisscale{2}(index))
%which is close to, but not identical, to the wavenumber defined by the
%cursor:
disp(wavenumber2plot);
%Now we have all the information we need to plot the wavenumber
%intensities. We will indicate the wavenumber position in the spectral plot
%with the function vline
pause
%-------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vline(raman_time_resolved.axisscale{2}(index),'k');
subplot(212);plot(raman_time_resolved.axisscale{1},raman_time_resolved.data(:,index));
title(['wavenumber: ',num2str(raman_time_resolved.axisscale{2}(index))]);
 
%It is possible to give an array of points for which the array index needs
%to be determined. For example, one could determine a series of points with
%a cursor to define a baseline and use FINDINDX to determine the proper
%indices.
pause
