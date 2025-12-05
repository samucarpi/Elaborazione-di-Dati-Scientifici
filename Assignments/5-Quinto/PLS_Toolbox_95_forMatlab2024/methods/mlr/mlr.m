function varargout = mlr(varargin)
%MLR Multiple Linear Regression for multivariate Y.
%  MLR identifies models of the form Xb = y + e or XB = Y + E.
%  INPUTS:
%        x  = X-block: predictor block (2-way array or DataSet Object),
%        y  = Y-block: predicted block (2-way array or DataSet Object), and
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%           display: [ 'off' | {'on'} ]      governs level of display to command window.
%             plots: [ 'none' | {'final'} ]  governs level of plotting.
%         algorithm: [{'leastsquares'} 'ridge' 'ridge_hkb' 'optimized_ridge' 'optimized_lasso' 'elasticnet'] Governs the
%                    level of regularization used when calculating the 
%                    regression vector. 'leastsquares' uses the normal equation without regularization.
%                    'ridge' uses the L2 penalty via the normal equation,
%                    'ridge_hkb' uses the L2 penalty with x'*x instead of
%                    the Identity matrix, 'optimized_ridge' uses the L2 penalty through an
%                    optimization approach, 'optimized_lasso' uses the L1 penalty, and 'elasticnet' uses both L1 and L2.
%             ridge: Value for ridge regression using the normal equation.
%   optimized_ridge: Value(s) for the ridge parameter to use in regularizing the inverse
%                    for optimized_ridge or elasticnet regression.
%   optimized_lasso: Value(s) for the lasso parameter to use in regularizing the inverse
%                    for lasso or elasticnet regression.
%           condmax: [{[]}] maximum condition number for inv(x'*x) {default:
%                    condmax>Nx*eps(norm(A))}. Provides ~principal components regression behavior to
%                    avoid rank deficiency during caluclation of inv(x'*x).
%                    Only used when 'algorithm' is 'leastsquares'.
%                cvi: {{'rnd' 5}} Standard cross-validation cell (see crossval)
%                     defining a split method, number of splits, and number
%                     of iterations. This cross-validation is use both for
%                     parameter optimization and for error estimate on the
%                     final selected parameter values. 
%                     Alternatively, can be a vector with the same number 
%                     of elements as x has rows with integer values
%                     indicating CV subsets (see crossval).
%     preprocessing: { [] [] }               preprocessing structure (see PREPROCESS).
%      blockdetails: [ {'standard'} | 'all' ]  Extent of predictions and raw residuals
%                     included in model. 
%                     'standard' = only y-block, 'all' x and y blocks
%
%  OUTPUT:
%     model = standard model structure containing the MLR model (See MODELSTRUCT)
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: model = mlr(x,y,options);       %identifies model (calibration step)
%I/O: pred  = mlr(x,model,options);   %makes predictions with a new X-block
%I/O: valid = mlr(x,y,model,options); %makes predictions with new X- & Y-block
%I/O: mlr demo                        %runs a demo of the MLR function
%I/O: options = mlr('options');       %returns a default options structure
%
%See also: ANALYSIS, CROSSVAL, ILS_ESTERROR, MLRENGINE, MODELSTRUCT, PCR, PLS, PREPROCESS, RIDGE, TESTROBUSTNESS

%Copyright Eigenvector Research, Inc. 1995
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 5/12/05 derrived from PCR

%Start Input
if nargin==0  % LAUNCH GUI
  analysis mlr
  return
elseif ischar(varargin{1}) %Help, Demo, Options
  options = [];
  options.name          = 'options';
  options.display       = 'on';     %Displays output to the command window
  options.plots         = 'final';  %Governs plots to make
  options.preprocessing = {[] []};  %See preprocess
  options.ridge         = 1;
  options.optimized_ridge         = logspace(-5,0.25,10);
  options.optimized_lasso         = logspace(-5,0.25,10);
  options.condmax       = [];
  options.algorithm     = 'leastsquares';
  options.cvi           = {'vet' 10};
  options.blockdetails  = 'standard';  %level of details
  options.definitions   = @optiondefs;

  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;

end

if nargin<2
  error([ upper(mfilename) ' requires 2 inputs.'])
end

%A) Check Options Input
predictmode = 0;    %default is calibrate mode

