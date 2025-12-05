function [ out ] = spereadr( files, options )
%SPEREADR reads Princeton Instruments SPE files.
% Reads a Princeton Instruments SPE file. The reader will pre-allocate the
% data dimensions for the DSO using the Frame dimensions as well as the
% number of Frames, as specified size found in the file header and/or
% footer. The importer will then populate the DSO with the data recorded
% for every Region of Interest (ROI) found in each Frame.
%
% Note: Currently only SPE format version 3.0 is supported.
%
%  INPUT:
%   files = One of the following identifications of files to read:
%            a) a single string identifying the file to read
%                  ('example')
%            b) a single element cell array of a string of a file to read
%                  ({'example_a'}), note: multiple files are currently NOT
%                  supported.
%            c) an empty array indicating that the user should be prompted
%               to locate the file(s) to read
%                  ([])
%
%  OPTIONAL INPUT:
%     options = structure array with the following fields:
%   options = structure array with the following fields:
%          waitbar : [ 'off' | {'on'}] governs the display of a waitbar.
%          dsomode : ['std'|{'img'}] governs the output dso type (standard
%                    or image).
%
%  Output:
%    out = A DataSet imported from an .spe file.
%
%I/O: out = spereadr();
%I/O: out = spereadr(file);
%
%See also: asfreadr, editds, jcampreadr, spareadr, spcreadr, textreadr

% Copyright © Eigenvector Research, Inc. 2018
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

% File SPEC for 3.0
% https://raw.githubusercontent.com/hududed/pyControl/master/Manual/LightField/Add-in%20and%20Automation%20SDK/SPE%203.0%20File%20Format%20Specification.pdf

out=[];

%Test for R2020b.
if verLessThan('matlab','9.9')
  %Using readstruct.m, only available in 2020b.
  error('Must use version 2020b or newer for SPEREAD.')
end

% Input check
if (nargin==0 | isempty(files)) % No input? prompt user for a file.
  [files,pathname] = evriuigetfile({'*.spe','SPE Files (*.spe)'; ...
    '*.*','All Files (*.*)'},'multiselect','off'); % left off for now (may be enabled later?)
  if (isnumeric(files) & (files == 0))
    return;
  end
  % Format files to be a cell array with the path & filename
  if (iscell(files))
    for (j=1:length(files))
      files{j} = [pathname files{j}];
    end
  else
    files = {[pathname,files]};
  end
  % If input is 'options' return options struct.
elseif ischar(files) & ismember(files,evriio([],'validtopics'))
  varargin{1} = files;
  options.waitbar = 'on';
  options.dsomode = 'img';
  if (nargout==0)
    clear out; evriio(mfilename,varargin{1},options);
  else
    out = evriio(mfilename,varargin{1},options);
  end
  return;
elseif ischar(files)
  files = {files};
end
if (nargin<2)
  options = spereadr('options');
end
options = reconopts(options,'spereadr');

% Import file as a cell array
for (i=1) % This line can be modified to handle multiple files in the future

  [directory, fn, fext] = fileparts(files{i});
  thisfile = [fn fext];
  
  % Exctract data & metadata from the file.
  [x,xmlraw] = speread(files{i});
  
  if isempty(x)
    %User cancel.
    return
  end
  
  % Construct DSO (or ImageDSO if MIA_Toolbox is installed).
  x = dataset(x);
  
  % Add additional metadata
  x.name = thisfile;
  x.author = 'Created By SPEREADR';
  % Add the axisscale
  try
    myscale = textscan(xmlraw.Calibrations.WavelengthMapping.Wavelength,'%f','Delimiter',',');
    x.axisscale{2} = myscale{1};
  catch
    warning('Unable to include an axisscale to DSO.');
  end
  % Add metadata (xmlfooter)
  x.userdata = xmlraw;
  
  % Add the info about imported source file(s)
  x = addsourceinfo(x, files{i});
  
  % Convert to ImageDSO if MIA_Toolbox is installed.
  if strcmpi(options.dsomode,'img')
    yn=evriio('mia');
    if (yn)
      x = buildimage(x);
    else
      warning('MIA_Toolbox no installed. Output is standard DSO.');
    end
  end
  
end

% TODO: Add ability to combine multiple files here (cell,dso,error) in the future.

% Assign x to out
out = x;
end

%--------------------------------------------------------------------------
function [x, xmlraw] = speread(files)
% The engine for spereadr.m, speread() handles the actual importing process.
% Important values

x = [];
xmlraw = [];

%These are the only offsets used by V3 specification.
headerOffset = 4100;
speVerOffset = 1992; % 1992 bytes offset to the file format version.
xmlFooterOffsetLoc = 678; % 678 bytes offset to the location for the xml offset

