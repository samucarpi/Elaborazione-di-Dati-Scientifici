function model = lreg(varargin)
%LREG Predictions based on softmax multinomial logistic regression model.
% Build an LREG model from input X and Y block data. 
% Alternatively, if a model is passed in LREG makes a Y prediction for an 
% input test X block.
%
% LREG solves for the logistic regression model parameters using the minFunc
% software: 
% M. Schmidt. minFunc: unconstrained differentiable multivariate optimization
%   in Matlab. http://www.cs.ubc.ca/~schmidtm/Software/minFunc.html, 2005.
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
%        algorithm: [ {'ridge'} | 'none' | 'lasso' | 'elasticnet'] specify
%                    the LREG implementation to use: 
%                    'none' has no regularization,
%                    'ridge' uses L2 regularization,
%                    'lasso' uses L1 regularization, and
%                    'elasticnet' uses equally weighted L1 and L2 regularization.
%          lambda : [{0.1}] Regularization parameter
%         maxIter : [400] Maximum number of iterations allowed in the
%                    minFunc optimization solver.
%      compression: [{'none'}| 'pca' | 'pls' ] type of data compression
%                    to perform on the x-block prior to calculaing or
%                    applying the ANN model. 'pca' uses a simple PCA
%                    model to compress the information. 'pls' uses a pls
%                    model. Compression can make the ANN more stable and
%                    less prone to overfitting.
%    compressncomp: [ 1 ] Number of latent variables (or principal
%                    components to include in the compression model.
%       compressmd: [ 'no' |{'yes'}] Use Mahalnobis Distance corrected
%         waitbar : [ 'off' |{'auto'}| 'on' ] governs use of waitbar during
%                   analysis. 'auto' shows waitbar if delay will likely be
%                   longer than a reasonable waiting period.
%
%  OUTPUT:
%     model = standard model structure containing the ANN model (See MODELSTRUCT)
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: [model] = lreg(x,y,options);
%I/O: [model] = lreg(x,y,nhid,options);
%I/O:  [pred] = lreg(x,model,options);
%I/O: [valid] = lreg(x,y,model,options);
%
%See also: LREGDA

% Copyright © Eigenvector Research, Inc. 1994
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Start Input
if nargin==0  % LAUNCH GUI
  analysis('lreg')
  return
end

if ischar(varargin{1}) %Help, Demo, Options
  options = [];
  options.name          = 'options';
  options.display       = 'on';
  options.displaymf     = 'off';
  options.plots         = 'none';
  options.blockdetails  = 'standard';  %level of details
  options.algorithm     = 'ridge';
  options.lambda        = 0.1;
  options.maxIter       = 400;
  options.cvi           = [];
  options.preprocessing = {[] []};  %See preprocess
  options.compression   = 'none';
  options.compressncomp = 1;
  options.compressmd    = 'yes';
  options.waitbar       = 'on';
  options.definitions   = @optiondefs;
  
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
  
  % Apply compression
  [xpp, commodel] = getcompressionmodel(xpp, ypp, inopts);
  
  % Train ANN on the included data
  [model] = calibratemodel(x, y, xpp, ypp, inopts, datasource, preprocessing, commodel);
  
else
  % Have model, do predict
  [model] = checkmodeltype(model);
  
  x = checkdatasizeandmissing(x, model);
  
  preprocessing = model.detail.preprocessing; %get preprocessing from model
  [xpp, ypp] = applypreprocessing(x, y, preprocessing, haveyblock);
  
  if ~isempty(model.detail.compressionmodel)
    [xpp, model] = applycompressionmodel(xpp, model);
  end
  
  %copy info
  model = updatemodelfromx(model, x, y, datasource);
  
  % Make predictions
  [model] = applymodel(model, xpp);
end   % end if ~predict

%handle model blockdetails
if strcmp('standard', lower(inopts.blockdetails))
  model.detail.data{1} = [];
end

model.pred{2} = preprocess('undo',model.detail.preprocessing{2},model.pred{2});
model.pred{2} = model.pred{1,2}.data;
% calcystats expects its third and fourth args to be preprocessed.
model = calcystats(model,predictmode, ypp, model.pred{2});

%label as prediction
if predictmode
  model.modeltype = [model.modeltype '_PRED'];
else
  model = addhelpyvars(model);
end
end


%--------------------------------------------------------------------------
function [theta, yp, prob] =  train(x,y, opts)
% TRAINING ANN using preprocessed x and y are datasets
% INPUTS:
%      x: Preprocessed X-block dataset
%      y: Preprocessed Y-block dataset
%   opts: Options structure
%
% OUTPUTS:
%   theta: Parameters of the LR hypothesis function
%      yp: Predicted y
%    prob: Per class probability of each sample

% displayon = strcmp(opts.display, 'on');

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
switch opts.algorithm
  case 'none'
    reg = 0;
  case 'lasso'
    reg = 1;
  case 'ridge'
    reg = 2;
  case 'elastic net'
    reg = 3;
  otherwise
    error('Unknown algorithm type, %s', opts.algorithm);
end
% lambda = opts.lambda;
[theta, yp0] = lrengine(xd, yd, nclass, reg, opts); %lambda,reg);

