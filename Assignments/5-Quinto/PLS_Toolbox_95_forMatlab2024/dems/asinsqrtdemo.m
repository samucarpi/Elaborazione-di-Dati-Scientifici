echo on
% ASINSQRTDEMO Demo of the ASINSQRT function
 
echo off
% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The ASINSQRT function is used to transform data matrices (x) typcially
% consisting of proportions such that 0<=x<1, using the
% arcsin(sqrt(x)) transform.
 
load arch
 
% Scale the data to the global maximum, and column and row maxima so that
% the scaled data are 0<=x<1:
 
x_global  = arch.data/max(arch.data,[],"all");     %Class double
x_colmax  = scale(arch,zeros(1,size(arch,2)),max(arch.data)); %Class DataSet
 
% Next, run ASINSQRT and plot the results versus the original (x).
 
pause
 
x_global  = asinsqrt(x_global);
x_colmax  = asinsqrt(x_colmax);
 
figure('Name','arcsin(sqrt(x)) A');
subplot(2,1,1)
plot(arch.data(:),x_global(:),'o')
ylabel('arcsin(sqrt(x))')
title('X scaled to global maximum')

subplot(2,1,2)
plot(arch.data,x_colmax.data,'o')
ylabel('arcsin(sqrt(x))')
title('X scaled to column maxima')
xlabel('Original Measurement (ppm)')
 
% Next, plot columns of x_rowmax
 
pause
 
figure('Name','arcsin(sqrt(x)) B');
plotgui(x_colmax,'plotby',2)
ylabel('arcsin(sqrt(x))')
title('X scaled to row maxima')
xlabel('Original Measurement (ppm)')
 
% It is interesting to perform PCA on x_colmax and compare the results
% to autoscaling.
 
%End of ASINSQRTDEMO
 
% See also: ASINHX, AUTO, MNCN
 
echo off
