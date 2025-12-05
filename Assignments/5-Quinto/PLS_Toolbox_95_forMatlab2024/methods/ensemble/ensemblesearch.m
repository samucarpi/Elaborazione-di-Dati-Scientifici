function [results] = ensemblesearch(varargin)
%ENSEMBLESEARCH Search for optimal ensemble using nchoosek method.
% Finds the best ensemble from the provided child models. The algorithm
% uses an nchoosek approach to create and test the performance of every
% combination of ensembles from size mink to maxk. Ensemble ambiguities are
% also calculated for each ensemble, which is a measure of diversity within
% an ensemble. It is recommended to pick the ensemble with the lowest
% error, minimal overfitting, and high diversity.
%
% INPUTS:
%        models = cell array of models for ensemble,
%          mink = minimum size of an ensemble,
%          maxk = maximum size of an ensemble,
%   aggregation = mode of aggregation to use when fusing predictions.
%                 'mean' and 'median' are supported.
%
% OUTPUTS:
%        results    = struct of results from the search with the following
%                  fields:
%         .bestmodel            = ensemble with the minimum error from the
%                                 search,
%         .bestchildindices = vector of indices indicating which of the
%                                 provided models are used in the .bestmodel 
%                                 ensemble object.
%         .dso                  = dataset object of results from the
%                                 search.
%         .booldso              = boolean dataset object of child presence
%                                 in each ensemble in the search.
%
%I/O: results = ensemblesearch(models,mink,maxk,aggregation);
%
%See also: ENSEMBLE AGGREGATEPREDICTIONS COMPUTEJACKKNIFE

% Copyright © Eigenvector Research, Inc. 2024
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

results = [];
[x,y,models,mink,maxk,aggregation,predictmode] = parsevarargin(varargin);
checkthemodels(models,'fusion');
func = str2func(aggregation);
modelinds = 1:length(models);
ks = mink:maxk;
% generate combinations with zero padding
combosperk = arrayfun(@(X) nchoosek(length(modelinds),X),mink:maxk);
ncombos = sum(arrayfun(@(X) nchoosek(length(modelinds),X),mink:maxk));
combos = zeros(ncombos,maxk);
start = 1;
for i=1:length(ks)
  finish = start + combosperk(i)-1;
  combos(start:finish,1:ks(i)) = nchoosek(modelinds,ks(i));
  start = finish+1;
end

disp(['Testing ' num2str(size(combos,1)) ' possible combinations of ensembles'])
if ~predictmode
  calpredictions = cell2mat(cellfun(@(x) x.pred{2},models,'uni',0));
  predictions = cellfun(@(x) size(x.pred{2},1),models);
  predictions = unique(predictions);
  if length(predictions)~=1
    error('inconsistent number of predictions for models')
  end
  candocvpred = ~any(cellfun(@(x) isempty(x.detail.cvpred),models));
  if candocvpred
    preds = nan(predictions,length(models));
    % use crossvalidation predictions
    for i=1:length(models)
      switch ndims(models{i}.detail.cvpred)
        case 2
          preds(:,i) = models{i}.detail.cvpred;
        case 3
          preds(:,i) = squeeze(models{i}.detail.cvpred(:,:,models{i}.ncomp));
      end
    end
  end
  modelrmsecs = nan(length(models),1);
  for i=1:length(models)
    try
      modelrmsecs(i) = models{i}.detail.rmsec(models{i}.ncomp);
    catch
      modelrmsecs(i) = models{i}.detail.rmsec;
    end
  end
  ensemblermsecs = nan(size(combos,1),1);
  for i=1:size(combos,1)
    ensemblermsecs(i) = func(modelrmsecs(nonzeros(combos(i,:))));
  end
  % repeat for cvpreds...
  if candocvpred
    modelrmsecvs = nan(length(models),1);
    for i=1:length(models)
      try
        modelrmsecvs(i) = models{i}.detail.rmsecv(models{i}.ncomp);
      catch
        modelrmsecvs(i) = models{i}.detail.rmsecv;
      end
    end
    ensemblermsecvs = nan(size(combos,1),1);
    for i=1:size(combos,1)
      ensemblermsecvs(i) = func(modelrmsecvs(nonzeros(combos(i,:))));
    end
  end
