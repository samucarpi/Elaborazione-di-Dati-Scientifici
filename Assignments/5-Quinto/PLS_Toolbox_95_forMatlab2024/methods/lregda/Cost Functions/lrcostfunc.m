function [J, grad] = lrcostfunc(theta, X, Y)
%lrcostfunc calculates cost and gradient for Logistic Regression
%  Inputs:
%   X(m,n)  = matrix of m samples x n variable
%   Y       = vector with binary classes 1 or 0
%   theta   = parameters of the hypothesis function

m = length(Y); % number of calibration samples

% Initial values for J and grad
J = 0;
grad = zeros(size(theta));


% Cost Function
J = (-1 / m) * sum(Y.*log(sigmoid(X * theta)) + (1 - Y).*log(1 - sigmoid(X * theta)));

if nargout > 1
    temp = sigmoid (X * theta);
    error = temp - Y;
    grad = (1 / m) * (X' * error); 
end

end
