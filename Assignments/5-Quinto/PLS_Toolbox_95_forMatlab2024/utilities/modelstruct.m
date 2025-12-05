function model = modelstruct(varargin)
%MODELSTRUCT Constructs an empty model object.
% Model objects are output by many higher-level PLS_Toolbox functions to
% contain all the results from building the model and all information
% necessary to apply that model to new data (when applicable for a given
% model type).
%
% Some empty model objects can also be used to build new models directly by
% assinging the necessary properties to the model (see model.required) and
% then calling the model.calibrate method (or calibrate(model) )
%
%OPTIONAL INPUTS:
%  modeltype = character string containing the model type to output. If
%              empty or not passed, an undefined model structure is
%              returned which can be used to create any model type.
%
%OUTPUT:
%    model   = standard model structure (format depends on input).
%
%I/O: model = modelstruct(modeltype);
%
%See also: ANALYSIS, COPYDSFIELDS, EXPLODE, PARAFAC, PCA, PCR, PLS

%Copyright (c) Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin == 0; varargin{1} = 'io'; end

switch lower(varargin{1})
  case evriio([],'validtopics')
    options = [];
    if nargout==0; clear model; evriio(mfilename,varargin{1},options); else; model = evriio(mfilename,varargin{1},options); end
    return;    
end

model = evrimodel(varargin{:});