% account for the offset by adding
yp = [ones(m,1) x.data(:, indsx{2})]*theta; % All samples, only incl vars

% CALC softmax probability here for all samples using yp (preprocessed y)
% Convert outSoftmax weights to Probabilities
prob = getsoftmax(yp);

% yp = unscale(yps, rnge.ymin, rnge.ymax);
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
  x.author = 'LREG';
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
    y.author = 'LREG';
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
% Make prediction using appropriate ANN implementation
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
        if strcmp(lower(options.functionname), 'lreg')
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
end

%--------------------------------------------------------------------------
function [result] = isclassification(args)
%ISCLASSIFICATION Test if args invoke classification type ANN analysis.
% isclassification returns true if ANN type is classification, false otherwise.
%I/O: out = isclassification(args_struct);

%Copyright Eigenvector Research, Inc. 2010-2019
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

result = false;
if isfield(args, 'functionname')
  result = strcmpi(args.functionname, 'lregda');
end
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
end

%--------------------------------------------------------------------------
function [x,y,xt,yt,model,inopts,predictmode] = parsevarargin(varargin)
%
%I/O: [model] = lreg(x,y,options);
%I/O: [model] = lreg(x,y,nhid);
%I/O: [ypred] = lreg(x,y,model);
%I/O: [ypred] = lreg(x,model,options);
%I/O: [ypred] = lreg(x,y,model,options);
%I/O: [model] = lreg(x,y,nhid,options);
%I/O: [ypred] = ann(x,y,model,nhid,options);

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
    %    lreg(x, model)
    %    lreg(x,y)
    if isdataset(varargin{1}) | isnumeric(varargin{1})
      if ismodel(varargin{2})
        % (x,model)
        x = varargin{1};
        model  = varargin{2};
        y = [];
        if ~isempty(model.detail.options)
          inopts = model.detail.options;
        else
          inopts = lreg('options');
        end
        predictmode = 1;
      elseif isdataset(varargin{2}) | isnumeric(varargin{2})
        % (x,y)
        x = varargin{1};
        y = varargin{2};
        inopts = lreg('options');
        model  = [];
        predictmode = 0;
      else
        error('lreg called with two arguments requires non-empty y or model as second argument.');
      end
    else
      error('lreg called with two arguments requires non-empty x data array.');
    end
    
  case 3 % 3 arg:
    %    [model] = lreg(x,y,options);
    %    [ypred] = lreg(x,model,options);
    %    [ypred] = lreg(x,y,model);
    %    [model] = lreg(x,y,nhid);
    if ismodel(varargin{3})
      % (x,y,model)
      x = varargin{1};
      y = varargin{2};
      model  = varargin{3};
      if ~isempty(model.detail.options)
        inopts = model.detail.options;
      else
        inopts = lreg('options');
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
        error('lreg called with 3 arguments has unexpected second argument.');
      end
    elseif isnumeric(varargin{3})
      %   [model] = lreg(x,y,nhid);
      x = varargin{1};
      y = varargin{2};
      model  = [];
      inopts = lreg('options');
      predictmode = 0;
      hid = varargin{3};
%       inopts = setlayernodes(inopts, hid);
    else
      error('lreg called with 3 arguments has unexpected third argument.');
    end
    
  case 4 % 4 arg:
    %    [ypred] = lreg(x, y, model, options);
    %    [model] = lreg(x,y,nhid,options);
    if ismodel(varargin{3}) & isstruct(varargin{4})
      % (x,y,model, options)
      x = varargin{1};
      y = varargin{2};
      model  = varargin{3};
      inopts  = varargin{4};
      predictmode = 1;
    elseif isnumeric(varargin{3}) & isstruct(varargin{4})
      %    [model] = lreg(x,y,nhid,options);
      x = varargin{1};
      y = varargin{2};
      nhid  = varargin{3};
      inopts = varargin{4};
