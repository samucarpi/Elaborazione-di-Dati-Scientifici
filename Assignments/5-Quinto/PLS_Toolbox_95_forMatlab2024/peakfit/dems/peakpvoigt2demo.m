echo on
%PEAKPVOIGT2DEMO Demo of the PEAKPVOIGT2 function
 
echo off
%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
 
echo on
 
% This demo calls the PEAKPVOIGT2 function and compares it.
% to other peak functions. See PEAKFUNCTION that calls these
% functions and is itself called by FITPEAKS.
 
pause
%-------------------------------------------------
%plot(ax,peakpvoigt2([2 51 8],ax),'-.r') gives a
% Pseudo-Voigt 2 peak.
peakcompare  %plots several peak shapes for comparison.
 
%End of PEAKPVOIGT2 Demo
%
%See also: PEAKFUNCTION, PEAKGAUSSIAN, PEAKLORENTZIAN, PEAKPVOIGT1
 
echo off
