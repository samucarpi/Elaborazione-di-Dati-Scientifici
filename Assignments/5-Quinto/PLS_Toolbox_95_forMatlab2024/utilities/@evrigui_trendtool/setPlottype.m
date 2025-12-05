function out = setPlottype(obj,parent,varargin)
%SETPLOTTYPE Sets plot type on Trend View images.
% 
%I/O: .setPlottype('')
%I/O: .sePlottype('surface')

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

trendtool('plottype',parent.handle,varargin{1});
out = 1;  

