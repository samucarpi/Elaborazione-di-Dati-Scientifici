function out = brukerxrpdreadr(filenames,options)
%BRUKERXRPDREADR Read Bruker raw files for XRPD data.
% Reads X-ray Powder Diffraction data from the Bruker Raw file format.
%
% INPUTS:
%   filenames = a string file name or a cell array of multiple file names
%               to read.
% OPTIONAL INPUTS:
%   options = a structure with one or more of the following fields:
%          waitbar : [ 'off' | 'on' |{'auto'}] governs the display of a
%                     waitbar when loading multiple files. If 'auto',
%                     waitbar is displayed for larger sets of files only.
%      nonmatching : [ 'error' | 'cell' |{'match'}] Governs behavior when
%                     multiple files are being read which cannot be
%                     combined due to mismatched types, sizes, etc.
%                     'match' aligns all files to axis scale on first
%                     file, 'cell' returns cell (see outputs, below)
%                      'error' throws an error.
%      multiselect : [ 'off' | {'on'} ] governs whether file selection
%                     dialog should allow multiple files to be selected
%                     and imported. Setting to 'off' will restrict user to
%                     importing only one file at a time.
% OUTPUTS:
%  data = normally a DataSet object with the data read from all files. If
%         nonmatching option is 'cell' and selected files did not have
%         matching axis scales, then data will be a cell array with one
%         file's data in each cell.
%
%I/O: data = brukerxrpdreadr('filename',options)
%I/O: data = brukerxrpdreadr({'filename' 'filename2'},options)
%
%See also: ASDREADR, ASFREADR, EDITDS, HJYREADR, JCAMPREADR, OPUSREADR, PDFREADR, SPAREADR, SPCREADR, TEXTREADR

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%check for evriio input
if nargin==1 && ischar(filenames) && ismember(filenames,evriio([],'validtopics'));
  options = [];
  options.multiselect = 'on';
  options.nonmatching = 'match';
  options.waitbar     = 'auto';
  if nargout==0; clear out; evriio(mfilename,filenames,options); else out = evriio(mfilename,filenames,options); end
  return;
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
  [filenames, pathname, filterindex] = evriuigetfile({'*.RAW; *.raw', 'Bruker RAW files'; '*.*', 'All files'}, 'Open Bruker pattern file','MultiSelect', options.multiselect);
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

length_of_format_string = 8;
format_pat = 'RAW1.01';
location_of_date_string = 16;
length_of_date_string   = 10;
location_of_time_string = 26;
length_of_time_string   = 10;
location_of_user_string = 36;
length_of_user_string   = 72;
location_of_site_string = 108;
length_of_site_string   = 218;
location_of_ID_string   = 326;
length_of_ID_string     = 60;


location_of_numrecords  = 716;
location_of_firstx      = 728;
location_of_xspacing    = 888;
location_of_supp_hdr_sz = 968;

location_of_data        = 1016;

file_struct = struct('file_name', {}, 'valid_file', {},'firstx', {}, 'xspacing', {}, 'data', {}, 'xaxis', {},  'date', {}, 'time', {}, 'user', {}, 'site', {}, 'ID', {});
for lll = 1:length(filenames)
  file_struct(lll).file_name = filenames{lll};
end

nfiles=length(file_struct);

%waitbar logic
if strcmp(options.waitbar,'on')
  wbh = waitbar(0,'Loading XRPD Files...');
else
  wbh = [];
end
starttime = now;
lastupdate = 0;

