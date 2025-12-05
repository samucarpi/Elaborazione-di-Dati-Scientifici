function  evrijavasetup
%EVRIJAVASETUP Do  Java set-up, add jars to dynamic java classpath, etc.
%
% WARNING: running this also clears any existing global variables in cases
% where it updates the javaclasspath. This is because updateClasspathWithJar
% leads to a call to clear('java'), which clears all. This only happens if
% there is a new jar file to be added to the javaclasspath.
%
%I/O: evrijavasetup
%
%See also: EVRIJAVAMETHODEDT, EVRIJAVAOBJECTEDT, UPDATECLASSPATHWITHJAR

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Add jars to the dynamic javaclasspath.
%[junk,junk2, mypath] = evrirelease('PLS_Toolbox');
mypath = fileparts(which('evriinstall'));
jarfiles = dir(fullfile(mypath,'extensions','javatools','*.jar'));
if evriio('mia')
  %Add mia jars.
  mypath = fileparts(which('miainstall'));
  miajarfiles = dir(fullfile(mypath,'utilities','*.jar'));
  jarfiles = [jarfiles; miajarfiles];
end

jarfolders = evriaddon('evrijavasetup_jarfolder');
for jarfitem = 1:length(jarfolders)
  otherjarfiles = dir(fullfile(feval(jarfolders{jarfitem}),'*.jar'));
  jarfiles = [jarfiles; otherjarfiles];
end

jarfiles = {jarfiles.name};
for jarfile = jarfiles
  %Don't add hidden files. A user had copies of all .jar files as hidden files
  %(from some backup system) in the folder and it caused errors.
  if ~strcmp(jarfile{:}(1),'.')
    updateClasspathWithJar(char(jarfile));
  end
end

% When adding derby.jar
try
  if ismember('derby.jar', jarfiles)
    p = java.lang.System.getProperties;
    p.setProperty('derby.stream.error.file', fullfile(evridir,'derby.log'));
  end
end

% Add the javatools folder so .properties files are added to javaclasspath
evripath = fileparts(which('evriinstall'));
jardir = fullfile(evripath,'extensions','javatools');
javaaddpath(jardir);

