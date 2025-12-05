function out = clearXblock(obj,parent,varargin)
%CLEARXBLOCK Clears current calibration X block data.
%I/O: .clearXblock

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

handles = guidata(parent.handle);
analysis('cleardata_callback',handles.analysis, [], handles, 'x')
out = true;
