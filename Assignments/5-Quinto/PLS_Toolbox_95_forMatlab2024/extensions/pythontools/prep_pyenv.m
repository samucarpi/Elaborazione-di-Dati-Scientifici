function varargout = prep_pyenv(varargin)
%PREP_PYENV Prepare pyenv object appropriately for future Python commands.
%   There are a couple of necessary measures to resolve before a Python
%   command is executed. For Unix machines, the dlopen flags for the pyenv
%   object need to be set to 10. This way, the various Python packages that
%   use libraries in common with Matlab won't share these libraries,
%   avoiding version mismatches. We also want to check if user's MATLAB is
%   2020b or higher.
%   
%  OPTIONAL INPUTS:
%   options = structure array with the following fields:
%          executable: [ '' ] path to python executable. This is set for
%                      deployed apps during config_pyenv. On some platforms
%                      with deployed apps (Mac) the path is not retained
%                      and pyenv keeps the path that was available at
%                      compile time.
%I/O:  prep_pyenv
%
%See also: CONFIG_PYENV, UNDO_CONFIG_PYENV

%Copyright Eigenvector Research, Inc. 2021
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==1 && ischar(varargin{1});
  options = [];
  options.executable = '';
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

if nargout>0
  varargout{1} = false;
end

% Check if user's MATLAB version, must be 2020b or higher
if ~(checkmlversion('>=','9.9'))
  evrierrordlg('PLS_Toolbox/Solo Python Integration only supported for versions R2020b and higher.');
  return
end

% Since this is only called in PLS_Toolbox methods, make sure the pyenv is
% ours.
pe = pyenv;
if ~(contains(pe.Executable,'pls_toolbox'))
  %Should be 'pls_toolbox_windows' | 'pls_toolbox_mac' | 'pls_toolbox_linux'
  %pyenv is not ours, error, tell user since they are trying to access
  %Python method to first run config_pyenv
  evrierrordlg('You are trying to run a Python method without the appropriate Python configuration. Please configure the PLS_Toolbox/Solo environment first.')
  return
end

%Current pyenv is for pls_toolbox. Check to see if executable exists for
%deployed apps. There is a known bug for Mac that saves the
%pyenv.Executable value from the machine it was compiled on and doesn't
%retain any new values. 
if isdeployed && ~exist(char(pe.Executable))
  %Check to see if there is a saved value.
  options = prep_pyenv('options');
  if ~isempty(options.executable) && exist(options.executable)
    pyenv('Version',options.executable)
  else
    evrierrordlg('You are trying to run a Python method without the appropriate Python configuration. Please configure the PLS_Toolbox/Solo environment first.')
    return
  end
end

% pyenv is ours
% now set up libs for unix machines
try
  set_pyenv_flags;
catch E
  evrierrordlg(['Error in preparing pyenv: ' E.message]);
  return
end

if nargout>0
  varargout{1} = true;
end

