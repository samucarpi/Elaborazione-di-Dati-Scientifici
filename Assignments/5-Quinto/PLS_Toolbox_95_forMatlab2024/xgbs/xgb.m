function varargout = xgb(varargin)
%XGB Gradient Boosted Tree (XGBoost) for regression or classification.
%
%  To choose between regression and classification, use the xgbtype option:
%    regression     : xgbtype = 'xgbr'
%    classification : xgbtype = 'xgbc'
%  It is recommended that classification be done through the xgbda
%  function.
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
%           waitbar : [ 'off' | {'on'} ] governs display of waitbar during
%                     optimization and predictions.
%          warnings : [{'off'} | 'on'] Silence or display any potential Python warnings.
%          algorithm: [ 'xgboost' ] algorithm to use. xgboost is default and currently only option.
%           classset: [ 1 ] indicates which class set in x to use when no y-block is provided. 
%            xgbtype: [ {'xgbr'} | 'xgbc' ] Type of XGB to apply.
%                     Default is 'xgbc' for classification, and 'xgbr' for regression.                   
% probabilityestimates: 1; whether to train a XGBC or XGBR model for probability
%                           estimates, 0 or 1 (default 0).
%      preprocessing: {[] []} preprocessing structures for x and y blocks
%                     (see PREPROCESS).
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
%                cvi: {{'rnd' 5}} Standard cross-validation cell (see crossval)
%                     defining a split method, number of splits, and number
%                     of iterations. This cross-validation is use both for
%                     parameter optimization and for error estimate on the
%                     final selected parameter values. 
%                     Alternatively, can be a vector with the same number 
%                     of elements as x has rows with integer values
%                     indicating CV subsets (see crossval).
%                eta: [{0.1}] Value(s) to use for XGBoost 'eta' parameter.
%                     Eta controls the learning rate of the gradient boosting.
%                     Values in range (0,1].
%          max_depth: [{6}] Value(s) to use for XGBoost 'max_depth' parameter. 
%                     Specifies the maximum depth allowed for the decision trees. 
%          num_round: [{500}] Value(s) to use for XGBoost 'num_round' parameter. 
%                     Specifies how many rounds of tree creation to perform.
%      random_state : [1] Random seed number. Set this to a number for reproducibility.
%
% OUTPUTS:
%     model = standard model structure containing the xgboost model (See MODELSTRUCT).
%             Feature scores are contained in model.detail.xgb.featurescores
% 
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: model = xgb(x,y,options);          %identifies model (calibration step)
%I/O: pred  = xgb(x,model,options);      %makes predictions with a new X-block
%I/O: valid  = xgb(x,y,model,options);    %performs a "test" call with a new X-block and known y-values
%
%See also: KNN, LWR, PLS, PLSDA, XGBDA, XGBENGINE

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%12/2009 Donal

%Start Input
if nargin==0  % LAUNCH GUI
  analysis('xgb')
  return
end
if ischar(varargin{1}) %Help, Demo, Options  
  %actual options
  options = [];
  options.name          = 'options';
  options.display       = 'on';     %Displays output to the command window
  options.plots         = 'final';  %Governs plots to make
  options.preprocessing = {[] []};  %See preprocess
  options.compression   = 'none';
  options.compressncomp = 1;
  options.compressmd    = 'yes';
  options.blockdetails  = 'standard';  %level of details
  options.waitbar       = 'on';
  options.warnings      = 'off';
  options.random_state  = 1;
  options.classset      = 1;
  options.definitions   = @optiondefs;
  
  % xgboost defaults (may be different from those set in xgbengine):
  options.algorithm  =  'xgboost';
  options.booster    =  'gbtree';
  options.cvi        = [];
  options.xgbtype    = 'xgbr';
  options.objective  = 'reg:linear';
  options.eval_metric= 'rmse';
  options.eta        = [0.1 0.3 0.5];  % XGBoost default=0.3, alias: learning_rate
  options.max_depth  = 1:6;            % XGBoost default=6
  options.num_round  = [100 300 500];  % The number of rounds for boosting
  options.alpha      = 0.;      % L1 regularization term on weights. Increasing this value will make model more conservative.
  options.lambda     = 1.0;     % L2 regularization term on weights. Increasing this value will make model more conservative.
  options.gamma      = 0.;      % Minimum loss reduction required to make a further partition on a leaf node of the tree.
                                % Increasing will make model more conservative
  options.scale_pos_weight = 1; % Control the balance of positive and negative weights, useful for unbalanced classes.
  options.silent     = 1;
  
  xgbengineoptions = xgbengine('options');
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
  
end

