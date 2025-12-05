function out = getPrediction(obj,parent,varargin)
%GETPREDICTION Returns current validation prediction.
%I/O: .getPrediction

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

handles = guidata(parent.handle);
out = analysis('getobjdata','prediction', handles);
