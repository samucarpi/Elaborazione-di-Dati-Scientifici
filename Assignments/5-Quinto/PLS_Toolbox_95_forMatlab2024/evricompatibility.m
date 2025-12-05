function [pds, badprods, errmsg] = evricompatibility(cmode)
%EVRICOMPATIBILITY Tests for inter-product compatibility of Eigenvector toolboxes
%
% Return structure 'pds' of products which would be installed (mode='install')
% or products which are on the path (mode='debug').
% Products which are incompatible because their version is too old are 
% not included in 'pds' but are included in 'badprods' instead. 
%          
% Output:  
% INPUTS:
%     mode = ['install' | 'debug' | 'list'] indicate which usage mode. If
%                                           'list' then compatibility
%                                           matrix is returned.
%            if mode = 'matlab' then only the matlab version is checked and
%            the output "errmsg" will contain any error message regarding
%            incompatibility
%
% OUTPUTS: 
%      pds = products to install or are on path, excluding PLS_Toolbox
% badprods = products which are too old to be compatible with this version
%   errmsg = text message describing products which failed compatibility.
% 
%I/O: [pds, badprods, errmsg] = evricompatibility(mode)
%I/O: [compatibility_table] = evricompatibility('list')
%
%See also: EVRIINSTALL

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% Verify the input array of products to install are compatible with this PLS_Toolbox release
% and delete from the array those which are found incompatible. 
% The required minimum version number for each product is set in the
% function "getevricompatibility". 
% For example, if the minimum required version for MIA_Toolbox is 2.8.4 then
% it needs 2.8.4 and will complain if you only have 2.8.3 or earlier. The
% minimum required version = 2.8 (equivalent to 2.8.0) means 2.8, 2.8.1 or 
% later would be okay.

if nargin==0
  cmode = 'install';
end

silent    = false;
pds       = [];
badprods  = [];
errmsg    = [];
if isempty(cmode) | ~ischar(cmode)
  error('evricompatibility: input argument must be char');
end

try
  switch lower(cmode)
    case 'install'
      pds = prodtoinstall;
    case 'debug'
      silent = true;
      pds = prodonpath;
    case 'list'
      pds = getevricompatibility(1);
      return
    case 'matlab'
      pds = [];
    otherwise
      errmsg = {'evricompatibility: Unknown input mode'};
  end
  
  %Get path of current mfile. Install should be taking place from inside
  %toolbox folder after it has been unzipped.
  mypath = fileparts(which(mfilename));
  
  %Read the pre-assigned evri compatibility information
  compatibilities = getevricompatibility;  
  if length(compatibilities)==0   % Nothing to check for
    return;
  end
  [release,baseproduct,epath] = evrirelease;
  dlgname = [baseproduct ' Compatibility Check'];

  if strcmpi(cmode,'matlab')
    %check Matlab compatibility first
    mlmin = find(ismember({compatibilities.product},'MATLAB_MIN'));
    mlmax = find(ismember({compatibilities.product},'MATLAB_MAX'));
    if ~isempty(mlmin)
      minver = encodeversion(compatibilities(mlmin).minrelver);
    else
      minver = [0 0];
    end
    if ~isempty(mlmax)
      maxver = encodeversion(compatibilities(mlmax).minrelver);
    else
      maxver = [0 0];
    end
    mlversion = encodeversion(version);
    mlstatus = '';
    if mlversion(1)<minver(1) | (mlversion(1)==minver(1) & mlversion(2)<minver(2))
      %MATLAB TOO OLD
      mlstatus = 'TOO OLD';
    end
    if mlversion(1)>maxver(1) | (mlversion(1)==maxver(1) & mlversion(2)>maxver(2))
      %MATLAB TOO NEW
      mlstatus = 'TOO NEW';
    end
    
    if ~isempty(mlstatus)
      % Found product(s) incompatible with this PLS_Toolbox release. Do not abort installation.
      errmsg = {['Matlab version is ' mlstatus]};
    end
    pds = [];
    return;
  end
  
  %check other product comapatibility  
  badprods = [];
  badpds_index = [];
  msg1 = [baseproduct ' Found Incompatible Software:'];
  msg2 = 'Product                Release             Minimum Required Ver.';
  msg4 = 'These products will not be installed.';
  errmsg = {msg1; msg2};  
  % Check over all Eigenvector products found in sibling directories.
  for ip=1:length(pds)
    testprod = pds(ip).product;
    testrel = pds(ip).release;
    % get minimum required release version for this product from compatibilities matrix
    minrelver = '';
    for jprod=1:length(compatibilities)
      if strcmp(testprod, compatibilities(jprod).product)
        minrelver = compatibilities(jprod).minrelver;
        break;
      end
    end
    
    % compare testrel and minrelver
    minvercode = encodeversion(minrelver);%Get version vector.
    testvercode = encodeversion(testrel);%Get version vector.
    % pad to the right to ensure they have the same depth of version numbers
    dlen = length(minvercode) - length(testvercode);
    if dlen > 0 % minvercode is longer
      testvercode = [testvercode zeros(1,dlen)];
    elseif dlen < 0         % testvercode is longer
      minvercode = [minvercode zeros(1,-dlen)];
    end
    
    [junk indx] = sortrows([minvercode; testvercode]);
    % testrel is higher than minrelver if indx(1) == 1, so is compatible
    if indx(1) ~= 1
      badpds_index(end+1) = ip;
      badprod.product = testprod;
      badprod.release = testrel;
      badprod.minrel = minvercode;
      badprods = [badprods badprod];
      msg3 = sprintf('%s       %s                  %s ', testprod, testrel, minrelver);
      errmsg(size(errmsg,1)+1,1) = {msg3};
    end
  end

  if ~isempty(badprods)
    % Found product(s) incompatible with this PLS_Toolbox release. Do not abort installation.
    errmsg(size(errmsg,1)+1,1) = {msg4}; 
    if ~silent
      errordlg(errmsg, dlgname);
    end
    pds(badpds_index) = [];     % remove the incompatible product(s) from pds
  end