%A) Check Options Input
%   options.algorithm     = 'xgboost';
% Convert each case to the 3-arg form:   [x, y, opts],
% or, if model input, to the 4-arg form: [x, y, opts, model]
%
% Possible calls:
% 1 inputs: (x)                     // Calibration: must have y in x.classid{1}. Classification XGB
% 2 inputs: (x, model)              // Prediction
%           (x, options)            // Calibration
%           (x, y)                  // Calibration
% 3 inputs: (x,model,options)       // Prediction
%           (x,y,model)             // Prediction
%           (x,y, options)          // Calibration
% 4 inputs: (x,y,model,options)     // Prediction

predictmode = 0;
switch nargin
  case 1
    if ~isa(varargin{1},'dataset')
      error(['Input X must be a ''dataset''.'])
    else
      varargin = {varargin{1}, varargin{1}.class{1}',xgb('options')};
      x = varargin{1};
      y = varargin{2};
      inopts = varargin{3};
      predictmode = 0;
    end
  case 2
    % 2 inputs: (x, model)              // Prediction
    %           (x, options)            // Calibration
    %           (x, y)                  // Calibration
    if ismodel(varargin{2})
      % (x,model): convert to (x,[],options,model) OR (x,class,options,model)
      varargin = {varargin{1}, [], xgb('options'), varargin{2}};
      x = varargin{1};
      y = varargin{2};
      inopts = varargin{3};
      model  = varargin{4};
      predictmode = 1;
      
    elseif isa(varargin{2},'struct')
      if isa(varargin{1},'dataset')  |  isa(varargin{1},'double')
        % (x,opts): convert to (x, x.class{1},opts) if xgbc
        varargin = {varargin{1}, [], varargin{2}};
        x = varargin{1};
        y = varargin{2};
        inopts = varargin{3};
        model = [];
        predictmode = 0;
        
      else                                  %  unrecognized args
        error(['xgb called with two arguments requires non-empty y or dataset x with classes.']);
      end
    elseif isnumeric(varargin{2}) | isdataset(varargin{2})     % (x,y): convert to (x,y,options,[])
      varargin = {varargin{1}, varargin{2},xgb('options')};
      x = varargin{1};
      y = varargin{2};
      inopts = varargin{3};
      model = [];
      predictmode = 0;
    else
      error(['xgb called with two arguments expects x, y, or x, model, or x, options.']);
    end
    
  case 3  %three inputs
    if  ismodel(varargin{2}) & isstruct(varargin{3})
      % Must be case A: (x,model,options)
      varargin = {varargin{1},[],varargin{3},varargin{2}};
      x = varargin{1};
      y = varargin{2};
      inopts = varargin{3};
      model = varargin{4};
      predictmode = 1;    % do prediction
    elseif ismodel(varargin{3})
      % Must be case B: (x,y,model)
      varargin = {varargin{1},varargin{2},xgb('options'),varargin{3}};
      x = varargin{1};
      y = varargin{2};
      inopts = varargin{3};
      model = varargin{4};
      predictmode = 1;    % do prediction
    elseif isstruct(varargin{3}) & (isnumeric(varargin{2}) | isdataset(varargin{2}) | iscell(varargin{2}))
      % Must be case C: (x,y,options)
      varargin = {varargin{1},varargin{2},varargin{3}};
      x = varargin{1};
      y = varargin{2};
      inopts = varargin{3};
      model = [];
      predictmode = 0;    % no prediction
    else
      error(['Input arguments not recognized.'])
    end
    
    % 4 inputs: (x,y,model,options) case C
  case 4   %four inputs
    if  isa(varargin{4},'struct')
      % Must be case C: (x,y,model,options)
      % convert to [x, [], opts, model]
      varargin = {varargin{1},varargin{2}, varargin{4},varargin{3}};
      x = varargin{1};
      y = varargin{2};
      inopts = varargin{3};
      model = varargin{4};
      predictmode = 1;    % prediction
    end
    
  otherwise
    error(['Input arguments not recognized.'])
    
end

try
  options = reconopts(inopts,mfilename,{'b','q','probabilityestimates','rawmodel','strictthreshold'});
catch
  error(['Input OPTIONS not recognized.'])
end

%set random seed
rng(options.random_state,'twister');
javaState = java.util.Random();
javaState.setSeed(options.random_state);

% warn user the xgb and xgbda have migrated to using Python
msg = ['XGB/XGBDA have migrated to using Python engines in version 9.5. '...
       'This requires getting Python configured to use PLS_Toolbox/Solo. '...
       newline ...
       'If you recieve the error: "Unable to resolve py.xgboost.XGBRegressor()" or '...
       '"Unable to resolve py.xgboost.XGBClassifier()" then Python needs to be configured. '...
       'Please see our documentation to get Python configured if not done already.'];
evritip('evrixgboost_python',msg,1);

% % Check if there are parameter ranges, indicating CV parameter optimization needed
% % Remove v if no parameters have ranges. v must be present if ranges
% options = checkCvArgument(options, size(x,1));

%Check for valid algorithm.
if ~ismember(options.algorithm,{'xgboost'})
  error(['Algorithm [' options.algorithm '] not recognized.'])
end

options.blockdetails = lower(options.blockdetails);
switch options.blockdetails
  case {'compact','standard','all'};
  otherwise
    error(['OPTIONS.BLOCKDETAILS not recognized.'])
end

%B) check model format
if length(varargin)>=4;
  try
    model = updatemod(model);        %make sure it's v3.0 model
  catch
    error(['Input MODEL not recognized.'])
  end
