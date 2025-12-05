echo on
%PEAKPVOIGT1DEMO Demo of the PEAKPVOIGT1 function
 
echo off
%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
% This demo calls the PEAKPVOIGT1 function and compares it.
% to other peak functions. See PEAKFUNCTION that calls these
% functions and is itself called by FITPEAKS.
 
pause
%-------------------------------------------------
%plot(ax,peakpvoigt1([2 51 8],ax),':g') gives a
% Pseudo-Voigt 1 peak.
peakcompare  %plots several peak shapes for comparison.
 
%End of PEAKPVOIGT1 Demo
%
%See also: PEAKFUNCTION, PEAKGAUSSIAN, PEAKLORENTZIAN, PEAKPVOIGT2
 
echo off
