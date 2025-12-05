function out = setYPreprocessing(obj,parent,varargin)
%SETYPREPROCESSING Load Y block preprocessing.
%I/O: .setYPreprocessing(preprocessing)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

pp = preprocess('validate',varargin{1});
handles = guidata(parent.handle);
analysis('loadpreprocessing',handles.analysis, [], handles, 'y', pp)
out = true;
