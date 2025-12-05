function [J,g] = lrcostfuncV2L2(theta,X,Y,lambda)
%lrcostfuncV2 calculates cost and gradient for V2 Logistic Regression
%  Inputs:
%   K       = Kernel Matrix X*X' (use functions kernelPoly or kernelRBF)
%   Y       = vector with binary clases 1 or -1
%   theta   = parameters of the hypothesis function
%   lambda  = regularization parameter

[m,n] = size(X);

Xtheta = X*theta;
yXtheta = Y.*Xtheta;

b = [zeros(m,1) -yXtheta];
B = max(b,[],2);
lse = log(sum(exp(b-repmat(B,[1 size(b,2)])),2))+B;

J = sum(lse);

J = J+sum(lambda.*(theta.^2)); %add penalty


if nargout > 1
        g = -(X.'*(Y./(1+exp(yXtheta))));    
end
        g = g + 2*lambda.*theta;                                                                                                                                                                                                                                
end

