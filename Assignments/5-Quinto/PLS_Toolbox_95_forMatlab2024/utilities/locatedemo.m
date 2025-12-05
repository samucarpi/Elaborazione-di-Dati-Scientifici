function file = locatedemo(lookfor)
%LOCATEDEMO Search common locations for a specific demo data file.
% Input is the filename to search for (with extension). Output is the full
% path to the given file. if file could not be found, output is an empty
% string.
%
%I/O: file = locatedemo(lookfor)

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if exist(lookfor,'file');
  file = which(lookfor);
  return
end
file = '';

if ~ismac
  %see if we might be deployed and can locate file in sub-folder of the
  %main application folder.
  sysfolder = getappdata(0,'systemfolder');
  while isempty(file) & length(sysfolder)>3
    %locate all sub-dirs in that folder
    dirs = dir(sysfolder);
    dirs = {dirs([dirs.isdir]).name};
    dirs = setdiff(dirs,{'.' '..'});
    
    %and check each for the file we need
    for j=1:length(dirs);
      testfile = fullfile(sysfolder,dirs{j},lookfor);
      if exist(testfile,'file')
        file = testfile;
        break;
      end
    end
    
    if isempty(file)
      %step up one folder if we can't find the file we need here
      sysfolder = fileparts(sysfolder);
    end
    
  end
else
  %Mac packaged differently so need different strategy of finding demo data.
  mydir = matlabroot; % Example: /Users/scottkoch/Desktop/work/LocalSVNR/solo/trunk/solomia_deploy/Solo_MIA.app/Contents/Resources/mcr
  try
    %If this bombs out then '' returned and correct error is given in
    %calling function.
    mydir = mydir(1:strfind(mydir, '.app')+3);%Retruns something like: /Users/scottkoch/Desktop/work/LocalSVNR/solo/trunk/solomia_deploy/Solo_MIA.app
    %Demo files are put in Solo.app/XXX_Data so only search to that level, depth = 2.
    [status, rslt] = system(['find "' mydir '" -depth 2 -name "*.mat"']);
    rslt = str2cell(rslt);
    for i = 1:length(rslt)
      thisfile = rslt{i};
      %Use file sep in search to make sure unique, wine.mat = gcwine.mat
      %without it.
      if strfind(thisfile,['/' lookfor])
        file = thisfile;
        break
      end
    end
  end
  
end


