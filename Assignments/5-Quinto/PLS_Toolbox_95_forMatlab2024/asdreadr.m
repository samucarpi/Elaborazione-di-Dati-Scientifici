function varargout = asdreadr(filenames,options)
%ASDREADR Imports data from Analytical Spectral Devices (ASD) Indico (Versions 6 and 7) data files.
% INPUT:
%   filename = a text string with the name of an ASD file or a cell of strings of ASD filenames.
%     If (filename) is omitted or an empty cell or array, the user will be
%     prompted to select a folder and then one or more files in the
%     identified folder. If (filename) is a blank string '', the user will
%     be prompted to select a single file.
% OPTIONAL INPUT:
%   options = an options structure containing one or more of the following
%    fields:
%       requestedfields: [ {'ratio'} ] and/or any combination of:
%                         'spectrumdata' 'referencedata' 'basecalibrationdata'
%                         'lampcalibrationdata' 'fiberopticcalibrationdata'. A dataset will be
%                         returned for each field included. For example, 
%                             options.requestedfields= {'spectrumdata' 'ratio' };
%                             [spectrumdata ratio] = asdreadr(filenames, options);
%                         would lead to two datasets being returned, as indicated, in the same order
%                         as they are listed in options.requestedfields. The user must take care to 
%                         specify the returned variables in the same order as they are listed in 
%                         option.requestedfields.
%        multiselect : [ 'off' | {'on'} ] governs whether file selection
%                      dialog should allow multiple files to be selected
%                      and imported. Setting to 'off' will restrict user to
%                      importing only one file at a time.
%
%
% OUTPUT:
%   varargout = one or more dataset (IN SAME ORDER as names in options.requestedfields).
%     A dataset is returned for each valid requested ASD data field. The valid field names
%     are listed above for option.requestedfields. The default is 'ratio', which is the ratio
%     of the spectrum / reference fields.
%     For example, when options.requestedfields = {'spectrumdata' 'ratio'}
%     then the command "[ds1 ds2] = asdreadr(filenames, options);" will return two output
%     datasets, ds1 and ds2. The dataset ds1 contains the spectrumdata data (ds1.data)
%     with dimensions (nx x nchannels), where nx is the number of successfully imported files
%     and nchannels is the unique number of channels read in each file. Similarly dataset ds2
%     contains the requested 'ratio' data.
%     Header information read from each file is available in the dataset's userinfo
%     field, for example: ds1.userdata.asd.metadata(1).spectrumFileHeader
%     contains information from the SpectrumFileHeader section of the first imported file.
%     Log records of the importing process are available in ds1.userdata.asd.log.
%
%I/O: out = asdreadr    
%I/O: out = asdreadr('filename',options)
%I/O: out = asdreadr({'filename' 'filename2'},options)
%
%See also: ASFREADR, EDITDS, JCAMPREADR, SPCREADR, TEXTREADR

%Copyright Eigenvector Research, Inc. 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%

%check for evriio input
if nargin==1 && ischar(filenames) && ismember(filenames,evriio([],'validtopics'));
  options = [];
  options.requestedfields = {'ratio'};
  options.multiselect = 'on';
  if nargout==0; clear out; evriio(mfilename,filenames,options); else; varargout{1} = evriio(mfilename,filenames,options); end
  return;
end

varargout{1} = [];

%This function is not available for 6.5.
if checkmlversion('<','7')
  error('ASDREADR does not work with older versions (R13 and below) of Matlab.')
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

% Set default for options.requestedfields

options = reconopts(options,mfilename);

% if no file list was passed
if isempty(filenames)
  %do actual read for filename
  [filenames, pathname, filterindex] = evriuigetfile({'*.ASD; *.asd; ','ASD Spectral File';'*.*' 'All Files'}, 'Open ASD spectral file','MultiSelect', options.multiselect);
  if filterindex==0
    return
  else
    %got one or more filenames, add path to each
    if ~iscell(filenames)
      filenames = {filenames};
    end
    for ifile = 1:length(filenames)
      filenames{ifile} = fullfile(pathname,filenames{ifile});
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
      for ifile = 1:length(filenames)
        filenames{ifile} = fullfile(target_path,filenames{ifile});
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
error_str = 'File I/O error - check format of data file(s)';

