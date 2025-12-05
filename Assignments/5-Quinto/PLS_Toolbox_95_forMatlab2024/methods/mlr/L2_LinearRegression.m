function [theta] = L2_LinearRegression(X,y,lambda)
%L2_LinearRegression fits a Linear Regression model. If lambda is supplied it
%   will use L2 (Ridge) regularization.
%
%  INPUTS:
%   X(m,n)  = matrix of m samples x n variable
%   y       = vector with reference values
%   lambda  = lambda  = regularization parameter
%  OUTPUTS:
%   output  = structure containing theta, predictions and
%             calibreation error.
%   theta   = parameters of the hypothesis function (regression vector)

[m, n] = size(X); %  Setup the data matrix appropriately, and add ones for the intercept term

% % Add intercept term (theta-nut) to X
%X = [ones(m, 1) X];

% Initialize fitting parameters
%initial_theta = zeros(n + 1, 1);
initial_theta = zeros(n, 1);

% Set options for minFnunc
options = [];
options.display = 'off';
options.MaxIter = 400;

if nargin == 2

  [theta, J, exit_flag] = minFunc(@(t)(linearRcost(t, X, y)), initial_theta,options);

else
  theta = zeros(n,size(y,2));
  for i=1:size(theta,2)
    [thisTheta, J, exit_flag] = minFunc(@(t)(linearRcostL2(t, X, y(:,i), lambda)), initial_theta,options);
    theta(:,i) = thisTheta;
  end
end
end
