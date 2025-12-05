function obj = vertcat(obj,varargin)
%EVRISCRIPT_STEP/VERTCAT

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

obj = cat(1,obj,varargin{:});
