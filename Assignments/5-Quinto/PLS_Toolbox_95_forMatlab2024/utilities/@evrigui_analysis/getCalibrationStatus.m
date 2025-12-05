function out = getCalibrationStatus(obj,parent,varargin)
%GETCALIBRATIONSTATUS Returns current calibration status (calold,calnew,...).
%I/O: .getCalibrationStatus

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

handles = guidata(parent.handle);
out     = getappdata(handles.analysis,'statmodl');
