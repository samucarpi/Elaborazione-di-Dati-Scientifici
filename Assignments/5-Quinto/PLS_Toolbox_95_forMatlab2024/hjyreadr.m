function out = hjyreadr(filenames, options)
%HJYREADR Reads HORIBA files from LabSpec version 6, .l6s and l6m types.
% INPUT:
%   filename = a text string with the name of a Horiba file or
%              a cell of strings of Horiba filenames.
%     If (filename) is omitted or empty user will be prompted for files.
%
% OPTIONAL INPUT:
%   options = an options structure containing one or more of the following
%    fields:
%       showparams       : [ 'on' |{'off'}] Display a list of parameters for
%                          the given file. This feature is only enabled when
%                          single file is input.
%       systemcheck      : [1] Governs checking for compatible operating
%                          system. If 0 (zero), the operating system will
%                          not be checked for compatibility. Usually, this
%                          will lead to errors if the Microsoft Visual C++
%                          2008 redistributable library is not installed on
%                          this computer.
%       nonmatching      : [ 'error' | 'cell' | {'matchvars'} ] Governs the
%                          handling of multiple spectra with non-matching
%                          axisscales. 'error' throws an error. 'cell'
%                          returns a cell array of spectra. 'matchvars'
%                          joins the spectra using the matchvars algorithm.
%
% OUTPUT:
% out = takes one of two forms:
%     1) If input is a single file, or multiple files containing data that
%        can be combined (same number of data points, same x-axis range,
%        same type of data), the output is a dataset object
%     2) If the input consists of multiple files containing data that
%        cannot simply be combined (different number of data points, 
%        differing x-axis ranges, etc), the output is either:
%        a cell array with a dataset object for each input file if the
%        'nonmatching' option has value 'cell', or
%        a dataset object containing the input data combined using the
%        MATCHVARS function if the 'nonmatching' option has value 
%        'matchvars'.
%
%I/O: out = hjyreadr
%I/O: out = hjyreadr('filename',options)
%I/O: out = hjyreadr({'filename' 'filename2'},options)
%
%See also: ASFREADR, EDITDS, JCAMPREADR, MATCHVARS, SPCREADR, TEXTREADR

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%check for evriio input
if nargin==1 && ischar(filenames) && ismember(filenames,evriio([],'validtopics'));
  options = [];
  options.waitbar      = 'on';
  options.showparams = 'off';
  options.nonmatching = 'matchvars';
  options.systemcheck  = 1;  %flag to enable checking for operating system incompatibility
  if nargout==0; clear out; evriio(mfilename,filenames,options); else out = evriio(mfilename,filenames,options); end
  return;
end
%Check if there are options and reconcile them as needed.
if nargin<2
  options = [];
end
options = reconopts(options,mfilename);

if (~ispc) & options.systemcheck
  error('HJYREADR only works on Windows systems. Use LabSpec software to export your data to another format (e.g. SPC).')
end
out = [];

if nargin<1 | isempty(filenames)
  %Prompt user for file.
  [filenames, pathname, filterindex] = evriuigetfile({'*.l6s; *.l6m;' , 'HORIBA spectral files'; '*.*', 'All files'}, 'Open HORIBA spectral file','MultiSelect', 'on');
  if filterindex==0
    return
  else
    %got one or more filenames, add path to each
    if ~iscell(filenames)
      filenames = {filenames};
    end
    for i = 1:length(filenames)
      filenames{i} = fullfile(pathname,filenames{i});
    end
  end
else
  %Create cell array.
  if ~iscell(filenames)
    filenames = {filenames};
  end
end

% Use standard waitbar
nfiles = length(filenames);
if nfiles>1 & strcmp(options.waitbar,'on');
  wh = waitbar(0,'Importing file(s)... (Close to cancel)');
else
  wh = [];
end

%If directory is not local it causes error with activex control.
mydir = pwd;