end

%C) CHECK Data Inputs
[datasource{1:2}] = getdatasource(x,y);
if isa(x,'double')      %convert varargin{1} and varargin{2} to DataSets
  x        = dataset(x);
  x.name   = inputname(1);
  x.author = 'XGB';
elseif ~isa(x,'dataset')
  error(['Input X must be class ''double'' or ''dataset''.'])
end
if ndims(x.data)>2
  error(['Input X must contain a 2-way array. Input has ',int2str(ndims(x.data)),' modes.'])
end

modelgroups = {};
if ~isempty(y);
  haveyblock = 1;
  if isclassification(options)
    if iscell(y)   % y as "modelgroups" (indicating class groupings)
      % regen y, creating from x-block classes
      modelgroups = y;
      
      y = class2logical(x,modelgroups,options.classset); %create y-block from x
      if isempty(y);
        error('Classes could not be found in x. Cannot use class grouping without x-block classes.')
      end
      y.include{1} = x.include{1};
      % revert to single column y, keeping class values used in y.classlookup
      newy = y.class{1}';
      newy = dataset(newy);
      y = copydsfields(y,newy,1);  %copy mode 1's labels from y into newy
      y.classlookup{2,1} = y.classlookup{1,1}; % necessary
      
      % set datasource again with y empty for multiclassifications.getclassid
      [datasource{1:2}] = getdatasource(x,[]);
      
    elseif isa(y,'double')
      %check for two classes (0 and 1) and revise to 1 and 2
      uniqueclasses = unique(y);
      % Do not model class 0 if there are more than 2 classes
      if length(uniqueclasses)==2 & all(uniqueclasses(:)==[0;1])
        y = y + 1;  %make 0:1 be 1:2
      end
    end
  end
  
  if isa(y,'double') | isa(y,'logical')
    if size(y,1)==1 & size(y,2)> 1
      y = y';   % transpose to be a column vector
    end
    y        = dataset(y);
    y.name   = inputname(2);
    y.author = 'XGB';
  elseif ~isa(y,'dataset')
    error(['Input y must be class ''double'', ''logical'' or ''dataset''.'])
  end
  
  if isa(y.data,'logical');
    y.data = double(y.data);
  end
  if ndims(y.data)>2
    error(['Input y must contain a 2-way array. Input has ',int2str(ndims(y.data)),' modes.'])
  end
  if size(x.data,1)~=size(y.data,1)
    error('Number of samples in X and y must be equal.')
  end
  %Check INCLUD fields of X and y
  i       = intersect(x.includ{1},y.includ{1});
  if ( length(i)~=length(x.includ{1,1}) | ...
      length(i)~=length(y.includ{1,1}) )
    if (strcmp(lower(options.display),'on')|options.display==1)
      disp('Warning: Number of samples included in X and y not equal.')
      disp('Using intersection of included samples.')
    end
    x.includ{1,1} = i;
    y.includ{1,1} = i;
  end
  %Change include fields in y dataset. Confirm there are enough y columns before trying.
  if length(varargin)>=4 % this means model was input
    if size(y.data,2)==length(model.detail.includ{2,2})
      %SPECIAL CASE - ignore the y-block column include field if the
      %y-block contains the same number of columns as the include field.
      model.detail.includ{2,2} = 1:size(y.data,2);
    else
      if size(y.data,2) < length(model.detail.includ{2,2})
        %trap this one error to give more diagnostic information than the
        %error below gives
        error('y-block columns included in model do not match number of columns in test set.');
      end
      try
        y.include{2} = model.detail.includ{2,2};
      catch
        error('Model include field selections will not work with current y-block.');
      end
    end
  end
  if length(y.include{2})>1
    error('XGB cannot operate on multivariate y. Choose a single column to operate on.')
  end
  
