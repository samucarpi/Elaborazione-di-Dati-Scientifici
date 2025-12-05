function varargout = encodexml(obj,varargin)
%EVRIGUI_fcn/ENCODEXML Overload

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargout==0
  encodexml(char(validmethods(obj)),varargin{:});
else
  [varargout{1:nargout}] = encodexml(char(validmethods(obj)),varargin{:});
end
