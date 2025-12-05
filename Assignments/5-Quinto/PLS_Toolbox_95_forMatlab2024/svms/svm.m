function varargout = svm(varargin)
%SVM Support Vector Machine (LIBSVM) for regression or classification.
%  SVM performs calibration and application of Support Vector Machine (SVM)
%  models. These are non-linear models which can be used for regression or
%  classification problems. The model consists of a number of support
%  vectors (essentially samples selected from the calibration set) and
%  non-linear model coefficients which define the non-linear mapping of
%  variables in the input x-block to allow prediction of either the
%  continuous y-block variable (for regression problems), or the
%  classification as passed in either the classes of the x-block or in a
%  y-block which contains numerical classes.
%
%  To choose between regression and classification, use the svmtype option:
%    regression     : svmtype = 'epsilon-svr' or 'nu-svr'
%    classification : svmtype = 'c-svc' or 'nu-svc'
%  It is recommended that classification be done through the svmda
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
%          algorithm: [ 'libsvm' ] algorithm to use. libsvm is default and currently only option.
%           classset: [ 1 ] indicates which class set in x to use when no y-block is provided. 
%         kerneltype: [ 'linear' | 'rbf' ] SVM kernel to use. 'rbf' is default.
%            svmtype: [ {'epsilon-svr'} | 'nu-svr' ] Type of SVM to apply.
%                     Default is 'c-svc' for classification, and 'epsilon-svr' for regression.                   
% probabilityestimates: 1; whether to train a SVC or SVR model for probability
%                           estimates, 0 or 1 (default 0)"
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
%                cvi: {{'rnd' 5}} Standard cross-validation cell (see crossval)
%                     defining a split method, number of splits, and number
%                     of iterations. This cross-validation is use both for
%                     parameter optimization and for error estimate on the
%                     final selected parameter values. 
%                     Alternatively, can be a vector with the same number 
%                     of elements as x has rows with integer values
%                     indicating CV subsets (see crossval).
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
%      random_state : [1] Random seed number. Set this to a number for reproducibility.
%
% OUTPUTS:
%     model = standard model structure containing the SVM model (See MODELSTRUCT).
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: model = svm(x,y,options);          %identifies model (calibration step)
%I/O: pred  = svm(x,model,options);      %makes predictions with a new X-block
%I/O: pred  = svm(x,y,model,options);  %performs a "test" call with a new X-block and known y-values
%
%See also: KNN, LWR, PLS, PLSDA, SVMDA, SVMENGINE

%Copyright Eigenvector Research, Inc. 2010
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%12/2009 Donal

%Start Input
if nargin==0  % LAUNCH GUI
  analysis('svm')
  return
end
if ischar(varargin{1}) %Help, Demo, Options
  %defaults for cross-validation settings
  ngamma   = 8;
  ngamma0  = -6;
  ncost    = 6;  % using cost > 100 runs very slowly
  ncost0   = -3;
  gammas   = logspace(ngamma0, ngamma0+ngamma-1, ngamma*2-1); % Two points per order of magnitude
  costs    = logspace(ncost0, ncost0+ncost-1, ncost*2-1);
  epsilons = [1.0, 0.1, 0.01];
  nus      = [0.2, 0.5, 0.8];
  
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
  options.classset      = 1;
  options.random_state = 1;
  options.definitions   = @optiondefs;
  
  % libsvm defaults (may be different from those set in svmengine):
  options.algorithm  =  'libsvm';
  options.cvi        = {'rnd' 5 1};
  options.svmtype    = 'epsilon-svr';
  options.kerneltype = 'rbf';
  options.gamma      = gammas;
  options.cost       = costs;
  options.epsilon    = epsilons;
  options.nu         = nus;
  
  svmengineoptions = svmengine('options');
  options.cvtimelimit = svmengineoptions.cvtimelimit;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
  
end