% Read the files -----------------------------------------------------------------------------------
try
  params.numChannels = -1;
  validFileCounter = 0;
  for ifile = 1:length(filenames) 
    thisFilename = char(filenames(ifile));
    params.ifile = ifile;
    [this_file_struct, params] = readFile(thisFilename, params);
    % only valid files are added to allFilesStruct
    if(this_file_struct.valid_file)
      validFileCounter = validFileCounter+1;
      allFilesStruct(validFileCounter) = this_file_struct;
    else 
        error(disp(sprintf('Error reading file: %s', thisFilename)));
    end  
  end
catch
  fclose all;
  err = lasterror;
  err.message = ['ASDREADR: reading "' thisFilename '"' 10  error_str 10  err.message];
  rethrow(err);
end

%  all entries should be valid files
if any([allFilesStruct.valid_file] == false)
  error_str = 'Unable to open/read one or more files';
  error(error_str);
end

  % check data compatability:
  % first test - same number of data points
  % second test - xaxis starts at the same point
  % third test - xaxis spacing is the same for each
  error_str = 'Invalid parameter found in one or more files';
  allFilesStruct(ifile).spectrumFileHeader.ch1_wavel;
  allFilesStruct(ifile).spectrumFileHeader.wavel_step;
  test_mat  = [allFilesStruct.firstx; allFilesStruct.incx; allFilesStruct.channels]'; 

%   %additional test on data integrity
  valid_test = [
    [allFilesStruct.firstx   ] >0
    [allFilesStruct.incx] >0
    [allFilesStruct.channels] >0
    ];
  if any(~valid_test(:))
    error(error_str)
  end

  error_str = 'Error assembling output';
  uniq_vals = unique(test_mat, 'rows');
  if ~isequal(size(uniq_vals, 1),1)
      error_str = 'Files are not compatible and cannot be combined';
      error(error_str);
  end
    
  % Ensure the requested fields are from the standard data field names
  standardDataFields = {'ratio' 'spectrumdata' 'referencedata' 'basecalibrationdata' 'lampcalibrationdata' 'fiberopticcalibrationdata'};
  fieldindex = ismember(options.requestedfields, standardDataFields);
  % get the valid requested fields in the same order which they had in options.requestedfields
  requestedDataFields = options.requestedfields(fieldindex);
    
  badRequestedField = setdiff(options.requestedfields, standardDataFields);
  if length(badRequestedField) > 0
    error(['User requested unknown fields names: ' sprintf('%s ', badRequestedField{:})] );
  end
  
  % Extract requested data fields and create a dataset for each. -----------------------------------
  % Assign to varargout in the same order as names in options.requestedfields.
  for iout=1:length(requestedDataFields)
    outfieldName = requestedDataFields{iout};
    % get the data for this field
    if ~ismember(outfieldName,standardDataFields)
      error(['Error: ' outfieldName ' is not an available imported data field, or calculated field']);
    end

    varargout(iout) = {getDSO(allFilesStruct, outfieldName, standardDataFields)};
  end
  

%===================================================================================================
function val = readNextString(fid)
%READNEXTSTRING Reads next VB-style variable length string from file.
% Reads variable length string from file. Assumes the string has a prefix indicating its length. 
% The prefix is a two byte unsigned integer if string length is less than 2^16, otherwise
% the prefix consists of six bytes; two bytes each equal to 255, followed by a four byte unsigned
% integer indicating the string length.
len  = fread(fid,1,'uint16');
if len==65535;
  len = fread(fid,1,'uint32');
end;
val = fread(fid,len,'char')';

%===================================================================================================
function [this_file_struct,params] = readFile(file_name, params)
%READFILE Read contents of an ASD v.7 file into a dataset object.

