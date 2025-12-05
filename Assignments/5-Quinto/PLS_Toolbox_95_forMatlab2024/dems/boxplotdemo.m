echo on
% BOXPLOTDEMO Demo of the BOXPLOT function
 
echo off
% Copyright © Eigenvector Research, Inc. 2009
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%nbg 8/09
 
echo on
 
% To run the demo hit a "return" after each pause
pause
 
%-------------------------------------------------
% The BOXPLOT function is used to visualize data matrices.
 
x = randn(100,5);
s = boxplot(x);
 
%  The horizontal line inside the box is the median.
%  The dot inside the box is the mean.
%  The top and bottom of the box are the 25th and 75th percentiles
%  Q(0.25) and Q(0.75) with IQR = Q(0.75)-Q(0.25).
%  The whiskers extend to the most extreme data points not considered 
%  outliers [i.e. Sh = the highest point < Q(0.75)+qrtlim*IQR and
%  Sl = the lowest point > Q(0.25)-qrtlim*IQR, where option qrtlim=1.5 by 
%  default].
 
pause
 
x(1,:)     = s(1,:)-2.5*(s(4,:)-s(2,:));
x(2,:)     = s(1,:)-1.6*(s(4,:)-s(2,:));
x(end-1,:) = s(5,:)+1.6*(s(4,:)-s(2,:));
x(end,:)   = s(5,:)+2.5*(s(4,:)-s(2,:));
s = boxplot(x);
 
%  Outliers > Q(0.75)+qrtlim*IQR and <= Q(0.75)+qrtlimx*IQR are
%  plotted with an open circle, where option qrtlimx=3.0 by default.
%  Outliers > Q(0.75)+qrtlimx*IQR are plotted with a closed circle.
%  Outliers <= Q(0.25)-qrtlim*IQR and > Q(0.25)-qrtlimx*IQR are
%  plotted with an open circle.
%  Outliers <= Q(0.25)-qrtlimx*IQR are plotted with a closed circle.
 
pause
  
load arch
boxplot(arch)
 
%End of BOXPLOTDEMO
 
echo off
