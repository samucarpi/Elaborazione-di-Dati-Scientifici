function peout = pereadr(filenames,options)
%PEREADR Read PerkinElmer files.
% INPUT:
%   filename = a text string with the name of a PE file or
%              a cell of strings of  filenames.
%     If (filename) is omitted or an empty cell or array, the user will be
%     prompted to select a folder and then one or more files in the
%     identified folder. If (filename) is a blank string '', the user will
%     be prompted to select a single file.
% OPTIONAL INPUTS:
%   options = an options structure containing one or more of the following
%    fields:
%       filetype : [ 'fsm'|'imp'|'lsc'|'sp'|'vis'|{'all'}] Limits file
%                  types in dialog.
%        multiselect : [ 'off' | {'on'} ] governs whether file selection
%                      dialog should allow multiple files to be selected
%                      and imported. Setting to 'off' will restrict user to
%                      importing only one file at a time.
%
% OUTPUT:
%   out = DataSet object. If multiple files are read, MATCHVARS is used to
%         join all the data into a single DataSet object (matching
%         axis scales if necessary)
%
%I/O: peout = pereadr
%I/O: peout = pereadr('filename',options)
%I/O: peout = pereadr({'filename' 'filename2'},options)
%
%See also: ASDREADR, ASFREADR, EDITDS, HJYREADR, JCAMPREADR, MATCHVARS, PDFREADR, SPAREADR, SPCREADR, TEXTREADR, WRITEASF

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%TODO: Figure out if should concat switch for .sp files (like spc).


if nargin==1 && ischar(filenames) && ismember(filenames,evriio([],'validtopics'));
  options = [];
  options.filetype = 'all';
  options.multiselect = 'on';
  if nargout==0; clear out; evriio(mfilename,filenames,options); else peout = evriio(mfilename,filenames,options); end
  return;
end

%This function is not available for 6.5.
if checkmlversion('<','7')
  error('PEReader does not work with older versions (R13 and below) of Matlab.')
end

peout = [];

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
  if strcmpi(options.filetype,'all')
    %do actual read for filename
    [filenames, pathname, filterindex] = evriuigetfile({'*.FSM; *.fsm; *.IMP; *.imp; *.LSC; *.lsc; *.SP; *.sp; *.vis; *.VIS ', 'PerkinElmer Files (*.fsm, *.imp, *.lsc, *.sp, *.vis)'; '*.*', 'All files'}, 'Open PerkinElmer File','MultiSelect', options.multiselect);
  else
    [filenames, pathname, filterindex] = evriuigetfile({['*.' upper(options.filetype) '; *.' lower(options.filetype)  ';'], ['PerkinElmer File (*.' lower(options.filetype) ')']; ['*.' lower(options.filetype)], [upper(options.filetype) ' Files']}, 'Open PerkinElmer File','MultiSelect', options.multiselect);
  end
  if filterindex==0
    out = [];
    return
  else
    %got one or more filenames, add path to each
    if ~iscell(filenames)
      filenames = {filenames};
    end
    for j = 1:length(filenames)
      filenames{j} = fullfile(pathname,filenames{j});
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
      for j = 1:length(filenames)
        filenames{j} = fullfile(target_path,filenames{j});
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

shortfilenames = {};

