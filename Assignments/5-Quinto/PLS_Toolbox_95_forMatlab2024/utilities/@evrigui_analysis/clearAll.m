function out = clearAll(obj,parent,varargin)
%CLEARALL Clears all data, models, and predictions.
%I/O: .clearAll

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

analysis('clearall',parent.handle,[],guidata(parent.handle))

out = true;
