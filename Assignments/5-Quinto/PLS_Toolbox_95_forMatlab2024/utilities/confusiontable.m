function [confusiontab, classids, texttable] = confusiontable(varargin)
%CONFUSIONTABLE Create confusion table
% Calculate confusion table for classification model or from a list of 
% actual classes and a list of predicted classes.
% Create a table with entry (i,j) = number predicted to be class with
% index i which actually are class with index j.
%
% Calculate confusion table for:
% 1. each class modeled in an input model.
%   Input models must be of type PLSDA, SVMDA, KNN, or SIMCA
%   Optional second parameter "usecv" specifies use of the cross-validation
%   based "cvclassification" instead of the default self-prediction 
%   classifications.
% 2. Input vectors of true class and predicted class either as numeric
%   values or as cell arrays of strings:
%       [1 2 3 4]  OR  {'a' 'b' 'c' 'd'}
%
% INPUTS:
%   model      = model or pred of type PLSDA, SVMDA, KNN, or SIMCA
%   usecv      = true: confusion table uses cross-validation predictions 
%                false (default) confusion table uses self-predictions
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
%   confusiontab = confusion table, nclasses x nclasses array, where the
%                  (i,j) cell shows the number of samples which were
%                  predicted to be class i but which actually were class j.
%   classids     = class names
%   texttable    = cell array containing a text representation of the
%                confusion table, texttable{i} is the i-th line of the
%                texttable. Note that this text representation of the
%                confusion table is displayed if the function is called
%                with no output assignment.
% 
%I/O: [confusiontab, classids, texttable] = confusiontable(model);
%I/O: [confusiontab, classids, texttable] = confusiontable(model, usecv);
%I/O: [confusiontab, classids, texttable] = confusiontable(model, usecv, predrule);
%I/O: [confusiontab, classids, texttable] = confusiontable(trueClass,predClass);
%
%See also: CONFUSIONMATRIX, GETTRUEANDPREDCLASSES

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin==0; varargin{1} = 'io'; end
if ischar(varargin{1}) & ismember(varargin{1},evriio([],'validtopics')) %Help, Demo, Options
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; confusiontab = evriio(mfilename,varargin{1},options); end
  return;
end
confusiontab = [];
classids     = [];
texttable    = [];

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
    % Reconstruct the class variable. Included-only samples.
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
        [y, predClass] = gettrueandpredclasses(model);
      end
      % identify the classes
      [classes, classids] = getClassesAndNames(model);
    
    else                          % (trueClass,predClass)
        model = [];
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

[confusiontab, classids, texttable] = getconfusiontable(y, predClass, classes, classids, usecv, model);

if nargout==0
  disp(texttable);
  clear confusiontab
end

function maxlen = getmaxlength(ids)
%GETMAXLENGTH get length of longest 'ids' ignoring leading,trailing spaces
maxlen = 0;
for cip = 1:size(ids,1)
  if length(strtrim(ids(cip,:))) > maxlen
    maxlen = length(strtrim(ids(cip,:)));
  end
end

function [confusiontab, classids, texttable] = getconfusiontable(y, predClass, classes, classids, usecv, model)
nonzeroclasses = classes(classes~=0);
nonzeroclassids = char(classids(classes~=0));%Get space padded char array for consistent formatting. 
nclasses = length(nonzeroclasses);
nonzeroclassesorig = nonzeroclasses;
nonzeroclassidsorig = nonzeroclassids;
nclassesorig = nclasses;
confusiontab = NaN(nclasses+1, nclasses);

% Create the table as string array
if usecv
  name = 'Confusion Table (CV):';
else
  name = 'Confusion Table:';
end
texttable = {
  name
  sprintf('%45s', 'Actual Class')
  };

if isempty(y)
  texttable = char(texttable);
  return
end

% Special case for SIMCA where y is an array. Orig classes and final
% classes can differ. An orig class can be in multiple final classes.
if isvector(y)
  %all other methods...
  maskin = y~=0;
  yp = predClass(maskin);   % Exclude class 0, which are test samples, with true class unknown.
  y  = y(maskin);
  
  for cip = 1:nclasses;
    for cit = 1:nclasses;
      class0 = y==nonzeroclasses(cit);
      % rows are predicted, columns are actual class.
      % (i,j) is number predicted to be class  with index i which actually are class with index j
      confusiontab(cip, cit) = sum(yp(class0) == nonzeroclasses(cip));
    end
  end
  for cit = 1:nclasses;
    class0 = y==nonzeroclasses(cit);
    confusiontab(nclasses+1, cit) = sum(yp(class0) == 0);
  end
