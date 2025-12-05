function out = clearMarkers(obj,parent,varargin)
%CLEARMARKERS Clears markers being used by TrendTool.
%I/O: .clearMarkers

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(2, 2, nargin))

trendmarker('delete','all',parent.handle);
out = 1;  
