function model = ldaimpl(varargin)
%LR Predictions based on softmax multinomial logistic regression model.
% Build a results struct from input X and Y block data. 
% Alternatively, if a model is passed in LR makes a Y prediction for an 
% input test X block.
%
% LR solves 
%
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
%        algorithm: [ {'svd'} | 'eig' | 'none'] specify
%                    the LR implementation to use: 
%                    'none' has no regularization,
%                    'eig' uses TODO,
%                    'svd' uses TODO
%          lambda : [{0.001}] Regularization parameter
%         waitbar : [ 'off' |{'auto'}| 'on' ] governs use of waitbar during
%                   analysis. 'auto' shows waitbar if delay will likely be
%                   longer than a reasonable waiting period.
%
%  OUTPUT:
%     model = standard model structure containing the ANN model (See MODELSTRUCT)
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: [model] = ldaimpl(x,y,options);
%I/O: [model] = ldaimpl(x,y,nhid,options);
%I/O:  [pred] = ldaimpl(x,model,options);
%I/O: [valid] = ldaimpl(x,y,model,options);
%
%See also: LRDA

% Copyright © Eigenvector Research, Inc. 1994
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Start Input
if nargin==0  % LAUNCH GUI
  analysis('lda')
  return
end

if ischar(varargin{1}) %Help, Demo, Options
  options = [];
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

% Prepare options.preprocessing
[inopts] = preppreprocessing(inopts);
preprocessing = inopts.preprocessing;

% Calibrate or apply model
if ~predictmode
  
  if mdcheck(x);
    if strcmp(inopts.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess". Results may be affected by this action.'); end
    [flag,missmap,x] = mdcheck(x);
    if length(y.include{1}) ~= length(x.include{1})
      %copy any changes over to y-block
      y.include{1} = x.include{1};
    end
  end
  
  % Apply preprocessing
  [xpp, ypp, preprocessing] = calibratepreprocessing(x, y, preprocessing);
  
%   LDA has no compression
  commodel = [];
  
  % Train on the included data
  [model] = calibratemodel(x, y, xpp, ypp, inopts, datasource, preprocessing, commodel);
  
else
  % Have model, do predict
  [model] = checkmodeltype(model);
  
  x = checkdatasizeandmissing(x, model);
  
  preprocessing = model.detail.preprocessing; %get preprocessing from model
  [xpp, ypp] = applypreprocessing(x, y, preprocessing, haveyblock);
  
  %copy info
  model = updatemodelfromx(model, x, y, datasource);
  
  % Make predictions
  [model] = applymodel(model, xpp);
end   % end if ~predict

%handle model blockdetails
if strcmp('standard', lower(inopts.blockdetails))
  model.detail.data{1} = [];
end

% calcystats expects its third and fourth args to be preprocessed.
% care for case where CV builds model on subset of all classes:
if size(ypp,2)==size(model.pred{2},2)
  model = calcystats(model,predictmode, ypp, model.pred{2});
end

%label as prediction
if predictmode
  model.modeltype = [model.modeltype '_PRED'];
else
  model = addhelpyvars(model);
end
end


%--------------------------------------------------------------------------
function [lda_model,Xlda,maxcomp] =  train(x,y, opts)
% TRAINING using preprocessed x and y are datasets
% INPUTS:
%      x: Preprocessed X-block dataset
%      y: Preprocessed Y-block dataset
%   opts: Options structure
%
% OUTPUTS:
% lda_model: struct with fields:
%      yp: Predicted y
%    prob: Per class probability of each sample
% lda_model has: prob, yp, calError


[m, n] = size(x); %  Setup the data matrix appropriately, and add ones for the intercept term
% Non dso input x,y have been converted to DSOs
indsx = x.includ;
indsy = y.includ;

% Build model using included data only
xd = x.data(indsx{:});
yd = y.data(indsy{:});

if ~isempty(opts.cvi) & isnumeric(opts.cvi) & length(opts.cvi)==size(x,1);
  opts.cvi = opts.cvi(indsx{1});
end

% % Preprocess x, y to range [0.1, 0.9] using only included data
% [xd, yd, rnge] = scaleset(xd, yd);

nclass = size(yd,2);
% convert logical y back to single column of integers 1, 2, ...
[~, yd] = max(yd,[],2);
ncomp  = opts.ncomp;
lambda = opts.lambda;
method = opts.algorithm;
[lda_model,Xlda,maxcomp] = lda_cal(xd, yd, ncomp, lambda, method);
%   lda_cal calibrates a regularized Linear Discriminant Analysis (LDA) model.
%   The 'method' input parameter determines whether to use 'eig' or 'svd', with 'svd' as the default.
end

%--------------------------------------------------------------------------
function est = updatewaitbar(hh, ii, nsplit, startat, opts)
fractelapsed = (ii-1)/nsplit;
fractremain = 1-fractelapsed;
est = round(((now-startat)*24*60*60*(fractremain/fractelapsed)));
if strcmp(opts.display, 'on')
  disp(sprintf('ii = %d, fraction elapsed = %4.4g, remaining = %4.4g, est = %4.4g', ii, fractelapsed, fractremain, est))
end
if strcmpi(opts.waitbar,'on')
  %update waitbar
  if ishandle(hh)
    if ~ishandle(hh)
      error('aborted by user');
    end
    if isfinite(est)
      timestr = besttime(est);
    else
      timestr = '-';
    end
    set(hh,'name',['Est. Time Remaining: ' timestr]);
  else
    error('Model optimization aborted by user');
  end
  waitbar(fractelapsed,hh)
end
end

%--------------------------------------------------------------------------
function [x,y, haveyblock] = converttodso(x,y, model, options)
%C) CHECK Data Inputs
if isa(x,'double')      %convert x and y to DataSets
  x        = dataset(x);
  x.name   = inputname(1);
  x.author = 'LR';
