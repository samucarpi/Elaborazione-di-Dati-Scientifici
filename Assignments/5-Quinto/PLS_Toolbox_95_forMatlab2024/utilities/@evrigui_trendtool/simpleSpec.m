function out = simpleSpec(obj,parent,varargin)
%SIMPLESPEC Enables simple spectrum display mode.
%I/O: .simpleSpec(1)
%I/O: .simpleSpec(0)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

trendtool('simplespec',parent.handle,varargin{1});
out = 1;  

