function [env, helper_script] = whichPython(varargin)
%whichPython Will tell you what Python virtual environment to use.
%   Versions of MATLAB support specific versions
%   of Python. So this hash table indicates the correct virtual environment
%   to be created/used based on the version of Matlab/MCR being used as 
%   well as based on the computer architecture. 
%
%  OUTPUT:
%     env           = name of correct Python virtual environment to be
%                     made.
%     helper_script = shell file that creates the environment.

%I/O: [env, helper_script] = whichPython()
%
%See also: config_pyenv undo_config_pyenv check_pyenv

%Copyright Eigenvector Research, Inc. 2022
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.
%  smr

env = '';
helper_script = '';
pyver = '';


% the target is to use versions of Python that have the longest shelf-life,
% which will result in having to make more Python environments
% check out the compatibility chart here:
% https://www.mathworks.com/content/dam/mathworks/mathworks-dot-com/support/sysreq/files/python-compatibility.pdf
if checkmlversion('<','9.9')
  pyver = 'Version of MATLAB is too old. Need at least R2020b.';
  evrierrordlg(pyver);
elseif checkmlversion('>=','9.9') && checkmlversion('<','9.13')
  pyver = '38';
elseif checkmlversion('>=','9.13')
  pyver = '310';
else
  pyver = 'Cannot determine which version of Python to use. Please contact helpdesk@eigenvector.com';
  evrierrordlg(pyver);
end

switch computer
  case 'MACI64'
    env = ['pls_toolbox_mac_' pyver];
    helper_script = ['make_mac_env_' pyver '.sh'];
  case 'MACA64'
    env = ['pls_toolbox_mac_arm_' pyver];
    helper_script = ['make_mac_arm_env_' pyver '.sh'];
  case 'PCWIN64'
    env = ['pls_toolbox_windows_' pyver];
    helper_script = ['make_windows_env_' pyver '.bat'];
  case 'GLNXA64'
    env = ['pls_toolbox_linux_' pyver];
    helper_script = ['make_linux_env_' pyver '.sh'];
  otherwise
    env = ['Unsupported computer : ' computer '. Please reach out to heldesk@eigenvector.com'];
    evrierrordlg(env);
end
end