this_file_struct = struct;
[path, fname, extension] = fileparts(file_name);
shortFilename = [fname extension];
this_file_struct.file_name = file_name;
this_file_struct.logrecords(1) = {['ASDREADR importer (' num2str(params.ifile) '):']};  % initial log record for this file

fid = fopen(file_name, 'rb', 'ieee-le');
if fid < 0
  this_file_struct.valid_file = false;
    error(['Failure reading file:  ' file_name]);
else
  this_file_struct.valid_file = true;
    this_file_struct.logrecords(end+1) = {(['Reading file:  ' file_name])};
end

% Support fileVersion = 'as6' or 'as7' but do not throw error if it is not as expected
fileVersion = fread(fid, 3, 'uint8=>char')';
this_file_struct.logrecords(end+1) = {['File version = ' fileVersion]};
% if ~(strcmpi(fileVersion', 'as6') | strcmpi(fileVersion', 'as7') )
%   error(['Error: ASD file (' shortFilename ') does not match Indico Version 7 File Format']);
% end

% Read ahead to get nchannels value
fseek(fid,204,'bof');
nchannels     = fread(fid, 1, 'integer*2');
if params.ifile == 1
  params.numChannels = nchannels;
elseif nchannels ~= params.numChannels
  error(['Error: ASD file (' shortFilename ') has different number of channels than last imported file']);
end

frewind(fid);

% initialize the struct (useful if error occurs in reading non-essential latter part of file)
this_file_struct.spectrumdata = repmat(nan, nchannels,1);
this_file_struct.referencedata = repmat(nan, nchannels,1);
this_file_struct.ratio = repmat(nan, nchannels,1);
this_file_struct.basecalibrationdata = repmat(nan, nchannels,1);
this_file_struct.lampcalibrationdata = repmat(nan, nchannels,1);
this_file_struct.fiberopticcalibrationdata = repmat(nan, nchannels,1);
this_file_struct.classifierData = struct;
this_file_struct.dependentVariables = struct;
this_file_struct.calibrationHeader = struct;

% Spectrum File Header
% Read the spectrum file header --------------------------------------------------------------------
sfh = [];
sfh.co     = fread(fid, 3, 'uint8=>char');
sfh.comments       = fread(fid, 157, 'uint8=>char');
sfh.when     = fread(fid, 18, 'uint8');
sfh.program_version     = fread(fid, 1, 'uint8');
sfh.file_version     = fread(fid, 1, 'uchar');
sfh.itime     = fread(fid, 1, 'uchar');
sfh.dc_corr     = fread(fid, 1, 'uchar');
sfh.dc_time     = fread(fid, 1, 'uint32'); % 4 byte long
sfh.data_type   = fread(fid, 1, 'uint8'); % 1 byte
% Spectrum data type (variable data_type at byte offset 186):
%     #define RAW_TYPE        (byte)0
%     #define REF_TYPE        (byte)1
%     #define RAD_TYPE        (byte)2
%     #define NOUNITS_TYPE    (byte)3
%     #define IRRAD_TYPE      (byte)4
%     #define QI_TYPE         (byte)5
%     #define TRANS_TYPE      (byte)6
%     #define UNKNOWN_TYPE    (byte)7
%     #define ABS_TYPE        (byte)8
sfh.ref_time     = fread(fid, 1, 'uint32'); % 4 byte long
sfh.ch1_wavel      = fread(fid, 1, 'real*4'); % 4 byte float
sfh.wavel_step     = fread(fid, 1, 'real*4'); % 4 byte float

sfh.data_format    = fread(fid, 1, 'uint8'); % 1 byte
% #define FLOAT_FORMAT    (byte)0
%     #define INTEGER_FORMAT  (byte)1
%     #define DOUBLE_FORMAT   (byte)2
%     #define UNKNOWN_FORMAT  (byte)3