%       inopts = setlayernodes(inopts, nhid);
      predictmode = 0;
    else
      error('lreg called with 4 arguments has unexpected arguments.');
    end
    
  case 5 % 5 arg:
    %    [ypred] = lreg(x, y, model, nhid, options);
    if ismodel(varargin{3}) & isnumeric(varargin{4}) & isstruct(varargin{5})
      %    [ypred] = lreg(x, y, model, nhid, options);
      x = varargin{1};
      y = varargin{2};
      model = varargin{3};
      nhid = varargin{4};
      inopts = varargin{5};
      predictmode = 1;
    else
      error('lreg called with 5 arguments has unexpected arguments.');
    end
    
  otherwise
    error('lreg: unexpected number of arguments to function ("%s")', nargin);
end
end

%--------------------------------------------------------------------------
function [model] = calibratemodel(x, y, xpp, ypp, inopts, datasource, preprocessing, commodel)
% Train LREG on the included data
% [W, niter, rmsec, rmsecv, rmsecviter, ypred0, ycvpp] =  train(xpp, ypp, inopts);
[theta, ypred0, prob] = train(xpp, ypp, inopts);
% train calls [theta,pred] = lrengine(xpp, ypp, nclass);  % k,lambda,reg)

% model
model = evrimodel('lreg');   %  'regression' LR
model.detail.lreg.theta = theta;
model.pred              = {[] ypred0};

model.detail.data = {x y};
model = copydsfields(x,model,[],{1 1});
model = copydsfields(y,model,[],{1 2});
model.detail.includ{1,2}      = x.include{1};   %x-includ samples for y samples too
model.datasource              = datasource;
model.detail.preprocessing    = preprocessing;   %copy calibrated preprocessing info into model
model.detail.compressionmodel = commodel;

%Set time and date.
model.date = date;
model.time = clock;
%copy options into model only if no model passed in
model.detail.options = inopts;
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
if ~strcmpi(model.modeltype,'lreg') & ~strcmpi(model.modeltype,'lregda')
  if strcmpi(model.modeltype,'lregpred'); %%% need to modify
    model.modeltype = 'LREG';
  else
    error('Input MODEL is not a LREG model');
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
% Make predictions for all samples, included or not.

indsx = xpp.include;
[ypred] = apply(xpp.data(:, indsx{2:end}), model.detail.lreg.theta);

model.pred  = {[] ypred};    % preprocessed yp. Will be unprocessed later
% model.rmsep is set later in calcystats
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
  'algorithm'              'Standard'       'select'        {'none' 'lasso' 'ridge' 'elastic net'}                  'novice'        [{'Algorithm to use. "Ridge" is default. "None", "Lasso", "Elastic Net" are alternative choices.'} getlregcp];
  'lambda'                 'Standard'       'double'        'float(0:inf)'                   'novice'        'Regularization parameter.';
  'maxIter'                'Standard'       'double'        'int(1:inf)'                     'advanced'      'Maximum number of iterations allowed.';
  'compression'            'Compression'    'select'        {'none' 'pca' 'pls'}             'novice'        'Type of data compression to perform on the x-block prior to LREG model. Compression can make the LREG more stable and less prone to overfitting. ''PCA'' is a principal components model and ''PLS'' is a partial least squares model (which may give improved sensitivity).';
  'compressncomp'          'Compression'    'double'        'int(1:inf)'                     'novice'        'Number of latent variables or principal components to include in the compression model.'
  'compressmd'             'Compression'    'select'        {'no' 'yes'}                     'novice'        'Use Mahalnobis Distance corrected scores from compression model.'
  };

out = makesubops(defs);
end

%-----------------------------------------------------------------
function out = getlregcp()

out  = {'The LREG method in PLS_Toolbox uses Matlab code provided by Mark Schmidt, e.g. '...
  'http://www.cs.ubc.ca/~schmidtm/Software/minFunc.html' ...
  ' ' ...
  'Copyright 2005-2015 Mark Schmidt. All rights reserved.  '...
  ' '...
  'Redistribution and use in source and binary forms, with or without modification, are ' ...
  'permitted provided that the following conditions are met: ' ...
  ' ' ...
  '   1. Redistributions of source code must retain the above copyright notice, this list of ' ...
  '      conditions and the following disclaimer. ' ...
  ' ' ...
  '   2. Redistributions in binary form must reproduce the above copyright notice, this list ' ...
  '      of conditions and the following disclaimer in the documentation and/or other materials ' ...
  '      provided with the distribution. ' ...
  ' ' ...
  'THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY EXPRESS OR IMPLIED ' ...
  'WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND ' ...
  'FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR ' ...
  'CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR ' ...
  'CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR ' ...
  'SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ' ...
  'ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING ' ...
  'NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ' ...
  'ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. ' };

out = cell2str(out,newline);
end

