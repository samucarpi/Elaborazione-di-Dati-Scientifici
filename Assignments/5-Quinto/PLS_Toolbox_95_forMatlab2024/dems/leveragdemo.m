echo on
%LEVERAGDEMO Demo of the LEVERAG function
 
echo off
%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
%To run the demo hit a "return" after each pause
pause
%-------------------------------------------------
% The LEVERAG function is used to estimate sample
% leverages. This is an important diagnostic tool
% in regression and PCA.
 
% Leverage is an estimate of the distance of a sample
% from the centroid of a data set. When applied to scores
% from PCA T, it is directly related to the Hotelling T^2
% statistic. The leverage for the ith row of T is given as
%    lev(i,1) = T(i,:)*inv(T'*T)*T(i,:)'          (1)
% and the Hotelling T^2 is
%    tsq(i,1) = T(i,:)*inv((T'*T)/(m-1))*T(i,:)'   (2)
% where (m) is the number of samples. In this case they
% only differ by a scale of (m-1).
 
% It should be mentioned that the leverage usually has
% an offset term associated with the mean of the Y-block
% when used in regression. This term is a constant and
% is ignored in LEVERAG which focusses on the salient
% information.
 
% The LEVERAG function is used in the DOPTIMAL function.
 
pause
%-------------------------------------------------
% In this demo we need to first create some data:
 
x = factdes(2,5);
x = scale(x,[2 2])
 
figure
plot(x(:,1),x(:,2),'o'), hold on
axis([-2.5 2.5 -2.5 2.5]), axis square, hline, vline
 
% Next we'll estimate the sample leverages and list
% them on the plot.
 
pause
%-------------------------------------------------
% Call LEVERAG
 
lev  = leverag(x);
 
a = ' '; a = [a(ones(size(x,1),1),:), num2str(lev)];
text(x(:,1),x(:,2),a)
echo off
colr = [lev/max(lev) zeros(length(lev),1) 1-lev/max(lev)];
for ii=1:length(lev)
  plot(x(ii,1),x(ii,2),'o','markerfacecolor',colr(ii,:))
end, echo on
 
% The text lists the sample leverage and shows that
% samples on the exterior of the data space have the
% highest leverages.
 
%End of LEVERAGDEMO
 
echo off
