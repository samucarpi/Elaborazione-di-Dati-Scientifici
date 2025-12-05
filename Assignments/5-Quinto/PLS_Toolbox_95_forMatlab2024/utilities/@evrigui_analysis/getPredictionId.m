function out = getPredictionId(obj,parent,varargin)
%GETPREDICTIONID Returns shared data ID of current validation prediction.
%I/O: .getPredictionId

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

handles = guidata(parent.handle);
out = analysis('getobj','prediction', handles);
