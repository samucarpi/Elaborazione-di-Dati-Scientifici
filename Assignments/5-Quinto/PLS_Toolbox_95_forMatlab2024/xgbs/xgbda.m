function varargout = xgbda(varargin)
%XGBDA Gradient Boosted Tree Ensemble for classification (Discriminant Analysis).
%  XGBDA performs calibration and application of gradient boosted decision
%  tree models for classification. These are non-linear models which
%  predict the probability of a test sample belonging to each of the
%  modeled classes, hence they predict the class of a test sample.
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
%          algorithm: [ 'xgboost' ] algorithm to use. xgboost is default and currently only option.
%            xgbtype: [ {'xgbc'} ] Type of XGB to apply.
%      preprocessing: {[]}  preprocessing structures for x block (see PREPROCESS).
%                     NOTE that y-block preprocessing is NOT used with XGBs
%                       Any y-preprocessing will be ignored.
%        compression: [{'none'}| 'pca' | 'pls' ] type of data compression
%                      to perform on the x-block prior to calculaing or
%                      applying the XGB model. 'pca' uses a simple PCA
%                      model to compress the information. 'pls' uses
%                      either a pls or plsda model (depending on the
%                      xgbtype). Compression can make the XGB more stable
%                      and less prone to overfitting.
%      compressncomp: [ 1 ] Number of latent variables (or principal
%                      components to include in the compression model.
%         compressmd: [ 'no' |{'yes'}] Use Mahalnobis Distance corrected
%                      scores from compression model.
%             splits: Number of subsets to divide data into when applying n-fold cross
%                     validation. Default is 5.
%                eta: [{0.1}] Value(s) to use for XGBoost 'eta' parameter.
%                     Eta controls the learning rate of the gradient boosting.
%                     Values in range (0,1].
%          max_depth: [{6}] Value(s) to use for XGBoost 'max_depth' parameter. 
%                     Specifies the maximum depth allowed for the decision trees. 
%          num_round: [{500}] Value(s) to use for XGBoost 'num_round' parameter. 
%                     Specifies how many rounds of tree creation to perform.
%         classset: [ 1 ] indicates which class set in x to use when no
%                   y-block is provided. 
%  strictthreshold: [0.5] Probability threshold for assigning a sample to
%                     a class. Affects model.classification.inclass.
%   predictionrule: { {'mostprobable'} | 'strict' ] governs which
%                   classification prediction statistics appear first in
%                   the confusion matrix and confusion table summaries.
%
% OUTPUTS:
%     model = standard model structure containing the XGB model (See MODELSTRUCT).
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: model = xgbda(x,options);          %identifies model using classes in x
%I/O: model = xgbda(x,y,options);        %identifies model using y for classes 
%I/O: pred  = xgbda(x,model,options);    %makes predictions with a new X-block
%I/O: valid  = xgbda(x,y,model,options);  %performs a "test" call with a new X-block with known y-classes 
%
%See also: KNN, LWR, PLSDA, SIMCA, SVM, XGB

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0  % LAUNCH GUI
  analysis('xgbda')
  return
end
if ischar(varargin{1}) %Help, Demo, Options
  options = xgb('options');
  options.functionname = 'xgbda';
  options.xgbtype    = 'xgbc';
  options.objective = 'multi:softprob';  % use softmax classifier, a generalization of binary:logistic
  options.eval_metric= 'error';
  options.classset   = 1;
  options.strictthreshold = 0.5;    %probability threshold for class assign
  options.predictionrule  = 'mostprobable';
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
  
end

defaultOptions = xgbda('options');

%force discriminant analysis flag
optsind = [];
if nargin>1
  for j=2:nargin
    if ~ismodel(varargin{j}) & isstruct(varargin{j})
      %this the options structure?
      optsind = j;
      if isfield(varargin{j},'xgbtype')
        %use the existing xgbtype
        type = varargin{j}.xgbtype;
      else
        %no xgbtype, force a defult
        type = defaultOptions.xgbtype;
      end
      if ~ismember(lower(type),{'xgbc'})
        error('XGBTYPE option must be ''xgbc''');
      end
      varargin{j}.xgbtype = type;  %assign the xgbtype
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


%call XGB
if nargout>0
  [varargout{1:nargout}] = xgb(varargin{:});
else
  xgb(varargin{:});
end

