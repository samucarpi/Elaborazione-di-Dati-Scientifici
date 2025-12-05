function [model, W, Xlda, priors, varargout] = lda_engine_cal_svd(X, y0, numComp, lambda)
%lda_engine_cal_svd calibrates a regularized Linear Discriminant Analysis (LDA) 
% model using singular value decomposition. 
%
%  INPUTS:
%   X(m,n)  = matrix of m samples x n variable
%   y0      = vector with numeric classes
%   numComb = Number of dicriminant components or factors to compute
%   lambda  = regularization parameter
%  OUTPUTS: 
%   model  = structure containing:
%                   model.w                 = model parameters(weights)
%                   model.scores            = score 
%                   model.varianceExplained = variance explained 
%                   model.numComp           = number of components 
%                   model.withingClass      = within-class scatter matrix
%                   model.betweenClass      = between-class scatter matrix
%                   model.numClasses        = number of classes
%                   model.classLabels       = class labels
%                   model.meanClasses       = class means
%                   model.l2penalty         = L2 penalty
%   W       = model parameters (weights)
%   Xlda    = scores. X projected into the LDA subspace
%   vargout = explained variance ratios in each dicriminant component
%
%  If lambda is not supplied it will make lambda = 0.001
%  If regularization is not required input lambda = 0
%
%  Writen by Manuel Palacios for Eigenvector Research Inc. 
%  Copyright Eigenvector Research, Inc. 2004
%  Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin < 4
    lambda = 0.001; % always regularize to improve numerical stability
end

Xorig = X;

% Compute class means
classLabels = unique(y0);
numClasses = length(classLabels);
if numComp >= min(numClasses,size(X,2))
  numComp = min(numClasses-1,size(X,2));
  warning(['Number of components is larger than acceptable. Switching to ' num2str(numComp) ' components.']);
end
numVariables = size(X, 2);
meanX = mean(X, 1);
meanClasses = zeros(numClasses, numVariables);
for i = 1:numClasses
    meanClasses(i,:) = mean(X(y0==classLabels(i),:), 1);
end

% Calculate Priors
priors = zeros(numClasses, 1);
for i = 1:numClasses
  priors(i) = sum(y0 == classLabels(i));
end
priors = priors / sum(priors);

xbar = priors' * meanClasses;

S_W = cell(numClasses,1);
for i = 1:numClasses
    Xi = X(y0==classLabels(i),:);
    meanXi = mean(Xi, 1);
    S_W{i} = (Xi - meanXi);
end

S_W = cat(1,S_W{:});

% within scaling by with classes std-dev
stddev = std(S_W,1);
stddev(find(stddev==0)) = 1;
fac = 1/(size(X,1) - numClasses);

% within variance scaling
X = sqrt(fac) * S_W./stddev;

[U,S,V] = svd(X,'econ');
Vt = V';
rankSW = sum(diag(S) > 1e-4);
scalings = (Vt(1:rankSW,:)./stddev)' ./ repmat(diag(S(1:rankSW,1:rankSW))',size(V,1),1);
if numClasses==1; fac = 1; else fac = 1/(numClasses - 1);

X = ((sqrt((size(X,1) .* priors) .* fac))' .* (meanClasses - xbar)')' * scalings;

[U,S,V] = svd(X,'econ');
[eigenvalues, indices] = sort(diag(S), 'descend');
scalings = scalings * V(:,1:numComp);
coef = (meanClasses - xbar) * scalings;
intercept = (-0.5 * sum(coef.^2,2) + log(priors))';
coef = coef * scalings';
intercept = intercept - (xbar * coef');
W = scalings;

% % Project data onto LDA subspace
Xlda = Xorig * W(:,1:numComp);
ncompmax = min(numClasses-1,size(Xorig,2));
eigenvalues = eigenvalues(1:ncompmax);
% Output explained variance ratios if requested
if nargout > 3
  ve = eigenvalues.^2 / sum(eigenvalues.^2);
  varargout{1} = ve(1:ncompmax);
end

model.eigenvalues = eigenvalues;
model.w                 = W;
model.scores            = Xlda; 
ve = eigenvalues.^2 / sum(eigenvalues.^2);
model.varianceExplained = ve(1:ncompmax);
model.numComp           = numComp;
model.withingClass      = S_W;
model.numClasses        = numClasses;
model.classLabels       = classLabels;
model.meanClass         = meanClasses;
model.l2penalty         = lambda;
model.coef              = coef;
model.intercept         = intercept;
end
