function [misclassed, classids, texttable] = confusionmatrix(varargin)
%CONFUSIONMATRIX Create confusion matrix
% Create confusion matrix from a classification model or from a list of 
% actual classes and a list of predicted classes.
%
% Calculate True/False Postive/Negative rates (TPR FPR TNR FNR) matrix for:
% 1. each class modeled in an input model.
%   Input models must be of type PLSDA, SVMDA, KNN, or SIMCA
%   Optional second parameter "usecv" specifies use of the cross-validation
%   based "cvclassification" instead of the default self-prediction 
%   classifications.
% 2. Input vectors of true class and predicted class.
% Rates are defined:
% TPR: proportion of positive cases that were correctly identified
% FPR: proportion of negatives cases that were incorrectly classified as positive
% TNR: proportion of negatives cases that were classified correctly
% FNR: proportion of positive cases that were incorrectly classified as negative
%
% MCC: Matthew's Correlation Coefficient, when there are only two classes:
%      MCC = TP*TN-FP*FN / sqrt((TP+FP)*(TP+FN)*(TN+FP)*(TN+FN))
%      where TP/TN/FP/FN refer to the count of each category.
%
% INPUTS:
%   model      = model or pred of type PLSDA, SVMDA, KNN, or SIMCA
%   usecv      = true: confusion matrix uses cross-validation predictions 
%                false (default) confusion matrix uses self-predictions
%    predrule  = [{'mostprobable'}, 'strict'] specifies the classification
%                rule used. 'mostprobable' makes predictions based on 
%                choosing the class that has the highest probability.
%                'strict' makes predictions based on the rule that each 
%                sample belongs to a class if the probability is greater 
%                than a specified threshold probability value for one and 
%                only one class. If no class has a probability greater than 
%                the threshold, or if more than one class has a probability 
%                exceeding it, then the sample is assigned to class zero (0) 
%                indicating no class could be assigned. The threshold value 
%                is specified for classification methods by the option 
%                strictthreshold, with a default value of 0.5.
%   trueClass  = vector of actual classes
%   predClass  = vector of predicted classes
%
% OUTPUTS:
%   misclassed = confusion matrix, nclasses x 8 array, one row per class,
%                columns are True/False Postive/Negative rates (TPR FPR TNR FNR)
%                followed by:
%                Number of samples, 
%                Error rate, proportion of samples which were incorrectly classified, = 1-accuracy, = (FP+FN)/(TP+TN+FP+FN)
%                Precision, = TP/(TP+FP)
%                F1-Score, = 2*TP/(2*TP+FP+FN)
%                where TP/TN/FP/FN refer to the counts rather than the rates for these quantities.
%   classids   = class names
%   texttable  = cell array containing a text representation of the
%                confusion matrix, texttable{i} is the i-th line of the
%                texttable. Note that this text representation of the
%                confusion matrix is displayed if the function is called
%                with no output assignment.
%                If there are only two classes then the Matthew's
%                Correlation Coefficient value is included as last line.
% 
%I/O: [misclassed, classids, texttable] = confusionmatrix(model);
%I/O: [misclassed, classids, texttable] = confusionmatrix(model, usecv);
%I/O: [misclassed, classids, texttable] = confusionmatrix(model, usecv, predrule);
%I/O: [misclassed, classids, texttable] = confusionmatrix(trueClass, predClass);
%
%See also: CONFUSIONTABLE, GETTRUEANDPREDCLASSES 

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin==0; varargin{1} = 'io'; end
if ischar(varargin{1}) & ismember(varargin{1},evriio([],'validtopics')) %Help, Demo, Options
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; misclassed = evriio(mfilename,varargin{1},options); end
  return;
end
misclassed = [];
classids   = [];
texttable  = [];

