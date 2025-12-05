function [J, grad] = lrcostfuncL2(theta, X, Y, lambda)
%rlrcostfunc calculates cost and gradient for Logistic Regression with
% L2 (Ridge) regularization
%
%  Inputs:
%   X(m,n)  = matrix of m samples x n variable
%   Y       = vector with binary classes 1 or 0
%   theta   = parameters of the hypothesis function
%   lambda  = regularization parameter


m = length(Y); % number of calibration samples

% Initial values for J and grad
J = 0;
grad = zeros(size(theta));


% Regularized Cost Function
ThetaTemp = theta;
ThetaTemp(1) = 0;

J = (-1 / m) * sum(Y.*log(sigmoid(X * theta)) + (1 - Y).*log(1 - sigmoid(X * theta)));


%add regularizer

J = J + (lambda / (2 * m))*sum(ThetaTemp.^2); 

if nargout > 1
    temp = sigmoid (X * theta);
    error = temp - Y;
    grad = (1 / m) * (X' * error) + (lambda/m)*ThetaTemp; %regularizer term for gradient
end

end
