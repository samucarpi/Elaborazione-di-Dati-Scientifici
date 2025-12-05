function [theta,pred] = lrengine(X,Y,k, reg, inopts)
%LRENGINE fits a Softmax Logistic Regression model. If lambda is supplied it
%   will use L2 (Ridge) regularization.
%
%  INPUTS:
%   X(m,n)  = matrix of m samples x n variable
%   Y       = vector with nonzero numerical classes
%   k       = number classes
%   reg     = selects the kind of regularization to use {1,2,3}
%             0 = No regularization
%             1 = L1    LASSO
%             2 = L2    RIDGE
%             3 = L1L2  ELASTIC NETS
% 
% Options:
%   lambda  = regularization. Large lambda increases regularization
%  maxIter  = minFunc max iteration (see minFunc.m)
%
%  OUTPUTS:
%   theta   = parameters of the hypothesis function
%   pred    = class prediction 1 or 0 based of a 0.5 probability threshold
%
%   LRV1 automatically sets up lambda for L1 optimization L1General2_PSSgb
%


[m, n] = size(X); %  Setup the data matrix appropriately, and add ones for the intercept term

% Add intercept term (theta-nut) to x and X_test
X = [ones(m, 1) X];

lambda = inopts.lambda;

% Initialize fitting parameters
initial_theta = zeros((n+1)*(k-1),1);

%  Set options for minFunc
mfOpts = [];
if strcmp(inopts.displaymf, 'on')
  mfOpts.display = 'full';
else
  mfOpts.display = 'off';
end
mfOpts.maxIter = inopts.maxIter;
% Use minFunc defaults for other minFunc options, including:
% verbose,verboseI,debug,doPlot,maxFunEvals,maxIter,optTol,progTol,method

if nargin < 4 | reg == 0
  try
    theta = minFunc(@(t)(softmaxcostfunc(t,X,Y,k)),initial_theta,mfOpts);
  catch ME
    msg = ['Error thrown from minFunc '];
    causeException = MException('MATLAB:myCode:dimensions',msg);
    ME = addCause(ME,causeException);
    rethrow(ME)
  end
  
  theta = reshape(theta,[n+1 k-1]);
  theta = [theta zeros(n+1,1)];
  
else
  
  if reg == 1
    if size(lambda, 1)==1
      % Set up regularizer
      lambda = lambda*ones(n+1,k-1);
      lambda(1,:) = 0; % Don't penalize biases
      lambda = lambda(:);
    else
      lambda = lambda;
    end
    
    L1options = struct('MaxIter', 2000,'verbose',0);
    theta = L1General2_PSSgb(@(t)(softmaxcostfunc(t,X,Y,k)),initial_theta,lambda,L1options);
    theta = reshape(theta,[n+1 k-1]);
    theta = [theta zeros(n+1,1)];
    
  elseif reg == 2
    if size(lambda, 1)==1
      % Set up regularizer
      lambda = lambda*ones(n+1,k-1);
      lambda(1,:) = 0; % Don't penalize biases
      lambda = lambda(:);
    else
      lambda = lambda;
    end
    
    theta = minFunc(@(t)(softmaxcostfuncL2(t,X,Y,k,lambda)),initial_theta,mfOpts);
    theta = reshape(theta,[n+1 k-1]);
    theta = [theta zeros(n+1,1)];
    
  elseif reg == 3
    if size(lambda, 1)==1
      % Set up regularizer
      lambda = lambda*ones(n+1,k-1);
      lambda(1,:) = 0; % Don't penalize biases
      lambda = lambda(:);
      lambda2 = lambda;
    else
      lambda2 = lambda; % it needs sencond lambda parameter for L2
    end
    
    L1options = struct('MaxIter', 2000,'verbose',0);
    
    theta = L1General2_PSSgb(@(t)(softmaxcostfuncL2(t,X,Y,k,lambda2)),initial_theta,lambda,L1options);
    theta = reshape(theta,[n+1 k-1]);
    theta = [theta zeros(n+1,1)];
  end
  
end

% Get Softmax Results
pred = X*theta;
end

