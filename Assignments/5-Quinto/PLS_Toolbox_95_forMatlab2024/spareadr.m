function out = spareadr(filenames,options)
%SPAREADR Reads Thermo Fisher SPA and SPG files.
% INPUTS:
%   filename = a text string with the name of an SPA file or
%              a cell of strings of SPA filenames.
%     If (filename) is omitted or an empty cell or array, the user will be
%     prompted to select a folder and then one or more files in the
%     identified folder. If (filename) is a blank string '', the user will
%     be prompted to select a single file.
%
% OPTIONAL INPUTS:
%   options = an options structure containing one or more of the following
%        multiselect : [ 'off' | {'on'} ] governs whether file selection
%                      dialog should allow multiple files to be selected
%                      and imported. Setting to 'off' will restrict user to
%                      importing only one file at a time.
%        nonmatching : [ 'error' |{'matchvars'} 'cell'] Governs behavior 
%                      when multiple files are being read which cannot be 
%                      combined due to mismatched types, sizes, etc.
%                      'matchvars' returns a dataset object,
%                      'cell' returns cell (see outputs, below), 
%                      'error' gives an error.
%
% OUTPUT:
%   out  = takes one of two forms:
%       1) If input is a single file, or multiple files containing data that
%          can be combined (same number of data points, same x-axis range,
%          same type of data), the output is a dataset object
%       2) If the input consists of multiple files containing data that
%          cannot simply be combined (different number of data points, 
%          differing x-axis ranges, etc), the output is either:
%          a cell array with a dataset object for each input file if the
%          'nonmatching' option has value 'cell', or
%          a dataset object containing the input data combined using the
%          MATCHVARS function if the 'nonmatching' option has value 
%          'matchvars'.
%
%
%I/O: out = spareadr    
%I/O: out = spareadr('filename')
%I/O: out = spareadr({'filename' 'filename2'})
%
%See also: ASFREADR, EDITDS, JCAMPREADR, SPCREADR, TEXTREADR

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS

%check for evriio input
if nargin==1 && ischar(filenames) && ismember(filenames,evriio([],'validtopics'));
  options = [];
  options.multiselect = 'on';
  options.nonmatching = 'matchvars';
  options.spectrumindex = 1; 
  if nargout==0; clear out; evriio(mfilename,filenames,options); else out = evriio(mfilename,filenames,options); end
  return;
end

% parse other possible inputs
% no inputs? set input = '' (to trigger single file read)
if nargin==0;
  filenames = {};
end
%check if there are options and reconcile them as needed
if nargin<2
  %no options!?! use empty
  options = [];
end
options = reconopts(options,mfilename);

% if no file list was passed
if isempty(filenames)
  %do actual read for filename
  [filenames, pathname, filterindex] = evriuigetfile({'*.spa; *.SPA','Omnic data files (*.spa)'; '*.*', 'All files'}, 'Open Omnic SPA file','MultiSelect', options.multiselect);
  if filterindex==0
    out = [];
    return
  else
    %got one or more filenames, add path to each
    if ~iscell(filenames)
      filenames = {filenames};
    end
    for lll = 1:length(filenames)
      filenames{lll} = fullfile(pathname,filenames{lll});
    end
  end

end


switch class(filenames)

  case 'char'
    % Only for the case where user passes explicit string (maybe with
    % wildcards) Does it contains a wild card?
    wild_card_pat = '[\*\?]';
    if regexp(filenames, wild_card_pat)
      % wild card character identified
      target_path = fileparts(filenames);
      if isempty(target_path)
        target_path = pwd;
      end
      dir_files = dir(filenames);
      filenames = {dir_files.name}; filenames = filenames(:)';
      for lll = 1:length(filenames)
        filenames{lll} = fullfile(target_path,filenames{lll});
      end
    else
      % turn single string into a string inside a cell
      filenames = {filenames};
    end

  case 'cell'
    % filenames is a cell already... don't need to do anything...

  otherwise
    error('incorrect input format');

