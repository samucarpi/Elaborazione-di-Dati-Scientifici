function out = setMethod(obj,parent,varargin)
%SETMETHOD Sets the Analysis method to the specified type.
%I/O: .setMethod('method')

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

handles = guidata(parent.handle);
analysis('enable_method',handles.analysis,[],handles,varargin{1})
out = true;
