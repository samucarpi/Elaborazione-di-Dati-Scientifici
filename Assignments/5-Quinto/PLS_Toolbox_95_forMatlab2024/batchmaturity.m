function [out, options] = batchmaturity(varargin)
%BATCHMATURITY Batch process model and monitoring, identifying outliers.
%  Analyzes multivariate batch process data to quantify the acceptable 
%  variability of the process variables during normal processing conditions.
%  The resulting model can be used on new batch process data to identify
%  measurements which indicate abnormal processing behavior. See the
%  pred.inlimits field for this indication.
%
%  Methodology: 
%  Given multivariate X data and a Y variable which represents the
%  corresponding state of batch maturity (BM) build a model by:
%  1. Build a PLS model on X and Y using specified preprocessing. Use its 
%     self-prediction of Y, ypred, as the indicator of BM. 
%  2. Simplify the X data by performing PCA analysis (with specified 
%     preprocessing). We now have PC scores and a measure of BM (ypred) for 
%     each sample.
%  3. Sort the samples to be in order of increasing BM. Calculate running
%     means "smoothed score" of these ordered scores for each PC.
%     Calculate deviations of scores from the smoothed means for each PC.
%  4. Form a set of equi-spaced BM values over the range (BMstart, BMend).
%     For each BM point find the n samples which have BM closest to that value.
%  5. For each BM point calculate low and high score limit values based on
%     one of the algorithms (see option clalgorithm, below):
%       'percentile' : limits correspond to the cl/2 and 1-cl/2 percentiles
%           of the n sample score deviations just selected. 
%       'astd' : limits correspond to the standard deviation to cl
%           confidence limits of a normal distribution for the n sample
%           score deviations. 
%     This is done for each PC. Add the smoothed scores to these limits to
%     get the actual limits for each PC at each BM point. These BM points
%     and corresponding low/high score limits constitute a lookup table for
%     score limits (for each PC) in terms of BM value.
%  6. The score limits lookup table contains upper and lower score limits
%     for each PC, for every equi-spaced BM point over the BM range. 
%  7. The batch maturity model contains the PLS and PCA sub-models and the 
%     score limits lookup table. It is applied to a new batch processing 
%     dataset, X1, by applying the PLS sub-model to get BM (ypred), then
%     applying the PCA sub-model to get scores. The upper and lower score 
%     limits (for each PC) for each sample are obtained by using the 
%     sample's BM value and querying the score limits lookup table. A
%     sample is considered to be an inlier if its score values are within 
%     the score limits for each PC.
%     
%
%  INPUTS:
%               x = X-block (2-way array class "double" or "dataset").
%               y = Y-block (vector class "double" or "dataset").
%       ncomp_pca = Number of components to to be calculated  in PCA model
%                   (positive integer scalar).
%       ncomp_reg = Number of latent variables for regression method.
%
%  OPTIONS:
%   regression_method : [ {'pls'} ] A string indicating type of regression
%                       method to use. Currently, only 'pls' is supported.
%       preprocessing : { [] } preprocessing structure goes to both PCA and
%                       PLS. PLS Y-block preprocessing will always be
%                       autoscale.
%         zerooffsety : [ 0 | {1}] transform y resetting to zero per batch
%            stretchy : [ 0 | {1}] transform y to have range=100 per batch
%                  cl : [ 0.95 ] Confidence limit (2-sided) for moving
%                        limits (defined as 1 - Expected fraction of
%                        outliers.)
%         clalgorithm : [ {'astd'} | 'percentile' ] governs confidence
%                       limit algorithm:
%                         'astd' = asymmetric standard deviation.
%                            Calculates standard deviation in positive and
%                            negative direction for each batch maturity
%                            point. Option cl defines the quantile to which
%                            the limit should be calculated. E.g. cl=.9987
%                            is equivalent to 3 standard deviations.
%                         'percentile' = asymmetric percentile limits. Uses
%                            percentile to calculate the requested
%                            confidence limit. Note: percentile, by nature,
%                            cannot exceed the observed data limits.
%          nearestpts : [{25}] number nearby scores used in getting limits
%           smoothing : [{0.05}] smoothing of limit lines. Width of window  
%                       used in Savgol smoothing as a fraction of BM range.
%         bmlookuppts : [{1001}] number of equi-spaced points in BM lookup
%                       table. 
%               plots : [ 'none' | 'detailed' | {'final'} ] governs production of plots
%                       when model is built. 'final' shows standard scores
%                       and loadings plots. 'detailed' gives individual
%                       scores plots with limits for all PCs.
%             waitbar : [ 'off' | {'auto'} ] governs display of waitbar when
%                       calculating confidence limits ('auto' shows waitbar
%                       only when the calculation will take longer than 15
%                       seconds)
%
%  OUTPUT:
%     model = standard model structure containing the PCA and Regression
%             model (See MODELSTRUCT).
%      pred = prediction structure contains the scores from PCA model for
%             the input test data as pred.t.
%  Model and pred contain the following fields related to score limits and 
%  whether samples are within normal ranges or not: 
%      limits : struct with fields: 
%               cl: value used for cl option
%               bm: (1 x bmlookuppts) bm values for score limits
%              low: (nPC x bmlookuppts) lower score limit of inliers
%             high: (nPC x bmlookuppts) upper score limit of inliers
%           median: (nPC x bmlookuppts) median trace of scores
%    inlimits : (nsample x nPC) logical indicating if samples are inliers.
%           t : (nsample x nPC) scores
%   t_reduced : (nsample x nPC) scores scaled by limits, with 
%               limits -> +/- 1 at upper/lower limit, and -> 0 at median.
% submodelreg : regression model built to predict bm. Only PLS currently.
% submodelpca : PCA model used to calculate X-block scores.
%
%I/O: model = batchmaturity(x,ncomp_pca,options);
%I/O: model = batchmaturity(x,y,ncomp_pca,options);
%I/O: model = batchmaturity(x,y,ncomp_pca,ncomp_reg,options);
%I/O: pred  = batchmaturity(x,model,options);
%I/O: pred  = batchmaturity(x,model);
%     model = batchmaturity(x,ncomp,{reg_parameter_1 reg_parameter_2},options);%NOT YET SUPPORTED
%
%See also: BATCHDIGESTER, PCA

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0  % LAUNCH GUI
  analysis batchmaturity
  return
