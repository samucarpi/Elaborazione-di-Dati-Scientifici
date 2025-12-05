function out = writeasf(x, filename, options)
%WRITEASF Writes AIT ASF files from a dataset object.
% INPUT:
%   x        = dataset object
%   filename = a text string with the name of an ASF file or
%              a cell of strings of ASF filenames.
%     If (filename) is omitted or an empty cell or array, the user will be
%     prompted to select a folder and then one or more files in the
%     identified folder. If (filename) is a blank string '', the user will
%     be prompted to select a single file.
% OPTIONAL INPUT:
%   options = an options structure containing one or more of the following
%    fields:
%       lfn : [ 'yes' | 'no'] Governs behavior when long file names are
%       allowed; setting to 'no' generates output file(s) that are
%       compatible with 8.3 file naming convention
%
%
%I/O: writeasf(x)
%I/O: writeasf(x, 'filename')
%I/O: writeasf(x, 'filename', options)
%
%See also: ASFREADR, AUTOEXPORT, EDITDS, JCAMPREADR, SPCREADR, TEXTREADR

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB¨, without
% written permission from Eigenvector Research, Inc.
%RR

% if nargin == 0; x = 'io'; end
% if ischar(x);
%   options = [];
%   options.lfn = 'no';
%   if nargout==0; clear out; evriio(mfilename,x,filename,options); else out = evriio(mfilename,x,filename,options); end
%   return;
% end


%This function is not available for 6.5.
if checkmlversion('<','7')
  error('WRITEASF does not work with older versions (R13 and below) of Matlab.')
end

if nargin == 0; x = 'io'; end
if ischar(x);
  options = [];
  options.lfn = 'yes';
  if nargout==0; clear out; evriio(mfilename,x,options); else out = evriio(mfilename,x,options); end
  return;
end

if nargin<3;
  options = [];
end
options = reconopts(options, mfilename);


if nargin<2; %no file name specified
  [filename,pth] = evriuiputfile({'*.asf' 'Analect spectral files (*.asf)'});
  if ~ischar(filename) & filename == 0;
    return;
  end
  filename = str2cell(fullfile(pth,filename)); %single file name to be used for all output
  options.lfn = 'yes';
end

if ~isa(x,'dataset');
  x = dataset(x);
end

if ~iscell(filename)
  filename = str2cell(filename);
end

% now make sure that all file names entered have the correct extension
msng_ext = cellfun(@isempty, regexp(filename, '\.[Aa][Ss][Ff]$'));
if any(msng_ext)
  filename(msng_ext) = cellfun(@(x)(cat(2, x, '.asf')), ...
    filename(msng_ext), 'uniformoutput', false);
end


try

  error_str = 'Error creating output file(s)';


  if isfield(x.userdata, 'asf') & ...
      all(isfield(x.userdata.asf, {'hdr' 'fmt'})) & ...
      ~isempty(x.userdata.asf.hdr) & ...
      ~isempty(x.userdata.asf.fmt)  %dso created with ASFREADR
    samps_incl = x.include{1};
    filename = mod_filename(x, filename, options);
    error_str = 'Error writing data';
    for lll = 1:length(samps_incl)
      fid = fopen(filename{lll}, 'w');
      fwrite(fid, x.userdata.asf.hdr{lll}, 'uint8');
      fwrite(fid, x.data(samps_incl(lll),:), x.userdata.asf.fmt{lll});
      fclose(fid);
    end
  else
    % assume dso not created by ASFREADR
    samps_incl = x.include{1};
    filename = mod_filename(x, filename, options);
    error_str = 'Error writing data';
    for lll = 1:length(samps_incl)
      def_hdr = create_hdr(x, samps_incl(lll));
      fid = fopen(filename{lll}, 'w');
      fwrite(fid, def_hdr, 'uint8');
      fwrite(fid,x.data(samps_incl(lll),:), 'float32');
      fclose(fid);
    end

  end

catch
  err = lasterror;
  err.message = ['WRITEASF: ' error_str 10 err.message];
  rethrow(err);
end


function nfilename = mod_filename(dso, filename, ops)

% if ops.lfn = 'no', use 8.3 naming convention
% first remove extensions and white space

base_filename = regexp(filename, '.+(?=\.[Aa][Ss][Ff]$)', 'match');
% convert cell array of cell(s)
% to cell array of string(s)
filename = cellfun(@char, base_filename, 'uniformoutput', false);

if strcmpi(ops.lfn, 'no')
  for lll = 1:length(filename)
    [cur_path, cur_file] = fileparts(filename{lll});
    cur_file = regexprep(cur_file, ' ', '');
    if length(cur_file) > 8
      cur_file = cur_file(1:8);
    end
    % reducing the number of characters to eight - reduce further later if
    % needed
    filename{lll} = fullfile(cur_path, cur_file);
  end
  % reducing the number of characters for each file name to eight - may
  % need to reduce further depending upon the number of unique file names
  % and the number of included sampled
