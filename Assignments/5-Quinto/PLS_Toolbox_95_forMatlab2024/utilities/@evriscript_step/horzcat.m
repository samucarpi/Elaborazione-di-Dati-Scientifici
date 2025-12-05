function obj = horzcat(obj,varargin)
%EVRISCRIPT_STEP/HORZCAT

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

obj = cat(2,obj,varargin{:});