try
  % Initialize/Update waitbar
  wbhandle = waitbar(0,'Preparing to load SPE File...','Name','Importing SPE File (close to cancel)');
  
  % Open file.
  [f, MESSAGE] = fopen(files);
  
  % Determine the SPE format version.
  speVersion = seeknget(f,speVerOffset,1,'float32'); %fread(f,1,'float32');
  
  % If version is not 3.0 or greater throw an error.
  if (speVersion<3.0)
    fclose(f);
    errmsg = sprint('SPE file formats older than 3.0 is currently unsupported, please contact Eignevector Helpdesk.');% SPE format version for the file is %d',speVersion);
    error(errmsg);
  end
  
  % Extract important info (& metadata) from the header.
  xmlFooterOffset = seeknget(f,xmlFooterOffsetLoc,1,'uint64');

  % Extract important info
  waitbar(0.05,wbhandle,'Extracting info');
  % (SPE v3.0) all info stored in XML footer.
  % Extract the xml footer.
  [xmlraw] = xmlextract(f,xmlFooterOffset);
  
  %From documentation: 
  %  SPE 3.0 supports any number of regions of interest for any number of frames. This lifts the previous
  %  requirement of SPE 2.x where frames must be rectangular and multiple regions typically required “filler”
  %  pixels to form a rectangle. However, the following requirements do apply:
  %   * Pixels within a region of interest have the same binary type.
  %   * All regions of interest have the same pixel binary type.
  %   * Regions of interest are rectangular (i.e., have a width and a height).
  %   * All frames have the same regions of interest in the same order.
  

  %Helpdesk correspondence Chris Wernik cwernik@deltaphotonics.com
  %mentioned we should not look at sensor information, but instead look at
  %DataBlock.
  %frameWidths = xmlraw.DataFormat.DataBlock(1).DataBlock(1).widthAttribute; %Hardwired 2 for now, xmlraw.Children(calchildidx).Children.name should be 'SensorInformation'
  %frameHeights = xmlraw.DataFormat.DataBlock(1).DataBlock(1).heightAttribute; %Hardwired 2 for now, xmlraw.Children(calchildidx).Children.name should be 'SensorInformation'
  nframes = xmlraw.DataFormat.DataBlock(1).countAttribute;
  frameSz = xmlraw.DataFormat.DataBlock(1).sizeAttribute;
  frameStride = xmlraw.DataFormat.DataBlock(1).strideAttribute;
  pixelFormat = parsePixelFormat(char(xmlraw.DataFormat.DataBlock(1).pixelFormatAttribute));


  % Regions should always have same size so just base off of first ROI.
  % Extract ROI info
  nroi = length(xmlraw.DataFormat.DataBlock(1).DataBlock);
  roiSzs = [xmlraw.DataFormat.DataBlock(1).DataBlock.sizeAttribute]; % (size=width*height*(pixelFormat: 16or32bit)/8)
  roiStrides = [xmlraw.DataFormat.DataBlock(1).DataBlock.strideAttribute];
  [startx,starty,roiWidths,roiHeights,frameDims] = getROIcoordinates(xmlraw); % get the ROI start coordinates ("upper left corner" based on the docs).

  % Extract the data from the file and format it.
  waitbar(0.1,wbhandle,'Extracting data: ');
  fseek(f,headerOffset,'bof');
  count=1;

  for (i=1:nframes)  % For each Frame
    if (i==1)
      thisFrameStride = 0;
    else % NOTE: Assuming the metadata entries between frames is consistent (not sparse).
      thisFrameStride = frameStride(2)*(i-1);
    end

    % Save all ROIs as a single matrix (concatinate them all together)
    tempfr = NaN(frameDims); % Frame will contain ALL ROIs
    for (j=1:nroi) % For each ROI
      msg = sprintf('Extracting data: Frame %d ROI %d',i,j);
      if ishandle(wbhandle)
        waitbar(count/(nframes*nroi),wbhandle,msg);
      else
        %User cancel.
        fclose(f);
        return
      end
      count = count + 1;
      if (j==1)
        thisROIStride = 0;
      else % NOTE: Assuming the metadata entries between frames is consistent (not sparse).
        thisROIStride = roiStrides(j-1);
      end
      fseek(f,(headerOffset + thisFrameStride + thisROIStride),'bof'); %fseek(f,(headerOffset+frameStride(i)),'bof');

      for (l=1:roiHeights(j))% For each Row in an ROI
        for (k=1:roiWidths(j))% For each Column in an ROI
          %tempfr(startx(j)+k,starty(j)+l) = fread(f,1,pixelFormat);
          temp = fread(f,1,pixelFormat);
          %if ~(isempty(temp))
          %tempfr(startx(j)+k,starty(j)+l) = temp;
          tempfr(starty(j)+l,startx(j)+k) = temp;
          %[startx(j)+k,starty(j)+l]
          %end
        end
      end
    end

    % Store extracted ROI in a cell array.
    tempFrame{i} = tempfr;
    tempfr=NaN(frameDims);%[];
  end

  % Save the data as a DSO.
  x = NaN(frameDims(1),frameDims(2),length(tempFrame));%x = NaN(col_t,row_t,length(tempFrame));%NaN(row_t ,col_t,length(tempFrame));
  for (i=1:length(tempFrame))
    x(:,:,i) = tempFrame{i}; % Transpose to make the reshaping simpler.
  end
  
  % Close waitbar
  if ishandle(wbhandle);
    delete(wbhandle);
  end
  fclose(f);
  
