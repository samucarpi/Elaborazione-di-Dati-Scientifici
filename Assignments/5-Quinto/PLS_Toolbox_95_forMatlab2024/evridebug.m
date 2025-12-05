function varargout = evridebug(varargin)
%EVRIDEBUG Checks the PLS_Toolbox installation for problems.
%  Runs various tests on the PLS_Toolbox installation to assure
%  that all necessary files are present and not "shadowed" by
%  other functions of the same name.
%
%  This utility should be run if you experience problems with
%  the PLS_Toolbox.
%
%  EVRIDEBUG tests for:
%   * Missing PLS_Toolbox folders in path,
%   * Multiple versions of PLS_Toolbox,
%   * "Shadowed" files (duplicate named files), and
%   * Duplicate definitions of Dataset object.
%
%  The output (problems) is a cell containing the text of the
%  problems discovered. If no problems are encountered, (problems) will be
%  empty. Output (code) is a status code:
%       0 = no problems discovered
%       1 = non-fatal installation errors discovered
%       2 = fatal installation errors discovered
%
%I/O: [problems,code] = evridebug
%
%See also: EVRIINSTALL, EVRIRELEASE, EVRIUNINSTALL, EVRIUPDATE

% Copyright © Eigenvector Research, Inc. 2003
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%JMS 3/2003
%NBG 3/03 modified help
%JMS 3/03 generalized for complete MAC/UNIX compatibility
%JMS 4/03 generalized for different root folder name
%JMS 5/03 fixed bug on MAC/UNIX relating to upper-case root name
%JMS 7/03 added output of reported problems (for automatically run tests)
%JMS 5/04 modified test for dont-run-in-main-folder, changed some text
%JMS 12/04 added status code as output
%RSK 03/16/06 add additional folders to existence and shadow checks.
%RSK 05/31/06 add demos.p to ignore list for shadowed files so demo
%             versions don't show errors.

problem = {};
code = 0;
if (~exist('isdeployed') | ~isdeployed)
  %Move rehash to here (inside ~deployed) because causes 2020b compiled apps to hang. 
  rehash toolboxcache
  %not deployed AND not told not to bother checking
  [problem,code] = dotests(varargin{:});
end

if ~isempty(problem)
  disp('WARNING: Problem found with PLS_Toolbox installation')
  disp('   PLS_Toolbox functions may not operate as expected');
  disp('   unless these problems are solved (see suggestions).');
  disp(char(problem))
else
  disp('No PLS_Toolbox installation problems were identified.')
end

if nargout >0
  varargout = cell(1,nargout);  %fake output
  varargout{1} = problem;
  varargout{2} = code;
end

%====================================================================
function [problem,code] = dotests(varargin)

code = 0;  %indicates no problems

problem = cell(0);  %initialize list of identified problems

% pth = which('evriio');
% pth = fileparts(fileparts(pth));
pth = which('evridebug');
pth = fileparts(pth);  %drop filename
[pth,rootname,ext] = fileparts(pth);  %get top-level folder name
rootname = [rootname ext];  %include any "extension" (period in foldername)
if isempty(rootname); 
  rootname = 'pls_toolbox'; 
end

%Fix problem when toolbox is in root unix folder "/". Comparisons below end
%up having // at beginning.
if strcmp(pth,'/')
  pth = '';
end

%------------------------------------------------
% Test for not-installed PLS_Toolbox

if (nargin==1 & strcmp(varargin{1},'installing')) | exist('evrinetwork.lic','file');
  %skip this test if we actually installing at this very moment (or this is
  %a network installation)
  installed = 1;
else
  %test if we've been installed correctly
  prefs=getpref('PLS_Toolbox');
  %Use "evrirelease" and not "evrirelease('PLS_Toolbox')" below so we don't
  %get problems when installing with old versions on the path.
  if isfield(prefs,'evriinstall') & isfield(prefs.evriinstall,'version') & strcmp(prefs.evriinstall.version,evrirelease)
    installed = 1;
  else
    installed = 0;
  end
