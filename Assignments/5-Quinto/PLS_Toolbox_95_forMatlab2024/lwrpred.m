function [ypred,extrap, ssqresiduals, tsqs,nearestpts] = lwrpred(xnew,xold,yold,lvs,npts,out)
%LWRPRED Predictions based on locally weighted regression models.
%  This function makes new sample predictions (ypred) for a new
%  matrix of independent variables (xnew) based on an existing 
%  data set of independent variables (xold), and a vector of dependent
%  variables (yold). Predictions are made using a locally weighted
%  regression model defined by the number principal components
%  used to model the independent variables (lvs), and the number
%  of points defined as local (npts). 
%  Optional input/output argument "model" (see I/O signatures below) contains 
%  quantities (loadings, weights etc) calculated from calibration data.
%  If a model structure is passed in then these do not have to be re-calculated. 
%  When a model is passed into this function the output is either as shown above 
%  or is a model, depending on the value of the input options.structureoutput 
%  (see options description below).
%
%  Optional input (options) is a
%  structure containing one or more of the following fields:
%
%   display : [ 'off' |{'on'}] Governs display 
%   waitbar : [ 'off' |{'auto'}| 'on' ] governs use of waitbar during
%             analysis. 'auto' shows waitbar if delay will likely be longer
%             than a reasonable waiting period.
%   alpha   : [0-1] Weighting of y-distances in selection of local points.
%       0 = do not consider y-distances {default}, 1 = consider ONLY
%       y-distances. With any positive alpha, the algorithm will tend to
%       select samples which are close in both the PC space but which also
%       have similar y-values. This is accomplished by repeating the
%       prediction multiple times. In the first iteration, the selection of
%       samples is done only on the PC space. Subsequent iterations take
%       into account the comparison between predicted y-value of the new
%       sample and the measured y-values of the calibration samples.
%   iter    : [{5}] Iterations in determining local points. Used only when
%       alpha > 0 (i.e. when using y-distance scaling).
%   preprocessing : {2 2} Two element cell array defining preprocessing to
%        use on data. First element of cell defines x-block preprocessing,
%        second element defines y-block preprocessing. Options are:
%          0 = no scaling or centering
%          1 = mean center only
%          2 = autoscale (default)
%        For example: {1 2} performs mean centering on x-block and
%        autoscaling on y-block.
%   algorithm: [{'globalpcr'} | 'pcr' | 'pls' ] Method of regression after
%        samples are selected. 'globalpcr' performs PCR based on the PCs
%        calculated from the entire calibration data set but a regression
%        vector calculated from only the selected samples. 'pcr' and 'pls'
%        calculate a local PCR or PLS model based only on the selected 
%        samples.
%   reglvs: [] Used only when algorithm is 'pcr' or 'pls', this is the
%        number of latent variables/principal components to use in  the
%        regression model, if different from the number used to select
%        calibration samples. [] (Empty) implies LWRPRED should use the
%        same number of latent variables in the regression as were used to
%        select samples. NOTE: This option is NOT used when algorithm is
%        'globalpcr'.
%   structureoutput: [ true |{false}] Determines whether output is a model 
%        structure (if true), or [ypred,extrap, ssqresiduals,tsqs] (if
%        false). This is only relevant for cases where a model is passed in
%        as argument.
%   waitbartrigger: [15] Threshold for estimated time remaining above
%        which a waitbar will be shown when in "auto" waitbar mode.
%
%  Additional output (extrap), a vector equal in length to number of
%  samples in xnew, is non-zero when the given sample was predicted
%  by extrapolating outside of the range of y-values which were used in the
%  model. The value represents the distance (in y-units) extrapolated
%  outside of the modeled samples. For example, a value of -0.3 indicates
%  that the given sample was predicted by extrapolating 0.3 y-units below
%  the lowest modeled sample in yold.
%  Additional output (ssqresiduals), cell array, first element contains
%  vector of residuals (Q).
%  Additional output (tsqs), cell array, first element contains vector of
%  Tsquared statistic.
%  Output (nearestpts) has dimension size(xnew,1) rows and npts columns. 
%  Each row contains the npts row indices to the X calibration data 
%  indicating which calibration samples were used to predict for the test
%  sample.
%
%Note: If scaling is done prior to calling lwrpred, be sure to use the same
% scaling on new and old samples!
%
%I/O: [ypred,extrap,ssqresiduals,tsqs,nearestpts] = lwrpred(xnew,xold,yold,lvs,npts,options);
%I/O: [model] = lwrpred(xold,yold,lvs,npts,options);
%I/O: [ypred,extrap,ssqresiduals,tsqs,nearestpts] = lwrpred(xnew,model,options);
%
%See also: LWR, MODELSELECTOR, PLS, POLYPLS

