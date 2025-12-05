function [J, grad] = linearRcost(theta, X, y)
%linearRcost calculates cost and gradient for Logistic Regression with
% 
% Least Square Cost Function
%
%  Inputs:
%   X(m,n)  = matrix of m samples x n variable
%   y       = vector with reference samples values
%   theta   = parameters of the hypothesis function (coeficients)

m = length(y); % number of calibration samples

% Initial values for J and grad
J = 0;
grad = zeros(size(theta));


% Regularized Cost Function

J = (1 / (2*m) ) * sum(((X * theta)-y).^2);

temp = X * theta;
error = temp - y;

grad = (1 / m) * (X' * error);

end