try
  cd(fileparts(which(mfilename)));  %change to PLS_Toolbox dir
  cd('extensions\hjy');
  hjydir = pwd;    % need to be here to use myApp DLL-based functions
  myApp = com.evri.hjyraman.HjyReader; 
  
  if options.systemcheck
    [result] = check_horiba_dll(myApp, hjydir, mydir);
  end
catch le
  cd(mydir);  %make CERTAIN we're back in user's directory
  rethrow(le);
end
cd(mydir);  %make CERTAIN we're back in user's directory

%do actual loading of files
try
  out = loadfiles(filenames,options,myApp, hjydir, wh);
  if length(out)==1
    out = out{:};
    out = addsourceinfo(out,filenames{1});
  else
    %try to combine all spectra into a single item
    sz = [];
    mismatch = false;
    for j=1:length(out);
      sz(j,:) = size(out{j});
      if any(sz(1,:)~=sz(j,:)) | any(out{1}.axisscale{2}~=out{j}.axisscale{2})
        mismatch = true;
      end
    end
    if ~mismatch
      %all axes match, combine using simple concatenation
      out = cat(1,out{:});
    else
      switch options.nonmatching
        case 'cell'
          %Add source info for each DSO.
          for i = 1:length(out)
            out{i} = addsourceinfo(out{i},filenames{i});
          end
  
        case 'error'
          %throw an error
          error('Multiple files with different axisscales found. Set "nonmatching" option to "matchvars" to combine.')
          
        otherwise  %'matchvars' or anyting else
          out = matchvars(out);
          out = addsourceinfo(out,filenames);          
          
      end
    end
  end
catch
  le = lasterror;
  le.message = ['HJYREADR Unable to read one or more files: ' le.message];
  cd(mydir)  %make CERTAIN we're back in user's directory
  rethrow(le);
end

if ~isempty(wh)
  close(wh)
end

cd(mydir)  %make CERTAIN we're back in user's directory

%--------------------------------------------------------------------
function out = loadfiles(filenames,options,myApp, hjydir, wh)
%Load spectra files, 'filenames' is cell array of full path file names.

  out = {};
  nfiles = length(filenames);
  for i = 1:nfiles
    [fpath, fname, ext] = fileparts(filenames{i});
    
    if ~ismember(lower(ext),{ '.l6s' '.l6m'})
      error('File format "%s" not supported by the HORIBA importer',ext)
    end

    %handle issues with path and loading file
    mydir = pwd;
    if isempty(fpath)
      %add current path if none specified on file (before we cd)
      filenames{i} = fullfile(mydir,filenames{i});
    end
    if ~exist(filenames{i},'file')
      error('File not found "%s"',filenames{i})
    end
    cd(hjydir);  %change to drive which contains OCX
    try
      %load file
      myApp.setFilename(filenames{i});
      myApp.setVerbose(0);
      
      myFiles = 0; % place holder
    catch
      le = lasterror;
      le.message = sprintf('Error reading %s\n%s',filenames{i},le.message);
      cd(mydir)
      rethrow(le)
    end

    mydso = getonespectrum(myApp,options);
    mydso.name = fname;
    out{end+1} = mydso;
    
    if ~(isempty(wh))
      if ~ishandle(wh)
        error('User aborted import');
      end
      waitbar(i/nfiles,wh);
    end
  end
  
  %   release(myApp,myFiles);

%--------------------------------------------------------------------
% Get a single spectrum (or image) from a spectrum ID
function mydso = getonespectrum(myApp,options)

acqinfo = myApp.readAcqInfo(30);
[acqstruct,acqchar] = parseacq(acqinfo);

datadim   = myApp.readDataDim;
datadimp1 = datadim +1;
datatitle = myApp.readDataTitle;

[axes] = getAxes(myApp, datadimp1);
if (datadim == 0)
  nsamp = 1;                                                   % 0D (single point)
elseif (datadim == 1) 
  nsamp = 1;                                                   % 1D (e.g. spectrum)
