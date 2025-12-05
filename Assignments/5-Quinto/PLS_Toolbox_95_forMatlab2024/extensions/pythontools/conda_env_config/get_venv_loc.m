function [p] = get_venv_loc(varargin)
%GET_VENV_LOC Get path location of PLS_Toolbox Python environment.
%   Find base location of the Miniconda3 or Anaconda3 software. This
%   assumes the user properly added one (or both) of these to their system
%   path during installation. If not added to the path properly see here:
% [https://developers.google.com/earth-engine/guides/python_install-conda#add_miniconda_to_path_variable].
%
% OUTPUTS:
%      conda_path =  Char of base installation location.
%
%I/O:  [conda_path] = get_venv_loc()
%
%See also: config_pyenv, undo_config_pyenv, find_conda

%Copyright Eigenvector Research, Inc. 2022
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.
%  smr




p = '';

orig_dir = pwd;
filepath = fileparts(mfilename('fullpath'));
cd(filepath);
cd('helper_scripts');

% get directory of Miniconda
conda_path = find_conda();
if strcmpi(computer,'PCWIN64')
  % launch anaconda powershell prompt to do the conda command
  % 'conda info -e'
  [~,env_info] = system(['get_env_info.bat ' conda_path '\shell\condabin\conda-hook.ps1']);
elseif isunix
  cmd = executeCondaConfigFiles();
  if ~isempty(cmd)
    [~,env_info] = system([cmd 'bash ./get_env_info.sh ' strcat(conda_path,'/bin')]);
  else
    error('Unable to find Conda. Please contact the helpdesk at helpdesk@eigenvector.com')
  end
end
%TODO: will need to change this for future environments
% get line from conda info -e that shows pltb env
plstb_env = regexp(env_info, ['(' replace(whichPython,'_','\_') '.*$)'],'match');
if ~isempty(plstb_env)
  % env was successfully created and shows up in the output of 'conda
  % info -e'
  % path should be the second element from the split
  p = split(plstb_env);
  p = p{2};
else
  p = 'Error in finding environment, please contact helpdesk@eigenvector.com';
  evrierrordlg(p);
end
cd(orig_dir);
end

