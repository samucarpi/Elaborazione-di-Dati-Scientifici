function [nodes, obj] = get_path_struct(obj,mypath)
%EVRITREE/GET_PATH_STRUCT - Get default node structure for given folder.
%   Build default .tree_data structure for file system. If mypath is empty then
%   get root directory. Don't show hidden files/folders.
%
% Copyright © Eigenvector Research, Inc. 2012
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

nodes = [];

if nargin<2 | isempty(mypath)
  %Find root folder.
  myroot = {matlabroot};
  count = 100;
  while count>0
    %Walk up the directory system until we get to a root.
    newpath = fileparts(myroot{end});
    if isempty(newpath) | strcmp(newpath,myroot{end})
      %can't go any further.
      break
    else
      myroot{end+1} = newpath;
    end
    count = count-1;
  end
  
  myroot = fliplr(myroot);%Start at root.
  mypath = myroot{1};
end

%Get dir and remove hidden files.
myfiles   = dir(mypath);
if ~isempty(myfiles)
  hidefiles = char({myfiles.name});
  hidefiles = hidefiles(:,1);
  myfiles   = myfiles(~ismember(hidefiles,'.'));
end

%Apply file filter.
if ~isempty(obj.file_filter)
  temp = myfiles([myfiles.isdir]==1);
  if ~isempty(myfiles);
    %look for these file extensions
    filetypes = obj.file_filter;
    filepattern = sprintf('\\%s$|',filetypes{:});
    filepattern = filepattern(1:end-1);
    %and filter filelist for those using regexp
    thesefiles = myfiles(~cellfun('isempty',regexp({myfiles.name},filepattern)));
    temp = [temp; thesefiles];
  end
  myfiles = temp;
end

%Sort folders to top.
[junk,idx] = sort([myfiles.isdir],'descend');
myfiles = myfiles(idx);

%Build structure.
for j = 1:size(myfiles,1)
  nodes(end+1).val = fullfile(mypath,myfiles(j).name);
  nodes(end).nam = myfiles(j).name;
  nodes(end).str = myfiles(j).name;
  nodes(end).icn = which('folder.gif');
  nodes(end).isl = false;
  nodes(end).chd = '/';
  nodes(end).clb = '';
  if ~myfiles(j).isdir
    %This is a file ('mat' 'm' 'other').
    fnlen = length(myfiles(j).name);
    myicon = which('file_icon.gif');
    if fnlen>4 & strcmpi(myfiles(j).name(end-3:end),'.mat')
      myicon = which('matfile.png');
    elseif fnlen>2 & strcmpi(myfiles(j).name(end-1:end),'.m')
      myicon = which('mfile.png');
    end
    nodes(end).icn = myicon;
    nodes(end).isl = true;
  end
end

%Add root_name and root_icon.
if ispc
  %Need to have root name be drive letter so expand to node will work.
  fsep = strfind(mypath,filesep);
  if ~isempty(fsep)
    mypath = mypath(1:fsep(1)-1);
  end
  obj.root_name = mypath;%Tree root name default.
else
  obj.root_name = '/';
end
obj.root_icon = which('topdrive.png');
obj.tree_data = nodes;
obj.path_sep  = filesep;

%-------------------------------------------------
function geticon
%Test code for getting system icons. 
%This doesn't seem to work on Mac.
ic = javax.swing.filechooser.FileSystemView.getFileSystemView.getSystemIcon(java.io.File(which('license_evri.htm')));
frame = javax.swing.JFrame; 
label = javax.swing.JLabel(ic); 
frame.getContentPane.add(label); 
frame.pack 
frame.show 

%Idea to get fancy icons: http://www.codebeach.com/2008/02/get-file-type-icon-with-java.html