end

if ~installed
  problem(end+1) =  {'----------------------------------------------------'};
  problem(end+1) =  {'* Problem: '};
  problem(end+1) =  {'     Current PLS_Toolbox has not been installed correctly.'};
  problem(end+1) =  {'  Possible Solutions:'};
  problem(end+1) =  {'     A) Re-run the installation program "evriinstall"'};
  problem(end+1) =  {'     B) Delete the current files and reinstall all  '};
  problem(end+1) =  {'         the PLS_Toolbox files.'};
  if code<2; code = 2; end  %fatal error
  return
end

%------------------------------------------------
% Test for missing sub-folders on path

R = lower(path);

%PLS_Toolbox Directories
fs = filesep;
plsdirs = {'dems' 'help' 'utilities' ...
           'dft' ['dft' fs 'dems'] ['dft' fs 'utilities'] ...
           'optimize' ['optimize' fs 'dems'] ['optimize' fs 'help'] ...
           'peakfit' ['peakfit' fs 'dems'] ['peakfit' fs 'help'] ['peakfit' fs 'utilities']...
           ['robust' fs 'dems'] ['robust' fs 'help'] ['robust' fs 'libra_plstoolb']};

lookfor = {lower(rootname)};
for ii = 1:length(plsdirs)
  lookfor = [lookfor {lower([rootname fs plsdirs{ii}])}];
end
 
%lookfor = lower({rootname,[rootname filesep 'dems'],[rootname filesep 'help'],[rootname filesep 'utilities']});
found   = zeros(1,length(lookfor));

while ~isempty(R)
  [T,R]=strtok(R,pathsep);
  for k = 1:length(lookfor);
    if length(T)>=length(lookfor{k}) & strcmp(T(end-length(lookfor{k})+1:end),lookfor{k});
      found(k) = 1;
    end
  end      
end

if any(~found)
  problem(end+1) =  {'----------------------------------------------------'};
  problem(end+1) =  {'* Problem: '};
  problem(end+1) =  {'     Path is missing required folder(s)'};
  problem(end+1) =  {'  Possible Solutions:'};
  problem(end+1) =  {'     A) Re-run the installation program "evriinstall"'};
  problem(end+1) =  {'     B) Delete the current files and reinstall all  '};
  problem(end+1) =  {'         the PLS_Toolbox files.'};
  problem(end+1) =  {'  Missing folder(s):'};
  for k = find(~found)
    problem(end+1) = {['     ' lookfor{k}]};
  end
  if code<2; code = 2; end  %fatal error
end

%------------------------------------------------
% Test for multiple version of PLS_Toolbox

info = ver;

verlist = cell(0);
for j=1:length(info);
  if strcmp(lower(info(j).Name),'pls_toolbox');
    verlist(end+1) = {[info(j).Version ' ' info(j).Release]};
  end
end

if length(verlist)>1;
  problem(end+1) =  {'----------------------------------------------------'};
  problem(end+1) =  {'* Problem: '};
  problem(end+1) =  {'     Multiple versions of PLS_Toolbox concurrently installed'};
  problem(end+1) =  {'  Possible Solutions:'};
  problem(end+1) =  {'     A) Reinstall the PLS_Toolbox using "evriinstall". When asked,'};
  problem(end+1) =  {'        make sure you approve the removal of old versions from the path.'};
  problem(end+1) =  {'     B) Manually remove old versions from the path using "pathtool".'};
  problem(end+1) =  {'  Versions found:'};
  for k = 1:length(verlist)
    problem(end+1) = {['     ' verlist{k}]};
  end
  if code<1; code = 1; end  %non-fatal error
end

%------------------------------------------------
% Test for missing EVRIIO file (if found, use as
%  reference point to search for paths and shadowed files)