catch
  if ishandle(wbhandle)
    delete(wbhandle);
  end
  
  fclose(f);
  rethrow(lasterror)
end

end

%--------------------------------------------------------------------------
function [xmlraw, xmlAttributes] = xmlextract(f,xmlFooterOffset)
% xmlextract extracts the xml footer from the spe file.
% temp xml file name.
tempfilename = [tempname '.xml'];

% Move to XML footer location
fseek(f,xmlFooterOffset,'bof');
% Create a temp xml file for the spe xml footer
[ftemp, msg] = fopen(tempfilename,'w');

% Read the footer & save it into the temp xml file.
while(~feof(f))
  tmp = fread(f,1);
  fwrite(ftemp,tmp,'bit8');
end
fclose(ftemp); % close the temp file for writing.

% Extract XML data from the temp file. NOTE: readstruct only available in
% R2020b.
[xmlraw] = readstruct(tempfilename); %xDoc = xmlread(tempfilename);
delete(tempfilename);

end

%--------------------------------------------------------------------------
function value = getAttributeValue(attributes,field)
% Get the value of an attribute at a specified field.
value = str2num(attributes.(field));
end

function out = parsePixelFormat(pixelFormat)
% Covert the PixelFormat from the xmlfooter to a string used for fread().
switch(pixelFormat)
  case {'MonochromeUnsigned16',3}
    out = 'uint16';
  case {'MonochromeUnsigned32',8}
    out = 'uint32';
  case {'MonochromeFloating32',0}
    out = 'float32';
  case {2} % v2.x only
    out = 'int16';
  case {1} % v2.x only
    out = 'int32';
  case {5} % v2.x only
    out = 'float64';
  otherwise
    error ('Unrecignized pixelFormat');
end
end

%--------------------------------------------------------------------------
function value = seeknget(f,offset,amount,type)
% Seek an offset location in the file via handle (f) & read in values of type 'type'.
fseek(f,offset,'bof');
value = fread(f,amount,type);
end

%--------------------------------------------------------------------------
function [startx,starty,roiwidth,roiheight,framesize] = getROIcoordinates(xmlraw)
%function [startx,endx,starty,endy] = getROIcoordinates(xmlraw)
% Updating this sub function with newer references to xml doc. Difficult to
% know if this is the correct way to get mappings but it seems to be
% similar to what we did in the old code.

%From the documentation:
%   The following applies to the SensorMapping calibration:
%   1. The x and y attributes describe the top-left corner on the sensor (zero-based).
%   2. The height and width attributes describe the size of the region on the sensor in pixels.
%   3. The xBinning and yBinning attributes describe the combination of columns and rows
%      on the sensor in relation to image data. This point of view is after the orientation is
%      applied to the sensor.
startx = zeros(1,length(xmlraw.DataFormat.DataBlock(1).DataBlock));
starty = startx;
roiwidth = startx;
roiheight = startx;

if isfieldcheck('xmlraw.Calibrations.SensorMapping',xmlraw)
  %This works for image files we've tried.
  % Preallocate the size for these vectors.
  for i=1:length(xmlraw.Calibrations.SensorMapping)
    % (end == length + start -1)
    startx(i) = xmlraw.Calibrations.SensorMapping(i).xAttribute;
    starty(i) = xmlraw.Calibrations.SensorMapping(i).yAttribute;
    roiwidth(i) = xmlraw.Calibrations.SensorMapping(i).widthAttribute;
    roiheight(i) = xmlraw.Calibrations.SensorMapping(i).heightAttribute;
  end
  
  %Use the startx and starty to infer how to concatenate each ROI to create
  %overall frame size. Only inferring x or y direction to concatenate, this
  %will get hosed up if there's tiling.
  
  framesize = [roiheight(1) startx(end)+roiwidth(end)];
  if length(starty)>1 && starty(2)>starty(1)
    framesize = [starty(end)+roiheight(end) roiwidth(1)];
  end
else
  %No sensor info so infer spectrum.
  for i = 1:length(xmlraw.DataFormat.DataBlock(1).DataBlock)
    roiwidth = xmlraw.DataFormat.DataBlock(1).DataBlock(i).widthAttribute;
    roiheight = xmlraw.DataFormat.DataBlock(1).DataBlock(i).heightAttribute;
  end
  framesize = [length(startx) roiwidth];
end

end
