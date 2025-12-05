function [model, Xlda, numComp] = lda_cal(X, y0, numComp, lambda, method, priors)
%   lda_cal calibrates a regularized Linear Discriminant Analysis (LDA) model.
%   The 'method' input parameter determines whether to use 'eig' or 'svd', with 'svd' as the default.
%
%  INPUTS:
%   X(m,n)  = matrix of m samples x n variable
%   y0      = vector with numeric classes
%   numComb = number of dicriminant components or factors to compute
%   lambda  = regularization parameter
%   priors  = prior probabilities for each class if not provided [class1,class2,...,classn]
%   method  = determines whether to use 'eig' or 'svd'    
%
%  OUTPUTS: 
%   model  = structure containing:
%                   model.w                 = model parameters(weights)
%                   model.scores            = X projected into the LDA subspace
%                   model.varianceExplained = variance explained 
%                   model.numComp           = number of components 
%                   model.withingClass      = within-class scatter matrix
%                   model.betweenClass      = between-class scatter matrix
%                   model.numClasses        = number of classes
%                   model.classLabels       = class labels
%                   model.meanClasses       = class means
%                   model.l2penalty         = L2 penalty
%                   model.Probs             = Samples class probabilities
%                   model.Pred              = most probable class prediction 
%                   model.calError          = calibration classification error
%                   model.Sw_lda            = Pooled covariance in the LDA space
%                   model.mean_lda          = Mean of the classes in the LDA space
%   Xlda    = scores. X projected into the LDA subspace
%
%  If lambda is not supplied it will make lambda = 0.001
%  If regularization is not required input lambda = 0
%
%  Writen by Manuel Palacios for Eigenvector Research Inc. 
%  Copyright Eigenvector Research, Inc. 2004
%  Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

if nargin < 4 || isempty(lambda)
    lambda = 0.0001; % Set default lambda if not specified
end

% Fit Linear Discriminant Analysis (LDA) model

% Set 'svd' as the default method if not specified
if nargin < 5 || isempty(method)
    method = 'svd';
end

% Select the computation method based on 'method' input
if strcmp(method, 'eig')
    % If 'method' is set to 'eig', use the generalized eigenvector problem solver
    [model, W, Xlda, priors] = lda_engine_cal_eig(X, y0, numComp, lambda);
elseif strcmp(method, 'svd')
    % Use the Singular Value Decomposition solver by default or if 'method' is set to 'svd'
    [model, W, Xlda, priors] = lda_engine_cal_svd(X, y0, numComp, lambda);
else
    error('Invalid method. Choose ''eig'' or ''svd''.');
end

% Calculate class probabilities and predictions

classLabels = model.classLabels;
numClasses  = model.numClasses;


% Calculate class means and covariance matrix in LDA subspace
numComp = model.numComp;

projection = (X * model.coef') + model.intercept;
Probs = getsoftmax(projection);

% Classify the samples using the probabilities
[~, Pred] = max(Probs, [], 2);

if size(y0,1) == 1
    y0=y0';
end

calError = (1-sum(Pred == y0) / length(y0));

model.Probs     = Probs;
model.Pred      = Pred;
model.calError  = calError;
model.priors    = priors;       % Priors used at calibration

end

%% support function 

function Y = mvnpdf_evri(X, mu, Sigma)
% mvnpdf_evri calculates the multivariate normal probability density function
% with inputs X, mu, and Sigma and output Y.

[n, d] = size(X); % n = number of observations, d = number of dimensions
X = X - mu; % subtract mean from X
[R, p] = chol(Sigma); % Cholesky factorization of Sigma
if p ~= 0 % check if Sigma is not positive definite
    error('Sigma must be positive definite');
end
Q = R'\X'; % solve R'Q = X' to get Q
q = dot(Q,Q,1); % calculate the squared Euclidean distance
c = (2*pi)^(-d/2) * prod(diag(R)); % normalization constant
Y = c * exp(-0.5*q); % evaluate the multivariate normal PDF

end