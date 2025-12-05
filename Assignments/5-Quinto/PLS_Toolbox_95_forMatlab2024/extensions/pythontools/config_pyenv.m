function [result] = config_pyenv(varargin)
%CONFIG_PYENV Configures Python environment for PLS_Toolbox Python methods.
%   Creates a Python interpreter specifically for PLS_Toolbox. This can be done
%   one of two ways. When the source is 'conda' (this is default), a conda
%   virtual environment is made either from Miniconda or Anaconda. This
%   option requires an internet connection as it builds the environment from
%   scratch and downloads packages from the conda repository. When source is
%   'archived', the Python is extracted from and archived file. This file is
%   available upon request to the helpdesk at helpdesk@eigenvector.com. This
%   method does not require an internet connection upon integrating with
%   PLS_Toolbox/Solo. The resulting Python interpreter gets passed to pyenv. Once pyenv is
%   setup, access is granted to use any Python method in PLS_Toolbox.
%   Output 'result' contains text message of outcome.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%           silent: [ {'no'} | 'yes' ] Governs the level of user-input
%                   needed. A dialog box is created asking the user if they would
%                   like to continue with the configuration when silent='no'. No
%                   dialog box is created when silent='yes'.
%           source: [ {'conda'} | 'archived' ] The source of which Python
%                   is built and configured for PLS_Toolbox/Solo. When
%                   source='conda', a virtual environment is built using
%                   Miniconda/Anaconda. If source='archived', then the Python comes
%                   from an archived file. This file is available upon request to
%                   our helpdesk.
%
% OUTPUTS:
%         result =  String reporting the success or failure of removal.
%
%I/O:  result = config_pyenv
%I/O:  result = config_pyenv(options)
%
%See also: undo_config_pyenv

%Copyright Eigenvector Research, Inc. 2021
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.
%  smr

if nargin==0
  options = config_pyenv('options');
else
  if ischar(varargin{1})
    %options structure
    options = [];
    options.silent = 'no';
    options.source = 'conda';
    options.timeout = 7200; % seconds
    options.archived_location = [];
    if nargout==0; evriio(mfilename,varargin{1},options); else; result = evriio(mfilename,varargin{1},options); end
    return;
  elseif isstruct(varargin{1})
    options = varargin{1};
  end
end


result = '';

%{
 patch for Macs

 * cannot support Python on M1 machines running Rosetta due to problems with Tensorflow

%}

if ismac
  [junk, arch] = system('sysctl -n machdep.cpu.brand_string');
  comp = computer;
  if ismember('M1',split(strtrim(arch),' '))
    if strcmpi(comp,'maci64')
      evrierrordlg('Python is not supported for Mac M1 machines running Rosetta MATLAB.');
      return
    end
  end
end


% Putting this under a try/catch. If user does not have a Cython set up
% already, calling pyenv can cause issues.

try
  pe = pyenv;
  if strcmpi(pe.Status,'Loaded')
    warning('EVRI:ConfigPyEnv','Python environment can''t be changed after loading. Restart to make changes.');
    result = 'Python environment can''t be changed after loading. Restart to make changes.';
    return
  end
catch
  % Do nothing, set up pyenv later when environment is created
end

% Check if user's MATLAB version, must be 2020b or higher
if ~(checkmlversion('>=','9.9'))
  evrierrordlg(['PLS_Toolbox Python Integration only supported for versions R2020b or newer. You are using version ' char(version('-release')) ', which is too old for this feature.']);
  return
end


switch options.source
  case 'conda'
    [result,waitbarhandle] = conda_config(options);
  case 'archived'
    [result,waitbarhandle] = archive_config(options);
  otherwise
    evrierrordlg('Unsupported configuration source. Expecting ''conda'' or ''archived''.')
    return
end

[success,waitbarhandle] = handle_dynamic_links(waitbarhandle);

if exist('waitbarhandle')
  delete(waitbarhandle);
end
end
%-------------------------------------------------------------------------%

function [result,waitbarhandle] = conda_config(options)
result = [];
waitbarhandle = [];
% see if conda is on the path
conda_dir = find_conda();
if isempty(conda_dir)
  result = 'Miniconda/Anaconda was not found on the path. Please reinstall and add to path, or manually add to system path. If the path was added, restart and rerun the configuration.';
  evrierrordlg('Miniconda/Anaconda was not found on the path. Please reinstall and add to path, or manually add to system path. If the path was added, restart and rerun the configuration.');
  return
