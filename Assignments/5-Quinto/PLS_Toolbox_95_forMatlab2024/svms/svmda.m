function varargout = svmda(varargin)
%SVMDA Support Vector Machine for classification (Discriminant Analysis).
%  SVM performs calibration and application of Support Vector Machine (SVM)
%  models for classification. These are non-linear models which consist of
%  a number of support vectors (essentially samples selected from the
%  calibration set) and non-linear model coefficients which define the
%  non-linear mapping of variables in the input x-block to allow prediction
%  of the classification as passed in either the classes of the x-block or
%  in a y-block which contains numerical classes.
%
% INPUTS:  
%        x  = X-block (predictor block) class "double" or "dataset",
%        y  = Y-block numerical classes as class "double" or "dataset". If
%             omitted in a calibration call, the x-block must be a dataset
%             object with classes in the first mode (samples). y can always
%             be omitted in a prediction call (when a model is passed)
%             If y is omitted in a prediction call, x will be checked for
%             classes. If found, these classes will be assumed to be the
%             ones corresponding to the model.
%    model  = previously generated model (when applying model to new data)
%
% OPTIONAL INPUTS:
%   options = structure array with the following fields:
%            display: [ 'off' | {'on'} ]      governs level of display to command window.
%              plots: [ 'none' | {'final'} ]  governs level of plotting.
%          algorithm: [ 'libsvm' ] algorithm to use. libsvm is default and currently only option.
%         kerneltype: [ 'linear' | 'rbf' ] SVM kernel to use. 'rbf' is default.
%            svmtype: [ {'c-svc'} | 'nu-svc' ] Type of SVM to apply.
% probabilityestimates: 1; whether to train a SVC or SVR model for probability
%                           estimates, 0 or 1 (default 1)"
%      preprocessing: {[]}  preprocessing structures for x block (see PREPROCESS).
%                     NOTE that y-block preprocessing is NOT used with SVMs
%                       Any y-preprocessing will be ignored.
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
%                     gamma or nu. Default is 10;
%                     A second timelimit = 30*cvtimelimit is applied to any 
%                     svm calibration calculation which is not part of 
%                     cross-validation.
%             splits: Number of subsets to divide data into when applying n-fold cross
%                     validation. Default is 5.
%              gamma: Value(s) to use for LIBSVM kernel 'gamma' parameter.
%                     Gamma controls the shape of the separating hyperplane.
%                     Increasing gamma usually increases number of support
%                     vectors. Default is 15 values from 10^-6 to 10, spaced 
%                     uniformly in log.
%               cost: Value(s) to use for LIBSVM 'c' parameter. 
%                     C [0 -> inf] which indicates how strongly misclassifications 
%                     should be penalized. Larger values force closer fitting
%                     to calibration/training data.
%                     Default is 11 values from 10^-3 to 100, spaced uniformly in log.
%                 nu: Value(s) to use for LIBSVM 'n' parameter. 
%                     Nu (0 -> 1] indicates a lower bound on the number of support 
%                     vectors to use, given as a fraction of total calibration
%                     samples, and an upper bound on the fraction of training
%                     samples which are errors (misclassified).
%                     allowed. Default is the set of values [0.2, 0.5, 0.8].
%         classset: [ 1 ] indicates which class set in x to use when no
%                   y-block is provided. 
%  strictthreshold: [0.5] Probability threshold for assigning a sample to
%                     a class. Affects model.classification.inclass.
%   predictionrule: { {'mostprobable'} | 'strict' ] governs which
%                   classification prediction statistics appear first in
%                   the confusion matrix and confusion table summaries.
%
% OUTPUTS:
%     model = standard model structure containing the SVM model (See MODELSTRUCT).
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: model = svmda(x,options);          %identifies model using classes in x
%I/O: model = svmda(x,y,options);        %identifies model using y for classes 
%I/O: pred  = svmda(x,model,options);    %makes predictions with a new X-block
%I/O: pred  = svmda(x,y,model,options);  %performs a "test" call with a new X-block with known y-classes 
%
%See also: KNN, LWR, PLSDA, SIMCA, SVM

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0  % LAUNCH GUI
  analysis('svmda')
  return
end
if ischar(varargin{1}) %Help, Demo, Options
  options = svm('options');
  options = rmfield(options, 'epsilon'); % svm classification does not use epsilon
  options.svmtype = 'c-svc';
  options.probabilityestimates = 1;
  options.classset = 1;
  options.strictthreshold = 0.5;    %probability threshold for class assign
  options.predictionrule = 'mostprobable';
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
  
end

defaultOptions = svmda('options');

%force discriminant analysis flag
optsind = [];
if nargin>1
  for j=2:nargin
    if ~ismodel(varargin{j}) & isstruct(varargin{j})
      %this the options structure?
      optsind = j;
      if isfield(varargin{j},'svmtype')
        %use the existing svmtype
        type = varargin{j}.svmtype;
      else
        %no svmtype, force a defult
        type = defaultOptions.svmtype;
      end
      if ~ismember(lower(type),{'c-svc' 'nu-svc'})
        error('SVMTYPE option must be either ''c-svc'' and ''nu-svc''');
      end
      varargin{j}.svmtype = type;  %assign the svmtype
      varargin{j} = reconopts(varargin{j},defaultOptions);
      break;
    end
  end
end
if isempty(optsind) & ~ischar(varargin{1})
  % If no options found (and not a string command coming in)
  % add default options structure at the end
  varargin{end+1} = defaultOptions;
  if nargin>1
    % If a model was passed in copy the display and plots options from it.
    for j=2:nargin
      if ismodel(varargin{j}) & ~isempty(varargin{j}.detail.options)
        modopts = varargin{j}.detail.options;
        if isfield(modopts, 'display') & ~isempty(modopts.display)
          varargin{end}.display = modopts.display;
        end
        if isfield(modopts, 'plots') & ~isempty(modopts.plots)
          varargin{end}.plots = modopts.plots;
        end
      end
    end
  end
end


%call SVM
if nargout>0
  [varargout{1:nargout}] = svm(varargin{:});
else
  svm(varargin{:});
end