sfh.old_dc_count = fread(fid, 1, 'uint8'); % 1 byte
sfh.old_ref_count    = fread(fid, 1, 'uint8'); % 1 byte
sfh.old_sample_count    = fread(fid, 1, 'uint8'); % 1 byte
sfh.application    = fread(fid, 1, 'uint8'); % 1 byte
fseek(fid,204,'bof');
sfh.channels     = fread(fid, 1, 'integer*2');
sfh.app_data    = fread(fid, 128, 'uint8'); % 1 byte
sfh.gps_data    = fread(fid, 56, 'uint8'); % 1 byte
sfh.it    = fread(fid, 1, 'uint32'); % 4 byte long
sfh.fo    = fread(fid, 1, 'int16'); % 2 byte int
sfh.dcc    = fread(fid, 1, 'int16'); % 2 byte int
sfh.calibration    = fread(fid, 1, 'uint16'); % 2 byte uint
sfh.instrument_num    = fread(fid, 1, 'uint16'); % 2 byte uint
sfh.ymin     = fread(fid, 1, 'real*4');
sfh.ymax     = fread(fid, 1, 'real*4');
fseek(fid,410,'bof');
sfh.xmin     = fread(fid, 1, 'real*4');
sfh.xmax     = fread(fid, 1, 'real*4');
sfh.ip_numbits    = fread(fid, 1, 'uint16'); % 2 byte uint
sfh.xmode    = fread(fid, 1, 'uint8'); % 1 byte
sfh.flags    = fread(fid, 4, 'uint8'); % 1 byte

fseek(fid,425,'bof');
sfh.dc_count     = fread(fid, 1, 'integer*2');
sfh.ref_count     = fread(fid, 1, 'integer*2');
sfh.sample_count     = fread(fid, 1, 'integer*2');
sfh.instrument     = fread(fid, 1, 'integer*1');
sfh.bulb     = fread(fid, 1, 'integer*4');

sfh.swir1_gain     = fread(fid, 1, 'integer*2');
sfh.swir2_gain     = fread(fid, 1, 'integer*2');
sfh.swir1_offset     = fread(fid, 1, 'integer*2');
sfh.swir2_offset     = fread(fid, 1, 'integer*2');
sfh.splice1_wavelength     = fread(fid, 1, 'real*4');
sfh.splice2_wavelength     = fread(fid, 1, 'real*4');

this_file_struct.spectrumFileHeader = sfh;

this_file_struct.firstx            = sfh.ch1_wavel;
this_file_struct.incx              = sfh.wavel_step;
this_file_struct.channels          = sfh.channels;
this_file_struct.xaxis             = 1;
this_file_struct.yaxis             = 1;

% Spectrum Data
% Read the spectrum data ---------------------------------------------------------------------------
indx_to_spectrumdata = 484;
fseek(fid,indx_to_spectrumdata,'bof');
nchannels = this_file_struct.spectrumFileHeader.channels;
haveSpectrumData = false;
[this_file_struct.spectrumdata elementsRead]    = fread(fid, nchannels, 'real*8');
if elementsRead==nchannels
  haveSpectrumData = true;
  % write to asd.metadata:   disp(['size spectrumdata = ' num2str(length(this_file_struct.spectrumdata))])
  this_file_struct.logrecords(end+1) = {['size spectrumdata = ' num2str(length(this_file_struct.spectrumdata))]};
else
    this_file_struct.logrecords(end+1) = {['Incomplete spectrumdata: read = ' num2str(elementsRead) ' values.']};
    error(['Incomplete spectrumdata: read = ' num2str(elementsRead) ' values.'])
  this_file_struct.spectrumdata = repmat(nan, nchannels, 1);
end
%---------------------------------------------------------------------------------------------------

% Reference file header ----------------------------------------------------------------------------
indexToReferenceHeader = ftell(fid);
rfh = [];
rfh.referenceflag = fread(fid, 2, 'uint8'); %'schar');
rfh.referencetime = fread(fid, 1, 'real*8');
rfh.spectrumtime = fread(fid, 1, 'real*8');
% see http://ros.thevbzone.com/data_types_main.html for VB date
% disp(sprintf('Approx reference date (year) = %6.6f', (1899 + rfh.referencetime/365) ))
% disp(sprintf('Approx spectrum date (year) = %6.6f', (1899 + rfh.spectrumtime/365) ))
rfh.SpectrumDescripton = readNextString(fid);
this_file_struct.referenceFileHeader = rfh;

