function [] = peakcompare()
%PEAKCOMPARE Makes plots of different peak shapes
%
%I/O: peakcompare
%
%See also: PEAKFUNCTION, ,PEAKGAUSSIAN, PEAKLORENTZIAN, PEAKPVOIGT1, PEAKPVOIGT2

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

ax = 0:0.1:100;
plot(ax,peakgaussian([2 51 8],ax),'-b', ...
     ax,peaklorentzian([2 51 8],ax),'--k', ...
     ax,peakpvoigt1([2 51 8 0.5],ax),':g', ...
     ax,peakpvoigt2([2 51 8 0.5],ax),'-.r')
legend('Gaussian','Lorentzian','PVoigt1','PVoigt2')
xlabel('Independent Axis')
ylabel('Peak Function')
vline(51)
