function [result] = undo_config_pyenv(varargin)
%UNDO_CONFIG_PYENV Removes PLS_Toolbox Python installation.
%   Removes the Python virtual environment created by config_pyenv if no
%   input arguments are given; it will remove Python, the package setup,
%   and all other associated files with this virtual environment. If 'all'
%   is given as an input argument, then the Miniconda3/Anaconda3 software will be
%   removed altogther. This not only deletes the virtual environment
%   created for PLS_Toolbox, but any other virtual environments created by
%   the user and any other associated files.
%
% OPTIONAL INPUTS:
%         options = structure array with the following fields:
%           silent: [ {'no'} | 'yes' ] Governs the level of user-input
%                   needed. A dialog box is created asking the user if they would
%                   like to continue with the configuration when silent='no'. No
%                   dialox box is created when silent='yes'.
%           remove_all: [ {'no'} | 'yes' ] Will dictate either the virtual
%                   environment (venv) removal or removal of all of Miniconda/Anaconda (which
%                   includes all venvs). By default, only the virtual environment
%                   will be removed.
%
% OUTPUTS:
%         result =  String reporting the success or failure of removal.
%
%I/O:  result = undo_config_pyenv
%I/O:  result = undo_config_pyenv(options)
%
%See also: config_pyenv

% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%
%smr


if nargin==0
  options = undo_config_pyenv('options');
else
  if ischar(varargin{1})
    %options structure
    options = [];
    options.silent = 'no';
    options.remove_all = 'no';
    if nargout==0; evriio(mfilename,varargin{1},options); else; result = evriio(mfilename,varargin{1},options); end
    return;
  elseif isstruct(varargin{1})
    options = varargin{1};
  end
end

answer = '';
result = '';

orig_dir = pwd;
filepath = fileparts(mfilename('fullpath'));
cd(filepath);
%cd('helper_scripts');
pe = pyenv;
if strcmpi(options.remove_all,'no')
  % User wishes to remove only PLS_Toolbox virtual environment
  
  env_loc = char(pe.Home);
  
  note = ['You are about to delete the PLS_Toolbox/Solo Python virtual environment located here:'...
    newline  newline env_loc newline newline ...
    'This will remove Python, add-on packages, and other assocatied files that pertain to the creation of this environment. Do you wish to continue?'];
  title = 'PLS_Toolbox Undo Python Configuration';
  if strcmpi(options.silent,'yes')
    %force answer to continue. this is mostly intended for Solo_Predictor,
    %where user-input is not allowed.
    answer = 'Yes';
  else
    answer = evriquestdlg(note, title, 'Yes', 'No', 'No');
  end

  switch answer
    case 'Yes'
      if isunix
        cmd = ['rm -rf ' env_loc];
      elseif strcmpi(computer, 'PCWIN64')
        cmd = ['powershell Remove-Item -Recurse ' env_loc ' -ErrorAction Ignore'];
      end
      [status, stdout] = system(cmd);
      % Condition on status, if 0, success
      if status==0
        result = 'PLS_Toolbox Python environment successfully removed.';
      elseif status==1
        result = ['Access to some files were denied when removing the environment. To fully remove environment, close this session and manually delete the folder ' env_loc];
      else
        cd(orig_dir);
        error(['Error when removing PLS_Toolbox Python environment with status ' num2str(status)])
      end
    case 'No'
      result = 'Removal of PLS_Toolbox Python virtual environment halted';
  end
  cd(orig_dir);
elseif strcmpi(options.remove_all,'yes')
  % User wants to get rid of Miniconda3/Anaconda3 altogether
  conda_loc = find_conda();
  if isempty(conda_loc)
    evrierrordlg('Miniconda3/Anaconda3 was not found on the path. Please reinstall and add to path, or manually add to system path. If the path was added, restart and rerun the configuration.');
    return
  end
  
  note = ['Continuing will remove the Miniconda3/Anaconda3 software and all virtual environments in this location:'...
    newline newline conda_loc newline newline 'Do you wish to continue?'];
  title = 'PLS_Toolbox Undo Python Configuration';
  answer = evriquestdlg(note, title, 'Yes', 'No', 'No');
  switch answer
    case 'Yes'
      if isunix
        cmd = ['rm -rf ' conda_loc];
      elseif strcmpi(computer, 'PCWIN64')
        % run uninstaller, previous rm command did not work for
        % Miniconda installed under all users
        % condition on the type of installer depending if Miniconda or
        % Anaconda is used.
        conda_type='';
        if ~isempty(regexp(conda_loc,'(.+[aA]naconda3$)','match'))
          conda_type = 'Anaconda3';
        elseif ~isempty(regexp(conda_loc,'(.+[mM]iniconda3$)','match'))
          conda_type = 'Miniconda3';
        end
        cmd = ['powershell Start-Process ' conda_loc '\Uninstall-' conda_type '.exe'];
      end
      [status, stdout] = system(cmd);
      % Condition on status, if 0, success
      if status==0
        if strcmpi(computer, 'PCWIN64')
          result = ['Launching ' conda_type ' Uninstaller.'];
        else
          result = 'Miniconda3 successfully removed.';
        end
      elseif status==1
        result = ['Access to some files were denied when removing Miniconda3. To fully remove Miniconda3, close this session and manually delete the folder ' conda_loc];
      else
        cd(orig_dir);
        error(['Error when removing PLS_Toolbox Python environment with status ' num2str(status)])
      end
    case 'No'
      result = 'Removal of Miniconda3 halted';
  end
  cd(orig_dir);
end


if strcmpi(answer,'yes')
  %Roll back symbolic link to libgfortran.3.dylib.
  if isdeployed && ismac
    mcr_root = matlabroot;%MCR root folder.
    %Should be symlink to miniconda.
    mlliblocation = fullfile(mcr_root,'sys','os','maci64','libgfortran.3.dylib');
    %Bakcup file.
    mlliblocationbak = fullfile(mcr_root,'sys','os','maci64','libgfortran.3.dylib.bak');
    %Check to see if .bak file exists. It shouldn't be a symlink so exist()
    %will work.
    if exist(mlliblocationbak)
      %Looks like user installed so delete the symlink. Don't make fatal
      %error (if it doesn't exist for example).
      try
        delete(mlliblocation);
      end
      %Move original file from .bak to normal filename.
      movefile(mlliblocationbak,mlliblocation);
    else
      %No backup file. Check for libgfortran.3.dylib file. Exist won't
      %resolve symlink. So if user somehow loses backup file but still has
      %conda symlink this could be misleading but that's unlikely.
      if ~exist(mlliblocation)
        %Looks like the libgfortran.3.dylib is missing. Need to contact
        %helpdesk because something went wrong.
        evrierrordlg(['Contact helpdesk@eigenvector.com, the following Matlab dylib location can''t be found/restored:  ' mlliblocation], 'Matlab DYLIB Location Error');
      else
        %Probably never installed so don't do anything.
      end
    end
  end

end
end