end
if ischar(varargin{1})
  options = [];
  options.plots         = 'final';
  options.waitbar       = 'auto';
  options.regression_method = 'pls';  %   [ {'pls'} | 'svm' | 'lwr'] only PLS is currently supported
  options.preprocessing = {[]};     %See Preprocess
  options.zerooffsety   = 1;
  options.stretchy      = 1;
  options.cl            = 0.95;      % confidence level
  options.clalgorithm   = 'astd';
  options.nearestpts    = 25;
  options.smoothing     = 0.05;
  options.bmlookuppts   = 1001;      % number of equi-spaced points in bm lookup table
  options.definitions = @optiondefs;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; out = evriio(mfilename,varargin{1},options); end
  return;
end

%Default output.
out = [];

%A) Check Options Input
[x,y,ncomp_pca,ncomp_reg,model,inopts,predictmode] = parseinputs(varargin{:});

% %Always put regression parameters cell.
% if ~iscell(reg_parameter)
%   reg_parameter = {reg_parameter};
% end

%Reconopts.
try
  options = reconopts(inopts, mfilename);
catch
  error(['Input OPTIONS not recognized.'])
end

if ~isdataset(x)
  x = dataset(x);
end

% now have x, y, ncomp_pca, ncomp_reg, options, OR x, model, options
% process:
include1     = x.include{1};

if isempty(y)
  y = (1:size(x,1))';
  options.zerooffsety = true;  %force these on if we have to make up y
  options.stretchy = true;
end
yn  = nan(size(x,1), 1);
if isdataset(y)
  y = y.data(:,y.include{2});              % switch from dataset
end
if size(x,1)==size(y,2) & size(y,1)==1
  y = y';
end
if size(y,2)>1
  error('BATCHMATURITY modes do not support multivariate (multi-column) Y-blocks');
end
if size(x,1)~=size(y,1)
  error('Number of rows in X and Y must match');
end

%look for batch indicators
batch = [];
[tf, loc] = ismember('bspc batch', lower(x.classname));
if loc==0
  %not found, check for just 'batch'
  [tf,loc] = ismember('batch',lower(x.classname));
end
if loc>0
  %got one...
  batch   = x.class{1,loc};
end
if isempty(batch)
  %check for cycling y values
  finy  = isfinite(y);
  dy    = diff(y(finy));  
  ndy   = dy<0;
  steps = find(ndy);
  sizes = diff([steps;sum(finy)]);
  if ~isempty(steps) & min(sizes)>1
    batch = cumsum([0;ndy])'+1;
  end
