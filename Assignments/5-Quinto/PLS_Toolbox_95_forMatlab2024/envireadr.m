function [out,hinfo] = envireadr(filenames,options)
%envireadr Reads ENVI image files.
%  ENVI format has two files, .hdr (header) and .img (binary image,
%  sometimes given the extension .dat, .sc, .cube or .raw). All file pairs
%  must have the same base filename.
%
% INPUT:
%   filenames = a text string with the name of an HDR file or
%               a cell of strings of HDR filenames. If (filenames) is omitted
%               or an empty cell or array, the user will be prompted to
%               select a folder and then one or more files in the identified
%               folder. If (filenames) is a blank string '', the user will be
%               prompted to select a single file.
%
% OPTIONAL INPUT:
%     options = an options structure containing one or more of the following
%    fields:
%      waitbar : [ 'off' |{'on'}] governs display of a waitbar while
%                 loading.
%
% OUTPUTS:
%         out = takes one of two forms:
%               1) If input is a single file, the output is a dataset object.
%               2) If the input consists of multiple files, the output is a cell
%                  array with a dataset object for each input file.
%       hinfo = structure array containing header information
%
%
% NOTE: In ENVI format (originally developed for geospatial imaging data),
%   the data is written into two files -- a flat binary file and a text
%   header file.  The header file contains the wavelength information as well
%   as how the image data is organized in the binary file.
%     http://groups.google.com/group/comp.lang.idl-pvwave/msg/615b19825970bf51?
%     https://www.harrisgeospatial.com/docs/ENVIHeaderFiles.html
%
%I/O: out = envireadr;
%I/O: out = envireadr('filename',options);
%I/O: out = envireadr({'filename1' 'filename2'},options);
%
%See also: ASFREADR, EDITDS, JCAMPREADR, OPOTEKTIFFRDR, SPCREADR, XCLREADR


%Copyright Eigenvector Research 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%check for evriio input
if nargin==1 && ischar(filenames) && ismember(filenames,evriio([],'validtopics'));
  options = [];
  options.waitbar = 'on';
  if nargout==0; clear out; evriio(mfilename,filenames,options); else out = evriio(mfilename,filenames,options); end
  return;
end

%Parse inputs.
if nargin==0;
  filenames = '';
end
%Reconcile options.
if nargin<2
  options = [];
end
options = reconopts(options,mfilename);

%No filenames input.
if isempty(filenames)
  switch class(filenames)
    case 'char'
      %Get single file if empty string.
      multiselect = 'off';
    otherwise
      %Use multifile.
      multiselect = 'on';
  end
  %Get files.
  [filenames, pathname, filterindex] = evriuigetfile({'*.hdr', 'ENVI Image Header Files (*.hdr)'; '*.*', 'All files'}, 'Import ENVI Image Files','MultiSelect', multiselect);
  if filterindex==0
    out = [];
    return
  else
    %Add path to filenames.
    if ~iscell(filenames)
      filenames = {filenames};
    end
    for i = 1:length(filenames)
      filenames{i} = fullfile(pathname,filenames{i});
    end
  end
else
  if ~iscell(filenames)
    filenames = {filenames};
  end
end

