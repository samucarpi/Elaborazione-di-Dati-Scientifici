function out = setOptions(obj,parent,varargin)
%SETOPTIONS Load Analysis Methods Options structure.
%I/O: .setOptions(options)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

handles = guidata(parent.handle);
analysis('loadoptions',handles.analysis, [], handles, varargin{:})
out = true;
