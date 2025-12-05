function model = umap(varargin)
%Uniform Manifold Approximation and Projection for dimension reduction.
% Python implementation of the UMAP algorithm from the UMAP package. The
% algorithm tries to model the data as a fuzzy topological structure.
% The embedding is found by searching for a lower dimensional space
% that most closely resembles the topological structure of the manifold.
% This algorithm can be used in a supervised & unsupervised setting, so it
% can take either an x-block, or a x-block and y-block.
% More details on UMAP documentation page here:
% [https://umap-learn.readthedocs.io/en/latest/].
%
% INPUTS:
%        x  = X-block (predictor block) class "double" or "dataset",
%        y  = Y-block (predicted block) class "double" or "dataset",
%    model  = previously generated model (when applying model to new data)
%
%  Optional input (options) is a
%  structure containing one or more of the following fields:
%         display : [ 'off' |{'on'}] Governs display
%           plots : ['none' | {'final'}]  %Governs plots to make
%        warnings : [{'off'} | 'on'] Silence or display any potential Python warnings.
%     n_neighbors : [{15}] Number of neighbors to consider. Controls
%                     the balance between local and global structure in the data.
%        min_dist : [{0.100}] Minimum distance from data points in the low dimensional representation.
%         spread  : [{1}] The effective scale of embedded points. In combination with min_dist this determines how clustered/clumped the embedded points are.
%    n_components : [{2}] The dimensionality of the reduced space.
%          metric : [{'euclidean'} | 'manhattan' 'cosine' 'mahalanobis']
%                     The metric used to calculate distance between data points.
%    random_state :[{1}] Random seed number. Set this to a number for reproducibility.
%      blockdetails: [ {'standard'} | 'all' ]   Extent of predictions and raw residuals
%                     included in model. 'standard' = none, 'all' x-block
%      compression: [{'none'}| 'pca'] type of data compression
%                    to perform on the x-block prior to calculating or
%                    applying the UMAP model. 'pca' uses a simple PCA
%                    model to compress the information.
%    compressncomp: [{2}] Number of latent variables (or principal
%                    components to include in the compression model).
%       compressmd: [ 'no' |{'yes'}] Use Mahalnobis Distance corrected
%
%  OUTPUT:
%     model = standard model structure containing the ANN model (See MODELSTRUCT)
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: [model] = umap(x,options);
%I/O: [ypred] = umap(x,model);
%I/O: [model] = umap(x,y,options);
%I/O: [ypred] = umap(x,y,model);
%I/O: [ypred] = umap(x,model,options);
%I/O: [ypred] = umap(x,y,model,options);
%
%See also: TSNE

% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Start Input
if nargin==0  % LAUNCH GUI
  analysis('umap')
  return
end

if ischar(varargin{1}) %Help, Demo, Options
  options = [];
  options.name                        = 'options';
  options.display                     = 'on';     %Displays output to the command window
  options.plots                       = 'final';  %Governs plots to make
  options.warnings                    = 'off';
  options.preprocessing               = {[]};     %See Preprocess
  options.blockdetails                = 'standard';
  options.n_neighbors                 = 15;    
  options.min_dist                    = 0.1000;  
  options.spread                      = 1;
  options.n_components                = 2;
  options.metric                      = 'euclidean'; 
  options.random_state                = 1;
  options.compression                 = 'none';
  options.compressncomp               = 2;
  options.compressmd                  = 'yes';
  options.roptions.cutoff = [];   %similar to confidencelimit for robust outlier detection
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
    if ~isempty(y) & (length(y.include{1}) ~= length(x.include{1}))
      %copy any changes over to y-block
      y.include{1} = x.include{1};
    end
  end
  
  if ~isempty(preprocessing{2}) & ~isempty(y);
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
  if ~isempty(ypp)
    [xpp, commodel] = getcompressionmodel(xpp, ypp, inopts);
  else
    [xpp, commodel] = getcompressionmodel(xpp, inopts);
  end
  
  % Train UMAP on the included data
  % train should be able to take in (x, inopts) or (x, y, inopts)
  
  train_args = {xpp};
  if ~isempty(ypp)
    train_args{2} = ypp;
    train_args{3} = inopts;
  else
    train_args{2} = inopts;
  end
  
  
  pyModel =  train(train_args);
  model = umapstruct;
  model.detail.umap.embeddings = pyModel.embeddings;
  model.loads{1,1} = model.detail.umap.embeddings;
  model.detail.umap.model = pyModel.model;
  model.detail.umap.supervised = pyModel.supervised;
  model.detail.umap.graph = pyModel.graph;
  model.detail.umap.linewidths = pyModel.linewidths;
  if ~isempty(preprocessing{1}) && ~isempty(pyModel.xhat)
    warning off;
    xhat = preprocess('undo',preprocessing{1},pyModel.xhat);
    model.detail.umap.xhat = xhat.data;
    warning on;
  else
    model.detail.umap.xhat = pyModel.xhat;
  end
    
  
  model.detail.data = x;
  model = copydsfields(x,model,[],{1 1});
  if ~isempty(y)
    model = copydsfields(y,model,[],{1 2});
  end
  model.detail.includ{1,2} = x.include{1};   %x-includ samples for y samples too
  model.datasource = datasource;
  model.detail.preprocessing = preprocessing;   %copy calibrated preprocessing info into model
  model.detail.compressionmodel = commodel;
  
  %{
  % Calculate rmsecv using ycv (preprocessed) for the optimal learn cycles
  model.detail.rmsecv = nan(1, inopts.nhid1); %size(model.detail.ann.W.w1,2));
  if ~isempty(ycvpp)
    ycv = preprocess('undo',model.detail.preprocessing{2}, ycvpp);
    yincl = y.data(y.include{1},y.include{2});
    model.detail.rmsecv(1, inopts.nhid1) = rmse(yincl(:), ycv.data(:));;
  end
  %}
  
  %Set time and date.
  model.date = date;
  model.time = clock;
  %copy options into model only if no model passed in
  model.detail.options = inopts;
  
