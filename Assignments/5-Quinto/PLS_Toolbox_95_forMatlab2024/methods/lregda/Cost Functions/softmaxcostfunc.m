function [J,g] = softmaxcostfunc(theta,X,Y,k)
%softmaxcostfunc calculates cost and gradient for Softmax Logistic
%Regression. The parameters for the last class are assumed to be zero to
%avoid over parametrization.
%  Inputs:
%   theta   = parameters of the hypothesis function. The parameters for the
%   last class are assumed to be zero 0
%   X(m,n)  = matrix of m samples x n variable
%   Y       = vector with numerical classes
%   k       = number of classes


[m, n] = size(X);
theta = reshape(theta,[n k-1]);
theta(:,k) = zeros(n,1);

Z = sum(exp(X*theta),2);
J = -sum((sum(X .* theta(:,Y).',2) - log(Z)));

if nargout > 1
    g = zeros(n,k-1);

    for c = 1:k-1
        g(:,c) = -sum(X .* repmat((Y==c) - exp(X * theta(:,c))./Z,[1 n]));
    end
    g = reshape(g,[n * (k-1) 1]);
end
end

