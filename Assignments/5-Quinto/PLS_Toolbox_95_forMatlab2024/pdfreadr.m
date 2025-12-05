function out = pdfreadr(filenames,options)
%PDFREADR Importer for AIT PIONIR PDF files.
%
% INPUTS:
%   filename = a text string with the name of a PDF file or a cell of
%               strings of PDF filenames.
%     If (filename) is omitted or an empty cell {} or array [], the user
%     will be prompted to select a folder and then one or more SPC files in
%     the identified folder. If (filename) is a blank string, the user will
%     be prompted to select a single file.
%
% OPTIONAL INPUTS:
%   options = an options structure containing one or more of the following
%        multiselect : [ 'off' | {'on'} ] governs whether file selection
%                      dialog should allow multiple files to be selected
%                      and imported. Setting to 'off' will restrict user to
%                      importing only one file at a time.
%
% OUTPUTS:
%   out = a dataset object containing the imported spectra as rows.
%
%I/O: out = pdfreadr
%I/O: out = pdfreadr('filename',options)
%I/O: out = pdfreadr({'filename' 'filename2'},options)
%
%See also: ASFREADR, EDITDS, JCAMPREADR, SPCREADR, TEXTREADR

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%RR

%check for evriio input
if nargin==1 && ischar(filenames) && ismember(filenames,evriio([],'validtopics'));
  options = [];
  options.multiselect = 'on';
  if nargout==0; clear out; evriio(mfilename,filenames,options); else out = evriio(mfilename,filenames,options); end
  return;
end

%This function is not available for 6.5.
if checkmlversion('<','7')
  error('PDFREADR does not work with older versions of Matlab (Version 7.0+ required).')
end

% parse other possible inputs
% no inputs? set input = [] (to trigger multi file read)
if nargin==0;
  filenames = [];
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
  [filenames, pathname, filterindex] = evriuigetfile({'*.PDF; *.pdf', 'PIONIR files (*.PDF)'; '*.*', 'All files'}, 'Open PIONIR spectral file','MultiSelect', options.multiselect);
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

num_vars   = 561;
first_xval = 800;
last_xval  = 1080;


try
  error_str = 'File I/O error - opening file';
  data = zeros(length(filenames), 561);
  for lll = 1:length(filenames)
    fid = fopen(filenames{lll}, 'rb');
    if fid < 0
      error('Error')
    end
    
    char_data = fread(fid, inf, 'uchar');
    char_data = char(char_data)';
    beg_of_data = regexp(char_data, '#DATA\x0D\x0A', 'end');
    end_of_hdr = regexp(char_data, '#DATA\x0D\x0A', 'start');
    end_of_hdr = end_of_hdr-1;
    hdr_data = char_data(1:end_of_hdr);
    % update 20091113 include file header info as a structure in the
    % userdata field of the output dataset object
    % RR
    error_str = 'File format error';
    if isempty(beg_of_data);
      fclose(fid);
      error('Error')
    end
    fseek(fid, beg_of_data, 'bof');
    float_data = fread(fid, inf, 'single');
    error_str = 'File error - incorrect number of data points';
    if ~ isequal(num_vars, length(float_data))
      fclose(fid);
      error('Error')
    end
    data(lll,:) = float_data;
    hdr_struct(lll) = make_hdr_struct(hdr_data);
    fclose(fid);
  end
  
  error_str = 'Error constructing dataset object';
  data = dataset(data);
  for lll = 1:length(filenames)
    [paths{lll} names{lll}] = fileparts(filenames{lll});
    data = addsourceinfo(data,filenames{lll});
  end
  data.label{1} = names;
  data.axisscale{2} = first_xval:0.5:last_xval;
  data.axisscalename{2} = 'nm';
  data.userdata.header = hdr_struct;
  
  
catch
  error(error_str);
  data = [];
end

out = data;

function out_struct = make_hdr_struct(hdr_data);

str_pat = '[\w\.\+ #\\:/,]{1,}(?=\r\n)';
reg_exp_matches = regexp(hdr_data, str_pat, 'match');
fields = {'hdr', 'file_info', 'source', 'start', 'stop', 'end', 'npts', ...
  'maxy', 'miny', 'units', 'type', 'hdr_mrkr', 'location', ...
  'analyzer_name', 'probe_id', 'temperature', 'pressure', 'addl_info_I', ...
  'addl_info_II'};
num_fields = length(fields);
num_matches = length(reg_exp_matches);
if ~isequal(num_fields, num_matches)
  if num_matches < num_fields
    reg_exp_matches = [reg_exp_matches repmat({''}, 1, ...
      num_fields-num_matches)];
  else
    reg_exp_matches = reg_exp_matches(1:num_fields);
  end
end
out_struct = cell2struct(reg_exp_matches, fields, 2);