switch nargin
  case 2  %two inputs
    %v3 : (x,model)
    %v3 : (x,y)
    if ismodel(varargin{2})
    %v3 : (x,model)
      varargin = {varargin{1},[],[],[],varargin{2}};
    else
    %v3 : (x,y)
      varargin = {varargin{1},varargin{2},[],[]};
    end

  case 3  %three inputs
    %v3 : (x,y,model)
    %v3 : (x,model,options)

    if ismodel(varargin{2})
      %v3 : (x,model,options)
      varargin = {varargin{1},[],[],varargin{3},varargin{2}};
    elseif ~ismodel(varargin{3})
      %v3 : (x,y,options)
      varargin = {varargin{1},varargin{2},[],varargin{3}};
    else
      %v3 : (x,y,model)
      varargin{5} = varargin{3};        %check model format later
      varargin{4} = [];                 %get default options
      varargin{3} = [];
    end

  case 4   %four inputs
    %v3 : (x,y,model,options)
    %v3 : (x,y,ncomp,options)   %ncomp is acceptable but not used

    if ismodel(varargin{3})
      %v3 : (x,y,model,options)
      varargin{5} = varargin{3};
      varargin{3} = [];
    end
  case 5  %five inputs
    %v3 : (x,y,ncomp,model,options)
    %v3 : (x,y,ncomp,options,model)
    if ismodel(varargin{4})
      %make sure model is 5 and options are 4
      varargin(4:5) = varargin([5 4]);
    end
end
varargin{3} = [];

%at this point varargin is:   { x , y , [] , options , model }

options = reconopts(varargin{4},mlr('options'));

