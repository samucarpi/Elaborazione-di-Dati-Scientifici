function varargout = visionairxmlreadr(filename,options)
%VISIONAIRXMLREADR Vision Air XML Reader imports .xml files that are Vision
% Air/Metrohm formatted.
% VISIONAIRXMLREADR is designed as a driver function for the m-file:
% readVisionAirSampleXML.m (which is provided by Metrohm). Yblock may be
% empty.
%
% INPUTS:
%      filename    = text string with name of excel file to read
% OPTIONAL INPUTS:
%   options = an options structure containing one or more of the following
%      bock    = ['both' | {'x'} | 'y'] What block to load.
%
% OUTPUTS:
%      xblock  = dataset object, the x-block
%      yblock  = dataset object, the y-block
%
%I/O: [ xblock, yblock ] = visionairxmlreadr(filename,options)
%I/O: [ xblock, yblock ] = visionairxmlreadr(filename)
%I/O: [ xblock, yblock ] = visionairxmlreadr()
%
%See also: AUTOIMPORT, TEXTREADR, WRITEPLT, PLTREADR
%
% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
% BK 6/27/2017

% Input check
if nargin == 0
  filename = '';
end

if ischar(filename) & ismember(filename,evriio([],'validtopics'))
  options = [];
  options.block = 'x';%Which block to load x, y, or both.
  % Set options struct
  if nargout==0; clear varargout; evriio(mfilename,filename,options); else varargout{1} = evriio(mfilename,filename,options); end
  return;
end

if nargin<2
  %Get defaults with empty.
  options = [];
  if nargout>1
    options.block = 'both';
  end
end

%Verify options.
options = reconopts(options,mfilename);

% If no file name provided, get one.
if isempty(filename)
  [filename, pathname] = evriuigetfile({'*.xml','Readable Files';'*.*','All Files (*.*)'});
  if filename==0
    %User cancel.
    if nargout>0
      [varargout{1:nargout}] = deal([]);
    end
    return
  end
  filename = [pathname,filename];
end

% Check file is a valid filename and that it can be found.
if ~(exist(filename))
  error(sprintf('Could not find the file ''%s'' in matlabpaths or in the current active directory.',filename));
elseif ~(strcmpi(filename(length(filename)-3:end),'.xml'))
  error('Invalid file type: visionairxmlreadr.m only supports (Vision Air Formatted) .xml files');
else % Check for readVisionAirSampleXML.m, if can't be found throw an error.
  if ~(exist('readVisionAirSampleXML.m') == 2)
    error('Cannot find readVisionAirSampleXML.m to import .xml file.');
  end
  % Initial checks passed & found readVisionAirSampleXML.m, attempt import.
  [xblock, yblock] = readVisionAirSampleXML(filename);
  switch options.block
    case 'x'
      varargout{1} = xblock;
    case 'y'
      varargout{1} = yblock;
    case 'both'
      varargout{1} = xblock;
      varargout{2} = yblock;
  end
end

end
