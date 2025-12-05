function model = ann(varargin)
%ANN Predictions based on Artificial Neural Network regression models.
% Build an ANN model from input X and Y block data using the optimal number
% of learning iterations (based on cross-validation) for specified number
% of layers and layer nodes. Alternatively, if a model is passed in ANN
% makes a Y prediction for an input test X block.
% The ANN model contains quantities (weights etc) calculated from the
% calibration data. If a model structure is passed in then these do not
% have to be re-calculated.
% There are two implementations available, 'bpn' (default) and 'encog'.
% Both are forward-feed neural networks using backpropagation training. The
% 'encog' implementation is based on the Java Encog package while 'bpn' is
% Matlab based.
%
% INPUTS:
%        x  = X-block (predictor block) class "double" or "dataset",
%        y  = Y-block (predicted block) class "double" or "dataset",
%     nhid  = number of nodes in a single hidden layer ANN, or vector of two 
%             two numbers, indicating a two hidden layer ANN, representing 
%             the number of nodes in the two hidden layers.
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
%           nhid1 : [{2}] Number of nodes in first hidden layer.
%           nhid2 : [{2}] Number of nodes in second hidden layer.
%       algorithm : [ {'bpn'} | 'encog' ] Specify which implementation of
%                     ANN to use. Both choices are forward-feed networks. 
%                     'bpn' uses backpropagation training with a fixed 
%                     learning rate. 'encog' uses backpropagation with
%                     resilient propagation training.
%       learnrate : [0.125] ANN learning rate (bpn only)
% activationfunction : [{'tanh'} | 'sigmoid'] ANN activation fn. (encog only).
%      compression: [{'none'}| 'pca' | 'pls' ] type of data compression
%                    to perform on the x-block prior to calculaing or
%                    applying the ANN model. 'pca' uses a simple PCA
%                    model to compress the information. 'pls' uses a pls
%                    model. Compression can make the ANN more stable and
%                    less prone to overfitting.
%    compressncomp: [ 1 ] Number of latent variables (or principal
%                    components to include in the compression model.
%       compressmd: [ 'no' |{'yes'}] Use Mahalnobis Distance corrected
% Training termination-related:
%     learncycles : [20] (bpn): Number of learning iterations
%                        (encog): tolerated cycles over which rmse must improve.
%    terminalrmse : [0.05] (encog only) Termination RMSE value (of scaled y)
% terminalrmserate: [1e-9] (encog only) rmse must improve by this min value over tolerated cycles
%      maxseconds : [20]   (encog only) Maximum duration of ANN training in seconds
%    random_state : [1] Random seed number. Set this to a number for reproducibility.  
%
%  OUTPUT:
%     model = standard model structure containing the ANN model (See MODELSTRUCT)
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: [model] = ann(x,y,options);
%I/O: [model] = ann(x,y,nhid,options);
%I/O:  [pred] = ann(x,model,options);
%I/O: [valid] = ann(x,y,model,options);
%
%See also: SVM

% Copyright © Eigenvector Research, Inc. 1994
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%Start Input
if nargin==0  % LAUNCH GUI
  analysis('ann')
  return
end

if ischar(varargin{1}) %Help, Demo, Options
  options = [];
  options.name = 'options';
  options.display = 'on';
  options.plots   = 'none';
  options.blockdetails  = 'standard';  %level of details
  options.nhid1   = 2;
  options.nhid2   = 0;
  options.learnrate        = 0.125;
  options.activationfunction   = 'tanh';  % encog only  'tanh | 'sigmoid'
  options.cvi      = [];
  options.preprocessing = {[] []};  %See preprocess
  options.compression   = 'none';
  options.compressncomp = 1;
  options.compressmd    = 'yes';
  options.algorithm        = 'bpn';  % or, 'encog'
  options.learncycles      = 20;
  options.terminalrmse     = 0.05; % terminalError value (RMS of scaled y)
  options.terminalrmserate = 1.e-9;
  options.maxseconds       = 20;
  options.waitbar          = 'on';
  options.random_state = 1;
  options.definitions      = @optiondefs;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; model = evriio(mfilename,varargin{1},options); end
  return;
end

% parse input parameters
[x,y,xt,yt,model,inopts,predictmode] = parsevarargin(varargin);

inopts = reconopts(inopts,mfilename);

%set random seed
rng(inopts.random_state,'twister');
javaState = java.util.Random();
javaState.setSeed(inopts.random_state);

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
  
  % Train ANN on the included data
  [W, niter, rmsecviter, ypred0, ycvpp] =  train(xpp, ypp, inopts);
   
  model = annstruct;
  model.detail.ann.W     = W;
  model.detail.ann.niter = niter;
  model.detail.ann.rmsecviter = rmsecviter; 
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
  model.detail.rmsecv = nan(1, inopts.nhid1); %size(model.detail.ann.W.w1,2));
  if ~isempty(ycvpp)
    ycv = preprocess('undo',model.detail.preprocessing{2}, ycvpp);
    yincl = y.data(y.include{1},y.include{2});
    model.detail.rmsecv(1, inopts.nhid1) = rmse(yincl(:), ycv.data(:));;
  end
  
  %Set time and date.
  model.date = date;
  model.time = clock;
  %copy options into model only if no model passed in
  model.detail.options = inopts;
  