if isempty(which('evriio'))
  
  problem(end+1) =  {'----------------------------------------------------'};
  problem(end+1) =  {'* Problem: '};
  problem(end+1) =  {'     evriio.m (REQUIRED file!) could not be found on the path'};
  problem(end+1) =  {'  Possible Solutions: '};
  if any(~found)
    problem(end+1) =  {'     A) This may be due to the missing folders identified'};
    problem(end+1) =  {'        above. Solve the missing-folder problem first...'};
    problem(end+1) =  {'     B) Reinstall the PLS_Toolbox'};
  else
    problem(end+1) =  {'     A) Reinstall the PLS_Toolbox'};
  end
  if code<2; code = 2; end  %fatal error

end

%------------------------------------------------
% Test for other evri product compatibility with PLS_Toolbox
if nargin==1 & strcmp(varargin{1},'installing')
  %skip this test if installing since evriinstall did not add these bad toolboxes to the path
else
  [pds, badprods, errmsg] = evricompatibility('debug');
  if ~isempty(badprods)
    
    problem(end+1) =  {'----------------------------------------------------'};
    problem(end+1) =  {'* Problem: '};
    problem(end+1) =  {'     evri product incompatibility found for toolbox:'};
    problem(end+1) =  {'     Product            Release              Minimum Required Ver.'};
    
    for i=1:size(badprods,2)
      minrelstr = '';
      if length(badprods(i).minrel)>0
        minrelstr = num2str(badprods(i).minrel(1));
      end
      for j=2:length(badprods(i).minrel)
        minrelstr = [minrelstr '.' num2str(badprods(i).minrel(j))];
      end
      problem(end+1) = {sprintf('     %s       %s                  %s ', ...
        badprods(i).product, badprods(i).release, minrelstr)};
    end
    
    
    problem(end+1) =  {'  Possible Solutions: '};
%     if any(~found)
      problem(end+1) =  {'     A) remove incompatible toolbox(es) from your path'};
      if nargin>0 & strcmp(varargin{1},'installing')
        problem(end+1) =  {'     B) Reinstall the PLS_Toolbox'};
      end
%     else
%       problem(end+1) =  {'     A) Reinstall the PLS_Toolbox'};
%     end
    if code<2; code = 2; end  %fatal error
  end
end

%------------------------------------------------
% Shadowing tests (skipped if other problems already found)

if ~isempty(problem)
  problem(end+1) =  {'------------------------------'};
  problem(end+1) =  {'* Shadowing tests skipped due to previously identified problems.'};
  problem(end+1) =  {['   Solve these other problems first and rerun ' mfilename '.']};
else

  olddir = pwd;
  if ~isempty(strfind(lower(pwd),lower(rootname)))
    cd(matlabroot);  %don't run this in the pls_toolbox folder(s) or we'll miss "shadowing" problems
  end

  %------------------------------------------------
  % Test for shadowed dataset object

  shadowwarning = 0;  
  dsver = which('dataset/dataset');
  [PATHSTR,NAME,EXT] = fileparts(dsver);
  if ~strcmpi(PATHSTR,fullfile(pth, rootname, '@dataset'));
    if ~shadowwarning
      problem(end+1) =  {'----------------------------------------------------'};
      problem(end+1) =  {'* Problem: '};
      problem(end+1) =  {'     Extra Dataset object definition(s) found (@dataset folder)'};
      problem(end+1) =  {'  Possible Solutions: '};
      problem(end+1) =  {'     A) If there are two or more dataset objects present on your Matlab path '};
      problem(end+1) =  {'  the PLS_Toolbox parent folder (containing the @dataset folder) should be '};
      problem(end+1) =  {'  above all other copies of the dataset object on the Matlab path.'};
    end
  end

  %------------------------------------------------
  % Test for jar files.
  plsjarfiles = dir(fullfile(pth,rootname,'extensions','javatools','*.jar'));
  
  if isempty(plsjarfiles)
  
  problem(end+1) =  {'----------------------------------------------------'};
  problem(end+1) =  {'* Problem: '};
  problem(end+1) =  {'     No Java (.jar) files found in PLS_Toolbox/extensions/javatools folder.'};
  problem(end+1) =  {'  The model cache, XGB, and SVM will not work with supporting java files.'};
  problem(end+1) =  {'  Possible Solutions: '};
  problem(end+1) =  {'     A) Reinstall the PLS_Toolbox'};
  if code<2; code = 2; end  %fatal error

