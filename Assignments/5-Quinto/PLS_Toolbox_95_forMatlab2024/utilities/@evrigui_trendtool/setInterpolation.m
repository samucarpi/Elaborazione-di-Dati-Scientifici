function out = setInterpolation(obj,parent,varargin)
%SETINTERPOLATION Sets interpolation on Trend View images.
% input is the amount of interpolation to use as a number of pixels of
% over-sampling to add.
%I/O: .setInterpolation(1)
%I/O: .setInterpolation(n)

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, 3, nargin))

trendtool('interpolation',parent.handle,varargin{1});
out = 1;  

