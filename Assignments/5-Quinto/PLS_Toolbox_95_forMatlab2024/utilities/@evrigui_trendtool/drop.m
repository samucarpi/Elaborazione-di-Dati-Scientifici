function out = drop(obj,parent,varargin)
%DROP Drops marker model or data onto TrendTool.
%I/O: .drop(obj)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

trendtool('drop',parent.handle,[],[],varargin{1});
out = 1;  

