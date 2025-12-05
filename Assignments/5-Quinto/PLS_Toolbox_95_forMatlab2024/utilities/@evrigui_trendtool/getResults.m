function out = getResults(obj,parent,varargin)
%GETRESULTS Returns trend analysis results from TrendTool.
%I/O: .getResults

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

model = trendmarker('getmodel',parent.handle);
data  = plotgui('getdataset',parent.handle);
out   = trendtool(data,model);


