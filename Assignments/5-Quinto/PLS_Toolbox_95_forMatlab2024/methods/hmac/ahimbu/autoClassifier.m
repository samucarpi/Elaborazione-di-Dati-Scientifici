function model = autoClassifier(X, labels, opts, clslookup)
%AUTOCLASSIFER Automatic Hierarchical Model Builder for Classification.
  % Engine function to automatically create a hierarchical model for
  % classification problems. The function splits up the classification
  % problem into smaller classification problems following the strategy
  % that is described in [Marchi, Lorenzo, et al. “Automatic Hierarchical
  % Model Builder.” Journal of Chemometrics, 2022,
  % https://doi.org/10.1002/cem.3455]
  %
  % INPUTS:
  %           x = X-block (predictor block) class "double" or "dataset",
  %      labels = Y-block (OPTIONAL) if (x) is a dataset containing classes for
  %                sample mode (mode 1) otherwise, (y) is a vector of sample 
  %                classes for each sample in x.
  %        opts = Model options and Cross Validation options.
  %   clslookup = Class lookup table.
  %
  %  OUTPUT:
  %       model  = Resulting hierarchical classification model.
  %
  %I/O: model = autoClassifier(X, labels, opts)
  % 
  %See also: HMAC, MERGELEASTSEPARABLE, GETMISCLASSIFICATION, GETPAIRMISCLASSIFICATION, MODELSELECTOR, CROSSVAL, PLSDA

  % Copyright © Eigenvector Research, Inc. 2022
  % Licensee shall not re-compile, translate or convert "M-files" contained
  %  in PLS_Toolbox for use with any software other than MATLAB®, without
  %  written permission from Eigenvector Research, Inc.

% fprintf('autoClassifier(): size(X) = (%d,%d); %d unique labels\n', size(X,1), size(X,2), length(unique(labels)))

% establish invariant for the first while loop iteration
wasdsolabels = false;
if isdataset(X)
  inclx = X.include{1, opts.classset};
else
  inclx = 1:size(X,1);
end


newlabels = labels;
if isdataset(labels)
  wasdsolabels = true;     % TODO: Note: this is never reached since labels will always be matrix when called in calibrate
  newlabels = labels.data(inclx);
end

RES = 1;
Xnew = X;
newclslookup = clslookup;
% Continue merging until we are ready to do the split
while length(unique(newlabels)) > 2 && max(RES(:)) > 0 % Perfect clasification or two classes left
   [RES,Xnew,newlabels,newclslookup] = mergeLeastSeparable(Xnew,newlabels,newclslookup,opts);
end

% For every new class ID, see how many old classes correspond to it
% modelselector docs say that the targets are ordered by the class number
class_ids = sort(unique(newlabels));

% Do not consider class 0
class_ids(class_ids==0) = [];

% target models for the modelselector
submodels = cell(length(class_ids)+1, 1);
% .classes will store the children of this level
Results.classes = cell(length(class_ids), 2);
for i=1:length(class_ids)
    Results.classes{i,1} = class_ids(i);
    % Samples of this new class
    subset = newlabels == class_ids(i);
    sublen = length(unique(labels(subset)));
    if sublen == 1
        % New class is a primitive class, can just return it
        if ~wasdsolabels
          submodels{i} = unique(labels(subset));
        else
          submodels{i} = unique(labels.data(subset));
        end
    else
        % otherwise split it further
        submodels{i} = autoClassifier(X(subset, :), labels(subset), opts, clslookup);
    end
end
submodels{length(class_ids) + 1} = 0;

% decide which target model to choose
pre = opts.cvopts.preprocessing;
% make new x with new class lookup table
XNew = dataset(X);
XNew.classlookup{1} = newclslookup;
XNew.class{1} = newlabels;
triggermodel = plsda(XNew, getPairMisclassification(X, newlabels, opts), struct('display', 'off', 'plots', 'none', 'preprocessing', {pre}));
% FIXME: need a way to pass options to the PLS-DA model here

%replace classes with strings
if ~isempty(clslookup)
  % if lookup for class 0 is not there, include it
  if ~ismember(0,[clslookup{:,1}])
    clslookup{end+1,1} = 0;
    clslookup{end,2} = 'Class 0';
  end
  for i=1:length(submodels)
    if isnumeric(submodels{i})
      submodels{i} = clslookup{find(submodels{i}==[clslookup{:,1}]),2};
    end
  end
end

model = modelselector(triggermodel, submodels{:});
end