catch
  if exist('mypath')
    cd(mypath)
  end
  h = warndlg({['Non-Fatal Installation Problems Exist -'],...
    ['An error occurred trying verify compatibility of additional Eigenvector products. '...
    'Please contact Eigenvector Research via e-mail at: helpdesk@eigenvector.com for additional assistance.']});
  beep
  set(h,'windowstyle','modal');
  waitfor(h);
end

%--------------------------------------------------------------------------
function compatibilities = getevricompatibility(listonly)
%GETEVRICOMPATIBILITY Returns Eigenvector product compatibility version numbers
% Note: 2.0 is equivalent to 2.0.0
% Update these entries for new releases
% If listonly flag given returns camptiblity matrix.
%
%   MATLAB 7.12	R2011a
%   MATLAB 7.13	R2011b
%   MATLAB 7.14	R2012a
%   MATLAB 8	  R2012b
%   MATLAB 8.1	R2013a
%   MATLAB 8.2	R2013b
%   MATLAB 8.3	R2014a
%   MATLAB 8.4	R2014b
%   MATLAB 8.5	R2015a
%   MATLAB 8.5	R2015aSP1
%   MATLAB 8.6	R2015b
%   MATLAB 9.0	R2016a
%   MATLAB 9.1	R2016b
%   MATLAB 9.2	R2017a
%   MATLAB 9.3	R2017b
%   R2018a (MATLAB 9.4) 
%   R2018b (MATLAB 9.5) 
%   R2019a (MATLAB 9.6) 
%   R2019b (MATLAB 9.7) 
%   R2020a (MATLAB 9.8) 
%   R2020b (MATLAB 9.9) 
%   R2021a (MATLAB 9.10) 
%   R2021b (MATLAB 9.11) 
%   R2022a (MATLAB 9.12) 
%   R2022b (MATLAB 9.13) 
%   R2023a (MATLAB 9.14) 
%   R2023b (MATLAB 23.2)
%   R2024a (MATLAB 24.1)
%   R2024b (MATLAB 24.2)

%See if matrix is available from web.
compatmatrix = getcompatibilitymatrix;