elseif ~isa(x,'dataset')
  error(['Input X must be class ''double'' or ''dataset''.'])
end
if ndims(x.data)>2
  error(['Input X must contain a 2-way array. Input has ',int2str(ndims(x.data)),' modes.'])
end

if ~isempty(y);
  haveyblock = 1;
  if isa(y,'double') | isa(y,'logical')
    y        = dataset(y);
    y.name   = inputname(2);
    y.author = 'LR';
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
end

%--------------------------------------------------------------------------
function [yp, hid] = apply(xin, W)
%
% Make prediction 
%
%	Input x and output y in REAL NON-SCALED UNITS
%
%		 yp = pred(x, W);
%

hid = [];
% if strcmp(W.type, 'mapa')
  [yp] = pred(xin, W);
% else
%   yp = predencog(xin, W);
% end
end

%--------------------------------------------------------------------------
function [y] = pred(x, theta);
%
% Linear Discriminant Analysis theta parameters used to predict
%
%	y = [1 X]*theta

y = [ones(size(x,1),1) x]*theta;

end

%--------------------------------------------------------------------------
function [result] = isclassification(args)
%ISCLASSIFICATION Test if args invoke classification type analysis.
% isclassification returns true if ANN type is classification, false otherwise.
%I/O: out = isclassification(args_struct);

%Copyright Eigenvector Research, Inc. 2010-2019
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

result = false;
if isfield(args, 'functionname')
  result = strcmpi(args.functionname, 'lda');
end
end