end
if isempty(batch)
  %no batch class found... just assume all one batch
  batch   = ones(1,size(x,1));
end

% interpolate y if necessary to fill in any nan values
if any(isnan(y))
  y = interpy(y, batch);
end

% option to disable normalization of y. both on as default
% Option1 name: zerooffsety
% Option2 name: stretchy
% (Also: both are forced on if y wasn't supplied and we had to make up
% values!)
for i=unique(batch)
  isub=batch(include1)==i;        % mask for included in this batch
  inclforbatch = include1(isub);  % the includes for this batch
  ysub = y(inclforbatch);
  if options.zerooffsety & options.stretchy
    if max(ysub)==min(ysub)
      yn(inclforbatch) = 50;      % If all identical, just set = 50
    else
      yn(inclforbatch) = (ysub - min(ysub))/(max(ysub)-min(ysub)) * 100;
    end
  elseif options.zerooffsety
    yn(inclforbatch) = ysub - min(ysub);
  elseif options.stretchy
    if max(ysub)==min(ysub)
      yn(inclforbatch) = 50;      % If all identical, just set = 50
    else
      yn(inclforbatch) = (ysub)/(max(ysub)-min(ysub)) * 100;
    end
  else
    yn(inclforbatch) = ysub;
  end
end

nlookuppts = options.bmlookuppts;
if ~predictmode

  %make yn a dataset and assign a label to the y-column
  yn = dataset(yn);
  yn.label{2} = 'Batch Maturity';

  % build PLS model on x
  optspls = pls('options');
  optspls.plots = 'none';
  optspls.display = 'off';
  optspls.preprocessing = options.preprocessing;
  modelpls = pls(x,yn,ncomp_reg,optspls);
  
  bm = modelpls.pred{2};
  bm = bm(include1);
  
  % Set the min and max of the BM range
  options.ymin = min(bm);
  options.ymax = max(bm);
  
  %   npts = length(yn);
  %   % plot all batches
  %   figure; plot(1:npts, yn, 'b', 1:npts, bm, 'g.')
  %   npl = min(size(x.data,2), 300);
  %   hold on; plot(1:npts,20*x.data(:,1:npl), 'k')
  %   hold on; plot(1:npts,20*x.data(:,1), 'r')  %plot first var red
  %   title('yn - blue, bm - green, x.data(:,1) - black')
  
  % build PCA model on x
  optspca = pca('options');
  optspca.plots = 'none';
  optspca.display = 'off';
  optspca.preprocessing = options.preprocessing;
  modelpca   = pca(x,ncomp_pca,optspca);
  t = modelpca.loads{1};
  t = t(include1,:);
  ncompused = size(t,2);
  
  % get limits on PCA scores
  cl = options.cl;
  npts = options.nearestpts;   % # nearby scores to use in getting limits
  npts = min(npts,length(include1));
  tlows = nan(ncompused, nlookuppts);
  thighs = nan(ncompused, nlookuppts);
  tmedians = nan(ncompused, nlookuppts);
  smoothing = options.smoothing; 
  nsmooth = smoothing*nlookuppts;
  bmtarget = [];
  if mod(nsmooth,2)==0
    nsmooth = nsmooth+1;  % ensure it is odd
  end
  
  %waitbar initialization
  sttime = now;
  h = [];
  % if not a raw model (~options.rawmodel)
  if ~isfield(options, 'rawmodel') | (isfield(options, 'rawmodel') &  ~options.rawmodel)
    for ii=1:ncompused
      t1 = t(:,ii);
      % handle exclusionof vars. should be same as used for pls above
      [bmtarget, tlows(ii,:), thighs(ii,:), tmedians(ii,:)] = getbmlimits(bm, t1, cl, include1, npts, nsmooth, nlookuppts, options);
      
      if ~strcmpi(options.waitbar,'off');
        %do waitbar if necessary
        pct = ii/ncompused;
        elap = (now-sttime);
        est = elap/pct*(1-pct)*24*60*60;
        if ~isempty(h) | elap*24*60*60>5 | est>15
          if isempty(h);
            h = waitbar(pct,'Calculating Confidence Limits...');
          else
            if ~ishandle(h);
              error('User Aborted Model Building');
            end
            waitbar(pct,h);
          end
          set(h,'name',['Est. Time: ' besttime(est)]);
        end
      end
    end
  end
  if ~isempty(h) & ishandle(h)
    close(h);
    drawnow;
  end
  
  model = modelstruct('batchmaturity');
  
  model.detail.preprocessing = options.preprocessing;
  
  if isempty(x.includ{1})
    error('No samples included. Can not calculate model.')
  end
  model.date  = date;
  model.time  = clock;
  model = copydsfields(x,model);
  model.detail.options = options;
  
  model.submodelreg = modelpls;
  model.submodelpca = modelpca;
  model.limits.cl = cl;
  model.limits.bm = bmtarget;
  model.limits.low = tlows;
  model.limits.high = thighs;
  model.limits.median = tmedians;
  
  out = model;
  