else
  % generate predictions for each of the models
  preds = nan(size(x,1),length(models));
  for i=1:length(models)
    temp = models{i}.apply(x);
    preds(:,i) = temp.pred{2};
  end
end

% generate errors for each of the combinations
func = str2func(aggregation);
if ~predictmode
  y = models{1}.detail.data{2}.data(models{1}.detail.includ{1,1},models{1}.detail.include{2,2});
  calpredictionerror = arrayfun(@(x) rmse(y,func(calpredictions(models{1}.detail.includ{1,1},nonzeros(combos(x,:))),2)),1:size(combos,1))';
  calambiguities = ensemblermsecs - calpredictionerror;
  if candocvpred
    predictionerror = arrayfun(@(x) rmse(y,func(preds(models{1}.detail.includ{1,1},nonzeros(combos(x,:))),2)),1:size(combos,1))';
    cvambiguities = ensemblermsecvs - predictionerror;
  else
    % overwrite prediction error
    predictionerror = calpredictionerror;
  end
else
  predictionerror = arrayfun(@(x) rmse(y,func(preds(models{1}.detail.includ{1,1},nonzeros(combos(x,:))),2)),1:size(combos,1))';
end

% output model with best prediction error
[minerror,bestensemble] = min(predictionerror);
o = ensemble('options');
o.aggregation = aggregation;
model = evrimodel('ensemble');
model.models = models(nonzeros(combos(bestensemble,:)));
model.options = o;
model = model.calibrate;
if predictmode
  if isempty(y)
    model = model.apply(x);
  else
    model = model.apply(x,y);
  end
end
% build dataset objects of results
if ~predictmode
  % predictions are cvpredictions, and there's also calpredictions
  % first get rmsec
  if candocvpred
    rmseccandidates = arrayfun(@(x) rmse(y,calpredictions(models{1}.detail.includ{1,1},x)),1:length(models))';
    rmsecvcandidates = arrayfun(@(x) rmse(y,preds(models{1}.detail.includ{1,1},x)),1:length(models))';
    candidatecalambiguity = zeros(length(models),1);
    candidatecvambiguity = zeros(length(models),1);
    allrmsecs = [rmseccandidates; calpredictionerror];
    allrmsecvs = [rmsecvcandidates; predictionerror];
    alloverfits = [(rmsecvcandidates./rmseccandidates); (predictionerror./calpredictionerror)];
    allcalambiguities = [candidatecalambiguity; calambiguities];
    allcvambiguities = [candidatecvambiguity; cvambiguities];
    dso = dataset([allrmsecs allrmsecvs alloverfits allcalambiguities allcvambiguities]);
    %dso = dataset([allrmsecs allrmsecvs alloverfits]);
    newcombos = combos;
    emptys = find(combos==0);
    newcombos(emptys) = inf;
    dso.label{1} = char([strcat(string(split(num2str(1:length(models)))), repmat("_",length(models),1));...
      erase(string(cell2str(cellfun(@(x) [x '_'],arrayfun(@num2str,newcombos,'UniformOutput',false),'UniformOutput',false))),'Inf_')]);
    dso.label{2} = {'RMSEC' 'RMSECV' 'Overfit' 'Calibration Ambiguity' 'Cross-Validation Ambiguity'};
    %dso.label{2} = {'RMSEC' 'RMSECV' 'Overfit'};
    ensembleclasses = [repmat({'Child Models'},1,length(models)) repmat({['Ensemble: ' aggregation]},1,size(combos,1))];
    dso.class{1,1} = ensembleclasses;
    dso.classname{1,1} = 'Ensemble Groups';
    themodels = (1:length(models))';
    tsf = zeros(1,maxk);
    tsf(1) = 1;
    individualmodels = themodels*tsf;
    allcombos = [individualmodels; combos];
    toplot = {{2 3} {2 5}};
    rows = 2;
  else
    rmseccandidates = arrayfun(@(x) rmse(y,calpredictions(models{1}.detail.includ{1,1},x)),1:length(models))';
    candidatecalambiguity = zeros(length(models),1);
    allrmsecs = [rmseccandidates; calpredictionerror];
    allcalambiguities = [candidatecalambiguity; calambiguities];
    dso = dataset([allrmsecs allcalambiguities]);
    newcombos = combos;
    emptys = find(combos==0);
    newcombos(emptys) = inf;
    dso.label{1} = char([strcat(string(split(num2str(1:length(models)))), repmat("_",length(models),1));...
      erase(string(cell2str(cellfun(@(x) [x '_'],arrayfun(@num2str,newcombos,'UniformOutput',false),'UniformOutput',false))),'Inf_')]);
    dso.label{2} = {'RMSEC' 'Calibration Ambiguity'};
    %dso.label{2} = {'RMSEC' 'RMSECV' 'Overfit'};
    ensembleclasses = [repmat({'Child Models'},1,length(models)) repmat({['Ensemble: ' aggregation]},1,size(combos,1))];
    dso.class{1,1} = ensembleclasses;
    dso.classname{1,1} = 'Ensemble Groups';
    themodels = (1:length(models))';
    tsf = zeros(1,maxk);
    tsf(1) = 1;
    individualmodels = themodels*tsf;
    allcombos = [individualmodels; combos];
    toplot = {{1 2}};
    rows = 1;
  end
  
  % add number of models in ensemble as axisscale
  dso.axisscale{1} = sum(logical(allcombos),2);
  dso.axisscalename{1} = 'Number of Models in Ensemble';
  % automatically create class sets for each of the models
  for i=1:length(models)
    % find models where i is present
    [present,~] = find(allcombos==i); %arrayfun(@(x1) any(contains(dso.label{1}(x1,:),[num2str(i) '_'])),1:size(dso,1));
    notpresent = setdiff(1:size(allcombos,1),present)';
    labels = cell(size(dso,1),1);
    [labels(present)] = {['Model ' num2str(i) ' present']};
    [labels(notpresent)] = {['Model ' num2str(i) ' not present']};
    dso.classid{1,i+1} = labels';
    dso.classname{1,i+1} = ['Model ' num2str(i) ' presence'];
  end
