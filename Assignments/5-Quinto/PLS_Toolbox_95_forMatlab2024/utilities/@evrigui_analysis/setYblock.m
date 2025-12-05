function out = setYblock(obj,parent,varargin)
%SETYBLOCK Loads data as calibration Y block.
%I/O: .setYblock(data)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

handles = guidata(parent.handle);
analysis('loaddata_callback',handles.analysis, [], handles, 'yblock',varargin{:})

out = true;
