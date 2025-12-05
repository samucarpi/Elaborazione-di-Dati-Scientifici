function [y, predClass] = gettrueandpredclasses(varargin)
%Reconstruct the true class variable as vector from the logical array
% when input a classifier model or pred structure.
% Also return the predicted class value for each row
% When using model input arg the optional second arg,
% usecv = [{true} | false], specifies whether to use self-predictions
% or CV-predictions for predicted class
%
%I/O: [y, predClass] = gettrueandpredclasses(model);
%I/O: [y, predClass] = gettrueandpredclasses(model, usecv);
%I/O: [y, predClass] = gettrueandpredclasses(model, usecv, predrule);
%
%See also: CONFUSIONTABLE, CONFUSIONMATRIX

%Copyright Eigenvector Research, Inc. 2011
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==1
  model = varargin{1};
  usecv = false;
  predrule = 'mostprobable';
elseif nargin==2
  model = varargin{1};
  usecv = varargin{2};
  predrule = 'mostprobable';
elseif nargin==3
  model = varargin{1};
  usecv = varargin{2};
  predrule = varargin{3};
else
  error('gettrueandpredclasses method requires one or two input args');
end

y = [];
predClass = [];

if isempty(model)
  error('Input is empty')
elseif ~ismodel(model)
  error('Input is not a model')
end

switch lower(model.modeltype)
  case {'knn' 'knn_pred'}
    classset  = model.detail.options.classset;
    if classset>0 & classset <=size(model.detail.class,3) & ~isempty(model.detail.class{1,1,classset})
      y = model.detail.class{1,1,classset};
      y = y(model.detail.includ{1});
    else
      y = [];
    end
    [predClass] = getpredclass(model, usecv, predrule);
    predClass = predClass(model.detail.includ{1});
    
  case {'plsda' 'plsda_pred' 'annda' 'annda_pred' 'lregda' 'lregda_pred' 'anndlda' 'anndlda_pred' 'lda' 'lda_pred'}
    y = gettrueclass(model);
    [predClass] = getpredclass(model, usecv, predrule);
    if ~isempty(y)
      y = y(model.detail.includ{1});
    end
    predClass = predClass(model.detail.includ{1});
    
  case {'svmda' 'svmda_pred'}
    if ~isempty(model.detail.data{2})
      y = model.detail.data{2}.data';
      y = y(model.detail.includ{1});
    else
      y = [];
    end
    [predClass] = getpredclass(model, usecv, predrule);
    predClass = predClass(model.detail.includ{1});
    
  case {'xgbda' 'xgbda_pred'}
    if ~isempty(model.detail.data{2})
      y = model.detail.data{2}.data';
      y = y(model.detail.includ{1});
    else
      y = [];
    end
    [predClass] = getpredclass(model, usecv, predrule);
    predClass = predClass(model.detail.includ{1});
    
  case {'simca' 'simca_pred'}
    if usecv
      error('SIMCA models do not have CV classification information')
    end
    % Create nsample x nsimca_classes logical array for y and predClass
    classset  = model.detail.options.classset;
    if classset>0 & classset <=size(model.detail.class,3) & ~isempty(model.detail.class{1,1,classset})
      y = model.detail.class{1,1,classset}';
      y = y(model.detail.includ{1});
      
      if any(y~=0)
        oclass = class2logical(y);
        smclass = model.detail.submodelclasses;
        y = zeros(size(oclass,1), length(smclass));
        for icol=1:length(smclass)
          use = ismember(oclass.class{2},smclass{icol});
          y(:,icol) = sum(oclass.data(:,use),2)>0;
        end
        % special case when class 0 is included in one submodel
        for icol=1:length(smclass)
          has0 = any(ismember(0,smclass{icol}));
          if has0
            use = sum(oclass.data,2)==0;
            y(use,icol) = 1;
          end
        end
        % y cols now represent submodels. Use classification.classnums/ids
        
        %add any unmodeled classes at end
        unmodeled = find(~ismember(oclass.class{2},[smclass{:}]));
        for icol = 1:length(unmodeled)
          y(:,end+1) = oclass.data(:,unmodeled(icol));
        end
      end
      
      predClass = getpredclass(model, usecv, predrule);
      predClass = predClass(model.detail.includ{1},:);
    else
      y = [];
    end
    
  otherwise
    error('Cannot operate on this model type ("%s")',model.modeltype);
end

%--------------------------------------------------------------------------
function [predClass] = getpredclass(model, usecv, predrule)
% Return predicted class numbers
if ~usecv | model.isprediction
  classification = model.classification;
else
  hascv = isfieldcheck(model,'model.detail.cvclassification');
  if hascv
    classification = model.detail.cvclassification;
  else
    error('model has no CV classification information')
  end
end
classnums = classification.classnums;
nsamps    = size(classification.probability,1);
predClass = repmat(0, nsamps, 1);

if strcmp('mostprobable', predrule)
  isbad = isnan(classification.mostprobable) | classification.mostprobable==0;
  predClass(~isbad) = classnums(classification.mostprobable(~isbad))';
elseif strcmp('strict', predrule)
  isbad = isnan(classification.inclass) | classification.inclass==0;
  predClass(~isbad) = classnums(classification.inclass(~isbad))';
else
  error('Unrecognized predrule value %s', predrule)
end


%--------------------------------------------------------------------------
function [y] = gettrueclass(model)
% Get the actual classes for samples.
%
% Do not use the following since it is not appropriate for plsda:
% classset  = model.detail.options.classset;
% if ~all(model.datasource{2}.size==0)    % has y
%   y = model.detail.class{1,2};
% else
%   y = model.detail.class{1,1,classset};
% end

% Instead,
% Find column of y-block that is =1, for each row: This gives column index.
% Convert to class # from column index using:
% 1) Look for classes in y-block COLUMNS (model.detail.data{2}.class{2}
%   (OR  model.detail.class{2,2}, which should be the same)
%   If there are no classes then use index 1:ncolumns(y)
% 2) index into classes vector (from (1)) to get actual class # for each
% sample
if ~isempty(model.detail.data{2})
  [mval, yi]= max(model.detail.data{2}.data');  % can be empty if no y
  
  if ~isempty(model.detail.data{2}.class{2})
    cls = model.detail.data{2}.class{2};
  else
    cls = 1:size(model.detail.data{2}, 2);
  end
  
  y = cls(yi);
  % handle case of  unknown class samples.
  % Set y = 0 if there was no class info for a sample.
  y(isnan(mval) | mval==0) = 0;
else
  y = [];
end