if isempty(compatmatrix)
  compatmatrix = {
    'PLS_Toolbox' 'MIA_Toolbox' 'MATLAB_MIN'  'MATLAB_MAX'
    '9.5'         '3.1'         '9.7'         '24.2'
    '9.3.1'       '3.1'         '9.6'         '24.1'
    '9.3'         '3.1'         '9.5'         '23.2'
    '9.2.1'       '3.1'         '9.4'         '23.2'
    '9.2'         '3.1'         '9.3'         '9.13'
    '9.1'         '3.1'         '9.3'         '9.13'
    '9.0'         '3.1'         '9.1'         '9.11'
    '8.9'         '3.0.9'       '8.3'         '9.10'
    '8.8'         '3.0.8'       '8.3'         '9.8'
    '8.7.1'       '3.0.7'       '8.3'         '9.7'
    '8.7'         '3.0.7'       '8.3'         '9.6'
    '8.6.2'       '3.0.6'       '7.14'        '9.4'
    '8.6.1'       '3.0'         '7.14'        '9.4'
    '8.6'         '3.0'         '7.14'        '9.3'
    '8.5'         '3.0'         '7.14'        '9.3'
    '8.2'         '3.0'         '7.12'        '9.1'
    '8.1.1'       '3.0'         '7.9'         '9.0'
    '8.1'         '3.0'         '7.9'         '8.6'
    '8.0.2'       '3.0'         '7.9'         '8.6'
    '8.0'         '3.0'         '7.9'         '8.5'
    '7.9'         '2.9.2'       '7.6'         '8.5'
    '7.8'         '2.9'         '7.6'         '8.3'
    '7.5'         '2.8.4'       '7.4'         '8.3'
    '7.3'         '2.8.4'       '7.2'         '8.2'
    '7.0'         '2.8'         '7.0'         '8.2'
    '6.7'	        '2.7'	        '7.0'         '7.14'
    '6.2'	        '2.5'	 	      '6.5'         '7.12'
    '6.0.1'      	'2.0.2'	      '6.5'         '7.11'
    '6.0'         '2.0.2'       '6.5'         '7.11'
    '5.8'         '2.0.0'       '6.5'         '7.11'
    };
  % evricompatibility not present before pls_toolbox 5.8

  %Use this code to update CSV file during release. Place CSV file on
  %server manually at:
  %  https://www.software.eigenvector.com/versiontable/evricompatibilitytable.csv
  %
  %thistbl = cell2table(compatmatrix);
  %writetable(thistbl,'evricompatibilitytable.csv')

end

if nargin>0 & listonly
  compatibilities = compatmatrix;
  return
end

% get the current PLS_TOOLBOX release number
[release,product,epath] = evrirelease;
if strcmpi(product, 'mia_toolbox')
  compatibilities = [];    
  % Do not check other products for compatibility with MIA_Toolbox
  return;
end

% Get the row for this PLS_Toolbox release in the compatmatrix.
% If no match is found for this release then search backwards for earlier releases
i0 = getCompatibilityRow(compatmatrix, release);
relvec = encodeversion(release);
intval = array2int(relvec);
isNormalMode = true;
while i0 < 0
  relvec = encodeversion(release);
  if length(relvec) > 0
    % decrement release version's most minor integer value
    [relvec, intval, isNormalMode] = decrement(intval, isNormalMode);
  else
    break                           % Should never happen. But avoid infinite while.
  end
  release = decodeversion(relvec);
  i0 = getCompatibilityRow(compatmatrix, release);
end

% Get min release version associated with each evri product, and Matlab
compatibilities = [];
if i0>0         % so the matrix has an entry for the current PLS_Toolbox release
  for j=1:size(compatmatrix,2)
    if(strcmp(compatmatrix{1,j}, 'PLS_Toolbox'))
      continue;
    end
    c.product = compatmatrix{1,j};
    c.minrelver = compatmatrix{i0,j};
    compatibilities = [compatibilities c];
  end
end

%---------------------------------------------------------------------------------------------------
function i0 = getCompatibilityRow(compatmatrix, release)
%GETCOMPATIBILITYROW gets the row of compatmatrix matched to this release
% or returns -1 if no matching row found.
i0 = -1;
for i=1:size(compatmatrix,1)
  if(strcmp(compatmatrix{i,1},release))
    i0=i;
  end
end

%---------------------------------------------------------------------------------------------------
function out = encodeversion(str)
%ENCODEVERSION convert string version to numerical vector. '5.6.1' -> [ 5 6 1]
out = [];
rem = str;
while ~isempty(rem) & length(out)<3
  [n,rem] = strtok(rem,'.');  %parse for periods
  nonnum = min(find(n>'9'));%any non-numeric characters?
  if ~isempty(nonnum);
    n = str2num(n(1:nonnum-1))+double(n(nonnum:end))/256;  %convert to decimal
  else
    n = str2num(n);
  end
  out(end+1) = n;
