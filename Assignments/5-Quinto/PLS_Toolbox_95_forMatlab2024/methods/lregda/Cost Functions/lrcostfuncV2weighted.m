function [J,g] = lrcostfuncV2weighted(theta,X,Y,W)
%lrcostfuncV2 calculates cost and gradient for Y-weighted V2 Logistic Regression
%  Inputs:
%   X(m,n)  = matrix of m samples x n variable
%   Y       = vector with binary clases 1 or -1
%   theta   = parameters of the hypothesis function
%   W       = weights

[m,n] = size(X);

Xtheta = X*theta;
yXtheta = Y.*Xtheta;

b = [zeros(m,1) -yXtheta];
B = max(b,[],2);
lse = log(sum(exp(b-repmat(B,[1 size(b,2)])),2))+B;

J = sum(W.*lse);

if nargout > 1
        g = -X.'*(W.*Y.*(1-(1./(1+exp(-yXtheta)))));   
end
                                                                                                                                                                                                                                    
end