% Reference data -----------------------------------------------------------------------------------
indexToReferenceData = ftell(fid);
haveReferenceData = false;
[this_file_struct.referencedata elementsRead]     = fread(fid, nchannels, 'real*8');
if elementsRead==nchannels
  haveReferenceData = true;
    this_file_struct.logrecords(end+1) = {['size referencedata = ' num2str(length(this_file_struct.referencedata))]};
else
    this_file_struct.logrecords(end+1) = {['Incomplete referencedata: read = ' num2str(elementsRead) ' values.']};
  error(['Incomplete referencedata: read = ' num2str(elementsRead) ' values.']);
  this_file_struct.referencedata = repmat(nan, nchannels, 1);
end
%---------------------------------------------------------------------------------------------------

% form the ratio of spectrum to reference
if haveSpectrumData & haveReferenceData
  this_file_struct.ratio = this_file_struct.spectrumdata./this_file_struct.referencedata;
else
  this_file_struct.ratio = [];
end

%     % summary and plots --------------------------------------------------------------------------
%     figure; scatter(1:nchannels, this_file_struct.spectrumdata, 2, '.'); hold on
%     scatter(1:2151, this_file_struct.referencedata, 2,'+')
%     figure; scatter(1:nchannels, this_file_struct.ratio, 2, '.')
%     %---------------------------------------------------------------------------------------------

