function out = open(obj,parent,varargin)
%OPEN Opens object or shortcut.
%I/O: .open('objectname')

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

workspace = getappdata(parent.handle,'workspace');
match = strmatch(lower(varargin{1}),lower({workspace.name}));
if isempty(match)
  error('Object or Shortcut "%s" not found',varargin{1});
else
  browse('doubleclick',parent.handle,workspace(match));
end
out = 1;
