function evrimovepath(mode)
%EVRIMOVEPATH Move all Eigenvector products to the top or bottom of the Matlab path.
% Input 'mode' can be 'top' or 'bottom', when 'bottom' a warning comes up
% notifying user that function will not work properly.
%
%I/O: evrimovepath(mode)
%
%See also: EVRIINSTALL, SETPATH

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk

%Use code from evriinstall and setpath.

curdir = pwd;
mypath = fileparts(which('evriinstall'));
pds = evricompatibility('debug');%Get installed toolboxex.

switch mode
  case 'top'
    cd(mypath);
    setpath(2);%Use flag input to setpath to move dems/uts/help folders to top of path.
    
    for jj = 1:length(pds)
      cd(pds(jj).folder);
      setpath(2);%Use flag input to setpath to move dems/uts/help folders to top of path.
    end
    if ~isempty(pds)
      %now re-add PLS_Toolbox at top
      cd(mypath);
      setpath(2);%Use flag input to setpath to move dems/uts/help folders to top of path.
    end
    
  case 'bottom'
    cd(mypath);
    setpath_bottom;
    
    for jj = 1:length(pds)
      cd(pds(jj).folder);
      setpath_bottom;
    end
    evriwarndlg({['PLS_Toolbox folders have been moved to the bottom of the Matlab path. '...
      'Functions may not work properly until folders are moved back to the top.'] ' ' ...
      'NOTE: Stats Toolbox owners will need the ''clear classes'' of the Matlab Dataset Object to work!!!'}...
      ,'PLS_Toolbox Folder Warning')
end
rehash toolboxcache;
cd(curdir);


%-----------------------------------------
function setpath_bottom
%Overload of setpath with 'end' flag when using addpath.

s = pwd;

s = genpath(s);  %generate path with sub-folders
opath = s;
toadd = {};
%add one at a time (testing for "bad" files)
while ~isempty(s);
  [onefolder,s] = strtok(s,pathsep);
  
  %check all parts of this path for illegal folders
  test = onefolder;
  [pth,name,ext] = fileparts(test);  %grab folder name
  use = ~isempty(onefolder) & (~isempty(name) | isempty(ext));   %as long as there is SOMETHING in name or NOTHING in ext, we can still use this path
  while length(pth)<length(test) & use;  %test = path when we reach the end of the path (C:\ or '')
    test = pth;
    [pth,name,ext] = fileparts(test);
    use = ~isempty(name) | isempty(ext);   %as long as there is SOMETHING in name or NOTHING in ext, we're OK
  end
  if use;  %if we didn't find a reason NOT to use this...
    toadd = [toadd; {onefolder}];  %remember to add it
  end;
end

toadd = flipud(toadd);
for j=1:length(toadd);
  addpath(toadd{j},'-end');
end

if checkmlversion('<','7')  %release <14?
  f = path2rc;
else
  f = savepath;
end


