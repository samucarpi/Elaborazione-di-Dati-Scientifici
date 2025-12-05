function varargout = evriinstall(varargin)
%EVRIINSTALL Install Eigenvector Research Product.
%
%See also: EVRICOMPATIBILITY, EVRIDEBUG, EVRIRELEASE, EVRIUNINSTALL, EVRIUPDATE, SETPATH

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB�, without
% written permission from Eigenvector Research, Inc.

try
  if nargout==0
    evriinstallengine(varargin{:});
  else
    [varargout{1:nargout}] = evriinstallengine(varargin{:});
  end
catch
  le = lasterror;
  if ~isempty(strfind(lower(le.message),'p-file'))
    action = questdlg(sprintf('This build of PLS_Toolbox is only compatible with Matlab versions 2007b and later.\n\nYou must download the "2007a" build of this product to use it with Matlab %s. You can access this build from the Download tab of your Eigenvector Research account on our web page.',version),'Version Incompatibility','Cancel','Download Now','Download Now');
    if ~strcmpi(action,'Cancel')
      web('http://download.eigenvector.com/','-browser');
    end
    error('PLS_Toolbox build is incompatible with this Matlab version - see Eigenvector download page');
  else
    rethrow(le);
  end
end