% Copyright © Eigenvector Research, Inc. 1994
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.
%Modified BMW 2/94
%nbg 11/00 added out
%bmw 8/02 modified to accept dataset object
%jms 4/05 -added options
%   -incorporated lwrxy functionality
%   -added flexible preprocessing
%   -vectorized selection code
%   -control waitbar with "display" option
  
if nargin == 0; xnew = 'io'; end
if ischar(xnew);
  options = [];
  options.name = 'options';
  options.display = 'on';
  options.alpha = 0;
  options.iter  = 5;
  options.preprocessing = 2;
  options.algorithm = 'globalpcr';   %'globalpcr' | 'pcr' | 'pls'
  options.reglvs = [];
  options.waitbar = 'auto';
  options.waitbartrigger = 15;
  options.structureoutput = false;
  
  if nargout==0; evriio(mfilename,xnew,options); else; ypred = evriio(mfilename,xnew,options); end
  return; 
end

usecase = 'model_none';
switch nargin
  case 6
    % lwrpred(xnew,xold,yold,lvs,npts,options);
    usecase = 'model_none';
  case 5
    % distinguish between two possible calls
    %A: [model] = lwrpred(xold,yold,lvs,npts,options);
    %B: [ypred] = lwrpred(xnew,xold,yold,lvs,npts);
    if isa(npts,'struct')   % case A
      usecase = 'model_out';
      % no Xnew passed in: calc model case
      [xold, yold, lvs, npts, out] = deal(xnew, xold, yold,lvs,npts);
      %NOTE: xnew is still == xold and we'll use it that way
    else                    % case B
      usecase = 'model_none';
      out = [];
      % xnew, xold, yold, lvs, npts passed in; no need to rename any arguments
    end
  case 4  % 4 arg: lwrpred(xold,yold,lvs,npts);
      usecase = 'model_out';
      % no Xnew passed in: calc model case
      [xold, yold, lvs, npts] = deal(xnew, xold, yold,lvs);
      %NOTE: xnew is still == xold and we'll use it that way
      out = [];
  case 3  % 3 arg: lwrpred(xnew, model, out)
    [model, out] = deal(xold, yold);
    yold = [];  % clean up
    xold = [];
    % distinguish between two possible outputs
    %A: [ypred,extrap,ssqresiduals,tsqs] = lwrpred(xnew, model, out)
    %B:                           [pred] = lwrpred(xnew, model, out);
    % handle two types of output:
    if (isfield(out, 'structureoutput') & ~isempty(out.structureoutput) & ~out.structureoutput)
      % structoutput is defined and is = false
      usecase = 'model_in';
    else
      % default to outputting model struct
      % Case lwrpred(xnew, model, out)
      usecase = 'model_inout';
    end   
    lvs = model.detail.lvs;
    npts = model.detail.npts;
  case 2  % 2 arg: lwrpred(xnew, model)
    % rename the second arguments
    model = xold;
    xold=[];
    yold=[];
    % structoutput is defined and is = false, so no model out
    usecase = 'model_in';
    lvs = model.detail.lvs;
    npts = model.detail.npts;
    out = [];
  otherwise
    error('lwrpred: unexpected number of arguments to function ("%s")', nargin);
end

if isa(xnew,'dataset')
  inds = xnew.includ;
  xnew = xnew.data(:,inds{2:end}); %do NOT exclude rows of xnew - we need predictions for those
end
xoldinclx = [];         % Needed to map the nearestpts indices to X cal
if isa(xold,'dataset')  % sample indices in case of excluded samples
  inds = xold.includ;
  xoldinclx = inds{1};
  xold = xold.data(inds{:});
end
if isa(yold,'dataset')
  inds = yold.includ;
  yold = yold.data(inds{:});
end

if ~isnumeric(out) | isempty(out);
  options = out;
else
  options = [];
  options.display = out;