%--------------------------------------------------------------------------
function [x,y,xt,yt,model,inopts,predictmode] = parsevarargin(varargin)
%
%I/O: [model] = ldaimpl(x,y,options);
%I/O: [model] = ldaimpl(x,y,nhid);
%I/O: [ypred] = ldaimpl(x,y,model);
%I/O: [ypred] = ldaimpl(x,model,options);
%I/O: [ypred] = ldaimpl(x,y,model,options);
%I/O: [model] = ldaimpl(x,y,nhid,options);

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
    %    ldaimpl(x, model)
    %    ldaimpl(x,y)
    if isdataset(varargin{1}) | isnumeric(varargin{1})
      if ismodel(varargin{2})
        % (x,model)
        x = varargin{1};
        model  = varargin{2};
        y = [];
        if ~isempty(model.detail.options)
          inopts = model.detail.options;
        else
          inopts = ldaimpl('options');
        end
        predictmode = 1;
      elseif isdataset(varargin{2}) | isnumeric(varargin{2})
        % (x,y)
        x = varargin{1};
        y = varargin{2};
        inopts = ldaimpl('options');
        model  = [];
        predictmode = 0;
      else
        error('ldaimpl called with two arguments requires non-empty y or model as second argument.');
      end
    else
      error('ldaimpl called with two arguments requires non-empty x data array.');
    end
    
  case 3 % 3 arg:
    %    [model] = ldaimpl(x,y,options);
    %    [ypred] = ldaimpl(x,model,options);
    %    [ypred] = ldaimpl(x,y,model);
    %    [model] = ldaimpl(x,y,nhid);
    if ismodel(varargin{3})
      % (x,y,model)
      x = varargin{1};
      y = varargin{2};
      model  = varargin{3};
      if ~isempty(model.detail.options)
        inopts = model.detail.options;
      else
        inopts = ldaimpl('options');
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
        error('ldaimpl called with 3 arguments has unexpected second argument.');
      end
    elseif isnumeric(varargin{3})
      %   [model] = ldaimpl(x,y,nhid);
      x = varargin{1};
      y = varargin{2};
      model  = [];
      inopts = ldaimpl('options');
      predictmode = 0;
      hid = varargin{3};
    else
      error('ldaimpl called with 3 arguments has unexpected third argument.');
    end
    
  case 4 % 4 arg:
    %    [ypred] = ldaimpl(x, y, model, options);
    %    [model] = ldaimpl(x,y,nhid,options);
    if ismodel(varargin{3}) & isstruct(varargin{4})
      % (x,y,model, options)
      x = varargin{1};
      y = varargin{2};
      model  = varargin{3};
      inopts  = varargin{4};
      predictmode = 1;
    elseif isnumeric(varargin{3}) & isstruct(varargin{4})
      %    [model] = ldaimpl(x,y,nhid,options);
      x = varargin{1};
      y = varargin{2};
      nhid  = varargin{3};
      inopts = varargin{4};
      predictmode = 0;
    else
      error('ldaimpl called with 4 arguments has unexpected arguments.');
    end
    
  case 5 % 5 arg:
    %    [ypred] = ldaimpl(x, y, model, nhid, options);
    if ismodel(varargin{3}) & isnumeric(varargin{4}) & isstruct(varargin{5})
      %    [ypred] = ldaimpl(x, y, model, nhid, options);
      x = varargin{1};
      y = varargin{2};
      model = varargin{3};
      nhid = varargin{4};
      inopts = varargin{5};
      predictmode = 1;
    else
      error('ldaimpl called with 5 arguments has unexpected arguments.');
    end
    
  otherwise
    error('ldaimpl: unexpected number of arguments to function ("%s")', nargin);
end
end

%--------------------------------------------------------------------------
function [model] = calibratemodel(x, y, xpp, ypp, inopts, datasource, preprocessing, commodel)
%
% Train LDA on the included data
[ldastruct, Xlda, ncompmax]  = train(xpp, ypp, inopts);
% train calibrates LDA model, returns struct with fields Probs, Pred, calError 

varexp = ldastruct.varianceExplained * 100.0;
ilvs   = (1:length(varexp))';
ssq = [ilvs, ldastruct.eigenvalues, varexp, cumsum(varexp)];

% model
model = evrimodel('lda');   %  
model.loads{1}                = ldastruct.scores;
model.loads{2}                = ldastruct.w;
model.detail.data             = {x y};
model                         = copydsfields(x,model,[],{1 1});
model                         = copydsfields(y,model,[],{1 2});
model.detail.includ{1,2}      = x.include{1};  % x-includ samples for y too
model.datasource              = datasource;
model.detail.preprocessing    = preprocessing;
model.detail.predprobability  = ldastruct.Probs;
model.detail.lda              = ldastruct;
model.detail.options          = inopts;

