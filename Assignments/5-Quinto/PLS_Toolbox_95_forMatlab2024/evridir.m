function edir = evridir(newhome)
%EVRIDIR Locate and or create EVRI home directory.
% The EVRI home directory is used to store PLS_Toolbox application data
% like model cache database and reports generated during analysis. This
% directory should be read/writeable by the current user. The default
% location is [user home directory]/EVRI. Using keyword 'backup' as first
% input will make copy the existing EVRI HOME folder in the parent folder.
%   
%I/O: edir = evridir; %Get current home directory.
%I/O: edir = evridir('select_new'); %Choose new home directory from dialog.
%I/O: edir = evridir('backup'); %Choose new home directory from dialog.
%I/O: edir = evridir(newhome); %Change home directory.
%
%See also: MODELCACHE

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 1 && ismember(newhome,evriio([],'validtopics')) %Help, Demo, Options
  options = [];
  options.evri_home_dir = '';%EVRI Home Directory.
  if nargout==0; evriio(mfilename,newhome,options); else; edir = evriio(mfilename,newhome,options); end
  return;
end

edir = '';

%Always use options in case SETPLSPREF used outside of this function.
opts = evridir('options');
if nargin == 0 && ~isempty(opts.evri_home_dir)
  %Call getdefaultdir to check for missing drive letter on windows.
  edir = getdefaultdir(opts.evri_home_dir);
  return
end

%Add new home dir.
if nargin == 1
  switch newhome
    case 'select_new'
      edir = evriuigetdir(getdefaultdir,'Select a Home Directory for EVRI Application Data');
      if edir==0
        return
      end
    case 'backup'
      %Make copy of evrihomedir within its parent folder.
      if isdir(opts.evri_home_dir)
        parentdir = fileparts(opts.evri_home_dir);
        backupdir = fullfile(parentdir,['EVRI_HOME_BACKUP_' datestr(now,30)]);
        [status,message,messageId] = copyfile(opts.evri_home_dir, backupdir, 'f');
        if status==0
          %Error occurred. 
          error(['An error occured trying to copy the EVRI HOME folder (' opts.evri_home_dir '). Try copying folder manually.'])
        end
        return
      else
        error('ERROR trying to create EVRI HOME backup folder. No EVRI HOME folder found. See EVRIDIR help for information on how to create a EVRI HOME folder.')
      end
      return
    otherwise
      %Change to new home.
      edir = newhome;
  end
end

if isempty(edir)  
  %Try and find a default location.
  edir = getdefaultdir;
end

if ~exist(edir,'dir')
  %Use java so file hierarchy is created if needed.
  myfileobj = java.io.File(edir);
  
  %Make sure home folder exists.
  if ~myfileobj.mkdirs 
    erdlgpls('Unable to create EVRI home directory. Please select a different directory or contact helpdesk@eigenvector.com')
    return
  end
end

setplspref(mfilename,'evri_home_dir',edir);

%----------------------------
function out = getdefaultdir(varargin)
%Get default home directory for the user.

if nargin>0
  out = varargin{1};
else
  out = '';
end

addhome = 0;
if isempty(out)
  %If we're getting the home directory for the first time we need to add
  %the EVRI root name.
  addhome = 1;
end


%Try and find a default location.
if ispc
  %XP:
  %HOMEPATH% \Documents and Settings\{username}
  %VISTA/WIN7:
  %HOMEPATH% \Users\{username}
  %LOCALAPPDATA% C:\Users\{username}\AppData\Local
  
  if isempty(out)
    %Try vista/win7/win8/win10
    out = getenv('LOCALAPPDATA');
  end
  
  if isempty(out)
    %Must be older than Vista.
    out = getenv('HOMEPATH');
  end
  
  if strcmp(out(1),'\')
    %No drive letter, check for HOMEDRIVE
    out = [getenv('HOMEDRIVE') out];
  end
  
  if strcmp(out(1),'\')
    %STILL No drive letter? need to prompt for local folder.
    mydir = evriuigetdir(pwd,'Please Select a Home Folder for Eigenvector application data (e.g., C:\Documents and Settings\{username}).');
    if ~isempty(mydir) & ~isnumeric(mydir)
      out = mydir;
    else
      evriwarndlg('No Home Folder set. Some application features will be disabled.','No Home Folder')
      out = '';
    end
  end
  
else
  if isempty(out)
    %Where the rest of the world keeps the home dir.
    out = getenv('HOME');
  end
end

if addhome
  out = fullfile(out,'EVRI');
end