else  
  % so isempty(y);
  % if classification look for classes
  if isclassification(options)    
    if options.classset == 0 & ~predictmode
      error('Options classset (= %i) must be a positive integer identifying a calibration data Class set',options.classset);
    end
    
    if options.classset>1 &(options.classset > size(x.class,2) | isempty(x.class{1,options.classset}))
      y = [];
    elseif options.classset == 0 & predictmode
      y = [];
    else
      y = x.class{1,options.classset}';
    end        
    
    if ~isempty(y)
      if ~predictmode | isempty(model) | isempty(model.detail.modelgroups)
        y = dataset(y);
        y.include{1} = x.include{1};
      else
        %predict mode with modelgroups specified
        modelgroups = model.detail.modelgroups;
        y = class2logical(y,modelgroups,options.classset); %group classes
        y.include{1} = x.include{1};
        newy = y.class{1}';          % revert to single column y, keeping class values used in y.classlookup
        newy = dataset(newy);
        y = copydsfields(y,newy,1);  %copy mode 1's labels from y into newy
        y.classlookup{2,1} = y.classlookup{1,1}; % necessary
      end
      
    end
  end
  if isempty(y)
    if ~predictmode
      %need y for model? error out
      error(['xgb requires non-empty y or dataset x with classes.']);
    end
    %empty y = NOT haveyblock mode (predict ONLY)
    haveyblock = 0;
  else
    haveyblock = 1;
  end
end

if isempty(options.preprocessing);
  options.preprocessing = {[] []};  %reinterpet as empty for both blocks
end
if ~isa(options.preprocessing,'cell')
  options.preprocessing = {options.preprocessing};
end
% y-block preprocessing is NOT used with classification XGB
if isclassification(options)  
  options.preprocessing{2} = [];  %DROP ANY y-block preprocessing
end

preprocessing = options.preprocessing;

if ~predictmode       % Calibration ----------------------------------------------------------------
  if ~haveyblock
    error('Need non-empty Y-block in order to calibrate, but Y-block is empty.');
  elseif isclassification(options) & sum(abs(y.data - round(y.data))) > eps
    error('XGB Classification requires integer-valued Y-block but non-integer values found.');
  end
  
  
if strcmp(options.xgbtype,'xgbc') 
    options.objective = 'multi:softprob';  % use softmax classifier
    options.num_class = length(unique(y.data));
