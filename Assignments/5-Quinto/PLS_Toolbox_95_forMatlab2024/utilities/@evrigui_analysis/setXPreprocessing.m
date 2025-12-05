function out = setXPreprocessing(obj,parent,varargin)
%SETXPREPROCESSING Load X block preprocessing.
%I/O: .setXPreprocessing(preprocessing)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

pp = preprocess('validate',varargin{1});
handles = guidata(parent.handle);
analysis('loadpreprocessing',handles.analysis, [], handles, 'x', pp)
out = true;
