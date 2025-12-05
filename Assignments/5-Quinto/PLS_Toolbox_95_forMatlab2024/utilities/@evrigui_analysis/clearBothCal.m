function out = clearBothCal(obj,parent,varargin)
%CLEARBOTHCAL Clear both X and Y calibration data.
%I/O: .clearBothCal

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

handles = guidata(parent.handle);
analysis('clearboth',handles.analysis, [], handles, 'cal')

out = true;
