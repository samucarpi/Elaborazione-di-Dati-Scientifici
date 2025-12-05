function varargout = mlrengine(varargin)
%MLRENGINE Multiple Linear Regression computational engine.
%
%  INPUTS:
%         x = X-block (MxNx predictor block) class "double", and
%         y = Y-block (MxNy predicted block) class "double".
%
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%         algorithm: [{'leastsquares'} 'ridge' 'ridge_hkb' 'optimized_ridge' 'optimized_lasso' 'elasticnet'] Governs the
%                    level of regularization used when calculating the 
%                    regression vector. 'leastsquares' uses the normal equation without regularization.
%                    'ridge' uses the L2 penalty via the normal equation,
%                    'ridge_hkb' uses the L2 penalty with x'*x instead of
%                    the Identity matrix, 'optimized_ridge' uses the L2 penalty through an
%                    optimization approach, 'optimized_lasso' uses the L1 penalty, and 'elasticnet' uses both L1 and L2.
%             ridge: Scalar for ridge regression using the normal equation.
%   optimized_ridge: Scalar for the ridge parameter to use in regularizing the inverse
%                    for optimized_ridge or elasticnet regression.
%   optimized_lasso: Scalar for the lasso parameter to use in regularizing the inverse
%                    for lasso or elasticnet regression.
%           condmax: [{[]}] maximum condition number for inv(x'*x) {default:
%                    condmax>Nx*eps(norm(A))}. Provides ~principal components regression behavior to
%                    avoid rank deficiency during caluclation of inv(x'*x).
%                    Only used when 'algorithm' is 'leastsquares'.
%
%  OUTPUTS:
%       reg = matrix of regression vectors
%     theta = regularization value used in regression calculation
%   condnum = is the condition number for x'*x (when options.ridge = 0) or
%               x'*x+eye(Nx)*options.ridge (when options.ridge ~= 0).
%               max(condnum) is governed by options.condmax.
% condncomp = number of components used based upon condmax 
%
%I/O: [reg,theta,condnum,condncomp] = mlrengine(x,y,options);
%
%See also: MLR, ANALYSIS, PCR, PLS

%Copyright Eigenvector Research, Inc. 2005-2019
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 5/12/05 derrived from PCRENGINE

if nargin == 0; varargin{1} = 'io'; end
if ischar(varargin{1})
  options = mlr('options');
  options = rmfield(options,'display');
  options = rmfield(options,'plots');
  options = rmfield(options,'preprocessing');
  options = rmfield(options,'cvi');
  options = rmfield(options,'blockdetails');
  options = rmfield(options,'definitions');
  %engine file only handles 1 value of theta at a time...
  options.optimized_ridge = options.optimized_ridge(1);
  options.optimized_lasso = options.optimized_lasso(1);
  if nargout==0; clear varargout; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

switch nargin
case 1
  error('Insufficient inputs')
case 2
  % (x,y)
  varargin{3} = [];
case 3
  % (x,y,options)
end
%parse inputs
% x,y,options
x       = varargin{1};
y       = varargin{2};
options = reconopts(varargin{3},'mlr',0);
if isempty(options.optimized_ridge), options.optimized_ridge=0; end
if isempty(options.optimized_lasso), options.optimized_lasso=0; end

if any(min(y)==max(y))
  error('Regression not possible when all y values are the same (i.e. range=0).');
end

m       = size(x); % [my,ny] = size(y);
lw      = lastwarn;  warning off

% determine calculations based on what the cost function is
switch options.algorithm
  case 'leastsquares'
    y       = x'*y;
    [v,d]   = svd(x'*x);
    d       = diag(d);% + options.ridge;
    if ~isempty(options.condmax)
      if options.condmax < 2*eps
        options.condmax = d(1)/(max(m)*eps(d(1)));
      end
      ii      = find(d>d(1)/options.condmax);
      if isempty(ii)
        ii = 1:m(2);  % no truncation
      end
      reg     = v(:,ii)*diag(1./d(ii))*v(:,ii)'*y;
      condncomp = length(ii);
    else
      reg     = v*diag(1./d)*v'*y;
      condncomp = [];
    end

    warning(lw);
    varargout = { reg [] options.condmax condncomp };
    
  case 'ridge'
    y       = x'*y;
    [v,d]   = svd(x'*x);
     d       = diag(d) + options.ridge;
    reg     = v*diag(1./d)*v'*y;

    warning(lw);
    varargout = { reg options.ridge [] [] };
    
  case 'ridge_hkb'
    [reg, theta] = ridge_hkb(x,y);
    varargout = { reg theta [] []};

  case 'optimized_ridge'
    reg = L2_LinearRegression(x,y,options.optimized_ridge);
    varargout = { reg options.optimized_ridge []};
  case 'optimized_lasso'
    reg = L1_LinearRegression(x,y,options.optimized_lasso,0);
    varargout = { reg options.optimized_lasso []};
  case 'elasticnet'
    [reg] = L1L2_LinearRegression(x,y,options.optimized_ridge,options.optimized_lasso,0);
    varargout = { reg {options.optimized_ridge,options.optimized_lasso} []};
  otherwise
    error('Unsupported regularization. Choose one of: none, ridge, optimized_ridge, optimized_lasso, or elasticnet.')
end