else
  % prediction mode: now have x, model, options
  % test X: pass through PLS and PCA model. Look up limits
  if ~ismodel(model) & ~strcmpi(model.modeltype,'batchmaturity')
    error('Input (model) does not appear to be a valid BATCHMATURITY model.')
  end
  
  if isempty(x.includ{1})
    error('No samples included. Can not predict.')
  end

  %create prediction model
  pred = model;
  pred.modeltype = 'BATCHMATURITY_PRED';
  pred.date  = date;
  pred.time  = clock;
  pred = copydsfields(x,pred);
  
  % apply PLS model
  modelpls = model.submodelreg;
  predpls = pls(x, modelpls, modelpls.detail.options);
  bmp = predpls.pred{2};
  bmp = bmp(include1);
  pred.submodelreg = predpls;
  
  % apply PCA model
  modelpca = model.submodelpca;
  predpca = pca(x, modelpca, modelpca.detail.options);
  t = predpca.loads{1};
  t = t(include1,:);
  pred.submodelpca = predpca;
  
  out = pred;
  
end

%do this for both predictions AND models
limitslow = model.limits.low';
limitshigh = model.limits.high';
tmedian    = model.limits.median';

% lookup index of nearest pt
if ~predictmode
  ibm = findnearestlookupindex(bm, model);
else 
  ibm = findnearestlookupindex(bmp, model);
end
ibm(ibm>size(limitslow,1)) = size(limitslow,1);
ibm(ibm<1) = 1;

% calculate inlimits, nsample x ncomp, values 1 or 0
inlimits = t <= limitshigh(ibm,:) & t >= limitslow(ibm,:);
% calculate reduced_t, where scores are scaled by limits, with reduced
% score at limits -> +/- 1, and -> 0 at the median trace
treduced  = nan(size(limitslow(ibm,:)));
treduced2 = treduced;

seq = 1:length(ibm);
for ip=1:size(limitslow,2)
  tpos = t(:,ip) > tmedian(ibm,ip);
  tposincludes = seq(tpos);
  d0           = limitslow(ibm,ip) == tmedian(ibm,ip);  % avoid div by 0
  treduced(~d0,ip)  = -(t(~d0,ip) - tmedian(ibm(~d0),ip))./(limitslow(ibm(~d0),ip)  - tmedian(ibm(~d0),ip));
  d0           = limitshigh(ibm,ip) == tmedian(ibm,ip); % reuse d0 for memory
  treduced2(~d0,ip) =  (t(~d0,ip) - tmedian(ibm(~d0),ip))./(limitshigh(ibm(~d0),ip) - tmedian(ibm(~d0),ip));
  treduced(tposincludes,ip) = treduced2(tposincludes,ip);
end
out.inlimits       = inlimits;
out.scores_reduced = treduced;
% out.scores       = t;   % virtual field referencing submodelpca.loads{1}

switch lower(options.plots)
  case 'final'
    if ~predictmode
      plotloads(out);
      plotscores(out);
    else
      plotscores(model,out);
    end
  case 'detailed'
  if ~predictmode
    for ii=1:ncompused
      %  plot test data scores and limits
      figure;plot(bmtarget, tlows(ii,:), 'b', bmtarget, thighs(ii,:), 'r')
      hold on; plot(bm, t(:, ii), 'k.');
%       hold on; plot(bm(~inlimits(:,ii)), t(~inlimits(:,ii), ii), 'g.');
      title(sprintf('PC%d scores for calibration data. Upper/lower limits (red/blue).  cl = %4.4g', ii, model.limits.cl));
      xlabel('BM')
      ylabel('t');
         
