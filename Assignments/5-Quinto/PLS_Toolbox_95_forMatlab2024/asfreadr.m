function out = asfreadr(filenames,options)
%ASFREADR Reads AIT ASF files.
% INPUT:
%   filename = a text string with the name of an ASF file or
%              a cell of strings of ASF filenames.
%     If (filename) is omitted or an empty cell or array, the user will be
%     prompted to select a folder and then one or more files in the
%     identified folder. If (filename) is a blank string '', the user will
%     be prompted to select a single file.
% OPTIONAL INPUTS:
%   options = an options structure containing one or more of the following
%    fields:
%       nonmatching : [ 'error' |{'matchvars'} 'cell'] Governs behavior 
%                      when multiple files are being read which cannot be
%                      combined due to mismatched types, sizes, etc.
%                      'matchvars' returns a dataset object,
%                      'cell' returns cell (see outputs, below), 
%                      'error' gives an error.
%        multiselect : [ 'off' | {'on'} ] governs whether file selection
%                      dialog should allow multiple files to be selected
%                      and imported. Setting to 'off' will restrict user to
%                      importing only one file at a time.
%
%
% OUTPUT:
%   x = takes one of two forms:
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
%I/O: x = asfreadr    
%I/O: x = asfreadr(filename,options)
%I/O: x = asfreadr({'filename' 'filename2'},options)
%
%See also: ASDREADR, ASFREADR, MATCHVARS, EDITDS, HJYREADR, JCAMPREADR, PDFREADR, SPAREADR, SPCREADR, WRITEASF, TEXTREADR

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%RR

%check for evriio input
if nargin==1 && ischar(filenames) && ismember(filenames,evriio([],'validtopics'));
  options = [];
  options.nonmatching = 'matchvars';
  options.multiselect = 'on';
  if nargout==0; clear out; evriio(mfilename,filenames,options); else out = evriio(mfilename,filenames,options); end
  return;
end

%This function is not available for 6.5.
if checkmlversion('<','7')
  error('ASFREADR does not work with older versions (R13 and below) of Matlab.')
end

% parse other possible inputs
% no inputs? set input = '' (to trigger single file read)
if nargin==0;
  filenames = '';
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
  [filenames, pathname, filterindex] = evriuigetfile({'*.ASF; *.asf; *.BKH; *.bkh; *.AIF; *.aif', 'Analect spectral files (*.asf, *.bkh, *.aif)'; '*.*', 'All files'}, 'Open Analect spectral file','MultiSelect', options.multiselect);
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


% loop over every element of filenames (cell array)

index_to_ptr       = 1;
index_to_ftype     = 2;
index_to_firstx    = 1;
index_to_lastx     = 2;
index_to_numpts    = 3;
index_to_date_time = 1;
index_to_trace_fmt = 13;
index_to_data_fmt  = 14;
index_to_xaxis     = 15;
index_to_yaxis     = 16;
index_to_title     = 1:60;

file_struct = struct('file_name', {}, 'valid_file', {}, 'desc', {}, 'asf_header', {}, 'firstx', {}, 'lastx', {}, 'numpts', {}, 'trace_fmt', {},  'data_fmt', {}, 'xaxis', {}, 'yaxis', {}, 'data', {}, 'date_time', {}, 'title', {});
for lll = 1:length(filenames)
  file_struct(lll).file_name = filenames{lll};
end

data_type_string = {'integer*2' 'integer*4' 'integer*8' 'real*4' 'real*8'};
xaxis_unit = {'unknown' 'cm^{-1}' '\mum' 'time' 'arbitrary'};
yaxis_unit = {'unknown' 'transmittance' 'absorbance' 'photoacoustic units' 'arbitrary' 'counts/20k'};
error_str = 'File I/O error - check format of data file(s)';