end
options = reconopts(options,'lwrpred',{'blockdetails','confidencelimit','definitions','plots','minimumpts','ptsperterm'});
if ischar(options.display);
  options.display = strcmp(options.display,'on');
end
if ~ismember(lower(options.algorithm),{'globalpcr' 'pls' 'pcr'})
  error('Unrecognized algorithm option "%s"',options.algorithm)
end

%test sizes of inputs
if strcmp(options.algorithm,'globalpcr')
  if lvs > npts
    error('globalpcr: npts must >= lvs')
  end
else
  if  options.reglvs > npts
    error('Local Regression: npts must >= reglvs')
  end
end
if( strcmp(usecase, 'model_in') | strcmp(usecase, 'model_inout'))
  [mold,nold] = size(model.detail.globalmodel.axold);
  [my,ny] = size(model.detail.globalmodel.ayold);
else
  [mold,nold] = size(xold);
  [my,ny] = size(yold);
end

[m,n] = size(xnew);
if n ~= nold
  error('xnew and xold must have the same number of columns')
end

if my ~= mold
  disp('xold and yold must have the same number of rows')
  error('if xold and/or yold is Dataset Object, check includ')
end 
  
if options.alpha == 0
  %do only one iteration if alpha is zero (no y weighting)
  options.iter = 1;
else
  if options.alpha<0 | options.alpha>1;
    error('options.alpha must be a value between zero and one')
  end    
end

%check regression lvs
if isempty(options.reglvs)
  options.reglvs = lvs;
end

if ~strcmp(options.algorithm,'globalpcr') && options.reglvs > npts
  error('options.reglvs must <= npts')
end

%handle preprocessing
if ~iscell(options.preprocessing)
  if length(options.preprocessing)==2;
    options.preprocessing = {options.preprocessing(1) options.preprocessing(2)};
  elseif length(options.preprocessing)==1
    options.preprocessing = {options.preprocessing(1) options.preprocessing(1)};
  else
    error('Unrecognized preprocessing option');
  end
else
  if length(options.preprocessing)==1
    options.preprocessing = options.preprocessing([1 1]);
  end
end

