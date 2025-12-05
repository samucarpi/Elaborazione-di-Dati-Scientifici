function mydso = addsourceinfo(mydso,mynames,mypath)
%ADDSOURCEINFO Store origin filename and path in DSO history field.
%
%
%I/O: mydso = addsourceinfo(mydso,mypath);
%I/O: mydso = addsourceinfo(mydso,mypath,mypath);
%I/O: mydso = addsourceinfo(mydso,'c:/path/filename.ext')
%I/O: mydso = addsourceinfo(mydso,{'c:/path/filename1.ext','c:/path/filename2.ext','c:/path/filename3.ext'})
%I/O: mydso = addsourceinfo(mydso,{'filename1.ext','filename2.ext','filename3.ext'},'c:/path/')
%
%See also: DATASET

% Copyright © Eigenvector Research, Inc. 2009
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB¨, without
%  written permission from Eigenvector Research, Inc.

if nargin<2
  error('ADDSOURCEINFO requires 2 inputs.')
end

if ~isdataset(mydso)
  return;
end

if nargin == 3
  %Passed path string separately.
  for i = 1:length(mynames)
    mynames{i} = fullfile(mypath,mynames{i});
  end
end

if iscell(mynames)
  for i = 1:length(mynames)
    mydso = addhistory(mydso,mynames{i});
  end
else
  mydso = addhistory(mydso,mynames);
end


%--------------------------------------------
function mydso = addhistory(mydso,filename)
%Add a single record into DSO history for a file name.

%Make sure we have a full path.
[p,f,e] = fileparts(filename);
if isempty(p)
  if exist(fullfile(pwd,filename),'file');
    %file is in the current directory
    filename = fullfile(pwd,filename);
  else
    %file is on path, use which to find it
    temp = which(filename);
    if ~isempty(temp)
      filename = temp;
    end
  end
end

%Create UNC file name. Only works on Windows systems.
fns = evriaddon('addsourceinfo_prefilter');
for j=1:length(fns)
  filename = feval(fns{j},filename);
end

mydso.history = ['Import From: ' filename];

