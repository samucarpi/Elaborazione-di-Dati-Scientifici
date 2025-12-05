echo on
%STDSSLCTDEMO Demo of theSTDSSLCT function
 
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
 
desgn = factdes(3,3);
desgn = scale(desgn,ones(1,3));
 
figure
plot3(desgn(:,1),desgn(:,2),desgn(:,3),'o'), grid, hold on
axis([-2.5 2.5 -2.5 2.5]), axis square, hline, vline, zline
 
% STDSLCT will be used to select 3 samples on the
% outside of this data set.
 
pause
%-------------------------------------------------
% Call STDSSLCT
 
[specsub,isel] = stdsslct(desgn,3);
 
plot3(desgn(isel,1),desgn(isel,2),desgn(isel,3),'o','markerfacecolor',[0 0 1])
a    = '  '; a = [a(ones(length(isel),1),:), int2str(isel(:))];
text(desgn(isel,1),desgn(isel,2),desgn(isel,3),a)
 
% The filled circles show the samples that were selected.
% Note that these 3 samples (imagine vectors drawn from 0,0,0
% to each of the samples) span the space.
 
% The STDSCLCT is often used to select samples to use in
% instrument standardization (a.k.a. calibration transfer).
% Please see STDDEMO.
 
%End of STDSSLCTDEMO
%
%See also: STDDEMO
 
echo off
