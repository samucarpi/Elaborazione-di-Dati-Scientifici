function varargout = evrimsgbox(varargin)
%EVRIMSGBOX Overload standard message dialog for automation management.
% Operation of this function is nearly identical to the standard Matlab
% MSGBOX function except that this function will intercept calls through an
% automation interface and skip showing the dialog
%
% For I/O options, see the MSGBOX function.
%
%See also: ERDLGPLS, EVRIHELPDLG, EVRIQUESTDLG, EVRIWARNDLG

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if inevriautomation
  %in automation, skip message
  if nargout>0
    varargout = {[]};
  end
  return
end

waitfor(msgbox(varargin{:}));
if nargout>0
  varargout = {[]};
end
