function out = getCrossvalidation(obj,parent,varargin)
%GETCROSSVALIDATION Get Analysis Cross-Validation settings.
%I/O: .getCrossvalidation

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

handles = guidata(parent.handle);
[cvmode,cvlv,cvsplit,cviter,cvi] = crossvalgui('getsettings',getappdata(handles.analysis,'crossvalgui'));
out = cvi;