end
if isempty(out);
  out = 0;
end
%---------------------------------------------------------------------------------------------------
function out = decodeversion(relvec)
%DECODEVERSION convert numerical vector version to string. [ 5 6 1] -> '5.6.1'
% relvec = [5 3 1] for ex
out = '';
len = length(relvec);
if len > 1
  for i=1:len-1
    out = [out num2str(relvec(i)) '.'];
  end
end
out = [out num2str(relvec(end))];



%---------------------------------------------------------------------------------------------------
function toinstall = prodtoinstall()
%PRODTOINSTALL Get products with directories which are siblings to the PLS_Toolbox directory.
%Current behavior is to install the PLS_Toolbox from (folder in) which
%installer is run plus the most current versions of all other products in
%the same parent folder.

%Search for all Eigenvector products.
try
  %Get path of current mfile. Install should be taking place from inside
  %toolbox folder after it has been unzipped.
  mypath = fileparts(which(mfilename));

  %Get path pieces so can step up one directory. Assumes all toolboxes will
  %be installed in same parent folder. Default of installer exe is
  %matlabXXX/toolbox
  pathpcs = strfind(mypath, filesep);

  %Generate parent path.
  parentpath = mypath(1:pathpcs(end));

  %Get list with 'dir' call to parent path.
  pfiles = dir(parentpath);

  %Remove files from list, search only directories.
  pfiles = pfiles(find([pfiles.isdir]==1));

  %Remove "." directories.
  remindx = [];
  for i = 1:size(pfiles,1)
    if ~strcmp(pfiles(i).name,'.') & ~strcmp(pfiles(i).name,'..')
      remindx = [remindx i];
    end
  end
  pfiles = pfiles(remindx);

  %Step through remaining directories looking for 'evrirelease.m'. Not
  %looking in sub folders of children, only one folder (child) down.
  pinfo = '';%Init variable to hold product info.
  for i = 1 : size(pfiles,1)
    sfolder = fullfile(parentpath, pfiles(i).name);%Current search folder.

    if exist(fullfile(parentpath, pfiles(i).name, 'evrirelease.m'), 'file');
      %If evrirelease is found, the Toolbox is 3.5+ generation. Retrieve
      %product/release info.

      try
        cd(sfolder);%Change to new folder.
        pinfo(end+1).folder = sfolder;%Add folder to list.
        %Run evrirelease from the current folder.
        [release,product] = evrirelease;
        %Stick results in 'product info' structure.
        pinfo(end).release = release;
        pinfo(end).product = product;
      catch
        cd(mypath);
      end

    elseif exist(fullfile(parentpath, pfiles(i).name, 'helppls.m'), 'file')
      %If evrirelease not found but helppls is, the Toolbox is pre 3.5
      %generation. Add generic info to the list.
      pinfo(end+1).folder = sfolder;%Add folder to list.
      pinfo(end).release = '3.0';
      pinfo(end).product = 'PLS_Toolbox';

    end

  end
  cd(mypath);%Go back to dir started in.
catch
  if exist(mypath)
    cd(mypath)
  end
  h = warndlg({['Non-Fatal Installation Problems Exist -'],...
    ['An error occurred trying locate additional Eigenvector products. '...
    'If you''re attempting to install additional products, they may need to be installed manually. '...
    'Please contact Eigenvector Research via e-mail at: helpdesk@eigenvector.com for additional assistance.']});
  beep
  set(h,'windowstyle','modal');
  waitfor(h);
end

uprods = unique({pinfo.product});%List of products.
toinstall = [];%List to install.

