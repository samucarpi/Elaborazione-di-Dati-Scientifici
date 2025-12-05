function varargout = xgbengine(varargin)
%XGBENGINE XGBoost for classification or regression using the XGBoost package.
%  Gradient Boosted Tree Ensemble for classification or regression.
%  xgbTrain uses the XGBoost package to train or apply an XGB model or
%  return cross validation accuracy based on training data.
%
%  Cross-validation search for optimal parameter values is triggered by 
%  passing ranges for the eta, max_depth, or num_round parameters.
%
%  INPUTS:
% Can take two forms, EITHER:
%         x = X-block (predictor block) class "double"
%         y = Y-block (predicted block) class "double" is a vector of length m
%             indicating sample class or target value.
%     model = XGB model produced by previous xgbengine training run.
%   options = Options to XGBoost's predict method in a struct form.
% OR:
%         x = X-block (predictor block) class "double"
%         y = Y-block (predicted block) class "double" is a vector of length m
%             indicating sample class or target value.
%   options = Arguments to XGBoost's train method in a struct form. Can
%             consist of one or more of the following fields:
%        xgbtype    : ['xgbc' | 'xgbr' ] type of XGB
%        n        (v) : n-fold cross validation mode
%        waitbar : [ 'off' | {'on'} ] governs wait bar during optimization
%                   and predictions.
%
%  OUTPUTS:
%     model = XGBoost Java model (if not run in cross-validation mode)
%     cv    = cross validation accuracy (%), if run in cross-validation mode
%     pred  = XGBoost prediction (if model is passed)
%    
%     Note: XGBENGINE is a lower level function. Users are recommended to use 
%           the functions xgb for regression or xgbda for classification.
%
%I/O: model = xgbengine(x,y,options)
%I/O: cv    = xgbengine(x,y,options)
%I/O: pred  = xgbengine(x,y,model,options)
%
%See also: XGB, XGBDA

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%Start Input
if nargin==0  % LAUNCH GUI
  varargin = {'io'};
end
if ischar(varargin{1}) %Help, Demo, Options
  
  options = [];
  options.display    = 'off';
  options.waitbar    = 'on';
  options.xgbtype    = 'XGBC';
  options.eta        = 0.3;
  options.max_depth  = 6;
  options.num_round  = 100;
  options.booster    = 'gbtree'; %'dart'; %'gblinear';  %'gbtree';      % def = gbtree
  options.eval_metric = 'error'; % classification default = error. Also, errorl@t where t is threshold, def=0.5
  % eval_metric = sprintf('error@%4.2f', class_threshold);
  %eval_metric = 'error'; %'auc';
  
  % non-xgboost options
  options.class_threshold = 0.5;
  options.nfold           = 5;
  options.niterCV         = 5;

  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
  
end

if nargin<2
  error([ upper(mfilename) ' requires 2 inputs.'])
end

try
  mode = '';
  % Check Input. Convert varargin to {x, y, model, options}
  % Possible calls:
  % //2 inputs: (x,model)
  % 3 inputs: (x,y,options)   case A
  %           (x,y,model)     case B
  % 4 inputs: (x,y,model,options)
  switch nargin
    case 2  %two inputs (x, y) or (x, options)
      if  isa(varargin{2},'struct')
        % Must be case A: (x,options)
        varargin = {varargin{1},[],[],varargin{2}};
        mode = 'train';    % do train
      else
        % (x,y): convert to (x, y, options)
        varargin = {varargin{1},varargin{2},[],xgbengine('options')};
        mode = 'train';    % do train
      end
    case 3  %three inputs
      % Case A: (x,y,options)
      % Case B: (x,model,options)
      % Case C: (x,y,model)
      if  isa(varargin{3},'struct')
        if ~isa(varargin{2},'evriPyClient')
          % Must be case A: (x,y,options)
          varargin = {varargin{1},varargin{2},[],varargin{3}};
          mode = 'train';    % do train
        else
          % Case B: (x,model,options)
          varargin = {varargin{1},[],varargin{2},varargin{3}};
          mode = 'predict';    % do prediction
        end
%       elseif (isjava(varargin{3}))
%         % Must be case B: (x,y, model)
%         varargin = {varargin{1:3},xgbengine('options')};
%         mode = 'predict';    % do prediction
      else
        error(['Input arguments not recognized. Type: ''help ' mfilename ''''])
      end
    case 4   %four inputs
      %Case A: (x,y,model,options)
      if(isnumeric(varargin{1}) & isa(varargin{3},'evriPyClient') & isa(varargin{4},'struct'))
        mode = 'predict';    % do prediction
      else
        error(['Input arguments not recognized. Type: ''help ' mfilename ''''])
      end
    otherwise
      error(['Input arguments not recognized. Type: ''help ' mfilename ''''])
      
  end
  
  if ~isfield(varargin{4},'norecon') | ~varargin{4}.norecon
    varargin{4} = reconopts(varargin{4},mfilename,0);
  end
  if strcmp(mode,'train') & isOptimize(varargin{4})
    mode = 'optimize';
  end

  cmap = [];  % unique input classes
  if strcmp(mode, 'predict')  %predictmode
    predictions = xgbPredict(varargin{1}, varargin{2}, varargin{3}, varargin{4});  %(x, y, model, options);
    varargout{1} = double(predictions);
  elseif strcmp(mode, 'train') | strcmp(mode, 'crossvalidate')
%       opts = m2javaopts(varargin{4});
    [modelOrCv, cmap] = xgbTrain(varargin{1}, varargin{2}, varargin{4}); %x, y, options)
    varargout{1} = modelOrCv;
  elseif strcmp(mode, 'optimize')
    [cvResult] = xgbOptimize(varargin{1}, varargin{2}, varargin{4}); %x, y, options)
    varargout{1} = cvResult;
  end
  varargout{2} = cmap;
  
catch
  lerror = lasterror;
  lerror.message = ['Error using xgbengine: ' lerror.message];
  rethrow(lerror);
end

