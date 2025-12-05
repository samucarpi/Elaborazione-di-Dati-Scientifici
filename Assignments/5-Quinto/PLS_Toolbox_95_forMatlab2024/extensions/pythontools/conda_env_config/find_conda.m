function [conda_path] = find_conda()
%FIND_CONDA Get path location of Miniconda3 or Anaconda3.
%   Find base location of the Miniconda3 or Anaconda3 software. This
%   assumes the user properly added one (or both) of these to their system
%   path during installation. If not added to the path properly see here:
% [https://developers.google.com/earth-engine/guides/python_install-conda#add_miniconda_to_path_variable].
%
% OUTPUTS:
%      conda_path =  Char of base installation location.
%
%I/O:  [conda_path] = find_conda()
%
%See also: config_pyenv, undo_config_pyenv, get_venv_loc

%Copyright Eigenvector Research, Inc. 2022
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.
%  smr


conda_path = '';
if strcmpi(computer,'PCWIN64')
  % Miniconda should have been added to the system path
  % Could make a .bat file to execute %CONDA_PREFIX% from anaconda powershell but is slow
  ps = split(getenv('PATH'),';');
  matches = cellfun(@(str)regexp(str,'(.+[mM]iniconda3$)','match'),ps,'UniformOutput',false);
  ind = find(~cellfun(@isempty,matches));
  if ~isempty(ind)
    conda_path = ps{ind};
  else
    % does user have Anaconda?
    matches = cellfun(@(str)regexp(str,'(.+[aA]naconda3$)','match'),ps,'UniformOutput',false);
    ind = find(~cellfun(@isempty,matches));
    if ~isempty(ind)
      conda_path = ps{ind};
    end
  end
elseif isunix
  % check if $CONDA_PREFIX is there already, if not then execute config files

  [~,out] = system('echo $CONDA_PREFIX');
  if ~isempty(strtrim(out))
    conda_path = strtrim(out);
  else
    cmd = executeCondaConfigFiles();
    if ~isempty(cmd)
      [~,conda_path] = system([cmd 'echo $CONDA_PREFIX']);
      conda_path = strtrim(conda_path);
    end
  end
end