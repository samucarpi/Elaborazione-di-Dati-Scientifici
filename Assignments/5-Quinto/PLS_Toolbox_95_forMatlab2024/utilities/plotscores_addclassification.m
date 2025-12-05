function [d,lbl] = plotscores_addclassification(modl,actual)
%PLOTSCORES_ADDCLASSIFICATION Adds classification fields to scores data.
%I/O: [d,lbl] = plotscores_addclassification(modl,actual)

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

clnums = [0 modl.classification.classnums];
clids  = [modl.classification.classids];

d = [];
lbl = {};

ny = length(clids);

%see if we can add actual classes
if ~isempty(actual);
  actual = double(actual);
  if size(actual,2)>1
    %multi-column actual means use "inclasses"
    if isfield(modl.detail, 'data') & ~isempty(modl.detail.data{2}) & ~isempty(modl.detail.data{2}.class{2})
      % avoid possible labeling problem when class groupings was used
      clactual = actual*modl.detail.data{2}.class{2}';
    else
      clactual = actual*modl.classification.classnums';
    end
  else
    %single column actual means use "inclass"
    clactual = actual;
  end
  %re-assign zero classes as NaN's
  clactual(clactual==0) = nan;
  d = [d clactual];
  lbl = [lbl {'Class Measured'}];
end


% add prediction statistics
% Handle NaNs by effectively setting those entries to be class 0
modl.classification.inclass(isnan(modl.classification.inclass)) = 0;
modl.classification.mostprobable(isnan(modl.classification.mostprobable)) = 0;

inclass = clnums(modl.classification.inclass+1)';
mostprob = clnums(modl.classification.mostprobable+1)';
d = [d, inclass];
d = [d, mostprob];
for ii=1:ny
  d = [d, modl.classification.inclasses(:,ii)];
end
d = [d, ~any(modl.classification.inclasses,2)];
multiclass=sum(modl.classification.inclasses,2)>1;
d = [d, multiclass];
for ii=1:ny
  d = [d, modl.classification.probability(:,ii)];
end

lbl{end+1} = ['Class Pred Strict'];
lbl{end+1} = ['Class Pred Most Probable'];
for ii=1:ny
  lbl{end+1} = ['Class Pred Member ' clids{ii}];
end
lbl{end+1} = ['Class Pred Member - unassigned'];
lbl{end+1} = ['Class Pred Member - multiple'];
for ii=1:ny
  lbl{end+1} = ['Class Pred Probability ' clids{ii}];
end

%see if we can add misclassed flag
if ~isempty(actual)
  if size(actual,2)>1
    %multi-column actual means use "inclasses"
    misclassed = double(any(actual~=modl.classification.inclasses,2));
    misclassed(all(actual==0,2)) = nan; %any all-zero actual rows are not ever "misclassed"
    misclassed(all(isnan(actual),2)) = nan; %any all-nan  actual rows are not ever "misclassed"
  else
    %single column actual means use "inclass"
    misclassed = double(actual~=inclass);
    misclassed(isnan(actual(:)) | (actual(:)==0)) = NaN;  %class 0 samples are NOT EVER "misclassified"
  end
  d = [d misclassed];
  lbl = [lbl {'Misclassified'}];
end
