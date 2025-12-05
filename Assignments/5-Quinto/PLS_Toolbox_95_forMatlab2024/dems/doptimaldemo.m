echo on
%DOPTIMALDEMO Demo of the DOPTIMAL function
 
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
% Create data:
 
desgn = factdes(2,5);
desgn = scale(desgn,[2 2])
 
figure
plot(desgn(:,1),desgn(:,2),'o'), hold on
axis([-2.5 2.5 -2.5 2.5]), axis square, hline, vline
 
% DOPTIMAL will be used to select 4 samples on the
% outside of this data set.
 
pause
%-------------------------------------------------
% Call DOPTIMAL
 
isel = doptimal(desgn,4)
 
plot(desgn(isel,1),desgn(isel,2),'o','markerfacecolor',[0 0 1])
a    = '  '; a = [a(ones(length(isel),1),:), int2str(isel(:))];
text(desgn(isel,1),desgn(isel,2),a)
 
% The filled circles show the samples that were selected.
 
%End of DOPTIMALDEMO
 
echo off