for lll = 1:nfiles
  try
    fid = fopen(file_struct(lll).file_name, 'rb');
    if fid < 0
      file_struct(lll).valid_file = false;
      continue
    end
    cur_str = fread(fid, length_of_format_string, 'uchar');
    cur_str = char(cur_str(cur_str>0)');
    if isempty(regexp(cur_str, format_pat,'once'))
      file_struct(lll).valid_file = false;
      fclose(fid);
      continue
    end
    file_struct(lll).valid_file = true;
    
    fseek(fid, location_of_date_string, 'bof');
    cur_str = fread(fid, length_of_date_string, 'uchar');
    datestrn = char(cur_str(cur_str>0)');
    
    fseek(fid, location_of_time_string, 'bof');
    cur_str = fread(fid, length_of_time_string, 'uchar');
    timestr = char(cur_str(cur_str>0)');
    
    fseek(fid, location_of_user_string, 'bof');
    cur_str = fread(fid, length_of_user_string, 'uchar');
    userstr = char(cur_str(cur_str>0)');
    
    fseek(fid, location_of_site_string, 'bof');
    cur_str = fread(fid, length_of_site_string, 'uchar');
    sitestr = char(cur_str(cur_str>0)');
    
    fseek(fid, location_of_ID_string, 'bof');
    cur_str = fread(fid, length_of_ID_string, 'uchar');
    IDstr   = char(cur_str(cur_str>0)');
    
    
    file_struct(lll).date = datestrn;
    file_struct(lll).time = timestr;
    file_struct(lll).user = userstr;
    file_struct(lll).site = sitestr;
    file_struct(lll).ID   = IDstr;
    
    fseek(fid, location_of_numrecords, 'bof');
    num_data_points = fread(fid, 1, 'integer*4');
    
    fseek(fid, location_of_firstx, 'bof');
    firstx   = fread(fid, 1, 'real*8');
    fseek(fid, location_of_xspacing, 'bof');
    xspacing = fread(fid, 1, 'real*8');
    
    file_struct(lll).firstx   = firstx;
    file_struct(lll).xspacing = xspacing;
    
    fseek(fid, location_of_supp_hdr_sz, 'bof');
    num_supp_bytes = fread(fid, 1, 'integer*4');
    
    fseek(fid, location_of_data + num_supp_bytes, 'bof');
    %fseek(fid, -location_of_data*4, 'eof');
    
    data = fread(fid, num_data_points, 'real*4');
    %data = fread(fid, inf, 'real*4');
    fclose(fid);
    
    data = data(:)';
    num_data_points = length(data);
    
    file_struct(lll).data  = data;
    % let's test this here
    file_struct(lll).xaxis = cumsum([firstx xspacing*ones(1, num_data_points-1)]);
    
  catch
    file_struct(lll).valid_file = false;
  end
  
  if ~mod(lll,5)
    elap = (now-starttime)*24*60*60;
    est = elap*(nfiles-lll)/lll;
    if isempty(wbh) 
      if elap>3 & est>10 & strcmp(options.waitbar,'auto')
        wbh = waitbar(lll/nfiles,'Loading XRPD Files...');
      end
    elseif elap>3 & (now-lastupdate)*60*60*24>1  %if we're at least 3 seconds in (with a waitbar already) and 1 second since last update
      drawnow;
      if ~ishandle(wbh)
        error('User Aborted File Import');
      end
      waitbar(lll/nfiles,wbh);
      set(wbh,'name',['Est. Time Remaining ' besttime(round(est))])
      lastupdate = now;
    end
  end
end

if ishandle(wbh); delete(wbh); end

% parse out entries that are not valid files
file_struct = file_struct([file_struct.valid_file]);
% if the file_struct is empty, let's end it right here
if isempty(file_struct)
  out = [];
  return
end
  
% can we combine the data into a single dataset object?
% first test - same number of data points
% second test - xaxis starts at the same point
% third test - xaxis spacing is the same for each

numpoints = arrayfun(@(x)length(x.data), file_struct);
firstx = [file_struct.firstx];
xspacing = [file_struct.xspacing];

matched = all([std(numpoints)./sum(numpoints) std(firstx)./sum(firstx) std(xspacing)./sum(xspacing)] < 1e-9);

if ~matched
  %axes do NOT match... how to handle
  switch options.nonmatching
    case 'error'
      error('Files are not compatible and cannot be combined')
      
    case 'match'
      %MAKE them match
      out = cell(1, nfiles);
      for lll = 1:nfiles
        cur_dso = dataset(file_struct(lll).data);
        cur_dso.axisscale{2} = file_struct(lll).xaxis;
        if lll==1
          first_dso = cur_dso;
        else
          %use matchvars to align, then insert back into structure
          cur_dso = matchvars(first_dso,cur_dso);
          file_struct(lll).data = cur_dso.data;
          file_struct(lll).xaxis = cur_dso.axisscale{2};
        end
      end
      
      matched = true;  %NOW they match, use code below
      
    case 'cell'
      %insert each dataset object in a separate cell array entry
      out = cell(1, nfiles);
      for lll = 1:nfiles
        cur_dso = dataset(file_struct(lll).data);
        out.name = file_struct.file_name;
        cur_dso.axisscale{2} = file_struct(lll).xaxis;
        [path,name] = fileparts(file_struct(lll).file_name);
        cur_dso.label{1,1} = name;
        cur_dso.labelname{1,1} = 'RAW file name';
        cur_dso.label{1,2} = [file_struct(lll).date ' ' file_struct(lll).time];
        cur_dso.labelname{1,2} = 'date & time';
        cur_dso.label{1,3} = [file_struct(lll).user ' ' file_struct(lll).site];
        cur_dso.labelname{1,3} = 'user & site';
        cur_dso.label{1,4} = file_struct(lll).ID;
        cur_dso.labelname{1,4} = 'sample ID';
        cur_dso.axisscale{2} = file_struct(lll).xaxis;
        cur_dso = addsourceinfo(cur_dso,file_struct(lll).file_name);
        out{lll} = cur_dso;
      end
      
  end
end

if matched
  % combine into single dataset object - use first entry as pattern
  xblock = cat(1, file_struct.data);
  out = dataset(xblock);
  if nfiles>1
    out.name = 'Multiple XRPD files';
  else
    out.name = file_struct.file_name;
  end
  out.axisscale{2} = file_struct(1).xaxis;
  [paths,names] = cellfun(@fileparts, {file_struct.file_name}, 'UniformOutput', false);
  out.label{1,1} = names;
  out.labelname{1,1} = 'RAW file name';
  out.label{1,2} = [(char({file_struct.date}')) char(32*ones(nfiles,1)) (char({file_struct.time}'))];
  out.labelname{1,2} = 'date & time';
  out.label{1,3} = [(char({file_struct.user}')) char(32*ones(nfiles,1)) (char({file_struct.site}'))];
  out.labelname{1,3} = 'user & site';
  out.label{1,4} = {file_struct.ID}; out.labelname{1,4} = 'sample ID';

  %Add source entries to history field.
  for i = 1:nfiles
    out = addsourceinfo(out,file_struct(i).file_name);
  end
  
end