%       % plot reduced scores and limits for calibration
%       figure; plot(bm(inlimits(:,ii)), treduced(inlimits(:,ii), ii), 'k.');
%       hold on; plot(bm(~inlimits(:,ii)), treduced(~inlimits(:,ii), ii), 'r.');
%       title(sprintf('Reduced scores for PC%d for cal data.  cl = %4.4g', ii, model.limits.cl));
%       hline(+1.,'--r');
%       hline(-1.,'--r');
%       xlabel('BM')
%       ylabel('reduced t');
    end
  else
    ncomp = size(t,2);
    for ii=1:min(ncomp, size(x,2))
      %  plot test data scores and limits
      figure;plot(model.limits.bm, limitslow(:, ii), 'b', model.limits.bm, limitshigh(:,ii), 'r')
      hold on; plot(bmp(inlimits(:,ii)), t(inlimits(:,ii), ii), 'k.');
      hold on; plot(bmp(~inlimits(:,ii)), t(~inlimits(:,ii), ii), 'g.');
      title(sprintf('PC%d scores for test data. Upper/lower limits (red/blue).  cl = %4.4g', ii, model.limits.cl));
      xlabel('BM')
      ylabel('t');
      
      % plot reduced scores and limits
      figure; plot(bmp(inlimits(:,ii)), treduced(inlimits(:,ii), ii), 'k.');
      hold on; plot(bmp(~inlimits(:,ii)), treduced(~inlimits(:,ii), ii), 'r.');
      title(sprintf('Reduced scores for PC%d for test data.  cl = %4.4g', ii, model.limits.cl));
      hline(+1.,'--r');
      hline(-1.,'--r');
      xlabel('BM')
      ylabel('reduced t');
    end
  end
end

%--------------------------------------------------------------------------
function index = findnearestlookupindex(bm, model)
% index ibm
deltay = model.detail.options.ymax - model.detail.options.ymin;
inc = deltay/(model.detail.options.bmlookuppts-1);

%  index = round(bm/inc)+1;  % index of pred bm for each sample
index = round((bm-model.detail.options.ymin)/inc)+1;  % index of bm

%--------------------------------------------------------------------------
function [xtarget, tlow, thigh, tmedian] = getbmlimits(x, t, cl, include1, npts, nsmooth, nlookuppts, options)
%TESTBMLIMITS test calculation of limits on scores for a sequence of BM values
% x and t are 1xnsample
% close all
% cl         = .9;    % confidence level, cl/2 each side
% npts       = 101;   % number of nearest y (BM)
% nsmooth    = 35;    % number of points in smoothing filter (width)
% nlookuppts = 1001   % number of pts in bm lookup table on range [0, 100] inclusive

if isdataset(x)
  x = x.data;
end

x = x';
t = t';
% xstart = 0;xend=100; xinc = 0.1;     % make xinc be a parameter
xstart = options.ymin;
xend   = options.ymax;
xinc   = (xend - xstart)/1000;
loopcount = 0;
while loopcount<5
  nx = floor((xend-xstart)/xinc) + 1;
  tlow = repmat(nan, 1, nx);         % lower limit on t for this cl
  thigh = repmat(nan, 1, nx);        % upper limit on t for this cl
  tmedian = repmat(nan, 1, nx);        % median t for this cl
  xtarget = repmat(nan, 1, nx);      % target BM
  sxmask = repmat(0, size(x));
  
  [sx,order]=sort(x);
  st=t(order);
  nmeansmooth = max(3, npts);
  if mod(nmeansmooth,2)==0
    nmeansmooth = nmeansmooth+1;      % ensure it is odd
  end
  stm = savgol(st,nmeansmooth,0,0);   %moving average
  
  for ix=1:nx
    xtarget(ix) = xstart + (ix-1)*xinc;
    [thigh(ix), tlow(ix), tmedian(ix), sortedxmask] = getcl(sx, st, stm, xtarget(ix), npts, cl, nsmooth, options);
    sxmask = sxmask | sortedxmask;
  end
  
  unused = getunused(sxmask);
  if sum(unused) == 0
    %     figure; plot(sx, st, 'b.', sx(unused), st(unused), 'g.', sx(sxmask), st(sxmask), 'r.')
    %     title('Calibration: Unused points, (green)');
    %     xlabel('BM')
    %     ylabel('t');
    break
  else
    xinc = xinc/2;  % reduce segment width to try using all points. Repeat.
    loopcount = loopcount+1;
    %     figure; plot(sx, st, 'b.', sx(unused), st(unused), 'g.', sx(sxmask), st(sxmask), 'r.')
    %     title('Unused points, (green)');
  end
