function [results,niter,nbatches] = evrishapley(varargin)
%EVRISHAPLEY Calculate a variable's contribution using Shapley Values.
% Shapley Values can be used to explain each variables's contribution to a 
% prediction. Shapley Values can explain any model type, including 
% decomposition, regression, and classification models. In practice, 
% Shapley Values tell you how much each variable contributes to the 
% deviation of a sample's prediction and the model's average prediction. 
% The sum of the Shapley Values for a sample adds up
% to the deviation from the sample's prediction and the average prediction.
%
% INPUTS:
%        x1  = X-block (predictor block) class "double" or "dataset",
%        x2  = X-block (predictor block) class "double" or "dataset",
%     model  = EVRIModel
%
%  Optional input (options) is a
%  structure containing one or more of the following fields:
%        int_width : [{10}] The window size of variables to group together
%                    for the Shapley Value calculation. Grouping together
%                    highly correlated variables can provide a better
%                    explanation as well as significantly speed up the
%                    algorithm.
%        n_batches : [{'auto'} double] Number of batches to piecemeal
%                    computation. When set to 'auto', n_batches is computed
%                    to preserve memory.
%           n_iter : [{'auto'} double] Number of perturbed samples to
%                     create per iteration. When set to 'auto', this will
%                     be the number of (variables * 2) + 1. Increasing this
%                     gives a more faithful representation of the
%                     contributions but can lock up memory.
%     random_state : [{1}] Random seed number. Set this to a number for reproducibility.
%
%  OUTPUT:
%        results.shap           = Shapley Values for x2.
%        results.baseprediction = Average prediction on x1.
%        results.vargroups      = Variables that were grouped together.
%        results.model          = EVRIModel.
%        results.explainpred    = Predictions on x2.
%        results.vargroups      = Variable groupings cell array.
%        results.calx           = Calibration data.
%        results.x              = Explanation data.
%        results.shapoptions    = evrishapley options structure.
%        niter                  = Number of iterations per sample.
%        nbatches               = Number of batches of samples that were
%                                 grouped together.
%
%I/O: [results,niter,nbatches] = evrishapley(x1,x2,model,options) % explain all predictions in x2
%I/O: [tesults,niter,nbatches] = evrishapley(x1,model,options) % explain all predictions in x1
%
%See also: VIP, SRATIO, IPLS

% Copyright © Eigenvector Research, Inc. 2023
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
% smr


results = [];
niter = [];
nbatches = [];

if ischar(varargin{1}) %Help, Demo, Options
  options = [];
  options.name = 'options';
  options.int_width = 10;
  options.variablegroups = {};
  options.nbatches = 'auto';
  options.niter = 'auto';
  options.algorithm = 'sampling';
  options.random_state = 1;
  options.silent = 'no';

  if nargout==0; evriio(mfilename,varargin{1},options); else; base_prediction=[]; results = evriio(mfilename,varargin{1},options); end
  return;
end

% get inputs, data will be in datasets
[caldata,expdata,model,options] = parsevarargin(varargin);

[results,niter,nbatches,bad] = explain(caldata,expdata,model,options);
end
%--------------------------------------------------------------------------

function [results,niter,nbatches,bad] = explain(caldata,expdata,model,options)
% generate explanations of predictions on the explanation data
% caldata: calibration data
% expdata: explanation data
% model:   calibrated model or function handle
% options: structure of options

shap = [];
base_prediction = [];
niter = [];
nbatches = [];
rng(options.random_state,'twister');

% obtain information about the data
% which variables are we using?
% which samples to explain?
caldatadouble = caldata.data;
expincludedsamples = expdata.include{1};
if isempty(expincludedsamples)
  error('No samples were included in the dataset to explain the model.')
end
if ismodel(model)
  expincludedvariables = model.detail.includ{2};
else
  expincludedvariables = caldata.include{2};
