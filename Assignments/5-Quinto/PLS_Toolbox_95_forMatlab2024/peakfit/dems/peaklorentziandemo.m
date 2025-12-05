echo on
%PEAKLORENTZIANDEMO Demo of the PEAKLORENTZIAN function
 
echo off
%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
% This demo calls the PEAKLORENTZIAN function and compares it.
% to other peak functions. See PEAKFUNCTION that calls these
% functions and is itself called by FITPEAKS.
 
pause
%-------------------------------------------------
%plot(ax,peaklorentzian([2 51 8],ax),'--k') gives a
% Lorentzian peak.
peakcompare  %plots several peak shapes for comparison.
 
%End of PEAKLORENTZIAN Demo
%
%See also: PEAKFUNCTION, PEAKGAUSSIAN, PEAKPVOIGT1, PEAKPVOIGT2
 
echo off