elseif (datadim == 2) 
  nsamp = length(axes{3});                                     % 2D (e.g. spectra)
elseif (datadim == 3)
  nsamp = length(axes{3}) * length(axes{4});                   % 3D (e.g. image)
elseif (datadim == 4)
  nsamp = length(axes{3}) * length(axes{4}) * length(axes{5}); % 4D (e.g. stack of images)
end

% "AxisUnits" : Get an array containing the Axis Units
% X units : "nm", "1/cm"="cm-1", "eV"
% Y units : "cnt", "cnt/sec"
% Image : "sec","mkm"="?m","kbar"
%
% "AxisType" : Get an array containing the Axis Types
% The Axis types depend on the application type. These are the standard types for Raman Applications :
% Intens : Intensity Axis
% Spectr : Frequency Axis
% X : X Axis
% Y : X Axis
% Z : X Axis
% Time : Time Axis
%
% "AxisSize" : Get an array containing the Axis Sizes.
% Each axis can have a different size. The Intensity Axis has a 0 size.

%Add meta data to info structure for debugging. Can remove later if
%desired. Make sure it's structure, if error occurs the comes out as
%orginal cell array.

% Axis
units  = getFieldForAxes(myApp, 'Unit', datadimp1);
types  = getFieldForAxes(myApp, 'Type', datadimp1);
labels = getFieldForAxes(myApp, 'Label', datadimp1);
sizes  = cellfun(@length, axes, 'UniformOutput', false);
sizes  = sizes';

readtransposedxy = true; % spatially transpose the 2D image 
if readtransposedxy & datadim>2  % 3=image, 4=volume, 5=volume-time
  imx = 3;
  imy = 4;
  nx = sizes{imx};
  ny = sizes{imy};
  switch datadim
    case 3
      nz = 1;
      nw = 1;
    case 4
      nz = sizes{5};
      nw = 1;
    case 5
      nz = sizes{5};
      nw = sizes{6};
  end 
  
%   if (datadim==3 & nx*ny ~= nsamp)
%     error('nsamp does not equal axis X length times axis Y length')
%   end
  k = 1;
  inew = int32(nsamp);
  for iw = 1:nw
    for iz = 1:nz
      for ix = 1:nx
        for iy = 1:ny
          inew(k) = (ix-1 + (iy-1)*nx) + (iz-1)*nx*ny + (iw-1)*nx*ny*nz;  % -1 because Java is 0-based index
          k      = k+1;
        end
      end
    end
  end
  IntensityData = myApp.readSampleData(inew);
else
  IntensityData = myApp.readSampleData(nsamp);
end

if isstruct(acqstruct)
  acqstruct.AxisUnits = units;
  acqstruct.AxisSize  = sizes;
  acqstruct.AxisType  = types;
  acqstruct.AxisLabel = labels;
end

mydso = dataset(double(IntensityData));
clear IntensityData;

if datadim > 0
  % "spectral" axisscale:
  mydso.axisscale{2} = axes{2};
  % Insert mAxisType in here?
  mydso.axisscalename{2} = [labels{2} '(' units{2} ')'];
end

% Make meaningful axisscales for 3D and 4D?
if datadim == 2   % spectra
  mydso.axisscale{1} = axes{3};
  mydso.axisscalename{1} = [labels{3} '(' units{3} ')'];
elseif datadim == 3  % 3=image, 4=volume, 5=volume-time
  mydso.type = 'image';
  mydso.imagemode = 1;  % target;
  if readtransposedxy
    % switch axes{imx} and axes{imy}
    tmp = axes{imy};
    axes{imy} = axes{imx};
    axes{imx} = tmp;
    imagesize = [length(axes{imx}) length(axes{imy})]; % [sizes(imy) sizes(imx)];
  else
    imagesize = [sizes{3:length(sizes)  }];
  end
  mydso.imagesize = imagesize; % sizeidata(modes);
  for ii=2:3 % imageaxisscale only has two elements
    mydso.imageaxisscale{ii-1} = axes{ii+1};
  end
