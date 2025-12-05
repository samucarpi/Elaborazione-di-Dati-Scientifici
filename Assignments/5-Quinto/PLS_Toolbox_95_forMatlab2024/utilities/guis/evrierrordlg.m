function varargout = evrierrordlg(varargin)
%EVRIERRORDLG Overload standard error dialog for automation management.
% Operation of this function is nearly identical to the standard Matlab
% ERRORDLG function except that this function will intercept calls through
% an automation interface and skip showing the dialog.
%
% When running in automation mode, an error is thrown with the given error
% text as the message.
%
% For I/O options, see the ERRORDLG function.
%
%See also: ERDLGPLS, EVRIWARNDLG, EVRIQUESTDLG, QUESTDLG

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

erdlgpls(varargin{:});
if nargout>0
  varargout = {[]};
end
