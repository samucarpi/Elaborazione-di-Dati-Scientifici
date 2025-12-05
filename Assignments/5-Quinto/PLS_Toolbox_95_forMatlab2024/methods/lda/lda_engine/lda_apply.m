function [output] = lda_apply(model,X)

% lda_apply applys a calibrated LDA model to a matrix X
%
%  INPUTS:
%   model   = LDA model
%   X(m,n)  = matrix of m samples x n variable
%   y0      = vector with numeric classes
%
%  OUTPUTS: 
%   output  = structure containing:
%                   output.scores           = scores, X projected into the LDA subspace 
%                   output.Pred             = Samples predictions
%                   output.numComp          = number of components 
%                   output.testError        = testset classification error


% Input validation for model and X
if ~isstruct(model)
    error('The first input must be a structure representing the LDA model.');
end
if ~ismatrix(X)
    error('The second input must be a two-dimensional matrix.');
end

ldastr = model.detail.lda;
coef = ldastr.coef;
intercept = ldastr.intercept;

% Apply Linear Discriminant Analysis (LDA) model to X
w = ldastr.w;
Xlda = X.data(:,            X.include{2}) * w;  % Apply to ALL samples

% Calculate class probabilities and predictions
classLabels = model.detail.lda.classLabels; %model.classLabels;
numClasses  = length(classLabels);
classset = model.detail.options.classset;

projection = (X.data(:,model.detail.includ{2}) * coef') + intercept;
Probs = getsoftmax(projection);

% Classify the samples using the most probable class
[~, Pred] = max(Probs, [], 2);

% Populate output structure
output.scores    = Xlda;         
output.Probs     = Probs;
output.Pred      = Pred;
end

%%
function Y = mvnpdf_evri(X, mu, Sigma)
% MY_MVNPDF calculates the multivariate normal probability density function
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