for j = 1:length(filenames)
  [junk1, shortfilename, myext] = fileparts(filenames{j});
  shortfilenames{j} = shortfilename;
  
  data = [];
  xAxis = [];
  yAxis = [];
  zAxis = [];
  switch lower(myext)
    case '.fsm'
      [data, xAxis, yAxis, zAxis, misc] = fsmload(filenames{j});
    case '.imp'
      [data, xAxis, yAxis, misc] = impload(filenames{j});
    case '.lsc'
      [data, wAxis, dAxis, xAxis, yAxis, misc] = lscload(filenames{j});
      %Don't have example data to test folding logic so leave unfolded and
      %just add wave number as y axis scale. 
      xAxis = [];
      yAxis = wAxis;
    case '.sp'
      [data, xAxis, misc] = spload(filenames{j});
    case '.vis'
      [data, xAxis, yAxis, misc] = visload(filenames{j});
  end
  
  %Make dataset.
  switch lower(myext)
    case '.fsm'
      % data is a 3D array. Convert to an image dataset
      peout{j} = buildimage(data);
      if ~isempty(yAxis)
        peout{j}.imageaxisscale{1} = yAxis;
      end
      if ~isempty(xAxis)
        peout{j}.imageaxisscale{2} = xAxis;
      end

      peout{j}.imageaxisscalename{2} = misc(ismember(misc(:,1), 'xLabel'),2);
      peout{j}.imageaxisscalename{1} = misc(ismember(misc(:,1), 'yLabel'),2);
      
    case {'.imp' '.lsc' '.vis'}
      peout{j} = dataset(data);
      
      if ndims(data)>0 & ~isempty(xAxis)
        peout{j}.axisscale{1} = xAxis;
      end
      
      if ndims(data)>2 & ~isempty(yAxis)
        peout{j}.axisscale{2} = yAxis;
      end
      
      if ndims(data)>3 & ~isempty(zAxis)
        peout{j}.axisscale{3} = zAxis;
      end
            
    case {'.sp'}
      peout{j} = dataset(data');         % Use scans-are-rows convention
      
      if ndims(data)>0 & ~isempty(xAxis)
        peout{j}.axisscale{2} = xAxis;   % Note 'xAxis' is y-axis for .SP
      end
      
      if ndims(data)>2 & ~isempty(yAxis)
        peout{j}.axisscale{1} = yAxis;   % Assuming this is also the case.
      end
      
      if ndims(data)>3 & ~isempty(zAxis)
        peout{j}.axisscale{3} = zAxis;
      end
  end
  
  peout{j} = addsourceinfo(peout{j}, filenames{j});
  
  peout{j}.name = shortfilename;
  peout{j}.author = 'pereadr';
  
  if ~isempty(misc)
    peout{j}.userdata = misc;
  end
end

if strcmpi('.sp', myext) & ~isempty(peout) & length(peout)>1
  % attempt to join using matchvars
  try
    joined = matchvars(peout);
    joined.name = 'Multiple Files';
    joined.label{1} = shortfilenames;
    peout = joined;
  catch
    %could not join, just return cell array already in peout
  end
end

if length(peout)==1
  peout = peout{1};
end



%----------------------------------------------
function [data, xAxis, yAxis, zAxis, misc] = fsmload(filename)
% Reads in IR image data from PerkinElmer block structured files.
% This version is compatible with '1994' standard FSM files.
% FSM files have 3 constant data intervals.
%
% [data, xAxis, yAxis, zAxis, misc] = fsmload(filename):
%   data:  3D array, [Y, X, Z]
%   xAxis: vector for horizontal axis (e.g. micrometers)
%   yAxis: vector for vertical axis (e.g. micrometers)
%   zAxis: vector for wavenumber axis (e.g. cm-1)
%   misc: miscellanous information in name,value pairs

% Copyright (C)2007 PerkinElmer Life and Analytical Sciences
% Stephen Westlake, Seer Green
%
% History
% 2007-04-24 SW     Initial version

% Block IDs
DS4C3IData            = 5100;   % 4D DS: header info
DS4C3IPts             = 5101;   % 4D DS: point coordinates (CvCoOrdArray)
DS4C3IPtsCont         = 5102;   % 4D DS: point coordinates (continuator for large CvCoOrdArray)
DS4C3ITemp2DData      = 5103;   % 4D DS: temp block for storing part of component 2d dataset
DS4C3I2DData          = 5104;   % 4D DS: release sw block for storing ALL of component 2d data
DS4C3IFloatPts        = 5105;   % 4D DS: point coordinates (FloatArray)
DS4C3IFloatPtsCont    = 5106;   % 4D DS: point coordinates (continuator for large FloatArray)
DS4C3IHistory         = 5107;   % 4D DS: history record

fid = fopen(filename,'r');
if fid == -1
    error('Cannot open the file.');
    return
end

% Fixed file header of signature and description
signature = setstr(fread(fid, 4, 'uchar')');
if ~strcmp(signature, 'PEPE')
    error('This is not a PerkinElmer block structured file.');
    return
end
description = setstr(fread(fid, 40, 'uchar')');

% Initialize a variable so we can tell if we have read it.
xLen = int16(0);

% The rest of the file is a list of blocks
while ~feof(fid)
    blockID = fread(fid,1,'int16');
    blockSize = fread(fid,1,'int32');
    
    % feof does not go true until after the read has failed.
    if feof(fid)
        break
    end
    
    switch blockID
        case DS4C3IData
            len = fread(fid,1,'int16');
            alias = setstr(fread(fid, len, 'uchar')');
        
            xDelta = fread(fid, 1, 'double');
            yDelta = fread(fid, 1, 'double');
            zDelta = fread(fid, 1, 'double');
            fread(fid, 1, 'double');      % zstart
            fread(fid, 1, 'double');      % zend    
            fread(fid, 1, 'double');      % min data value
            fread(fid, 1, 'double');      % max data value
            x0 = fread(fid, 1, 'double');
            y0 = fread(fid, 1, 'double');
            z0 = fread(fid, 1, 'double');
            xLen = fread(fid, 1, 'int32');
            yLen = fread(fid, 1, 'int32');
            zLen = fread(fid, 1, 'int32');            
            
            len = fread(fid, 1, 'int16');
            xLabel = setstr(fread(fid, len, 'uchar')');
            len = fread(fid, 1, 'int16');
            yLabel = setstr(fread(fid, len, 'uchar')');
            len = fread(fid, 1, 'int16');
            zLabel = setstr(fread(fid, len, 'uchar')');
            len = fread(fid, 1, 'int16');
            wLabel = setstr(fread(fid, len, 'uchar')');

            % matlab row 1 is the top, i.e. fsm row N.
            y = yLen;
            x = 1;
            
        case DS4C3IFloatPts         % the next spectrum
            data(y, x, :) = fread(fid, zLen, 'float');
            % set up the index for the next point
            x = x + 1;
            if x > xLen
                x = 1;
                y = y - 1;
            end
     
        otherwise               % unknown block, just seek past it
            fseek(fid, blockSize, 'cof');
    end
end
fclose(fid);

if xLen == 0
    error('The file does not contain spectral image data.');
    return
end

% Expand the axes specifications into vectors
% Y axis is reversed to match the image
xEnd = x0 + (xLen - 1) * xDelta;
yEnd = y0 + (yLen - 1) * yDelta;
zEnd = z0 + (zLen - 1) * zDelta;
xAxis = x0 : xDelta : xEnd;
yAxis = yEnd : -yDelta : y0;
zAxis = z0 : zDelta : zEnd;

% Return the other details as name,value pairs
misc(1,:) = {'xLabel', xLabel};
misc(2,:) = {'yLabel', yLabel};
misc(3,:) = {'zLabel', zLabel};
misc(4,:) = {'wLabel', wLabel};
misc(5,:) = {'alias', alias};

%----------------------------------------------
function [data, xAxis, yAxis, misc] = impload(filename)
% Reads intensity map data from PerkinElmer block structured files.
% This version is compatible with '1994' standard IMP files.
% IMP files have 2 constant data intervals.
%
% [data, xAxis, yAxis, misc] = impload(filename):
%   data: length(x) * length(y) 2D array
%   xAxis: vector for horizontal axis (e.g. micrometers)
%   yAxis: vector for vertical axis (e.g. micrometers)
%   misc: miscellanous information in name,value pairs

% Copyright (C)2007 PerkinElmer Life and Analytical Sciences
% Stephen Westlake, Seer Green
%
% History
% 2007-04-24 SW     Initial version

% Block IDs
DS3C2IData            = 5108;   % 3D DS: header info
DS3C2IPts             = 5109;   % 3D DS: point coordinates (CvCoOrdArray)
DS3C2IPtsCont         = 5110;   % 3D DS: point coordinates (continuator for large CvCoOrdArray)
DS3C2IHistory         = 5111;   % 3D DS: history record
DSet3DC2DIBlock       = 5112;   % 3D DS: the block containing all other 3d blocks.

fid = fopen(filename,'r');
if fid == -1
    error('Cannot open the file.');
    return
end

% Fixed file header of signature and description
signature = setstr(fread(fid, 4, 'uchar')');
if ~strcmp(signature, 'PEPE')
    error('This is not a PerkinElmer block structured file.');
    return
end
description = setstr(fread(fid, 40, 'uchar')');

% Initialize a variable so we can tell if we have read it.
xLen = int16(0);

% The rest of the file is a list of blocks
while ~feof(fid)
    blockID = fread(fid,1,'int16');
    blockSize = fread(fid,1,'int32');
    
    % feof does not go true until after the read has failed.
    if feof(fid)
        break
    end
    
    switch blockID
        case DS3C2IData % Dataset header
            len = fread(fid,1,'int16');
            alias = setstr(fread(fid, len, 'uchar')');
        
            xDelta = fread(fid, 1, 'double');
            yDelta = fread(fid, 1, 'double');
            x0 = fread(fid, 1, 'double');
            y0 = fread(fid, 1, 'double');
            xLen = fread(fid, 1, 'int32');
            yLen = fread(fid, 1, 'int32');
            
            len = fread(fid, 1, 'int16');
            xLabel = setstr(fread(fid, len, 'uchar')');
            len = fread(fid, 1, 'int16');
            yLabel = setstr(fread(fid, len, 'uchar')');
            len = fread(fid, 1, 'int16');
            zLabel = setstr(fread(fid, len, 'uchar')');

        case DS3C2IPts  % This contains the first block
            count = blockSize / 8;
            data = fread(fid, count, 'double');
            
        case DS3C2IPtsCont % Continuation blocks
            countCont = blockSize / 8;
            data(count + 1 : count + countCont) = fread(fid, countCont, 'double');
            count = count + countCont;
     
        otherwise               % unknown block, just seek past it
            fseek(fid, blockSize, 'cof');
    end
end
fclose(fid);

if xLen == 0
    error('The file does not contain spectral image data.');
    return
end

% Reshape the linear array we have read in and flip so the
% data is in the correct aspect for image(data) with 1,1 at the top.
data = flipud(transpose(reshape(data, xLen, yLen)));

% Expand the axes specifications into vectors
% The yAxis is reversed to match the flip.
xEnd = x0 + (xLen - 1) * xDelta;
yEnd = y0 + (yLen - 1) * yDelta;
xAxis = x0 : xDelta : xEnd;
yAxis = yEnd : -yDelta : y0;

% Return the other details as name,value pairs
misc(1,:) = {'xLabel', xLabel};
misc(2,:) = {'yLabel', yLabel};
misc(3,:) = {'zLabel', zLabel};
misc(4,:) = {'alias', alias};

%----------------------------------------------
function [data, wAxis, dAxis, xAxis, yAxis, misc] = lscload(filename)
% Reads in IR image data from PerkinElmer block structured files.
% This version is compatible with '1994' standard LSC files.
%
% [data, wAxis, dAxis, xAxis, yAxis, misc] = lscload(filename):
%   data:  2D array, [W, D]     wavelength x distance
%   wAxis: vector of e.g. wavenumbers
%   dAxis: vector of distance along line
%   xAxis: vector for stage x positions (e.g. micrometers)
%   yAxis: vector for stage y positions (e.g. micrometers)
%   misc: miscellanous information in name,value pairs

% Copyright (C)2007 PerkinElmer Life and Analytical Sciences
% Stephen Westlake, Seer Green
%
% History
% 2007-05-01 SW     Initial version

% Block IDs
DS4C3IData            = 5100;   % 4D DS: header info
DS4C3IPts             = 5101;   % 4D DS: point coordinates (CvCoOrdArray)
DS4C3IPtsCont         = 5102;   % 4D DS: point coordinates (continuator for large CvCoOrdArray)
DS4C3ITemp2DData      = 5103;   % 4D DS: temp block for storing part of component 2d dataset
DS4C3I2DData          = 5104;   % 4D DS: release sw block for storing ALL of component 2d data
DS4C3IFloatPts        = 5105;   % 4D DS: point coordinates (FloatArray)
DS4C3IFloatPtsCont    = 5106;   % 4D DS: point coordinates (continuator for large FloatArray)
DS4C3IHistory         = 5107;   % 4D DS: history record

fid = fopen(filename,'r');
if fid == -1
    error('Cannot open the file.');
    return
end

% Fixed file header of signature and description
signature = setstr(fread(fid, 4, 'uchar')');
if ~strcmp(signature, 'PEPE')
    error('This is not a PerkinElmer block structured file.');
    return
end
description = setstr(fread(fid, 40, 'uchar')');

% Initialize a variable so we can tell if we have read it.
dLen = int32(0);
qLen = int32(0);

% The rest of the file is a list of blocks
while ~feof(fid)
    blockID = fread(fid,1,'int16');
    blockSize = fread(fid,1,'int32');
    
    % feof does not go true until after the read has failed.
    if feof(fid)
        break
    end
    
    switch blockID
        case DS4C3IData
            len = fread(fid,1,'int16');
            alias = setstr(fread(fid, len, 'uchar')');
        
            dDelta = fread(fid, 1, 'double');       % distance delta
            angle = fread(fid, 1, 'double');        % angle (radians)
            wDelta = fread(fid, 1, 'double');       % wavenumber delta
            fread(fid, 1, 'double');      % zstart
            fread(fid, 1, 'double');      % zend    
            fread(fid, 1, 'double');      % min data value
            fread(fid, 1, 'double');      % max data value
            x0 = fread(fid, 1, 'double');           % stage x0
            y0 = fread(fid, 1, 'double');           % stage y0
            w0 = fread(fid, 1, 'double');           % wavenumber start
            dLen = fread(fid, 1, 'int32');          % distance points
            qLen = fread(fid, 1, 'int32');          % should be 1
            wLen = fread(fid, 1, 'int32');          % wavelength points            
            
            len = fread(fid, 1, 'int16');
            dLabel = setstr(fread(fid, len, 'uchar')');
            len = fread(fid, 1, 'int16');
            setstr(fread(fid, len, 'uchar')');
            len = fread(fid, 1, 'int16');
            wLabel = setstr(fread(fid, len, 'uchar')');
            len = fread(fid, 1, 'int16');
            zLabel = setstr(fread(fid, len, 'uchar')');

            % imshow row 1 is the top, i.e. fsm row N.
            d = dLen;
            
        case DS4C3IFloatPts         % the next spectrum
            data(d, :) = fread(fid, wLen, 'float');
            if d == 0
                error('There are too many data points.');
                return
            end
            % set up the index for the next point
            d = d - 1;
     
        otherwise               % unknown block, just seek past it
            fseek(fid, blockSize, 'cof');
    end
end
fclose(fid);

if dLen == 0
    error('The file does not contain spectral image data.');
    return
end
if qLen ~= 1
    error('The file does not contain line scan data.');
    return
end

% d0 is implicitly 0
dEnd = (dLen - 1) * dDelta;
wEnd = w0 + (wLen - 1) * wDelta;

% Calculate end stage positions from angle and hypoteneuse
xEnd = x0 + dEnd * cos(angle);
yEnd = y0 + dEnd * sin(angle);
xDelta = dDelta * cos(angle);
yDelta = dDelta * sin(angle);

% Expand the axes specifications into vectors
% D axis is reversed to match the image data
xAxis = x0 : xDelta : xEnd;
yAxis = y0 : yDelta : yEnd;
dAxis = dEnd : -dDelta : 0;
wAxis = w0 : wDelta : wEnd;

% Return the other details as name,value pairs
misc(1,:) = {'dLabel', dLabel};
misc(2,:) = {'wLabel', wLabel};
misc(3,:) = {'zLabel', zLabel};
misc(4,:) = {'alias', alias};
misc(5,:) = {'angle', angle};

%----------------------------------------------
function [data, xAxis, misc] = spload(filename)
% Reads in spectra from PerkinElmer block structured files.
% This version supports 'Spectrum' SP files.
% Note that earlier 'Data Manager' formats are not supported.
%
% [data, xAxis, misc] = spload(filename):
%   data:  1D array of doubles
%   xAxis: vector for abscissa (e.g. Wavenumbers).
%   misc: miscellanous information in name,value pairs

% Copyright (C)2007 PerkinElmer Life and Analytical Sciences
% Stephen Westlake, Seer Green
%
% History
% 2007-04-24 SW     Initial version

% Block IDs
DSet2DC1DIBlock               =  120;
HistoryRecordBlock            =  121;
InstrHdrHistoryRecordBlock    =  122;
InstrumentHeaderBlock         =  123;
IRInstrumentHeaderBlock       =  124;
UVInstrumentHeaderBlock       =  125;
FLInstrumentHeaderBlock       =  126;
% Data member IDs
DataSetDataTypeMember              =  -29839;
DataSetAbscissaRangeMember         =  -29838;
DataSetOrdinateRangeMember         =  -29837;
DataSetIntervalMember              =  -29836;
DataSetNumPointsMember             =  -29835;
DataSetSamplingMethodMember        =  -29834;
DataSetXAxisLabelMember            =  -29833;
DataSetYAxisLabelMember            =  -29832;
DataSetXAxisUnitTypeMember         =  -29831;
DataSetYAxisUnitTypeMember         =  -29830;
DataSetFileTypeMember              =  -29829;
DataSetDataMember                  =  -29828;
DataSetNameMember                  =  -29827;
DataSetChecksumMember              =  -29826;
DataSetHistoryRecordMember         =  -29825;
DataSetInvalidRegionMember         =  -29824;
DataSetAliasMember                 =  -29823;
DataSetVXIRAccyHdrMember           =  -29822;
DataSetVXIRQualHdrMember           =  -29821;
DataSetEventMarkersMember          =  -29820;
% Type code IDs
ShortType               = 29999;
UShortType              = 29998;
IntType                 = 29997;
UIntType                = 29996;
LongType                = 29995;
BoolType                = 29988;
CharType                = 29987;
CvCoOrdPointType        = 29986;
StdFontType             = 29985;
CvCoOrdDimensionType    = 29984;
CvCoOrdRectangleType    = 29983;
RGBColorType            = 29982;
CvCoOrdRangeType        = 29981;
DoubleType              = 29980;
CvCoOrdType             = 29979;
ULongType               = 29978;
PeakType                = 29977;
CoOrdType               = 29976;
RangeType               = 29975;
CvCoOrdArrayType        = 29974;
EnumType                = 29973;
LogFontType             = 29972;


fid = fopen(filename,'r');
if fid == -1
    error('Cannot open the file.');
    return
end

% Fixed file header of signature and description
signature = setstr(fread(fid, 4, 'uchar')');
if ~strcmp(signature, 'PEPE')
    
    error('This is not a PerkinElmer block structured file.');
    return
end
description = setstr(fread(fid, 40, 'uchar')');

% Initialize a variable so we can tell if we have read it.
xLen = int32(0);

% The rest of the file is a list of blocks
while ~feof(fid)
    blockID = fread(fid,1,'int16');
    blockSize = fread(fid,1,'int32');
    
    % feof does not go true until after the read has failed.
    if feof(fid)
        break
    end
    
    switch blockID
        case DSet2DC1DIBlock
        % Wrapper block.  Read nothing.

        case DataSetAbscissaRangeMember
            innerCode = fread(fid, 1, 'int16');
            %_ASSERTE(CvCoOrdRangeType == nInnerCode);
            x0 = fread(fid, 1, 'double');
            xEnd = fread(fid, 1, 'double');
                
        case DataSetIntervalMember
            innerCode = fread(fid, 1, 'int16');
            xDelta = fread(fid, 1, 'double');

        case DataSetNumPointsMember
            innerCode = fread(fid, 1, 'int16');
            xLen = fread(fid, 1, 'int32');

        case DataSetXAxisLabelMember
            innerCode = fread(fid, 1, 'int16');
            len = fread(fid, 1, 'int16');
            xLabel = setstr(fread(fid, len, 'uchar')');

        case DataSetYAxisLabelMember
            innerCode = fread(fid, 1, 'int16');
            len = fread(fid, 1, 'int16');
            yLabel = setstr(fread(fid, len, 'uchar')');
            
        case DataSetAliasMember
            innerCode = fread(fid, 1, 'int16');
            len = fread(fid, 1, 'int16');
            alias = setstr(fread(fid, len, 'uchar')');
          
        case DataSetNameMember
            innerCode = fread(fid, 1, 'int16');
            len = fread(fid, 1, 'int16');
            originalName = setstr(fread(fid, len, 'uchar')');
          
        case DataSetDataMember
            innerCode = fread(fid, 1, 'int16');
            len = fread(fid, 1, 'int32');
            % innerCode should be CvCoOrdArrayType
            % len should be xLen * 8
            if xLen == 0
                xLen = len / 8;
            end
            data = fread(fid, xLen, 'double');
 
        otherwise               % unknown block, just seek past it
            fseek(fid, blockSize, 'cof');
    end
end
fclose(fid);

if xLen == 0
    error('The file does not contain spectral data.');
    return
end

% Expand the axes specifications into vectors
xAxis = x0 : xDelta : xEnd;

% Return the other details as name,value pairs
misc(1,:) = {'xLabel', xLabel};
misc(2,:) = {'yLabel', yLabel};
misc(3,:) = {'alias', alias};
misc(4,:) = {'original name', originalName};

%----------------------------------------------
function [data, xAxis, yAxis] = visload(filename)
% Reads PerkinElmer vis image files files.
% This version is compatible with single image files.
%
% [data, xAxis, yAxis] = visload(filename):
%   data: length(x) * length(y) 2D array
%   xAxis: vector for horizontal axis (e.g. micrometers)
%   yAxis: vector for vertical axis (e.g. micrometers)

% Copyright (C)2007 PerkinElmer Life and Analytical Sciences
% Stephen Westlake, Seer Green
%
% History
% 2007-04-29 SW     Initial version


% Read the bitmap
data = imread(filename, 'bmp');

fid = fopen(filename,'r');
if fid == -1
    error('Cannot open the file.');
    return
end

% Fixed file header of signature and description
signature = setstr(fread(fid, 2, 'uchar')');
if ~strcmp(signature, 'BM')
    error('This is not a PerkinElmer vis file.');
    return
end
fseek(fid, 0, 'bof');


% Read the trailer
fseek(fid, -4 * 8, 'eof');

% YAxis is reversed to suit image()
xAxis(1) = fread(fid, 1, 'double');     % x1
yAxis(2) = fread(fid, 1, 'double');     % y1 
xAxis(2) = fread(fid, 1, 'double');     % x2
yAxis(1) = fread(fid, 1, 'double');     % y2

fclose(fid);





