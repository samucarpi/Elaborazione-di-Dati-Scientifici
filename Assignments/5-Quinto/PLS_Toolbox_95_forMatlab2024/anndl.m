function model = anndl(varargin)
%ANNDL Predictions based on Deep Learning Artificial Neural Networks.
% Similar to ANN, build a neural network from input X and Y block the optimal number
% of learning iterations (based on cross-validation) for specified number
% of layers and layer nodes. Alternatively, if a model is passed in ANNDL
% makes a Y prediction for an input test X block.
% The ANNDL model contains quantities (weights etc) calculated from the
% calibration data. If a model structure is passed in then these do not
% have to be re-calculated. This implementation uses third party software:
% Scikit-Learn and Tensorflow. These neural networks tend to work well
% with more hidden layers and larger node sizes. For more information
% regarding the Scikit-Learn implementation, visit
% [https://scikit-learn.org/stable/modules/generated/sklearn.neural_network.MLPRegressor.html].
% For more information regarding the Tensorflow implementation, please
% visit: [https://www.tensorflow.org/api_docs/python/tf/keras/Sequential].
%
% INPUTS:
%        x  = X-block (predictor block) class "double" or "dataset",
%        y  = Y-block (predicted block) class "double" or "dataset",
%    model  = previously generated model (when applying model to new data)
%
%  Optional input (options) is a
%  structure containing one or more of the following fields:
%         display : [ 'off' |{'on'}] Governs display
%           plots : [{'none' | 'final']  %Governs plots to make
%     blockdetails: [ {'standard'} | 'all' ]  Extent of detail included in model.
%                     'standard' keeps only y-block, 'all' keeps both x- and y- blocks
%         waitbar : [ 'off' |{'auto'}| 'on' ] governs use of waitbar during
%                   analysis. 'auto' shows waitbar if delay will likely be
%                   longer than a reasonable waiting period.
%        warnings : [{'off'} | 'on'] Silence or display any potential Python warnings.
%       algorithm : [ {'sklearn'} | 'tensorflow' ] Specify which implementation of
%                     ANNDL to use. Both have no limitations on the number
%                     of hidden layers used. The Scikit-Learn
%                     implementation uses their MLPRegressor object, while
%                     the Tensorflow model is a sequential model that can
%                     be built using various layer types.
%           cvskip: [{[]}] Control the step size in cross-validation over
%                   the number of nodes in the first hidden layer. Empty is the
%                   default, so it will incorporate a 'smart rule' in determining
%                   what nodes to cross-validate over. More on this at
%                   [https://wiki.eigenvector.com/index.php?title=Anndl#Cross-validation].
%                   Otherwise, an integer can be passed to specify the increment
%                   between nodes to cross-validate over. 
%      compression: [{'none'}| 'pca' | 'pls' ] type of data compression
%                    to perform on the x-block prior to calculaing or
%                    applying the ANNDL model. 'pca' uses a simple PCA
%                    model to compress the information. 'pls' uses a pls
%                    model. Compression can make the ANNDL more stable and
%                    less prone to overfitting.
%    compressncomp: [ 1 ] Number of latent variables (or principal
%                    components to include in the compression model).
%       compressmd: [ 'no' |{'yes'}] Use Mahalnobis Distance corrected
%               sk: Sub-structure for Python sklearn ANNDL parameters. Used
%                    only when algorithm='sklearn'.
%                   sk.activation: [{'relu'} 'identity' 'tanh' 'logistic'] Type of activation function applied to the weights.
%                   sk.solver: [{'adam'} 'lbfgs' 'sgd'] Solver for weight optimization.
%                   sk.alpha: [{1.0000e-04}] L2 Penalty parameter.
%                   sk.max_iter: [{200}] Maximum iterations, determined by tol or this parameter.
%                   sk.hidden_layer_sizes: {[100]} Vector of node sizes. The ith element represent the number of nodes in the ith hidden layer in the network.
%                   sk.random_state: [{1}] Random seed number. Set this to a number for reproducibility.
%                   sk.tol: [{1.0000e-04}] Tolerance for optimization.
%                   sk.learning_rate_init: [{1.0000e-03}] Initial learning
%                    rate
%                   sk.batch_size: [{12}] Number of samples in each of the minibatches.
%               tf: Sub-structure for Python tensorflow ANNDL parameters.
%                   tf.activation: [{'relu'} 'linear' 'tanh' 'sigmoid'] Type of activation function applied to the weights.
%                   tf.optimizer: [{'adam'} 'adamax' 'rmsprop' 'sgd'] Solver for weight optimization.
%                   tf.loss: [{'mean_squared_error'} 'mean_absolute_error' 'log_cosh'] Choice of loss function to be minimized.
%                   tf.epochs: [{200}] Maximum number of training iterations, determined by min_delta or this parameter.
%                   tf.hidden_layer: {[struct('type','Dense','units',100)]} Cell array of structs, each struct representing a hidden layer. Accepted fields include 'type' (each layer needs this) 'units' (all layer types need this, except for 'Flatten'), 'size' (for pooling layer types this is pool_size, for convolutional layers this is kernel_size).
%                   tf.random_state: [{1}] Random seed number. Set this to a number for reproducibility.
%                   tf.min_delta: [{1.0000e-04}] Minimum change in the loss to count as an improvement.
%                   tf.learning_rate_init: [{1.0000e-03}] Initial learning rate.
%                   tf.batch_size: [{12}] Number of samples in each of the minibatches.
%
%      NOTE: There are sub-structures for each 'algorithm'. The sub-structures
%            include additional input parameters (additional inputs needed by
%            the function) as well as optional inputs (i.e., the options 
%            structure for that particular function).
%
%      Example: To change options for the sklearn ANNDL, set algorithm to
%      'sklearn' and modify the sk sub-structure:
%         >>>opts = anndl('options')
%         >>>opts.sk.activation = 'tanh'
%
%      Example: To change options for the tensorflow ANNDL, set algorithm to
%      'tensorflow' and modify the tf sub-structure:
%         >>>opts = anndl('options')
%         >>>opts.tf.activation = 'tanh'
%
%  OUTPUT:
%     model = standard model structure containing the ANNDL model (See MODELSTRUCT)
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: [model] = anndl(x,y,options);
%I/O:  [pred] = anndl(x,model,options);
%I/O: [valid] = anndl(x,y,model,options);
%
%See also: SVM ANN

% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Start Input
if nargin==0  % LAUNCH GUI
  analysis('anndl')
  return
end

if ischar(varargin{1}) %Help, Demo, Options
  %Short circuit to get default layer settings.
  if strcmpi(varargin{1},'getlayerdefaults')
    if nargin==1
      model = getlayerdefaults;
    else
      model = getlayerdefaults(varargin{2});
    end
    return
  end
  options = [];
  options.name = 'options';
  options.display = 'on';
  options.plots   = 'none';
  options.blockdetails  = 'standard';  %level of details
  options.cvi      = [];
  options.cvskip   = [];
  options.preprocessing = {[] []};  %See preprocess
  options.compression   = 'none';
  options.compressncomp = 1;
  options.compressmd    = 'yes';
  options.waitbar       = 'on';
  options.warnings      = 'off';
  options.definitions   = @optiondefs;
  options.algorithm     = 'sklearn'; %tensorflow
  options.sk.activation           = 'relu';
  options.sk.solver               = 'adam';
  options.sk.alpha                = 0.0001;
  options.sk.max_iter             = 200;
  options.sk.hidden_layer_sizes   = {100};
  options.sk.random_state         = 1;
  options.sk.tol                  = 0.0001;
  options.sk.learning_rate_init   = 0.001;
  options.sk.batch_size           = 12;
  options.tf.activation           = 'relu';
  options.tf.optimizer            = 'adam';
  options.tf.loss                 = 'mean_squared_error';
  options.tf.epochs               = 200;
  options.tf.hidden_layer         = {struct('type','Dense','units',100)};
  options.tf.random_state         = 1;
  options.tf.min_delta            = 0.0001;
  options.tf.batch_size           = 12;
  options.tf.learning_rate        = 0.001;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; model = evriio(mfilename,varargin{1},options); end
  return;
end

% parse input parameters
[x,y,xt,yt,model,inopts,predictmode] = parsevarargin(varargin);

inopts = reconopts(inopts,mfilename);

inopts.blockdetails = lower(inopts.blockdetails);
switch inopts.blockdetails
  case {'standard','all'};
  otherwise
    error(['OPTIONS.BLOCKDETAILS not recognized.'])
end

% Check model format
if ismodel(model);
  try
    model = updatemod(model);        %make sure it's v3.0 model
  catch
    error(['Input MODEL not recognized.'])
  end
else
  %NOT a model (none passed)
  predictmode = 0;
end

% Convert x and y to dataset, if not already
[x,y, haveyblock] = converttodso(x,y, model, inopts);

[datasource{1:2}] = getdatasource(x,y);

if isempty(inopts.preprocessing);
  inopts.preprocessing = {[] []};  %reinterpet as empty for both blocks
end
if ~isa(inopts.preprocessing,'cell')
  inopts.preprocessing = {inopts.preprocessing};
end
if length(inopts.preprocessing)==1;
  inopts.preprocessing = inopts.preprocessing([1 1]);
  % Special case: if user passed only X preprocessing use same for X and Y
end
% y-block preprocessing is NOT used with classification SVM
if isclassification(inopts)
  inopts.preprocessing{2} = [];  %DROP ANY y-block preprocessing
end
preprocessing = inopts.preprocessing;

% reuse the input model when model_inout, adding ypred, Q and Tsq.
if ~predictmode
  
  if mdcheck(x);
    if strcmp(inopts.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess". Results may be affected by this action.'); end
    [flag,missmap,x] = mdcheck(x);
    if length(y.include{1}) ~= length(x.include{1})
      %copy any changes over to y-block
      y.include{1} = x.include{1};
    end
  end
  
  if ~isempty(preprocessing{2});
    [ypp,preprocessing{2}] = preprocess('calibrate',preprocessing{2},y);
  else
    ypp = y;
  end
  if ~isempty(preprocessing{1});
    [xpp,preprocessing{1}] = preprocess('calibrate',preprocessing{1},x,ypp);
  else
    xpp = x;
  end
  
  % compression
  [xpp, commodel] = getcompressionmodel(xpp, ypp, inopts);
  
  % Train ANNDL on the included data
  [W, niter, rmsecviter, ypred0, ycvpp] =  train(xpp, ypp, inopts);
  
  model = anndlstruct(inopts.algorithm);
  model.detail.anndl.W     = W;
  model.detail.anndl.niter = niter;
  model.detail.anndl.rmsecviter = rmsecviter;
  % rmsecviter are rmse on scaled y, so only usable internally to the model.
  % Similarly for rmsec and rmsecv;
  model.pred          = {[] ypred0};
  
  model.detail.data = {x y};
  model = copydsfields(x,model,[],{1 1});
  model = copydsfields(y,model,[],{1 2});
  model.detail.includ{1,2} = x.include{1};   %x-includ samples for y samples too
  model.datasource = datasource;
  model.detail.preprocessing = preprocessing;   %copy calibrated preprocessing info into model
  model.detail.compressionmodel = commodel;
  
  % Calculate rmsecv using ycv (preprocessed) for the optimal learn cycles
  
  %W.hid is a tuple, cast to cell to index and get nhid1
  %nhidvec = cell(W.hid);
  nhid1 = getanndlnhidone(inopts);
  model.detail.rmsecv = nan(1, nhid1); 
  if ~isempty(ycvpp)
    ycv = preprocess('undo',model.detail.preprocessing{2}, ycvpp);
    yincl = y.data(y.include{1},y.include{2});
    model.detail.rmsecv(1, nhid1) = rmse(yincl(:), ycv.data(:));;
  end
  
  %Set time and date.
  model.date = date;
  model.time = clock;
  %copy options into model only if no model passed in
  model.detail.options = inopts;
  
else
  % have model, do predict
  if ~strcmpi(model.modeltype,'anndl') & ~strcmpi(model.modeltype,'anndlda')
    if strcmpi(model.modeltype,'anndlpred'); %%% need to modify
      model.modeltype = 'ANNDL';
    else
      error('Input MODEL is not a ANNDL model');
    end
  end
  
  %check data size and for missing variables
  if size(x.data,2)~=model.datasource{1}.size(1,2)
    error('Variables included in data do not match variables expected by model');
  elseif length(x.include{2,1})~=length(model.detail.includ{2,1}) | any(x.include{2,1} ~= model.detail.includ{2,1});
    missing = setdiff(model.detail.includ{2,1},x.include{2,1});
    x.data(:,missing) = nan;  %replace expected but missing data with NaN's to force replacement
    x.include{2,1} = model.detail.includ{2,1};
  end
  
  if mdcheck(x.data(:,x.include{2,1}));
    if strcmp(inopts.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess" from existing model. Results may be affected by this action.'); end
    x = replacevars(model,x);
  end
  
  preprocessing = model.detail.preprocessing;   %get preprocessing from model
  if haveyblock & ~isempty(preprocessing{2});
    [ypp]                           = preprocess('apply',preprocessing{2},y);
  else
    ypp = y;
  end
  if ~isempty(preprocessing{1});
    [xpp]                           = preprocess('apply',preprocessing{1},x);
  else
    xpp = x;
  end
  
  if ~isempty(model.detail.compressionmodel)
    [xpp, model] = applycompressionmodel(xpp, model);
  end
  
  indsx = xpp.include;
  
  %copy info
  model = copydsfields(x,model,1,{1 1});
  model.detail.includ{1,2} = x.include{1};   %x-includ samples for y samples too
  model.datasource = datasource;
  
  %Update time and date.
  model.date = date;
  model.time = clock;
  
  % model was input and was applied to new data. Make predictions
  [ypred] = apply(xpp.data(:, indsx{2:end}), model.detail.anndl.W,model.detail.options); % Make predictions for all samples, included or not.
  
  model.detail.data   = {x y};
  model.pred  = {[] ypred};    % preprocessed yp. Will be unprocessed later
  % model.rmsep is set later in calcystats
end   % end if ~predict

%handle model blockdetails
if strcmp('standard', lower(inopts.blockdetails))
  model.detail.data{1} = [];
end

% calcystats expects its third and fourth args to be preprocessed.
ypredpp = model.pred{2};
model.pred{2} = preprocess('undo',model.detail.preprocessing{2},model.pred{2});
model.pred{2} = model.pred{1,2}.data;
model = calcystats(model,predictmode,ypp,ypredpp);
% if ~predictmode
%   %add info to ssq table's y-columns
%   model.detail.ssq(end,4:5) = [nan nan];
% end

%label as prediction
if predictmode
  model.modeltype = [model.modeltype '_PRED'];
else
  model = addhelpyvars(model);
end


%--------------------------------------------------------------------------
function [W, niter, rmsecviter, yp, ycv] =  train(x,y, opts)
% TRAINING ANNDL using Forward-Feed Neural Network and backpropagation training.
% x and y are datasets

displayon = strcmp(opts.display, 'on');

% Non dso input x,y have been converted to DSOs
indsx = x.includ;

if ~isempty(opts.cvi) & isnumeric(opts.cvi) & length(opts.cvi)==size(x,1);
  opts.cvi = opts.cvi(indsx{1});
end
[yp, niter, rmsecviter, ycv, W] = buildmodel(x,y,opts);

%{
switch opts.algorithm
  case 'sklearn'
    [yp, niter, rmsecviter, ycv, W] = buildmlpregressor(x,y,opts);
  case 'tensorflow'
    [yp, niter, rmsecviter, ycv, W] = buildtensorflow(x,y,opts);
end
%}


%--------------------------------------------------------------------------
function [x,y, haveyblock] = converttodso(x,y, model, options)
%C) CHECK Data Inputs
if isa(x,'double')      %convert x and y to DataSets
  x        = dataset(x);
  x.name   = inputname(1);
  x.author = 'ANNDL';
elseif ~isa(x,'dataset')
  error(['Input X must be class ''double'' or ''dataset''.'])
end
%{
if ndims(x.data)>2
  error(['Input X must contain a 2-way array. Input has ',int2str(ndims(x.data)),' modes.'])
end
%}
if ~isempty(y);
  haveyblock = 1;
  if isa(y,'double') | isa(y,'logical')
    y        = dataset(y);
    y.name   = inputname(2);
    y.author = 'ANNDL';
  elseif ~isa(y,'dataset')
    error(['Input Y must be class ''double'', ''logical'' or ''dataset''.'])
  end
  
  if isa(y.data,'logical');
    y.data = double(y.data);
  end
  if ndims(y.data)>2
    error(['Input Y must contain a 2-way array. Input has ',int2str(ndims(y.data)),' modes.'])
  end
  if size(x.data,1)~=size(y.data,1)
    error('Number of samples in X and Y must be equal.')
  end
  %Check INCLUD fields of X and Y
  i       = intersect(x.includ{1},y.includ{1});
  if ( length(i)~=length(x.includ{1,1}) | ...
      length(i)~=length(y.includ{1,1}) )
    if (strcmp(lower(options.display),'on')|options.display==1)
      disp('Warning: Number of samples included in X and Y not equal.')
      disp('Using intersection of included samples.')
    end
    x.includ{1,1} = i;
    y.includ{1,1} = i;
  end
  %Change include fields in y dataset. Confirm there are enough y columns before trying.
  if ismodel(model)
    if size(y.data,2)==length(model.detail.includ{2,2})
      %SPECIAL CASE - ignore the y-block column include field if the
      %y-block contains the same number of columns as the include field.
      model.detail.includ{2,2} = 1:size(y.data,2);
    else
      if size(y.data,2) < length(model.detail.includ{2,2})
        %trap this one error to give more diagnostic information than the
        %error below gives
        error('Y-block columns included in model do not match number of columns in test set.');
      end
      try
        y.include{2} = model.detail.includ{2,2};
      catch
        error('Model include field selections will not work with current Y-block.');
      end
    end
  end
else    %empty y = NOT haveyblock mode (predict ONLY)
  haveyblock = 0;
end


%--------------------------------------------------------------------------
function outstruct = anndlstruct(algorithm)
switch algorithm
  case 'sklearn'
    outstruct = modelstruct('anndl','sk');
  case 'tensorflow'
    outstruct = modelstruct('anndl','tf');
  otherwise
    error(['Unknown algorithm type: ' algorithm]);
end

%--------------------------------------------------------------------------
function [stats] = rms2(y, yp, yt, ytp)
%
% Do Goodness-of-Fit calculations for all y's
%
%	stats = [Y-number RMS-train R2-train RMS-test R2-test]
%
[n, m] = size(y);
[n2, m2] = size(yt);
stats = zeros(m,5);
for i = 1:m
  ssq(i) = ((y(:,i)-yp(:,i))'*(y(:,i)-yp(:,i))/n);
  var(i) = std(y(:,i))^2;
  r2(i) = (var(i)-ssq(i))/var(i);
  ssqt(i) = ((yt(:,i)-ytp(:,i))'*(yt(:,i)-ytp(:,i))/n2);
  vart(i) = std(yt(:,i))^2;
  r2t(i) = (vart(i)-ssqt(i))/vart(i);
  stats(i,:) = [i ssq(i)^0.5 r2(i) ssqt(i)^0.5 r2t(i)];
end


%-------------------------------------------------------------

function [yp] = pred(xin, W,opts);
%
% Apply using evriPyClient

client = evriPyClient(opts, W.meta);
client = client.apply(xin);
yp = client.validation_pred;
% Make prediction (cast, and reshape), and un-scale y
yp = reshape(yp, [], W.y_col_dim);


%--------------------------------------------------------------------------
function [yp, hid] = apply(xin, W, opts);
%
% Make prediction using appropriate ANNDL implementation
%
%	Input x and output y in REAL NON-SCALED UNITS
%
%		 yp = predmlpregressor(x, W);
%
 
yp = pred(xin,W,opts);

%--------------------------------------------------------------------------
function [xpp, commodel] = getcompressionmodel(xpp, ypp, options)
%
% compress X-block data
%
% Apply data compression if desired by user
switch options.compression
  case {'pca' 'pls'}
    switch options.compression
      case 'pca'
        comopts = struct('display','off','plots','none','confidencelimit',0,'preprocessing',{{[] []}});
        commodel = pca(xpp,options.compressncomp,comopts);
      case 'pls'
        comopts = struct('display','off','plots','none','confidencelimit',0,'preprocessing',{{[] []}});
        if strcmp(lower(options.functionname), 'anndl')
          commodel = pls(xpp,ypp,options.compressncomp,comopts);
        else
          commodel = plsda(xpp,ypp,options.compressncomp,comopts);
        end
    end
    scores   = commodel.loads{1};
    if strcmp(options.compressmd,'yes')
      incl = commodel.detail.includ{1};
      eig  = std(scores(incl,:)).^2;
      commodel.detail.eig = eig;
      scores = scores*diag(1./sqrt(eig));
    else
      commodel.detail.eig = ones(1,size(scores,2));
    end
    xpp      = copydsfields(xpp,dataset(scores),1);
  otherwise
    commodel = [];
end


%--------------------------------------------------------------------------
function [result] = isclassification(args)
%ISCLASSIFICATION Test if args invoke classification type ANNDL analysis.
% isclassification returns true if ANNDL type is classification, false otherwise.
%I/O: out = isclassification(args_struct);

%Copyright Eigenvector Research, Inc. 2010-2019
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

result = false;
if isfield(args, 'functionname')
  result = strcmpi(args.functionname, 'anndlda');
end

%--------------------------------------------------------------------------
function [xpp, model] = applycompressionmodel(xpp, model)
%
% compress X-block data using supplied compression model
%
%apply any compression model found to data
commodel = model.detail.compressionmodel;
comopts  = struct('display','off','plots','none');
compred  = feval(lower(commodel.modeltype),xpp,commodel,comopts);
scores   = compred.loads{1};
scores   = scores*diag(1./sqrt(commodel.detail.eig));
xpp      = copydsfields(xpp,dataset(scores),1);
model.detail.compressionmodel = compred;

%--------------------------------------------------------------------------
function [x,y,xt,yt,model,inopts,predictmode] = parsevarargin(varargin)
%
%I/O: [model] = anndl(x,y,options);
%I/O: [ypred] = anndl(x,y,model);
%I/O: [ypred] = anndl(x,model,options);
%I/O: [ypred] = anndl(x,y,model,options);

x           = [];
y           = [];
xt          = [];
yt          = [];
model       = [];
inopts      = [];
predictmode = true;

varargin = varargin{1};
nargin = length(varargin);
switch nargin
  case 2  % 2 arg:
    %    anndl(x, model)
    %    anndl(x,y)
    if isdataset(varargin{1}) | isnumeric(varargin{1})
      if ismodel(varargin{2})
        % (x,model)
        x = varargin{1};
        model  = varargin{2};
        y = [];
        if ~isempty(model.detail.options)
          inopts = model.detail.options;
        else
          inopts = anndl('options');
        end
        predictmode = 1;
      elseif isdataset(varargin{2}) | isnumeric(varargin{2})
        % (x,y)
        x = varargin{1};
        y = varargin{2};
        inopts = anndl('options');
        model  = [];
        predictmode = 0;
      else
        error('anndl called with two arguments requires non-empty y or model as second argument.');
      end
    else
      error('anndl called with two arguments requires non-empty x data array.');
    end
    
  case 3 % 3 arg:
    %    [model] = anndl(x,y,options);
    %    [ypred] = anndl(x,model,options);
    %    [ypred] = anndl(x,y,model);
    if ismodel(varargin{3})
      % (x,y,model)
      x = varargin{1};
      y = varargin{2};
      model  = varargin{3};
      if ~isempty(model.detail.options)
        inopts = model.detail.options;
      else
        inopts = anndl('options');
      end
    elseif isstruct(varargin{3})
      if ismodel(varargin{2})
        % (x,model,options)
        x = varargin{1};
        y = [];
        model  = varargin{2};
        inopts = varargin{3};
        predictmode = 1;
      elseif isnumeric(varargin{2}) | isdataset(varargin{2})
        % (x,y,options)
        x = varargin{1};
        y = varargin{2};
        model  = [];
        inopts = varargin{3};
        predictmode = 0;
      else
        error('anndl called with 3 arguments has unexpected second argument.');
      end
    else
      error('anndl called with 3 arguments has unexpected third argument.');
    end
    
  case 4 % 4 arg:
    %    [ypred] = anndl(x, y, model, options);
    if ismodel(varargin{3}) & isstruct(varargin{4})
      % (x,y,model, options)
      x = varargin{1};
      y = varargin{2};
      model  = varargin{3};
      inopts  = varargin{4};
      predictmode = 1;
    else
      error('anndl called with 4 arguments has unexpected arguments.');
    end    
  otherwise
    error('anndl: unexpected number of arguments to function ("%s")', nargin);
end

%--------------------------------------------------------------------
function [yps, niter, rmsecviter, ycv, W] = buildmodel(x, y,opts)
displayon = strcmp(opts.display, 'on');
% Sklearn MLP Regressor

% Non dso input x,y have been converted to DSOs
indsx = x.includ;
indsy = y.includ;

% Build model using included data only
xd = x.data(indsx{:});
yd = y.data(indsy{:});

ysize = size(yd);
W.y_col_dim = ysize(2);

if strcmp(opts.algorithm,'sklearn') && size(xd,1)<=20 && ~strcmp(opts.sk.solver,'lbfgs')
  evritip('anndl_nsamples_solver','The current solver is not recommended when building a model on so few samples. Use ''lbfgs'' instead.',0);
end

% build client object
client = evriPyClient(opts);
% calibrate Python model object
client = client.calibrate(xd,x.data(:,indsx{2}),yd);
% extract information client
yps = client.calibration_pred;

W.meta = client.serialized_model;
W.loss = client.extractions.loss;
niter = client.extractions.niter;
rmsecviter = [];
ycv = [];

%--------------------------------------------------------------------------
function out = getlayerdefaults(mytype)
%Get default layer values and settings.
%            layer type           units       size
out =      {'Dense'               100         [];
            'Dropout'             .25         [];
            'Flatten'             []          [];
            'BatchNormalization'  []          [];
            'Conv1D'              100         [3];
            'Conv2D'              100         [3 3];
            'Conv3D'              100         [3 3 3];
            'MaxPooling1D'        []          [3];
            'MaxPooling2D'        []          [3 3];
            'MaxPooling3D'        []          [3 3 3];
            'AveragePooling1D'    []          [3];
            'AveragePooling2D'    []          [3 3]; 
            'AveragePooling3D'    []          [3 3 3]}; 
if nargin>0
  out = out(ismember(out(:,1),mytype),:);  
end

%--------------------------

function out = optiondefs()

defs = {
  %name                    tab              datatype        valid                            userlevel       description
  'display'                'Display'        'select'        {'on' 'off'}                     'novice'        'Governs level of display.';
  'plots'                  'Display'        'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
  'blockdetails'           'Standard'       'select'        {'standard' 'all'}               'novice'        'Extent of predictions and raw residuals included in model. ''standard'' = keeps only y-block, ''all'' keeps both x- and y- blocks.';
  'waitbar'                'Display'        'select'        {'on' 'off' 'auto'}              'novice'        'governs use of waitbar during analysis. ''auto'' shows waitbar if delay will likely be longer than a reasonable waiting period.';
  'warnings'               'Display'        'select'        {'on' 'off'}                     'novice'        'Silence or display any potential Python warnings.';
  'algorithm'              'Standard'       'select'        {'sklearn' 'tensorflow'}         'novice'        [{'Algorithm to use. ''sklearn'' is the default. ''sklearn''/''tensorflow'' use Python implemntations. '} getanndlcp];
  'cvskip'                 'Standard'       'double'        'int(1:inf)'                     'novice'        'Control the step size in cross-validation over the number of nodes in the first hidden layer. Empty is the default, so it will incorporate a ''smart rule'' in determining what nodes to cross-validate over. More on this at [https://wiki.eigenvector.com/index.php?title=Anndl#Cross-validation]. Otherwise, an integer can be passed to specify the increment between nodes to cross-validate over.'
  'compression'            'Compression'    'select'        {'none' 'pca' 'pls'}             'novice'        'Type of data compression to perform on the x-block prior to SVM model. Compression can make the SVM more stable and less prone to overfitting. ''PCA'' is a principal components model and ''PLS'' is a partial least squares model (which may give improved sensitivity).';
  'compressncomp'          'Compression'    'double'        'int(1:inf)'                     'novice'        'Number of latent variables or principal components to include in the compression model.'
  'compressmd'             'Compression'    'select'        {'no' 'yes'}                     'novice'        'Use Mahalnobis Distance corrected scores from compression model.'
  'sk.activation'          'Sklearn'        'select'        {'relu' 'tanh' 'logistic' 'identity'}  'novice'  'Activation function.'
  'sk.solver'              'Sklearn'        'select'        {'adam' 'lbfgs' 'sgd'}           'novice'        'Solver for weight optimization.'
  'sk.alpha'               'Sklearn'        'double'        'float(0:inf)'                   'novice'        'L2 penalty parameter.'
  'sk.max_iter'            'Sklearn'        'double'        'int(1:inf)'                     'novice'        'Maximum iterations, determined by tol or this parameter.'
  'sk.hidden_layer_sizes'  'Sklearn'        'matrix'        ''                               'novice'        'Vector of node sizes. The ith element represent the number of nodes in the ith hidden layer in the network.'
  'sk.random_state'        'Sklearn'        'double'        'float(0:inf)'                   'novice'        'Random seed number. Set this to a number for reproducibility.'
  'sk.tol'                 'Sklearn'        'double'        'float(0:inf)'                   'novice'        'Tolerance for optimization.'
  'sk.learning_rate_init'  'Sklearn'        'double'        'float(0:inf)'                   'novice'        'Learning rate for controlling step size in the updating of weights.'
  'sk.batch_size'          'Sklearn'        'double'        'int(1:inf)'                     'novice'        'Size of minibatches for the solver.'
  'tf.activation'          'Tensorflow'     'select'        {'relu' 'tanh' 'sigmoid' 'linear'}  'novice'     'Activation function.'
  'tf.optimizer'           'Tensorflow'     'select'        {'adam' 'adamax' 'rmsprop' 'sgd'}   'novice'     'Solver for weight optimization.'
  'tf.epochs'              'Tensorflow'     'double'        'int(1:inf)'                     'novice'        'Maximum iterations, determined by tol or this parameter.'
  'tf.loss'                'Tensorflow'     'select'        {'mean_squared_error' 'mean_absolute_error' 'log_cosh'} 'novice' 'Choice of loss function to be minimized.'
  'tf.hidden_layer'        'Tensorflow'     'matrix'        ''                               'novice'        'Cell array of structs, each struct representing a hidden layer. Accepted fields include ''type'' (each layer needs this) ''units'' (all layer types need this, except for ''Flatten''), ''size'' (for pooling layer types this is pool_size, for convolutional layers this is kernel_size).'
  'tf.random_state'        'Tensorflow'     'double'        'float(0:inf)'                   'novice'        'Random seed number. Set this to a number for reproducibility.'
  'tf.min_delta'           'Tensorflow'     'double'        'float(0:inf)'                   'novice'        'tf.min_delta: [{1.0000e-04}] Minimum change in the loss to count as an improvement.'
  'tf.learning_rate'       'Tensorflow'     'double'        'float(0:inf)'                   'novice'        'Learning rate for controlling step size in the updating of weights.'
  'tf.batch_size'          'Tensorflow'     'double'        'int(1:inf)'                     'novice'        'Size of minibatches for the solver.'

  };

out = makesubops(defs);

%-----------------------------------------------------------------
function out = getanndlcp()

out  = {'This ANNDL method in PLS_Toolbox uses the Scikit-Learn framework, provided '...
  'by Scikit-Learn API, under the terms of the BSD 3-Clause license. ANNDL also uses the Tensorflow framework, provided '...
  'by Tensorflow API, under the terms of the Apache 2.0 license.'};

