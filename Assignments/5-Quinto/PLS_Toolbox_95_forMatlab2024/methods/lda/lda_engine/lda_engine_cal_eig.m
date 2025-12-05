function [model, W, Xlda, varargout] = lda_engine_cal_eig(X, y0, numComp, lambda)
%lda_engine_cal_eig calibrates a regularized Linear Discriminant Analysis (LDA) 
% model solving generalized eigenvalue problem. 
%
%  INPUTS:
%   X(m,n)  = matrix of m samples x n variable
%   y0      = vector with numeric classes
%   numComp = Number of dicriminant components or factors to compute
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

if nargin < 3
    error(['Input number of components () is missing.']);
end

% Compute class means
classLabels = unique(y0);
numClasses = length(classLabels);
if numComp >= min(numClasses,size(X,2))
  numComp = min(numClasses-1,size(X,2));
  warning(['Number of components is larger than acceptable. Switching to ' num2str(numComp) ' components.']);
end
% Calculate Priors
priors = zeros(numClasses, 1);
for i = 1:numClasses
  priors(i) = sum(y0 == classLabels(i));
end
priors = priors / sum(priors);
numVariables = size(X, 2);
meanX = mean(X, 1);
meanClasses = zeros(numClasses, numVariables);
for i = 1:numClasses
    meanClasses(i,:) = mean(X(y0==classLabels(i),:), 1);
end

% Compute within-class scatter matrix
S_W = zeros(numVariables);
for i = 1:numClasses
    Xi = X(y0==classLabels(i),:);
    meanXi = mean(Xi, 1);
    S_i = cov(Xi,1) * priors(i);
    S_W = S_W + S_i;
end

% Add the L2 Ridge regularization term (lambda penalty) to the pooled covariance matrix
S_W = S_W + lambda * eye(numVariables);

% Compute between-class scatter matrix
S_B = zeros(numVariables);
for i = 1:numClasses
    meanDiff = meanClasses(i,:) - meanX;
    S_B = S_B + sum(y0==classLabels(i)) * (meanDiff' * meanDiff);
end

St = cov(X,1);
S_B = St - S_W;
% Solve generalized eigenvalue problem 
% first check for erroneous solution
[AA,BB] = qz(S_B,S_W);
around = diag(AA) < eps;
bround = diag(BB) < eps;
if any((around & bround)==1)
  error(['The Scatter-Within and Scatter-Between matrices are ill-conditioned'...
        ' and a reliable solution cannot be found. Increase the regularization parameter'...
        ' to avoid this issue.'])
end


[W, D] = eig(S_B, S_W);

% Sort eigenvectors by decreasing eigenvalues
[eigenvalues, indices] = sort(diag(D), 'descend');
eigenvalues = abs(eigenvalues);
ncompmax = min(numClasses-1,size(X,2));
eigenvalues = eigenvalues(1:ncompmax);
W = W(:, indices);

% Select top numComp eigenvectors
W = W(:, 1:numComp);

coef = (meanClasses * W) * W';
intercept = (-0.5 * diag(meanClasses * coef') + log(priors))';

% Project data onto LDA subspace
Xlda = X * W;

% Output explained variance ratios if requested
if nargout > 3
    varargout{1} = eigenvalues / sum(eigenvalues);
end

model.eigenvalues       = eigenvalues;
model.w                 = W;
model.scores            = Xlda; 
model.varianceExplained = eigenvalues / sum(abs(eigenvalues));
model.numComp           = numComp;
model.withingClass      = S_W;
model.betweenClass      = S_B;
model.numClasses        = numClasses;
model.classLabels       = classLabels;
model.meanClass         = meanClasses;
model.l2penalty         = lambda;
model.coef              = coef;
model.intercept         = intercept;

end


