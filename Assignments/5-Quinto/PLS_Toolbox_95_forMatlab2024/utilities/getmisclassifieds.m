function [misclassifiedIndex, status] = getmisclassifieds(model, theclass)
% Find the misclassified samples for the specified class:
% Returns 
% misclassifiedIndex: index of samples which are misclassified
% status            : status of each sample as True Positive, False Positive, True Negative 
%                     or False Negative, for the specified class 'theclass'
%
%I/O: [misclassifiedIndex] = getmisclassifieds(model);

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%
if isempty(model)
  error('Input is empty')
elseif ~ismodel(model)
  error('Input is not a model')
end

% Reconstruct class variable
[y, predClass] = gettrueandpredclasses(model);

maskin = y~=0;                       % class 0 are test samples, with true class unknown.
misclassifiedIndex = predClass(maskin)~=y(maskin);

[classes, classnames] = getClassesAndNames(model);

if nargin==2 & isnumeric(theclass)
  status = repmat('NA', length(y), 1);
  masktp = y==theclass & predClass==theclass & maskin;
  maskfp = y~=theclass & predClass==theclass & maskin;
  masktn = y~=theclass & predClass~=theclass & maskin;
  maskfn = y==theclass & predClass~=theclass & maskin;
  status(masktp,:) = repmat('TP', sum(masktp),1);
  status(maskfp,:) = repmat('FP', sum(maskfp),1);
  status(masktn,:) = repmat('TN', sum(masktn),1);
  status(maskfn,:) = repmat('FN', sum(maskfn),1);
end

if nargout==0
  disp(sprintf('Number of misclassified samples = %d', sum(misclassifiedIndex)));
  
  if nargin==1
    disp(sprintf('Number of misclassified samples = %d', sum(misclassifiedIndex)));
  elseif nargin==2 & isnumeric(theclass)
    misc = sum(maskfp) + sum(maskfn);
    disp(sprintf('Number of misclassified samples (for class %d) = %d', theclass, misc));
    disp(sprintf('Sample:  status (for class %d)', theclass));
    for i=1:size(status,1)
      disp(sprintf('%5d: %4s', i, status(i,:)));
    end
  end
end