end

x100 = linspace(options.ymin, options.ymax, nlookuppts); % 
limits100 = interp1(xtarget', [tlow' thigh' tmedian'], x100');
xtarget = x100;
tlow = limits100(:,1)';
thigh = limits100(:,2)';
tmedian = limits100(:,3)';

if nsmooth > 1
  tlow  = savgol(tlow, nsmooth,0,0);    %moving average
  thigh = savgol(thigh, nsmooth,0,0);   %moving average
  tmedian = savgol(tmedian, nsmooth,0,0);   %moving average
end


% figure; plot(sx, st, 'b.', sx(unused), st(unused), 'g.', sx(sxmask), st(sxmask), 'r.')
% title(sprintf('Points used in calculating limits (red). xinc = %4.4g, npts = %d, cl = %4.4g', xinc, npts, cl));
% xlabel('BM')
% ylabel('t');

% figure;plot(xtarget, tlow, 'b', xtarget, thigh, 'r')
% title(sprintf('Upper and lower limits for cl = %4.4g. (xinc = %4.4g, npts = %d)', cl, xinc, npts));
% xlabel('BM')
% ylabel('t');

% figure; plot(sx, st, 'b.')
% figure; plot(sx, st, 'b.', sx(sxmask), st(sxmask), 'r.')

%--------------------------------------------------------------------------
function unused = getunused(sxmask)
% find any points within the segments which are not used by getcl
ss=1:length(sxmask);
ss1 = ss(sxmask);
unused1 = (ss>min(ss1)&ss<max(ss1));
unused2 = ~sxmask;
unused = unused1 & unused2;

%--------------------------------------------------------------------------
function [thigh, tlow, tmedian, sortedymask] = getcl(sy,st, stm, ytar, n, cl, win, options)
%GETCL: Get limits in scores, t, if batch maturity value equals ytar.
%
% Input:
%    sy = vector of batch maturity values, sorted ascending
%    st = vector scores values, in same order as sy
%   stm = vector of scores, smoothed form of st.
%  ytar = y value at which limits on t are desired
%     n = number of points nearest ytar to use in finding t limits
%    cl = 1 - fraction of data expected to be outliers, e.g. 0.09
%   win = number of points in smoothing filter (width)
%
% I/O: [yhigh, ylow, ymedian] = getcl(y,t, ytar, n, cl)
%
% The 'normal' score range is between percentile(cl/2) to
% percentile(1-cl/2).
% The limits are calculated using the weighted score deviations from 
% the mean score, weighted by distance from ytar using the n nearest points 
% to ytar. A Gaussian weighting is used with s.d. = n/4.

st = st - stm;              % deviation t from mean

% find the n y's which are closest to ytar
dev = abs(sy-ytar);
[sdev, is] = sort(dev);
irange = is(1:n); % indicies of dev
sortedymask = repmat(0, size(is));
sortedymask(irange) = 1;

st  = st(irange);           % nearest points
stm = stm(irange);

