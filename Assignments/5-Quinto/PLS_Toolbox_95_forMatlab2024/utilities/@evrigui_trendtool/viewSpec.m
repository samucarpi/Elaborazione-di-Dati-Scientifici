function out = viewSpec(obj,parent,varargin)
%VIEWSPEC Displays the specified spectrum (or spectra).
%I/O: .viewSpec(index)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

trendtool('viewspec',parent.handle,varargin{1});
out = 1;  

