function [J,g] = softmaxcostfunckernelL2(theta,K,Y,k,lambda)
%softmaxcostfunckernelL2 calculates cost and gradient for kernel Softmax
%Logistic with L2 (Ridge) Regularization
%Regression. The parameters for the last class are assumed to be zero to
%avoid over parametrization.
%  Inputs:
%   theta   = parameters of the hypothesis function. The parameters for the
%   last class are assumed to be zero 0
%   K       = Kernel Matrix X*X' (use functions kernelPoly or kernelRBF)
%   Y       = vector with numerical classes
%   k       = number of classes
%   lambda  = regularization parameter

[m, n] = size(K);
nCols = k-1;

theta1 = reshape(theta,[n nCols]);
theta1(:,k) = zeros(n,1); %last class fixed to zero

Z = sum(exp(K*theta1),2);
J = -sum((sum(K .* theta1(:,Y).',2) - log(Z)));


%add penalty
theta2 = reshape(theta,[m nCols]);

for i = 1:nCols
    J = J+lambda*sum(theta2(:,i)'*K*theta2(:,i));
end


if nargout > 1
    g = zeros(n,k-1);
    for c = 1:k-1
        g(:,c) = -sum(K .* repmat((Y==c) - exp(K * theta1(:,c))./Z,[1 n]));
    end

    for j = 1:nCols
        g(:,j) = g(:,j) + 2*lambda*K*theta2(:,j);
    end
    g = g(:);
end 

end

