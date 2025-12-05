function model = ensemble(varargin)
%ENSEMBLE Predictions based on multiple calibrated regression models.
% Build an ensemble from a collections of any number of models. ENSEMBLE 
% uses model fusion, which is combining previously calibrated models. This 
% assumes that the models in the ensemble are calibrated on the same set of
% samples. The ensemble model's calibration error ends up being the root 
% mean squared% error of the aggregated predictions from each of the models. 
% If each model is cross-validated, the ensemble's cross-validation error is the
% root mean squared error of each of the model's cross-validation
% predictions. ENSEMBLE can be applied to new data. This involves taking
% the aggregated predictions from each of the models in the ensemble. There
% are a few ways to aggregate predictions using ENSEMBLE: 'mean' 'median'
% and 'jackknife'. See the options for a description on jackknife
% aggregation.
%
% INPUTS:
%        x  = X-block (predictor block) class "double" or "dataset",
%        y  = Y-block (predicted block) class "double" or "dataset",
%    models = cell array of previously generated models.
%
%  Optional input (options) is a
%  structure containing one or more of the following fields:
%         aggregation : [ {'mean'} | 'median' | 'jackknife'] Mode of
%                        aggregation to use for predictions. 'mean' takes
%                        the mean prediction from each model for every
%                        sample, the same is true for 'median'. 'jackknife'
%                        uses a median leave-one-model-out approach, 
%                        followed by another median for the final prediction. 
%           algorithm : [{'fusion'}] Mode of ensemble creation. 'fusion'
%                       takes previously calibrated models and aggregates
%                       their predictions to create the ensemble.
% 
%  OUTPUT:
%     model = standard model structure containing the ENSEMBLE model (See MODELSTRUCT)
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: [model] = ensemble(models,options)
%I/O:  [pred] = ensemble(x,model,options)
%I/O: [valid] = ensemble(x,y,model,options)
%
%See also: AGGREGATEPREDICTIONS CHECKTHEMODELS COMPUTEJACKKNIFE

% Copyright © Eigenvector Research, Inc. 2024
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Start Input
if nargin==0  % LAUNCH GUI
  error('ENSEMBLE does not have an interface at this time.')
end

if ischar(varargin{1}) %Help, Demo, Options
  options = [];
  options.name = 'options';
  options.aggregation = 'mean';
  options.algorithm = 'fusion';
  if nargout==0; evriio(mfilename,varargin{1},options); else; model = evriio(mfilename,varargin{1},options); end
  return;
end

% parse input parameters
[x,y,models,model,options,predictmode] = parsevarargin(varargin);

if ~predictmode
  % check the models
  checkthemodels(models,options.algorithm);
  if ~strcmpi(options.algorithm,'fusion')
    error('Unsupported algorithm for ENSEMBLE')
  end
  % CALIBRATE
  model = modelstruct('ensemble');
  calpred = cell(1,length(models));
  aggregation = options.aggregation;

  % predictions on calibration data
  for i=1:length(models)
    calpred{i} = models{i}.pred{2};
  end
  
  % aggregate the calibration predictions
  calpreds = aggregatepredictions(calpred,aggregation);

  % copy over to model structure
  y = models{i}.detail.data{2};
  model = copydsfields(models{i},model,[],{1 1});
  model = copydsfields(y,model,[],{1 2});
  model.pred{2} = calpreds;
  % package models
  model.detail.ensemble.children = models;
  %Set time and date.
  model.date = date;
  model.time = clock;
  %copy options into model only if no model passed in
  model.detail.options = options;
  model.detail.data = {[] y};
  model = calcystats(model,predictmode,y,calpreds);

  % now do the same for crossvalidation predictions
  candocvpred = ~any(cellfun(@(x) isempty(x.detail.cvpred),models));
  if candocvpred
    cvpred = cell(1,length(models));
    for i=1:length(models)
      switch ndims(models{i}.detail.cvpred)
        case 2
          cvpred{i} = models{i}.detail.cvpred;
        case 3
          cvpred{i} = squeeze(models{i}.detail.cvpred(:,:,models{i}.ncomp));
      end
    end
    % aggregate the crossvalidation predictions
    cvpreds = aggregatepredictions(cvpred,aggregation);
    if ~isempty(cvpreds)
      model.detail.cvpred = cvpreds;
      temp = model;
      temp.pred{2} = cvpreds;
      temp = calcystats(temp,predictmode,y,cvpreds);
      model.detail.rmsecv = temp.detail.rmsec;
      model.detail.r2cv = temp.detail.r2c;
      model.detail.cvbias = temp.detail.bias;
    end
  else
    warning('EVRI:Ensemble','At least 1 model was not cross-validated. CV stats for ensemble are left empty')
  end