switch options.clalgorithm
  case 'astd'
    %use asymmetric standard deviation limits
    clstds = normdf('q',cl);  %confidence limit = how many standard deviations
    negs = st<0;
    pos  = st>0;
    %calculate standard deviation of the positive and negative deviating
    %groups
    tlow  = stm(1)-(sqrt(sum((st(negs).^2)/(sum(negs)-1)))*clstds);
    thigh = stm(1)+(sqrt(sum((st(pos).^2)/(sum(negs)-1)))*clstds);
    tmedian = stm(1)+median(st,2);
    
  case 'percentile'
    % use percentile of deviations
    cl = 1-cl;  %convert from confidence limit to outlier amount (1-cl)
    tlow = percentile(st', cl/2);
    thigh = percentile(st', 1-cl/2);
    tmedian = percentile(st', 0.5);
    tlow = tlow+stm(1);
    thigh = thigh+stm(1);
    tmedian = tmedian+stm(1);
    
end

%--------------------------------------------------------------------------
function yn = interpy(y, batch)
% replace nan values in y by linear interpolation
% y is vector length N
% batch is a vector of integers indicating which y values are same batch.
% Interpolation is done to points within a batch, batch by batch.
yn = y*nan;
for i=unique(batch)
  isub = batch==i;
  ysub = y(isub);
  xsub = 1:length(ysub);
  xind = ~isnan(ysub);
  yysub = interp1(xsub(xind), ysub(xind), xsub, 'linear', 'extrap');
  yn(isub) = yysub;
end

%----------------------------------------------------
% Possible calls:
% 2 inputs: (x, model)                        // Prediction
% 2 inputs: (x, ncomp_pca)                    // Calibration
% 3 inputs: (x,ncomp_pca,options)             // Calibration
%           (x,model,options)                 // Prediction
%           (x,y,ncomp_pca)                   // Calibration
% 4 inputs: (x,y,ncomp_pca,options)           // Calibration
%           (x,y,ncomp_pca,ncomp_reg)         // Calibration  ***
% 5 inputs: (x,y,ncomp_pca,ncomp_reg,options) // Calibration
function [x,y,ncomp_pca,ncomp_reg,model,inopts,predictmode] = parseinputs(varargin)

ncomp_reg   = [];
ncomp_pca   = [];

if (~isnumeric(varargin{1}) & ~isdataset(varargin{1})) | prod(size(varargin{1}))==1
  error('Input X must be a dataset or double matrix')
end

switch nargin
  case 1
    error(['Requires more than one input parameter'])
  case 2
    %I/O: pred  = batchmaturity(x,model);
    %I/O: pred  = batchmaturity(x,ncomp_pca);
    if ismodel(varargin{2})
      % (x,model): convert to (x, model, opts)
      x           = varargin{1};
      y           = [];
      model       = varargin{2};
      inopts      = model.detail.options;
      predictmode = 1;
    elseif isnumeric(varargin{2}) & prod(size(varargin{2}))==1
      %I/O: pred  = batchmaturity(x,ncomp_pca);
      x           = varargin{1};
      y           = [];
      ncomp_pca   = varargin{2};
      ncomp_reg   = ncomp_pca;
      inopts      = [];
      model       = [];
      predictmode = 0;    % no prediction      
    else                                  %  unrecognized args
      error('Y-block input is missing or invalid model. try: (x, model) or (x,y,ncomp)');
    end
    
  case 3  %three inputs
    %I/O: model = batchmaturity(x,ncomp_pca,options);                   A
    %I/O: pred  = batchmaturity(x,model,options);                       B
    %I/O: model = batchmaturity(x,y,ncomp_pca);                         C
    %I/O: model = batchmaturity(x,ncomp_pca,ncomp_pls);                 D
    if  ismodel(varargin{2}) & isa(varargin{3},'struct')
      % Must be case B: (x,model,options)
      % varargin is good as-is.
      x           = varargin{1};
      y           = [];
      model       = varargin{2};
      inopts      = varargin{3};
      predictmode = 1;    % do prediction
    elseif isvalidy(varargin{1:2}) & isnumeric(varargin{3})
      %I/O: model = batchmaturity(x,y,ncomp_pca);                         C
      x           = varargin{1};
      y           = varargin{2};
      ncomp_pca   = varargin{3};
      ncomp_reg   = ncomp_pca;
      inopts      = [];
      model       = [];
      predictmode = 0;    % no prediction
    elseif isvalidy(varargin{1:2}) & ismodel(varargin{3})
      %I/O: (x,y,model)   ***INVALID!
      error('Test mode (model and new y) not supported');
    elseif isnumeric(varargin{2}) & prod(size(varargin{2}))==1 & ismodel(varargin{3})
      %I/O: (x,ncomp,model)   ***INVALID!
      error('Input arguments not recognized.');
    elseif isnumeric(varargin{2}) & prod(size(varargin{2}))==1 & isnumeric(varargin{3})
      %I/O: model = batchmaturity(x,ncomp_pca,ncomp_pls);                         D
      x           = varargin{1};
      y           = [];
      ncomp_pca   = varargin{2};
      ncomp_reg   = varargin{3};
      inopts      = [];
      model       = [];
      predictmode = 0;    % no prediction
    elseif isnumeric(varargin{2}) & prod(size(varargin{2}))==1 & isstruct(varargin{3})
      % Must be case A: (x,ncomp_pca,options);
      x           = varargin{1};
      y           = [];
      ncomp_pca   = varargin{2};
      ncomp_reg   = ncomp_pca;
      inopts      = varargin{3};
      model       = [];
      predictmode = 0;    % no prediction
    else
      error('Input arguments not recognized.')
    end
    
    % 4 inputs: model = batchmaturity(x,y,ncomp_pca,options);
  case 4   %four inputs
    %I/O: model = batchmaturity(x,y,ncomp_pca,options);
    if  isvalidy(varargin{1:2}) & isnumeric(varargin{3})  & isstruct(varargin{4})
      % Must be (x,y,ncomp_pca,options)
      x           = varargin{1};
      y           = varargin{2};
      ncomp_pca   = varargin{3};
      ncomp_reg   = varargin{3};
      inopts      = varargin{4};
      model       = [];
      predictmode = 0;    % no prediction
    elseif isvalidy(varargin{1:2}) & isnumeric(varargin{3})  & isnumeric(varargin{4})
      %           (x,y,ncomp_pca,ncomp_reg)         // Calibration  ***
      x           = varargin{1};
      y           = varargin{2};
      ncomp_pca   = varargin{3};
      ncomp_reg   = varargin{4};
      inopts      = [];
      model       = [];
      predictmode = 0;    % no prediction
    elseif isnumeric(varargin{2}) & prod(size(varargin{2}))==1  & isnumeric(varargin{3}) & isstruct(varargin{4})
      %           (x,ncomp_pca,ncomp_reg,options)         // Calibration
      x           = varargin{1};
      y           = [];
      ncomp_pca   = varargin{2};
      ncomp_reg   = varargin{3};
      inopts      = varargin{4};
      model       = [];
      predictmode = 0;    % no prediction
    else
      error('Input arguments not recognized.')
    end
    
  case 5
    %I/O: model = batchmaturity(x,y,ncomp_pca,ncomp_reg,options);
    if  isvalidy(varargin{1:2}) & isnumeric(varargin{3})  & isa(varargin{5},'struct')
      % Must be (x,y,ncomp_pca,options)
      % convert to [x, y, ncomp_pca, ncomp_reg, opts]
      % varargin is good as-is
      x           = varargin{1};
      y           = varargin{2};
      ncomp_pca   = varargin{3};
      ncomp_reg   = varargin{4};
      inopts      = varargin{5};
      model       = [];
      predictmode = 0;    % no prediction
    else
      error(['Input arguments not recognized.'])
    end
    
  otherwise
    error('Input arguments not recognized.')
    
end

if ~predictmode & isempty(ncomp_reg)
  ncomp_reg = ncomp_pca;
end


%-----------------------------------------------------------------------
function out = isvalidy(x,y)

if isempty(y) | ((isnumeric(y) | isdataset(y)) & max(size(y))>1)
  out = true;
else
  out = false;
end
% out =  isempty(y) || ((isnumeric(y) || isdataset(y)) && size(x,1)==size(y,1));

%-----------------------------------------------------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                            userlevel       description
'plots'                  'Display'        'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
'preprocessing'          'Standard'       'cell(vector)'  ''                               'novice'        'Preprocessing structures. Cell 1 is preprocessing for X block, Cell 2 is preprocessing for Y block.';
%'regression_method'      'Standard'       'select'        {'pls' 'svm' 'lwr'}              'novice'        '[ {''pls''} | ''svm'' | ''lwr''] A string indicating type of regression method to use.';
'zerooffsety'            'Standard'       'boolean'       ''                               'novice'        'Transform y resetting to start at zero in each batch.';
'stretchy'               'Standard'       'boolean'       ''                               'novice'        'Transform y to have range=100 in each batch.';
'cl'                     'Standard'       'double'        'float(0:1)'                     'novice'        'Expected fraction of outliers (2-sided) in data.';
'clalgorithm'            'Standard'       'select'        {'astd' 'percentile'}            'novice'        'Confidence Limits algorithm: ''astd'' = asymmetric standard deviation, ''percentile'' = percentile of data.';
'nearestpts'             'Standard'       'double'        'int(1:inf)'                     'novice'        'Number nearby scores used in getting limits.';
'smoothing'              'Standard'       'double'        'float(0:0.5)'                   'novice'        'Governs smoothing applied to limit lines. Width of savgol smoothing window as fraction of the BM range.';
'bmlookuppts'            'Standard'       'double'        'int(1:inf)'                     'novice'        'Number of equi-spaced points in bm lookup table.';

};

out = makesubops(defs);


