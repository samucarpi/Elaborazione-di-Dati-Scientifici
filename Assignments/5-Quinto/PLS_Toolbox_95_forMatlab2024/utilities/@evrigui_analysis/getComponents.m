function out = getComponents(obj,parent,varargin)
%GETCOMPONENTS Returns current selection for model components.
%I/O: .getComponents

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

handles = guidata(parent.handle);
out     = getappdata(handles.pcsedit,'default');
if isempty(out)
  %For some reason appdata does not get populated sometimes so check
  %string.
  out = str2num(get(handles.pcsedit,'string'));
end