else
  % APPLY
  % have model, do predict
  % check the models
  checkthemodels(models,model.detail.options.algorithm);

  if ~strcmpi(model.modeltype,'ensemble')
    error('Input MODEL is not a ENSEMBLE model');
  end
  aggregation = model.detail.options.aggregation;
  % predictions on validation data
  pred = cell(1,length(models));
  for i=1:length(models)
    temp = models{i}.apply(x);
    pred{i} = temp.pred{2};
  end
  % aggregate the validation predictions
  preds = aggregatepredictions(pred,aggregation);
  model.pred{2} = preds;
  model.modeltype = 'ENSEMBLE_PRED';
  model = copydsfields(x,model,1,{1 1});
  model.detail.includ{1,2} = x.include{1};
  if ~isempty(y)
    y.include{2} = model.detail.includ{2,2};
    model.detail.data = {[] y};
    model = calcystats(model,predictmode,y,preds);
  end
end
end
%--------------------------------------------------------------------------

function [x,y,models,model,options,predictmode] = parsevarargin(varargin)
x = [];
y = [];
models = [];
model = [];
options = [];
predictmode = 0;
varargin = varargin{1};
switch length(varargin)
  case 2
    %ensemble(models,options)

    % checking model
    if iscell(varargin{1})
      if all(cellfun(@ismodel,varargin{1}))
        models = varargin{1};
        if length(models) < 2
          error('ENSEMBLE requires at least 2 models')
        end
      else
        error('At least 1 element in cell array is not an evrimodel. Please check that all elements are evrimodels.')
      end
    else
      error('Expecting cell array of models as first input when calling ensemble with 2 arguments.')
    end

    % checking options
    if isstruct(varargin{2})
      options = varargin{2};
    end

  case 3
    %ensemble(x,model,options)

    %checking x
    if isdataset(varargin{1}) | isnumeric(varargin{1})
      x = varargin{1};
    else
      error('Expecting Xblock as first argument when calling ensemble with 3 arguments.')
    end

    %checking model
    if ismodel(varargin{2})
      model = varargin{2};
      predictmode = 1;
      if isfieldcheck(model,'.detail.ensemble.children')
        models = model.detail.ensemble.children;
      else
        error('Children models are missing. Please check modeltype.')
      end
    end

    % checking options
    if isstruct(varargin{3})
      options = varargin{3};
    end

  case 4
    %ensemble(x,y,model,options)

    %checking x
    if isdataset(varargin{1}) | isnumeric(varargin{1})
      x = varargin{1};
    else
      error('Expecting Xblock as first argument when calling ensemble with 4 arguments.')
    end

    %checking y
    if isdataset(varargin{2}) | isnumeric(varargin{2})
      y = varargin{2};
    else
      error('Expecting Yblock as second argument when calling ensemble with 4 arguments.')
    end

    %checking model
    if ismodel(varargin{3})
      model = varargin{3};
      predictmode = 1;
      if isfieldcheck(model,'.detail.ensemble.children')
        models = model.detail.ensemble.children;
      else
        error('Children models are missing. Please check modeltype.')
      end
    end

    % checking options
    if isstruct(varargin{4})
      options = varargin{4};
    end

  otherwise
    error('Unrecognized input to ensemble.')
end
end