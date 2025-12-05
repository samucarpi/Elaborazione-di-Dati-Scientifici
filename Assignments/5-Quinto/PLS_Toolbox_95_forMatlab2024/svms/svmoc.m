function varargout = svmoc(varargin)
%SVMOC Support Vector Machine for one-class analysis.
% 
% One-class analysis using SVM. SVMOC performs calibration and application 
% of one-class Support Vector Machine models. SVMOC tries to represent the 
% distribution of a data set where all data points belong to the same class. 
% It does this by identifying an envelope which surrounds most of the 
% calibration data. A small, user-specified, fraction (nu) of the data is 
% left outside the distribution defining envelope. This fraction represents 
% the expected outlier fraction in the data. When the model is applied to a 
% new dataset any data points which fall outside the envelope are considered 
% outliers from the one class. Svmoc is implemented using the LIBSVM package.
%
% Note: svmoc is currently only available as a command-line function and is 
% not available as a graphical user interface (GUI) analysis method. 
%
% INPUTS:
%        x  = X-block (predictor block) class "double" or "dataset",
%        y  = Y-block (predicted block) class "double" or "dataset",
%    model  = previously generated model (when applying model to new data)
%
% OPTIONAL INPUTS:
%   options = structure array with the following fields:
%            display: [ 'off' | {'on'} ]      governs level of display to command window.
%              plots: [ 'none' | {'final'} ]  governs level of plotting.
%            waitbar: [ 'off' | {'on'} ] governs display of waitbar during
%                     optimization and predictions.
%          algorithm: [ 'libsvm' ] algorithm to use. libsvm is default and currently only option.
%      preprocessing: {[] []} preprocessing structures for x and y blocks
%                     (see PREPROCESS).
%        compression: [{'none'}| 'pca' | 'pls' ] type of data compression
%                      to perform on the x-block prior to calculaing or
%                      applying the SVM model. 'pca' uses a simple PCA
%                      model to compress the information. 'pls' uses
%                      either a pls or plsda model (depending on the
%                      svmtype). Compression can make the SVM more stable
%                      and less prone to overfitting.
%      compressncomp: [ 1 ] Number of latent variables (or principal
%                      components to include in the compression model.
%         compressmd: [ 'no' |{'yes'}] Use Mahalnobis Distance corrected
%                      scores from compression model.
%        cvtimelimit: Set a time limit (seconds) on individual cross-validation
%                     sub-calculation when searching over supplied SVM parameter
%                     ranges for optimal parameters. Only relevant if parameter
%                     ranges are used for SVM parameters such as cost, epsilon,
%                     gamma or nu. Default is 10 seconds;
%                     A second timelimit = 30*cvtimelimit is applied to any 
%                     svm calibration calculation which is not part of 
%                     cross-validation.
%              gamma: Value(s) to use for LIBSVM kernel 'gamma' parameter.
%                     Gamma controls the shape of the separating hyperplane.
%                     Increasing gamma usually increases number of support
%                     vectors. Default is 15 values from 10^-6 to 10, spaced 
%                     uniformly in log.
%               cost: Value(s) to use for LIBSVM 'c' parameter. Cost [0 ->inf]
%                     represents the penalty associated with errors larger than epsilon.
%                     Increasing cost value causes closer fitting to the
%                     calibration/training data.
%                     Default is 11 values from 10^-3 to 100, spaced uniformly in log.
%            epsilon: Value(s) to use for LIBSVM 'p' parameter (epsilon in loss function).
%                     In training the regression function there is no penalty 
%                     associated with points which are predicted within distance 
%                     epsilon from the actual value. Decreasing epsilon
%                     forces closer fitting to the calibration/training data.
%                     Default is the set of values [1.0, 0.1, 0.01].
%                 nu: Value(s) to use for LIBSVM 'n' parameter (nu of nu-SVR).
%                     Nu (0 -> 1] indicates a lower bound on the number of support 
%                     vectors to use, given as a fraction of total   
%                     calibration samples, and an upper bound on the fraction
%                     of training samples which are errors (poorly predicted).
%                     Default is the set of values [0.2, 0.5, 0.8].
%
% OUTPUTS:
%     model = standard model structure containing the SVMOC model (See MODELSTRUCT).
%      pred = structure array with predictions
%
%I/O: model = svmoc(x,options);          %identifies model using classes in x
%I/O: pred  = svmoc(x,model,options);    %makes predictions with a new X-block
%
%See also: SVM, SVMDA

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0  % LAUNCH GUI
  error('zero arg usage not supported by svmoc');
%   analysis('svmoc')   % TODO: analysis support for one-class SVM
%   return
end
if ischar(varargin{1}) %Help, Demo, Options
  options = svm('options');
  options = rmfield(options, 'epsilon'); % svm classification does not use epsilon
  options.svmtype              = 'one-class svm';
  options.nu                   = 0.05;               % 5% outliers
  options.probabilityestimates = 0;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
  
end

defaultOptions = svmoc('options');

optsind = [];
switch nargin
  case 1
    % (x)
    varargin{2} = defaultOptions;
    
  case 2
    % 2 inputs: (x, options)            // Calibration
    if isstruct(varargin{2}) & ~ismodel(varargin{2})
      %this the options structure?
      optsind = varargin{2};
      if isfield(varargin{2},'svmtype')
        %use the existing svmtype
        type = varargin{2}.svmtype;
      else
        %no svmtype, force a defult
        type = defaultOptions.svmtype;
      end
      if ~isoneclasssvm(defaultOptions)
        error('SVMTYPE option must be ''one-class svm''');
      end
      varargin{2}.svmtype = type;  %assign the svmtype
      varargin{2} = reconopts(varargin{2},defaultOptions);
    end
    if isempty(optsind) & ~ischar(varargin{1})
      %no options found (and not a string command coming in)?
      %add options structure at the end
      varargin{end+1} = defaultOptions;
    end
    
  case 3
    % 3 inputs: (x, model, options)     // Prediction
    % use varargin as-is, but update options
      varargin{3} = reconopts(varargin{3},defaultOptions);
    
  otherwise
    error(['Input arguments not recognized.'])
end

%call SVM
if nargout>0
  [varargout{1:nargout}] = svm(varargin{:});
else
  svm(varargin{:});
end