% Calculate the preprocessed x, y, loadings and scores, or get them from input model:
if (~strcmp(usecase, 'model_in') & ~strcmp(usecase, 'model_inout'))
  % No input model
  switch options.preprocessing{1}
    case 2
      [axold,mxold,stdxold] = auto(xold);
    case 1
      [axold,mxold] = mncn(xold);
      stdxold = ones(1,nold);
    case 0
      axold   = xold;
      mxold   = zeros(1,nold);
      stdxold = ones(1,nold);
    otherwise
      error('Other preprocessing options not currently supported');
  end
  switch options.preprocessing{2}
    case 2
      [ayold,myold,stdyold] = auto(yold);
    case 1
      [ayold,myold] = mncn(yold);
      stdyold = ones(1,ny);
    case 0
      ayold   = yold;
      myold   = zeros(1,ny);
      stdyold = ones(1,ny);
    otherwise
      error('Other preprocessing options not currently supported');
  end

  % Need to calculate PCA model of old data
  if nold < mold
    cov = (axold'*axold)/(mold-1);
    [u,s,v] = svd(cov,0);
  else
    cov = (axold*axold')/(mold-1);
    [u,s,v] = svd(cov,0);
    v = axold'*v;
    for i = 1:mold
      v(:,i) = v(:,i)/norm(v(:,i));
    end
  end
  u = axold*v(:,1:lvs);   %project calX onto loadings to get cal scores
  [au,umx,ustd] = auto(u(:,1:lvs));   %autoscale scores to give each score equal weight in distance calculation
  
  % Save these quantities into the new, returned model:
  if strcmp(usecase, 'model_out')
    outstruct = lwrstruct;
    outstruct.loads{1,1} = u;  %X-block scores   't'  (will be replaced at end with Xnew's scores)
    outstruct.loads{2,1} = v(:,1:lvs); %X-block loadings 'p'
    outstruct.detail.includ{1,1} = 1:size(xold,1);  % enter default include arrays
    outstruct.detail.includ{2,1} = 1:size(xold,2);  % enter default include arrays
    outstruct.detail.preprocessing = options.preprocessing;
    outstruct.detail.lvs = lvs;
    outstruct.detail.npts = npts;
    outstruct.detail.globalmodel.u  = u;
    outstruct.detail.globalmodel.v  = v(:,1:lvs);
    outstruct.detail.globalmodel.au = au;
    outstruct.detail.globalmodel.umx = umx;
    outstruct.detail.globalmodel.ustd = ustd;
    outstruct.detail.globalmodel.axold = axold;
    outstruct.detail.globalmodel.mxold = mxold;
    outstruct.detail.globalmodel.stdxold = stdxold;
    outstruct.detail.globalmodel.ayold = ayold;
    outstruct.detail.globalmodel.myold = myold;
    outstruct.detail.globalmodel.stdyold = stdyold;
    outstruct.detail.globalmodel.xoldinclx = xoldinclx;
    outstruct.detail.options = out;
  end
else
  % Have an input model.
  % Get u, v, au, umx, ustd, axold,mxold,stdxold,ayold,myold,stdyold from input model
  u   = model.detail.globalmodel.u;  %grabbing from global model (NOT top level loads)
  v   = model.detail.globalmodel.v;  %grabbing from global model (NOT top level loads)
  au  = model.detail.globalmodel.au;
  umx = model.detail.globalmodel.umx;
  ustd = model.detail.globalmodel.ustd;
  axold   = model.detail.globalmodel.axold;
  mxold   = model.detail.globalmodel.mxold;
  stdxold = model.detail.globalmodel.stdxold;
  ayold   = model.detail.globalmodel.ayold;
  myold   = model.detail.globalmodel.myold;
  stdyold = model.detail.globalmodel.stdyold;
  xoldinclx = model.detail.globalmodel.xoldinclx;
end

[mau,nau] = size(au);
sxnew     = scale(xnew,mxold,stdxold);  %center and scale NEW X to the calibration center and scaling
newu      = scale(sxnew*v(:,1:lvs),umx,ustd);  %project new X onto loadings AND apply same autoscaling as done above for scores

%pre-allocate outputs
ureg      = zeros(npts,lvs);
yreg      = zeros(npts,1);
weights   = zeros(npts,1);
extrap    = zeros(m,1);
yregmin   = nan(m,1);
yregmax   = nan(m,1);
nearestpts = zeros(m,npts);

%keep npts "in range"  (in case they asked for more points than we have)
npts = min(npts,mau);

%prep ypred variable
if options.alpha == 0
  ypred     = zeros(m,1);
else
  %if using y-weighting, do initial guess for y
  r = u(:,1:lvs)\ayold;
  bpcr = (v(:,1:lvs)*r)';
  ypred = sxnew*bpcr';
end

if strcmp(options.waitbar,'on')
  hh = waitbar(0,'Please wait while LWRPRED completes predictions');
else
  hh = nan;   %not a handle - will ignore all waitbar actions later
end
regopts = [];
regopts.display = 'off';

% Calculate Q and Tsquared for globalpcr case. Calculated again for pcr and pls cases
Tnew = sxnew*v(:,1:lvs);
% lambda = sum(scores.^2)/(npts-1)
lambda = sum(u.^2)/(size(u,1)-1);

tsqs = nan(size(Tnew,1),1);
for i = 1:size(Tnew,1)
  tsqs(i) = sum((Tnew(i,:).^2)./lambda,2);
end

x_hat = Tnew*v(:,1:lvs)';
E = sxnew - x_hat;
ssqresiduals = nan(size(E,1),1);
for i = 1:size(E,1)
  ssqresiduals(i) = sum(E(i,:).^2,2);
end

ssqresiduals_var = nan(1,size(E,2));
for i = 1:size(E,2)
  ssqresiduals_var(i) = sum((E(:,i).^2),1);
end 

if ~strcmp(options.algorithm,'globalpcr')
  ssqresiduals_var = 0;  %if we're doing local models, calculate this on-the-fly but initialize at zero
end

startat = now;
%loop over each sample in xnew
for i = 1:m;

  if mod(i,40)==0
    est = round(((now-startat)*24*60*60*((m-i+1)/(i-1))));
    if ishandle(hh)
      %update waitbar
      waitbar(i/m,hh)
      if ~ishandle(hh)
        error('aborted by user');
      end
      set(hh,'name',['Est. Time Remaining: ' besttime(est)]);
    elseif strcmpi(options.waitbar,'auto') & i>5 & est>options.waitbartrigger
      hh = waitbar(i/m,'Please wait while LWRPRED completes predictions');
    end
  end

  %do multiple iterations (but only if using y-weighting, otherwise this is
  %allways a SINGLE cycle through)
  for k = 1:options.iter
    if options.alpha>0;
      %calculate distance (including y-weighting in the calcuation)
      xdist = sum(((au-ones(mold,lvs)*diag(newu(i,:))).^2)',1)';
      ydist = (ayold-ones(mold,1)*ypred(i,1)).^2;
      dists = (1-options.alpha)*xdist + options.alpha*ydist;
    else
      %calculate distance
      dists = sum(((au-ones(mau,nau)*diag(newu(i,:))).^2)',1)';
    end
    if any(isnan(dists))
      continue;
    end
    [a,b]   = sort(dists);
    weights = (1-(a(1:npts,1)./a(npts,1)).^3).^3;
    h       = diag(weights.^2);
    nearestpts(i,:) = b(1:npts);
    switch options.algorithm
      case 'globalpcr'
        %use PCA model calculated on whole dataset (this is the standard
        %  way LWR had been implemented in past PLS_Toolbox versions)
        ureg    = au(b(1:npts,1),:);      %grab scores of interest (npts total points)
        yreg    = ayold(b(1:npts,1),1);   %grab y-values of interest (npts total points)
        
        % if u (samples) or y values are identical then return mean of y
        urange = range(ureg);
        yrange = range(yreg);
        if(all(urange==0) | yrange==0)
          % return mean of these y in this case
          ypred(i,1) = mean(yreg);
          % extrap(i,1) will be zero below because ypred is within yreg range
        else
          ureg1   = [ureg ones(npts,1)];    %create x for regression (including intercept)
          breg    = pinv(ureg1'*h*ureg1)*ureg1'*h*yreg;   %weighted regression
          %  b = inv(U'hU)U'hy
          % where
          %  U = scores of cal samples
          %  y = y values of cal samples
          %  h = diagonal weighting matrix
          ypred(i,1) = [newu(i,:) 1]*breg;    %apply regression just calculated to new sample's scores (newu)
        end
      otherwise
        %Local models built on local decomposition of data
        %start by re-centering and scaling the data (as desired)
        
        axoldset = axold(b(1:npts,1),:);
        ayoldset = ayold(b(1:npts,1),:);                
        % if u (samples) or y values are identical then return mean of y (ticket #668)
        xrange = range(axoldset);
        yrange = range(ayoldset);
        if(all(xrange==0) | yrange==0 | options.reglvs==0)
          % return mean of these y in this case
          ypred(i,1) = mean(ayoldset);
          % extrap(i,1) will be zero below because ypred is within yreg range
        else 
          switch options.preprocessing{1}
            case 2
              %autoscale
              [localaxold,localmx,localsx] = auto(axoldset);
            otherwise
              %mean center (required even with preprocessing = 0)
              [localaxold,localmx] = mncn(axoldset);
              localsx = ones(1,size(axold,2));
          end
          switch options.preprocessing{2}
            case 2
              %autoscale
              [localayold,localmy,localsy] = auto(ayoldset);
            otherwise
              %mean center (required even with preprocessing = 0)
              [localayold,localmy] = mncn(ayoldset);
              localsy = 1;
          end
          %apply to new data
          localsxnew = scale(sxnew(i,:),localmx,localsx);

          %apply weighting and re-adjust centering
          [localaxoldwt,localmx_adj] = mncn(h*localaxold);
          [localayoldwt,localmy_adj] = mncn(h*localayold);
          localsxnewwt = scale(localsxnew,localmx_adj);

          switch options.algorithm
            case 'pcr'
              %Do PCR on selected samples and predict from that regression vector                          
              [breg,ssq,loads,scores,pcassq] = pcrengine(localaxoldwt,localayoldwt,options.reglvs,regopts);
              [breg0,ssq,loads,scores,pcassq] = pcrengine(localaxold,localayold,options.reglvs,regopts);
              % calculate Q and Tsq
              Tnew_i = localsxnew*loads;
              npcassq = min(options.reglvs, size(pcassq,1));
              lambda = pcassq(1:npcassq,2);
%               lambda = sum(scores.^2)/(npts-1); % it is same
              lambdainv = diag(1./lambda);              
              tsqs(i, :) = NaN;   % clear
              ssqresiduals(i, :) = NaN;
              tsqs(i, 1) = Tnew_i*lambdainv*Tnew_i';
              x_hat(i,:) = Tnew_i*loads';
              E(i,:) = localsxnew - x_hat(i,:);  % use the loadings to project for x_hat
              E1 = localsxnew - x_hat(i,:);  % use the loadings to project for x_hat
              ssqresiduals(i, 1) = E1*E1';
              ssqresiduals_var = ssqresiduals_var + E1.^2;

              % chose the highest index row which contains no NaNs by
              % filtering out rows with NaNs, and then using last row (below)
              rows_with_nans = any(isnan(breg),2);
              breg=breg(~rows_with_nans,:);   % filter out rows with NaNs

            case 'pls'
              %Do PLS on selected samples and predict from that regression vector
              [breg,ssq,xlds,ylds,wts,xscrs] = simpls(localaxoldwt,localayoldwt,options.reglvs,regopts);
              [breg0,ssq,xlds,ylds,wts,xscrs] = simpls(localaxold,localayold,options.reglvs,regopts);
              % calculate Q and Tsq
              Tnew_i = localsxnew*wts;  % use weights instead of loads
              lambda = sum(xscrs.^2)/(npts-1);
              lambdainv = diag(1./lambda);             
              tsqs(i, 1) = NaN;
              ssqresiduals(i, 1) = NaN;   % clear
              tsqs(i, 1) = Tnew_i*lambdainv*Tnew_i';
              x_hat(i,:) = Tnew_i*xlds';
              E(i,:) = localsxnew - x_hat(i,:);  % use the loadings to project for x_hat
              E1 = localsxnew - x_hat(i,:);  % use the loadings to project for x_hat
              ssqresiduals(i, 1) = E1*E1';
              ssqresiduals_var = ssqresiduals_var + E1.^2;
          end
          ypred(i,1) = localsxnewwt*breg(end,:)';   %apply regresion vector to new X
          ypred(i,1) = rescale(ypred(i,1),localmy_adj);   %UNDO weighting on prediceted y
          ypred(i,1) = rescale(ypred(i,1),localmy,localsy);   %UNDO preprocesing on predicted y
          Tnew(i,1) = Tnew_i(1,1);
          yreg = ayoldset;
        end	% end if
        %end otherwise
    end

    yregmin(i) = min(yreg);
    yregmax(i) = max(yreg);
  end
end
if ishandle(hh)
  close(hh)
end
ypred   = rescale(ypred,myold,stdyold);
yregmin = rescale(yregmin, myold, stdyold);
yregmax = rescale(yregmax, myold, stdyold);
for i=1:m
  extrap(i,1) = sum([min([0 ypred(i,1)-yregmin(i)]) max([0 ypred(i,1)-yregmax(i)])]);
end

ssqresiduals = {ssqresiduals(:,1), E; ssqresiduals_var []}; %Use {1,2} for E
tsqs = {tsqs(:,1), []; [] []};

% reuse the input model when model_inout, adding ypred, Q and Tsq.
if strcmp(usecase, 'model_inout')
  %model came in and was applied to new data, copy input model over to
  %outstruct (so we can re-use code below)
  outstruct = model;
end
if ismember(usecase, {'model_out' 'model_inout'})
  if ~isempty(xoldinclx)
    for i=1:m
      if all(nearestpts(i,:))
      nearestpts(i,:) = xoldinclx(nearestpts(i,:));
      else
        for j = 1:size(nearestpts,2)
          if nearestpts(i,j)> 0
            nearestpts(i,j) = xoldinclx(nearestpts(i,j));
          else
            nearestpts(i,j)=0;
          end
        end
      end
    end
  end
  %calculation of new model (no xnew so we used xold as xnew)
  outstruct.loads{1,1}    = Tnew;           %X-block scores   't' (for NEW data)
  outstruct.pred          = {x_hat ypred};    %X_hat and Y_hat (aka ypred)
  outstruct.detail.extrap = extrap;
  outstruct.ssqresiduals  = ssqresiduals;
  outstruct.tsqs          = tsqs;
  outstruct.detail.nearestpts = nearestpts;
  ypred = outstruct;
end


function outstruct = lwrstruct
outstruct = modelstruct('lwrpred');

