function out = getVisibility(obj,parent,varargin)
%GETVISIBILITY Returns current GUI visibility (0 = invisible, 1 = visible)
%I/O: .getVisibility

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

out = strcmp(get(parent.handle,'visible'),'on');
