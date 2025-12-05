function [J,g] = lrcostfuncV2kernelL2(theta,K,Y,lambda)
%lrcostfuncV2 calculates cost and gradient for Logistic Regression using a 
% kernalized matrix and L2 regularization
%  Inputs:
%   K       = Kernel Matrix X*X' (use functions kernelPoly or kernelRBF)
%   Y       = vector with binary clases 1 or -1
%   theta   = parameters of the hypothesis function
%   lambda  = regularization parameter

[m,n] = size(K);

Ktheta = K*theta;
yKtheta = Y.*Ktheta;

b = [zeros(m,1) -yKtheta];
B = max(b,[],2);
lse = log(sum(exp(b-repmat(B,[1 size(b,2)])),2))+B;

J = sum(lse);

J = J+sum(lambda*theta'*K*theta); %add penalty


if nargout > 1
        g = -(K.'*(Y./(1+exp(yKtheta)))); 
        g = g + 2*lambda*K*theta;
end                                                                                                                                                                                                                                        
end

