function varargout = evrihelpconfig(hpath,action,fontsize)
%EVRIHELPCONFIG Configure info.xml file so help will work correctly. 
%  Optional input 'hpath' is the path to the folder that contains
%  'info.xml'. Otherwise will obtain path from parent directory.
%  Options input 'action' can be set to "reset" and will use info.xml.bak
%  to set info.xml back to factory default.
%
%I/O: evrihelpconfig
%I/O: evrihelpconfig(path)
%
%See also: 

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 08/15/05 hardcode help location folder name 'help'
%rsk 03/23/06 change warning to disp() so works better with installer.

if nargin<2;
  action = '';
end
if nargin==1 && strcmp(hpath,'reset');
  %make ('reset') just like ('','reset')
  action = 'reset';
  hpath = '';
end

%Get path
if nargin < 1 || isempty(hpath)
  hpath = fileparts(which(mfilename));
end

%reset special help files
if strcmp(action,'reset')
  resetinfo(hpath)
  resetsearch(hpath)
  return
end

%Get font size for help.
if strcmp(action,'getfont')
  try
    varargout{1} = sethelpfont([]);
  catch
    evrierrordlg(['Unable access CSS file (' which('main.css') '). Manually edit this file if you wish to change font size.'],'Help Font Size Warning')
  end
  return
end

%Set new font size for help.
if strcmp(action,'setfont')
  try
    sethelpfont(fontsize);
  catch
    evrierrordlg(['Unable access CSS file (' which('main.css') '). Manually edit this file if you wish to change font size.'],'Help Font Size Warning')
  end
  return
end

%Get version data. This command should work during evriinstall becuase it's
%called after path has been set.
[release,product,epath] = evrirelease;

%Get file contents.
hcell = readcell(fullfile(hpath ,'info.xml'));

%Get relative path of installation folder if in ML toolbox folder.
ifolder = findtbpath(hpath);

if mlver < 7.1
  %Older versions of ML don't support relative paths.
  hcell = changeloc(hcell,hpath,0);
else
  if mlver < 8 | (mlver > 7.99 & strcmp(action,'force'))
    %Newer versions of ML require relative paths.
    hcell = changeloc(hcell,hpath,1);
  end
end

%Reopen discarding orginal contents and put new text in. 
success = writecell(fullfile(hpath ,'info.xml'),hcell);
if ~success
  %disp('Could not modify XML help configuration file... Help may be misconfigured.');
end

%----------------------------------------------
function outcell = changeloc(hcell,hpath,rel)
%Replace each relative path with full path for icons.
%Replace help location path with full path depending on input 'rel'.
% hcell - cell array of stings containing file contents.
% hpath - path to info.xml, should be parent folder of function or given as
%         input.
% rel - [0 1] wether to use relative path in help location (1 = use relative).

ifolder = '';
if rel
  %Also try to use relative icon paths if product installed in ML toolbox
  %folder.
  ifolder = findtbpath(hpath);
end

%Get PLS_Toolbox main folder name.
[junk parent] = fileparts(hpath);

%Change locations in tags.
for tag = {'icon' 'help_location'}
  %Loop through xml for each tag and replace with current path.
  for i = 1:size(hcell,2)
    if strfind(hcell{i}, ['<' tag{:} '>']);
      [token, rem] = strtok(hcell{i},'<>');%cut to first tag.
      [ptoken, rem] = strtok(rem,'<>');%cut to closing tag.
      [pth name ext] = fileparts(ptoken);%extract file parts.
      if ~strcmp(name, 'helpicon')
        switch tag{:}
          case 'icon'
            if ~isempty(ifolder)
              hcell{i} = ['<' tag{:} '>' fullfile('$toolbox',ifolder, 'help', [name ext]) '</' tag{:} '>'];%rel location in help folder.
            else
              hcell{i} = ['<' tag{:} '>' fullfile(hpath, 'help', [name ext]) '</' tag{:} '>'];%location in help folder.
            end
          case 'help_location'
            if rel
%               hcell{i} = ['<' tag{:} '>' './help' '</' tag{:} '>'];%location in main folder.
%             elseif rel && ~ispc
              %Need parent folder using .. for NIX.
              hcell{i} = ['<' tag{:} '>' '../' parent '/help/' '</' tag{:} '>'];%location in main folder.
            else
              %help_location is a folder location not a file location.
              hcell{i} = ['<' tag{:} '>' fullfile(hpath, 'help') '</' tag{:} '>'];%location in main folder.
            end
        end
      end
    end
  end