for j = uprods %Loop through products.
  %Don't search for PLS_Toolbox versions. Install Toolbox from where
  %installer is being run.
  if strcmp(j, 'PLS_Toolbox')
    continue
  end

  verlist = [];%Version list.
  verlixtidx = [];%Version list index.
  for k = 1:size(pinfo,2)
    if strcmp(char(j),pinfo(k).product)
      vercode = encodeversion(pinfo(k).release);%Get version vector.
      %Adjust size of version vector to add to list. Will need to pad with
      %zeros if longer version numbers are encountered along the way.
      if size(vercode,2)>size(verlist,2)
        zpad = zeros(size(verlist,1),size(vercode,2)-size(verlist,2));
        verlist = [verlist zpad];
      elseif size(vercode,2)<size(verlist,2)
        zpad = zeros(1,size(verlist,2)-size(vercode,2));
        vercode = [vercode zpad];
      end
      verlist = [verlist; vercode];%Construct list.
      verlixtidx = [verlixtidx; k];%Keep track of original index.
    end
  end

  if size(verlist,2)>2
    %If there are more than 2 columns, we have to deal with potential
    %alphanumeric version numbering in 1st and 2nd column. Subtract alpha
    %part out of column and add it to third column so the sort will work
    %correctly.
    minorbase1 = floor(verlist(:,1));
    minorbase2 = floor(verlist(:,2));
    subminor = (verlist(:,1)-minorbase1) + (verlist(:,2)-minorbase2) + verlist(:,3);
    verlist = [minorbase1 minorbase2 subminor];
  end

  %Sort the results and take the latest product
  [junk inx] = sortrows(verlist);
  inx = inx(end);
  toinstall = [toinstall pinfo(verlixtidx(inx))];
end

%---------------------------------------------------------------------------------------------------
function pds = prodonpath()
%PRODONPATH Get all evri products on path
pds = [];
release = '';
product = '';
epath   = '';
mypath = pwd;
vrs = which('evrirelease.m','-all');
for i = 1:length(vrs)
  cd(fileparts(vrs{i}));
  [release, product, epath] = evrirelease;
  pds(i).product = product;
  pds(i).release = release;
  pds(i).folder = epath;
end
cd(mypath);%Go back to dir started in.

%---------------------------------------------------------------------------------------------------
function str = vec2str(vec)
len = length(vec);
str = '[';
for i=1:len
  str = [str sprintf('%2d ', vec(i))]; 
end
str = [str ']'];

%---------------------------------------------------------------------------------------------------
function [arrval2, intval, isNormalMode] = decrement(intval, isNormalMode)
%DECREMENT decrements intval and returns an array representation of the intval digits.
% isNormalMode = true/false affect the length of the array returned when intval ending in 0.
% Examples:
% Input:  intval  isNormalMode      Output: arrval2   intval  isNormalMode
%         342     true                      [3 4 1]   341     true
%         341     true                      [3 4 0]   340     true
%         340     true                      [3 4]     340     false
%         340     false                     [3 3 9]   339     true
%         339     true                      [3 3 8]   338     true

if mod(intval,10)==0 & isNormalMode
  isNormalMode = false;
else
  isNormalMode = true;
end
if isNormalMode
  intval = intval - 1;
  if intval > 0
    arrval2 = int2arr(intval);
  else
    arrval2 = [];
  end
else
  arrval = int2arr(intval);
  arrval2 = arrval(1:end-1);
end

%---------------------------------------------------------------------------------------------------
function intval = array2int(vecval)
len = length(vecval);
intval = 0;
for i=1:len-1
  intval = (intval + vecval(i))*10; 
end
intval = intval+vecval(len);

%---------------------------------------------------------------------------------------------------
function arrval = int2arr(intval)
arrval = [];
ic = 1;
addLeadingZero = false;
if intval<10
  addLeadingZero = true;
end
while intval>0
  rem = mod(intval, 10);
  intval = floor(intval/10);
  arrval(ic) = rem;
  ic = ic+1;
end
arrval = fliplr(arrval);
if addLeadingZero
  arrval = [0 arrval];
end

%---------------------------------------------------------------------------------------------------
function ctbl = getcompatibilitymatrix()
%Get latest compatibility table from web. Only expected changes would be to
%latest version of MATLAB supported. If a version of MATLAB was released
%before hard-coded compatibility table was updated a warning will show. If
%PLS_Toolbox is compatible with newest MATLAB and website version of
%compatibility talbe is updated then [needless] warning will be avoided. 

%Only need to check once so make persistent.
persistent rawtbl

if ~isempty(rawtbl)
  ctbl = rawtbl;
  return
end

wopts = weboptions;
wopts.ContentType = 'text';

try
  rawtbl = webread('https://www.software.eigenvector.com/versiontable/evricompatibilitytable.csv','format','%s%s%s%s',wopts);
  rawtbl = textscan(rawtbl,'%s %s %s %s','Delimiter',',');
  rawtbl = [rawtbl{:}];
end

ctbl = rawtbl;





  