switch nargin
  case 0
    error('Insufficient inputs')
  case 1
    % (model)
    model = varargin{1};
    usecv = false;
    predrule = 'mostprobable';
    if isempty(model)
      return
    end
    % Reconstruct the class variable
    [y, predClass] = gettrueandpredclasses(model, usecv, predrule);
    % identify the classes
    [classes, classids] = getClassesAndNames(model);
    
  case 2
    % (model, usecv)
    % (trueClass,predClass)
    if isempty(varargin{1}) & isempty(varargin{2})
      return
    end
    
    if ismodel(varargin{1})       % (model, usecv)
      model = varargin{1};
      usecv = varargin{2};
      predrule = 'mostprobable';
      if isempty(model)
        return
      end
      % Reconstruct the class variable
      if usecv
        if ~strcmpi(model.modeltype, 'simca')
          [y, predClass] = gettrueandpredclasses(model, usecv, predrule);
        else  % simca does not have cv classification info
          y = [];
          predClass = [];
        end
      else
        [y, predClass] = gettrueandpredclasses(model, false, predrule);
      end
      % identify the classes
      [classes, classids] = getClassesAndNames(model);
      
    else                          % (trueClass,predClass)
      usecv = false;
      if isempty(varargin{1})   
        y = repmat(nan, size(varargin{2}));
        predClass = varargin{2};
      elseif isempty(varargin{2})
        predClass = repmat(nan, size(varargin{1}));
        y = varargin{1};
      else
        y = varargin{1};
        predClass = varargin{2};
      end
      % identify the classes      
      if ~iscell(y) | ~iscell(predClass)
        %numeric values
        if iscell(predClass) | iscell(y)
          error('If either trueClass or predClass is numeric, both must be');
        end
        classes = unique([y(:);predClass(:)]);
        classids = str2cell(num2str(classes(:)));
      else
        %cell array of strings
        if ~all(cellfun('isclass',y,'char')) | ~all(cellfun('isclass',predClass,'char'))
          error('trueClass and predClass must be cell arrays of strings')
        end
        [classids,classes] = unique([y(:);predClass(:)]);
        y = cellfun(@(s) classes(ismember(classids,s)),y);
        predClass = cellfun(@(s) classes(ismember(classids,s)),predClass);
      end
    end
    
  case 3
    % (model, usecv, predrule)
    % (trueClass,predClass)
    if isempty(varargin{1}) & isempty(varargin{2})
      return
    end
    
    if ismodel(varargin{1})       % (model, usecv)
      model = varargin{1};
      usecv = varargin{2};
      predrule = varargin{3};
      if isempty(model)
        return
      end
      % Reconstruct the class variable
      if usecv
        if ~strcmpi(model.modeltype, 'simca')
          [y, predClass] = gettrueandpredclasses(model, usecv, predrule);
        else  % simca does not have cv classification info
          y = [];
          predClass = [];
        end
      else
        [y, predClass] = gettrueandpredclasses(model,false,predrule);
      end
      % identify the classes
      [classes, classids] = getClassesAndNames(model);
    end
end

% use y, predClass, classes and classids:
[misclassed, classids, texttable] = getconfusionmatrix(y, predClass, classes, classids, usecv);

if nargout==0
  disp(texttable);
  clear misclassed
end

%--------------------------------------------------------------------------
function [misclassed, classids, texttable] = getconfusionmatrix(y, predClass, classes, classids, usecv)

nonzeroclasses = classes(classes~=0);
nonzeroclassnames = char(classids(classes~=0));%Get space padded char array for consistent formatting. 
nclasses = length(nonzeroclasses);
misclassed = repmat([0 nan], nclasses, 1);
predcounts = repmat(nan, nclasses, 4);     % to hold TP, FP, TN, FN

texttable = {};
if usecv
  texttable{end+1} = 'Confusion Matrix (CV):';
else
  texttable{end+1} = 'Confusion Matrix:';
end
sz = size(nonzeroclassnames);
ptitle = sprintf('%-*s', sz(2), '    Class:');
texttable{end+1} = [ptitle '      TPR         FPR         TNR         FNR         N      Err         P           F1'];

if isempty(y)
  return
end

% Special case for SIMCA where y is an array. Orig classes and final
% classes can differ. An orig class can be in multiple final classes.
if isvector(y)
  % Exclude class 0, which are test samples, with true class unknown.
  maskin = y~=0;
  y = y(maskin);
  ypred = predClass(maskin);
  nsamp = length(y);
  
  %loop over all non-zero classes
  for classind = 1:nclasses;
    class0 = y==nonzeroclasses(classind);                 % logical vector identifying samples belonging to this class
    % rows are class indices, columns: TPR FPR TNR FNR
    tp = sum(ypred(class0) == nonzeroclasses(classind));  % TP: Number of positive cases that were correctly classified
    fp = sum(ypred(~class0) == nonzeroclasses(classind)); % FP: Number negatives cases that were incorrectly classified as positive
    tn = sum(ypred(~class0) ~= nonzeroclasses(classind)); % TN: Number of negatives cases that were classified correctly
    fn = sum(ypred(class0) ~= nonzeroclasses(classind));  % FN: Number of positives cases that were incorrectly classified as negative
    err = fn + fp;                                        % Err: Number of cases belonging to this class which were incorrectly classified
    
    % convert to RATES
    misclassed(classind,1) = tp./sum(class0);   % TPR: proportion of positive cases that were correctly identified
    misclassed(classind,2) = fp./sum(~class0);  % FPR: proportion of negatives cases that were incorrectly classified as positive
    misclassed(classind,3) = tn./sum(~class0);  % TNR: proportion of negatives cases that were classified correctly,
    misclassed(classind,4) = fn./sum(class0);   % FNR: proportion of positives cases that were incorrectly classified as negative
    misclassed(classind,5) = sum(class0);       % NC:  Number of samples which are this class. TP+FN
    misclassed(classind,6) = err/nsamp;         % ER:  proportion of cases which are incorrectly classified. = 1-accuracy = (fp+fn)/total.
    p                      = tp/(tp+fp);        % P:   Precision = TP/(TP+FP)
    r                      = tp/sum(class0);    % R:   Recall    = TP/(TP+FN)
    misclassed(classind,7) = p;                 % P:   Precision = TP/(TP+FP)
    misclassed(classind,8) = 2*p*r/(p+r);       % F:   F1 Score  = 2PR/(P+R), where R (recall) = TPR, and P (precision) = TP/(TP+FP)
    
    predcounts(classind,1) = tp;                % TP
    predcounts(classind,2) = fp;                % FP
    predcounts(classind,3) = tn;                % TN
    predcounts(classind,4) = fn;                % FN
  end
  