out = {};
try
  if strcmp(options.waitbar,'on')
    wbh = waitbar(0,'Reading first file.','name','Reading ENVI Files (Close to cancel)');
    title_hdl = get(findobj(allchild(wbh), 'type', 'axes'), 'title');
    if ~isempty(title_hdl)
      set(title_hdl, 'Interpreter', 'none');
    end
    
  else
    wbh = [];
  end
  len = length(filenames);
  
  for i = 1:len;
    %Get file name to use in waitbar.
    [pth, myname, ext] = fileparts(filenames{i});
    if isempty(ext)
      filenames{i} = fullfile(pth,[myname '.hdr']);
    end
    
    %Use 2*length so can indicate 2 steps (read info, read file).
    if ishandle(wbh)
      waitbar(((3*i)-2)/((3*len)+1),wbh,['Parsing header file:  ' myname])
    end
    %Read header.
    hinfo = readheader(filenames{i});
    
    %Do some error checking.
    %     if ~strcmpi(hinfo.interleave,'bsq')
    %       error(['Unexpected interleave setting (''' hinfo.interleave '''). Expecting interleave ''bsq'' (Band Sequential Format).']);
    %     end
    
    
    if ishandle(wbh)
      waitbar(((3*i)-1)/((3*len)+1),wbh,['Reading img file for:  ' myname])
    end
    
    %Read data.
    myds = readimgfile(filenames{i},hinfo,strcmp(options.waitbar,'on'));
    if isempty(myds)
      %User cancel read or some other problem.
      close(wbh)
      return
    end
    
    if ishandle(wbh)
      waitbar(((3*i))/((3*len)+1),wbh,['Creating DataSet Object for:  ' myname])
    end
    
    if evriio('mia')
      myds = buildimage(myds, [1 2], 1);
    else 
      myds = dataset(myds);
    end
    
    if isfield(hinfo,'wavelength')
      wavlens = textscan(hinfo.wavelength,'%f','delimiter',',');
      wavlens = wavlens{:};
      %If size doesn't match skip.
      if length(wavlens)==size(myds,2)
        myds.axisscale{2,1} = wavlens;
      elseif length(wavlens)==size(myds,3)
        %Not unfolded.
        myds.axisscale{3,1} = wavlens;
      else
        evriwarndlg(['Unable to add axisscale to dataset. Number of wavelengths [' ...
          num2str(length(wavlens)) '] does not match number of bands [' num2str(size(myds,2)) ']. Axisscale will not be added.'],...
          'Wavelength to Axisscale Warning')
      end
    end
    myds.name = filenames{i};
    myds = addsourceinfo(myds,filenames{i});
    out{i} = myds;
    close(wbh)
  end
  
catch
  myerr = lasterr;
  fclose all;
  if ishandle(wbh)
    close(wbh)
  end
  error('Error Reading ENVI File: %s',myerr)
end

if length(out)==1
  out = out{1};
end

%-----------------------------
function hinfo = readheader(filename)
%Header File Format (.hdr)
%
%
% description - A character string describing the image or the processing performed.
% samples - The number of samples (pixels) per image line for each band.
% lines - The number of lines per image for each band.
% bands - The number of bands per image file.
% header offset - The number of bytes of imbedded header information present in the file
%   (for example, 128 bytes for ERDAS 7.5 .lan files). ENVI skips these
%   bytes when reading the file.
% file type- The ENVI-defined file type, such as a certain data format and processing
%   result. The available file types are listed in the filetype.txt file
%   (see ENVI File Type File). The file type ASCII string must match an
%   entry in the filetype.txt file verbatim, including case.
% data type - The type of data representation, where 1=8-bit byte; 2=16-bit signed
%   integer; 3=32-bit signed long integer; 4=32-bit floating point; 5=64-bit
%   double-precision floating point; 6=2x32-bit complex, real-imaginary pair
%   of double precision; 9=2x64-bit double-precision complex, real-imaginary
%   pair of double precision; 12=16-bit unsigned integer; 13=32-bit unsigned
%   long integer; 14=64-bit signed long integer; and 15=64-bit unsigned long
%   integer.
% interleave - Refers to whether the data are BSQ, BIP, or BIL.
%   BSQ - format is the simplest format, where each line of the data is
%   followed immediately by the next line in the same spectral band. This
%   format is optimal for spatial (x,y) access of any part of a single
%   spectral band.
%   BIP - format provides optimal spectral processing performance. Images
%   stored in BIP format have the first pixel for all bands in sequential
%   order, followed by the second pixel for all bands, followed by the
%   third pixel for all bands, etc., interleaved up to the number of
%   pixels. This format provides optimum performance for spectral (Z)
%   access of the image data.
%   BIL - format provides a compromise in performance between spatial and
%   spectral processing and is the recommended file format for most ENVI
%   processing tasks. Images stored in format have the first line of the
%   first band followed by the first line of the second band, followed by
%   the first line of the third band, interleaved up to the number of
%   bands. Subsequent lines for each band are interleaved in similar
%   fashion.
% sensor type - Instrument types, such as Landsat TM, SPOT, RADARSAT, and so on. The
%   available sensor types are the sensor.txt file described in ENVI Sensor
%   File. The sensor type ASCII string defined here must match one of the
%   entries in the sensor.txt file verbatim., including case.
% byte order - The order of the bytes in integer, long integer, 64-bit integer,
%   unsigned 64-bit integer, floating point, double precision, and complex
%   data types. Use one of the following:
%   Byte order=0 (Host (Intel) in the Header Info dialog) is least
%   significant byte first (LSF) data (DEC and MS-DOS systems).

%Read in header.
[fid,msg] = fopen(filename,'rt');

if fid<0
  error(msg)
end

frewind(fid);
hcell = {''};

while ~feof(fid)
  ln    = fgetl(fid);
  if ischar(ln)
    hcell = [hcell {ln}];
  end
end
fclose(fid);

%Remove first empty cell.
hcell = hcell(2:end);
i = 1;

flines = strfind(hcell,'='); %Lines with field names.
hinfo = [];

while i <= length(hcell)
  if ~isempty(flines{i})
    %Field name.
    fname = strtrim(hcell{i}(1:flines{i}-1));
    fname = strrep(fname,' ','_');

    %The .hdr files seem to be a little non-standard so try to make
    %wavelength lower case so the test to add wavelength data to dataset
    %works (above).
    if strcmpi(fname,'wavelength')
      fname = lower(fname);
    end

    if i==length(hcell) |  isempty(strfind(hcell{i},'{')) %If last line or don't find multiline then value is on single line.
      %Value is contained on single line.
      myval = strtrim(hcell{i}(flines{i}+1:end));
      myval = myval(~ismember(myval,'{}'));
      i = i+1;
    elseif ~isempty(strfind(hcell{i},'{')) & ~isempty(strfind(hcell{i},'}'))
      %Multiline marker, but all on the same line
      myval = strtrim(hcell{i}(flines{i}+1:end));
      %myval = myval(~ismember(myval,'{}'));
      myval = myval(strfind(myval,'{')+1:strfind(myval,'}')-1);
      i = i+1;
    elseif ~isempty([flines{i+2:end}])
      %Multiline value but not the end. Find the next field name line and
      %create value from lines in between.
      j = i+2;
      while j<length(hcell)
        if ~isempty(flines{j})
          %Found next field line.
          loc = j;
          break
        else
          j = j+1;
        end
      end
      myval = [hcell{i:j-1}];
      myval = myval(strfind(myval,'{')+1:strfind(myval,'}')-1);
      i = j;
    else
      %Value is rest of cell array.
      myval = [hcell{i:end}];
      myval = myval(strfind(myval,'{')+1:strfind(myval,'}')-1);
      i = length(hcell);
    end
    hinfo.(genvarname(fname)) = myval;
  else
    i = i+1;
  end
end

%-----------------------------
function mydata = readimgfile(filename,hinfo,show_waitbar)
%Read the img file matching the hdr file (filename).

if isfield(hinfo,'byte_order') & strcmp(hinfo.byte_order,'0')
  %Byte order=0 is least significant byte first (LSF), little-endian.
  mformat = 'ieee-le';
elseif isfield(hinfo,'byte_order') & strcmp(hinfo.byte_order,'1')
  %Byte order=1 is most significant byte first (MSF), big-endian.
  mformat = 'ieee-be';
else
  %Give up and use native.
  mformat = 'native';
end

%data type parameter identifying the type of data representation, where
%1=8 bit byte;
%2=16-bit signed integer;
%3=32-bit signed long integer;
%4=32-bit floating point;
%5=64- bit double precision floating point;
%6=2x32-bit complex, real-imaginary pair of double precision;
%9=2x64-bit double precision complex, real-imaginary pair of double precision;
%12=16-bit unsigned integer;
%13=32-bit unsigned long integer;
%14=64-bit unsigned integer;
%15=64-bit unsigned long integer.

%Guessing on a couple of these types.
switch hinfo.data_type
  case '1'
    dformat = 'uint8';
  case '2'
    dformat = 'int16';
  case '3'
    dformat = 'int32';
  case '4'
    dformat = 'single';
  case '5'
    dformat = 'double';
  case '6'
    dformat = 'real*4';
  case '9'
    dformat = 'real*8';
  case '12'
    dformat = 'uint16';
  case '13'
    dformat = 'uint32';
  case '14'
    dformat = 'uint16';
  case '15'
    dformat = 'ulong';
  otherwise
    error(['File type number: ',num2str(hinfo.data_type),' not supported']);
end

%look for data file
myfile = '';
exttotry = {'.img' '.dat' '.raw' '.sc' '.cube' '.bil' '.bin' ''};
for j=1:length(exttotry)
  myfile = strrep(filename,'.hdr',exttotry{j});
  if exist(myfile,'file')
    break;
  end
  myfile = '';
end
if isempty(myfile)
  error(['Data file corresponding to ' filename ' (.img, .dat, .raw, .sc, .cube .bil .bin) could not be found']);
end

%n = str2num(hinfo.samples)*str2num(hinfo.lines)*str2num(hinfo.bands);
fid = fopen(myfile,'r',mformat);
fseek(fid, str2num(hinfo.header_offset), 'bof');
position = ftell(fid);
%mydata = fread(fid,inf,dformat,0,mformat);

if ~ismember(lower(hinfo.interleave),{'bsq' 'bil' 'bip'})
  error('Unknown interleave format "%s"',hinfo.interleave)
end

%NEED: lines x samples x bands
%BSQ = samples x lines x bands (2 1 3)  -> [2 1 3] -> lines x samples x bands (1 2 3)
%BIL = samples x bands x lines (2 3 1)  -> [1 3 2] -> samples x lines x bands (2 1 3)
%BIP = bands x samples x lines (3 2 1)  -> [2 1 3] -> samples x bands x lines (2 3 1)

%read entire image and permute individual slabs using indexing
mydata = fread(fid,inf,dformat,0,mformat);
sz = [str2double(hinfo.lines),str2double(hinfo.samples),str2double(hinfo.bands)];

%determine how many steps we'll be taking so we can scale the waitbar correctly
switch lower(hinfo.interleave)
  case 'bsq'
    waitbarmax = sz(3);
  case 'bil'
    waitbarmax = sz(3)+sz(2);
  case 'bip'
    waitbarmax = sz(3)+sz(2)+sz(1);
end
wboffset = 0;
if show_waitbar
  wbh = waitbar(0,'Parsing Image File','name','Reading Image File (Close to cancel)');
else
  wbh = [];
end

try
  %use in-place permutation to allow permutes with large images
  
  blocksize = 40;  %maximum # of slabs to permute at a time
  
  switch lower(hinfo.interleave)
    case {'bip'}
      %permute: bands x samples x lines.  -> [2 1 3] -> samples x band x lines
      mydata = reshape(mydata,sz(3)*sz(2),sz(1)); %[(bands x samples) x lines ]
      i = reshape(1:(sz(3)*sz(2)),sz(3),sz(2))';  %create index to transpose in-place
      for slabs=1:blocksize:sz(1)
        if show_waitbar
          wbh = waitbar(slabs/waitbarmax,wbh);
        end
        slabblock = slabs:min(sz(1),slabs+blocksize-1);
        mydata(:,slabblock) = mydata(i,slabblock);
        if show_waitbar & ~ishandle(wbh)
          mydata = [];
          return
        end
      end
      mydata = reshape(mydata,sz(2),sz(3),sz(1));  %[samples x bands x lines]
      wboffset = wboffset + sz(1);
  end

  switch lower(hinfo.interleave)
    case {'bip' 'bil'}
      %permute: samples x bands x lines.  -> [1 3 2] -> samples x lines x bands
      mydata = reshape(mydata,sz(2),sz(1)*sz(3));  %[samples x (bands x lines)]
      i = reshape(1:(sz(1)*sz(3)),sz(3),sz(1))';  %create index to transpose in-place
      for slabs=1:blocksize:sz(2)
        if show_waitbar
          wbh = waitbar((wboffset + slabs)/waitbarmax,wbh);
        end
        slabblock = slabs:min(sz(2),slabs+blocksize-1);
        mydata(slabblock,:) = mydata(slabblock,i);
        if show_waitbar & ~ishandle(wbh)
          mydata = [];
          return
        end
      end
      mydata = reshape(mydata,sz(2),sz(1),sz(3));  %[samples x lines x bands]
      wboffset = wboffset + sz(2);
  end

  %permute: samples x lines x bands.  -> [2 1 3] -> lines x samples x bands
  mydata = reshape(mydata,sz(2)*sz(1),sz(3)); %[(samples x lines) x bands]
  i = reshape(1:(sz(2)*sz(1)),sz(2),sz(1))';  %create index to transpose in-place
  for slabs=1:blocksize:sz(3)
    if show_waitbar
      wbh = waitbar((wboffset + slabs)/waitbarmax,wbh);
    end
    slabblock = slabs:min(sz(3),slabs+blocksize-1);
    mydata(:,slabblock) = mydata(i,slabblock);
    if show_waitbar & ~ishandle(wbh)
      mydata = [];
      return
    end
  end
  mydata = reshape(mydata,sz(1),sz(2),sz(3));  %[lines x samples x bands]

catch
  le = lasterror;
  if ishandle(wbh)
    close(wbh)
  end
  rethrow(le);
end

fclose(fid);

if ishandle(wbh)
  close(wbh)
end
