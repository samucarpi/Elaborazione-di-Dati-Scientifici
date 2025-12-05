function [theta] = L1_LinearRegression(X,y,lambda,initial_guess)
%L1_LinearRegression fits a Linear Regression model. If lambda is supplied it
%   will use L1 (Lasso) regularization.
%
%  INPUTS:
%   X(m,n)  = matrix of m samples x n variable
%   y         = vector with reference values
%   lambda  = regularization parameter
%   initial_guess = 0 or 1 for least square solution
%
%  OUTPUTS:
%   output  = structure containing theta, predictions and
%             calibreation error.
%   theta   = parameters of the hypothesis function (regression vector)

[m, n] = size(X); %  Setup the data matrix appropriately, and add ones for the intercept term

% Add intercept term (theta-nut) to X
% X = [ones(m, 1) X];

% Set penalty vector
lambda = lambda*ones(size(X,2),1);

% Initialize fitting parameters
%initial_theta = zeros(n + 1, 1);

if initial_guess == 1
  initial_theta = pinv(X'*X)*X'*y;; % start from the least square solution
else
  initial_theta = zeros(n, 1);
end


%  Set options for minFnunc
optionsminFnunc = [];
optionsminFnunc.display = 'off';
optionsminFnunc.MaxIter = 400;


%  Set options for L1General2_PSSgb
options = [];
options.verbose = 0;
options.MaxIter = 500;


if nargin == 2

  [theta, J, exit_flag]   = minFunc(@(t)(linearRcost(t, X, y)), initial_theta,optionsminFnunc);

else
  theta = zeros(n,size(y,2));
  for i=1:size(theta,2)
    theta(:,i) = L1General2_PSSgb(@(t)linearRcost(t,X,y(:,i)),initial_theta,lambda,options);
  end
end
end
