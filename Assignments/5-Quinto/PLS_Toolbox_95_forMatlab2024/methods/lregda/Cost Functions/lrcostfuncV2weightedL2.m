function [J,g] = lrcostfuncV2weightedL2(theta,X,Y,lambda,W)
%lrcostfuncV2 calculates cost and gradient for Y-weighted Logistic
%Regression with L2 Ridge Regression 
%  Inputs:
%   X       = matrix of variables
%   Y       = vector with binary clases 1 or -1
%   theta   = parameters of the hypothesis function
%   lambda  = regularization parameter
%   W       = weights

[m,n] = size(X);

Xtheta = X*theta;
yXtheta = Y.*Xtheta;

b = [zeros(m,1) -yXtheta];
B = max(b,[],2);
lse = log(sum(exp(b-repmat(B,[1 size(b,2)])),2))+B;

J = sum(W.*lse);

J = J+sum(lambda.*(theta.^2)); %add penalty

if nargout > 1
        g = -X.'*(W.*Y.*(1-(1./(1+exp(-yXtheta)))));  
        g = g + 2*lambda.*theta; 
end
                                                                                                                                                                                                                                      
end