% Contents of the file past this point are not essential. 
% Any error while reading the remainder of this file should not cause this file read to fail.
try
  % Clasifier data -----------------------------------------------------------------------------------
  cld = [];
  indexToClassifierData = ftell(fid);
  fseek(fid,indexToClassifierData,'bof');
  cld.yCode = fread(fid, 1, 'integer*1');
  cld.yModelType = fread(fid, 1, 'integer*1');
  cld.stitle = readNextString(fid);
  cld.sSubTitle = readNextString(fid);
  cld.sProductName = readNextString(fid);
  cld.sVendor = readNextString(fid);
  cld.sLotNumber = readNextString(fid);
  cld.sSample = readNextString(fid);
  cld.sModelName = readNextString(fid);
  cld.sOperator = readNextString(fid);
  cld.sDateTime = readNextString(fid);
  cld.sInstrument = readNextString(fid);
  cld.sSerialNumber = readNextString(fid);
  cld.sDisplayMode = readNextString(fid);
  cld.sComments = readNextString(fid);
  cld.sUnits = readNextString(fid);
  cld.sFilename = readNextString(fid);
  cld.sUserName = readNextString(fid);
  cld.sReserved1 = readNextString(fid);
  cld.sReserved2 = readNextString(fid);
  cld.sReserved3 = readNextString(fid);
  cld.sReserved4 = readNextString(fid);
  cld.constituentCount = fread(fid, 1, 'integer*2');
  
  %  ConstituentType
  %  'Items in the Material Report
  for ii=1:cld.constituentCount
    cld.constituentType(ii) = [];
    cld.constituentType(ii).ctConstituentName = readNextString(fid); % As String
    cld.constituentType(ii).ctPassFail = readNextString(fid); % As String
    cld.constituentType(ii).ctMDistance = fread(fid, 1, 'real*8'); %As Double
    cld.constituentType(ii).ctMDistanceLimit = fread(fid, 1, 'real*8'); %As Double
    cld.constituentType(ii).ctConcentration = fread(fid, 1, 'real*8'); %As Double
    cld.constituentType(ii).ctConcentrationLimit = fread(fid, 1, 'real*8'); %As Double
    cld.constituentType(ii).ctFRatio = fread(fid, 1, 'real*8'); %As Double
    cld.constituentType(ii).ctResidual = fread(fid, 1, 'real*8'); %As Double
    cld.constituentType(ii).ctResidualLimit = fread(fid, 1, 'real*8'); %As Double
    cld.constituentType(ii).ctScores = fread(fid, 1, 'real*8'); %As Double
    cld.constituentType(ii).ctScoresLimit = fread(fid, 1, 'real*8'); %As Double
    cld.constituentType(ii).ctModelType   = fread(fid, 1, 'uint32'); %As Long     integer*3 is 4-byte
    cld.constituentType(ii).ctReserved1 = fread(fid, 1, 'real*8'); %As Double
    cld.constituentType(ii).ctReserved2 = fread(fid, 1, 'real*8'); %As Double
  end
  
  this_file_struct.classifierData = cld;
  
  % Dependent variables ------------------------------------------------------------------------------
  indexToDependentVariables = ftell(fid);
  this_file_struct.dependentVariables.saveDependentVariables = fread(fid, 1, 'uint8'); % bool 1-byte
  this_file_struct.dependentVariables.dependentVariableCount   = fread(fid, 1, 'integer*2'); % integer, 2-byte
  % this_file_struct.dependentVariables.dependentVariableLabels = [];
  for ii=1:this_file_struct.dependentVariables.dependentVariableCount
    this_file_struct.dependentVariables.dependentVariableLabels(ii) = readNextString(fid); % As String
    this_file_struct.dependentVariables.dependentVariables(ii) = fread(fid, 1, 'real*4');  % float, 4-byte
  end
  
  % Calibration header -------------------------------------------------------------------------------
  indexToCalibrationHeader = ftell(fid);
  fseek(fid, indexToCalibrationHeader+7, 'bof'); % need to skip 7 bytes to stay synchronized. Why?
  this_file_struct.calibrationHeader.count =  fread(fid, 1, 'integer*1');
  
  % this_file_struct.calibrationHeader.calBuffer = [];
  for ii=1:this_file_struct.calibrationHeader.count
    this_file_struct.calibrationHeader.calBuffer(ii).cbType = fread(fid, 1, 'uint8');        %  1-byte
    this_file_struct.calibrationHeader.calBuffer(ii).cbName = fread(fid, 20, '*char')';       %  20   chars (1-byte)
    this_file_struct.calibrationHeader.calBuffer(ii).cbIT  = fread(fid, 1, 'uint32');        %  // Integration Time in ms of buffer
    this_file_struct.calibrationHeader.calBuffer(ii).cbSwir1Gain	= fread(fid, 1, 'uint16');  %  // int	 Swir1 Gain of buffer
    this_file_struct.calibrationHeader.calBuffer(ii).cbSwir2Gain	= fread(fid, 1, 'uint16');  %  // int	 Swir2 Gain of buffer
  end
  
  % Base Calibration Data ----------------------------------------------------------------------------
  indexToBaseCalibrationData = ftell(fid);
  [this_file_struct.basecalibrationdata elementsRead] = fread(fid, nchannels, 'real*8');
  if elementsRead==nchannels
      this_file_struct.logrecords(end+1) = {['size basecalibrationdata = ' num2str(length(this_file_struct.basecalibrationdata))]};
  else
      this_file_struct.logrecords(end+1) = {['Incomplete basecalibrationdata: read = ' num2str(elementsRead) ' values.']};
    this_file_struct.basecalibrationdata = repmat(nan, nchannels, 1);
  end
  
  % Lamp Calibration Data ----------------------------------------------------------------------------
  indexToLampCalibrationData = ftell(fid);
  [this_file_struct.lampcalibrationdata elementsRead] = fread(fid, nchannels, 'real*8');
  if elementsRead==nchannels
      this_file_struct.logrecords(end+1) = {['size lampcalibrationdata = ' num2str(length(this_file_struct.lampcalibrationdata))]};
  else
      this_file_struct.logrecords(end+1) = {['Incomplete lampcalibrationdata: read = ' num2str(elementsRead) ' values.']};
    this_file_struct.lampcalibrationdata = repmat(nan, nchannels, 1);
  end
  
  % Fiber Optic Data ---------------------------------------------------------------------------------
  indexToFiberOpticData = ftell(fid);
  [this_file_struct.fiberopticcalibrationdata elementsRead] = fread(fid, nchannels, 'real*8');
  if elementsRead==nchannels
      this_file_struct.logrecords(end+1) = {['size fiberopticcalibrationdata = ' num2str(length(this_file_struct.fiberopticcalibrationdata))]};
  else
      this_file_struct.logrecords(end+1) = {['Incomplete fiberopticcalibrationdata: read = ' num2str(elementsRead) ' values.']};
    this_file_struct.fiberopticcalibrationdata = repmat(nan, nchannels, 1);
  end