try

  for lll = 1:length(file_struct)
    fid = fopen(file_struct(lll).file_name, 'rb');
    if fid < 0
      file_struct(lll).valid_file = false;
      continue
    end
    %no other way of checking if this is an ASF format except for maybe

    %here we read in the file descriptor
    file_struct(lll).desc(1).longs     = fread(fid, 3, 'integer*4');
    file_struct(lll).desc(1).int       = fread(fid, 1, 'integer*2');
    file_struct(lll).desc(1).chars     = fread(fid, 2, 'uchar');
    ptr_to_next                        = file_struct(lll).desc(1).longs(index_to_ptr);

    %now read in the header descriptor
    fseek(fid, ptr_to_next, 'bof');
    file_struct(lll).desc(2).longs     = fread(fid, 3, 'integer*4');
    file_struct(lll).desc(2).int       = fread(fid, 1, 'integer*2');
    file_struct(lll).desc(2).chars     = fread(fid, 2, 'uchar');
    ptr_to_next                        = file_struct(lll).desc(2).longs(index_to_ptr);

    %now read in the ASF header - which is right after its descriptor
    file_struct(lll).asf_header.longs  = fread(fid, 14, 'integer*4');
    file_struct(lll).asf_header.floats = fread(fid, 14, 'real*4');
    file_struct(lll).asf_header.ints   = fread(fid, 20, 'integer*2');
    file_struct(lll).asf_header.chars  = fread(fid, 746, 'uchar');

    file_struct(lll).ftype             = file_struct(lll).desc(1).chars(index_to_ftype);
    etime                              = file_struct(lll).asf_header.longs(index_to_date_time);
    file_struct(lll).date_time         = datestr(datenum([1970 1 1 0 0 0]) + etime/(3600*24));

    file_struct(lll).firstx            = file_struct(lll).asf_header.floats(index_to_firstx);
    file_struct(lll).lastx             = file_struct(lll).asf_header.floats(index_to_lastx);
    file_struct(lll).numpts            = file_struct(lll).asf_header.longs(index_to_numpts);
    file_struct(lll).trace_fmt         = file_struct(lll).asf_header.ints(index_to_trace_fmt);
    file_struct(lll).data_fmt          = file_struct(lll).asf_header.ints(index_to_data_fmt);
    file_struct(lll).xaxis             = file_struct(lll).asf_header.ints(index_to_xaxis);
    file_struct(lll).yaxis             = file_struct(lll).asf_header.ints(index_to_yaxis);
    file_struct(lll).title             = file_struct(lll).asf_header.chars(index_to_title);
    file_struct(lll).title             = file_struct(lll).title(file_struct(lll).title > 0);
    file_struct(lll).title             = char(file_struct(lll).title)';
    
    %unrecognized units always get set to "unknown"
    if (file_struct(lll).xaxis>length(xaxis_unit)-1); file_struct(lll).xaxis = 0; end 
    if (file_struct(lll).yaxis>length(yaxis_unit)-1); file_struct(lll).yaxis = 0; end 
    
    fseek(fid, ptr_to_next, 'bof');

    %now at the data descriptor
    file_struct(lll).desc(3).longs     = fread(fid, 3, 'integer*4');
    file_struct(lll).desc(3).int       = fread(fid, 1, 'integer*2');
    file_struct(lll).desc(3).chars     = fread(fid, 2, 'uchar');

    %now ready to read in data
    data_fmt                           = file_struct(lll).data_fmt;
    numpts                             = file_struct(lll).numpts;
    file_struct(lll).data              = fread(fid, numpts, data_type_string{data_fmt});
    file_struct(lll).data              = file_struct(lll).data(:)';

    file_struct(lll).valid_file        = true;
    
    frewind(fid);
    file_struct(lll).hdr_data          = uint8(fread(fid, ptr_to_next + 16, 'uchar'));
    file_struct(lll).fmt_string        = data_type_string{data_fmt};

    fclose(fid);



  end

  % parse out entries that are not valid files
  if any([file_struct.valid_file] == false)
    error_str = 'Unable to open/read one or more files';
    error(error_str);
  end

  % can we combine the data into a single dataset object?
  % first test - same number of data points
  % second test - xaxis starts at the same point
  % third test - xaxis spacing is the same for each
  % fourth test - same file type (even though this has not ever changed)
  % fifth test - same data type
  % sixth test - same xaxis type
  % seventh test - same yaxis type
  % eighth test - same trace format


  error_str = 'Invalid parameter found in one or more files';
  test_mat  = [file_struct.firstx; file_struct.lastx; file_struct.numpts; file_struct.trace_fmt; file_struct.data_fmt; file_struct.xaxis; file_struct.yaxis; file_struct.ftype]';

  %additional test on data integrity
  %firstx and/or lastx can conceivably be less than zero (for example, an
  %interferogram), but the other elements have well defined acceptable
  %values
  bad_parameter = '';
  if any([file_struct.numpts   ] <=0); 
    bad_parameter = ('Invalid parameter found in one or more files: numpts'); 
  end
  if any([file_struct.trace_fmt] <0) | any([file_struct.trace_fmt] >6);
    bad_parameter = ('Invalid parameter found in one or more files: trace_fmt'); 
  end
  if any([file_struct.data_fmt ] <0) | any([file_struct.data_fmt ] >length(data_type_string)-1);                          
    bad_parameter = ('Invalid parameter found in one or more files: data_fmt'); 
  end 
  if any([file_struct.xaxis    ] <0);  %note: "xaxis type too large" trapped and set to zero during read
    bad_parameter = ('Invalid parameter found in one or more files: xaxis type'); 
  end
  if any([file_struct.yaxis    ] <0);  %note: "yaxis type too large" trapped and set to zero during read
    bad_parameter = ('Invalid parameter found in one or more files: yaxis type'); 
  end
  if ~isempty(bad_parameter)
    error(bad_parameter);
  end
  

  error_str = 'Error assembling output';

  uniq_vals = unique(test_mat, 'rows');

  if ~isequal(size(uniq_vals, 1),1)
    if strcmp(options.nonmatching,'error')
      error_str = 'Files are not compatible and cannot be combined';
      error(error_str);
    end
    output_case = 'cell';
  else
    output_case = 'dso';
  end

  switch output_case
    case 'dso'
      out                  = cat(1, file_struct.data);
      out                  = dataset(out);
      out.axisscale{2}     = linspace(file_struct(1).firstx, file_struct(1).lastx, file_struct(1).numpts);
      out.axisscalename{2} = xaxis_unit{file_struct(1).xaxis+1};
      out.axisscalename{1} = yaxis_unit{file_struct(1).yaxis+1};

      [paths,names,exts]   = cellfun(@fileparts, {file_struct.file_name}, 'UniformOutput', false);
      out.label{1,1}       = names;
      out.labelname{1,1}   = 'ASF file name';
      out.label{1,2}       = {file_struct.date_time};
      out.labelname{1,2}   = 'Date and time';
      out.label{1,3}       = {file_struct.title};
      out.labelname{1,3}   = 'Title';
      out.userdata.asf.hdr = {file_struct.hdr_data};
      out.userdata.asf.fmt = {file_struct.fmt_string};
      %Add source entries to history field.
      for i = 1:length(file_struct)
        out = addsourceinfo(out,file_struct(i).file_name);
      end
        
    case 'cell'
      for lll = 1:length(file_struct)
        cur_dso                  = dataset(file_struct(lll).data);
        cur_dso.axisscale{2}     = linspace(file_struct(lll).firstx, file_struct(lll).lastx, file_struct(lll).numpts);
        cur_dso.axisscalename{2} = xaxis_unit{file_struct(lll).xaxis+1};
        cur_dso.axisscalename{1} = yaxis_unit{file_struct(lll).yaxis+1};
        [path,name,ext]          = fileparts(file_struct(lll).file_name);
        cur_dso.label{1,1}       = name;
        cur_dso.labelname{1,1}   = 'ASF file name';
        cur_dso.label{1,2}       = file_struct(lll).date_time;
        cur_dso.labelname{1,2}   = 'Date and time';
        cur_dso.label{1,3}       = file_struct(lll).title;
        cur_dso.labelname{1,3}   = 'Title';
        cur_dso.userdata.asf.hdr = file_struct(lll).hdr_data;
        cur_dso.userdata.asf.fmt = file_struct(lll).fmt_string;
        cur_dso = addsourceinfo(cur_dso,file_struct(lll).file_name);
        out{lll} = cur_dso;
      end
      if strcmp(options.nonmatching,'matchvars')
        out = matchvars(out);
        for lll = 1:length(file_struct)
          out = addsourceinfo(out,file_struct(lll).file_name);
        end
      end

  end

catch
  fclose all;
  err = lasterror;
  err.message = ['ASFREADR: reading "' file_struct(lll).file_name '"' 10 error_str 10 err.message];
  rethrow(err);

end






