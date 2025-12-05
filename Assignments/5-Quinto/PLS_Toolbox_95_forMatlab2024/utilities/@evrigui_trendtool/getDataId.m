function out = getDataId(obj,parent,varargin)
%GETDATAID Returns shareddata ID of data being analyzed in TrendTool.
%I/O: .getDataId

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

ids = getshareddata(parent.handle);
out = ids{1};

