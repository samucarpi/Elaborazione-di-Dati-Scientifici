function varargout = evriwarndlg(varargin)
%EVRIWARNDLG Overload standard warning dialog for automation management.
% Operation of this function is nearly identical to the standard Matlab
% WARNDLG function except that this function will intercept calls through
% an automation interface and skip showing the dialog
%
% For I/O options, see the WARNDLG function.
%
%See also: ERDLGPLS, EVRIHELPDLG, EVRIMSGBOX, EVRIQUESTDLG

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

evrimsgbox(varargin{:},'warn','modal');
if nargout>0
  varargout = {[]};
end