else
  % have model, do predict
  if ~strcmpi(model.modeltype,'ann') & ~strcmpi(model.modeltype,'annda')
    if strcmpi(model.modeltype,'annpred'); %%% need to modify
      model.modeltype = 'ANN';
    else
      error('Input MODEL is not a ANN model');
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
  [ypred] = apply(xpp.data(:, indsx{2:end}), model.detail.ann.W); % Make predictions for all samples, included or not.
  
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
% TRAINING ANN using Forward-Feed Neural Network and backpropagation training.
% using either "bpn" (matlab implementation) or "Encog" (Java implementation).
% number of learning iterations
% x and y are datasets

displayon = strcmp(opts.display, 'on');

% Non dso input x,y have been converted to DSOs
indsx = x.includ;
indsy = y.includ;

% Build model using included data only
xd = x.data(indsx{:});
yd = y.data(indsy{:});

if ~isempty(opts.cvi) & isnumeric(opts.cvi) & length(opts.cvi)==size(x,1);
 opts.cvi = opts.cvi(indsx{1});
end

% Preprocess x, y to range [0.1, 0.9] using only included data
[xd, yd, rnge] = scaleset(xd, yd);

if strcmp(opts.algorithm, 'bpn')
  [yps, niter, rmsecviter, ycv, W] = buildbpn(x,xd,yd,rnge,opts);

elseif strcmp(opts.algorithm, 'encog')
  [yps, niter, rmsecviter, ycv, W] = buildencog(x,xd,yd,rnge,opts); 
else
  error('Unknown algorithm type, %s', opts.algorithm);
end

yp = unscale(yps, rnge.ymin, rnge.ymax);

%--------------------------------------------------------------------------
function [niter, rmsec, rmsecv, rmsecviter, ycv, Wbest] = getoptimalw(xd,yd, rng, opts)
% Uses specified CV method to find CV subsets. GETOPTIMALW then calculates
% rmsecv for each value of learning iterations from 1 to ops.learncycles.
% Finally, GETOPTIMALW calcuates the ANN weights, Wbest,  from xd, yd and
% the optimal number of learning iterations.
% NOTE: these rmsec, rmsecv, rmsecviter are using scaled y values so should
% not be reported values.
% INPUTS:
%    xd: X-block (double array)
%    yd: Y-block (double array)
%   rng: range of X and Y data
%  opts: Options structure (see ann options)
% OUTPUTS:
%  niter: The optimal number of learning iterations to use
%  rmsec: RMSEC from xd, yd, from ANN built with niter learning cycles.
% rmsecv: RMSECV from xd, yd, from ANN built with niter learning cycles.
% rmsecviter: RMSECV value for each learning cycle.
%    ycv: cross-validation y, unscaled. This is still pre-processed y.
%  Wbest: Weights structure for ANN built with niter learning cycles.

if strcmp(opts.waitbar,'on')
  hh = waitbar(0,'Please wait while ANN is training... (Close to cancel)');
else
  hh = nan;   %not a handle - will ignore all waitbar actions later
end

nhiddenlayers = 1;
if opts.nhid2>0
  nhiddenlayers = 2;
end

numstp = opts.learncycles;
nrow = size(xd,1);
learnrate = opts.learnrate;

% CV
% cvi(i) = -2 the sample is always in the test set.
% cvi(i) = -1 the sample is always in the calibration set,
% cvi(i) = 0 the sample is always never used, and
% cvi(i) = 1,2,3... defines each test subset.
% % check CV
if isempty(opts.cvi)
  if isfield(opts,'cvsplits') & isfield(opts, 'cvmethod') & ~isempty(opts.cvsplits) & ~strcmp(opts.cvmethod, 'none')
    %backwards compatibility for when user calls with depreciated options
    opts.cvi = {opts.cvmethod opts.cvsplits 1};
    cvi = encodemethod(nrow, opts.cvmethod, opts.cvsplits);
    nsplit = opts.cvsplits;
  else
    % Use a single split of a 5-split rnd case
    nsplit = 1;
    cvi = encodemethod(nrow, 'rnd', 5);
    cvi(cvi~=1) = -1;  % Cal: -1 the sample is always in the calibration set
    cvi(cvi==1) = -2;  % Tst: -2 the sample is always in the test set
  end
else
  % opts.cvi not empty
  if isa(opts.cvi,'double')
    cvi = opts.cvi;
    nsplit = max(2, length(unique(cvi(cvi>0))));
  elseif strcmp(opts.cvi{1},'custom') & length(opts.cvi)>1 & ~isempty(opts.cvi{2})
    cvi = opts.cvi{2};
    nsplit = max(1, length(unique(cvi(cvi>0))));
    if nsplit==1
      % handle special case of cvi being single-valued, nsplit=1:
      % Use random split-half
      cvi = encodemethod(nrow, 'rnd', 2);
      cvi(cvi~=1) = -1;  % Cal: -1 the sample is always in the calibration set
      cvi(cvi==1) = -2;  % Tst: -2 the sample is always in the test set
    end
  else
    nlen = length(opts.cvi);
    cvmethod = 'rnd';
    nsplit = 5;
    if nlen > 0
      cvmethod = opts.cvi{1};
    end
    if nlen > 1
      nsplit = opts.cvi{2};
    end
    cvi = encodemethod(nrow, cvmethod, nsplit);
  end
