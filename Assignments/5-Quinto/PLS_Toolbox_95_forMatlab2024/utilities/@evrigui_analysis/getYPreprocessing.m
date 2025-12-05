function out = getYPreprocessing(obj,parent,varargin)
%GETYPREPROCESSING Return Y block preprocessing.
%I/O: .getYPreprocessing

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

handles = guidata(parent.handle);
out = getappdata(handles.preproyblkmain,'preprocessing');