end

% when we reach here, filenames must be a cell

if isempty(filenames)
  out = [];
  return
end

nspec = length(filenames);

%read first file and create matricies to hold all the content
[data, axisinfo, xaxis, text, title] = load_spa(filenames{1}, options);

out          = cell(1,nspec);
alltitle     = cell(1,nspec);
allxaxis     = xaxis;

matchingaxes = true;
for j=1:nspec
  [pth,file,ext] = fileparts(filenames{j});
  file = [file ext];
  if j>1
    %next file(s): concantenate as possible
    [data, axisinfo, xaxis, text, title] = load_spa(filenames{j}, options);
    if length(xaxis)~=length(allxaxis) | any(xaxis~=allxaxis)
      matchingaxes = false;
      if strcmp(options.nonmatching,'error')
        error('File "%s" does not match axisscale of previous files. Cannot combine mismatched axisscales.',file);
      end
    end
  end
  
  alltitle{j}  = title;
  out{j} = dataset(data);
  if strcmp(options.nonmatching,'cell')
    out{j} = addsourceinfo(out{j},filenames{j});
  end
  out{j}.axisscale{2} = xaxis;
  out{j}.axisscalename{2} = 'Wavenumbers (cm-1)';
  
  out{j}.label{1} = char(file);
  out{j}.labelname{1} = 'Filename';
  
  out{j}.description = char(text);
  out{j}.userdata = char(text);
  
  out{j}.label{1,2} = title;
  out{j}.labelname{1,2} = 'Title';
end

% Now alldata is cell array, where all var. axes match 
% OR they do not all match and option nonmatching = 'cell', or 'matchvars'
% Call matchvars and return dso except if they don't match and nonmatching = 'cell'
if ~matchingaxes & strcmp(options.nonmatching, 'cell')
  return;
else
  out = matchvars(out);
end

if strncmp(alltitle{1},'Linked spectrum at',18)
  %appears to match linked spectrum keywords
  tm = nan(1,nspec);
  for j=1:length(alltitle);
    tm(j) = sscanf(alltitle{j}(:,20:end),'%f %*s',[1 inf]);
  end
  out.axisscale{1} = tm;
  
  units = alltitle{1};
  units = strtrim(units(max(find(units==' ')):end));
  out.axisscalename{1} = sprintf('Time (%s)',units);
end

%----------------------------------------------------------------
function [data, axisinfo, xaxis, text, title] = load_spa(file_name, options)
%LOAD_SPA Low-level read of SPA file format.
% Input is a single file name (file_name)
% Outputs are:
%    data     = intensity data
%    axisinfo = details of axis (number of points, start wl, end wl)
%    xaxis    = vector of wavelength axis
%    text     = text description from file
%    title    = text title from file

% Written by Nancy Jestel, Chuck Bradley
% Modified by JMS to clean and speed up code

% this block copied from load_raman_spg, changing spg to spa
if nargin<1  % no file name given, request one
  [file_name,file_path]=uigetfile({'*.spa','Omnic data files (*.spa)';...
    '*.*','All files (*.*)'},'Read SPA file');
  if isnumeric(file_name) %check for cancel pressed
    return
  end
  
  file_name=[file_path file_name];
end

[file,message] = fopen(file_name,'r');
% check that the fopen worked
if file<0
  error('Unable to open "%s": %s',file_name,message);
end

