function out = vertcat(varargin)
%SHAREDDATA/VERTCAT overload

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

out = cat(1,varargin{:});
