function RES = getMisclassification(A,labels,opts)
%GETMISCLASSIFICATION Reports missclassification for pairs of classes.
% Reports a matrix of missclassification errors. Each point in the
% matrix resembles a pairing of two classes and its error calculated by
% PLS cross-validation.
%
% INPUTS:
%       A = X-block (predictor block) class "double" or "dataset",
%  labels = Y-block (OPTIONAL) if (x) is a dataset containing classes for
%            sample mode (mode 1) otherwise, (y) is a vector of sample
%            classes for each sample in x.
%    opts = Model options and Cross Validation options.
%
%  OUTPUT:
%    RES  = Matrix of misclassification error.
%
%I/O: RES = getMisclassification(A,labels,opts,modelsettings)
%
%See also: HMAC, MERGELEASTSEPARABLE, AUTOCLASSIFIER, GETPAIRMISCLASSIFICATION, MODELSELECTOR, CROSSVAL, PLSDA


% Copyright © Eigenvector Research, Inc. 2022
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if isdataset(A)
  inclx = A.include{1};
else
  inclx = 1:size(A,1);
end

%% Now do the thing
% numcl = unique(labels);
% only consider included samples
numcl = unique(labels(inclx,:));

RES=[];  %RB RES matrix
for i=1:length(numcl)-1
  for j=i+1:length(numcl)
    idx = find(labels==numcl(i)|labels==numcl(j));
    a = A(idx,:);
    [ncomp, res] = getPairMisclassification(a, labels(idx)',opts);
    % res.misclassed{1} is for class i
    % res.misclassed{1}(:,2) is the false negative rate
    % And by doing min, I select the best one (the number of components
    % that gives the lowest
    RES(i,j)=sum(res.detail.misclassedcv{1}(:,ncomp));
    RES(j,i)=RES(i,j);
  end
end
end