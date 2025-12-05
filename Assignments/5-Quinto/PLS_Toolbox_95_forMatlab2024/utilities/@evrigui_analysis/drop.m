function out = drop(obj,parent,varargin)
%DROP Automatically load one or more objects into GUI (data and/or models).
% Inputs can be multiple objects: (xdata, ydata, model)
% User may be prompted for where to load the given data. To put data into a
% particular location, use the .setXblock, .setYblock, methods and the
% corresponding set validation methods.
%
%I/O: .drop(data1,data2,model)  %or other combinations

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

error(nargchk(3, inf, nargin))

analysis('drop',parent.handle,[],guidata(parent.handle),varargin{:})

out = true;