end

if ismac
  archIsGood = checkCondaArchitecture;
  if ~archIsGood
    s.MACI64 = 'osx_64';
    s.MACA64 = 'osx_arm64';
    result = ['Incorrect Conda architecture for computer. Python configuration needs the ' upper(s.(computer)) ' installer of Miniconda3 or Anaconda3.'];
    evrierrordlg(result)
    return
  end
end

% Dialog box warning user the time and space it takes to build/configure
% Python
% If Python is loaded, then restarting MATLAB is highly recommended.
pyload = '';

%set up dialog box
note = ['This Python configuration can take a few minutes to complete and the Python environment created can take up 1-2 GB of disk storage. ' newline newline];
query = append(pyload, note);
title = 'PLS_Toolbox Python Configuration';

if strcmpi(options.silent,'yes')
  %force answer to continue. this is mostly intended for Solo_Predictor,
  %where user-input is not allowed.
  answer = 'Continue';
else
  answer = evriquestdlg(query, title, 'Continue', 'Exit', 'Continue');
end

orig_dir = pwd;
switch answer
  case 'Continue'
    waitbarhandle = waitbar(0.2,'Please note that this process can take a few minutes.','Name','Configuring Python');
    % Switch to this directory to access local scripts

    filepath = fileparts(mfilename('fullpath'));
    cd(filepath);
    cd('conda_env_config');
    cd('helper_scripts');

    % Update notes to print during configuration
    reiterate = 'Starting shell script.';
    env_start = ['Starting virtual environment creation.' newline 'This can take several minutes...'];
    env_complete = ['Conda is done building.' newline 'Finding path to PLS\_Toolbox Python interpreter...'];
    python_path = 'Path to PLS\_Toolbox Python interpreter found.';
    pass_path = 'Passing path the to MATLAB pyenv function...';
    
    % based on system and version of Matlab, get appropriate environment to
    % build
    [env_name, helper_script] = whichPython();

    % Condition on systems, macOS, Windows, and Linux
    disp(reiterate);
    switch computer
      case {'MACI64' 'MACA64'}
        % Creates conda env from yml file in Terminal
        waitbar(0.3,waitbarhandle,env_start);
        % make virtual environment
        % bash ./make_mac_env_pyver.sh arg1 arg2
        % arg1: conda_dir + '/bin' is the path that allows to call the conda executable
        % arg2: path of where the env will be built
        disp(['Building environment in ' strcat(conda_dir,['/envs/' env_name])]);
        cmd = ['bash ./' helper_script ' ' strcat(conda_dir, '/bin ') ' ' strcat(conda_dir,['/envs/' env_name])];
        system(cmd);
        waitbar(0.6,waitbarhandle,env_complete);
        % get location of environment
        env_path = get_venv_loc();
        % complete path to Python executable
        conda_full_path = [env_path '/bin/python'];
        waitbar(0.8,waitbarhandle,python_path);

      case 'PCWIN64'
        % Opens Anaconda Powershell Prompt, creates environment
        waitbar(0.3,waitbarhandle,env_start);
        % make virtual environment
        disp(['Building environment in ' conda_dir '\envs\' env_name]);
        % make_windows_env_38.bat arg1 arg2
        % arg1: path that allows to call the conda executable
        % arg2: path of where the env will be built
        cmd = [helper_script ' ' conda_dir '\shell\condabin\conda-hook.ps1 ' conda_dir '\envs\' env_name];
        timerhandle = timer('TimerFcn', {@checkcondaprocess, 'check'}, ...
                            'StopFcn',  {@checkcondaprocess, 'stop'}, ...
                            'StartDelay', 60, ...
                            'BusyMode', 'drop', ...
                            'ExecutionMode', 'fixedSpacing', ...
                            'Period', 10,...
                            'TasksToExecute',99999,...
                            'StartFcn',{@config cmd},...
                            'UserData',struct('starttime',datetime('now'),'maxtime',options.timeout));
        start(timerhandle);
        wait(timerhandle);
        waitbar(0.6,waitbarhandle,env_complete);
        % get location of environment
        env_path = get_venv_loc();
        % complete path to Python executable
        conda_full_path = [env_path '\python'];
        waitbar(0.8,waitbarhandle,python_path);

      case 'GLNXA64'
        % Creates conda env from yml file in Terminal
        waitbar(0.3,waitbarhandle,env_start);
        % make virtual environment
        % bash ./make_linux_env_38.sh arg1 arg2
        % arg1: conda_dir + '/bin' is the path that allows to call the conda executable
        % arg2: path of where the env will be built
        disp(['Building environment in ' strcat(conda_dir,['/envs/' env_name])]);
        cmd = ['bash ./' helper_script ' ' strcat(conda_dir, '/bin ') ' ' strcat(conda_dir,['/envs/' env_name])];
        system(cmd);
        waitbar(0.6,waitbarhandle,env_complete);
        % get location of environment
        env_path = get_venv_loc();
        % complete path to Python executable
        conda_full_path = [env_path '/bin/python'];
        waitbar(0.8,waitbarhandle,python_path);
        
      otherwise
        result = ['Unsupported architecture ' computer '. Please contact heldesk@eigenvector.com'];
        evrierrordlg(result);
        return
    end

    try
      % Point pyenv to virtual environment
      waitbar(0.9,waitbarhandle,pass_path);
      pyenv('ExecutionMode','InProcess');
      pyenv('Version',conda_full_path)

      %Save path to executable in case it's lost (known mac issue).
      setplspref('prep_pyenv','executable',conda_full_path);

      % Make sure Python uses its own libraries, and not Matlab's
      set_pyenv_flags;
      % See if any libraries are missing
      [envres,envstatus] = check_pyenv;
      if envstatus
        % something went wrong, output the message from check_pyenv
        result = envres;
      else
        result = 'Your pyenv was configured successfully!';
      end
      
      cd(orig_dir);
      %Don't delete waitbar, it's used below.
      %delete(waitbarhandle)
    catch E
      cd(orig_dir);
      evrierrordlg(['Error occured when configuring pyenv: ' E.message newline 'Error in line: ' num2str(E.stack(1).line) newline...
        'Conda path: ' conda_full_path]);
    end
  case 'Exit'
    result = 'Python Configuration halted by user.';
    waitbarhandle = [];
end
cd(orig_dir);
end
%-------------------------------------------------------------------------%

function [result, waitbarhandle] = archive_config(opts)
% check if file exists first, since this option is only available upon
% request
result = [];
waitbarhandle = waitbar(0.2,'Starting Python configuration with archived option...');
pause(1);
% get location of archived file
if ~isempty(opts.archived_location)
  if ~ischar(opts.archived_location)
    error('Expecting char of archived file location.')
  else
    [archivedDirectory, file, ext] = fileparts(opts.archived_location);
    file = [file ext];
  end
else
  [file, archivedDirectory, junk] = uigetfile({'*.zip;*.tar;*.gz;'},...
    'Select Python Archived File (*.zip,*.tar,*.gz)');
  if isequal(file,0) || isequal(archivedDirectory,0)
    result = 'Aborting archived configuration.';
    return
  end
end



supported_archives = {'pls_toolbox_mac_38.tar.gz', ...
                      'pls_toolbox_mac_arm_38.tar.gz',...
                      'pls_toolbox_windows_38.zip',...
                      'pls_toolbox_linux_38.tar',...
                      'pls_toolbox_mac_310.tar.gz',...
                      'pls_toolbox_mac_arm_310.tar.gz',...
                      'pls_toolbox_windows_310.zip',...
                      'pls_toolbox_linux_310.tar'...
                      };
% error if file does not exist
if ~ismember(file,supported_archives)
  %print supported_archives
  error('The archived file chosen is not supported.')
  return
else
  archivedFile = file;
  orig_dir = pwd;
  cd(archivedDirectory);
end

waitbar(0.4,waitbarhandle,'Extracting Python files, give this a couple of minutes...');
pause(1);
pyname = split(archivedFile,'.');
pyname = pyname{1};
pyver = split(insertAfter(pyname,'3','.'),'_');
pyver = pyver{end};
% file exists, extract Python
switch computer
  case 'MACI64'
    untar(archivedFile);
    % dynamic links are not conserved, directly point to app
    pythonPath = [archivedDirectory '/' pyname '/bin/python' pyver];
  case 'MACA64'
    untar(archivedFile);
    % dynamic links are not conserved, directly point to app
    pythonPath = [archivedDirectory '/' pyname '/bin/python' pyver];
  case 'PCWIN64'
    unzip(archivedFile);
    pythonPath = [archivedDirectory '\' pyname '\python'];
  case 'GLNXA64'
    % untar doesn't seem to work well here, use system to untar
    system(['tar -xzf ' archivedFile]);
    % dynamic links are not conserved, directly point to 3.8 app
    pythonPath = [archivedDirectory '/' pyname '/bin/python' pyver];
end

waitbar(0.75,waitbarhandle,'Passing path the to MATLAB pyenv function...')

pyenv('Version',pythonPath,'ExecutionMode','InProcess')

%Save path to executable in case it's lost (known mac issue).
setplspref('prep_pyenv','executable',pythonPath);

% Make sure Python uses its own libraries, and not Matlab's
set_pyenv_flags;
result = 'Your pyenv was configured successfully!';
cd(orig_dir);
end
%-------------------------------------------------------------------------%

function [success,waitbarhandle] = handle_dynamic_links(waitbarhandle)
%Make symbolic link to libgfortran.3.dylib so scipy works correctly.
if isdeployed && ismac
  try
    waitbar(0.95,waitbarhandle,'Adding symlink to Conda libgfortran.3.dylib file for Mac.');
    pause(2)%So user can see the message.
    mcr_root = matlabroot;%MCR root folder. mcr_root = '/Applications/MATLAB/MATLAB_Runtime/v99'

    %This file will not be a symlink to begin with. But if a user runs
    %config twice without a rollback then this will be a symlink.
    mlliblocation = fullfile(mcr_root,'sys','os','maci64','libgfortran.3.dylib');%MCR libgfortran.3.dylib location.
    mllib_flag = 0;%0=doesn't exist, 1=isfile, 2=issymlink

    %In some environments exist will resolve a symlink and sometimes not.
    %So go through this logic to find real status.
    if exist(mlliblocation)
      mllib_flag = 1;
    end

    %Try following symlink.
    [junk, mylink] = system(['readlink ' mlliblocation]);
    if ~isempty(mylink)
      mllib_flag = 2;
    end

    if mllib_flag==0
      %Can't find libgfortran.3.dylibd file as real file or symlink.
      evrierrordlg(['The following MATLAB dylib location can''t be found:  ' newline mlliblocation newline 'Contact helpdesk@eigenvector.com'], 'MATLAB DYLIB Location Error');
    end

    %We can't be sure what version of python is being used so try to do a
    %search that doesn't rely on knowing python version.
    pe = pyenv;
    [junk,scipyliblocation] = system(['find ' char(pe.Home) ' -name "libgfortran.3.dylib"']);

    %Usually finds 2 locations, one for numpy and one for scipy.
    scipyliblocation = str2cell(scipyliblocation);
    myloc = ~cellfun(@isempty,(strfind(scipyliblocation,'scipy')));
    if any(myloc)
      scipyliblocation = scipyliblocation{myloc};
    else
      scipyliblocation = '';
      evrierrordlg('Error occured when creating a symlink for libgfortran.3.dylib so scipy works correctly. Contact helpdesk@eigenvector.com.', ...
        'Symlink for MAC Error');
    end
  catch E
    evrierrordlg(['Error occured when creating symlink: ' E.message newline 'Error in line: ' num2str(E.stack.line) newline...
      'Conda lib location: ' scipyliblocation newline 'Matlab lib location: ' mlliblocation]);
  end

  %Assuming that the scipyliblocation will always be a real file and
  %resolve by the exist() function.
  if exist(scipyliblocation)
    if mllib_flag==1
      %The original file is not symlink so move existing file to .bak so
      %link can be undone.
      movefile(mlliblocation,fullfile([mlliblocation '.bak']));
    end

    if mllib_flag==2
      %An old symlink file exists. Delete it and refresh the link.
      delete(mlliblocation);
    end

    %Having some trouble with getting this to work. Wrap it a few times
    %to propagate out the problem.
    try
      %Create (or refresh) the symlink to scipy.
      [success] = system(['ln -s ' scipyliblocation ' ' mlliblocation]);
    catch E
      evrierrordlg(['Error occured when creating symlink: ' E.message newline 'Error in line: ' num2str(E.stack.line) newline...
        'Conda lib location: ' scipyliblocation newline 'Matlab lib location: ' mlliblocation]);
    end

    if success>0
      evrierrordlg(['Error occured when creating symlink: ' msg newline ...
        'Conda lib location: ' scipyliblocation newline 'Matlab lib location: ' mlliblocation]);
    end

  end
else
  success = 0;
end
end
%-------------------------------------------------------------------------%

function [status] = checkCondaArchitecture()
status = 0;
% Only needed for mac osx86_64 and arm64
if ismac
  [~, stdout] = system([executeCondaConfigFiles 'conda info | grep platform']);
  stdout = split(strtrim(stdout),' : ');
  arch = stdout{2};
  if strcmpi(computer,'MACI64') && strcmpi(arch,'osx-64')
    status = 1;
  elseif strcmpi(computer,'MACA64') && strcmpi(arch,'osx-arm64')
    status = 1;
  end
end
end
%-------------------------------------------------------------------------%

function checkcondaprocess(timerhandle, EventData, Cmd)
starttime = timerhandle.UserData.starttime;
maxtime = timerhandle.UserData.maxtime;
fig = findall(groot,'Tag','pythonconfigureprog');
if ~isempty(fig)
  texth = findall(fig,'Type','UIControl');
else
  texth = [];
end
switch Cmd
  case 'check'
    [status,stdout] = system('powershell Get-Process ''conda-env''');
    if status~=0
      if contains(stdout,'Cannot find a process with the name "conda-env"')
        %process is done
        if ~isempty(texth) && ~isempty(fig)
          txt = [get(texth,'String');{'Conda is done building'}];
          set(texth,'String',txt);
          set(texth,'Value',length(txt));
        end
        stop(timerhandle);
      end
    else
      %process is still running
      numsecondsrunning = ceil(seconds(datetime('now') - starttime));
      if ~isempty(texth) && ~isempty(fig)
          txt = [get(texth,'String');{['Pulse. Conda still building environment after ' num2str(numsecondsrunning) ' seconds ...']}];
          set(texth,'String',txt);
          set(texth,'Value',length(txt));
      end
      if numsecondsrunning >= maxtime
        if ~isempty(texth)
          txt = [get(texth,'String');{['Maximum time of ' num2str(maxtime) ' seconds reached. Aborting Conda build.']}];
          set(texth,'String',txt);
          set(texth,'Value',length(txt));
        end
        stop(timerhandle);
      end
    end
  case 'stop'
    system('powershell .\stop_windows.ps1');
    fig = findall(groot,'Tag','pythonconfigureprog');
    if ~isempty(fig)
        texth = findall(fig,'Type','UIControl');
        if ~isempty(texth)
          txt = [get(texth,'String');{'Notes about the build process have been sent to a log file.'}];
          txt = {txt{:} 'View this log file if any issues arise and provide it to the helpdesk:'};
          txt = {txt{:} [pwd filesep 'output.log']};
          set(texth,'String',txt);
          set(texth,'Value',length(txt));
        end
    end
end
end
%-------------------------------------------------------------------------%

function config(varargin)
  mytimer = varargin{1};
  inputcmd = varargin{3};
  cmd = ['start .\run.vbs powershell -WindowStyle hidden -ExecutionPolicy ByPass .\' inputcmd];
  system(cmd);
  % create infobox for displaying information about configuration
  o = infobox('options');
  o.figurename = 'Python Configuration Progress';
  txt = {['Python configuration process has started. Maximum time allotted is ' num2str(ceil(mytimer.UserData.maxtime/60)) ' minutes.']};
  txt = {txt{:} 'Monitor this window to view progress of the build.'};
  txt = {txt{:} 'Conda build will be monitored after 60 seconds, and then continue to check about every 10 seconds.'};
  txt = {txt{:} ''};
  txt = {txt{:} '------------------------------------Progress of build will be shown below------------------------------------'};
  txt = {txt{:} ''};
  txt = {txt{:} 'Pulse. Conda building environment ...'};
  fig = infobox(txt,o);
  set(fig,'Tag','pythonconfigureprog');
end