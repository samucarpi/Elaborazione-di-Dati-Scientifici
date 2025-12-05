function [result,envstatus] = check_pyenv
%CHECK_PYENV Checks status of PLS_Toolbox Python Environment
%   Compares user's current Python environment against one that was created
%   for PLS_Toolbox. If the user has a PLS_Toolbox environment, their
%   current environment is checked with what should be contained in the
%   environment. This check is done in the corresponding check_pyenv.py
%   file. The true environment contents are in this directory and are in
%   the corresponding pythonXY.mat files. Each of these will load 3 pickled
%   Python lists, each list containing the valid contents of what should be
%   in the user's Python environment. The .py file takes a set difference
%   between what the user currently has, and what should be there. The
%   'result' output contains message of any differences or that environment
%   is configured properly. A check is also done to see if the PLS_Toolbox
%   Python interpreter is functional.
%
%I/O: result = check_pyenv
%
%See also: config_pyenv undo_config_pyenv

%Copyright Eigenvector Research, Inc. 2021
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.
%  smr

%This function is primarily used by 'browse' menu item to check python
%setup.

result = [];
envstatus = 0;

try
  myenvisgood = prep_pyenv;% Restore default path if needed and check for pls_toolbox environment. 
  if ~myenvisgood
    %User will get error message from prep_pyenv so just return.
    return
  end
  pe = pyenv;  
  interpreter = pe.Executable;
  
  %cd here to execute Python script
  orig_dir = pwd;
  filepath = fileparts(mfilename('fullpath'));
  cd(filepath);
  
  
  %first, check to see if Python is working. The fields in pyenv do not
  %update if the configured Python is deleted or moved.
  %Build inexpensive Python command. Simple enough command to see if Python
  %is broken, here we are importing a built-in Python package.
  cmd = [char(interpreter) ' ' '-c "import sys"'];
  %If Python is truly working, then status will be 0 and stdout will be an
  %empty char array. Other behavior tells us that the Python interpreter is broken, has moved, or is nonexistent.
  [status, stdout] = system(cmd);
  
  if ~(status==0 && strcmp(stdout,char.empty))
    result = 'The PLS_Toolbox/Solo Python interpreter cannot be found. Restart and reconfigure to use Python in PLS_Toolbox/Solo.';
    envstatus = 1;
    cd(orig_dir);
    return
  end
   
  %MATLAB does a prescan of the code for any py. commands.
  %If Python was not found there would be an error calling check_pyenv.
  %Therefore, this wrapper is called to get the results of any adding or missing Python packages. 
  [addons, addons_size,missing,missing_size] = get_python_diff;
  
  if addons_size == 0 && missing_size == 0
    %nothing is missing and nothing is added on
    result = 'Default Python environment for PLS_Toolbox/Solo is configured correctly.';
    envstatus = 0;
  else
    %Not sure if 'addons' or 'missing' can be less than 0 so make result with empty
    %string just in case so error does not occur.
    result = '';
    envstatus = 1;
    if addons_size > 0
      %packages have been added on
      result = ['The PLS_Toolbox Python environment has been changed.' newline...
        'Packages that have been added since original configuration:' newline ...
        char(addons) newline ...
        'We cannot guarantee Python within PLS_Toolbox/Solo will work correctly, please restart and then reconfigure Python.'];
    elseif missing_size > 0
      %%packages are missing
      result = [' The PLS_Toolbox Python environment has been changed.' newline...
        'Packages that are now missing since original configuration:' newline ...
        char(missing) newline ...
        'We cannot guarantee Python within PLS_Toolbox/Solo will work correctly, please restart and then reconfigure Python.'];
    end
  end
  cd(orig_dir);
catch E
  evrierrordlg(['Error occured when checking pyenv: ' E.message],'PYENV ERROR');

end