end
  
  if mdcheck(x);
    if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess". Results may be affected by this action.'); end
    [flag,missmap,x] = mdcheck(x);
    if length(y.include{1}) ~= length(x.include{1})
      %copy any changes over to y-block
      y.include{1} = x.include{1};
    end
  end
  
  originalinclude = x.include{1};
  if isclassification(options)
    %if classification, drop any samples from class zero
    iszero = any(y.data(originalinclude,:)==0,2);
    if any(iszero)
      %remove those from the xsub and ysub (so we don't calibrate with them)
      incl = originalinclude;
      incl(iszero) = [];  %drop the zero items
      x.include{1} = incl;
      y.include{1} = incl;
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
  % preprocessing contains the x and y values
  options.preprocessing{1} = preprocessing{1};
  options.preprocessing{2} = preprocessing{2};
  
  % Apply data compression if desired by user
  switch options.compression
    case {'pca' 'pls'}
      switch options.compression
        case 'pca'
          comopts = struct('display','off','plots','none','confidencelimit',0,'preprocessing',{{[] []}});
          commodel = pca(xpp,options.compressncomp,comopts);
          comlabel = 'PC_';
        case 'pls'
          comopts = struct('display','off','plots','none','confidencelimit',0,'preprocessing',{{[] []}});
          if ~isclassification(options)
            commodel = pls(xpp,ypp,options.compressncomp,comopts);
          else
            commodel = plsda(xpp,ypp,options.compressncomp,comopts);
          end
          comlabel = 'LV_';
      end
      scores   = commodel.loads{1};
      
      ndigits = floor(log10(size(scores,2)))+1;
      scorelabels = [repmat(comlabel,size(scores,2), 1) repmat('0',size(scores,2),ndigits)];
      vfmt = sprintf('%s%%.%dd', comlabel, ndigits);   %  for ex: 'LV_%.1d' 
      for iv=1:size(scores,2)
        scorelabels(iv,:) = sprintf(vfmt, iv);
      end
           
      if strcmp(options.compressmd,'yes')
        incl = commodel.detail.includ{1};
        eig  = std(scores(incl,:)).^2;
        commodel.detail.eig = eig;
        scores = scores*diag(1./sqrt(eig));
      else
        commodel.detail.eig = ones(1,size(scores,2));
      end
      xpp      = copydsfields(xpp,dataset(scores),1);
      xpp.label{2} = scorelabels;
    otherwise
      commodel = [];
  end
  
  % check CV
  if isempty(options.cvi)
    if isfield(options,'splits') 
    %backwards compatibility for when user calls with depreciated options
    options.cvi = {'rnd' options.splits 1};
    else
    options.cvi = {'rnd' 5 1};
    end      
  end
  
  % build model (and do outlier rejection)
  model = xgbadapter(xpp, ypp, options);
  % is Matlab-version model, contains model.detail.xgb.model (also Matlab)
  
  % check if these fields are already set
  model.detail.data = {x y};
  model = copydsfields(x,model,[],{1 1});  
  model = copydsfields(y,model,[],{1 2});
  model.detail.includ{1,2} = x.include{1};   %x-includ samples for y samples too
  model.datasource = datasource;
  model.detail.preprocessing = preprocessing;   %copy calibrated preprocessing info into model
  model.detail.compressionmodel = commodel;
  
  % update featureIDs if compression was used
  if ~strcmpi(options.compression, 'none')
    model.detail.xgb.featureIDs = xpp.label{2};
  end
    
  %Set time and date.
  model.date = date;
  model.time = clock;
  
  % Use replace hyper-parameter ranges with the selected optimal values
  if ~isempty(model.detail.xgb.cvscan)
    options.eta       = model.detail.xgb.cvscan.optimalArgs.eta;
    options.max_depth = model.detail.xgb.cvscan.optimalArgs.max_depth;
    options.num_round = model.detail.xgb.cvscan.optimalArgs.num_round;
  end
  
  %copy options into model only if no model passed in
  model.detail.options = options;
  
  % do crossvalidation
  if ~isempty(model.detail.xgb.cvscan)
      %do EVRI-based cross-validation to populate cv fields
      tempArgs = model.detail.xgb.cvscan.optimalArgs;
  else
    tempArgs.eta = options.eta;
    tempArgs.max_depth = options.max_depth;
    tempArgs.num_round = options.num_round;
  end
  tempArgs.v = 0;   %force cross-val OFF
  tempArgs.b = 0;
  tempArgs.plots = 'none';
  tempArgs.display = 'off';
  
  cvopts = struct('rmoptions',tempArgs,'plots','none','display','off','preprocessing',{0}); % x is already pp
  if isclassification(model.detail.options)
    cvopts.discrim = 'yes';
    % find values of y=0 and exclude them using x.include(1)
    x.include{1} = setdiff(x.include{1}, find(y.data==0));
  else
    cvopts.discrim = 'no';
  end
  if isfield(options,'splits') & isempty(options.cvi)
    %backwards compatibility for when user calls with depreciated
    %options
    cvi = {'rnd' options.splits 1};
  else
    cvi = options.cvi;
  end
  % use xpp since cvopts.preprocessing = 0
  model = crossval(xpp,y,model,cvi,1,cvopts);
  if strcmpi(model.modeltype, 'xgbda')
    [misclassed, classids, texttable] = confusionmatrix(model, true);
    wtclasserr = misclassed(:,6)'*misclassed(:,5)/sum(misclassed(:,5));
    model.detail.classerrcv = wtclasserr;
    model.detail.misclassedcv = [];
  elseif strcmpi(model.modeltype, 'xgb')
    % already have rmsecv
  else
    %
    error('Model is not XGB or XGBDA type (%s)', model.modeltype);
  end
  
  if  isclassification(model.detail.options)
    % misclassedc
    [misclassed, classids, texttable] = confusionmatrix(model);
    wtclasserr = misclassed(:,6)'*misclassed(:,5)/sum(misclassed(:,5));
    model.detail.classerrc = wtclasserr;
    model.detail.misclassedc = [];
    
    % Add model.classification
    mcopts.strictthreshold = options.strictthreshold;
    model = multiclassifications(model, mcopts);
    model.detail.originalinclude = {originalinclude};
    model.detail.modelgroups = modelgroups;  %store modelgroup info (may be empty, but store either way)
  end
  
  
else    % have model, do predict ---------------------------------------------------------------
  originalmodel = model;
  
  if strcmpi(model.modeltype,'xgb') | strcmpi(model.modeltype,'xgbpred');
    model.modeltype = 'XGB';
  elseif strcmpi(model.modeltype,'xgbda') 
    % is okay
  else
    error('Input MODEL is not an XGB or XGBDA model');
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
      if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess" from existing model. Results may be affected by this action.'); end
      x = replacevars(model,x);
    end
    
    preprocessing     = model.detail.preprocessing;   %get preprocessing from model
    options.algorithm = model.detail.options.algorithm;   %get algorithm from model
    
    if haveyblock & ~isempty(preprocessing{2});
      [ypp]           = preprocess('apply',preprocessing{2},y);
    else
      ypp = y;
    end
    if ~isempty(preprocessing{1});
      [xpp]           = preprocess('apply',preprocessing{1},x);
    else
      xpp = x;
    end
    
    if ~isempty(model.detail.compressionmodel)
      %apply any compression model found to data
      commodel = model.detail.compressionmodel;
      comopts  = struct('display','off','plots','none');
      compred  = feval(lower(commodel.modeltype),xpp,commodel,comopts);
      scores   = compred.loads{1};
      scores   = scores*diag(1./sqrt(commodel.detail.eig));
      xpp      = copydsfields(xpp,dataset(scores),1);
      model.detail.compressionmodel = compred;
    end
    
    %copy info
    model = copydsfields(x,model,1,{1 1});
    model.detail.includ{1,2} = x.include{1};   %x-includ samples for y samples too
    model.datasource = datasource;
    
    %Update time and date.
    model.date = date;
    model.time = clock;
    
    %make predictions for new samples
    switch lower(options.algorithm)
      case {'xgboost'}
        client = evriPyClient(options,model.detail.xgb.model.bytearray);
        resultp = xgbengine(xpp.data(:,xpp.include{2}), [], client, options );   % call engine to get ypred       
        model.pred = {[] resultp};
        
        if isclassification(options)
          % probability for each sample belonging to each class
          model.detail.predprobability = resultp;
        end
      otherwise
        error(['Input options.algorithm argument not recognized, ''' options.algorithm ''''])
    end
    
  %and copy over values
  model.detail.data   = {x y};
  model.pred          = {[] resultp};

  if  isclassification(model.detail.options)
    model.detail.options.classset = options.classset;
    mcopts.strictthreshold = options.strictthreshold;
    model = multiclassifications(originalmodel,model, mcopts);

    % misclassedp
    if isempty(y)
      model.detail.classerrp = [];
      model.detail.misclassedp = [];
    else
      [misclassed, classids, texttable] = confusionmatrix(model);
      wtclasserr = misclassed(:,6)'*misclassed(:,5)/sum(misclassed(:,5));
      model.detail.classerrp = wtclasserr;
      model.detail.misclassedp = [];
    end
  else
    % rmsec and rmsep are added later by call to calcystats
  end

end       % end if ~predict ------------------------------------------------------------------------


%handle y predictions
% model.pred{2} is in unprocessed form
% but calcystats expects its fourth arg, ypredpp, to be preprocessed.
if ~isempty(model.detail.xgb.model) 
  if  ~isempty(model.pred{2})
    ypredpp = model.pred{2};
    model.pred{2} = preprocess('undo',model.detail.preprocessing{2},model.pred{2});
    model.pred{2} = model.pred{1,2}.data;
    if ~isclassification(model.detail.options) 
      model = calcystats(model,predictmode,ypp,ypredpp);
    end
  end
else
  model.pred{2} = [];
  model.info    = 'Warning: No XGB solution found'; 
end

% Record parameters
model.detail.xgb.model.options = inopts;
% If parameter optimization was performed then record the optimal params
if ~isempty(model.detail.xgb.cvscan) 
    model.detail.xgb.model.options.eta       = model.detail.xgb.cvscan.best.eta;
    model.detail.xgb.model.options.max_depth = model.detail.xgb.cvscan.best.max_depth;
    model.detail.xgb.model.options.num_round = model.detail.xgb.cvscan.best.num_round;
end

%label as prediction
if predictmode
  model.modeltype = [model.modeltype '_PRED'];
else
  model = addhelpyvars(model);
end

% reset cvi if it has been internally converted to custom ('user')
% xgb/xgbda Analysis gui encodes the CV specification as mode 'user'.
if isfieldcheck(model,'model.detail.cv') & isfieldcheck(model, 'model.detail.options.cvi_orig')
  if strcmp('user', model.detail.cv) & isnumeric(model.detail.options.cvi) %& isfield(model.detail.options, 'cvi_orig')
    cv0 = model.detail.options.cvi_orig{1};
    split0 = model.detail.options.cvi_orig{2};
    if ~isempty(model.detail.options.cvi_orig{3})
      iter0 = model.detail.options.cvi_orig{3};
    else
      iter0 = 1;
    end
    model.detail.cv = cv0;
    model.detail.split = split0;
    model.detail.iter = iter0;
  end
end

%handle model compression
switch lower(options.blockdetails)
  case 'standard'
    model.detail.data{1} = [];   % First element not populated for standard detail level
    model.pred{1} = [];   % First element not populated for standard detail level
    model.detail.res{1}  = [];
end

varargout{1} = model;

switch lower(options.plots)
  case 'final'
    try
      if ~predictmode
        %plotloads(model);
        plotscores(model);
      else
        %plotloads(originalmodel,model);
        plotscores(originalmodel,model);
      end
    catch
      warning('EVRI:PlottingError',lasterr)
    end
end

%End Input

%-----------------------------------------------------------------------
%Functions


%-----------------------------------------------------------------
function model = xgbadapter(x,y,options)
%XGBADAPTER Runs xgboost on x and y and returns a model
% This wraps the call to xgbengine and packages the returned Java model
% into a Matlab model of type 'xgb' or 'xgbda', as appropriate.

ma      = size(x,1);  %ALL data size
m       = length(x.includ{1,1});  %= y.includ{1}
nx      = length(x.includ{2,1});
ny      = length(y.includ{2,1});

if isclassification(options)
  model = modelstruct('xgbda');
else
  model = modelstruct('xgb');
end

model.date       = date;
model.time       = clock;

if ~all([m nx] == size(x.data));
  xsub = x.data(x.includ{1},x.includ{2});
  if isa(options.cvi, 'double')
    options.cvi = options.cvi(x.includ{1});
  end
else
  xsub = x.data;
end
if ~all([length(y.includ{1}) length(y.includ{2})] == size(y.data));
  ysub = y.data(y.includ{1},y.includ{2});
else
  ysub = y.data;
end

if isclassification(options)
  %if classification...  
  % check there are two or more classes for classification
  if length(unique(ysub))<2
    error('Samples from at least two non-zero classes must be included in model');
  end
  
end

switch options.algorithm
  
  case 'xgboost'
    [result, cmap] = xgbengine(xsub, ysub, options);
    
    if(isa(result, 'evriPyClient'))
      % Build model from calibration data without parameter optimizing CV scan
      model.detail.xgb.model.bytearray = result.serialized_model;
      model.detail.xgb.model.label = unique(ysub);  % used in multiclassifications
      model.detail.xgb.cmap  = cmap;
      
      % Add feature scores
      [model, scores, labels] = getfeaturescores(model, result, nx);

        % model needs pred, so use this to call xgbengine
        resultp    = xgbengine(x.data(:,x.include{2}), y.data(:,y.include{2}), result, options);
        model.pred = {[] resultp};
        
      % prediction is the probability for each sample belonging to each class, for all samples
      if isclassification(options)
        probEsts = resultp;
        model.detail.predprobability = probEsts;       
      end
    elseif isfield(result,'optimalArgs')
      % Did CV optimization scan of parameters.  Now apply these parameters to train model
      client = xgbengine(xsub, ysub, result.optimalArgs);
      model.detail.xgb.model.bytearray = client.serialized_model;
      model.detail.xgb.model.label = unique(ysub);  % used in multiclassifications
      model.detail.xgb.cvscan = result; % Also put the CV param scan results in the model
      
      % Add feature scores
      [model, scores, labels] = getfeaturescores(model, client, nx);
      
      % If the xgb model had y-preprocessing then the cv values (rmsecv) were calculated using preprocessed data
      % Correct rmsecv by multiplying by std. dev.. Note, we can only correct in the case of 'Autoscale'.
      try
        if ~isclassification(result.optimalArgs) & ~isempty(options.preprocessing{2})  ...
            & strcmp(options.preprocessing{2}.keyword, 'Autoscale') & ~isempty(options.preprocessing{2}.out{2})
          stddev = options.preprocessing{2}.out{2};
          result.bestCV = result.bestCV*stddev;
        end
      catch
        % don't die over this
      end
      
      % Calculate the probability for each sample belonging to each class    
      % model needs pred, so use this Java model again with xsub for prediction (on all data)
      newoptions = result.optimalArgs;
      newoptions.waitbar = options.waitbar;
      resultp = xgbengine(x.data(:,x.include{2}), y.data(:,y.include{2}), client, newoptions);
      model.pred = {[] resultp};
      
      if isclassification(options)
        probEsts = resultp;        
        model.detail.predprobability = probEsts;       
      end       
    else
      model.detail.xgb_pred = result;
    end  
end

%-----------------------------------------------------------------
function [model, scores, labels] = getfeaturescores(model, jmodel, nincy)
%Get feature scores from the XGBoost (Java) model
% if(~isa(jmodel, 'ml.dmlc.xgboost4j.java.Booster'))
%   [jmodel] = modelToJava(jmodel);
% end
% fs = evri.util.ModelHelper(jmodel);
% ids = char(fs.getFeatureIDs);
% fscores = fs.getFeatureScores;
% 
% % account for features with zero score being not included in these
% nids = size(ids,1);
% ints = nan(1,nids);
% for ii=1:nids
%   ints(ii) = str2num(strtrim(ids(ii,2:end)));
% end
% 
% [tmp, isort] = sort(ints);
% sfscores = fscores(isort);
% sints = ints(isort);
% sints = sints+1; % need to be 1-based for Matlab use
% 
% % Expand scores and labels to the size of the model's included variables
% % Need include length because ids/fscores can be too short if last feature
% % to be listed had score = 0, meaning it is not included in ids/fscores.
% % incl2 = model.detail.include{2,1};  
% scores = zeros(nincy, 1);
% labels = repmat(' ', nincy, size(ids,2));
% scores(sints) = sfscores;
% for i=1:length(sints)
%   labels(sints(i),:) = ids(isort(i),:);
% end
scores = jmodel.extractions.feature_importance;
labels = char(arrayfun(@(x) ['f' num2str(x)],1:size(nincy,2),'UniformOutput',false));
model.detail.xgb.featurescores = scores;
model.detail.xgb.featureIDs    = labels;

%-----------------------------------------------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                            userlevel       description
'display'                'Display'        'select'        {'on' 'off'}                              'novice'        'Governs level of display.';
'plots'                  'Display'        'select'        {'none' 'final'}                          'novice'        'Governs level of plotting.';
'algorithm'              'Standard'       'select'        {'xgboost'}                                'novice'        [{'Algorithm to use. xgboost is default and currently only option.'} getxgbcp];
'booster'                'Parameters'     'select'        {'gbtree' 'gblinear' }                    'advanced'      'Which booster to use. gbtree uses tree based models while gblinear uses linear functions.(default = ''gbtree'').';
'xgbtype'                'Standard'       'select'        {'xgbr' 'xgbc'} 'novice'        'Type of XGBOOST to apply. The default is ''xgbc'' for classification, and ''xgbr'' for regression.';
'max_depth'              'Parameters'     'mode'          'int(1:inf)'                              'novice'        'Value(s) to use for XGBoost max_depth parameter. Default is 6.';
'num_round'              'Parameters'     'mode'          'int(1:inf)'                              'novice'        'Value(s) to use for XGBoost num_round parameter. Default is 200.';
'eta'                    'Parameters'     'mode'          'float(0:1)'                              'novice'        'XGBoost eta parameter (''learning rate''). Step size shrinkage used in update to prevents overfitting. Default is 0.3.';
'alpha'                  'Parameters'     'mode'          'float(0:inf)'                            'advanced'      'XGBoost alpha parameter. L1 regularization term on weights. Default is 0.';
'lambda'                 'Parameters'     'mode'          'float(0:inf)'                            'advanced'      'XGBoost lambda parameter. L2 regularization term on weights. Default is 1.';
'gamma'                  'Parameters'     'mode'          'float(0:inf)'                            'advanced'      'XGBoost gamma parameter. Minimum loss reduction required to make a further partition on a leaf node of the tree. Default is 0.';
'scale_pos_weight'       'Parameters'     'mode'          'float(0:inf)'                            'advanced'      'XGBoost. Control the balance of positive and negative weights, useful for unbalanced classes. Default is 1.';
'preprocessing'          'Standard'       'cell(vector)'  ''                                        'novice'        'Preprocessing structures. Cell 1 is preprocessing for X block';
'classset'               'Standard'       'double'        'int(1:inf)'                              'novice'        'Class set to model when performing discriminant analysis';
'compression'            'Compression'    'select'        {'none' 'pca' 'pls'}                      'novice'        'Type of data compression to perform on the x-block prior to XGB model. Compression can make the XGB more stable and less prone to overfitting. ''PCA'' is a principal components model and ''PLS'' is a partial least squares model (which may give improved sensitivity).';
'compressncomp'          'Compression'    'double'        'int(1:inf)'                              'novice'        'Number of latent variables or principal components to include in the compression model.'
'compressmd'             'Compression'    'select'        {'no' 'yes'}                              'novice'        'Use Mahalnobis Distance corrected scores from compression model.'
'strictthreshold'        'Classification' 'double'        'float(0:1)'                              'advanced'        'Threshold probability for associating sample with a class in model.classification.inclass. (default = 0.5).';
'predictionrule'         'Classification' 'select'        {'mostprobable' 'strict' }                'advanced'    'Specifies which classification preciction results appear first in confusion matrix window opened from Analysis (default = ''mostprobable'').';
};

out = makesubops(defs);

%-----------------------------------------------------------------
function out = getxgbcp()

out  = {'XGB and XGBDA in PLS_Toolbox use the XGBOOST library. '...
' '...
'Copyright (c) 2014 by Tianqi Chen and Contributors '...
' '...
'Licensed under the Apache License, Version 2.0 (the "License");'...
'you may not use this file except in compliance with the License.'...
'You may obtain a copy of the License at'...
' '...    
'   http://www.apache.org/licenses/LICENSE-2.0'...
' '...
'Unless required by applicable law or agreed to in writing, software'...
'distributed under the License is distributed on an "AS IS" BASIS,'...
'WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.'...
'See the License for the specific language governing permissions and'...
'limitations under the License.'};