% get results for all samples, not just included
ldastruct2 = lda_apply(model, xpp);
model.pred                    = {[] ldastruct2.Pred};
model.loads{1}                = ldastruct2.scores;
model.detail.predprobability  = ldastruct2.Probs;
% limit  to the max useful number of components,  num classes -1.
model.detail.ssq              = ssq; %ssq(1:(ldastruct.numClasses-1),:);      

%Set time and date.
model.date = date;
model.time = clock;
end

%--------------------------------------------------------------------------
function [xpp, ypp, preprocessing] = calibratepreprocessing(x, y, preprocessing)
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
end

%--------------------------------------------------------------------------
function [xpp, ypp] = applypreprocessing(x, y, preprocessing, haveyblock)
if haveyblock & ~isempty(preprocessing{2});
  [ypp]                        = preprocess('apply',preprocessing{2},y);
else
  ypp = y;
end
if ~isempty(preprocessing{1});
  [xpp]                        = preprocess('apply',preprocessing{1},x);
else
  xpp = x;
end
end

%--------------------------------------------------------------------------
function [inopts] = preppreprocessing(inopts)
% prepare options.preprocessing
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
% y-block preprocessing is NOT used with classification
if isclassification(inopts)
  inopts.preprocessing{2} = [];  %DROP ANY y-block preprocessing
end
end

%--------------------------------------------------------------------------
function [model] = checkmodeltype(model)
if ~strcmpi(model.modeltype,'lda')
  if strcmpi(model.modeltype,'ldapred'); %%% need to modify
    model.modeltype = 'LDA';
  else
    error('Input MODEL is not a LDA model');
  end
end
end

%--------------------------------------------------------------------------
function [x] = checkdatasizeandmissing(x, model)
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
end

%--------------------------------------------------------------------------
function [model] = updatemodelfromx(model, x, y, datasource)
model = copydsfields(x,model,1,{1 1});
model.detail.includ{1,2} = x.include{1};   %x-includ samples for y samples too
model.datasource = datasource;

%Update time and date.
model.date = date;
model.time = clock;
model.detail.data   = {x y};
end

%--------------------------------------------------------------------------
function [model] = applymodel(model, xpp)
%
% Make predictions for all samples, included or not.
ldastruct = lda_apply(model, xpp);
model.pred                    = {[] ldastruct.Pred};
model.detail.predprobability  = ldastruct.Probs;
model.loads{1}                = ldastruct.scores;
model.detail.lda              = ldastruct;
end

%--------------------------
function out = optiondefs()

defs = {
  %name                    tab              datatype        valid                            userlevel       description
  'display'                'Display'        'select'        {'on' 'off'}                     'novice'        'Governs level of display.';
  'displaymf'              'Display'        'select'        {'on' 'off'}                     'advanced'      'Governs level of minFunc display.';
  'plots'                  'Display'        'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
  'blockdetails'           'Standard'       'select'        {'standard' 'all'}               'novice'        'Extent of predictions and raw residuals included in model. ''standard'' = keeps only y-block, ''all'' keeps both x- and y- blocks.';
  'waitbar'                'Display'        'select'        {'on' 'off' 'auto'}              'novice'        'governs use of waitbar during analysis. ''auto'' shows waitbar if delay will likely be longer than a reasonable waiting period.';
  'algorithm'              'Standard'       'select'        {'eig' 'svd'}                    'novice'        [{'Algorithm to use. "svd" is default. "eig" is the alternative choice.'} ];
  'lambda'                 'Standard'       'double'        'float(0:inf)'                   'novice'        'Regularization parameter.';
  };
%   'maxIter'                'Standard'       'double'        'int(1:inf)'                     'advanced'      'Maximum number of iterations allowed.';

out = makesubops(defs);
end
