
%Module2 Perform model calibration for Diviner.
%  Calibrate PLS and MLR models for Diviner. The calibration of these
%  models will depend on the provided preprocessing, crossvalidation
%  settings, maximum lvs, included variables, and variable selection. This
%  serves as the backbone for all model calibration that is to be done in
%  Diviner, regardless of how far the user is in the Diviner run.
%
%  INPUTS:
%     modeltype = char indicating valid evrimodel type to be calibrated,
%        x_cal  = X-block (predictor block) class "double" or "dataset",
%        y_cal  = Y-block (predicted block) class "double" or "dataset",
%     varselect = char indicating which variable selection algorithm to
%                 run. If provided 'refine', then the included variables
%                 from the model must be provided,
%           cvi = {{'vet' 5 1}} Standard cross-validation cell (see crossval),
%        cvopts = options structure for model to be used in crossvalidation,
%           lvs = number of lvs to use, if applicable,
%   includevars = vector of variables to be included in the model,
%        maxlvs = maximum number of lvs to crossvalidate up to,
%        rawssq = ssq table for PLS models.
%
%  OUTPUT:
%        cvmodel  = crossvalidated model
%          ssq    = ssq table for PLS models,
%         ncomp   = number of lvs the model used,
%    varinclude   = vector of included variables in the model.
%
% I/O: [cvmodel,ssq,ncomp,varinclude] = module2('pls',x_cal,y_cal,'Automatic',cvi,cvopts,10,[],[],[]); % initial gridsearch mode
% I/O: [cvmodel,~,~,~]                = module2('pls',x_cal,y_cal,'refine',cvi,cvopts{i},10,includedvars,maxlvs,ssq); % latent variable survey mode
%
%See also: DIVINER PLS PCA MODELOPTIMIZER ANALYSIS PREPROCESS

%Copyright Eigenvector Research, Inc. 2024
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
