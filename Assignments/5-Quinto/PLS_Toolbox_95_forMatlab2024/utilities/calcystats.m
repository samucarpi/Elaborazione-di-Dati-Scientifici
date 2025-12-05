function model = calcystats(model,predictmode,ypp,ypredpp)
%CALCYSTATS Calculate y-block statistics for a regression model.
% This helper function calculates the following statistics given a
% regression model with a y-block. This function operates on either a model
% or a prediction structure.
%
% INPUTS
%   model        - regression model.
%   predictmode  - [0|1] in prediction mode (1=prediction, 0=calibratio).
%   ypp          - preprocessed y-data.
%   ypredpp      - preprocessed predicted y-data.
%
%    .ssqresiduals{:,2} (y-block Q)
%    .detail.bias
%    .detail.rmsec 
%    .detail.rmsep
%    .detail.res{2}     (y-block residuals)
%
% This function requires the following model fields to be already filled in
% for the calculations to be made:
%   .loads           (if applicable)
%   .detail.data{2}  (y-block raw data "y-measured")
%   .detail.pred{2}  (y-block predictions)
%   .detail.includ   (original DSO include information)
%   .detail.preprocessing{2}  (y-block preprocessing)
%
% Calculating Q requires preprocessed y-measured and y-predictions. These
% can either be passed on the command line (as ypp and ypredpp) or they can
% be calculated using the preprocessing in the model and the y-data stored
% therein. Passing these values will be slightly faster and is generally
% recommended if the values are available.
%
%I/O: model = calcystats(model)               
%I/O: model = calcystats(model,ypp,ypredpp)
%
%See also: CLS, MLR, NPLS, PCR, PLS

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 1/2/09 created from PLS.m
%BK 5/2/2016 safeguards added for RMSEP & Pred Bias, when there are NaNs

%infer number of components
switch lower(model.modeltype)
  case {'mlr' 'cls', 'svm', 'svmda'}
    ncomp = 1;
  case 'ann'
    ncomp = model.detail.options.nhid1;
  case 'anndl'
    ncomp = getanndlnhidone(model);
  otherwise
    if ~isfield(model,'loads')
      ncomp = 1;
    else
      try
        ncomp = size(model.loads{1},2);
      catch
        ncomp = 1;
      end
    end
end

%determine if we have y-block data in the model and if we're doing
%prediction mode
haveyblock  = ~isempty(model.detail.data{2});

%Can't use this way to determine predict mode because rawmodel will return
%false positive.
%predictmode = ~isempty(model.detail.rmsec);

if haveyblock
  %if we have y-block information in the model, calculate statistics
  if nargin<3
    %if we didn't get raw y information from caller, calculate it now
    ypp     = preprocess('apply',model.detail.preprocessing{2},model.detail.data{2});
    ypredpp = preprocess('apply',model.detail.preprocessing{2},model.pred{2});
    ypredpp = ypredpp.data;
  end

  %calculate residuals
  model.detail.res{1,2}    = (model.pred{1,2}-model.detail.data{2}.data(:,model.detail.includ{2,2}));   %res is in original units
  
  %calculate ssq residuals
  model.ssqresiduals{1,2}  = (ypp.data(:,ypp.includ{2}) - ypredpp).^2;    %ssq is in preprocessed units (whatever they are)
  model.ssqresiduals{2,2}  = sum(model.ssqresiduals{1,2}(model.detail.includ{1,2},:),1); %based on cal samples only
  model.ssqresiduals{1,2}  = sum(model.ssqresiduals{1,2},2); %residuals for ALL samples
  
  %calculate other statistics
  ny = size(model.pred{2},2);
  if predictmode
    model.detail.rmsep(1:ny,1:ncomp) = nan;
    rmsepvals = model.detail.res{2}(model.detail.includ{1,2},:);
    model.detail.predbias(1:ny,1:ncomp)  = nan;  %5/16/07 % <- moved up 5/2/2016
    
    if (~isnan(rmsepvals)) % 5/2/2016
      rmsepvals(isnan(rmsepvals))      = [];    %Remove NaNs if there are any.
      model.detail.rmsep(1:ny,ncomp)   = sqrt(mean(rmsepvals.^2));
      model.detail.predbias(1:ny,1:ncomp)  = nan;  %5/16/07
      model.detail.predbias(1:ny,ncomp)    = mean(model.pred{2}(model.detail.includ{1,2},:)) - ...
        mean(model.detail.data{2}.data(model.detail.includ{1,2},model.detail.includ{2,2}));
    else
      ymeas = model.detail.data{2}.data(model.detail.includ{1,2},model.detail.includ{2,2});
      ypred = model.pred{2}(model.detail.includ{1,2},:);
      
      for i = 1:ny % Remove NaNs, per column.
        % calc RMSEP
        rmsepvals_icol = rmsepvals(:,i);
        rmsepvals_icol(isnan(rmsepvals_icol)) = [];
        model.detail.rmsep(i,ncomp) = sqrt(mean(rmsepvals_icol.^2));
        % calc pred bias
        ymeas_col = ymeas(:,i);
        ypred_col = ypred(:,i);
        ypred_col(isnan(ymeas_col)) = [];
        ymeas_col(isnan(ymeas_col)) = [];
        model.detail.predbias(i,ncomp) = mean(ypred_col) - mean(ymeas_col);
      end
    end

    model.detail.r2p(1:ny,1:ncomp)   = nan;
    r2                               = diag(r2calc(model.pred{1,2}(model.detail.includ{1,2},:),model.detail.data{2}.data(model.detail.includ{1,2},model.detail.includ{2,2})));
    if ~isempty(r2)
      model.detail.r2p(1:ny,ncomp)   = r2;
    end
  else        %calibrate mode... calculate rmsec for this one model
    model.detail.rmsec(1:ny,1:ncomp) = nan;
    model.detail.rmsec(1:ny,ncomp)   = sqrt(mean(model.detail.res{2}(model.detail.includ{1,2},:).^2));
    model.detail.bias(1:ny,1:ncomp)  = nan;  %5/16/07
    model.detail.bias(1:ny,ncomp)    = mean(model.pred{2}(model.detail.includ{1,2},:)) - ...
      mean(model.detail.data{2}.data(model.detail.includ{1,2},model.detail.includ{2,2})); 
    model.detail.r2c(1:ny,1:ncomp)   = nan;
    r2                               = diag(r2calc(model.pred{1,2}(model.detail.includ{1,2},:),model.detail.data{2}.data(model.detail.includ{1,2},model.detail.includ{2,2})));
    if ~isempty(r2)
      model.detail.r2c(1:ny,ncomp)   = r2;
    end
  end
  
else
  %no y-block available, clear out prediction and y-block info
  model.detail.res{1,2}   = [];
  model.ssqresiduals{1,2} = [];
  model.ssqresiduals{2,2} = [];
  model.detail.rmsep      = [];
  model.detail.bias       = [];
end