%A) Check Options Input
%   options.algorithm     = 'libsvm';
% Convert each case to the 3-arg form:   [x, y, opts],
% or, if model input, to the 4-arg form: [x, y, opts, model]
%
% Possible calls:
% 1 inputs: (x)                     // Calibration: must have y in x.classid{1}. Classification SVM
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
      varargin = {varargin{1}, varargin{1}.class{1}',svm('options')};
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
      varargin = {varargin{1}, [], svm('options'), varargin{2}};
      x = varargin{1};
      y = varargin{2};
      inopts = varargin{3};
      model  = varargin{4};
      predictmode = 1;
      
    elseif isa(varargin{2},'struct')
      if isa(varargin{1},'dataset')  |  isa(varargin{1},'double')
        % (x,opts): convert to (x, x.class{1},opts) if c-svc/nu-svc
        % (x,opts): convert to (x,         [],opts) if one-class svm
        varargin = {varargin{1}, [], varargin{2}};
        % check that opts specifies classification SVM
        svmTypeName = getSvmTypeName(varargin{3});
        if ~ismember(svmTypeName,{'C-SVC' 'nu-SVC' 'one-class SVM'})
          error(['When svm is called with no yblock then options must specify SVM classification or one-class SVM'])
        end
        x = varargin{1};
        y = varargin{2};
        inopts = varargin{3};
        model = [];
        predictmode = 0;
        
      else                                  %  unrecognized args
        error(['svm called with two arguments requires non-empty y or dataset x with classes.']);
      end
    elseif isnumeric(varargin{2}) | isdataset(varargin{2})     % (x,y): convert to (x,y,options,[])
      varargin = {varargin{1}, varargin{2},svm('options')};
      x = varargin{1};
      y = varargin{2};
      inopts = varargin{3};
      model = [];
      predictmode = 0;
    else
      error(['svm called with two arguments expects x, y, or x, model, or x, options.']);
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
      if strcmpi(model.modeltype, 'svmoc')
        model.detail.svm.model.param.svm_type = 3; % the trick to get the decision values
      end
    elseif ismodel(varargin{3})
      % Must be case B: (x,y,model)
      varargin = {varargin{1},varargin{2},svm('options'),varargin{3}};
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

% Check if there are parameter ranges, indicating CV parameter optimization needed
% Remove v if no parameters have ranges. v must be present if ranges
options = checkCvArgument(options, size(x,1));

%Check for valid algorithm.
if ~ismember(options.algorithm,{'libsvm'})
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
  x.author = 'SVM';
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
    y.author = 'SVM';
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
    error('SVM cannot operate on multivariate y. Choose a single column to operate on.')
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
  elseif  isoneclasssvm(options) % ignores classes. everything is one class
    haveyblock = 0;
    y = dataset(ones(size(x,1),1)); % dummy y
    y.include{1} = x.include{1};
  end
  if isempty(y)
    if ~predictmode
      %need y for model? error out
      error(['svm requires non-empty y or dataset x with classes.']);
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
% y-block preprocessing is NOT used with classification SVM
if isclassification(options)  
  options.preprocessing{2} = [];  %DROP ANY y-block preprocessing
end

preprocessing = options.preprocessing;

if ~predictmode       % Calibration ----------------------------------------------------------------
  if ~haveyblock & ~isoneclasssvm(options)
    error('Need non-empty Y-block in order to calibrate, but Y-block is empty.');
  elseif isclassification(options) & sum(abs(y.data - round(y.data))) > eps
    error('SVM Classification requires integer-valued Y-block but non-integer values found.');
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
        case 'pls'
          comopts = struct('display','off','plots','none','confidencelimit',0,'preprocessing',{{[] []}});
          if ~isclassification(options)
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
  model = svmadapter(xpp, ypp, options);
  % is Matlab-version model, contains model.detail.svm.model (also Matlab)
  
  % check if these fields are already set
  model.detail.data = {x y};
  model = copydsfields(x,model,[],{1 1});  
  model = copydsfields(y,model,[],{1 2});
  model.detail.includ{1,2} = x.include{1};   %x-includ samples for y samples too
  model.datasource = datasource;
  model.detail.preprocessing = preprocessing;   %copy calibrated preprocessing info into model
  model.detail.compressionmodel = commodel;
  
  model.detail.svm.svindices = [];
  mValues = getSupportVectors(model);  
  if ~isempty(mValues)
    [C,ia,ib] = intersect(mValues, xpp.data.include{2}, 'rows');
    model.detail.svm.svindices = ib; % SV indices into X-block
  end
  
  %Set time and date.
  model.date = date;
  model.time = clock;
  %copy options into model only if no model passed in
  model.detail.options = options;
  
  %do crossvalidation if we did an optimization
  if ~isempty(model.detail.svm.cvscan)
    if ~isoneclasssvm(model.detail.options)
      %do EVRI-based cross-validation to populate cv fields
      tempArgs = model.detail.svm.cvscan.optimalArgs;
      tempArgs.v = 0;   %force cross-val OFF
      tempArgs.b = 0;
      tempArgs.plots = 'none';
      tempArgs.display = 'off';
      cvopts = struct('rmoptions',tempArgs,'plots','none','display','off','preprocessing',{preprocessing});
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
      model = crossval(x,y,model,cvi,1,cvopts);
      
    else
      model.detail.classerrcv   = model.detail.svm.cvscan.bestCV;   % fraction of SV (i.e. outliers)
    end
    
  else
    if isfield(model.detail, 'classerrcv')
      model.detail.classerrcv   = model.detail.svm.model.l/size(x,1); % fraction of SV (i.e. outliers)
    end
    % record used params
    args1 = model.detail.svm.model.param;
    args1 = convertToLibsvmArgNames(args1);
    args1 = convertToLibsvmArgValues(args1);
    args1 = removeExtraSvmParams(args1);
    model.detail.svm.paramsused = getSupportedParameters(args1);
  end
  % misclassedc
  
  if  isclassification(model.detail.options)
    if isempty(y)
      ydata = [];
    else
      ydata = y.data;
    end
    cm =confusionmatrix(ydata, model.pred{2});
    if ~isempty(cm)
      % misclassed row 1 = False Pos Rate, row 2 = False Neg Rate
      misclassedc = cm(:,[2 4])';
      model.detail.misclassedc = cell(1,size(misclassedc,2));
      for i=1:size(misclassedc,2)
        model.detail.misclassedc{i} = misclassedc(:,i);
      end
    end
  end
  
  if  isclassification(model.detail.options)    
    mcopts.strictthreshold = options.strictthreshold;
    model = multiclassifications(model, mcopts);
    model.detail.originalinclude = {originalinclude};
    model.detail.modelgroups = modelgroups;  %store modelgroup info (may be empty, but store either way)
  end


else    % have model, do predict ---------------------------------------------------------------
  originalmodel = model;
  
  if strcmpi(model.modeltype,'svm') | strcmpi(model.modeltype,'svmpred');
    model.modeltype = 'SVM';
  elseif strcmpi(model.modeltype,'svmda') | strcmpi(model.modeltype, 'svmoc')
    % is okay
  else
    error('Input MODEL is not an SVM or SVMDA model');
  end
  
  % case where model has zero support vectors
  if getSupportVectorsCount(model)<1
    ypred  = [];
  else    
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
      case {'libsvm'}
        jmodel = modelToJava(model.detail.svm.model);
        newoptions = getprobabilitystruct(model.detail.options);
        % use plots, display and waitbar values from options
        newoptions.plots = options.plots;
        newoptions.display = options.display;
        newoptions.waitbar = options.waitbar;
        ypred = svmengine(xpp.data(:,xpp.include{2}), [], jmodel, newoptions );   % call engine to get ypred       
        
        if strcmpi(model.modeltype, 'svmoc')
          model.detail.svm.model.param.svm_type = 2; % reset to one-class
        end
        
        % Calculate the probability for each sample belonging to each class
        if isclassification(model.detail.options)
          nsampl = size(xpp.data,1);
          probEsts = ones(nsampl, jmodel.nr_class)*nan;
          if ~isempty(jmodel.probA) & ~isempty(jmodel.probB)
            for isam=1:nsampl
              sample1 = xpp.data(isam, xpp.include{2});
              probEsts(isam,:) = libsvm.evri.SvmTrain2.getProbEstimates(jmodel,sample1);
            end
          end
          model.detail.predprobability = probEsts;
          
          % Get decision function values
          decfnvals = ones(nsampl, (jmodel.nr_class*(jmodel.nr_class-1)/2))*nan;
          for isam=1:size(x.data,1)
            sample1 = xpp.data(isam, xpp.include{2});
            decfnvals(isam,:) = libsvm.evri.SvmTrain2.getDecisionValues(jmodel,sample1);
          end
          model.detail.svm.decfnvals_pred = decfnvals;
          
        end
      otherwise
        error(['Input options.algorithm argument not recognized, ''' options.algorithm ''''])
    end
  end
  %and copy over values
  model.detail.data   = {x y};
  model.pred          = {[] ypred};
  
  if  isclassification(model.detail.options)
    if ~isempty(y)
      ydata = y.data;
      cm = confusionmatrix(ydata, ypred);
      if ~isempty(cm)
        model.detail.classerrp = sum(cm(:,[2 4]),2)/2;
        misclassedp = cm(:,[2 4])';
        model.detail.misclassedp = cell(1,size(misclassedp,2));
        for i=1:size(misclassedp,2)
          model.detail.misclassedp{i} = misclassedp(:,i);
        end
      end
    end
  end

  if  isclassification(model.detail.options)
    model.detail.options.classset = options.classset;
    mcopts.strictthreshold = options.strictthreshold;
    model = multiclassifications(originalmodel,model, mcopts);
  end

end       % end if ~predict ------------------------------------------------------------------------


%handle y predictions
% model.pred{2} is in unprocessed form
% but calcystats expects its fourth arg, ypredpp, to be preprocessed.
if ~isempty(model.detail.svm.model) & getSupportVectorsCount(model)>0 
  if  ~isempty(model.pred{2})
    ypredpp = model.pred{2};
    model.pred{2} = preprocess('undo',model.detail.preprocessing{2},model.pred{2});
    model.pred{2} = model.pred{1,2}.data;
    if ~isclassification(model.detail.options) & ~isoneclasssvm(model.detail.options)
      model = calcystats(model,predictmode,ypp,ypredpp);
    end
  end
else
  model.pred{2} = [];
  model.info    = 'Warning: No SVM solution found (there are no support vectors)'; 
end

%label as prediction
if predictmode
  model.modeltype = [model.modeltype '_PRED'];
else
  model = addhelpyvars(model);
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
function model = svmadapter(x,y,options)
%SVMADAPTER Runs svm on x and y and returns a model
% This wraps the call to svmengine and packages the returned Java model
% into a Matlab model of type 'svm' or 'svmda', as appropriate.

ma      = size(x,1);  %ALL data size
m       = length(x.includ{1,1});  %= y.includ{1}
nx      = length(x.includ{2,1});
ny      = length(y.includ{2,1});

if isclassification(options)
  model = modelstruct('svmda');
elseif isoneclasssvm(options)
  model = modelstruct('svmoc');
else
  model = modelstruct('svm');
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
  
  if isNuClassification(options)
    % check the nu parameter(s) are in the admissible range
    options = checkNuRange(options, ysub);
  end
  
end

switch options.algorithm
  
  case 'libsvm'
    result = svmengine(xsub, ysub, options); %options.libsvmargs);  % where are libsvmargs input and standardized?
    
    if(isa(result, 'libsvm.svm_model'))
      % Build model from calibration data without parameter optimizing CV scan
      mmodel = modelToMatlab(result);
      model.detail.svm.model = mmodel;
      
      % Calculate the probability for each sample belonging to each class, for all samples
      if isclassification(options)
        nsampl = size(x.data,1);
        probEsts = ones(nsampl, mmodel.nr_class)*nan;
        if  ~(isempty(result.probA) | isempty(result.probB))
          for isam=1:nsampl
            sample1 = x.data(isam,x.include{2});
            probEsts(isam,:) = libsvm.evri.SvmTrain2.getProbEstimates(result,sample1);
          end
        end
        model.detail.predprobability = probEsts;
        
        % Get decision function values
        decfnvals = ones(nsampl, (mmodel.nr_class*(mmodel.nr_class-1)/2))*nan;
        for isam=1:size(x.data,1)
          sample1 = x.data(isam, x.include{2});
          decfnvals(isam,:) = libsvm.evri.SvmTrain2.getDecisionValues(result,sample1);
        end
        model.detail.svm.decfnvals = decfnvals;
        
        % model needs pred, so use this output Java model to call svmengine
        % again with xsub for prediction
        newoptions = getprobabilitystruct(options);
        resultp    = svmengine(x.data(:,x.include{2}), y.data(:,y.include{2}), result, newoptions);
        model.pred = {[] resultp};
      end      
    elseif isfield(result,'optimalArgs')
      % Did CV optimization scan of parameters.  Now apply these parameters to train model
      jmodel = svmengine(xsub, ysub, result.optimalArgs);
      mmodel = modelToMatlab(jmodel);
      model.detail.svm.model = mmodel;
      model.detail.svm.cvscan = result; % Also put the CV param scan results in the model
      
      % If the svm model had y-preprocessing then the cv values (rmsecv) were calculated using preprocessed data
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
           
      %copy cv details into model fields
      model.detail.rmsecv = result.bestCV;  %and copy into EVRI-specific field. 
      
      % Calculate the probability for each sample belonging to each class
      % ensure the model has non-empty probA and probB fields
      if isclassification(options)
        nsampl = size(x.data,1);
        probEsts = ones(nsampl, mmodel.nr_class)*nan;
        if ~(isempty(jmodel.probA) | isempty(jmodel.probB))
          for isam=1:size(x.data,1)
            sample1 = x.data(isam, x.include{2});
            probEsts(isam,:) = libsvm.evri.SvmTrain2.getProbEstimates(jmodel,sample1);
          end
        end
        model.detail.predprobability = probEsts;
        
        % Get decision function values
        decfnvals = ones(nsampl, (mmodel.nr_class*(mmodel.nr_class-1)/2))*nan;
        for isam=1:size(x.data,1)
          sample1 = x.data(isam, x.include{2});
          decfnvals(isam,:) = libsvm.evri.SvmTrain2.getDecisionValues(jmodel,sample1);
        end
        model.detail.svm.decfnvals = decfnvals;
      end
      
      % model needs pred, so use this Java model again with xsub for prediction (on all data)
      newoptions = getprobabilitystruct(options);
      newoptions.waitbar = options.waitbar;
      resultp = svmengine(x.data(:,x.include{2}), y.data(:,y.include{2}), jmodel, newoptions);
      model.pred = {[] resultp};
    else
      model.detail.svm_pred = result;
    end
    
    
end


%-----------------------------------------------------------------
function result = getprobabilitystruct(options)
result = struct;
if isfield(options, 'b')
  result.b = options.b;
elseif isfield(options, 'probabilityestimates')
  result.b = options.probabilityestimates;
end
if isfield(options, 'q')
  result.q = options.q;
elseif isfield(options, 'quiet')
  result.q = options.quiet;
end
if isfield(options, 'waitbar')
  result.waitbar = options.waitbar;
end
if isfield(options, 'display')
  result.display = options.display;
end
if isfield(options, 'plots')
  result.plots = options.plots;
end

%-----------------------------------------------------------------
% Ensure that the libsvm 'v' argument is only present if CV
% Check if any svm parameters have ranges, which indicates CV parameter optimization
% Remove v if no parameters have ranges. v must be present if ranges
% Check max length of these parameter fields
% 1. if > 1 then use user-supplied v, or add v with default value min(5, sqrt(nsamples))
% 2. if <= 1 then remove v from args, if present.
function args = checkCvArgument(args, nsample)
args = removeExtraSvmParams(args);
parameters = getSupportedParameters(args);
pnames = fieldnames(parameters);
plen = size(pnames,1);
maxlen = 0;
for i=1:plen
  value = parameters.(pnames{i});
  if ischar(value)
    maxlen = max(maxlen, 1);
  else
    maxlen = max(maxlen, length(value));
  end
end

% Check max length of these supparams
% 1. if > 1 then use user-supplied v, or add v with default value min(10, root(nsamples))
% 2. if <= 1 then remove v from args, if present.
if maxlen > 1
  if ~isfield(args, 'splits')
    args.v = min(5, sqrt(nsample));
  end
elseif maxlen <= 1
  if isfield(args, 'splits')
    % remove v from args, if present
    args = rmfield(args, 'splits');
  end
end

%-----------------------------------------------------------------
function [result] = isNuClassification(args)
%ISNUCLASSIFICATION Test if args invoke nu classification type SVM analysis.
% True if SVM type is nu classification, false otherwise.
%I/O: out = isNuClassification(args_struct);

result = false;

if isfield(args, 's')
  switch args.s
    case {'1', 1}
      result = true;
    otherwise
      result = false;
  end
elseif isfield(args, 'svm_type')
  switch args.svm_type
    case {'1', 1}
      result = true;
    otherwise
      result = false;
  end
elseif isfield(args, 'svmtype')
  switch lower(args.svmtype)
    case {'nu-svc'}
      result = true;
    otherwise
      result = false;
  end
end

%-----------------------------------------------------------------
function options = checkNuRange(options, ydata)
%CHECKNURANGE Check nu param values do not exceed the admissible range.
% nu-svc requires the nu parameter lies between 0 and a threshold value
% less than or equal to 1, which depends on the distribution of the
% sample data between the classification groups, as described in
% "A Tutorial on nu-Support Vector Machines" by Chen, Lin and Schölkopf.
% See section 8. Note that the ydata is assumed to be integer type (so 
% float values are truncated to integers).
%I/O: options = checkNuRange(options);

% Check the nu value if nu-svc
P = hist(floor(ydata), unique(floor(ydata)));
nuMax = 1;
np = length(P);
for i=1:np
  for j = (i+1):np
    nuMaxIj = 2*(min(P(i),P(j)))/(P(i)+P(j));
    if nuMaxIj < nuMax
      nuMax = nuMaxIj;
    end
  end
end

% If necessary, rescale options.nu downwards so max(options.nu) = 0.99*nuMax
if max(options.nu) > 0.99*nuMax
  rescaleFactor = 0.99*nuMax/max(options.nu);
  options.nu = options.nu*rescaleFactor;
end

%-----------------------------------------------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                            userlevel       description
'display'                'Display'        'select'        {'on' 'off'}                              'novice'        'Governs level of display.';
'plots'                  'Display'        'select'        {'none' 'final'}                          'novice'        'Governs level of plotting.';
'algorithm'              'Standard'       'select'        {'libsvm'}                                'novice'        [{'Algorithm to use. libsvm is default and currently only option.'} getsvmcp];
'kerneltype'             'Standard'       'select'        {'linear'  'rbf' }                        'novice'        'SVM kernel to use. ''linear'' = simple linear kernal or ''rbf'' = radial basis function';
'svmtype'                'Standard'       'select'        {'c-svc' 'nu-svc' 'epsilon-svr' 'nu-svr'} 'novice'        'Type of SVM to apply. The default is ''c-svc'' for classification, and ''nu-svr'' for regression.';
'random_state'           'Standard'       'double'        'int(0:inf)'                              'novice'        'Random seed number. Set this to a number for reproducibility.';
'preprocessing'          'Standard'       'cell(vector)'  ''                                        'novice'        'Preprocessing structures. Cell 1 is preprocessing for X block';
'cvtimelimit'            'Standard'       'double'        'int(1:inf)'                              'novice'        'Set a time limit (seconds) on individual cross-validation sub-calculation when searching over supplied SVM parameter ranges for optimal parameters. Only relevant if parameter ranges are used for SVM parameters such as cost, epsilon, gamma or nu.';
'classset'               'Standard'       'double'        'int(1:inf)'                              'novice'        'Class set to model when performing discriminant analysis';
'compression'            'Compression'    'select'        {'none' 'pca' 'pls'}                      'novice'        'Type of data compression to perform on the x-block prior to SVM model. Compression can make the SVM more stable and less prone to overfitting. ''PCA'' is a principal components model and ''PLS'' is a partial least squares model (which may give improved sensitivity).';
'compressncomp'          'Compression'    'double'        'int(1:inf)'                              'novice'        'Number of latent variables or principal components to include in the compression model.'
'compressmd'             'Compression'    'select'        {'no' 'yes'}                              'novice'        'Use Mahalnobis Distance corrected scores from compression model.'
'gamma'                  'Parameters'     'mode'          'float(0:inf)'                            'novice'        'Value(s) to use for LIBSVM kernel gamma parameter. Default is 15 values from 10^-6 to 10, spaced uniformly in log.';
'cost'                   'Parameters'     'mode'          'float(0:inf)'                            'novice'        'Value(s) to use for LIBSVM ''c'' parameter. Default is 11 values from 10^-3 to 100, spaced uniformly in log.';
'epsilon'                'Parameters'     'mode'          'float(0:inf)'                            'novice'        'Value(s) to use for LIBSVM ''p'' parameter (epsilon in loss function). Default is the set of values [1.0, 0.1, 0.01].';
'nu'                     'Parameters'     'mode'          'float(0:1)'                              'novice'        'Value(s) to use for LIBSVM ''n'' parameter (nu of nu-SVC, and nu-SVR). Default is the set of values [0.2, 0.5, 0.8].';
'strictthreshold'        'Classification' 'double'        'float(0:1)'                              'advanced'        'Threshold probability for associating sample with a class in model.classification.inclass. (default = 0.5).';
'predictionrule'         'Classification' 'select'        {'mostprobable' 'strict' }                'advanced'    'Specifies which classification preciction results appear first in confusion matrix window opened from Analysis (default = ''mostprobable'').';
};

out = makesubops(defs);

%-----------------------------------------------------------------
function out = getsvmcp()

out  = {'SVM and SVMDA in PLS_Toolbox use the LIBSVM library. '...
' '...
'Chih-Chung Chang and Chih-Jen Lin, '...
'LIBSVM : a library for support vector machines, 2001. '...
'Software available at http://www.csie.ntu.edu.tw/~cjlin/libsvm '...
' '...
'--------------------------------------------------------------------- '...
'Copyright (c) 2000-2010 Chih-Chung Chang and Chih-Jen Lin '...
'All rights reserved. '...
' '...
'Redistribution and use in source and binary forms, with or without '...
'modification, are permitted provided that the following conditions '...
'are met: '...
' '...
'1. Redistributions of source code must retain the above copyright '...
'notice, this list of conditions and the following disclaimer. '...
' '...
'2. Redistributions in binary form must reproduce the above copyright '...
'notice, this list of conditions and the following disclaimer in the '...
'documentation and/or other materials provided with the distribution. '...
' '...
'3. Neither name of copyright holders nor the names of its contributors '...
'may be used to endorse or promote products derived from this software '...
'without specific prior written permission. '...
' '...
' '...
'THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS '...
'''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT '...
'LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR '...
'A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR '...
'CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, '...
'EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, '...
'PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR '...
'PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF '...
'LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING '...
'NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS '...
'SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'};

