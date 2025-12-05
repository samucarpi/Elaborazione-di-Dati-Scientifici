function varargout = comparemodels(varargin)
%COMPAREMODELS Create summary table of models' performance statistics.
% Generate a table which summarizes the performance of a set of input
% models, and also shows their relevant input parameters and options.
% This is useful for comparing the quality of a set of models.
% The table shows:
% Parameters: parameters and important options from each model (LVs, PCs,
% gamma, number of points, etc).
% Statistics: (RMSEC/CV/P, # of support vectors, classification error rates
% as False Pos/Neg Rate average over classes.
% In all cases, value must be a single value for a given model (no vectors).
% Models which are not in the supported model list are ignored (see 
% getallowedmodeltypes).
%
%  INPUTS:
%   models = a cell array containing one or more models.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%        display: [ 'off' | {'on'} ]      governs level of display to command window.
%          plots: [ 'final' | {'none'} ]  governs level of plotting.
%       category: [ {'all'} | 'classification' | 'regression'  | 'decomposition' ]  
%                 restrict output to models of this category type, or all.
%
%  OUTPUTS:
%     columnkeys: 1 x ncolumn cell array containing keys identifying table columns in order.
%   columnlabels: 1 x ncolumn cell array containing descriptive labels for table columns in order.
%    tablevalues: nmodel x ncolumn cell array containing values
%
%I/O: [columnkeys columnlabels tablevalues] = comparemodels(models) % create table
%
%See also: MODELOPTIMIZER

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0
  error([ upper(mfilename) ' requires inputs.'])
end

%parse inputs
if ischar(varargin{1}) %Help, Demo, Options
  if ismember(lower(varargin{1}),evriio([],'validtopics'))
    options = [];
    options.name        = 'options';
    options.display     = 'on';     %Displays output to the command window
    options.plots       = 'none';  %Governs plots to make
    options.category    = 'all';    % Which category of models to show
    options.useweightedmean = 'on'; %Use weighted means when getting mean statistics
    
    if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
    return;
  else
    %Call named sub function.
    if nargout == 0;
      feval(varargin{:}); % FEVAL switchyard
    else
      [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    end
    return
  end
end

switch nargin
  case 1 % (models)
    if iscell(varargin{1})
      models = varargin{1};
      options = comparemodels('options');
    else
      error('Single input parameter must be models (cell array of models or model names).');
    end
    
  case 2  % (models,options)
    if isstruct(varargin{2}) & iscell(varargin{1})
      models = varargin{1};
      options = varargin{2};
    else
      error('Two input parameter must be (models, options).');
    end
end

options = reconopts(options,mfilename);


varargout{1} = [];
varargout{2} = [];
varargout{3} = [];

% ensure models is column, not row
models = models(:);

%Get models if IDs are given.
for i = 1:length(models)
  if ~ismodel(models{i})
    thismodel = modelcache('get',safename(models{i}));
    if ~isempty(thismodel)
      models{i} = thismodel;
    else
      %Can't find model in cache so show error. Maybe cache was purged or
      %cache dir changed.
      evrierrordlg('Model not found in modelcache. Cache may have been purged or changed. Try regenerating model or cache directory.','Can''t Locate Model in Cache')
      return
    end
  end
end

%Remove empties.
rmidx = cellfun('isempty',models);
models(rmidx) = [];


% remove models which are not supported
models = removeunsupportedmodels(models);

% restrict models to specified category
models = restricttocategory(models, options.category);

if numel(models)==0
  erdlgpls(sprintf('There are no input models for category <%s>', options.category))
  varargout = {[] [] []};
  return
end

% get model types and categories sorted by category and subsorted by type
[modeltypes,modelcategs,sortindex] = getmodeltypesandsorting(models);

% get union of column statistics and param labels
[paramnames,statsnames,paramnamescolindex,statsnamescolindex] = getcolumnlabels(models,options);

% statistics
fldnames_stat = fieldnames(statsnames);

% params
fldnames_param = fieldnames(paramnames);

% get the table values ordered to match the column labels
tablevalues = gettablevalues(models, fldnames_param, fldnames_stat, sortindex, paramnamescolindex, statsnamescolindex, options);

% the column keys and user-friendly labels
columnkeys = [fldnames_param' fldnames_stat'];
columnlabels = [struct2cell(paramnames); struct2cell(statsnames)]';
% explicitly added special columns
[scolumnkeys,scolumnlabels] = getspecialcolumns;
columnkeys   = [columnkeys scolumnkeys];
columnlabels = [columnlabels scolumnlabels];

% Have uniqueids, modeltypes, columnkeys, columnlabels, tablevalues

% IO: [columnkeys columnlabels tablevalues] = comparemodels(models)
varargout{1} = columnkeys;
varargout{2} = columnlabels;
varargout{3} = tablevalues;

% example table of results (this does not work in R2009b)
if strcmp(options.plots, 'final')
  fig=figure;
  tablevalues = tablevalues';
  columnnames = ['Value' tablevalues(end,:)];
  tablevalues = [columnlabels' tablevalues];
  
  etable('parent_figure',fig,'tag','comparemodeltable',...
    'data',tablevalues,'column_labels',columnnames,...
    'autoresize','AUTO_RESIZE_SUBSEQUENT_COLUMNS');
end

if nargout==0
  clear varargout
end

%-----------------------------------------------------------
function out = simple(mt)

out = regexprep(lower(mt),'_pred','');

%--------------------------------------------------------------------------
function [params, names] = getparams(model)
% Specify which parameters are associated with each model type
% Get struct with key:value = param_field_name:value for this model
params = struct;
names  = struct;

switch simple(model.modeltype)
  case {'svm' 'svmda' 'svmoc'}
    modelinfo = ...
      {'svmtype'    'SVM Type'      model.detail.options.svmtype
      'kerneltype' 'Kernel Type'   model.detail.options.kerneltype
      'gamma'         'SVM Gamma param.'       model.detail.svm.model.param.gamma
      'epsilon'       'SVM Epsilon param.'     model.detail.svm.model.param.p
      'cost'          'SVM Cost param.'        model.detail.svm.model.param.C
      'nu'            'SVM Nu param.'          model.detail.svm.model.param.nu
      };
  
  case {'xgb' 'xgbda'}
    modelinfo = ...
      {'xgbtype'    'XGBoost Type'              model.detail.options.xgbtype
      'objective'   'Learning Task Objective'   model.detail.options.objective
      'max_depth'   'XGBoost max_depth param.'  model.detail.xgb.model.options.max_depth
      'eta'         'XGBoost eta parameter'     model.detail.xgb.model.options.eta
      'num_round'   'XGBoost num_round param.'  model.detail.xgb.model.options.num_round
      };
    
  case {'pca' 'mpca' 'plsda' 'pls' 'npls' 'pcr' 'mcr'}
    modelinfo = ...
      { 'ncomp'       'Number of components'     model.ncomp };
    
  case 'knn'
    modelinfo = ...
      { 'k'           'Num. Nearest Neighbors'   model.k };
    
    % have nothing
  case {'simca'  }
    modelinfo =  { };
    
  case {'lwr' 'lwrpred'}
    modelinfo = ...
      { 'ncomp'     'Number of components'       model.detail.lvs
        'lwr_npts'   'Number of local reg. pts.'  model.detail.npts
        'lwr_algor' 'LWR algorithm used'    model.detail.options.algorithm 
        'lwr_reglvs' 'Number of local LVs'  model.detail.options.reglvs
      };
    
    % mlr
  case {'mlr' 'cls'}
    modelinfo =  { };
    
  case {'ann' 'annda'}
    modelinfo = ...
      { 'nhid1'   'Nodes 1st layer'  model.detail.options.nhid1 
        'nhid2'   'Nodes 2nd layer'   model.detail.options.nhid2 
      };
  case {'anndl' 'anndlda'}
    switch model.detail.options.algorithm
      case 'sklearn'
        opts = model.detail.options.sk;
        modelinfo = ...
          { 'hidden_layer_sizes'   'Sklearn Layers' opts.hidden_layer_sizes
            'activation'           'Activation'     opts.activation
            'solver'               'Solver'         opts.solver
          };
      case 'tensorflow'
        opts = model.detail.options.tf;
        modelinfo = ...
          { 'hidden_layer'   'Tensorflow Layers'  opts.hidden_layer
            'activation'     'Activation'         opts.activation
            'optimizer'      'Optimizer'          opts.optimizer
          };
    end
    
  case {'lreg' 'lregda'}
    modelinfo = ...
      { 'lambda'   'Regularization'  model.detail.options.lambda 
      };
    
  case {'tsne' 'umap'}
    modelinfo = ...
      { 'n_components'   'Number of components'  model.detail.options.n_components 
      };
    
  case {'lda'}
    modelinfo = ...
      { 'ncomps'    'Number of components'      model.ncomp
        'lambda'   'Regularization'            model.detail.options.lambda
      };
    
  case {'ensemble'}
    modelinfo = ...
      { 'aggregation'    'Prediction Aggregation'      model.detail.options.aggregation
      };
  otherwise
    error('Unsupported modeltype: %s', lower(model.modeltype))
end
% Allow for customization. getuserparams would be similar function to this.
% params = getuserparams(model, params)

% create the params and names structures for this model
for j=1:size(modelinfo,1);
  key = modelinfo{j,1};
  params.(key) = modelinfo{j,3};
  names.(key)  = modelinfo{j,2};
end

%--------------------------------------------------------------------------
function [statistics, names] = getstatistics(model, options)
% Get struct with key:value = input_field_name:value for this model
statistics = struct;
names      = struct;

info1 = {}; info2 = {};
% if is classifier and is not pred
if strcmp('classification', getCategory(model))
  if isempty(strfind(lower(model.modeltype), '_pred')) & ~isempty(model.detail.cvclassification.probability)
    falseratesc   = getmisclassed(model, 0, options);
    falseratescv = getmisclassed(model, 1, options);
    info1 = ...
      {
      % [FPR FNR], average over classes
      % What about pred:      'misclassedp'  'Misclassified Rate (Pred)' model.detail.misclassedp
      'fpc' 'Avg. False Pos. Rate (Cal)'      falseratesc(1)
      'fnc' 'Avg. False Neg. Rate (Cal)'      falseratesc(2)
      'er'  'Error Rate (Cal)'                falseratesc(3)
      'p'   'Precision (Cal)'                 falseratesc(4)
      'f'   'F1 Score (Cal)'                  falseratesc(5)
      'fpcv' 'Avg. False Pos. Rate (CV)'      falseratescv(1)
      'fncv' 'Avg. False Neg. Rate (CV)'      falseratescv(2)
      'ercv' 'Error Rate (CV)'                falseratescv(3)
      'pcv'  'Precision (CV)'                 falseratescv(4)
      'fcv'  'F1 Score (CV)'                  falseratescv(5)
      'fppred' 'Avg. False Pos. Rate (Pred)'  []
      'fnpred' 'Avg. False Neg. Rate (Pred)'  []
      'erpred' 'Error Rate (Pred)'            []
      'ppred'  'Precision (Pred)'             []
      'fpred'  'F1 Score (Pred)'              []
      };
  else
    falseratesc   = getmisclassed(model, 0, options);
    info1 = ...
      {
      % [FPR FNR], average over classes
      'fpc' 'Avg. False Pos. Rate (Cal)'  falseratesc(1)
      'fnc' 'Avg. False Neg. Rate (Cal)'  falseratesc(2)
      'er'  'Error Rate (Cal)'            falseratesc(3)
      'p'   'Precision (Cal)'             falseratesc(4)
      'f'   'F1 Score (Cal)'              falseratesc(5)
      };
  end
end
if strcmp('regression', getCategory(model))  
  rmsec = []; rmsecv = []; rmsep = []; r2c = []; r2cv = []; bias = []; cvbias = [];
  if isfield(model, 'loads') | strcmpi(model.modeltype,'ann') | strcmpi(model.modeltype,'anndl')
    if strcmpi(model.modeltype,'ann')
      ncomp = model.detail.options.nhid1;
    elseif strcmpi(model.modeltype,'anndl')
      ncomp = getanndlnhidone(model);
    else
      ncomp = model.ncomp;
    end
    if ~isempty(model.detail.rmsec)
      rmsec = model.detail.rmsec(:,min(end,ncomp));
    end
    if ~isempty(model.detail.rmsecv)
      rmsecv = model.detail.rmsecv(:,min(end,ncomp));
    end
    if ~isempty(model.detail.rmsep)
      rmsep = model.detail.rmsep(:,min(end,ncomp));
    end
    if ~isempty(model.detail.r2c)
      r2c = model.detail.r2c(:,min(end,ncomp));
    end
    if ~isempty(model.detail.r2cv)
      r2cv = model.detail.r2cv(:,min(end,ncomp));
    end
    if ~isempty(model.detail.bias)
      bias = model.detail.bias(:,min(end,ncomp));
    end
    if isfield(model.detail, 'cvbias') & ~isempty(model.detail.cvbias)
      cvbias = model.detail.cvbias(:,min(end,ncomp));
    end
  else
    rmsec  = model.detail.rmsec;
    rmsecv = model.detail.rmsecv;
    rmsep  = model.detail.rmsep;
    r2c    = model.detail.r2c;
    r2cv   = model.detail.r2cv;
    bias   = model.detail.bias;
    if isfield(model.detail, 'cvbias')
      cvbias = model.detail.cvbias;
    end
  end
  if isempty(rmsecv)
    rmseratio = nan(size(rmsec));
  else
    rmseratio = rmsecv./rmsec;
  end
  info1 = ...
    {
    'rmsec'      'RMSEC (Cal)'               rmsec
    'rmsecv'     'RMSECV (CV)'               rmsecv
    'rmsep'      'RMSEP (Pred)'              rmsep
    'rmseratio'  'RMSE Ratio (RMSECV/RMSEC)' rmseratio
    'r2c'        'R2C (Cal)'                 r2c
    'r2cv'       'R2CV (CV)'                 r2cv
    'bias'       'Bias'                      bias
    'cvbias'     'Bias (CV)'                 cvbias
    };
  comptype = []; compnum = [];
  if isfield(model.detail, 'compressionmodel') & ~isempty(model.detail.compressionmodel)
    comptype = model.detail.compressionmodel.modeltype;
    compnum  = model.detail.compressionmodel.ncomp;
    info2 = ...
      {
      'compress'      'Compression Type'           comptype
      'compnum'       'Num. Compression Comp.'     compnum
      };
  end
end

info = {};
switch simple(model.modeltype)
  case {'svmda' 'svm' 'svmoc'}
    info = ...
      {
        'nsv'  'Number Support Vectors'   model.detail.svm.model.l
      };
    
  case {'pca' 'mpca' 'mcr' }
    ncomp = size(model.loads{1},2);
    rmsec = []; rmsecv = []; rmsep = [];
    if ~isempty(model.detail.rmsec) & length(model.detail.rmsec)>=ncomp
      rmsec = model.detail.rmsec(ncomp);
    end
    if ~isempty(model.detail.rmsecv) & length(model.detail.rmsecv)>=ncomp
      rmsecv = model.detail.rmsecv(ncomp);
    end
    if isfield(model.detail, 'rmsep') & ~isempty(model.detail.rmsep) & length(model.detail.rmsep)>=ncomp
      rmsecv = model.detail.rmsecv(ncomp);
    end
    info = ...
      {
      'rmsec'      'RMSEC (Cal)'               rmsec
      'rmsecv'     'RMSECV (CV)'               rmsecv
      'rmsep'      'RMSEP (Pred)'              rmsep
      'rmseratio'  'RMSE Ratio (RMSECV/RMSEC)' rmsecv./rmsec
      };

  case 'plsda'
    info = ...
      { };
    
  case 'knn'
    info = { };
    
  case 'simca'
    info = { };
    
  case {'tsne'}
    info = ...
      {
        'num_neighbors' 'Neighbors/Perplexity' model.detail.options.perplexity
        'KLDivergence'  'KL Divergence'   model.detail.tsne.distance_metrics.kl_divergence
      };
    if isfield(model.detail.tsne.distance_metrics,'ratio_min')
      info = ...
        { info{:}
          'distance_ratio_min'  'Distance Ratio (min)'   model.detail.tsne.distance_metrics.ratio_min
          'distance_ratio_mean'  'Distance Ratio (mean)'   model.detail.tsne.distance_metrics.ratio_mean
        };
    end
      
  case {'umap'}
    info = ...
      {
         'num_neighbors' 'Neighbors/Perplexity' model.detail.options.n_neighbors
      };
    if isfield(model.detail.umap.distance_metrics,'ratio_min')
      info = ...
        {
          info{:}
          'distance_ratio_min'  'Distance Ratio (min)'   model.detail.umap.distance_metrics.ratio_min
          'distance_ratio_mean'  'Distance Ratio (mean)'   model.detail.umap.distance_metrics.ratio_mean
        };
    end
end
info = [info1;info2;info];

% Allow for customization.
% statistics = getuserstatistics(model, stats)

%automatically create the statistics and names structures to pass out
for j=1:size(info,1);
  key = info{j,1};
  statistics.(key) = info{j,3};
  names.(key)  = info{j,2};
end

%--------------------------------------------------------------------------
function modelsout = restricttocategory(models, thecategory)
% restrict models to specified category
if strcmp(thecategory, 'all')
  modelsout = models;
  return
end

modelcategs = cell(numel(models),1);
for ii = 1:numel(models)
  modelcategs{ii} = getCategory(models{ii});
end

categorymask = ismember(modelcategs, {thecategory});

modelsout = models(categorymask);

%--------------------------------------------------------------------------
function [modeltypes, modelcategs, sortindex] = getmodeltypesandsorting(models)
% get a list of the input modeltypes and categories. The most important
% returned quantity is the index, sortindex, which organizes the models so
% they are sorted by category, then subsorted by modeltype
modeltypes  = cell(numel(models),1);
modelcategs = cell(numel(models),1);
modelcatplustype = cell(numel(models),1);
for ii = 1:numel(models)
  model = models{ii};
  modeltypes{ii}  = simple(model.modeltype);
  modelcategs{ii} = getCategory(model);
  modelcatplustype{ii} = [modelcategs{ii} modeltypes{ii}];
end

[modelcattypeSorted, sortindex] = sort(modelcatplustype);

%--------------------------------------------------------------------------
function allowedmodels = getallowedmodels
% modeltype must appear here or the model will not be considered
allowedmodels = ...
  { 
  'knn' 'classification';
  'plsda' 'classification';
  'simca' 'classification';
  'svmda' 'classification';
  'xgbda' 'classification';
  'annda' 'classification';
  'anndlda' 'classification';
  'lregda' 'classification';
  'lda' 'classification';
  'mcr' 'decomposition';
  'par' 'decomposition';
  'parafac' 'decomposition';
  'par2' 'decomposition';
  'parafac2' 'decomposition';
  'pca' 'decomposition';
  'mpca' 'decomposition';
  'tsne' 'decomposition';
  'umap' 'decomposition';
  'cls' 'regression';
  'lwr' 'regression';
  'lwrpred' 'regression';
  'mlr' 'regression';
  'nip' 'regression';
  'npl' 'regression';
  'npls' 'regression';
  'pcr' 'regression';
  'sim' 'regression';
  'svm' 'regression';
  'xgb' 'regression';
  'pcr' 'regression';   % Had to add this since it wasn't in modelstruct/template *********
  'pls' 'regression';   % Had to add this since it wasn't in modelstruct/template *********
  'ann' 'regression';
  'anndl' 'regression';
  'ensemble' 'regression';
  };
% Currently not supported
%   'svmoc' 'classification';

% TODO: consider replace second col by isclassification and number of blocks in pred,
% one block means decomp.

%--------------------------------------------------------------------------
function allowedmodeltypes = getallowedmodeltypes
% list of allowed modeltypes. This specifies the order in which models are
% presented in views

allowedmodeltypes = getallowedmodels;
allowedmodeltypes = allowedmodeltypes(:,1);

%--------------------------------------------------------------------------
function allowedmodelcategories = getallowedmodelcategories
% list of allowed modeltypes. This specifies the order in which models are
% presented in views

allowedmodelcategories = getallowedmodels;
allowedmodelcategories = allowedmodelcategories(:,2);


%--------------------------------------------------------------------------
function modelcateg = getCategory(model)
modeltype = simple(model.modeltype);
allowedmodeltypes      = getallowedmodeltypes;  % bad calling every time
allowedmodelcategories = getallowedmodelcategories;
[isallowedtype,i2]     = ismember(modeltype, allowedmodeltypes);
if isallowedtype
  modelcateg = allowedmodelcategories{i2};
else
  error('Unknown model category for model with type: %s', modeltype);
end

%--------------------------------------------------------------------------
function resultvalues = gettablevalues(models, fldnames_param, fldnames_stat, sortindex, paramnamescolindex, statsnamescolindex, options)
nmodels           = size(models,1);
specialcolumnkeys = getspecialcolumns; % for modeltype, uniqueid, and date
nspecialcols      = numel(specialcolumnkeys);
  
% table values. nparams + nstats + nspecialcols cols 
% Note, the special cols must be added at the end of normal cols
ncols = size(fldnames_stat,1)+size(fldnames_param,1);
resultvalues = cell(nmodels, ncols + nspecialcols);
paramsoffset = length(fldnames_param);
for ii=1:nmodels
  model          = models{sortindex(ii)};
  resultvalues(ii, (ncols+1):(ncols+nspecialcols)) = getspecialcolumnvalues(model);
  params = getparams(model);
  statistics = getstatistics(model, options);
  % Insert these params in appropriate cols for row ii
  % parameters
  fn = fieldnames(params);
  for fld=fn'
    icol = paramnamescolindex.(char(fld));
    value = params.(char(fld));
    if ~isnumeric(value) & ~ischar(value) %& ~isempty(resultvalues{ii, icol})
      value = encode(value, struct('includeclear', 'off', 'floatdigits', 4)); % *** temporary ***
    end
    resultvalues{ii, icol} = value;
  end
  % statistics
  fns = fieldnames(statistics);
  for fld=fns'
    icol = paramsoffset+statsnamescolindex.(char(fld));
    value = statistics.(char(fld));
    if isnumeric(value) & length(value)>1
      value = sprintf('%3.3g ', value);
    end
    if ~isnumeric(value) & ~ischar(value) %& ~isempty(resultvalues{ii, icol})
      value = encode(value, struct('includeclear', 'off', 'floatdigits', 4)); % *** temporary ***
    end
    resultvalues{ii, icol} = value;
  end
end

%--------------------------------------------------------------------------
function [paramnames, statsnames, paramnamescolindex, statsnamescolindex] = getcolumnlabels(models, options)
nmodels = numel(models);
paramnames  = struct;  % names of model params over all input models
statsnames  = struct;  % names of model statistics over all input models
paramnamescolindex  = struct;  % names of model params over all input models
statsnamescolindex  = struct;  % names of model statistics over all input models
iparamcount         = 1;
istatscount         = 1;
% loop over input models extracting params and statistics
for ii = 1:nmodels
  model = models{ii};
  [params, names_param]  = getparams(model);
  [statistics, names_stat]  = getstatistics(model, options);
  
  %automatically create the params and names structures to pass out
  fldnames_param = fieldnames(names_param);
  for j=1:numel(fldnames_param)
    key = fldnames_param{j};
    % add key if it is not already there
    if ~ismember(key, fieldnames(paramnames))
      paramnames.(key)  = names_param.(key);
      paramnamescolindex.(key) = iparamcount;  % keep track of which column
      iparamcount = iparamcount+1;
    end
  end
  
  fldnames_stat = fieldnames(names_stat);
  for j=1:numel(fldnames_stat)
    key = fldnames_stat{j};
    % add key if it is not already there
    if ~ismember(key, fieldnames(statsnames))
      statsnames.(key)  = names_stat.(key);
      statsnamescolindex.(key) = istatscount;  % keep track of which column
      istatscount = istatscount+1;
    end
  end
end

%--------------------------------------------------------------------------
function misclassed = getmisclassed(model, usecv, options)
% return a 1x5 vector of rates: [FPR FNR Err P F] (false pos, false neg, classification error, precision, F1)
if strcmp(model.modeltype, 'KNN')
  if usecv & isempty(model.detail.cvclassification.probability)
    misclassed = [];
    return
  end
end
% disp(sprintf('modeltype = %s, usecv = %d', model.modeltype, usecv))
cm = confusionmatrix(model, usecv);

% [FPR FNR, ER], simple mean over classes
if ~strcmp(lower(options.useweightedmean),'on')
  % Use simple mean over classes
  misclassed = mean(cm(:,[2 4 6 7 8]),1);
else
  % Use class count-weighted mean
  tvals = cm(:,[2 4 6 7 8]);   % FPR FNR ErrorRate Precision F-measure
  ncounts = cm(:,5)';
  misclassed = ncounts*tvals/sum(ncounts);
end

%--------------------------------------------------------------------------
function [models, disallowedmodels] = removeunsupportedmodels(models_in)
% remove models which are not supported
allowedmodeltypes = getallowedmodeltypes;

modeltypes = cell(1,numel(models_in));
for ii = 1:numel(models_in)
  model = models_in{ii};
  modeltypes{ii}  = simple(model.modeltype);
end
allowedindices = ismember(modeltypes, allowedmodeltypes);

models = models_in(allowedindices);
disallowedmodels = models_in(~allowedindices);

%--------------------------------------------------------------------------
function [columnkeys, columnlabels] = getspecialcolumns
% Special column key and label
% Note: The order must be consistent with getspecialcolumnvalues.
% Add a new column by modifying this function and in getspecialcolumnvalues.
columnkeys = {'modeltype' 'date' 'preprox' 'preproy' 'uniqueid'};
columnlabels = {'Model Type' 'Date' 'X Preprocessing' 'Y Preprocessing' 'Model ID'};

%--------------------------------------------------------------------------
function [specialcolvals] = getspecialcolumnvalues(model)
% Special column values. 
% Note: Their order must be consistent with getspecialcolumns.
% Add a new column by modifying this function and in getspecialcolumns.
  specialcolvals = {};
  % modeltype
  specialcolvals{end+1} = model.modeltype;
  % date
  dateformat='dd-mmm-yyyy HH:MM:SS';
  specialcolvals{end+1} = datestr(model.time,dateformat);
  % preprocessing (X, then Y)
  separatorstring = '-+-';
  pad = [' ' separatorstring ' '];
  ppros=model.detail.preprocessing;
  if ~isempty(ppros) & ~isempty(ppros{1})
    ppx=ppros{1};
    if isstruct(ppx)
      preprox = {ppx.keyword};
    else
      preprox = {ppx};
    end
    preprox = cell2str(preprox, pad);
  else
    preprox = 'None';
  end
  if length(ppros)>1 & ~isempty(ppros{2})
    ppy=ppros{2};
    if isstruct(ppy)
      preproy = {ppy.keyword};
    else
      preproy = {ppy};  
    end
    preproy = cell2str(preproy, pad);
  else
    preproy = 'None';
  end
  specialcolvals{end+1} = preprox;
  specialcolvals{end+1} = preproy;
  % uniqueid
  specialcolvals{end+1} = model.uniqueid;