options.blockdetails = lower(options.blockdetails);
if ~ismember(options.blockdetails,{'compact','standard','all'})
  error(['OPTIONS.BLOCKDETAILS not recognized. Type: ''help ' mfilename ''''])
end
if ~isfield(options,'rawmodel')
  options.rawmodel = 0;       %undocumented option to output raw results ONLY
end

%B) check model format
if length(varargin)>=5
  try
    varargin{5} = updatemod(varargin{5});        %make sure it's an up-to-date model format
  catch
    error(['Input MODEL not recognized. Type: ''help ' mfilename ''''])
  end
  predictmode = 1;                                  %and set predict mode flag
end

%C) CHECK Data Inputs
[datasource{1:2}] = getdatasource(varargin{1:2});
if isa(varargin{1},'double')      %convert varargin{1} and varargin{2} to DataSets
  varargin{1}        = dataset(varargin{1});
  varargin{1}.name   = inputname(1);
  varargin{1}.author = 'MLR';
elseif ~isa(varargin{1},'dataset')
  error(['Input X must be class ''double'' or ''dataset''.'])
end
if ndims(varargin{1}.data)>2
  error(['Input X must contain a 2-way array. Input has ',int2str(ndims(varargin{1}.data)),' modes.'])
end

if ~isempty(varargin{2})
  haveyblock = 1;
  if isa(varargin{2},'double') | isa(varargin{2},'logical')
    varargin{2}        = dataset(varargin{2});
    varargin{2}.name   = inputname(2);
    varargin{2}.author = 'MLR';
  elseif ~isa(varargin{2},'dataset')
    error(['Input Y must be class ''double'', ''logical'' or ''dataset''.'])
  end
  if isa(varargin{2}.data,'logical')
    varargin{2}.data = double(varargin{2}.data);
  end
  if ndims(varargin{2}.data)>2
    error(['Input Y must contain a 2-way array. Input has ',int2str(ndims(varargin{2}.data)),' modes.'])
  end
  if size(varargin{1}.data,1)~=size(varargin{2}.data,1)
    error('Number of samples in X and Y must be equal.')
  end
  %Check INCLUD fields of X and Y
  i       = intersect(varargin{1}.includ{1},varargin{2}.includ{1});
  if ( length(i)~=length(varargin{1}.includ{1,1}) | ...
      length(i)~=length(varargin{2}.includ{1,1}) )
    if (strcmpi(options.display,'on')|options.display==1)
      disp('Warning: Number of samples included in X and Y not equal.')
      disp('Using intersection of included samples.')
    end
    varargin{1}.includ{1,1} = i;
    varargin{2}.includ{1,1} = i;
  end
  %Change include fields in y dataset. Confirm there are enough y columns
  %before trying.
  if length(varargin)>=5
    if size(varargin{2}.data,2)==length(varargin{5}.detail.includ{2,2})
      %SPECIAL CASE - ignore the y-block column include field if the
      %y-block contains the same number of columns as the include field.
      varargin{5}.detail.includ{2,2} = 1:size(varargin{2}.data,2);
    else
      %otherwise, do the rest of this to match include fields with y.
      if size(varargin{2}.data,2) < length(varargin{5}.detail.includ{2,2})
        %trap this one error to give more diagnostic information than the
        %error below gives
        error('Y-block columns included in model do not match number of columns in test set.');
      end
      try
        varargin{2}.include{2} = varargin{5}.detail.includ{2,2};
      catch
        error('Model include field selections will not work with current Y-block.');
      end
    end
  end
else    %empty y = NOT haveyblock mode (predict ONLY)
  haveyblock = 0;
end

%----------------------------------------------------------------------------------------
x = varargin{1};
y = varargin{2};

if isempty(options.preprocessing)
  options.preprocessing = {[] []};  %reinterpet as empty for both blocks
end
if ~isa(options.preprocessing,'cell') | length(options.preprocessing)<2
  error('option.preprocessing must be cell array of preprocessing structures.')
end

preprocessing = options.preprocessing;

if ~predictmode

  if mdcheck(x)
    if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess". Results may be affected by this action.'); end
    [~,~,x] = mdcheck(x); %[flag,missmap,x] = mdcheck(x);
    if length(y.include{1}) ~= length(x.include{1})
      %copy any changes over to y-block
      y.include{1} = x.include{1};
    end
  end

  if ~isempty(preprocessing{2})
    [ypp,preprocessing{2}] = preprocess('calibrate',preprocessing{2},y);
  else
    ypp = y;
    preprocessing{2} = [];
  end
  if ~isempty(preprocessing{1})
    [xpp,preprocessing{1}] = preprocess('calibrate',preprocessing{1},x,ypp);
  else
    xpp = x;
    preprocessing{1} = [];
  end

  %Call MLR Function
  model = mlrregression(xpp,ypp,options,preprocessing);
  model.detail.preprocessing = preprocessing;   %copy calibrated preprocessing info into model
  model.datasource = datasource;
  model.algorithm = options.algorithm;

else    %5 inputs implies that input #5 is a raw model previously output, don't decompose/regress

  model = varargin{5};
  if ~strcmpi(model.modeltype,'mlr')
    error('Input MODEL is not a MLR model');
  end

  if size(x.data,2)~=model.datasource{1}.size(1,2)
    error('Variables included in data do not match variables expected by model');
  else
    missing = setdiff(model.detail.includ{2,1},x.include{2,1});
    x.data(:,missing) = nan;  %replace expected but missing data with NaN's to force replacement
    x.includ{2,1} = model.detail.includ{2,1};
  end

  if mdcheck(x.data(:,x.includ{2,1}))
    if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess" from existing model. Results may be affected by this action.'); end
    x = replacevars(model,x);
  end

  preprocessing = model.detail.preprocessing;   %get preprocessing from model
  if haveyblock & ~isempty(preprocessing{2})
    [ypp]                           = preprocess('apply',preprocessing{2},y);
  else
    ypp = y;
  end
  if ~isempty(preprocessing{1})
    [xpp]                           = preprocess('apply',preprocessing{1},x);
  else
    xpp = x;
  end

  model = copydsfields(x,model,[1],{1 1});
  model.detail.includ{1,2} = x.includ{1};
  model.datasource = datasource;

  %Update time and date.
  model.date = date;
  model.time = clock;

end

%copy options into model
model.detail.options = options;
if ismember(options.algorithm,{'optimized_ridge' 'optimized_lasso' 'elasticnet'})
  model.detail.options.optimized_ridge = model.detail.mlr.best_params.optimized_ridge;
  model.detail.options.optimized_lasso = model.detail.mlr.best_params.optimized_lasso;
end

if options.rawmodel & ~predictmode
  varargout{1} = model;   %pass raw model info out as output
else
  if options.rawmodel & predictmode; predictmode = 0; end
  %rawmodel here means that this is really just a normal "reduce raw model" call, do NOT treat as predictmode

  %X-Block Statistics
  model.detail.data{1}  = x;
                
  if ~predictmode
    model.detail.selratio = sratio(xpp,model,struct('preprocessed',true));
  end
  
  %calculate t2 and leverage
  %note that these calculations include calculating the covariance matrix
  %which could be HUGE for lots of variables, but since MLR isn't
  %particularly useful with lots of variables, we'll risk it but put a
  %try/catch around this to assure we still get a model (albeit without T2
  %and leverage) if it fails.
  if ~predictmode
    origmodel = model;
  else
    origmodel = varargin{5};   %get pointer to original model
  end
  try  %particularly here for MEMORY issues
    if ~predictmode
      %calculate cov matrix and save it
      c = xpp.data.include'*xpp.data.include/(length(xpp.include{1})-1);
      model.detail.cov = c;
    else
      %retreive cov matrix from model
      c = model.detail.cov;
    end
    if ~isempty(c)
      %only do this if we had a covariance matrix. no covariance matrix
      %indicates old model where we couldn't calculate it - skip these
      %stats for those old models
      m = length(origmodel.detail.includ{1,1});
      t2raw = xpp.data(:,xpp.include{2})/c.*xpp.data(:,xpp.include{2});
      model.tsqs{1,1} = sum(t2raw,2);  %same as diag(X*pinv(C)*X')
      model.detail.leverage = model.tsqs{1,1}/(m-1);
      clear t2raw c  %force clearing now
    end
  catch
    %no T2 or leverage calculated
    le = lasterror;
    if isempty(strfind(lower(le.message),'memory'))
      %not a memory issue? throw error normally
      rethrow(le)
    end
    %memory errors are ignored
  end

  %Y-Block Statistics
  %store original and predicted Y values
  model.detail.data{1,2}   = y;
  ypred                    = xpp.data(:,xpp.includ{2})*model.reg;
  model.pred{1,2}   = preprocess('undo',preprocessing{2},ypred);
  model.pred{1,2}   = model.pred{1,2}.data;
  model = calcystats(model,predictmode,ypp,ypred);
  model.algorithm = origmodel.algorithm;

  %test for Compact Blockdetails with calibrate mode
  if ~predictmode & strcmp(options.blockdetails,'compact')
    options.blockdetails = 'standard';
  end

  %label as prediction
  if predictmode
    model.modeltype = [model.modeltype '_PRED'];
    % inherit same algorithm value from original model
    if isfield(origmodel.detail.options,'algorithm')
      model.detail.options.algorithm = origmodel.detail.options.algorithm;
    end
  else
    model = addhelpyvars(model);
  end

  %handle model compression
  switch lower(options.blockdetails)
    case {'compact' 'standard'}
      model.detail.data{1} = [];
      model.pred{1} = [];
      model.detail.res{1}  = [];
  end

  varargout{1} = model;
end

try
  switch lower(options.plots)
    case 'final'
      if ~predictmode
        plotloads(model);
        plotscores(model);
      else
        plotscores(varargin{5},model);
      end
  end
catch
  warning('EVRI:PlottingError',lasterr)
end

%End Input

%-----------------------------------------------------------------------
%Functions
function model = mlrregression(x,y,options,preprocessing);

%call model = mlrregression(xpp,ypp,options);

m       = length(x.includ{1,1});  %= y.includ{1}
nx      = length(x.includ{2,1});
ny      = length(y.includ{2,1});

model            = modelstruct('mlr');

model.date       = date;
model.time       = clock;
model.detail.means{1,1}  = NaN*ones(1,size(x.data,2));
model.detail.means{1,2}  = NaN*ones(1,size(y.data,2));
model.detail.means{1,1}(1,x.includ{2}) = ...
  mean(x.data(x.includ{1},x.includ{2})); %mean of X-block
model.detail.means{1,2}(1,y.includ{2}) = ...
  mean(y.data(y.includ{1},y.includ{2})); %mean of Y-block
model.detail.stds{1,1}   = NaN*ones(1,size(x.data,2));
model.detail.stds{1,2}   = NaN*ones(1,size(y.data,2));
model.detail.stds{1,1}(1,x.includ{2}) = ...
  std(x.data(x.includ{1},x.includ{2})); %std of X-block
model.detail.stds{1,2}(1,y.includ{2}) = ...
  std(y.data(y.includ{1},y.includ{2})); %std of Y-block

model = copydsfields(x,model,[],{1 1});
model = copydsfields(y,model,[],{1 2});

if ~all([length(x.includ{1}) length(x.includ{2})] == size(x.data))
  xsub = x.data(x.includ{1},x.includ{2});
else
  xsub = x.data;
end
if ~all([length(y.includ{1}) length(y.includ{2})] == size(y.data))
  ysub = y.data(y.includ{1},y.includ{2});
else
  ysub = y.data;
end

model = mlrOptimize(xsub,x,ysub,y,options,preprocessing,model);

%model.reg        = reg;
%   model.loads = {zeros(m,1);zeros(1,nx)};
% model.detail.ssq = [];

%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab           datatype        valid                            userlevel       description
'display'                'Display'     'select'        {'on' 'off'}                     'novice'        '[ {''off''} | ''on''] governs level of display.';
'plots'                  'Display'     'select'        {'none' 'final'}                 'novice'        '[ ''none'' | {''final''} ]  governs level of plotting.';
'preprocessing'          'Set-Up'      'cell(vector)'  ''                               'novice'        '{[ ]} preprocessing structure (see PREPROCESS).';
'blockdetails'           'Set-Up'      'select'        {'standard' 'all'}               'novice'        '[ {''standard''} | ''all'' ] Extent of predictions and raw residuals included in model. ''standard'' = only y-block, ''all'' x and y blocks.'; 
'algorithm'              'Set-Up'      'select'        {'leastsquares' 'ridge' 'ridge_hkb' 'optimized_ridge' 'optimized_lasso' 'elasticnet'}  'novice'  'Governs the level of regularization used when calculating the regression vector. ''leastsquares'' uses the normal equation without regularization. ''ridge'' uses the L2 penalty via the normal equation, ''ridge_hkb'' uses the L2 penalty with x''*x instead of the Identity matrix, ''optimized_ridge'' uses the L2 penalty through an optimization approach, ''optimized_lasso'' uses the L1 penalty, and ''elasticnet'' uses both L1 and L2.'
'ridge'                  'Set-Up'      'mode'          'float(0:inf)'                   'novice'        'Value for ridge regression using the normal equation.';
'optimized_ridge'        'Set-Up'      'mode'          'float(0:inf)'                   'novice'        'Penalty value used when using ridge regularization';
'optimized_lasso'        'Set-Up'      'mode'          'float(0:inf)'                   'novice'        'Penalty value used when using lasso regularization';
'condmax'                'Set-Up'      'mode'          'float(0:inf)'                   'novice'        'maximum condition number for inv(x''*x) {default: condmax>Nx*eps(norm(A))}. Provides ~principal components regression behavior to avoid rank deficiency during caluclation of inv(x''*x).';
};

out = makesubops(defs);
