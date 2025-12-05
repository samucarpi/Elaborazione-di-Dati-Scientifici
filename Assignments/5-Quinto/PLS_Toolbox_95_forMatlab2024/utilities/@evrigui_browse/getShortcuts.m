function out = getShortcuts(obj,parent,varargin)
%GETSHORTCUTS Returns currently available workspace shortcuts.
%I/O: .getShortcuts

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

workspace = getappdata(parent.handle,'workspace');
out = {workspace(ismember({workspace.class},'shortcut')).name};
