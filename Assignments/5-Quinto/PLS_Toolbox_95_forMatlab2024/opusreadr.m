function out = opusreadr(filenames,options)
%OPUSREADR Reads Bruker OPUS files.
% INPUT:
%   filename = a text string with the name of an OPUS file or
%              a cell of strings of OPUS filenames.
%     If (filename) is omitted or an empty cell or array, the user will be
%     prompted to select a folder and then one or more files in the
%     identified folder. If (filename) is a blank string '', the user will
%     be prompted to select a single file.
% OPTIONAL INPUT:
%   options = an options structure containing one or more of the following
%    fields:
%       spectrumtype : [''] Specify which data type to read. If empty, the
%                      most commonly used type is selected (based on the
%                      "typepriority" option below) Spectrum types include:
%             'absorbance', 'transmittance', 'kubelka-munck spectrum',
%             'trace', 'raman spectrum', 'emission', 'reflectance'
%             (among others). The entire list of types can be obtained by
%             calling opusreader with the keyword 'types'.
%       typepriority : Specifies a list of spectrum types (in numerical
%                      format) in the order that the given block type
%                      should be selected if present. This list is used
%                      when the spectrumtype is empty, indicating that the
%                      most common block should be used.
%         multiblock : [{1}] Defines which block to read when more than one
%                      block in a file has the "spectrumtype" type. The
%                      value can be any integer between 0 (zero) and
%                      infinity but the following are typical settings:
%                        0 = Throws an error "multiple blocks are present"
%                        1 = Always choose the first block matching the
%                            type. The first block is usually the original,
%                            un-preprocessed version of the data.
%                      inf = Always choose the last block mathcing the
%                            type. The last block is usually a modified
%                            (processed) version of the data.
%                      2-n = Chooses the specified block matching the type
%                            Mostly useful when an exact sequence of steps
%                            have been used in creating the OPUS file and
%                            the user knows a specific step in that
%                            sequence is the version of the data needed.
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
%           sorttype : [{'none'} | 'time' | 'name']  Determines wether the
%                      output dataset will be sorted by the spectrum 
%                      timestamp, input filenames, or not at all. 
%          waitbar : [ 'off' | 'on' |{'auto'}] governs the display of a
%                     waitbar when loading multiple files. If 'auto',
%                     waitbar is displayed for larger sets of files only.
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
%       3) A row classset named 'Instrument Serial Number' is created using the numeric value of the SRN ENUM for each file.   
%
%I/O: out = opusreadr
%I/O: out = opusreadr(filename,options)
%I/O: out = opusreadr({filename filename2},options)
%I/O: list = opusreadr('types');  %return list of block types supported
%
%See also: ASDREADR, ASFREADR, BRUKERXRPDREADR, EDITDS, HJYREADR, JCAMPREADR, PDFREADR, SPAREADR, SPCREADR, TEXTREADR, WRITEASF

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%RR

%check for evriio input
if nargin==1 & ischar(filenames) & ismember(filenames,evriio([],'validtopics'))
  options = [];
  options.spectrumtype = '' ;
  options.typepriority = [ 9    10    17    19     4    15    16    12    11    18     5     6     7    14     8     2     3     1    13];  %see getdbtype and opusreadr('types') command
  options.multiblock = 1;
  options.waitbar = 'on';
  options.multiselect = 'on';
  options.sorttype = 'none';
  options.nonmatching = 'matchvars';
  if nargout==0; clear out; evriio(mfilename,filenames,options); else out = evriio(mfilename,filenames,options); end
  return;
elseif nargin==1 & ischar(filenames) & strcmpi(filenames,'types')
  out = getdbtype;
  return;
end

%This function is not available for 6.5.
%Jer - this is a carryover from asfreadr . . . what's specific about
%asfreadr that older versions of Matlab will not work?
if checkmlversion('<','7')
  error('OPUSREADR does not work with older versions (R13 and below) of Matlab.')
end

% parse other possible inputs
% no inputs? set input = '' (to trigger single file read)
if nargin==0
  filenames = {};
