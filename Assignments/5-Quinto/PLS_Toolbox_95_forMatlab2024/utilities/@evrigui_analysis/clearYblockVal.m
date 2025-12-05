function out = clearYblockVal(obj,parent,varargin)
%CLEARYBLOCK Clear the validation Y block data.
%I/O: .clearYblockVal

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

handles = guidata(parent.handle);
analysis('cleardata_callback',handles.analysis, [], handles, 'y_val')
out = true;
