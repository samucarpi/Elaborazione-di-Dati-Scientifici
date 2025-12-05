echo on
% ASINHXDEMO Demo of the ASINHX function
 
echo off
% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
 
echo on
 
% To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The ASINHX function is used to transform data matrices (x) using the
% arcsinh(x) transform.
 
load StandardWireTest
 
% Center and transform the data using ASINHX:
 
ax        = asinhx(mncn(data));     %Class DataSet
 
% Next, plot the results versus the original (data).
 
pause
 
figure('Name','arcsinh(x) of StandardWireTest');
plot(data.data(:, 26),ax.data(:, 26),'o'), hold on
plot(data.data(:, 93),ax.data(:, 93),'d')
plot(data.data(:,640),ax.data(:,640),'s'), hline
ylabel('arcsinh(x)')
xlabel('Original Measurement (kev)')
legend('0.26 keV','0.93 kev','6.4 kev','Location','southeast')
title('asinhx(mncn(data))')
 
% Next, run PCA on the transformed data
 
pause
 
model   = pca(ax,4);
 
% It is interesting to compare these results to PCA using Poisson scaling.
 
%End of ASINHXDEMO
 
% See also: ASINSQRT, AUTO, MNCN, POISSONSCALE
 
echo off
