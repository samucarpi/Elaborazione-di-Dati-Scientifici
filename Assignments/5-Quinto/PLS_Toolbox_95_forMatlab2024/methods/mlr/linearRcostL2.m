function [J, grad] = linearRcostL2(theta, X, y, lambda)
%rlrcostfunc calculates cost and gradient for Logistic Regression with
% L2 (Ridge) regularization
%
%  Inputs:
%   X(m,n)  = matrix of m samples x n variable
%   Y       = vector with binary classes 1 or 0
%   theta   = parameters of the hypothesis function
%   lambda  = regularization parameter


m = length(y); % number of calibration samples

% Initial values for J and grad
J = 0;
grad = zeros(size(theta));

% Regularized Cost Function

ThetaTemp = theta;
ThetaTemp(1) = 0;

J = (1/(2*m))*sum(((X*theta)-y).^2)+(lambda/(2*m))*sum(ThetaTemp.^2);

temp = X * theta;
error = temp - y;

grad = (1/m)*(X'*error)+(lambda/m)*ThetaTemp;

end