end

  
  %------------------------------------------------
  % Test cache database.
  goodconnection = 1;
  try
    %Test connection.
    cobj = modelcache('getcacheobj');
    if isempty(cobj)
      %Possible multiple connections.
      goodconnection = 0;
    else
      goodconnection = cobj.test;
    end
  catch
    goodconnection = 0;
  end
  
  if ~goodconnection
    problem(end+1) =  {'----------------------------------------------------'};
    problem(end+1) =  {'* Problem: '};
    problem(end+1) =  {'     Cannot connect to Model Cache database.'};
    problem(end+1) =  {'  Possible Solutions: '};
    problem(end+1) =  {'     A) Reset the modelcache from Workspace Browser window View/Reset Model Cache'};
    problem(end+1) =  {'        or, use the command:  modelcache(''reset'')'};
    problem(end+1) =  {'        or, Restart Matlab'};
    problem(end+1) =  {'     B) Turn off the modelcache from Workspace Browser window Edit/Options/Model Cache Settings'};
    problem(end+1) =  {'        Or, use the command: setplspref(''modelcache'',''cache'',''off'')'};
    problem(end+1) =  {'     C) Multiple instances of Matlab/Solo running. Only one instance of Matlab/Solo can access the Model Cache'};
    problem(end+1) =  {'        at one time. The Model Cache will be automatically turned off until connection can be re-established.'};
  end
  
  %-----------------------------------------------------
  % Test for shadowed files on path
  
  shadowwarning = 0;  %flag saying we've already given "shadow" warning header
  
  lookfor = {lower(rootname)};
  for ii = 1:length(plsdirs)
    if isempty(strfind(plsdirs{ii},'help'))
      lookfor = [lookfor {lower([rootname fs plsdirs{ii}])}];
    end
  end
  
  
  %lookfor = {rootname, [rootname filesep 'dems'], [rootname filesep 'utilities']};
  for k = 1:length(lookfor)  
    %get list of files and make sure each is "which"ed to this path
    thispath = fullfile(pth,lookfor{k});
    files    = dir(fullfile(thispath, '*.*'));
    files([files.isdir]) = [];
    for j=1:length(files);
      if ~isempty(deblank(files(j).name))
        [PATHSTR,NAME,EXT] = fileparts(which(files(j).name));
        if ismember(files(j).name,{'load.bmp' 'save.bmp' 'paint.mat' 'select.bmp'}) & ~isempty(findstr(NAME,'Java method'))
            %These ones will appear as overloaded Java methods in 7.3 -
            %ignore them.
            %Remove this code if TMW fixes bug.
            continue
        end
        if ~isempty(NAME) & ~ismember(lower([NAME EXT]),{'contents.m' 'readme.m' 'evrirelease.m' 'info.xml' 'demos.m' 'demos.p'}) & ~strcmp(lower(PATHSTR),lower(thispath))
          if ~shadowwarning
            problem(end+1) = {'----------------------------------------------------'};
            problem(end+1) = {'* Problem: '};
            problem(end+1) = {'     Some PLS_Toolbox files are "shadowed" by files with the same name.'};
            problem(end+1) = {'  Possible Solutions: '};
            problem(end+1) = {'     A) Remove/Rename the duplicate file(s)'};
            problem(end+1) = {'     B) Move the identified folder below the PLS_Toolbox folders'};
            problem(end+1) = {'         using the Matlab command "pathtool"'};
            problem(end+1) = {'     C) Remove the identified folder from the path using "pathtool"'};
            problem(end+1) = {'  Shadowed file(s):'};
            shadowwarning = 1;
          end
          problem(end+1) = {['     ' files(j).name '   (duplicate file in  ' PATHSTR ' )']};
          if code<1; code = 1; end  %non-fatal error
        end
      end
    end
  end
  
  cd(olddir)
  
end
