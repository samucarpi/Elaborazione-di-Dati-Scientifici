function model = simcastats(model,origmodel,options)
%SIMCASTATS Calculates prediction statistics for a SIMCA model or prediction
% This function is used by SIMCA and SIMCA_GUIFCN and is not generally
% called directly by users. It takes a SIMCA model as input and calculates
% the reduced Q and T^2 statistics for all sub-models allong with combined
% statistics and classifications.
% Outputs are the model with the statistics and classification information
% added (model)
%
%I/O: [model,classindx] = simcastats(model,options);

%Copyright Eigenvector Research, Inc. 2005
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

switch nargin
  case 1
    options = [];
    origmodel = [];
  case 2
    if isfield(origmodel,'modeltype')
      options = [];
    else
      options = origmodel;
      origmodel = [];
    end
end

if isempty(origmodel)
  origmodel = model;
end
if isempty(options)
  options = origmodel.detail.options;
end

classset = origmodel.detail.options.classset;
noclass = length(origmodel.submodel);

% Determine limits
for ii = 1:noclass
  n_in_model  = length(origmodel.submodel{ii}.ssqresiduals{1}(origmodel.submodel{ii}.detail.includ{1,1}));
  pc_in_model = size(origmodel.submodel{ii}.loads{1},2);
  model.rules.t2.decision(ii) = tsqlim(n_in_model,pc_in_model,options.rule.limit.t2);
  model.rules.q.decision(ii)  = residuallimit(origmodel.submodel{ii}.detail.reseig, options.rule.limit.q);
end

%calculate reduced stats
for ii=1:noclass
  
  tsqs = model.submodel{ii}.tsqs;
  if iscell(tsqs);
    tsqs = tsqs{1};
  end
  model.rtsq(:,ii)   = tsqs./model.rules.t2.decision(ii);

  ssqr = model.submodel{ii}.ssqresiduals;
  if iscell(ssqr);
    ssqr = ssqr{1};
  end
  if model.rules.q.decision(ii)>0
    model.rq(:,ii)     = ssqr./model.rules.q.decision(ii);
  else
    model.rq(:,ii)     = zeros(1,length(ssqr));
  end

  model.detail.submodelclasses{ii}  = unique(origmodel.submodel{ii}.detail.class{1,1,classset}(origmodel.submodel{ii}.detail.includ{1,1}));

  classes{ii}        = model.detail.submodelclasses{ii};  % allow composite classes
end
rt2rqsum     = sqrt(model.rtsq.^2 + model.rq.^2);

% copy values to "rules" level
model.rules.combined.value  = rt2rqsum;
model.rules.t2.value        = model.rtsq;
model.rules.q.value         = model.rq;

switch lower(options.rule.name)
  case 'combined'
    [mnt2q,classindx]  = min(rt2rqsum,[],2);
  case 't2'
    [mnt2q,classindx]  = min(model.rules.t2.value,[],2);
  case 'q'
    [mnt2q,classindx]  = min(model.rules.q.value,[],2);
  case 'both'
    [mnt2q,classindx]  = min(model.rules.q.value,[],2);
end

if ~isempty(classes)
  model.nclass = classes(classindx);
end
model.detail.nsubmodel = classindx;
