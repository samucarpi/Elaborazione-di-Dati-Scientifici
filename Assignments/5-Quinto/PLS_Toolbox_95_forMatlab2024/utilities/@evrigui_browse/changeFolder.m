function out = changeFolder(obj,parent,varargin)
%CHANGEFOLDER Change current directory.
%I/O: .changefolder('/Users/jeffgordon/Desktop/')

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

cd(varargin{1});
browse('update',parent.handle);
out = 1;