elseif ismatrix(y)
  % matrix y and predClass. Convert vector predClass to logical matrix
  if isvector(predClass)
    tmp = class2logical(predClass,nonzeroclasses);
    predClass = tmp.data;
  end
  maskin = sum(y,2)~=0;
  yp = predClass(maskin,:);
  y  = y(maskin,:);
  nsamp = size(y,1);
  
  %loop over all non-zero classes
  for classind = 1:nclasses;
    % rows are class indices, columns: TPR FPR TNR FNR
    tp = sum( y(:,classind).*yp(:,classind));
    fp = sum(~y(:,classind).*yp(:,classind));
    tn = sum(~y(:,classind).*~yp(:,classind));
    fn = sum( y(:,classind).*~yp(:,classind));
    err = fp + fn;
    % convert to RATES
    misclassed(classind,1) = tp./sum(y(:,classind));  % TPR: proportion of positive cases that were correctly identified
    misclassed(classind,2) = fp./sum(~y(:,classind)); % FPR: proportion of negatives cases that were incorrectly classified as positive
    misclassed(classind,3) = tn./sum(~y(:,classind)); % TNR: proportion of negatives cases that were classified correctly,
    misclassed(classind,4) = fn./sum(y(:,classind));  % FNR: proportion of positives cases that were incorrectly classified as negative
    misclassed(classind,5) = sum(y(:,classind));      % NC: Number of samples which are this class.
    misclassed(classind,6) = err/nsamp;               % ER: proportion of cases which are incorrectly classified. = 1-accuracy = (fp+fn)/total.
    p                      = tp/(tp+fp);              % P:  Precision = TP/(TP+FP)
    r                      = tp/sum(y(:,classind));   % R:  Recall    = TP/(TP+FN)
    misclassed(classind,7) = p;                       % P:  Precision = TP/(TP+FP)
    misclassed(classind,8) = 2*p*r/(p+r);             % F:  F1 Score  = 2PR/(P+R), where R (recall) = TPR, and P (precision) = TP/(TP+FP)
    
    predcounts(classind,1) = tp;                % TP
    predcounts(classind,2) = fp;                % FP
    predcounts(classind,3) = tn;                % TN
    predcounts(classind,4) = fn;                % FN
  end
else
  error('Unexpected dimensions for true and predicted class');
end

for ic=1:nclasses
  texttable{end+1} = sprintf('%10s  %11.5f %11.5f %11.5f %11.5f %6d %11.5f %11.5f %11.5f',  nonzeroclassnames(ic,:), ...
    misclassed(ic,1), misclassed(ic,2), misclassed(ic,3), misclassed(ic,4), misclassed(ic,5), misclassed(ic,6), ...
    misclassed(ic,7), misclassed(ic,8));
end

if nclasses==2
  % MCC: Matthew's Correlation Coefficient, iff there are two classes:
  %      MCC = TP*TN-FP*FN / sqrt((TP+FP)*(TP+FN)*(TN+FP)*(TN+FN))
  tp = predcounts(1,1);
  fp = predcounts(1,2);
  tn = predcounts(1,3);
  fn = predcounts(1,4);
  mcc = (tp*tn-fp*fn) / sqrt( (tp+fp)*(tp+fn)*(tn+fp)*(tn+fn) );
  texttable{end+1} = sprintf('%10s  %4.3f', 'Matthew''s Correlation Coefficient =',  mcc); 
end

texttable = char(texttable);


