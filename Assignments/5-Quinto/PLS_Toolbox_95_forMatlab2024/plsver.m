function varargout = plsver(varargin)
%PLSVER Displays version information.
%
%I/O: plsver

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 06/02/04 Initial coding.
%jms 6/10/04 Added Release information
%   -use fixed-font for infobox

varargout = {};
spcstr = strvcat(' ','-----------------------------------------------------------------',' ');

%figure out copyright date
crdate = '';
try
  crdate = datestr(datenum(getfield(dir(fileparts(which('pls.m'))),'date')),'YYYY');
catch
  crdate = '';
end
if isempty(crdate)
  crdate = datestr(now,'YYYY');
end

if exist('isdeployed') & isdeployed
  [release,prodname]=evrirelease;%Solo creates its own version of evrirelease with only 2 outputs.
  %SOLO information 
  plsinfo = strvcat(...
    [prodname ' - Copyright (C) 2007 - ' crdate ' Eigenvector Research, Inc.'],...
    '  ',...
    ['License:  ' evriio('test')]...
    );

  %read build_info file
  if exist('build_info.m')
    info = build_info;
    for f = fieldnames(info)';
      value = info.(f{:});
      if ~iscell(value)  %(don't display contents if a cell)
        plsinfo = strvcat(plsinfo,sprintf('%s: %s',f{:},value));
      end        
    end
  else
    fname = fullfile(getappdata(0,'dllfolder'),'build_info.txt');
    if exist(fname,'file')
      [fid,msg] = fopen(fname,'r');
      if fid>0
        while ~feof(fid);
          plsinfo = strvcat(plsinfo,strrep(fgetl(fid),'=',': '));
        end
        fclose(fid);
      end
    else
      plsinfo = strvcat(plsinfo,sprintf('Version: %s ',release));
      if exist('overload_customization');
        plsinfo = strvcat(plsinfo,sprintf('Customization: %s\n',overload_customization));
      end
      
    end
  end
  plsinfo = strvcat(plsinfo,...
    ['Installation Path: ' getappdata(0,'systemfolder')],...
    ['DLL Path: ' getappdata(0,'dllfolder')],...
    ['MCR Path: ' fileparts(which(mfilename))],...
    ['Preferences Path: ' prefdir],...
    ['Current Path: ' pwd],...
    ['EVRI Home Directory: ' evridir]);

  tbxs = '';
  pths = '';

  mlverstr = [''];
  mllicstr = [''];

  matlabinfo = strvcat(spcstr,...
    'MATLAB(R). (c) 1984 - 2008 The MathWorks, Inc.  ',...
    'Deployment rights of this product are governed by a certain ',...
    'license agreement between Eigenvector Research, Inc. and MathWorks.');

else
  %PLS_Toolbox information
  [release,prodname,prodpath,rdate]=evrirelease;

  %Not sure why we don't use evrirelease info here but not changed for the
  %time being (2/10/17). Maybe change in future. -SK
  verstr = [];
  try
    %parse the entire ver struct.
    vinfo = ver;
    for i = 1:length(vinfo)
      if strcmpi(vinfo(i).Name,'pls_toolbox')
        verstr = vinfo(i);
        continue
      end
    end
  catch
  end
  if isempty(verstr)
    verstr.Version = '';
  end

  plsinfo = strvcat(...
    ['PLS_Toolbox - Copyright (C) 1995 - ' crdate ' Eigenvector Research, Inc.'],...
    '  ');
  try
    instinfo = evriinstall('info');

    if ~isempty(verstr.Version);
      % get pls_toolbox info
      plsinfo = strvcat(plsinfo,...
        ['Version: ' verstr.Version],...
        ['Release: ' verstr.Release],...
        ['Date: ' verstr.Date]);
    else
      %No version information found? Use install version only
      plsinfo = strvcat(plsinfo,...
        ['Release: ' instinfo.version]);
    end

    plsinfo = strvcat(plsinfo,' ',...
      ['Installation Type: ' instinfo.type],...
      ['License info: ' instinfo.license],...
      ['Installation Date: ' instinfo.date],...
      ['Installation Directory: ' fileparts(fileparts(mfilename('fullpath')))],...
      ['EVRI Home Directory: ' evridir]);
  catch
    plsinfo = strvcat(plsinfo,'Unable to retrieve license information: ',lasterr);
  end

  %path info
  pths = char(strread(matlabpath,'%s','delimiter',[pathsep '\n']));
  pths = strvcat(spcstr,'Current Path:',' ',pths);

  %toolbox info
  z = ver;
  r = '';for j=1:length(z); r = strvcat(r,['  ' z(j).Release]); end
  tbxs = strvcat(spcstr,'Available Toolboxes:',' ',[strvcat(z.Name) ones(length(z),1)*'   Version ' strvcat(z.Version) r]);

  mlverstr = ['MATLAB Version ' version];
  mllicstr = ['MATLAB License Number: ',license];

  matlabinfo = '';
  
end

%Cache info.
try
  cobj = evricachedb;
  cacheinfo = cobj.getstats;
catch
  cacheinfo = {'Not available'};
end

cachestr = strvcat('MODELCACHE INFORMATION: ',' ',cacheinfo{:},spcstr);

% Make reference string.
% Per our FAQ (http://www.eigenvector.com/faq/index.php?id=177)
% [Product] [Version] ([Year]). Eigenvector Research, Inc., Manson, WA USA 98831; software available at http://www.eigenvector.com. 
% PLS_Toolbox with MIA_Toolbox 8.2.1 (2016). Eigenvector Research, Inc., Manson, WA USA 98831; software available at http://www.eigenvector.com. 

refstr = 'Reference Information: ';
if ~isdeployed & evriio('mia')
  %Add mia string.
  myprod = [prodname ' with MIA_Toolbox'];
else
  myprod = prodname;
end
refstr = strvcat(refstr, [myprod sprintf(' %s ',release) '(' crdate '). Eigenvector Research, Inc., Manson, WA USA 98831; software available at http://www.eigenvector.com.']);

% get OS
if ispc
  osstr = [system_dependent('getos'),' ',system_dependent('getwinsys')];
else
  osstr = system_dependent('getos');
end
% get matlab info

mljavastr = ['Java VM Version: ',...
  char(strread(version('-java'),'%s',1,'delimiter',',\n'))];

%prepare final string
options.figurename = 'Version Information';
options.fontname   = get(0,'FixedWidthFontName');
options.fontsize   = getdefaultfontsize;

dispstr = strvcat(plsinfo, spcstr, cachestr, refstr, spcstr, osstr, mlverstr, mllicstr, mljavastr, tbxs, pths, matlabinfo);
if nargout==0;
  if exist('infobox')
    infobox(dispstr,options)
  else
    disp(dispstr);
  end
else
  varargout{1} = dispstr;
end
