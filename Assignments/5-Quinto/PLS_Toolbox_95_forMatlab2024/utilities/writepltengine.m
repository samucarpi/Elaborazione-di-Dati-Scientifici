
% WRITEPLT writes a PLS_Toolbox model object from the Matlab workspace
%  to a Vision Air plt file.
%
% SYNTAX:
%
%   docNode = writeplt(model, fn, modelname, options)
%
% INPUT:
%   model:       valid model object from PLS_Toolbox. Supported models
%                are: pls, pls-da, ann, svm, mlr, pca, simca, knn, svmda,
%                lwr, pcr
%   fn:          Full path to output file
%   modelname:   Model name as shown in Vision Air. if empty is the model
%                type used.
%   units:       Unit of properties. Only applicable for quantitative models.
%                If a non-valid units are replaced with "None". See below
%                for valid units.
%   options:     Options structure with the fields:
%   -version:    Manually specify version number. Format example: 1.0.0.
%                Takes precedence when upedate is True.
%   -guid:       Manually specify guid. Takes precedence when update is True.
%   -update:     true/[false]; if true and fn is an existing plt file, the
%                guid from the existing file will be copied and the
%                version number automatically increased.
%   -encodeFile: [true]/false; if true, the model is embedded in the plt file
%                as a base64 encoded string. If false, the model is written
%                to a mat file and referenced from the plt file.
%   -index:      [1]; specify prediction label index in regression models.
%                E.g. by PLS models with multiple constituents. Or the PC
%                number by PCA models.
%
% OUTPUT:
%   docNode:  Document Object Model which can be used to modify the output
%             file.
%
% SYNOPSIS:
% The function writes a plt file which can be imported with the Vision Air
% Manager and used in Vision Air Routine. If the filename already exists
% the model is updated (i.e. the file is replaced with the current model).
%
% The model must have an axisscale defined in the field
% model.detail.axisscale{2,1}. It is recommended to ensure the axisscale is
% defined in the dataset prior to creating the calibration. This can be
% done as follows:
%
%  ds = dataset(x)
%  ds.axisscale{2,1} = 400:0.5:2499.5
%  ds.axisscalename{2,1} = 'Wavelength
%
% Use the include field in the dataset or the GUI to edit the wavelengths
% to use in the calibration.
%
% It is recommended to expand the data matrix 400 - 2499.5 range before use
% if the data was collected on a non Metrohm NIR instrument.
%
% VALID UNITS:
%   'None'
%   '#'
%   '#-%'
%   '%'
%   'µg/L'
%   'µm'
%   '1000/mL'
%   'Absorbance Units'
%   'g/L'
%   'g/mL'
%   'mg/dL'
%   'mg/L'
%   'mK'
%   'mL/100g'
%   'mM'
%   'mmol/10 kg'
%   'mmol/L'
%   '°Brix'
%   '°C'
%   '°TH'
%   '°SH'
%   '°D'
%   'Volume-%'
%   'Weight-%'
%   'mm'
%   'kg/hL'
%   'lb/Bu'
%   'mm3'
%   'cm3'
%   'mmol/kg'
%   'Mcal/lb'
%   'Mcal/kg'
%   'ppm'
%   'ppb'
%   'g/lb'
%   'mg/lb'
%   'meq'
%   'mL'
%   'mg/100g'
%   'mgN/dL'
%   'kg'
%   'g'
%   'µmol/g'
%   'lb'
%   'rpm'
%   'J'
%   'mg/g'
%   'in'
%   'L*'
%   'kJ/kg'
%   'PSI'
%   'MPa'
%   'Kg/L'
%   'cP'
%   'mm2/s'
%   'ml/g'
%   '‰'
%   'kg/m3'
%   'St'
%   'cSt'
%   'mPas'
%
%
% Author : Oliver Weinhold
% Creation date : (2017-01-09)
% Copyright (c)  by Metrohm AG, Ionenstr,  Herisau, Switzerland,
% all rights reserved

%% Default value assignment

%TODO reqrite the options handling to a optionsstruct

% no options input is also fine



