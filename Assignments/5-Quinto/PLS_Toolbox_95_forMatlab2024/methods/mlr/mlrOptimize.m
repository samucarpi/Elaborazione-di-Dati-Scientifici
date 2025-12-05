function [model] = mlrOptimize(xsub,x,ysub,y,options,preprocessing,model)
%MLROPTIMIZE  Search over parameter ranges to perform CV
%   The calculated CV quantity is root mean squared error. If
%   regularization is used, looping over penalties is done and a regression
%   vector is calculated for each penalty. Predictions are made to monitor
%   which penalty was used to generate the lowest RMSECV. Then that penalty
%   (and its corresponding regression vector) is used in the model object
%   for further CV (if provided) and model application. The best penalty or
%   penalties will be stored directly in the model object under:
%       model.detail.mlr.best_params.optimized_ridge
%       model.detail.mlr.best_params.optimized_lasso
%   and then the evrimodel object is returned.
%  INPUTS:
%         xsub          = X-block, included samples.
%         x             = X-block, all samples.
%         ysub          = Y-block, included samples.
%         y             = Y-block, all samples.
%         options       = Struct denoting useroptions from mlr.
%         preprocessing = Cells extracted from options.preprocessing.
%         model         = Evrimodel object to be populated further.
%
%
% The parameter optimization uses a parfor loop which takes advantage of
% the Parallel Computating Toolbox (PCT) if available. In that case the 
% initevripct function is called to start the PCT parpool of workers and to
% handle their synchronized access to the matlabprefs.mat file.
% If the PCT is not available then the parfor loop behaves like a for loop.
%
%I/O: model = mlrOptimize(xsub,x,ysub,y,options,preprocessing,model;

%Copyright Eigenvector Research, Inc. 2022
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

% when using regularization, the corresponding penalty terms need to be
% nonzero. i.e. if options.algorithm is 'ridge' and options.ridge is 0,
% then it should be doing normal MLR.
% the values should also be nonempty when using regularization

% check for ridge case
if strcmpi(options.algorithm,'optimized_ridge')
  if length(options.optimized_ridge)==1 && options.optimized_ridge==0
    evritip('ridge_switch_0','Algorithm was set to ''optimized_ridge'' with the penalty set to 0. Switching to MLR with no regularization.',0);
    % switch to normal MLR
    options.algorithm = 'leastsquares';
  elseif isempty(options.optimized_ridge)
    evritip('ridge_switch_empty','Algorithm was set to ''optimized_ridge'' with no penalty or penalties provided. Switching to MLR with no regularization.',0);
    % switch to normal MLR
    options.algorithm = 'leastsquares';
  end
  
elseif strcmpi(options.algorithm,'optimized_lasso')
  if length(options.optimized_lasso)==1 && options.optimized_lasso==0
    evritip('lasso_switch_0','Algorithm was set to ''optimized_lasso'' with the penalty set to 0. Switching to MLR with no regularization.',0);
    % switch to normal MLR
    options.algorithm = 'leastsquares';
  elseif isempty(options.optimized_lasso)
    evritip('lasso_switch_empty','Algorithm was set to ''optimized_lasso'' with no penalty or penalties provided. Switching to MLR with no regularization.',0);
    % switch to normal MLR
    options.algorithm = 'leastsquares';
  end
elseif strcmpi(options.algorithm,'elasticnet')
  if sum(options.optimized_lasso)==0 && sum(options.optimized_ridge)==0 && length(options.optimized_ridge)==1 && length(options.optimized_lasso)==1
    evritip('elasticnet_switch_0','Algorithm was set to ''elasticnet'' with both optimizing penalties set to 0. Switching to MLR with no regularization.',0);
    % switch to normal MLR
    options.algorithm = 'leastsquares';
  elseif isempty(options.optimized_ridge) || isempty(options.optimized_lasso)
    evritip('elasticnet_switch_empty','Algorithm was set to ''elasticnet'' with either no ridge or no lasso penalty values provided. Switching to MLR with no regularization.',0);
    % switch to normal MLR
    options.algorithm = 'leastsquares';
  end
end

% get crossvalidation options, used to do small random subset CV to find
% best penalties
if ~isempty(options.cvi)
  cvopts = crossval('options');
  cvopts.preprocessing = 0;
  cvopts.waitbartrigger = inf;
else
  cvopts = [];
end

[reg_vectors,theta,condnum,ncomp,cvresults,cvopts_cell] = fit(xsub,x,ysub,y,options,cvopts);


% rank the models and set model properties, return model with best
% penalties
[model] = rank_models(x,y,reg_vectors,theta,condnum,ncomp,cvresults,cvopts_cell,options,preprocessing,model);

end
%--------------------------end of mlrOptimize------------------------------
function [reg_vectors,theta,condnum,condncomp,cvresults,cvopts_cell] = fit(xsub,x,ysub,y,options,cvopts)
%INPUTS:
% xsub       = included xblock samples
% x          = all xblock samples
% ysub       = included yblock samples
% y          = all yblock samples
% options    = mlr useroptions
% cvopts     = crossvalidation options
%OUTPUTS:
% reg_vectors = cell of regression vectors for each corresponding penalty
% theta       = theta used in ridge (only for ridge or ridge_hkb, empty otherwise)
% condnum     = condition number
% condncomp   = number of variables used
% cvresults   = output struct from crossvalidation
% cvopts_cell = the crossvalidation options for each penalty

cvresults = {};
cvopts_cell = {};

% parse algorithm
switch options.algorithm
  case {'leastsquares' 'ridge' 'ridge_hkb'}
    % no regularization so no looping is done, should just get one
    % regression vector
    [reg_vectors{1}, theta, condnum, condncomp] = mlrengine(xsub,ysub,options);
    
  case {'optimized_ridge' 'optimized_lasso' 'elasticnet'}
    theta = [];
    condnum = [];
    condncomp = [];
    % start PCT
    hasgcp = initevripct;

    % looping is involved in finding the best penalties, create array for
    % all regression vectors to be evaluated later
   
    reg_vectors = {};
    if ~isempty(options.cvi)
      % need the total number of cross validation models to be made,
      % depending on the number of penalties
      switch options.algorithm
        case 'optimized_ridge'
          n = length(options.optimized_ridge);
        case 'optimized_lasso'
          n = length(options.optimized_lasso);
        case 'elasticnet'
          n = length(options.optimized_ridge)*length(options.optimized_lasso);
      end
      cvopts_cell = repstructs(cvopts,n);
    end

    % we do want a waitbar in this case since we are optimizing the penalty
    % value

    starttime = now;

    if checkmlversion('>','9.1')
      % Matlab ver. 9.2 or later can use PCT's DataQueue. (9.2 is R2017a)
      matlab92plus = true;    
    else
      matlab92plus = false;
    end

    % set up parfor progress monitor
    nProgressStepSize = ceil(n/10);
    D = [];
    if hasgcp
      if matlab92plus       % Can use DataQueue?
        h = waitbar(0, 'Performing Penalty Optimization...');
        h.UserData = [0 n];
        D = parallel.pool.DataQueue;
        afterEach(D,@(varargin) updatepctwaitbar(h));
      end
    else
      % no PCT R2017a or later. Use standard waitbar
      h = waitbar(0,'Performing Penalty Optimization... (Close to cancel)');
      D = [];
      set(h,'name','MLR Optimization');
    end

    if strcmpi(options.algorithm,'elasticnet')
      % loop over all the penalty values for elasticnet regression
      % here, we need to get all possible pairings between the range of
      % ridge values and the range of lasso values
      penalties{1,1} = options.optimized_ridge;
      penalties{1,2} = options.optimized_lasso;
      % column 1 in penalty_combinations will be replicates of ridge,
      % column 2 will be lasso

      penalty_combinations = cell(1,numel(penalties));
      [penalty_combinations{:}] = ndgrid(penalties{:});
      penalty_combinations = cellfun(@(X) reshape(X,[],1),penalty_combinations,'UniformOutput',false);
      penalty_combinations = horzcat(penalty_combinations{:});
    else
      penalty_combinations = [];
    end

    % main loop for all algorithms using penalties
    parfor i=1:n

      if hasgcp
        if matlab92plus
          send(D, i);
        end
      else
        % No PCT, so standard waitbar. Note parfor iterates decreasing
        if ~isempty(h) % ((now-lastupdate)*60*60*24)>.5  (not in parfor!)
          %show progress bar
          elap = (now-starttime)*60*60*24;
          i2 = n -i + 1; % account for parfor index runs in reverse
          est = round(elap*(n-i2)/i2);
          drawnow;
          if ~ishandle(h)
            error('Model optimization aborted by user');
          end
          waitbar(i2./n,h);
          if elap>3
            set(h,'name',['Est. Completion Time ' besttime(est)]);
          end
        end
      end


      opts = options;
      switch options.algorithm
        case 'optimized_ridge'
          opts.optimized_ridge = options.optimized_ridge(i);
        case 'optimized_lasso'
          opts.optimized_lasso = options.optimized_lasso(i);
        case 'elasticnet'
          opts.optimized_ridge = penalty_combinations(i,1);
          opts.optimized_lasso = penalty_combinations(i,2);
      end
      reg_vectors{i} = mlrengine(xsub,ysub,opts);
      if ~isempty(opts.cvi)
        cvopts_cell{i}.rmoptions = opts;
        cvresults{i} = crossval(x,y,'mlr',options.cvi,[],cvopts_cell{i});
      end
    end

    if ishandle(h)
      delete(h);
    end
    
  otherwise
    error('Unsupported algorithm. Choose one of: none, ridge, lasso, or elasticnet.')
end

  function updatepctwaitbar(wb)
    if ~ishandle(wb)
      error('aborted by user');
    end
    ud = wb.UserData;
    ud(1) = ud(1) + 1;
    waitbar(ud(1) / ud(2), wb);
    wb.UserData = ud;
  end

end
%--------------------------------------------------------------------------
function [model] = rank_models(x,y,reg_vectors,theta,condnum,condncomp,cvresults,cvopts_cell,options,preprocessing,model)
%INPUTS:
% x                = all xblock samples
% y                = all yblock samples
% reg_vectors      = cell of regression vectors for each corresponding penalty
% cvresults        = output struct from crossvalidation
% theta            = theta used in ridge (only for ridge or ridge_hkb, empty otherwise)
% condnum          = condition number
% condncomp        = number of variables used
% cvopts_cell      = the crossvalidation options for each penalty
% options          = mlr useroptions
% preprocessing    = preprocessing specified from options
%OUTPUTS:
% model            = evrimodel object to be populated with best parameters and regression vector.


% get unpreprocessed yblock with included variables
myy = y.data(:,y.include{2});
if ~isempty(preprocessing{2})
  myy = preprocess('undo',preprocessing{2},myy);
else
  myy = dataset(myy);
end

if isempty(cvresults)
  % no cross-validation done, make predictions and get rmsec to come up
  % with best penalites
  switch options.algorithm
    case {'leastsquares' 'ridge' 'ridge_hkb'}
      predictions{1} = x.data(:,x.includ{2})*reg_vectors{1};
      rmses{1} = rmse(predictions{1},myy.data);
    case {'optimized_ridge' 'optimized_lasso' 'optimized_elasticnet'}
      predictions = cell(size(reg_vectors));
      rmses = cell(size(reg_vectors));
      for j=1:length(reg_vectors)
        % make predictions with the regression vectors
        predictions{j} = x.data(:,x.include{2})*reg_vectors{j};
        % undo preprocessing if there
        if ~isempty(preprocessing{2})
          predictions{j} = preprocess('undo',preprocessing{2},predictions{j});
        else
          predictions{j} = dataset(predictions{j});
        end
        % evaluate prediction
        rmses{j} = rmse(predictions{j}.data,myy.data);
      end
  end

else
  % cross-validation done, use rmsecv to rank models and their penalties
  rmses = cellfun(@(x) x.rmsecv, cvresults,'UniformOutput',false);
  predictions = cellfun(@(x) x.cvpred, cvresults,'UniformOutput',false);
end
% then we need to evaluate to see which was the best one.
% need to condition this on the number of variables in rmse
if ~strcmpi(options.algorithm,'leastsquares')
  if isequal(size(rmses{1}), [1 1])
    [~, idx] = sortrows(rmses', 1, 'ascend');
    [~, rankings] = sort(idx);
  else
    % need to evaluate all the rmse values into 1 to rank the multivariate
    % output
    % take myy and autoscale
    msg = ['The Y-Block was found to be multivariate. This results in multiple rmse values for each variable in Y. '...
      'Therefore, a scaling approach is taken to account for each of these rmse values in order to compute the best model.'];
    evritip('multivariate_y_rank',msg,1);
    [cal_y_dso, cal_y_mean, cal_y_std] = auto(myy);
    cal_y_auto = cal_y_dso.data;
    performance = nan(size(rmses));
    for i=1:length(predictions)
      % scale the predictions using means and stds from myy
      scaled_predictions = scale(predictions{i},cal_y_mean,cal_y_std);
      % take difference, unravel into row vector, and take rmse
      performance(i) = rmse(reshape(scaled_predictions-cal_y_auto,1,[]));
    end
    % now we can rank the multivariate output using performance
    [~, idx] = sortrows(performance', 1, 'ascend');
    [~, rankings] = sort(idx);
  end
end

% populate model object with the correct content:
%   model.detail.mlr.best_params.optimized_ridge
%   model.detail.mlr.best_params.optimized_lasso
%   model.detail.mlr.ridge_theta
%   model.detail.mlr.ridge_hkb_theta
%   model.detail.mlr.optimized_ridge_theta
%   model.detail.mlr.optimized_lasso_theta

switch options.algorithm
  case {'leastsquares' 'ridge' 'ridge_hkb'}
    % leave the best ridge and lasso penalties empty
    model.reg = reg_vectors{1};
    model.detail.mlr.condmax_value = condnum;
    model.detail.mlr.condmax_ncomp = condncomp;
    switch options.algorithm
      case 'ridge'
        model.detail.mlr.ridge_theta = theta;
      case 'ridge_hkb'
        model.detail.mlr.ridge_hkb_theta = theta;
    end
  case {'optimized_ridge' 'optimized_lasso' 'elasticnet'}
    % get best model and its hyperparameters decided by the ranking
    bestmod = find(rankings==1);
    model.reg = reg_vectors{bestmod};
    switch options.algorithm
      case 'optimized_ridge'
        % populate best ridge penalty
        model.detail.mlr.best_params.optimized_ridge = options.optimized_ridge(bestmod);
        model.detail.mlr.optimized_ridge_theta = options.optimized_ridge;
      case 'optimized_lasso'
        % populate best lasso penalty
        model.detail.mlr.best_params.optimized_lasso = options.optimized_lasso(bestmod);
        model.detail.mlr.optimized_lasso_theta = options.optimized_lasso;
      case 'elasticnet'
        % populate best ridge and lasso penalty
        model.detail.mlr.best_params.optimized_ridge = cvopts_cell{bestmod}.rmoptions.optimized_ridge;
        model.detail.mlr.best_params.optimized_lasso = cvopts_cell{bestmod}.rmoptions.optimized_lasso;
        model.detail.mlr.optimized_ridge_theta = options.optimized_ridge;
        model.detail.mlr.optimized_lasso_theta = options.optimized_lasso;
    end
end
end

%--------------------------------------------------------------------------
function [structs] = repstructs(inputstruct,n)
% simple helper functions to get a cell array of structs so that PCT can be
% used
structs = cell(n,1);
parfor i=1:n
  structs{i} = inputstruct;
end
end

%--------------------------------------------------------------------------


%----------------------------EOF-------------------------------------------