else
  % have model, do predict
  if ~strcmpi(model.modeltype,'UMAP')
    error('Input MODEL is not a UMAP model');
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
  %[ypred xhat] = apply(xpp.data(:, indsx{2:end}), model, inopts); % Make predictions for all samples, included or not.
  [ypred xhat] = apply(xpp.data(:, indsx{2:end}), model, model.detail.options); % Make predictions for all samples, included or not.
  model.detail.data   = {x y};
  model.detail.umap.embeddings  = ypred;
  model.loads{1,1} = ypred;
  model.detail.umap.xhat  = xhat;
  
  % model.rmsep is set later in calcystats
end   % end if ~predict

%handle model blockdetails
if ~isempty(model.detail.umap.xhat)
  x_hat = model.detail.umap.xhat;
  model.detail.res{1}     = xpp.data(xpp.include{1},xpp.include{2}) - x_hat(xpp.include{1},:);
  model.ssqresiduals{1,1} = model.detail.res{1}.^2;
  model.ssqresiduals{2,1} = sum(model.ssqresiduals{1,1},1); %var SSQs based on cal samples only
  model.ssqresiduals{1,1} = sum(model.ssqresiduals{1,1},2);
end
%where is the class set? 
if ~isempty(x.class{1})
  %class set is in x
  [ratio_min,ratio_mean] = calculate_distanceratio(model.detail.umap.embeddings,x.class{1}(x.include{1}));
  model.detail.umap.distance_metrics.ratio_min         = ratio_min;
  model.detail.umap.distance_metrics.ratio_mean        = ratio_mean;
elseif ~isempty(y) && isint(y.data)
  %y is the class set
  [ratio_min,ratio_mean] = calculate_distanceratio(model.detail.umap.embeddings,y.data);
  model.detail.umap.distance_metrics.ratio_min         = ratio_min;
  model.detail.umap.distance_metrics.ratio_mean        = ratio_mean;
end



if strcmp('standard', lower(inopts.blockdetails))
  model.pred{1} = [];
end

% calcystats expects its third and fourth args to be preprocessed.
%{
ypredpp = model.pred{2};
model.pred{2} = preprocess('undo',model.detail.preprocessing{2},model.pred{2});
model.pred{2} = model.pred{1,2}.data;
model = calcystats(model,predictmode,ypp,ypredpp);
% if ~predictmode
%   %add info to ssq table's y-columns
%   model.detail.ssq(end,4:5) = [nan nan];
% end
%}
%label as prediction
if predictmode
  model.modeltype = [model.modeltype '_PRED'];
end
%}

%--------------------------------------------------------------------------
function [pyModel] =  train(varargin)
% TRAINING UMAP using Python implementation. Send included samples to buildUMAP.
% x and y are datasets