end

outcell = hcell;
%----------------------------------------------
function ifolder = findtbpath(hpath)
%Find relative path if PLS_Toolbox is in Matlab toolbox folder. Return
%empty if can't find.
ifolder = '';
pos1 = strfind(hpath,'toolbox');
if pos1
  ifolder = hpath(pos1+8:end);
end

%----------------------------------------------
function out = mlver
out  = version;
out  = str2num(out(1:3));

%----------------------------------------------
function resetinfo(hpath)
%Put original info.xml back into file.

%Open file and read each line into cell array.
hcell = readcell(fullfile(hpath ,'info.xml.bak'));

fpath = fullfile(hpath ,'info.xml');
%Reopen discarding orginal contents and put new text in.
success = writecell(fpath,hcell);
if ~success
  disp('Could not modify XML help configuration file... Help may be misconfigured.');
end

%----------------------------------------------
function resetsearch(hpath)
%Remove search db. This actually just disables the search db functionality
%which will allow help files to be present in Matlab help but not be
%searchable upon restart after a help "reset".

hpath = fullfile(hpath,'help','helpsearch');

if exist(hpath,'dir')==7
  %NOTE: Can't remove .cfs file becuase it is locked by Matlab.
  rmfiles = {'deletable' 'segments'};
  for i = rmfiles
    delname = fullfile(hpath,i{:});
    if exist(delname,'file') == 2
      delete(delname)
    end
  end
end

%----------------------------------------------
function out = sethelpfont(fontsize)
%Change size of font in CSS file.

out = [];
myfile = which('load.css');
if isempty(myfile)
  return
end

hcell = readcell(myfile);

%New css from media wiki as of 2021. Need to find bod`y location and adjust.
bc_loc = strfind(hcell,'.mw-body-content{');%Body content location.
bc_loc = find(~cellfun(@isempty,bc_loc));
myline = [];
txt_loc = [];
myerr = false;%Flag for when to throw error, can't find either body content object or font size property.
if ~isempty(bc_loc)&&length(bc_loc)==1
  %Found (expected) one location for .mw-body-content. Search for font-size
  %property in json.
  for i = bc_loc:bc_loc+20;%Will always be in next few lines after mw-body-content object.
    %Default property def is:  font-size:0.875em;
    if strfind(hcell{i},'font-size:');
      txt_loc = i;
      break
    end
  end
else
  myerr = true;
end

if isempty(txt_loc)
  myerr = true;
end

if myerr
  error('Can''t locate font size in media wiki CSS file.')
end

thisline = hcell{txt_loc};
[fsline,myfs] = strtok(thisline,':');
if isempty(fontsize)
  %Report out font size.
  myfs(1)='';%Remove :
  myfs = strtrim(strrep(myfs,';',''));%Remove ; and trim any space.
  if strfind(myfs,'em')
    thisfs = strrep(myfs,'em','');
    thisfs = round(str2num(thisfs)*16);
  elseif strfind(myfs,'px')
    thisfs = strrep(myfs,'px','');
    thisfs = str2num(thisfs);
  else
    error('Unrecognized font size units, expecting px or em.');
  end
  out = thisfs;
  return
else
  %Setting fontsize.
  myfs = num2str(fontsize);
  if ~isempty(myfs)
    hcell{txt_loc} = [fsline ':' myfs 'px;'];
  else
    hcell{txt_loc} = [fsline ':16px;'];
  end
end
%Reopen discarding orginal contents and put new text in.
success = writecell(myfile,hcell);
if ~success
  error('Could not write to load.css for font size.');
end

%----------------------------------------------
function hcell = readcell(filepath)
%Get cell array of each line in a file.

%Open file and read each line into cell array.
fid = fopen(filepath,'rt');
frewind(fid);
hcell = {''};
while ~feof(fid)
  hcell = [hcell {fgetl(fid)}];
end
fclose(fid);

%Remove first empty cell.
hcell = hcell(2:end);

%----------------------------------------------
function success = writecell(filepath,hcell)
%Write cell to a file.
success = 1;
fid = fopen(filepath,'wt');
if fid>0;
  fprintf(fid, '%s\n',hcell{:});
  fclose(fid);
else
  success = 0;
end