end
nsamples = length(expincludedsamples);
nvariables = length(expincludedvariables);
excludedvariables = setdiff(1:size(expdata,2),expincludedvariables);
allvariables = [expincludedvariables excludedvariables];
nallvariables = length(allvariables);
%haspct = initevripct;


results.model = model;
modeltype = getmodeltype(model);
% can we use modelexporter to speed up predictions?
if exist('exportmodel','file') && ~strcmpi(modeltype,'classification') && ~isdeployed
  dontexportthese = {'SVM'};
  if ~ismember(upper(model.modeltype),dontexportthese)
    tmpfolder = tempdir;
    filename = [upper(model.modeltype) 'shapley'];
    fullpathfilename = [tmpfolder filename];
    meopts = exportmodel('options');
    meopts.handleexcludes = 'placeholders';
    meopts.datastorageformat = 'text';
    meopts.creatematlabfunction = 'yes';
    try  % see if model is exportable
      exportmodel(model,[fullpathfilename '.m'],meopts);
      orig = pwd;
      cd(tmpfolder);
      model = str2func(filename);
      cd(orig);
    end
  end
end
% get dimensions of predictions since shapley explains every output
modeltype = getmodeltype(model);
if strcmpi(modeltype,'regression')
  base_prediction = mean(model.pred{2});
  explainpred = model.apply(expdata(expincludedsamples));
  explainpred = explainpred.pred{2};
  field = 'pred';
elseif strcmpi(modeltype,'decomposition')
  base_prediction = mean(model.scores);
  explainpred = model.apply(expdata(expincludedsamples));
  explainpred = explainpred.scores;
  field = 'scores';
elseif strcmpi(modeltype,'classification')
  base_prediction = mean(model.classification.probability);
  field = 'classification.probability';
  explainpred = model.apply(expdata(expincludedsamples));
  explainpred = explainpred.classification.probability;
elseif isa(model,'function_handle')
  base_prediction = mean(model(caldatadouble));
  % predict on calibration data, get average prediction
  explainpred = model(expdata(expincludedsamples).data);
end
noutputs = size(base_prediction,2);

% handle nbatches and niter
% This in large part determines how many synthetic samples we are creating
niter = options.niter;
nbatches = options.nbatches;
if strcmpi(niter,'auto') || strcmpi(nbatches,'auto')
  [niter,nbatches,minsamplespervar,bad] = dividework(niter,nbatches,nsamples,nvariables,options.int_width);
end
if bad; return; end

% variable groupings
% did user provide?
if isempty(options.variablegroups)
  ngroups = ceil(nvariables/options.int_width);
  variablegroupings = cell(1,ngroups);
  for i=1:ngroups
    thesevariables = (i-1)*options.int_width + (1:options.int_width);
    thesevariables = thesevariables(thesevariables <= nvariables);
    variablegroupings{i} = expincludedvariables(thesevariables);
  end
else
  variablegroupings = options.variablegroups;
  % check user-provided variable groupings
  if ~all(cellfun(@isnumeric,variablegroupings)) || any(cellfun(@isempty,variablegroupings))
    error('Expecting numeric indices for variable group designation.')
  end
  % are there any excluded variables in these groups?
  for i=1:length(variablegroupings)
    thisgroup = variablegroupings{i};
    unq = setdiff(thisgroup,excludedvariables);
    if length(unq)~=length(thisgroup)
      % there are excluded variables in the group
      thisgroup = unq;
    end
    variablegroupings{i} = thisgroup;
  end
  ngroups = length(variablegroupings);
end
nvariables = ngroups; % overwrite
if ~strcmpi(options.silent,'yes')
  if nvariables > 500
    evriwarndlg(['There are over 500 variables to calculate Shapley Values for. '...
                 'This may result in a slow calculation that can take hours.']);
  end
