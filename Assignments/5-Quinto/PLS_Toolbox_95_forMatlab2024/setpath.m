function failure=setpath(flag)
%SETPATH Modifies and saves current directory to the MATLAB search path.
%  SETPATH will modify the MATLAB path to include the
%  current directory and all subdirectories and will
%  save the path to the pathdef.m file.
%
%  The optional input (flag) can be:
%     0 = only the current directory is added
%     1 = add the current directory and all sub-folders to the path top
%     2 = tries to move dems/help/uts to top of path.
%     3 = current folder and sub-folders are added BELOW any currently
%         installed PLS_Toolbox folders.
%
%I/O: failure = setpath(flag)
%
%See also: EVRIINSTALL, EVRIUNINSTALL

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%jms 3/18/04 -skip folders which start with "."
%jms 03/24/06 -add flag = 2 options for moving dems/help/uts to top.

if nargin<1,  flag = 1; end
s = pwd;
switch flag
case 0
  addpath(s);
otherwise %{default}
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
  
    if flag==3
      %flag 3 means put this folder BELOW currently installed PLS_Toolbox
      startpath = path;
      evpath = fileparts(which('evriinstall'));
      if ~isempty(evpath)
        while ~isempty(startpath);
          [one,startpath] = strtok(startpath,';');
          if ~isempty(strfind(one,evpath));
            toadd = [{one};toadd];
          end
        end
      end
    end      
    
  toadd = flipud(toadd);
  for j=1:length(toadd);
    addpath(toadd{j});
  end
  
  if flag==2
    %Flag for moving dems/help/utilities to top of path.
    %Assumes first directory for 'cd' call above is parent dir.
    [parent] = strtok(opath,pathsep);
    movedirs = {'utilities','help','dems'};%added to list in decending order.
    for ii = 1:length(movedirs)
      if exist(fullfile(parent,movedirs{ii}));
        addpath(fullfile(parent,movedirs{ii}));
      end
    end
    addpath(parent);
  end
  
end

try
  if checkmlversion('<','7')  %release <14?
    f = path2rc;
  else
    f = savepath;
  end
catch
  f = -1;
end

if nargout>0
  failure = f;
else
  switch f
    case 0
      disp([s,' Successfully added to the path and saved.'])
    case 1
      disp([s,' Added to the path but NOT saved.'])
    otherwise
      disp([s,' Problem encoutered when saving the path.'])
  end
end
