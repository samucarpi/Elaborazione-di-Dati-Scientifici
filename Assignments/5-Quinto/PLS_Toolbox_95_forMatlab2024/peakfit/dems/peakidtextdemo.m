echo on
%PEAKIDTEXTDEMO Demo of the PEAKIDTEXT function
 
echo off
%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
peaksdemos
echo on
 
%Note that the initial guesses can also be labeled
 
pause
%-------------------------------------------------
axis([0 100 0 4])
peakidtext(peakdef)
axis([0 100 0 4.5])
 
%End of PEAKIDTEXTDEMO
%
%See also: FITPEAKS, and PEAKFUNCTION, PEAKIDTEXT, PEAKSTRUCT
 
echo off