end

% splits loop
rmseps = nan(numstp, nsplit);
ycvs   = nan(numstp,size(yd,1), size(yd,2));
im1    = cvi==-1; % always cal
im2    = cvi==-2; % always test
cvilevs = unique(cvi(cvi>0));
if isempty(cvilevs)
  cvilevs = [0]; % ensure not empty
end
startat = now;
try
  for ii=1:nsplit
    cvii = cvilevs(ii);
    updatewaitbar(hh, ii, nsplit, startat, opts);
    isubtst = (cvi==cvii & cvi>0) | im2;
    isubcal = (cvi~=cvii & cvi>0) | im1;
    % make a flag, 1=cal, 0=test

    xc = xd(isubcal,:);
    xt = xd(isubtst,:);
    yc = yd(isubcal,:);
    yt = yd(isubtst,:);
    
    [npat, nin] = size(xc);
    [npat, nout] = size(yc);
    [npat2, nout] = size(yt);
    
    % Initialize weights to small random values
    if opts.nhid2==0
      W = initr(nin, opts.nhid1, nout);
    else
      W = initr(nin, opts.nhid1, opts.nhid2, nout);
    end
    
    W.type = 'bpn';
    W.xmin = rng.xmin;
    W.xmax = rng.xmax;
    W.ymin = rng.ymin;
    W.ymax = rng.ymax;
    W.nhiddenlayers = nhiddenlayers;
    
    % find rmsep for each value 1:numstp of learning iterations
    [W1,rmsec, rmsep, ytps] = trnstf(xc,yc,xt,yt,numstp,learnrate,W);   % trnstf returns rmsep(1:numstp)
    % Note, returns last W, NOT the best W over numstp
    rmseps(:,ii) = rmsep;

    % support multi-col y
    ycvs(:, isubtst,:) = ytps; % ytps is (numstp, size(yt,1), size(yt,2))
  end

  if nsplit==1
    xsize = size(ytps);
    ytps1 = reshape(ytps,xsize(1),prod(xsize(2:end)));
    rmsecviter = rmse(ytps1', yt(:)); % double-check
  else
    % also unroll ycvs
    xsize = size(ycvs);
    ycvs1 = reshape(ycvs,xsize(1),prod(xsize(2:end)));
    rmsecviter = rmse(ycvs1', yd(:));
  end
catch
  %any errors? delete any waitbar and rethrow error
  le = lasterror;
  if ishandle(hh)
    delete(hh);
  end
  rethrow(le);
end

if ishandle(hh)
  delete(hh);
end

% pick the iteration which has smallest rmsecv
[rmsecvmin, niter] = min(rmsecviter);
% recover cross-validation y unscaled. This is still pre-processed y.
% ycv = unscale(ycvs(niter,:,:)', rng.ymin, rng.ymax); 
if ndims(ycvs)>2
  ycvsniter = squeeze(ycvs(niter,:,:))';
else
  ycvsniter = ycvs(niter,:);
end
ycv = unscale(ycvsniter', rng.ymin, rng.ymax);

if strcmp(opts.plots, 'final')
  figure; plot(rmsecviter, 'b-'); 
  hold on; plot(rmsec, 'r-');
  title(sprintf('rmsecv (blue), rmsec (red). Min = %4.4g at %d iterations', rmsecvmin, niter));
  xlabel ('Training Iteration')
  ylabel ('RMS Error')
end

% now that we have the optimal niter we build W    
% Initialize weights to small random values
    if opts.nhid2==0
      W = initr(nin, opts.nhid1, nout);
    else
      W = initr(nin, opts.nhid1, opts.nhid2, nout);
    end
    
    W.type = 'bpn';
    W.xmin = rng.xmin;
    W.xmax = rng.xmax;
    W.ymin = rng.ymin;
    W.ymax = rng.ymax;
    W.nhiddenlayers = nhiddenlayers;
[Wbest,rmsec, rmsep] = trnstf(xd,yd,[],[],niter,learnrate,W);

% set rmsecv to this min value
rmsecv = rmsecvmin;

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
function [x,y, haveyblock] = converttodso(x,y, model, options)
%C) CHECK Data Inputs
if isa(x,'double')      %convert x and y to DataSets
  x        = dataset(x);
  x.name   = inputname(1);
  x.author = 'ANN';
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
    y.author = 'ANN';
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
function outstruct = annstruct
outstruct = modelstruct('ann');

%--------------------------------------------------------------------------
function [W] = initr(varargin) 
%
% INPUT:
%        nin, nhid1, nhid2, nout
%
% OUTPUT:
%        W = struct with weights for 2 or 3 layers
%
% Random weight initialization
%
%		[w1, w2, w3] = initr(nin, nhid1, nhid2, nout)
%

if nargin>=3
  nin  = varargin{1};
  nhid1 = varargin{2};
  nhid2 = varargin{3};
  W.w1 = (0.5-rand(nin+1,nhid1))/(nin+1);
  W.w2 = (0.5-rand(nhid1+1,nhid2))/(nhid1+1);
end
if nargin==4
  nout = varargin{4};
  W.w3 = (0.5-rand(nhid2+1,nout))/(nhid2+1);
end

%--------------------------------------------------------------------------
function [dw] = deltaw1(t,w,NIN,NOUT,NHID1,XDATA,YDATA)
nw1 = (NIN+1)*NHID1;
nw2 = (NHID1+1)*NOUT;
nw = nw1 + nw2;
w1 = reshape(w(1:nw1),NIN+1,NHID1);
w2 = reshape(w(nw1+1:nw),NHID1+1,NOUT);

% [dw1 dw2] = delta(XDATA,YDATA,w1,w2);%
% Compute "Delta Rule" for Back Propagation Network
%	with 2 Layers of Weights (One Hidden Layer)
%
% Input matrices 
%
%	x(npat, nin)     -- X values
%	y(npat, nout)    -- Y values
%	w1(nin+1, nhid)  -- Present first-layer weights
%	w2(nhid+1, nout) -- Present second-layer weights
%
% Outputs matrices
%
%	dw1(nin+1, nhid)  -- Change in first-layer weights
%	dw2(nhid+1, nout) -- Change in second-layer weights
%
% N.B. -- Does NO scaling of x and y -- they must be in the 
%		range 0 <= x,y <= 1
%
% 	[dw1, dw2, h, yp] = delta(x,y,w1,w2)
%
x = XDATA;
y = YDATA;
%
dw1 = zeros(size(w1)); 
dw2 = zeros(size(w2)); 
%
% Add a column of 1's to patterns to make bias nodes
%
xp = [x ones(size(x,1),1)];
%
h = 1./(1+exp(-xp*w1));
%
% Add bias nodes
%
h1 = [h ones(size(h,1),1)];
yp = 1./(1+exp(-h1*w2));
%
dw2 = h1'*((y-yp).*yp.*(1-yp));
%
del = ((y-yp).*yp.*(1-yp))*w2';
%
% Drop delta for bias nodes
%
del(:,size(del,2)) = [];
dw1 = xp'*(del.*h.*(1-h)); 

dw = [dw1(:)' dw2(:)']';

%--------------------------------------------------------------------------
function [dw] = deltaw2(t,w,NIN,NOUT,NHID1,NHID2,XDATA,YDATA)
nw1 = (NIN+1)*NHID1;
nw2 = (NHID1+1)*NHID2;
nw3 = (NHID2+1)*NOUT;
nw = nw1 + nw2 + nw3;
w1 = reshape(w(1:nw1),NIN+1,NHID1);
w2 = reshape(w(nw1+1:nw1+nw2),NHID1+1,NHID2);
w3 = reshape(w(nw1+nw2+1:nw),NHID2+1,NOUT);
%
% Compute "Delta Rule" for Back Propagation Network
%	with 3 Layers of Weights (Two Hidden Layer)
%
% Input matrices 
%
%	x(npat, nin)       -- X values
%	y(npat, nout)      -- Y values
%	w1(nin+1, nhid1)   -- Present first-layer weights
%	w2(nhid1+1, nhid2) -- Present second-layer weights
%   w3(nhid2+1, nout)  -- Present third-layer weights
%
% Outputs matrices
%
%	dw1(nin+1, nhid1)  -- Change in first-layer weights
%	dw2(nhid1+1, nhid2) -- Change in second-layer weights
%	dw3(nhid2+1, nout) -- Change in third-layer weights
%
% N.B. -- Does NO scaling of x and y -- they must be in the 
%		range 0 <= x,y <= 1
%
x = XDATA;
y = YDATA;
%
dw1 = zeros(size(w1)); 
dw2 = zeros(size(w2)); 
dw3 = zeros(size(w3));
%
% Add a column of 1's to patterns to make bias nodes
%
xp = [x ones(size(x,1),1)];
h = 1./(1+exp(-xp*w1));
h1 = [h ones(size(h,1),1)];
g = 1./(1+exp(-h1*w2));
g1 = [g ones(size(g,1),1)];
yp = 1./(1+exp(-g1*w3));
%
dw3 = g1'*((y-yp).*yp.*(1-yp));
%
del2 = ((y-yp).*yp.*(1-yp))*w3';
del2(:,size(del2,2)) = [];
dw2 = h1'*(del2.*g.*(1-g));
%
del1 = del2.*g.*(1-g)*w2';
del1(:,size(del1,2)) = [];
dw1 = xp'*(del1.*h.*(1-h));
%
% Weight decay
%
alfa = 0; % was .01 in pre ver. 8.
dw1 = dw1 - alfa*w1;
%
% Fix one weight
%
dw1(1) = 0;
%
dw = [dw1(:)' dw2(:)' dw3(:)']';

%--------------------------------------------------------------------------
function [xs, ys, W] = scaleset(x, y)
%
% Set up SCALING x and y, determining their mins and maxs 
% Scale x -> xs and y -> ys into scaled variables from 0.1 to 0.9
% Put scaling limits into the structure W
%
%		[xs, ys, W] = scaleset(x, y)
%
xmin = min(x);
xmax = max(x);
ymin = min(y);
ymax = max(y);
[xs] = scaleit(x, xmin, xmax);
[ys] = scaleit(y, ymin, ymax);
W.xmin = xmin;
W.xmax = xmax;
W.ymin = ymin;
W.ymax = ymax;

%--------------------------------------------------------------------------
function [xs] = scaleit(x, xmin, xmax)
%
% Scales values of x into xs in the range 0.1 to 0.9
%
%   function [xs] = scaleit(x, xmin, xmax)
%
m = size(x,2);
%
sc = 0.8./(xmax-xmin+eps*10);
%
for i = 1:m
  xs(:,i) = 0.1 + sc(i)*(x(:,i)-xmin(i));
end

%--------------------------------------------------------------------------
function [W1, rmsec, rmsep, ytps] = trnstf(x,y,xt,yt,nstep,learnrate,W);
%
% "STIFF BACKPROPAGATION" to Train the
%  Back Propagation Network program
%  with two or three hidden layers
%
% NO internal scaling: X and Y must be in the range 0 < x,y < 1
%
% Uses the training algorithm:
%	dW/dt = -Del_W
% and a stiff ODE solver
%
% If xt,yt are not empty then trnstf trains weights nstep times and returns
% the RMSEP for each case in rmsep. Returned W is the last trained case (nstep
% training iterations).
% If xt,yt are empty trnstf trains weights using nstep training iterations
% and returnes trained W.
% 
% Inputs
%
%	x(npat, nin)       = Input X matrix, npat patterns, nin inputs each
%	y(npat, nout)      = Target Y matrix, npat patterns, nout outputs each
%	xt(npat2, nin)     = Input TEST X matrix
%	yt(npat2, nout)    = Target TEST Y matrix
%	nstep              = Number of training steps to take
%   learnrate          = Governs size of weights changes during learning
%   W                  = Input model structure
%
%	w1(nin+1, nhid1)    = Weights in first layer (INITIAL VALUES)
%	w2(nhid1+1, nhid2)  = Weights in the second layer (INITIAL VALUES)
% w3(nhid2+1, nout)   = Weights in the third layer (INITIAL VALUES)
%
% Outputs
%
% W1                 = Output trained model structure
%	w1(nin+1, nhid1)   = Weights in first layer		    (OUTPUT VALUES)
%	w2(nhid1+1, nhid2) = Weights in the second layer	(OUTPUT VALUES)
%	w3(nhid2+1, nout)  = Weights in the third layer	(OUTPUT VALUES)
%	yp(npat, nout)     = Predicted output Y matrix
%	rms(nstep)         = Training mean sum-of-squares of errors versus
%				           training step number (RMS)
%   rmsec              = rmse of self-prediction
%   rmsep              = rmse of prediction
%   ytps               = nstep x size(yt,1) x size(yt,2) predicted yt, for each iteration
%
% function [W1] = trnstf(x,y,xt,yt,nstep,W);
%
[n, nin] = size(x);
[ny, nout] = size(y);
nhid1 = size(W.w1,2);
nhid2 = size(W.w2,2);

if ~isempty(xt) & ~isempty(yt)
  % Validate predicted y to find the optimal number of training iterations
  optimizetrainingiterations = true;
else
  % Just train the weights using x and y
  optimizetrainingiterations = false;
end


NIN = nin;
NOUT = nout;
NHID1 = nhid1;
NHID2 = nhid2;
if n ~= ny error (' The Lengths of X and Y must be the same')
end
%
threelayer = isfield(W, 'w3');
if threelayer
  w = [W.w1(:)' W.w2(:)' W.w3(:)']';
else
  w = [W.w1(:)' W.w2(:)']';
end

nw1 = (nin+1)*nhid1;
nw2 = (nhid1+1)*nhid2;
nw3 = (nhid2+1)*nout;
nw = nw1 + nw2;
if threelayer
  nw = nw + nw3;
end
rms = zeros(nstep,1);
%
% Stiff ODE solution
%
XDATA = x;
YDATA = y;
%
t0 = 0;
t1 = learnrate; %0.125; 
%
options = [];
options = odeset('NormControl','on');
%options = odeset('Vectorized','on');
%
smin = 1.0e20;
tt = 1:nstep;
tt = tt';
rmsec = nan(nstep,1);
rmsep = nan(nstep,1);
ibest = zeros(nstep,1);
ytps  = nan(nstep, size(yt,1), nout);

% A function handle stores variable values used in its definition. Thus the
% uppercase variables' values at this FH creation time are saved in 
% deltawfn even if the those variable values are changed before deltawfn is
% called.
if threelayer
  deltawfn = @(t,w) deltaw2(t,w,NIN,NOUT,NHID1,NHID2,XDATA,YDATA);
else
  deltawfn = @(t,w) deltaw1(t,w,NIN,NOUT,NHID1,XDATA,YDATA);
end

for ns=1:nstep
  [t,wall] = ode15s(deltawfn,[t0 t1],w,options);
  
  [n1, n2] = size(wall);
  w = wall(n1,:)';
  w1 = reshape(w(1:nw1),nin+1,nhid1);
  w2 = reshape(w(nw1+1:nw1+nw2),nhid1+1,nhid2);
  if threelayer
    w3 = reshape(w(nw1+nw2+1:nw),nhid2+1,nout);
  end
  %
  W1 = W;
  W1.w1 = w1;
  W1.w2 = w2;
  if threelayer
    W1.w3 = w3;
  end
  
  %
  % Predict scaled y and yt
  %
  [yp, hid] = preds(x,W1);

  if optimizetrainingiterations
    ytp = preds(xt,W1);
    %
    stats = rms2(y,yp,yt,ytp);
    ssqt = 0;
    ssq = 0;
    for kk=1:nout
      ssq = ssq + stats(kk,2)^2;
      ssqt = ssqt + stats(kk,4)^2;
      if threelayer
        [nhid2 ns stats(kk,:) ibest(ns)];
      else
        [nhid1 ns stats(kk,:) ibest(ns)];
      end
    end
    ytps(ns,:,:) = ytp;
    rmsec(ns) = (ssq/nout)^0.5;
    rmsep(ns) = (ssqt/nout)^0.5;
%     evrirmse = rmse(yt,ytp);
    [ns rmsec(ns) rmsep(ns)];

    if ssqt<smin
      smin = ssqt;
      ibest(ns) = 1;
    end
  else
      ytp = [];
  end
  %
  t0 = t1;
  t1 = 2*t1;
end
%
if optimizetrainingiterations
  if threelayer
    nunits = nhid2;
  else
    nunits = nhid1;
  end
%   figure(nunits)
%   plot (tt,rmsec,tt,rmsep,':')
%   axis ([0 1.1*max(tt) 0 1.1*max([max(rmsec) max(rmsep)])])
%   xlabel ('Training Iteration')
%   ylabel ('RMS Error')
%   title (strcat('Train/Test Curves with --',num2str(nunits), ...
%     '-- Mapping Units'))
%   grid
%   legend ('Train', 'Test')
%   disp('training_step rmsec rmsep best_model_step')
%   [tt rmsec rmsep ibest]
else
  %
  % Predict scaled y
  %
  [yp, hid] = preds(x,W1);
  rmsec = rmse(y,yp);
end

%--------------------------------------------------------------------------
function [ys, hid] = preds(xs, W);
%
% Forward Prediction With Feedforward Neural Network
% Two layers of weights (one layer of hidden units)
% Weights in BPN format, in the model file W
%
% For a network with THREE Hidden Layers, 3 matrices of weights.
%
%	Input XS and output YS in SCALED UNITS
%
%		 ys = pred(xs, W);
%
% Forward propagation through network
%
% Integration function: Linear weighted sum f(x) = x*w
% Activation function:  g(x) = 1/(1 + exp(-x))

threelayer = isfield(W, 'w3');

w1 = W.w1;
w2 = W.w2;
if threelayer
  w3 = W.w3;
end

xp = [xs ones(size(xs,1),1)];
h = 1./(1+exp(-xp*w1));
hid = h;
h1 = [h ones(size(h,1),1)];
g = 1./(1+exp(-h1*w2));
if threelayer
  g1 = [g ones(size(g,1),1)];
  ys = 1./(1+exp(-g1*w3));
else
  ys = g;
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

%--------------------------------------------------------------------------
function [yp] = unscale(yps, ymin, ymax)
%
% Re-Scale values of yps in the range 0.1 to 0.9
% Back to physical units, yp, from ymin to ymax
%
%		[ys] = unscale(yps, ymin, ymax)
%
[n, m] = size(yps);
%
sc = 1.25*(ymax-ymin);
%
for i = 1:m
yp(:,i) = ymin(i) + sc(i)*(yps(:,i)-0.1);
end

%--------------------------------------------------------------------------
function [yp, hid] = pred(xin, W);
%
% Forward Prediction With BPN Feedforward Neural Network
%
%	Input x and output y in REAL NON-SCALED UNITS
%
%		 yp = pred(x, W);
%
xs = scaleit(xin,W.xmin,W.xmax);
[ys, hid] = preds(xs, W);
yp = unscale(ys, W.ymin, W.ymax);

%--------------------------------------------------------------------------
function [yp] = predencog(xin, W);
% Encog Neural Net Prediction With Feedforward Neural Network 
%
%	Input x and output y in REAL NON-SCALED UNITS
%
%		 yp = predencog(x, W);
%
xs = scaleit(xin,W.xmin,W.xmax);

engine = evri.ann.EncogEngine;
nhiddenlayers = W.nhiddenlayers;
ninput = size(W.xmin,2);
noutput = length(W.ymin);
engine.setnHid1(W.nhl1);
engine.setnHid2(W.nhl2);
weights = W.encogweights;

% Create network Java object and load weights
tanh = W.tanhactivation;
network = org.encog.util.simple.EncogUtility.simpleFeedForward(ninput, W.nhl1, W.nhl2, noutput, tanh);
org.encog.neural.networks.structure.NetworkCODEC.arrayToNetwork(weights, network);

% Make prediction and un-scale y
ys = engine.predictAnn(noutput, xs, network);
yp = unscale(ys, W.ymin, W.ymax);

%--------------------------------------------------------------------------
function [yp, hid] = apply(xin, W);
%
% Make prediction using appropriate ANN implementation
%
%	Input x and output y in REAL NON-SCALED UNITS
%
%		 yp = pred(x, W);
%

hid = [];
if strcmp(W.type, 'bpn')
  [yp, hid] = pred(xin, W);
elseif strcmp(W.type, 'encog')
  yp = predencog(xin, W);
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
          if strcmp(lower(options.functionname), 'ann')
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
  function options = setlayernodes(options, hid)
  % Update options with number of nodes in each layer, and hence number of
  % layers (anntype)
    if length(hid)==1
      options.nhid1 = hid(1);
      options.nhid2 = 0;
    elseif length(hid)==2
      options.nhid1 = hid(1);
      options.nhid2 = hid(2);
    else
      %hid must be length 1 or 2.
      error('ann: setlayernodes: Unexpected hid with length = %d. Length must be less than 3', length(hid))
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
  result = strcmpi(args.functionname, 'annda');
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
%I/O: [model] = ann(x,y,options);
%I/O: [model] = ann(x,y,nhid);
%I/O: [ypred] = ann(x,y,model);
%I/O: [ypred] = ann(x,model,options);
%I/O: [ypred] = ann(x,y,model,options);
%I/O: [model] = ann(x,y,nhid,options);
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
    %    ann(x, model)
    %    ann(x,y)
    if isdataset(varargin{1}) | isnumeric(varargin{1})
      if ismodel(varargin{2})
        % (x,model)
        x = varargin{1};
        model  = varargin{2};
        y = [];
        if ~isempty(model.detail.options)
          inopts = model.detail.options;
        else
          inopts = ann('options');
        end
        predictmode = 1;
      elseif isdataset(varargin{2}) | isnumeric(varargin{2})
        % (x,y)
        x = varargin{1};
        y = varargin{2};
        inopts = ann('options');
        model  = [];
        predictmode = 0;
      else
        error('ann called with two arguments requires non-empty y or model as second argument.');
      end
    else
      error('ann called with two arguments requires non-empty x data array.');
    end
    
  case 3 % 3 arg:
    %    [model] = ann(x,y,options);
    %    [ypred] = ann(x,model,options);
    %    [ypred] = ann(x,y,model);
    %    [model] = ann(x,y,nhid);
    if ismodel(varargin{3})
      % (x,y,model)
      x = varargin{1};
      y = varargin{2};
      model  = varargin{3};
      if ~isempty(model.detail.options)
        inopts = model.detail.options;
      else
        inopts = ann('options');
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
        error('ann called with 3 arguments has unexpected second argument.');
      end
    elseif isnumeric(varargin{3})
    %   [model] = ann(x,y,nhid); 
        x = varargin{1};
        y = varargin{2};
        model  = []; 
        inopts = ann('options');
        predictmode = 0;
        hid = varargin{3};
        inopts = setlayernodes(inopts, hid);
    else
      error('ann called with 3 arguments has unexpected third argument.');
    end    
    
  case 4 % 4 arg: 
    %    [ypred] = ann(x, y, model, options);
    %    [model] = ann(x,y,nhid,options);
    if ismodel(varargin{3}) & isstruct(varargin{4})
      % (x,y,model, options)
      x = varargin{1};
      y = varargin{2};
      model  = varargin{3};
      inopts  = varargin{4};
      predictmode = 1;
    elseif isnumeric(varargin{3}) & isstruct(varargin{4})
    %    [model] = ann(x,y,nhid,options);    
      x = varargin{1};
      y = varargin{2};
      nhid  = varargin{3};
      inopts = varargin{4};
      inopts = setlayernodes(inopts, nhid);
      predictmode = 0;
    else
      error('ann called with 4 arguments has unexpected arguments.');
    end
    
  case 5 % 5 arg:
    %    [ypred] = ann(x, y, model, nhid, options);
    if ismodel(varargin{3}) & isnumeric(varargin{4}) & isstruct(varargin{5})
      %    [ypred] = ann(x, y, model, nhid, options);
      x = varargin{1};
      y = varargin{2};
      model = varargin{3};
      nhid = varargin{4};
      inopts = varargin{5};
      inopts = setlayernodes(inopts, nhid);
      predictmode = 1;
    else
      error('ann called with 5 arguments has unexpected arguments.');
    end
    
  otherwise
    error('ann: unexpected number of arguments to function ("%s")', nargin);
end

%--------------------------------------------------------------------------
  function[yps, niter, rmsecviter, ycv, W] = buildbpn(x,xd,yd,rnge,opts);
  % BPN
  % Get optimal W
  [niter, rmsec, rmsecv, rmsecviter, ycv, W]  = getoptimalw(xd,yd,rnge,opts);
  % Get predicted y for this W, for all samples, included or not
  indsx = x.include;
  [yps, hid] = preds(scaleit(x.data(:, indsx{2}), W.xmin, W.xmax), W);
  W.type = 'bpn';
  W.nhl1 = opts.nhid1;
  W.nhl2 = opts.nhid2;
  
%--------------------------------------------------------------------------
  function [yps, niter, rmsecviter, ycv, W] = buildencog(x, xd,yd,rnge,opts)
  displayon = strcmp(opts.display, 'on');
  % ENCOG
  W.type = 'encog';
  W.xmin = rnge.xmin;
  W.xmax = rnge.xmax;
  W.ymin = rnge.ymin;
  W.ymax = rnge.ymax;
  if strcmp(opts.activationfunction, 'sigmoid')
    W.tanhactivation = false;
  else
    W.tanhactivation = true;
  end

  nhidden1       = opts.nhid1;
  nhidden2       = opts.nhid2;
  terminalerror  = opts.terminalrmse;     % terminal error value (RMS)
  minimprovement = opts.terminalrmserate; % rmse must improve by this min value over tolerated cycles
  toleratedcycles = opts.learncycles;     % rmse must improve over this (tolerated) number of cycles
  maxseconds     = opts.maxseconds;       % time limit
  showdisplay    = strcmpi(opts.display, 'on');
  
  engine = evri.ann.EncogEngine;
  engine.setnHid1(nhidden1);
  engine.setnHid2(nhidden2);
  engine.setTerminalError(terminalerror);
  engine.setMinImprovement(minimprovement);
  engine.setMaxSeconds(maxseconds);
  engine.setToleratedCycles(toleratedcycles);
  engine.setDisplay(showdisplay);
  engine.setTanh(W.tanhactivation);

  if displayon
    msg = 'Calibrate using minImprovement = %4.4g, over toleratedCycles = %4.4g';
    disp(sprintf(msg, engine.getMinImprovement, engine.getToleratedCycles));
    disp(sprintf('Use TerminalError = %4.4g', terminalerror));
    disp(sprintf('Use maxSeconds = %4.4g', maxseconds));
  end
  
  % Calibrate model
  network = engine.calibrateAnn(xd, yd); % train on xcal, ycal (preprocessed)
  
  yinputSize = size(yd,2);
  % Make prediction for all samples, included or not
%   yps = engine.predictAnn(yinputSize, scaleit(x.data(:, indsx{2}), rnge.xmin, rnge.xmax), network);
%   yps = engine.predictAnn(yinputSize, scaleit(xd, rnge.xmin, rnge.xmax), network);
  indsx = x.include;
  yps = engine.predictAnn(yinputSize, scaleit(x.data(:, indsx{2}), rnge.xmin, rnge.xmax), network);
  niter = -1;
  rmsecviter = [];
  % add weights etc to W, whatever encog needs.
  nlayers = network.getLayerCount;
  nhl1 = network.getLayerNeuronCount(1);  % Java 0-based index
  nhl2 = 0;
  if nlayers>3
    nhl2 = network.getLayerNeuronCount(2);
  end
  W.nhiddenlayers = nlayers-2;
  W.nhl1 = nhl1;
  W.nhl2 = nhl2;
  encogweights = org.encog.neural.networks.structure.NetworkCODEC.networkToArray(network);
  W.encogweights = encogweights;
  ycv = [];    


  

%--------------------------

function out = optiondefs()

defs = {
%name                    tab              datatype        valid                            userlevel       description
'display'                'Display'        'select'        {'on' 'off'}                     'novice'        'Governs level of display.';
'plots'                  'Display'        'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
'blockdetails'           'Standard'       'select'        {'standard' 'all'}               'novice'        'Extent of predictions and raw residuals included in model. ''standard'' = keeps only y-block, ''all'' keeps both x- and y- blocks.';
'waitbar'                'Display'        'select'        {'on' 'off' 'auto'}              'novice'        'governs use of waitbar during analysis. ''auto'' shows waitbar if delay will likely be longer than a reasonable waiting period.';
'algorithm'              'Standard'       'select'        {'encog' 'bpn'}                  'novice'        [{'Algorithm to use. BPN ("back-propogation network") is the default. "encog" is an alternative back-propogation engine based on the Encog java package.'} getanncp];
'nhid1'                  'Standard'       'double'        'int(1:inf)'                     'novice'        'Number of nodes in first hidden layer.';
'nhid2'                  'Standard'       'double'        'int(0:inf)'                     'novice'        'Number of nodes in second hidden layer.';
'random_state'           'Standard'       'double'        'int(0:inf)'                     'novice'        'Random seed number. Set this to a number for reproducibility.';
'learnrate'              'BPN'            'double'        'float(0:1)'                     'novice'        'ANN learning rate.';
'learncycles'            'BPN'            'double'        'int(1:inf)'                     'novice'        'Iterations of the training cycle.';
'maxseconds'             'Encog'          'double'        'int(1:inf)'                     'novice'        'Maximum ANN training time.';
'terminalrmse'           'Encog'          'double'        'float(0:1)'                     'novice'        'ANN training ends when RMSE decreases to this value.';
'terminalrmserate'       'Encog'          'double'        'float(0:1)'                     'novice'        'ANN training ends when RMSE decreases by this value over 100 iterations.';
'activationfunction'     'Standard'       'select'        {'tanh' 'sigmoid'}               'novice'        'Activation function type.';
'compression'            'Compression'    'select'        {'none' 'pca' 'pls'}             'novice'        'Type of data compression to perform on the x-block prior to SVM model. Compression can make the SVM more stable and less prone to overfitting. ''PCA'' is a principal components model and ''PLS'' is a partial least squares model (which may give improved sensitivity).';
'compressncomp'          'Compression'    'double'        'int(1:inf)'                     'novice'        'Number of latent variables or principal components to include in the compression model.'
'compressmd'             'Compression'    'select'        {'no' 'yes'}                     'novice'        'Use Mahalnobis Distance corrected scores from compression model.'
};

out = makesubops(defs);

%-----------------------------------------------------------------
function out = getanncp()

out  = {'The ANN method in PLS_Toolbox uses the Encog framework, provided '...
'by Heaton Research, Inc, under the terms of the Apache 2.0 license.'};

