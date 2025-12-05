function varargout = svmengine(varargin)
%SVMENGINE Support Vector Machine for classification or regression using the LIBSVM package.
%  Support Vector Machine for classification or regression.
%  svmTrain uses the LIBSVM package to train or apply an SVM model or
%  return cross validation accuracy based on training data.
%
%  Cross-validation is triggered by passing ranges for the cost, nu,
%  epsilon, or gamma options.
%
%  INPUTS:
% Can take two forms, EITHER:
%         x = X-block (predictor block) class "double"
%         y = Y-block (predicted block) class "double" is a vector of length m
%             indicating sample class or target value.
%     model = SVM model produced by previous svmengine training run.
%   options = Options to LIBSVM's svm_predict method in a struct form.
%         -b probability_estimates: whether to predict probability
%           estimates, 0 or 1 (default 0); for one-class SVM only 0 is supported
% OR:
%         x = X-block (predictor block) class "double"
%         y = Y-block (predicted block) class "double" is a vector of length m
%             indicating sample class or target value.
%   options = Arguments to LIBSVM's svm_train method in a struct form. Can
%             consist of one or more of the following fields (letter(s) in
%             parenthesis after each field name is the corresponding flag
%             passed into LIBSVM) :
%        svmtype (s) : type of SVM (default 0)
%           0 -- C-SVC
%           1 -- nu-SVC
%           2 -- one-class SVM
%           3 -- epsilon-SVR
%           4 -- nu-SVR
%        kerneltype (t) : type of kernel function (default 2)
%           0 -- linear: u'*v
%           1 -- polynomial: (gamma*u'*v + coef0)^degree
%           2 -- radial basis function: exp(-gamma*|u-v|^2)
%           3 -- sigmoid: tanh(gamma*u'*v + coef0)
%           4 -- precomputed kernel (kernel values in training_set_file)
%           WARNING: 1 and 3 are not currently supported.
%        degree (d) : degree in kernel function (default 3)
%        gamma  (g) : gamma in kernel function (default 1/k)
%                     Gamma controls the shape of the separating hyperplane.
%                     Increasing gamma usually increases number of support
%                     vectors. 
%        coef0  (r) : coef0 in kernel function (default 0)
%        cost   (c) : the parameter C of C-SVC, epsilon-SVR, and nu-SVR (default 1)
%                     Cost [0 ->inf] represents the penalty associated with errors 
%                     larger than epsilon. Increasing cost value causes 
%                     closer fitting to the calibration/training data.
%        nu     (n) : the parameter nu of nu-SVC, one-class SVM, and nu-SVR (default 0.5)
%                     Nu (0 -> 1] indicates a lower bound on the number of support 
%                     vectors to use, given as a fraction of total   
%                     calibration samples, and an upper bound on the fraction
%                     of training samples which are errors (poorly predicted 
%                     in regression or misclassified in classification).
%        epsilon   (p) : the epsilon in loss function of epsilon-SVR (default 0.1)
%                     In training the regression function there is no penalty 
%                     associated with points which are predicted within distance 
%                     epsilon from the actual value. Decreasing epsilon
%                     forces closer fitting to the calibration/training data.
%        cachesize (m) : cache memory size in MB (default 100)
%        terminationepsilon (e): tolerance of termination criterion (default 0.001)
%        shrinking (h) : whether to use the shrinking heuristics, 0 or 1 (default 1)
%        probability_estimates (b): whether to train a SVC or SVR model for probability
%             estimates, 0 or 1 (default 0)
%        weight  (wi) : the parameter C of class i to weight*C, for C-SVC (default 1)
%        n        (v) : n-fold cross validation mode
%        quiet    (q) : quiet mode (no outputs, default 1)
%        cvtimelimit (x) : maximum number of seconds to allow for any
%                       iteration of cross-validation testing (default 10)
%        waitbar : [ 'off' | {'on'} ] governs wait bar during optimization
%                   and predictions.
%
%  OUTPUTS:
%     model = LIBSVM model (if not run in cross-validation mode)
%     cv    = cross validation accuracy (%), if run in cross-validation mode
%     pred  = LIBSVM prediction (if model is passed)
%
%I/O: model = (x,y,options)
%I/O: cv    = (x,y,options)
%I/O: pred  = (x,y,model,options)

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
  options.svmtype    = 'C-SVC';
  options.kerneltype = 2;    %radial basis fn
  options.degree     = 3;
  options.coef0     = 0;
  options.cost      = 1;
  options.nu        = 0.5;
  options.epsilon   = 0.1;
  options.cachesize = 100;
  options.terminationepsilon = 0.001;
  options.shrinking = 1;
  options.probabilityestimates = 0;   % This slows training down
  options.quiet     = 1;
  options.cvtimelimit = 10;

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
        varargin = {varargin{1},varargin{2},[],svmengine('options')};
        mode = 'train';    % do train
      end
    case 3  %three inputs
      % Case A: (x,y,options)
      % Case B: (x,model,options)
      % Case C: (x,y,model)
      if  isa(varargin{3},'struct')
        if ~isjava(varargin{2})
          % Must be case A: (x,y,options)
          varargin = {varargin{1},varargin{2},[],varargin{3}};
          mode = 'train';    % do train
        else
          % Case B: (x,model,options)
          varargin = {varargin{1},[],varargin{2},varargin{3}};
          mode = 'predict';    % do prediction
        end
      elseif (isjava(varargin{3}))
        % Must be case B: (x,y, model)
        varargin = {varargin{1:3},svmengine('options')};
        mode = 'predict';    % do prediction
      else
        error(['Input arguments not recognized. Type: ''help ' mfilename ''''])
      end
    case 4   %four inputs
      %Case A: (x,y,model,options)
      if(isnumeric(varargin{1}) & isjava(varargin{3}) & isa(varargin{4},'struct'))
        mode = 'predict';    % do prediction
      else
        error(['Input arguments not recognized. Type: ''help ' mfilename ''''])
      end
    otherwise
      error(['Input arguments not recognized. Type: ''help ' mfilename ''''])
      
  end
  
  % Ensure arg names and values are in libsvm's expected form
  if ~isfield(varargin{4},'norecon') | ~varargin{4}.norecon
    varargin{4} = reconopts(varargin{4},mfilename,0);
    varargin{4} = standardizeToLibsvmArgs(varargin{4});
    % Remove parameters which are not appropriate for the svm type
    varargin{4} = removeExtraSvmParams(varargin{4});
    % Is this an optimize parameter request. First standardize names!
  end
  if strcmp(mode,'train') & isOptimize(varargin{4})
    mode = 'optimize';
  end

  if strcmp(mode, 'predict')  %predictmode
    predictions = svmPredict(varargin{1}, varargin{2}, varargin{3}, varargin{4});  %(x, y, model, options);
    varargout{1} = predictions;
  elseif strcmp(mode, 'train') | strcmp(mode, 'crossvalidate')
    modelOrCv = svmTrain(varargin{1}, varargin{2}, varargin{4}); %x, y, options)
    varargout{1} = modelOrCv;
  elseif strcmp(mode, 'optimize')
    [cvResult] = svmOptimize(varargin{1}, varargin{2}, varargin{4}); %x, y, options)
    varargout{1} = cvResult;
  end
  
catch
  lerror = lasterror;
  lerror.message = ['Error using svmengine: ' lerror.message];
  rethrow(lerror);
end
