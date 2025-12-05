function [ model ] = pltreadr(file,options)
%PLTREADR .plt reader imports Vision Air .plt model as an EVRI model.
% PLTREADR is designed as a driver function for the m-file:
% readplt.m (which is provided by Metrohm).
%
% OPTIONAL INPUTS:
%      file    = text string with name of the .plt file to read
%      options = structure array with the following fields:
%                (Empty for now)
%
% OUTPUTS:
%      model  = standard model structure containing the PLS model (See MODELSTRUCT).
%
%I/O: model = pltreadr(file,options)
%I/O: model = pltreadr(file)
%I/O: model = pltreadr()
%
%See also: AUTOIMPORT, TEXTREADR, WRITEPLT, VISIONAIRXMLREADR
%
% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
% Default options here

% Input check
switch nargin
  case 0 % If no input, prompt user for a file.
    [file, pathname] = evriuigetfile({'*.plt','PLT Model Files';'*.*','All Files (*.*)'});
    file = [pathname,file];
  case 1 % if string is 'options' return options struct.
    if ((isa(file,'char')) & (strcmpi(file,'options')))
      % Set default options to xblock and exit
      options = [];
      % Set options struct
      model = options;
      return;
    end
  otherwise % 2 input arguments (filename and options struct)
end

% Run reconopts on options

% Check file is a valid filename and that it can be found.
if ~(exist(file))
  error(sprintf('Could not find the file ''%s'' in matlabpaths or in the current active directory.',file));
elseif ~(strcmpi(file(length(file)-3:end),'.plt'))
  error('Invalid file type: pltreadr.m only supports (Vision Air) .plt model files');
else % Check for readplt.m, if can't be found throw an error.
  if ~(exist('readplt.m') == 2)
    error('Cannot find readplt.m to import model from .plt file.');
  end
  % Initial checks passed & found readVisionAirSampleXML.m, attempt import.
  [model] = readplt(file);
end

end