else
  
end

fighandle = figure;

subplot(rows,1,1);
axs = cell(rows,1);
for plotind = 1:rows
  %add plots as needed storing plot to display in each axes
  if ~ishandle(fighandle); return; end   %figure closed? exit now
  axs{plotind} = subplot(rows,1,plotind);
  plotgui(dso,'axismenuvalues',toplot{plotind});
end
plotgui('update','viewclasses',1);
linkaxes([axs{:}],'x')


booldata = zeros(size(dso,1),length(models));
for i=1:size(booldata,1)
  these = str2double(split(strtrim(dso.label{1}(i,:)),'_'))';
  these = these(~isnan(these));
  booldata(i,these) = 1;
end
booldso = copydsfields(dso,dataset(booldata),1);
booldso.label{2} = cell2str(split(num2str(1:length(models))));

results.bestmodel = model;
results.bestchildindices = nonzeros(combos(bestensemble,:));
results.dso = dso;
results.booldso = booldso;
end


function [x,y,models,mink,maxk,aggregation,predictmode] = parsevarargin(varargin)
% ensemblesearch(models,mink,maxk,aggregation);
% ensemblesearch(x,models,mink,maxk,aggregation);
% ensemblesearch(x,y,models,mink,maxk,aggregation);
x = [];
y = [];
models = [];
mink = [];
maxk = [];
aggregation = [];
predictmode = 0;
varargin = varargin{1};
switch length(varargin)
  case 4
    % ensemblesearch(models,mink,maxk,aggregation);

    % checking model
    if iscell(varargin{1})
      if all(cellfun(@ismodel,varargin{1}))
        models = varargin{1};
      else
        error('At least 1 element in cell array is not an evrimodel. Please check that all elements are evrimodels.')
      end
    else
      error('Expecting cell array of models as first input when calling ensemble with 4 arguments.')
    end

    % check mink
    if ~isscalar(varargin{2})
      error('Expecting scalar for minimum k as second input when calling ensemblesearch with 4 arguments.')
    else
      mink = varargin{2};
    end
    
    % check maxk
    if ~isscalar(varargin{3})
      error('Expecting scalar for maximum k as third input when calling ensemblesearch with 4 arguments.')
    else
      maxk = varargin{3};
    end
    
    % check aggregation
    if ~ischar(varargin{4})
      error('Expecting char for aggregation as fourth input when calling ensemblesearch with 4 arguments.')
    else
      aggregation = varargin{4};
      if ~ismember(aggregation,{'mean' 'median'})
        error('Unsupported aggregation for ensemblesearch')
      end
    end

  case 5
    % ensemblesearch(x,models,mink,maxk,aggregation);
    predictmode = 1;
    
    %checking x
    if isdataset(varargin{1}) | isnumeric(varargin{1})
      x = varargin{1};
    else
      error('Expecting Xblock as first argument when calling ensemble with 3 arguments.')
    end

    % checking model
    if iscell(varargin{2})
      if all(cellfun(@ismodel,varargin{2}))
        models = varargin{2};
      else
        error('At least 1 element in cell array is not an evrimodel. Please check that all elements are evrimodels.')
      end
    else
      error('Expecting cell array of models as second input when calling ensemble with 5 arguments.')
    end

    % check mink
    if ~isscalar(varargin{3})
      error('Expecting scalar for minimum k as third input when calling ensemblesearch with 5 arguments.')
    else
      mink = varargin{3};
    end
    
    % check maxk
    if ~isscalar(varargin{4})
      error('Expecting scalar for maximum k as fourth input when calling ensemblesearch with 5 arguments.')
    else
      maxk = varargin{4};
    end
    
    % check aggregation
    if ~ischar(varargin{5})
      error('Expecting char for aggregation as fifth input when calling ensemblesearch with 5 arguments.')
    else
      aggregation = varargin{5};
    end

  case 6
    % ensemblesearch(x,y,models,mink,maxk,aggregation);
    predictmode = 1;

    %checking x
    if isdataset(varargin{1}) | isnumeric(varargin{1})
      x = varargin{1};
    else
      error('Expecting Xblock as first argument when calling ensemblesearch with 6 arguments.')
    end

    %checking y
    if isdataset(varargin{2}) | isnumeric(varargin{2})
      y = varargin{2};
    else
      error('Expecting Yblock as second argument when calling ensemblesearch with 6 arguments.')
    end

    % checking model
    if iscell(varargin{3})
      if all(cellfun(@ismodel,varargin{3}))
        models = varargin{3};
      else
        error('At least 1 element in cell array is not an evrimodel. Please check that all elements are evrimodels.')
      end
    else
      error('Expecting cell array of models as third input when calling ensemble with 6 arguments.')
    end

    % check mink
    if ~isscalar(varargin{4})
      error('Expecting scalar for minimum k as fourth input when calling ensemblesearch with 6 arguments.')
    else
      mink = varargin{4};
    end
    
    % check maxk
    if ~isscalar(varargin{5})
      error('Expecting scalar for maximum k as fifth input when calling ensemblesearch with 6 arguments.')
    else
      maxk = varargin{5};
    end
    
    % check aggregation
    if ~ischar(varargin{6})
      error('Expecting char for aggregation as sizth input when calling ensemblesearch with 6 arguments.')
    else
      aggregation = varargin{6};
    end

  otherwise
    error('Unrecognized input to ensemble.')
end

% check magnitude of mink and maxk
if mink<0 || mink > length(models)
  error(['Min k must be positive and less than ' num2str(length(models))])
end
if maxk<0 || maxk <= mink || maxk > length(models)
  error(['Max k must be positive, less than or equal to ' num2str(length(models)) ', and larger than ' num2str(mink) '.'])
end

% check models
nmodels = length(models);
if prod(size(models))~=nmodels || size(models,1)>1
  error('Expecting a row vector of models')
end
end