varargin = varargin{1};
[x,y,xt,yt,model,inopts,predictmode] = parsevarargin(varargin);

%displayon = strcmp(opts.display, 'on');


%{
if ~isempty(opts.cvi) & isnumeric(opts.cvi) & length(opts.cvi)==size(x,1);
 opts.cvi = opts.cvi(indsx{1});
end
%}




build_args = {x};
if ~isempty(y)
  indsy = y.includ;
  yd = y.data(indsy{:});
  build_args{2} = yd;
  build_args{3} = inopts;
else
  build_args{2} = inopts;
end


pyModel = buildumap(build_args);

%--------------------------------------------------------------------------

function [ypred xhat] = apply(xin, model, inopts);
%
% Make prediction using calibrated UMAP model
% Apply using evriPyClient
%
%

% build client
%inopts.functionname = 'umap';
client = evriPyClient(inopts,model.detail.umap.model);
client = client.apply(xin);
ypred = client.validation_pred;
xhat = client.extractions.xhat;
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

%--------------------------------------------------------------------------
function [x, y, haveyblock] = converttodso(x, y, model, options)
%C) CHECK Data Inputs
if isa(x,'double')      %convert x and y to DataSets
  x        = dataset(x);
  x.name   = inputname(1);
  x.author = 'UMAP';
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
    y.author = 'UMAP';
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
    % add something here
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
function outstruct = umapstruct
outstruct = modelstruct('umap');

%--------------------------------------------------------------------------
function [xpp, commodel] = getcompressionmodel(varargin)
%
% compress X-block data
%
% Apply data compression if desired by user

xpp = varargin{1};
if nargin==2
  ypp = [];
  options = varargin{2};
elseif nargin==3
  ypp = varargin{2};
  options = varargin{3};
end

switch options.compression
  case {'pca'}
    switch options.compression
      case 'pca'
        comopts = struct('display','off','plots','none','confidencelimit',0,'preprocessing',{{[] []}});
        commodel = pca(xpp,options.compressncomp,comopts);
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
%I/O: [model] = umap(x,options);      coded
%I/O: [ypred] = umap(x,model);        coded

%I/O: [model] = umap(x,y,options);       coded
%I/O: [ypred] = umap(x,y,model);         coded
%I/O: [ypred] = umap(x,model,options);   coded

%I/O: [ypred] = umap(x,y,model,options);    coded


x           = [];
y           = [];
xt          = [];
yt          = [];
model       = [];
inopts      = [];
predictmode = true;

varargin = varargin{1};
nargin = length(varargin);
% x should be first arg in all cases of nargin. Take care of it here.
% data will be true when conditioned on: isdataset | (isnumeric & numel>1)
% n_comp will when isnumeric & numel==1 is true
% isstruct(some model object) will return 1

if isdataset(varargin{1}) | (isnumeric(varargin{1}) & numel(varargin{1})>1)
  %treat first arg as x
  x = varargin{1};
else
  error('umap requires non-empty x data array as first argument.');
end
switch nargin
  case 2  % 2 arg:
    if ismodel(varargin{2})
      % (x,model)
      model = varargin{2};
      predictmode = 1;
      
    elseif isstruct(varargin{2}) & ~ismodel(varargin{2})
      % (x,options)
      inopts = varargin{2};
      predictmode = 0;
    else
      error('umap called with two arguments requires model, number of components, or options structure as second argument.');
    end
  case 3  % 3 arg
    if isdataset(varargin{2}) | isnumeric(varargin{2})
      %treat second arg as y
      % (x, y, ...)
      error('Supervised UMAP is currently not supported.');
      y = varargin{2};
      %%third arg can be options, or model
      if ismodel(varargin{3})
        % (x, y, model)
        inopts = umap('options');
        model = varargin{3};
        predictmode = 1;
      elseif isstruct(varargin{3}) & ~ismodel(varargin{3})
        % (x, y, options)
        inopts = varargin{3};
        predictmode = 0;
      else
        error('umap called with three arguments has an unexpected third argument')
      end
      %%actually condition on 3, since it has to be options, determine 2
    elseif isstruct(varargin{3}) & ~ismodel(varargin{3})
      % (x, ..., options)
      inopts = varargin{3};
      % now 2 has to be model
      if ismodel(varargin{2})
        % (x, model, options)
        model = varargin{2};
        predictmode = 1;
      else
        error('umap called with three arguments has an unexpected second argument.');
      end
    else
      error('umap called with three arguments ...');
    end
    
  case 4
    if isdataset(varargin{2}) | (isnumeric(varargin{2}) & numel(varargin{2})>1)
      %treat second arg as y
      % (x, y, ..., ...)
      error('Supervised UMAP is currently not supported.');
      y = varargin{2};
    else
      error('umap called with four arguments requires the second argument to be non-empty data array');
    end
    %first check for options in 4, since n_comp can be in 3
    if isstruct(varargin{4}) & ~ismodel(varargin{4})
      % (x, y, ..., options)
      inopts = varargin{4};
    else
      error('umap called with 4 arguments requires fourth argument to be options structure.');
    end
    % get 3, can be model
    if ismodel(varargin{3})
      % (x, y, model, options)
      model = varargin{3};
      predictmode = 1;
    else
      error('umap called with four arguments has unexpected third argument.');
    end
  otherwise
    error('Inappropriate number of input arguments.')
    
    
