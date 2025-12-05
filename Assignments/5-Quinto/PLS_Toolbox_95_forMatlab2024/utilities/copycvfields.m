function model = copycvfields(from,to)
%COPYCVFIELDS Copy cross-validation results into model from structure.
% Given the output of the crossval function (from, as either a structure or
% a model with the expected fields in the detail sub-field) and a target
% model, the fields associated with cross-validation results will be copied
% over to the target model.
%
% If the target model (to) is omitted or is not a standard model structure,
% the cross-validation fields in (from) are copied directly to
% corresponding fields in a flat structure.
%
% Examples:
%   Copying crossval results (res) to a model:
%      model = copycvfields(res,model)
%   Copying crossval results from a model to a structure:
%      res = copycvfields(model)
%   Copying crossval results from one model to another:
%      model_to = copycvfields(model_from,model_to)
% Note: no assurance is made that the copied cross-validation results
% actually correspond to the model - user must assure the results apply to
% the (to) model.
%
%I/O: model = copycvfields(from,to)
%
%See also: COPYDSFIELDS, CROSSVAL

%Copyright © Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS

if ismodel(from)
  %if input for "from" was a model...
  if ~isfield(from,'detail')
    error('Input "from" model must have a detail field to copy from')
  end
  from = from.detail; %just extract detail field
  if isfield(from, 'cvclassification')
    from = rmfield(from,'cvclassification');  %but do NOT copy this field from a model (because it is specific to that model)
  end
end
if nargin<2
  to = [];
end
model = to;  %create output copy
ismod = ismodel(model);

%copy appropriate fields over into model structure
tocopy = {'cv' 'split' 'iter' 'press' 'cumpress' 'rmsecv' 'rmsec' 'rmsep' ...
  'cvpred' 'cvbias' 'cvi'...
  'r2cv' 'classerrc' 'classerrcv' 'misclassed' 'misclassedcv' 'cvclassification'...
  'r2c' 'cbias' 'q2y' 'r2y'...
  };

if ismod & strcmpi(model.modeltype, 'svmda')
  notcopy = {'rmsecv' 'rmsec' 'rmsep' 'cvbias' 'r2cv' 'r2c' 'cbias'};
  tocopy = setdiff(tocopy, notcopy);
end

%cell array of field translations. if we find the field in the first
%column, output should go to field name in second column
translate = {'misclassed' 'misclassedcv'};

%run through fields...
for f = tocopy;
  %look for field in from
  if isfield(from,f{:})
    %see if this field name is supposed to be translated to something
    %else in the model details field
    translateind = find(ismember(f{:},translate(:,1)));
    if ~isempty(translateind)
      tofield = translate{translateind,2};
    else
      tofield = f{:};
    end
    
    if ~ismod
      %save to output structure (if extracting)
      model.(tofield) = from.(f{:});
    elseif isfield(model.detail,tofield);
      %or save to model if a matching "target" field exists in the model
      model.detail.(tofield) = from.(f{:});
    end
  end
end


