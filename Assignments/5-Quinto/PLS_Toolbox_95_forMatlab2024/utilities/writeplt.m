function success = writeplt( model,file)
%WRITETOPLT .plt writer, exports an EVRI model as a Vision Air .plt model.
% WRITEPLT is designed as a driver function for the m-file:
% writepltengine.m (which is provided by Metrohm).
%
% INPUTS:
%      model   = standard model structure containing the PLS model (See MODELSTRUCT).
%      file    = text string with name of the .plt file to read
%
% OUTPUTS:
%      success = a bool indicating if the export was successful.
%
%I/O: success = writeplt( model,file)
%I/O: success = writeplt( model)
%
%See also: AUTOIMPORT, TEXTREADR, PLTREADR, VISIONAIRXMLREADR
%
% Copyright © Eigenvector Research, Inc. 2004
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
% Default options here

  % Todo: no input arguments? prompt for a model
  % then prompt for a file to save to.
  if (nargin==0)
    success = [];
    return;
  end
  % check user specified values.
  if isempty(model)
    success = [];
    return;
  end
  if isempty(file)
    [file, pathname] = evriuiputfile({'*.plt','PLT Model Files';'*.*','All Files (*.*)'});
    file = [pathname,file];
  else
    [filepath,name,ext] = fileparts(file);
    if isempty(filepath)
    filepath = pwd;
    file = fullfile(filepath,[name ext]); % todo: check ext need to be .plt
    end
  end
  
  if ~(exist('writepltengine.m') == 2)
    error('Cannot find writepltengine.m to save model as a .plt file.');
  end
  
  try
    unit = model.detail.labelname{2,1}; % Attempt to extract units from model.    
    [node,model] = writepltengine(model,file,[],[],[]);
    success = true;
    return;
  catch
    success = false;
    errordlg('Failed to export Model as a .plt file.','Error exporting model');
    return;
  end
end
