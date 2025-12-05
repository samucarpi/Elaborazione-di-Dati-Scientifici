function obj = cat(dim,obj,varargin)
%EVRISCRIPT/CAT

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

for j=1:length(varargin)
  obj = add(obj,varargin{j});
end
