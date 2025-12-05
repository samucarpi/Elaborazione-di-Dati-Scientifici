function [RES,A,labels,clslookup] = mergeLeastSeparable(A,labels,clslookup,opts)
%MERGELEASTSEPARABLE Combine pairs of classes that are hardest to classify.
  % Merges the samples coming from the two least separable classes into one
  % class.
  %
  % INPUTS:
  %         A = X-block, "double" or "dataset", data to classify
  %    labels = Y-block (OPTIONAL) if (x) is a dataset containing classes for
  %              sample mode (mode 1) otherwise, (y) is a vector of sample 
  %              classes for each sample in A.
  % clslookup = Cell array of class lookup table.
  %      opts = Model options and Cross Validation options.
  %
  %  OUTPUT:
  %       RES = Matrix containing pairwise misclassification between classes
  %               res = crossval.m results.
  %         A = Data to classify.
  %    labels = Updated class labels.
  % clslookup = Update class lookup table.
  %
  %I/O: [RES,A,labels,clslookup] = mergeLeastSeparable(A,labels,clslookup,opts)
  % 
  %See also: HMAC, GETPAIRMISCLASSIFICATION, GETMISCLASSIFICATION, AUTOCLASSIFIER, MODELSELECTOR, CROSSVAL, PLSDA

  % Copyright © Eigenvector Research, Inc. 2022
  % Licensee shall not re-compile, translate or convert "M-files" contained
  %  in PLS_Toolbox for use with any software other than MATLAB®, without
  %  written permission from Eigenvector Research, Inc.

RES = getMisclassification(A,labels,opts);

[row,col] = find(RES==max(max(RES))); %take position of max misclass error
% if max(max(RES))==0
%     disp('    mergeLeastSeparable: perfect classification, no merging') % tempdos
% end
r = row(1);
c = col(1);

% only consider included samples
if isdataset(A)
  numcl = unique(labels(A.include{1},:));
else
  numcl = unique(labels);
end

% Remove class zero. That one is not used by us (it is for samples with no
% class and is automatically added even if there are none of such samples
numcl(numcl==0)=[];
if length(numcl)~=size(RES,2)
    error('Something wrong')
end

% merge the least separable pair of classes into one class
idx = find(labels==numcl(r)|labels==numcl(c));
labels(idx)=numcl(r); % Set all of them to one of the classes
% r and c can be the same, execute below only if they are different
if ~isequal(r,c)
  % update class lookup to indicate class merging
  classR = find(numcl(r)==[clslookup{:,1}]);
  classC = find(numcl(c)==[clslookup{:,1}]);
  clslookup{classR,2} = [clslookup{classR,2} ', ' clslookup{classC,2}];
end
end