try
  %read file contents
    
  % The title seems to be at a fixed location, hex 1e = decimal 30.
  % It ends at hex 11c = decimal 284 or sooner, and is followed by at least one \0
  title_position = 30;
    
  % Find various information locations by scanning the file in 16-byte
  % steps looking for key "line codes" which indicate we're at a specific
  % marker. Make sure we read all possible markers before continuing
  scan_position = 304-16;	% x130 aka 130h
  gotitems = [false false false];
  count = 0;
  while any(~gotitems) & ~feof(file)
    scan_position = scan_position + 16;
    fseek(file, scan_position, 'bof');
    line_code = fread(file, 1, 'char');
    
    switch line_code
      case 27    % hex 1B        
        if (gotitems(1)); continue; end
        dummy         = fread(file, 1, 'char');	% skip one byte
        text_position = fread(file, 1, 'uint32');
        gotitems(1) = true;

      case 2
        %maker for spectral info data
        if (gotitems(2)); continue; end
        dummy                  = fread(file, 1, 'char');	% skip one byte
        spectral_info_position = fread(file, 1, 'uint32');
        num_data_points_position  = spectral_info_position +  4;
        wavelength_start_position = spectral_info_position + 16;
        wavelength_end_position   = spectral_info_position + 20;
        gotitems(2) = true;
        
      case 3
        %marker for intensity location and size
        if (gotitems(3)); continue; end
        dummy              = fread(file, 1, 'char');		% skip one byte
        intensity_position = fread(file, 1, 'uint32');
        intensity_size     = fread(file, 1, 'uint32');
        gotitems(3) = true;
        
      case 0
        %assuming this is end of header...
        break
        
      otherwise
        %not interested...
        
        % here are a few more positions, perhaps.
        % in general, look at decimal 304 + 16*n for n = 0,1,2,3...
        % look for various values of line_code.
        % it is not certain that a given code will be found.
        % we need to find out how to limit the search.
        % line_code hex 6a, unknown
        % line_code hex 69. unknown
        % line_code hex 92. skip 1 byte, then next 4 is position of custom
        % info
        
    end
    if all(gotitems)
      count = count +1;
      if count < options.spectrumindex
        gotitems = [false false false];
      end
    end
  end;
  if count < options.spectrumindex
    error(sprintf('desired spectrum index exceeds number of available spectra, which is %d',count)) % WARNING: If you change this message, update okerror variable in spgreadr.m as well (HARDWIRED VALUE).
  end
  if ~gotitems(2)
    error('File format not recognized - axis information not found');
  end
  if ~gotitems(3)
    error('File format not recognized - intensity information not found');
  end
  
  % Now that we know where to find everything, copy it to the outputs
  
  % first, the intensity data
  number_of_values = intensity_size / 4;		% sizeof(float)
  
  fseek(file, intensity_position, 'bof');
  data = fread(file, number_of_values, 'float')';

  % then the information about the x axis
  fseek(file, num_data_points_position, 'bof');
  num_data_points = fread(file, 1, 'uint32');
  
  fseek(file, wavelength_start_position, 'bof');
  wavelength_start = fread(file, 1, 'float');
  fseek(file, wavelength_end_position, 'bof');
  wavelength_end = fread(file, 1, 'float');
  
  %create xaxis output
  axisinfo = [num_data_points,wavelength_start,wavelength_end];
  if length(axisinfo)~=3
    error('File format not recognized - axis information not found');
  end
  xaxis = axisinfo(2):(-1*(axisinfo(2)-axisinfo(3))/(axisinfo(1)-1)):axisinfo(3);
  
  if gotitems(1)
    % and now the text
    fseek(file, text_position,-1);
    text = readtozero(file);
  else
    text = '';
  end
  
  % and finally the title
  fseek(file, title_position,-1);
  title = readtozero(file);
  
catch
  %close file before throwing error
  le = lasterror;
  fclose(file);
  rethrow(le);
end

fclose(file);


%---------------------------------------------------------
function text = readtozero(file);
%reads contents of the file from the current position up to the first zero

text = {};			% start with empty output buffer
line = '';		% be sure to enter while loop
while ~any(line==0) & ~feof(file)
  line = fread(file,80,'*char')';
  text = [text line];
end;
text = [text{:}];
text = text(1:min(find(text==0))-1);  %drop after first zero character
text = regexprep(text,'\r\n','\n');