end



n_fn = length(unique(filename)); % make sure file names are unique
samps_incl = dso.include{1};
n_samps_incl = length(samps_incl);

%  if number of samples included is less than the number of
%  unique file names, piece of cake
if n_samps_incl < n_fn
  nfilename = unique(filename); % Fewer included samples than unique supplied filenames
else
  nfilename = filename;         % No need to do anything
end

%  if number of samples included is greater than or equal to the number of
%  unique file names, use the first file name in the list and append an
%  underscore and numbers
if n_samps_incl > n_fn
  [cur_path, base_filename] = fileparts(filename{1});
  n_inds_digits = length(num2str(n_samps_incl)) + 1;
  if strcmpi(ops.lfn, 'no')
    base_filename = base_filename(1:8 - n_inds_digits);
  end
  fnmat = repmat(fullfile(cur_path,base_filename), n_samps_incl, 1); % use first file name as template
  fnmat = str2cell(fnmat);
  for lll = 1:n_samps_incl
    inds{lll} = sprintf('_%s', num2str(lll));
  end
  inds = inds(:);
  nfilename = cellfun(@(a,b)cat(2,a,b), fnmat, inds, 'uniformoutput', false);
end
nfilename = cellfun(@(a)cat(2,a, '.asf'), nfilename, 'uniformoutput', false);

function hdr = create_hdr(dso, row)

% creates a default header for the ASF data file

npts = size(dso, 2);
max_val = max(dso.data(row,:));
min_val = min(dso.data(row,:));

max_val = ceil(double(max_val));
min_val = floor(double(min_val));


hdr = uint8(zeros(946,1));

% now enter default values

% first descriptor
% pointer to next descriptor - offset 16 (10h)
hdr(1) = uint8(16);
% size of descriptor
hdr(9) = uint8(16);
% version number
hdr(13) = uint8(100);
% component type - AFHEADER
hdr(15) = uint8(6);
% file type - TRACEFILE
hdr(16) = uint8(1);

% second descriptor
% pointer to next descriptor - offset 930 (3A2h)
hdr(17) = uint8(162);
hdr(18) = uint8(3);
% size of descriptor + header block = 914 (392h)
hdr(25) = uint8(146);
hdr(26) = uint8(3);
%version number
hdr(29) = uint8(100);
% component type - TRACEHEADER
hdr(31) = uint8(2);
% file type - TRACEFILE
hdr(32) = uint8(1);

% ASF header
% calculate the number of seconds between now and 19700101T000000
num_secs = uint32((now - datenum([1970 1 1 0 0 0]))*24 * 3600);
hdr(33:36) = revintbytes(num_secs);
% number of points
hdr(41:44) = revintbytes(uint32(npts));

if isempty(dso.axisscale{2,1})
  % x-axis leftmost value = 1
  hdr(89:92) = revintbytes(single(1));
  % x-axis rightmost value = npts
  hdr(93:96) = revintbytes(single(npts));
  % spacing between data points = 1.0
  hdr(131) = uint8(128);
  hdr(132) = uint8(63);
else
  le = dso.axisscale{2,1}(1);
  re = dso.axisscale{2,1}(end);
  delta = (re - le)/(npts - 1);
  hdr(89:92) = revintbytes(single(le));
  hdr(93:96) = revintbytes(single(re));
  hdr(129:132) = revintbytes(single(delta));
end


% scale factor = 1
hdr(107) = uint8(128);
hdr(108) = uint8(63);
% yorg
hdr(97:100) = revintbytes(single(min_val));
% ymax
hdr(101:104) = revintbytes(single(max_val));
% header structure version number = 300
hdr(151) = uint8(44);
hdr(152) = uint8(1);
% trace data format = DFMT_FLT4
hdr(171) = uint8(4);
% title
tstr = uint8('Created from PLS_Toolbox');
hdr(185:185 + length(tstr) -1) = tstr;


% last descriptor
% size of descriptor + data block
comp_size = 16 + 4*npts;
hdr(939:942) = revintbytes(uint32(comp_size));
% version number
hdr(943) = uint8(100);
% component type = TRACEDATA
hdr(945) = uint8(1);
% file type = TRACEFILE
hdr(946) = uint8(1);

%-----------------------------------------------------
%value-safe version of swapping integer bytes
function res = revintbytes(val)

switch class(val)
  case 'uint32'
    hex_str = dec2hex(swapbytes(val));
  otherwise
    hex_str = num2hex(swapbytes(val));
end
while length(hex_str)<8;
  hex_str = ['0' hex_str];  %pad with missing zero(s) if <8 bytes long
end
hex_str = reshape(hex_str, 2, 4)';
res = uint8(hex2dec(hex_str));











