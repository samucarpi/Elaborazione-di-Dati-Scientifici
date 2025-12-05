function out = getOptions(obj,parent,varargin)
%GETOPTIONS Return Analysis Methods Options structure.
%I/O: .getOptions

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

handles = guidata(parent.handle);
out = getappdata(handles.analysis,'analysisoptions');

