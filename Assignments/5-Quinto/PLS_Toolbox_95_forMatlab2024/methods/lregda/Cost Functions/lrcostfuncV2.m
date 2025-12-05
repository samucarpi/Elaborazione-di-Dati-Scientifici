function [J,g] = lrcostfuncV2(theta,X,Y)
%lrcostfuncV2 calculates cost and gradient for V2 Logistic Regression
%  Inputs:
%   X(m,n)  = matrix of m samples x n variable
%   Y       = vector with binary clases 1 or -1
%   theta   = parameters of the hypothesis function

[m,n] = size(X);

Xtheta = X*theta;
yXtheta = Y.*Xtheta;

b = [zeros(m,1) -yXtheta];
B = max(b,[],2);
lse = log(sum(exp(b-repmat(B,[1 size(b,2)])),2))+B;

J = sum(lse);


if nargout > 1
        g = -(X.'*(Y./(1+exp(yXtheta))));    
end
                                                                                                                                                                                                                                    
end