end


%--------------------------

function [pyModel] = buildumap(varargin)
% Build UMAP model, either supervised or unsupervised
varargin = varargin{1};
[x,y,xt,yt,model,inopts,predictmode] = parsevarargin(varargin);

% Non dso input x,y have been converted to DSOs
indsx = x.includ;
% Build model using included data only
xd = x.data(indsx{:});

% build client object
client = evriPyClient(inopts);
% calibrate Python model object
client = client.calibrate(xd,x.data(:,indsx{2}),[]);
% extract information client
pyModel.model = client.serialized_model; %dump model to bytes
pyModel.embeddings = client.extractions.embeddings;
pyModel.supervised = client.extractions.supervised;
pyModel.graph = client.extractions.graph;
pyModel.linewidths = client.extractions.linewidths;
pyModel.xhat = client.extractions.xhat;
%--------------------------

function check_datasize(data)
  %Tip will be spawned if num samples>1000 or num(variables)>100
  
  if size(data,1)>1000 | size(data,2)>100
    evritip('umap_performance','UMAP being called with a significantly large X-block. Please note this can take some time to finish.',0);
  end

%--------------------------

function out = optiondefs()

defs = {
  %name                    tab              datatype        valid                            userlevel       description
  'display'                'Display'        'select'        {'on' 'off'}                     'novice'        'Governs level of display.';
  'plots'                  'Display'        'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
  'warnings'               'Display'        'select'        {'on' 'off'}                     'novice'        'Silence or display any potential Python warnings.';
  'blockdetails'           'Standard'       'select'        {'standard' 'all'}               'novice'        'Extent of predictions and raw residuals included in model. ''standard'' = keeps only y-block, ''all'' keeps both x- and y- blocks.';
  %'waitbar'                'Display'        'select'        {'on' 'off' 'auto'}              'novice'        'governs use of waitbar during analysis. ''auto'' shows waitbar if delay will likely be longer than a reasonable waiting period.';
  'n_neighbors'            'Display'        'double'        'int(1:inf)'                     'novice'        'Number of neighbors to consider. Controls the balance between local and global structure in the data.';
  'min_dist'               'Display'        'double'        'float(0.0:inf)'                 'novice'        'Minimum distance from data points that are allowed to be in the low dimensional representation.';
  'spread'                 'Display'        'double'        'float(0:inf)'                   'novice'        'The effective scale of embedded points. In combination with min_dist this determines how clustered/clumped the embedded points are.';
  'n_components'           'Display'        'double'        'int(1:inf)'                     'novice'        'The dimensionality of the reduced space.';
  'metric'                 'Display'        'select'        {'euclidean' 'manhattan' 'cosine' 'mahalanobis'}                    'novice'        'The metric used to calculate distance between data points.';
  'random_state'           'Display'        'double'        'int(1:inf)'                     'novice'        'Random seed number. Set this to a number for reproducibility.';
  'compression'            'Compression'    'select'        {'none' 'pca'}                   'novice'        'Type of data compression to perform on the x-block prior to UMAP model. Compression can make the UMAP more stable and less prone to overfitting. ''PCA'' is a principal components model.';
  'compressncomp'          'Compression'    'double'        'int(1:inf)'                     'novice'        'Number of latent variables or principal components to include in the compression model.'
  'compressmd'             'Compression'    'select'        {'no' 'yes'}                     'novice'        'Use Mahalnobis Distance corrected scores from compression model.'
  
  
  
  };

out = makesubops(defs);

%-----------------------------------------------------------------