catch
  err = lasterror;
    this_file_struct.logrecords(end+1) = {['ASDREADR: Non-critical error reading "' this_file_struct.file_name '"'    err.message]};
  % NB: cancel the error...
end
% Reached end...
this_file_struct.valid_file        = true;


fclose(fid);

%===================================================================================================
function makeContourPlot(dso, nx, ny, name)
% Used for quick check of imported data
figure
[c h] = contourf(dso.data(1:nx, 1:ny)); clabel(c,h), colorbar
hold on
title(dso.name);
ylabel(dso.label{1,1});

%===================================================================================================
function mydso = addAsdLogging(mydso, allFileStruct)
%Add a log records from each asd file's struct into DSO userdata.asd.log.

% Determine number of log records and pre-allocate cell array
nfiles = length(allFileStruct);
logRecordCount = 0;
for ifile=1:nfiles
  logRecordCount = logRecordCount + length(allFileStruct(ifile).logrecords);
end
allLogRecords = cell(1, logRecordCount);

iRecord = 1;
for ifile=1:nfiles
  filename = allFileStruct(ifile).file_name;
  %Create UNC file name. Only works on Windows systems.
  fns = evriaddon('addsourceinfo_prefilter');
  for j=1:length(fns)
    filename = feval(fns{j},filename);
  end
  
% concatenate log records for all files
  logRecords1 = allFileStruct(ifile).logrecords;  % a (1,nrecs) cell array containing strings
  logsize = length(logRecords1);
  for ilog = 1:logsize
    allLogRecords(iRecord) = {logRecords1{ilog}};
    iRecord = iRecord+1;
  end
end
mydso.userdata.asd.log = allLogRecords;

%===================================================================================================
function dso_out = getDSO(allFilesStruct, datafieldName, standardDataFields)
% Create a dataset object containing the data field named 'datafieldName', provided this field name
% is one of the standard field names. See description of options.requestedfields.

% get the data as array
outfield = [allFilesStruct.(datafieldName)]';

% remove the data blocks
removeFields = intersect(fieldnames(allFilesStruct), standardDataFields);
allFilesStruct = rmfield(allFilesStruct, removeFields);

dso_out                  = dataset(outfield);
dso_out.name             = datafieldName;

dso_out.userdata.asd.metadata = allFilesStruct;
% build arrays and add fields as specified in options

xaxis_unit = {'unknown' 'wavelength (nm)' '\mum' 'time' 'arbitrary'};
yaxis_unit = {'unknown' 'transmittance' 'absorbance' 'photoacoustic units' 'arbitrary'};
nx                   = length(allFilesStruct);
ny                   = allFilesStruct(1).channels;
starty               = allFilesStruct(1).firstx;
incy                 = allFilesStruct(1).incx;
endy                 = starty + incy*(ny-1);
dso_out.axisscale{2}     = linspace(starty, endy, ny);
dso_out.axisscalename{2} = xaxis_unit{allFilesStruct(1).xaxis+1};
dso_out.axisscalename{1} = datafieldName; 

[paths names exts]   = cellfun(@fileparts, {allFilesStruct.file_name}, 'UniformOutput', false);
dso_out.label{1,1}       = names;
dso_out.labelname{1,1}   = datafieldName; % should be 'file name' but use datafieldName to identify field;
dso_out                  = addsourceinfo(dso_out,{allFilesStruct.file_name});

dso_out                  = addAsdLogging(dso_out, allFilesStruct);

% if nx > 2   % plot if 3 or more files read
%   makeContourPlot(dso_out, nx, min(ny, 1000), datafieldName);
% end






