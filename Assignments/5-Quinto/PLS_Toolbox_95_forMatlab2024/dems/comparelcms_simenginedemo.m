 
%Copyright (c) Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
echo on
%The function comparelcms_simengine determines which corresponding variables from
%several data sets are different. 
%The data used consists of 3 LC/MS data sets of highly related samples.
%The data sets are combined into a 3d array with the size 
%nsamples*nspectra*nvariables.
%The data will be plotted in its original form and the reduced form,
%which is obtained by only plotting variables with a similarity index of
%less than 0.57. In order to minimize the effects of small retention time
%shifts the data are smoothed with a reactangular window of 7 scans. Due
%the size of the file the calculations will take some time.
pause
%-------------------------------------------------
%load lcms_compare_combined
%[nslabs,nrows,ncols]=size(lcms_compare_combined.data);
load lcms_compare1;
load lcms_compare2;
load lcms_compare3;
lcms_compare_combined.data(1,:,:)=lcms_compare1.data;
lcms_compare_combined.data(2,:,:)=lcms_compare2.data;
lcms_compare_combined.data(3,:,:)=lcms_compare3.data;
 
subplot(3,2,1);plot(lcms_compare1.data);
title('original data');
subplot(3,2,3);plot(lcms_compare2.data);
subplot(3,2,5);plot(lcms_compare3.data);
 
y=comparelcms_simengine(lcms_compare_combined.data,7);
subplot(3,2,2);plot(lcms_compare1.data(:,y<.57));v=axis;v(4)=15;axis(v);
title('reduced data');
subplot(3,2,4);plot(lcms_compare2.data(:,y<.57));v=axis;v(4)=15;axis(v);
subplot(3,2,6);plot(lcms_compare3.data(:,y<.57));v=axis;v(4)=15;axis(v);
shg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%The reduced data clearly shows differences which could not be seen easily
%in the original data set. There are a lot of noisy variables in the data
%set. Normally the data are first reduced by the function CODA_DW, which is
%done in the function COMPARELCMS_SIM_INTERACTVE. Since data sets may not
%have the same variables and scans, care has to be taken that the different data
%sets, such as the 3 data sets in this demo, are lined up properly. The function 
%COMPARELCMS_SIM_INTERACTVE takes care of this.
echo off;