end
expincludedvariables = 1:nvariables; % overwrite
% randomly shuffle the variables
% this is done to generate the x_plus_j's and x_minus_j's
% Use the algorithm by Štrumbelj and Konenenko:
% Štrumbelj, Erik, and Igor Kononenko. “Explaining Prediction Models
% and Individual Predictions with Feature Contributions.” Knowledge and
% Information Systems, vol. 41, no. 3, 2013, pp. 647–665., https://doi.org/10.1007/s10115-013-0679-x.
shuffled_inds = cell(niter,1);
for i=1:niter
  shuffled_inds{i} = shuffle(expincludedvariables')';
end
[~,inds_order] = cellfun(@sort,shuffled_inds,'UniformOutput',false);
shuffled_inds = cat(1,shuffled_inds{:});
inds_order = cat(1,inds_order{:});
sortvarorder = sub2ind(size(shuffled_inds),repmat(1:size(shuffled_inds,1),size(shuffled_inds,2),1)',inds_order);
[posrow,poscol] = arrayfun(@(x) find(x==shuffled_inds),expincludedvariables,'UniformOutput',false);
[~,ind] = cellfun(@(x) sort(x,'ascend'),posrow,'UniformOutput',false);
poscol = arrayfun(@(x) poscol{x}(ind{x}),expincludedvariables,'UniformOutput',false);
datasize = size(shuffled_inds);
xmjinds = cell(1,length(poscol));
for k = 1:length(poscol)
  xmjinds{k} = sub2ind(datasize,1:datasize(1),poscol{k}');
end
maskxmj = cell(1,length(poscol));
maskxpj = cell(size(maskxmj));
% in order to make the synthetic samples, we need to know which parts of
% the sample and the mean data to take. this is denoted by the logical masks realmaskxpj
% realmaskxmj. the generation of the synthetic samples is done later
% through element-wise multiplication
realmaskxpj = cell(size(maskxmj));
realmaskxmj = cell(size(maskxmj));
vargroupxpjmask = cell(size(maskxmj));
vargroupxmjmask = cell(size(maskxmj));
for k=1:length(maskxmj)
  maskxmj{k} = zeros(size(shuffled_inds));
  maskxmj{k}(xmjinds{k}) = 1;
  maskxmj{k} = logical(cumsum(maskxmj{k},2));
  maskxpj{k} = maskxmj{k};
  maskxpj{k}(xmjinds{k}) = 0;
  % sort back
  maskxpj{k} = maskxpj{k}(sortvarorder);
  maskxmj{k} = maskxmj{k}(sortvarorder);
  vargroupxpjmask{k} = arrayfun(@(x) find(maskxpj{k}(x,:)),1:size(maskxpj{k},1),'UniformOutput',false);
  vargroupxmjmask{k} = arrayfun(@(x) find(maskxmj{k}(x,:)),1:size(maskxpj{k},1),'UniformOutput',false);
  realmaskxpj{k} = zeros(size(vargroupxpjmask{k},2),nallvariables);
  realmaskxmj{k} = zeros(size(vargroupxmjmask{k},2),nallvariables);
  for i=1:size(realmaskxpj{k},1)
    varsinthesegroupsxpj = variablegroupings(vargroupxpjmask{k}{i});
    varsinthesegroupsxpj = cat(2,varsinthesegroupsxpj{:});
    realmaskxpj{k}(i,varsinthesegroupsxpj) = 1;
    varsinthesegroupsxmj = variablegroupings(vargroupxmjmask{k}{i});
    varsinthesegroupsxmj = cat(2,varsinthesegroupsxmj{:});
    realmaskxmj{k}(i,varsinthesegroupsxmj) = 1;
  end
end

% divide explain data into batches to protect memory but also limits the
% amount of model.apply calls
batchinds = arrayfun(@(x) expincludedsamples(x:nbatches:end),1:nbatches,'UniformOutput',false);
batchdsos = cellfun(@(x) expdata(x),batchinds,'UniformOutput',false);
% we will sample from the data mean for the x_plus_j and x_minus_j
meancaldata = repmat(mean(caldatadouble),niter,1);

% preallocate shapley values
switch noutputs
  case 1
    shap = nan(nsamples,nvariables);
    shapvar = nan(nsamples,nvariables);
  otherwise
    shap = nan(nsamples,nvariables,noutputs);
    shapvar = nan(nsamples,nvariables,noutputs);
end

% setup waitbar
wb = waitbar(0,'Generating Shapley Values. Please wait...(close to cancel)');
startat = now;
allmymarginalcontributions = cell(1,nvariables);
for k=1:nbatches
  thisbatch = batchdsos{k}.data;
  %Pre-allocate the perturbations
  % 4d synthetic data. The first dimension is the explanation sample. The
  % second dimension is the variable we are testing over. The third and
  % fourth dimensions refer to the data matrix of perturbed samples of that
  % sample (1st dim) and variable (2nd dim).
  % We eventually concatenate all of these matrices by perserving the order
  % of the 2nd dim.
  X_plus_j = nan(size(thisbatch,1),nvariables,niter,nallvariables);
  X_minus_j = nan(size(thisbatch,1),nvariables,niter,nallvariables);
  for i=1:size(thisbatch,1)
    sample = thisbatch(i,:);
    sample = repmat(sample,niter,1);
    for j=1:nvariables
      X_plus_j(i,j,:,:) = reshape(((realmaskxpj{j}).*meancaldata) + ((~realmaskxpj{j}).*sample),1,1,niter,nallvariables);
      X_minus_j(i,j,:,:) = reshape(((realmaskxmj{j}).*meancaldata) + ((~realmaskxmj{j}).*sample),1,1,niter,nallvariables);
    end
  end
  % correctly permute data back perserving order of samples and variables
  % down to 2d data
  X_plus_j = reshape(permute(X_plus_j,[3,2,1,4]),[],nallvariables);
  X_minus_j = reshape(permute(X_minus_j,[3,2,1,4]),[],nallvariables);
  
  % get xpj predictions
  if ~isa(model,'function_handle')
    x_plus_j_pred = model.apply(X_plus_j);
  else
    x_plus_j_pred = model(X_plus_j);
  end
  %clear X_plus_j;
  switch modeltype
    case 'regression'
      x_plus_j_preds = x_plus_j_pred.(field){end};
    case 'decomposition'
      x_plus_j_preds = x_plus_j_pred.(field);
    case 'classification'
      x_plus_j_preds = x_plus_j_pred.classification.probability;
    case 'function'
      x_plus_j_preds = x_plus_j_pred;
  end
  %clear x_plus_j_pred;
  
  % get xmj predictions
  if ~isa(model,'function_handle')
    x_minus_j_pred = model.apply(X_minus_j);
  else
    x_minus_j_pred = model(X_minus_j);
  end
  %clear X_minus_j;
  switch modeltype
    case 'regression'
      x_minus_j_preds = x_minus_j_pred.(field){end};
    case 'decomposition'
      x_minus_j_preds = x_minus_j_pred.(field);
    case 'classification'
      x_minus_j_preds = x_minus_j_pred.classification.probability;
    case 'function'
      x_minus_j_preds = x_minus_j_pred;
  end
  %clear x_minus_j_pred;

  % Marginal contributions for all X perturbations
  marginalcontributions_thisbatch = x_plus_j_preds - x_minus_j_preds;
  %clear x_plus_j_preds  x_minus_j_preds;
  
  % start to calculate shapley values
  start = 1;
  samples = cell(size(thisbatch,1)*nvariables,1);
  for i=1:size(samples,1)
    finish = start+niter-1;
    samples{i} = start:finish;
    start = finish+1;
  end
  samples = reshape(samples',nvariables,size(thisbatch,1))';
  if noutputs==1
    for n=1:size(thisbatch,1)
      %SCOTT: Can this be vectorized.
      for z=1:nvariables
        shap(find(expincludedsamples==batchinds{k}(n)),z) = mean(marginalcontributions_thisbatch(samples{n,z}));
        %shapvar(find(expincludedsamples==batchinds{k}(n)),z) = var(marginalcontributions_thisbatch(samples{n,z}));
        allmymarginalcontributions{z} =  [allmymarginalcontributions{z}; marginalcontributions_thisbatch(samples{n,z})];
      end
    end
  elseif noutputs > 1
    for n=1:size(thisbatch,1)
      s = samples(n,:);
      %SCOTT: Can this be vectorized.
      for z=1:nvariables
          shap(find(expincludedsamples==batchinds{k}(n)),z,:) = mean(marginalcontributions_thisbatch(s{z},:));
          %shapvar(find(expincludedsamples==batchinds{k}(n)),z,:) = var(marginalcontributions_thisbatch(s{z},:));
          allmymarginalcontributions{z} =  [allmymarginalcontributions{z}; marginalcontributions_thisbatch(s{z},:)];
      end
    end
  end

  if ishandle(wb)
    updatewaitbar(wb,k,nbatches,startat,'Generating Shapley Values. Please wait...(close to cancel)');
  else
    error('Aborted by user.')
  end
  %allmymarginalcontributions = [allmymarginalcontributions marginalcontributions_thisbatch];
end

% correct the shapley values to equal the predictions of the explanation
% samples using ridge regression
total = arrayfun(@(x) var(allmymarginalcontributions{x}),1:nvariables,'UniformOutput',false);
total = cat(1,total{:})';
switch noutputs
  case 1
    for i=1:size(shap,1)
      sumerror = explainpred(i,:) - base_prediction - sum(shap(i,:),2);
      shapvar(i,:) = total;
      if all(shapvar(i,:)<1e-3)
        shapvar(i,:) = shapvar(i,:).*10^(min(floor(abs(log10(shapvar(i,:))))));
      end
      v = (shapvar(i,:)./max(shapvar(i,:),2)) * 1e6;
      adj = sumerror * (v - (v * sum(v)) / (1 + sum(v)));
      shap(i,:) = shap(i,:) + adj;
    end
  otherwise
    for i=1:size(shap,1)
      for j=1:size(shap,3)
        sumerror = explainpred(i,j) - base_prediction(j) - sum(shap(i,:,j),2);
        shapvar(i,:,j) = total(j,:);
        if all(shapvar(i,:,j)<1e-3)
          shapvar(i,:,j) = shapvar(i,:,j).*10^(min(floor(abs(log10(shapvar(i,:,j))))));
        end
        v = (shapvar(i,:,j)./max(shapvar(i,:,j),2)) * 1e6;
        adj = sumerror * (v - (v * sum(v)) / (1 + sum(v)));
        shap(i,:,j) = shap(i,:,j) + adj;
      end
    end
end

if ishandle(wb)
  close(wb);
end

% reset back to default
rng('default')

results.shap = shap;
results.explainpred = explainpred;
results.baseprediction = base_prediction;
results.vargroups = variablegroupings;
results.calx = caldata;
results.x = expdata;
results.shapoptions = options;
end
%--------------------------------------------------------------------------

function [caldata,expdata,model,options] = parsevarargin(varargin)
caldata = [];
expdata = [];
model = [];
options = [];

varargin =  varargin{1};

switch length(varargin)
  % explain all samples from the calibration dataset
  case 3
    % (x,model,options)
    if isnumeric(varargin{1}) || isdataset(varargin{1})
      caldata = varargin{1};
      if ~isdataset(caldata)
        caldata = dataset(caldata);
      end
      expdata = caldata;
    else
      error('Expecting numeric type for calibration data')
    end
    % model, can be evrimodel or function handle
    if ismodel(varargin{2})
      model = varargin{2};
      % TODO: handle modelselector models here.
    elseif isa(varargin{2},'function_handle')
      model = varargin{2};
    else
      error('Unsupported type for model. Expecting EVRIMODEL or function handle')
    end
    if isstruct(varargin{3})
      options = varargin{3};
    else
      error('Expecting structure for options');
    end
  case 4
    % (calx,expx,model,options)
    if isnumeric(varargin{1}) || isdataset(varargin{1})
      caldata = varargin{1};
      if ~isdataset(caldata)
        caldata = dataset(caldata);
      end
    else
      error('Expecting numeric type for calibration data')
    end
    if isnumeric(varargin{2}) || isdataset(varargin{2})
      expdata = varargin{2};
      if ~isdataset(expdata)
        expdata = dataset(expdata);
      end
    else
      error('Expecting numeric type for explanation data')
    end

    % model, can be evrimodel or function handle
    if ismodel(varargin{3})
      model = varargin{3};
      % TODO: handle modelselector models here.
    elseif isa(varargin{3},'function_handle')
      model = varargin{3};
    else
      error('Unsupported type for model. Expecting EVRIMODEL or function handle')
    end
    if isstruct(varargin{4})
      options = varargin{4};
    else
      error('Expecting structure for options');
    end
  otherwise
    error('Need 3 or 4 inputs')
end


end
%----------------------------------------------------------------------

function [modeltype] = getmodeltype(model)
% Set the model type for the object
%TODO: can we make this better by using fields of a model?
regression = {'ANN'...
  'ANNDL'...
  'CLS'...
  'LWR'...
  'MLR'...
  'PCR'...
  'PLS'...
  'SVM'...
  'XGB',...
  'NPLS',...
  'ENSEMBLE'};
classification = {'ANNDA'...
  'ANNDLDA'...
  'KNN'...
  'LREGDA'...
  'PLSDA'...
  'SIMCA',...
  'SVMDA'...
  'XGBDA',...
  'LDA'};
decomposition = {'MCR'...
  'PARAFAC'...
  'PCA'...
  'UMAP'};
if isa(model,'function_handle')
  modeltype = 'function';
elseif ismember(model.modeltype,regression)
  modeltype = 'regression';
elseif ismember(model.modeltype,classification)
  modeltype = 'classification';
elseif ismember(model.modeltype,decomposition)
  modeltype = 'decomposition';

else
  error(['Unsupported modeltype ' model.modeltype])
end
end
%----------------------------------------------------------------------

function [niter,nbatches,minsamplespervar,bad] = dividework(niter,nbatches,nsamples,nvariables,int_width)
% divide up the calculations for shapley
% higher values of niter give us better accuracy but is more of a memory
% hog
%
bad = 0;

% find a thres here to create an optimal number of batches

minsamplespervar = floor((nvariables/int_width * 2) + 1);
if ischar(niter)
  niter = minsamplespervar; %* 2; % total for both rounds 1 and 2
end
maxperbatch = nvariables * niter; %1000000;%300000;   % nsamplesinbatch * nvariables * niter
if ischar(nbatches)
  nbatches = ceil(((niter*nsamples*nvariables)/maxperbatch)*0.5);
end

if nbatches > nsamples
  evrierrordlg(['Shapley Values computation will require too much memory to proceed. '...
    'Please consider subsampling or select a number of iterations that is lower than ' num2str(niter) ' to limit memory cost.'])
  bad = 1;
  return
end
end
%----------------------------------------------------------------------

function est = updatewaitbar(hh, i, tot, startat,msg)
fractelapsed = i/tot;
fractremain = 1-fractelapsed;
est = round(((now-startat)*24*60*60*(fractremain/fractelapsed)));

%update waitbar
if ishandle(hh)
  if ~ishandle(hh)
    error('aborted by user');
  end
  if isfinite(est)
    timestr = besttime(est);
  else
    timestr = '-';
  end
  set(hh,'name',['Est. Time Remaining: ' timestr]);
else
  error('Shapley Value calculation aborted by user');
end
waitbar(fractelapsed,hh,[msg newline num2str(i) '/' num2str(tot) ' batches completed.'])

end