end
%check if there are options and reconcile them as needed
if nargin<2
  %no options!?! use empty
  options = [];
end
options = reconopts(options,mfilename);

spectrumtype = options.spectrumtype;

% if no file list was passed
if isempty(filenames)
  %do actual read for filename
  [filenames, pathname, filterindex] = evriuigetfile({'*.*', 'All files'}, 'Open OPUS spectral file','MultiSelect', options.multiselect);
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
      dir_files = dir_files(~[dir_files.isdir]);
      % strip out any directories in case wildcard was used
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

% need to check each file to make sure that it's a valid OPUS file

is_opus = true(length(filenames), 1);
magic_number = uint32(4278061578);

for lll = 1:length(filenames)
  [fid msg]  = fopen(filenames{lll}, 'r');
  if isequal(fid, -1)
    error(['File ''' filenames{lll} ''' does not exist or some other similar error (check directory)']);
  end
  
  mag_num_test_val = fread(fid, 1, 'uint32');
  if ~isequal(mag_num_test_val, magic_number)
    is_opus(lll) = false;
  end
  fclose(fid);
end

filenames = filenames(is_opus);
% exclude files that cause a file open error or is not an OPUS file

% shortcut out if none are opus files
if isempty(filenames)
  error('Input contains no valid OPUS files.');
end

% identify the spectrum type needed
dbtype = getdbtype(spectrumtype);


%initialize array of serial numbers 

serial_numbers = cell(length(filenames),1);
[serial_numbers{1:length(filenames), 1}] = deal('Instrument Serial Number Not Found');

try
  start = now;
  h = [];
  for lll = 1:length(filenames)
    fid = fopen(filenames{lll});
    fseek(fid, 4, 'bof');
    % move past magic number
    vers_num   = fread(fid, 1, 'float64');
    firstBlock = fread(fid, 1, 'int32');
    maxBlock   = fread(fid, 1, 'int32');
    numBlocks  = fread(fid, 1, 'int32');
    
    fseek(fid, firstBlock, 'bof');
    block = [];
    for j = 1:numBlocks
      block(j).type = fread(fid, 1, 'int32');
      block(j).len = fread(fid, 1, 'int32');
      block(j).offset = fread(fid, 1, 'int32');
    end
    
    % now find the data block and the data parameter block
    % for now, extracting only the user-requested block type
    dbscplx   = bitand(bitshift([block.type],   0),   3);
    dbsstyp   = bitand(bitshift([block.type],  -2),   3);
    dbsparam  = bitand(bitshift([block.type],  -4),  63);
    dbsdata   = bitand(bitshift([block.type], -10), 127);
    dbsderiv  = bitand(bitshift([block.type], -17),   3);
    dbsextnd  = bitand(bitshift([block.type], -19), 127);
    dbsparam_dbtdstat = bitand(bitshift([block.type],  -4), 3); % 1=data status parameter
    bit31     = bitand(bitshift([block.type], -30), 1);  % =1 initially. =0 if spectrum modified by user
    
    if isempty(dbtype)
      %no selected type? search available block types for the highest
      %priority one
      priorder = 1:128;
      priorder(options.typepriority) = 1:length(options.typepriority); %vector giving priority for each type (used as index)
      availtypes = unique(dbsdata(dbsextnd==0 & dbsdata>0));    %get available types
      if ~isempty(availtypes)
        priwhat = min(priorder(availtypes));     %which priority index did we choose?
        dbtype = options.typepriority(priwhat);  %convert it to a block type
      else
        dbtype = getdbtype('absorbance');  %fallback if nothing else defined
      end
      spectrumtype = getdbtype(dbtype);
    end
    spectrum        = dbsdata==dbtype & dbsextnd==0;
    param_und       = dbsparam==0;
    
    % Use modified data block, if available
    data_block      = find(spectrum & param_und & bit31==0);             % user modified
    if isempty(data_block)
      data_block      = find(spectrum & param_und & bit31==1);
    end

    % Use modified data parameter block, if available    
    data_parm_block = find(spectrum & dbsparam_dbtdstat==1 & bit31==0);  % user modified
    if isempty(data_parm_block)
      data_parm_block = find(spectrum & dbsparam_dbtdstat==1 & bit31==1);
    end
    
    
    %   DBSDATA = bitand(bitshift([block.type], -10), 127) == 4;       % <- 4=absorbance spectrum data
    %   DBSPARM_und = bitand(bitshift([block.type], -4), 63) == 0;     % <- 0=undefined parameters
    %   DBSPARM_DBTDSTAT = bitand(bitshift([block.type], -4), 3) == 1; % <- 1=data status parameter
    %   data_block = find(bitand(DBSDATA, DBSPARM_und));               % abs spectrum AND undef param
    %   data_parm_block = find(bitand(DBSDATA, DBSPARM_DBTDSTAT));     % abs spectrum AND data status parameter
    
    %     % data_block should usually be single valued. Error if =0
    %     % If there are > 1 matching blocks then use option.multiblock to choose
    if isempty(data_block)
      error('Input file <%s> does not contain any %s data blocks', filenames{lll}, spectrumtype)
    elseif length(data_block) > 1
      %multiple blocks match the type? use options.multiblock to decide
      %which to choose. "inf" will choose last one (usually something with
      %additional processing). one (1) chooses basic unprocessed data, zero
      %(0) throws error.
      if isempty(options.multiblock) | options.multiblock<1
        error('Input file: (%s) contains more than one (%d) data blocks of type %s', filenames{lll}, length(data_block), spectrumtype)
      end
      iuse = min(length(data_block),options.multiblock);
      data_block = data_block(iuse);  %choose the specified block from all matching ones
      
      if isempty(data_parm_block)
        error('Input file <%s> does not contain any %s data parameter blocks', filenames{lll}, spectrumtype)
      end
      data_parm_block = data_parm_block(iuse);
    end
    
    % now that the data blocks and the data parameter blocks have been identified,
    % need to get the relevant parameters (FXV, Lxv, NPT, date, and time)
    
    fseek(fid, block(data_parm_block).offset, 'bof');

    %initilize these values
    DAT_str = '';
    TIM_str = '';
    DXU_str = '';
    
    endFound = false;
    while ~endFound
      pname = fread(fid, 4, 'char');
      pname = char(pname(1:3))';
      ptype = fread(fid, 1, 'int16');
      prs   = fread(fid, 1, 'int16');
      switch ptype
        case 0
          pivalue = fread(fid, 1, 'int32');
        case 1
          pdvalue = fread(fid, 1, 'float64');
        otherwise  %usually string, enum, senum
          pstring = fread(fid, prs * 2, '*char')';
          pstring = char(pstring(1:min(strfind(pstring,0))-1));
      end  % end of switch

      switch pname
        case 'NPT'
          dblock(lll).NPT = pivalue;
        case 'FXV'
          dblock(lll).FXV = pdvalue;
        case 'LXV'
          dblock(lll).LXV = pdvalue;
        case 'DAT'
          dblock(lll).DAT = pstring;
          DAT_str = dblock(lll).DAT;
        case 'TIM'
          dblock(lll).TIM = pstring;
          TIM_str = dblock(lll).TIM;
        case 'DXU'
          dblock(lll).DXU = pstring;
          DXU_str = dxulookup(dblock(lll).DXU);
        case 'END'
          endFound = true;
      end  % end of case
    end  % end of while

    % Get Instrument Serial Number (SRN)
    srn = getsrn(fid, dbsparam);
    if (length(srn)>0) % If srn isn't empty, add to serial_numbers cell
      serial_numbers{lll} = srn;
    else
      serial_numbers{lll} = 'missing SRN';
    end
    
    % following "if" structure - if fields DAT and/or TIM are missing,
    % don't freak out - this means that the output dataset will not be
    % sorted by time
    
    if all([~isempty(TIM_str) ~isempty(DAT_str)])
      
      TIM_str_mod = regexprep(TIM_str, '\.[0-9]{1,}\s{1,}.{1,}', '');
      % strip out fractions of a second, white space and text after seconds
      % entry
      
      match_str = '(?<=\()(GMT|UTC)\s{0,}[+-]\s{0,}[0-9]{1,}(?=\))';
      dblock(lll).timestamp = datenum([DAT_str ' ' TIM_str_mod], ...
        'dd/mm/yyyy HH:MM:SS');
      if ~isempty(regexp(TIM_str, '(GMT|UTC)')) 
        UTC_begin = regexp(TIM_str, '(GMT|UTC)');
        UTC_begin = UTC_begin + 4;
        UTC_end   = strfind(TIM_str, ')');
        UTC_corr  = str2num(TIM_str(UTC_begin:UTC_end-1));
        dblock(lll).timestamp = dblock(lll).timestamp - UTC_corr/24;
        dblock(lll).timebasis = regexp(TIM_str, match_str, 'match');
      else
        dblock(lll).timestamp = 0;
      end
      if ~isempty(regexp(TIM_str, '(GMT|UTC)'))
        dblock(lll).timebasis = regexp(TIM_str, match_str, 'match');
      end
    else
      dblock(lll).timestamp = 0;
    end
    
    % now get the data
    fseek(fid, block(data_block).offset, 'bof');
    dblock(lll).data = fread(fid, dblock(lll).NPT, 'float32');
    
    fclose(fid);
    
    %show waitbar if it is a long load
    if ishandle(h)
      waitbar(lll/length(filenames),h);
    elseif ~isempty(h) & ~ishandle(h)
      error('User cancelled operation')
    elseif strcmp(options.waitbar,'on')
      h = waitbar(0,'Loading OPUS Files...');
    elseif strcmp(options.waitbar,'auto') & (now-start)>1/60/60/24 
      %Elapsed time greater than second then show waitbar.
      h = waitbar(0,'Loading OPUS Files...');
    end
  end
catch
  le = lasterror;
  if ishandle(h);
    delete(h);
  end
  rethrow(le)
end
if ishandle(h);
  delete(h);
end

% following "if" structure - if DAT or TIM fields were missing above, we
% cannot sort the data on the basis of date/timestamp so we just bypass the
% sorting steps

time_vals = [dblock.timestamp];
time_vals_sorted = time_vals;
if strcmp(options.sorttype, 'time') & ~any([dblock.timestamp]==0 )
  [time_vals_sorted, sort_inds] = sort(time_vals);
  filenames = filenames(sort_inds);
  short_filenames = filenames;  % use for lables
  dblock = dblock(sort_inds);
end

for j = 1:length(dblock)
  [path,name,ext] = fileparts(filenames{j});
  if ~isempty(ext)
    short_filenames{j} = [name  ext];
  else
    short_filenames{j} = name;
  end
end

% Check for consistency of samples
% FXV: First X Value
% LXV: Last X Value
% NPT: Number of Data Points
checkFXV =  all([dblock.FXV] == [dblock(1).FXV]);
checkLXV =  all([dblock.LXV] == [dblock(1).LXV]);
checkNPT =  all([dblock.NPT] == [dblock(1).NPT]);

if  checkFXV & checkLXV & checkNPT
  % Samples variables mode match without problem. Create output DSO
  xblock = zeros(length(dblock), dblock(1).NPT);
  for lll = 1:length(dblock)
    xblock(lll,:) = dblock(lll).data;
  end
  out = dataset(xblock);
  for j=1:length(dblock)
    out = addsourceinfo(out, filenames{j});
  end
  xvals = linspace(dblock(1).FXV, dblock(1).LXV, dblock(1).NPT);
  out.axisscale{2,1} = xvals;
  % following two "if" structures - have encountered some data where DXU,
  % DAT, and TIM fields from above are missing.  If date/timestamp info is
  % available for all files, the variable "time_vals" will exist at this
  % point and we can populate the axis scales for mode 1.  Similarly, DXU
  % is a text descriptor for axisscalename{2,1} - if missing, just leave it
  % blank
  if ~isempty(DXU_str)
    out.axisscalename{2,1} = DXU_str;
  end
  
  if exist('time_vals')
    out.axisscale{1,1} = time_vals_sorted;
    out.axisscalename{1,1} = 'date and time';
  end
  out.label{1} = short_filenames;
else
  % Samples do not match because of different mode 2 axisscales
  if strcmp(options.nonmatching, 'error') 
    error('X-axes of files do no match.')
  end
  
  out = {};
  for j = 1:length(dblock)
    xblock = zeros(length(dblock(j)), dblock(j).NPT);
    xblock(1,:) = dblock(j).data;
    out{j} = dataset(xblock);
    xvals = linspace(dblock(j).FXV, dblock(j).LXV, dblock(j).NPT);
    out{j}.axisscale{2,1} = xvals;
    
    %out{j}.class{1} = find(str2num(cell2mat(unique_serial_numbers')) == str2num(serial_numbers{j}))
    
    if ~isempty(DXU_str)
      out{j}.axisscalename{2,1} = DXU_str;
    end
    if exist('time_vals')
      out{j}.axisscale{1,1} = time_vals_sorted(j);
      out{j}.axisscalename{1,1} = 'date and time';
      out{j}.label{1,1} = short_filenames{j};
      out{j}.labelname{1,1} = 'File names';
    end
  end
  
  if strcmp(options.nonmatching, 'cell')
    for j=1:length(dblock);
      out{j} = addsourceinfo(out{j}, filenames{j});
    end
  else  % Use 'matchvars'
    % apply matchvars
      out = matchvars(out);
      out = addsourceinfo(out, filenames);
      out.name = 'Multiple Bruker OPUS files';
  end
end

out.classid{1} = serial_numbers;
out.classname{1} = 'Instrument Serial Numbers';

if strcmp(options.sorttype, 'name')
   out = sort_by_name(out);
end

%--------------------------------------------------------------------------
function dbsdata = getdbsdata
%
dbsdata.DBTSPEC    =  1;     % spectrum, undefined Y-units
dbsdata.DBTIGRM    =  2;     % interferogram
dbsdata.DBTPHAS    =  3;     % phase spectrum
dbsdata.DBTAB      =  4;     % absorbance spectrum 
dbsdata.DBTTR      =  5;     % transmittance spectrum 
dbsdata.DBTKM      =  6;     % kubelka-munck spectrum 
dbsdata.DBTTRACE   =  7;     % trace (intensity over time) 
dbsdata.DBTGCIG    =  8;     % gc file, series of interferograms
dbsdata.DBTGCSP    =  9;     % gc file, series of spectra
dbsdata.DBTRAMAN   = 10;     % raman spectrum 
dbsdata.DBTEMIS    = 11;     % emission spectrum 
dbsdata.DBTREFL    = 12;     % reflectance spectrum 
dbsdata.DBTDIR     = 13;     % directory block
dbsdata.DBTPOWER   = 14;     % power spectrum (from phase calculation)
dbsdata.DBTLOGREFL = 15;     % - log reflectance (like absorbance) 
dbsdata.DBTATR     = 16;     % ATR-spectrum 
dbsdata.DBTPAS     = 17;     % photoacoustic spectrum 
dbsdata.DBTARITR   = 18;     % result of arithmetics, looks like TR 
dbsdata.DBTARIAB   = 19;     % result of arithmetics, looks like AB

%--------------------------------------------------------------------------
function dbtype = getdbtype(spectrumtype)
%lists block types (in order so their index matches the lookup for the
%dbtype code)
spectrumtypes = {
  'undefined Y-units'
  'interferogram'
  'phase'
  'absorbance'
  'transmittance'
  'kubelka-munck spectrum'
  'trace'
  'gc file, interferograms'
  'gc file, spectra'
  'raman spectrum'
  'emission'
  'reflectance'
  'directory block'
  'power'
  '- log reflectance'
  'ATR'
  'photoacoustic spectrum'
  'result of arithmetics, TR'
  'result of arithmetics, AB'
  };

if nargin>=1
  if ischar(spectrumtype)
    dbtype = find(ismember(lower(spectrumtypes(:,1)), lower(spectrumtype)));
  elseif length(spectrumtype)==1
    dbtype = spectrumtypes{spectrumtype};
  else
    dbtype = spectrumtypes(spectrumtype);
  end
else
  dbtype = spectrumtypes;
end


%--------------------------------------------------
function str = dxulookup(dxu)
%look up full string from abbreviated DXU string

dxu = upper(dxu);
lu = {
  'WN'  'Wavenumbers (cm-1)'
  'MI'  'Microns'
  'LGW' 'Log Wavenumbers'
  'MIN' 'Minutes'
  'PNT' 'Points'
  }';
lu  = struct(lu{:});  %convert cell to a structure
if isfield(lu,dxu)
  str = lu.(dxu);
else
  str = '';
end

%--------------------------------------------------
function ds_out = sort_by_name(ds_in)

nfn = str2cell(ds_in.label{1,1});
bsnms = regexp(nfn, '.{1,}(?=\.[0-9]{1,}$)', 'match');
% extract all portions of the labels prior to last period and extension
% if any of the extensions are non-numeric, 
if any(cellfun(@(x)isempty(x), bsnms))
  ds_out = ds_in;
  return
end
bsnms = [bsnms{:}];
unq_bsnms = unique(bsnms);
unq_bsnms = sort(unq_bsnms);
ds_cell = cell(length(unq_bsnms),1);

for jl = 1:length(unq_bsnms)
  cur_bsnm = unq_bsnms{jl};
  inds     = ~cellfun(@(x)isempty(x), regexp(nfn, cur_bsnm));
  cur_ds   = ds_in(inds,:);
  sub_lbls = str2cell(cur_ds.label{1,1});
  f_exts   = regexp(sub_lbls, '(?<=\.)[0-9]{1,}$', 'match');
  f_exts   = [f_exts{:}];
  f_exts   = cellfun(@(x)str2num(x),f_exts);
  [jnk, sort_inds] = sort(f_exts);
  cur_ds   = cur_ds(sort_inds, :);
  ds_cell{jl} = cur_ds;
end
  
ds_out = cat(1, ds_cell{:});

%--------------------------------------------------
function [srn] = extractsrn(stridx, strblk)
% Extract the SRN. Assume it is ascii-printable and null-terminated
srn = strblk((stridx+4):stridx+50); % 50 is arbitrary - want to make sure we get the full srn.
if ~(isempty(stridx))
  srn1 = regexprep(srn, '[^\x20-\x7E \x0]\x0', ''); % Replace all ASCII non-printables-plus-\x0, but not \x0\x0, with ''.
  inull = regexp(srn1, '\x0');  % index of the null-terminating char
  iend = inull(1)-1;
  srn = srn1(1:iend);
end

%--------------------------------------------------------------------------
function [srn] = getsrn(fid, dbsparam)
% Get the SRN (Instrument Serial Number) for this file
srn = '';
% Search the entire file for SRN (mark position, rewind then reset at end)
ipos = ftell(fid);       % save current position
fseek(fid, 4, 'bof');    % rewind

try
  % Read in the instrument serial number
  dbinstr_idx = find(dbsparam==2);
  if ~(isempty(dbinstr_idx)) % Assume PKA parameter always follows SRN.
    strblk = fread(fid, '*char'); % Get the entire column vector of chars
    strblk = strblk(:)';     % Transpose to make a string (row vector).
    stridx = regexp(strblk, 'SRN\x0'); % Get the starting index for 'SRN'
    
    if ~(isempty(stridx))
      for ii=1:length(stridx)
        srns{ii} = extractsrn(stridx(ii), strblk);
      end
      %       uniqsrns = unique(srns); % error if there are multiple different?
      srn = srns{1}; % use the first one
    end
  end
catch
  % don't let this cause import to fail
end
fseek(fid, ipos, 'bof'); % restore position