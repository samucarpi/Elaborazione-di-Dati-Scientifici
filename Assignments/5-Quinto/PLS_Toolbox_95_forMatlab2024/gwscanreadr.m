function data = gwscanreadr(filename,varargin)
%GWSCANREADR Reads Guided Wave scan files.
% Reads SCAN and AUTOSCAN files from Guided Wave. Imports ASCII and binary
% scan data (FileIDs DF1A, DF1B, WS1A and WS1B). May work on other file
% types but those are not guaranteed nor tested with this importer.
%
% INPUTS:
%   filename = a text string with the name of a SCAN file or a cell of
%               strings of SCAN filenames.
%     If (filename) is omitted or an empty cell {} or array [], the user
%     will be prompted to select a folder and then one or more SPC files in
%     the identified folder. If (filename) is a blank string, the user will
%     be prompted to select a single file.
%
% OPTIONAL INPUTS:
%   options = a structure with one or more of the following fields:
%        waitbar: [ 'off' |{'on'}] governs use of waitbar while reading
%                  file(s).
%
% OUTPUTS:
%   data = a dataset object containing the data from all input/selected
%          files
%
%I/O: data = gwscanreadr
%I/O: data = gwscanreadr('filename',options)
%I/O: data = gwscanreadr({'filename' 'filename2'},options)
%
%See also: ASFREADR, EDITDS, JCAMPREADR, SPCREADR, TEXTREADR

%Copyright Eigenvector Research, Inc 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==1 && ischar(filename) && ismember(filename,evriio([],'validtopics'));
  options = [];
  options.waitbar = 'on';
  if nargout==0; clear data; evriio(mfilename,filename,options); else data = evriio(mfilename,filename,options); end
  return;
end


if nargin<1 | isempty(filename)
  %this code will ask the user to locate a file:
  [file,pathname] = evriuigetfile({'*.scan;*.autoscan','Guided Wave Scan file (*.scan,*.autoscan)';'*.*','All Files (*.*)'},'multiselect','on');
  if ~iscell(file)
    if file == 0
      data = [];  %exit without data
      return
    else
      filename = [pathname,file];
    end
  else
    filename = {};
    for j=1:length(file);
      filename{j} = [pathname,file{j}];
    end
  end
end

if nargin<2
  options = [];
else
  options = varargin{1};
end
options = reconopts(options,mfilename);

if isstruct(filename) 
  if ~isfield(filename,'name')
    error('Unrecognized input')
  end
  filename = {filename.name};
end

if iscell(filename)
  %handle cell array of filenames
  if length(filename)>1
    if strcmp(options.waitbar,'on');
      wbh = waitbar(0,'Loading Guided Wave Files...');
    else
      wbh = [];
    end

    try
      data = {};
      for j=1:length(filename);
        data{j} = gwscanreadr(filename{j},options);
        if ~isempty(wbh)
          if ~ishandle(wbh)
            error('User cancelled import')
          else
            waitbar(j/length(filename),wbh);
          end
        end
      end
      data = matchvars(data);
    catch
      le = lasterror;
      if ishandle(wbh)
        close(wbh);
      end
      rethrow(le)
    end
    if ishandle(wbh)
      close(wbh);
    end
    for j=1:length(filename);
      data = addsourceinfo(data,filename{j});
    end
    return;
  else
    filename = filename{1};  %only one file, just read normally
  end
end   

%read file
[fid,msg] = fopen(filename,'r');
if fid<0
  error(msg)
end

try
  %defaults
  nvars = nan;
  lowwl = nan;
  highwl = nan;
  mydate = '';
  mytime = '';
  fileid = '';
  
  %header
  line = '';
  header = {};
  binary = true;
  while ~feof(fid) & ~strcmp(strtrim(line),'9999')
    line = fgetl(fid);
    [code,val] = strtok(line,' ');
    val = strtrim(val);
    code = str2num(code);
    if ~isempty(code)
      switch code
        case 1
          binary = ~strcmpi(val(end),'A');
          fileid = val;
        case 801
          nvars  = str2num(val);
        case 802
          lowwl  = str2num(val);
        case 804
          highwl = str2num(val);
        case 204
          mydate = val;
        case 205
          mytime = val;
      end
    end
    header{end+1,1} = line;
  end
  
  if isempty(fileid)
    error('Missing FileID. Cannot read "%s"',filename);
  end
  
  %data
  if binary
    if mod(ftell(fid),2)
      fread(fid,1,'*char');      %move to next even byte
    end
    data = double(fread(fid,inf,'single')');
  else
    data = fread(fid,inf,'*char');
  end
  
catch
  fclose(fid);
  rethrow(lasterror)
end
fclose(fid);

if ~binary
  %if text, convert to numeric
  data = char(data');
  data(data==13) = [];
  data = regexprep(data,'LOW','NaN');
  data = str2num(data);
  data = data(:)';
  if isempty(data)
    error('Could not convert from apparent ASCII format')
  end
end

%grab correct block
if isnan(nvars)
  nvars = size(data,2);
  if strfind(upper(fileid),'WS1')==1
    blks = 3;  %has 3 blocks
    nvars = floor(nvars/blks);
  end
end
data = data(1,1:nvars);

%create dataset
data = dataset(data);
data.description = header;

%add axisscale to columns
if ~isnan(lowwl) & ~isnan(highwl)
  data.axisscale{2} = linspace(lowwl,highwl,nvars);
  data.axisscalename{2} = 'Wavelength (nm)';
end

%add date/time to row
if ~isempty(mydate) & ~isempty(mytime)
  datetime = [mydate ' ' mytime];
  data.label{1} = datetime;
  data.axisscale{1} = datenum(datetime);
end

data = addsourceinfo(data,filename);