elseif ismatrix(y)
  % matrix y and predClass (ONLY SIMCA comes into here)
  if isvector(predClass)
    tmp = class2logical(predClass,nonzeroclasses);
    predClass = tmp.data;
  end
  incl = model.detail.include{1};
  maskin = sum(y,2)~=0;     % Exclude samples which do not belong to a modeled class
  yp = predClass(maskin,:);
  y  = y(maskin,:);
  
  nonzeroclasses = classes(classes~=0);
  nonzeroclassids = char(classids(classes~=0));%Get space padded char array for consistent formatting.
  nclasses = length(nonzeroclasses);
  % For the original classes
  classset = model.detail.options.classset;
  clas = model.detail.classlookup{1,1,classset};
  clasnum=[clas{:,1}];
  clasid=clas(:,2);
  nonzeroclassesorig = clasnum(clasnum~=0);
  
  % nonzeroclassesorig are the classes in classlookup for this classset.
  % Remove any nonzeroclassesorig which is not present in oclass
  oclass = model.detail.class{1,1,classset};
  % set nonzeroclasesorig to intersection with oclass
  nonzeroclassesorig = nonzeroclassesorig(ismember(nonzeroclassesorig, oclass(incl)));
  nonzeroclassesorigindices = ismember(clasnum,nonzeroclassesorig);
  nonzeroclassidsorig = char(clasid(nonzeroclassesorigindices));
  nclassesorig = length(nonzeroclassesorig);

  oclassl = class2logical(oclass(incl));
  oclasslm = oclassl.data(maskin,:);
  % sum(yp,2)==0 are the samples which were not predicted to any modelled class
  %(sum(yp,2)==0)'*double(oclasslm) shows how many of each orig class were not assigned to modelled class
  confusiontab = ([yp sum(yp,2)==0])'*double(oclasslm);
else
  error('Unexpected dimensions for true and predicted class');
end

ngap = 10;
maxlabel = 10;
% Can table be compacted?
lenmax = getmaxlength(nonzeroclassids);
shift = lenmax - maxlabel + 1;
if shift > 0
  shift = 0; % no compacting
end
lenmax0 = max(lenmax, length('Unassigned'));
shift0 = lenmax0 - maxlabel + 1;
nspaces = ngap + 8 + length('Predicted as ') + shift0;
tmpa = sprintf('%-*s', nspaces, ' ');
classid = cell(nclassesorig,1);
keys = cell(1);
vals = cell(1);
nlongnames = 0;
for cip = 1:nclassesorig
  classid{cip} = strtrim(nonzeroclassidsorig(cip,:));
  if length(classid{cip})> maxlabel  % Abbreviate long class ids
    nlongnames = nlongnames+1;
    clidfull = classid{cip};
    classid{cip} = sprintf('%.5s*%d', classid{cip}, cip);
    key = classid{cip};
    keys{nlongnames} = key;
    vals{nlongnames} = clidfull;
  else
    classid{cip} = sprintf('%-8s', classid{cip});
  end
  tmpa = [tmpa, sprintf('%-9.8s', classid{cip})];
end
texttable{end+1} = tmpa;

% get labels and append table values
lenmax = getmaxlength(nonzeroclassids);
lenmax = max(lenmax, length('Unassigned'));
shift = lenmax - maxlabel + 1;
sublen = ngap+ length('Predicted as ')+shift;
labels = repmat(' ', nclasses+1, sublen);
for cip = 1:nclasses
  classid{cip} = strtrim(nonzeroclassids(cip,:));
  labels(cip,1:sublen) = sprintf('Predicted as %-*s', (ngap+shift), strtrim(classid{cip,:}));
end
classid{nclasses+1,1} = 'Unassigned';
labels(nclasses+1,1:sublen) = sprintf('Predicted as %-*s', (ngap+shift), strtrim(classid{nclasses+1,:}));

ngap = size(labels,2);
for cip = 1:nclasses
  tmpp = '';
  for cit = 1:nclassesorig;
    tmpp = [tmpp, sprintf('%9s', num2str(confusiontab(cip, cit)))];
  end
  texttable{end+1} = sprintf('%-*s%s', ngap, labels(cip,:), tmpp);
end
% Add row for predicted unclassified
  tmpp = '';
for cit = 1:nclassesorig;
  tmpp = [tmpp, sprintf('%9s', num2str(confusiontab(nclasses+1, cit)))];
end
texttable{end+1} = sprintf('%-*s%s', ngap, labels(nclasses+1,:), tmpp);

% Add Key if necessary
nkeys = length(keys);
if nlongnames>0
  texttable{end+1} = 'Key:';
  for ikey = 1:nkeys
  texttable{end+1} = sprintf('%-*s = %s', 9, keys{ikey}, vals{ikey});
  end
end
  
texttable = char(texttable);

