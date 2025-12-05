echo on
%DISTSLCTDEMO Demo of the DISTSLCT function
 
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
 
desgn = factdes(2,3);
desgn = scale(desgn,[1 1])
 
figure
plot(desgn(:,1),desgn(:,2),'o'), hold on
axis([-2 2 -2 2]), axis square
 
% DISTSLCT will be used to select 4 samples on the
% outside of this data set.
 
pause
%-------------------------------------------------
% Call DISTSLCT
 
isel = distslct(desgn,4)
 
plot(desgn(isel,1),desgn(isel,2),'o','markerfacecolor',[0 0 1])
a    = '  '; a = [a(ones(length(isel),1),:), int2str(isel(:))];
text(desgn(isel,1),desgn(isel,2),a)
 
% The filled circles show the samples that were selected.
 
%End of DISTSLCTDEMO
 
echo off