elseif datadim > 3
  % no samples axisscale
end

mydso.userdata.acqusitionInfo = acqstruct;
mydso.author = 'hjyreadr';
    
  %--------------------------------------------------------------------------
function [axes] = getAxes(myApp, naxes)
% 
axes = cell(1,naxes);
for i=1:naxes
  axes{i} = myApp.readDataAxis(i-1);
  axes{i} = double(axes{i});
end
    
%--------------------------------------------------------------------------      
function [res] = getFieldForAxes(myApp, property, naxes)
  root = 'Data[Matrix][Axis][';
  str1 = '[';
  str2 = ']';
  res = cell(naxes,1);
  for i=1:naxes
    tmp = sprintf('%s%d%s%s%s%s', root, (i-1), str2, str1, property, str2);
    res0 = myApp.readString(tmp);
    res{i} = char(res0);
  end

%--------------------------------------------------------------------
function [acqstruct,acqchar] = parseacq(acqinfo)
%Parse and display acquisition info.
acqstruct = struct();
acqchar   = '';
names = acqinfo.names;
values = acqinfo.values;
units = acqinfo.units;

nnames = names.size;
try
  if nnames>0
    for i = 0:(names.size-1)   % Java is 0-based index
      try
        name = names.get(i);
      catch
        name = 'err';
      end
      try
        value = values.get(i);
      catch
        value = 'err';
      end
      try
        unit = units.get(i);
      catch
        unit = 'err';
      end
      name = strrep(name,'.','');
      name = strrep(name,' ','_');
      try
        acqstruct.(name).value = value;
      catch
        %       acqstruct.(name).value = 'err';
      end
      try
        acqstruct.(name).units = unit;
      catch
        %     acqstruct.(name).units = unit;
      end
    end
    
    acqchar = [];
  end
catch
  acqchar = '';
end

%--------------------------------------------------------------------------
function [result] = check_horiba_dll(myApp, hjydir, mydir);
% Try using the Java Hjyreader object to access a known data file,
% Spectrum.l6s.
% If both  calls on myApp give negative responses then it is very likely
% that the Microsoft Visual C++ redistributable 2008 is not installed.
% Give a message to install it and try again.
% This check adds insignificant time (about 0.02 seconds) to import time
cd(hjydir);  %change to folder which contains HORIBA_Importer64.dll and Spectrum.l6s
try
  %load known good file
  myApp.setFilename('Spectrum.l6s');
  myApp.setVerbose(0);
  datadim       = myApp.readDataDim;
  dataavailable = myApp.checkDataAvailable;
  vcredistlink = 'http://www.microsoft.com/en-us/download/details.aspx?id=11895';
  if ~dataavailable & datadim<0
    result = false;
    vcre = 'vcredist_x64';
    msg1 = 'Could not import Horiba Raman file. Possibly the Microsoft Visual C++ 2008 redistributable is not installed on this computer. Please install "';
    message = [msg1 vcre '.exe", available from: ' vcredistlink '  and try again after restarting (Solo or Matlab)'];
    error(message);
  else
    result = true;
  end
    
catch le
  vcre = 'vcredist_x64';
  web('http://www.microsoft.com/en-us/download/details.aspx?id=11895','-browser');
  cd(mydir)
  rethrow(le)
end
cd(mydir)

% %-------------------------------------------------------------------
% function release(myApp,myFiles)
% 
% %release all IDs
% if checkmlversion('>=','7')
%   stat = feature('COM_PassSafeArrayByRef'); 
%   feature('COM_PassSafeArrayByRef', 1);
% else
%   stat = [];
% end
% 
% for j=1:length(myFiles)
%   myApp.invoke('exec', myFiles{j}, 2, {});
% end
% 
% if ~isempty(stat)
%   feature('COM_PassSafeArrayByRef', stat);
% end
