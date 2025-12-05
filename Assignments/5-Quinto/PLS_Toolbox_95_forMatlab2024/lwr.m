function varargout = lwr(varargin)
%LWR Locally weighted regression for univariate Y.
%  LWR is a wrapper around lwrpred, supporting a model argument.
%  Predictions are made using a locally weighted
%  regression model defined by the number principal components
%  used to model the independent variables (lvs), and the number
%  of points defined as local (npts). 
%
%  INPUTS: x,y,ncomp,npts,options, model
%        x  = X-block (predictor block) class "double" or "dataset",
%        y  = Y-block (predicted block) class "double" or "dataset", and
%    ncomp  = the number of latent variables to be calculated (positive
%             integer scalar).
%     npts  = the number of points to use in local regression
%  OR:
%        x  = X-block (predictor block) class "double" or "dataset",
%    model  = previously generated model.
%  OR:
%        x  = X-block (predictor block) class "double" or "dataset",
%        y  = Y-block (predicted block) class "double" or "dataset", and
%    model  = previously generated model.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%          display: [ 'off' | {'on'} ]      governs level of display to command window.
%          waitbar: [ 'off' |{'auto'}| 'on' ] governs use of waitbar during
%                     analysis. 'auto' shows waitbar if delay will likely
%                     be longer than a reasonable waiting period.
%            plots: [ 'none' | {'final'} ]  governs level of plotting.
%    preprocessing: {[] []}                 preprocessing structures for x and y blocks
%                                             (see PREPROCESS).
%        algorithm: [ 'globalpcr' | {'pcr'} | 'pls' ] LWR algorithm to use.
%                     Method of regression after samples are selected.
%                     'globalpcr' performs PCR based on the PCs calculated
%                     from the entire calibration data set but a regression
%                     vector calculated from only the selected samples.
%                     'pcr' and 'pls' calculate a local PCR or PLS model
%                     based only on the selected samples.
%     blockdetails: [ {'standard'} | 'all' ]  Extent of detail included in model.
%                     'standard' keeps only y-block, 'all' keeps both x- and y- blocks
%  confidencelimit: [{0.95}] Confidence level for Q and T2 limits. A value
%                     of zero (0) disables calculation of confidence
%                     limits.
%            alpha: [0-1] Weighting of y-distances in selection of local points.
%                     0 = do not consider y-distances {default}, 1 = consider ONLY
%                     y-distances. With any positive alpha, the algorithm will tend to
%                     select samples which are close in both the PC space but which also
%                     have similar y-values. This is accomplished by repeating the
%                     prediction multiple times. In the first iteration, the selection of
%                     samples is done only on the PC space. Subsequent iterations take
%                     into account the comparison between predicted y-value of the new
%                     sample and the measured y-values of the calibration samples.
%             iter: [{5}] Iterations in determining local points. Used only when
%                     alpha > 0 (i.e. when using y-distance scaling).
%           reglvs: [] Used only when algorithm is 'pcr' or 'pls', this is the
%                     number of latent variables/principal components to use in  the
%                     regression model, if different from the number used to select
%                     calibration samples. [] (Empty) implies LWRPRED should use the
%                     same number of latent variables in the regression as were used to
%                     select samples. NOTE: This option is NOT used when algorithm is
%                     'globalpcr'.
%
%  OUTPUT:
%     model = standard model structure containing the LWR model (See MODELSTRUCT).
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%  model.detail.nearestpts  = (nsamples, npts) are indices of the nearest
%                             points used in the local regression model
%                             for each sample prediction.
%
%I/O: model = lwr(x,y,ncomp,npts,options);  %identifies model (calibration step)
%I/O: pred  = lwr(x,model,options);    %makes predictions with a new X-block
%I/O: valid = lwr(x,y,model,options);  %makes predictions with new X- & Y-block
%I/O: updatedmodel = lwr(x,y,model,options);  %update (add x & y to cal).
                                              %Important:(1) options.algorithm == 'update'.
                                              %(2) Original model must contain both x & y blocks (opts.blockdetails == 'all').
%I/O: options = lwr('options');        %returns a default options structure
%I/O: lwr demo                         %runs a demo of the LWR function
%
%See also: LWRPRED, PCR, PLS, POLYPLS

%Copyright Eigenvector Research, Inc. 2009
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%9/2009 Donal

%Start Input
if nargin==0  % LAUNCH GUI
  analysis('lwr')
  return
end
if ischar(varargin{1}) %Help, Demo, Options
  
  options = [];
  lwropts = lwrpred('options');
  options.name          = 'options';
  options.display       = 'on';     %Displays output to the command window
  options.plots         = 'final';  %Governs plots to make
  options.preprocessing = {[] []};  %See preprocess
  options.algorithm     = lwropts.algorithm;    %globalpcr algorithm
  options.blockdetails  = 'standard';  %level of details
  options.confidencelimit = 0.95;
  options.alpha         = 0;
  options.iter          = 5;
  options.reglvs        = [];
  options.waitbar       = 'auto';
  options.definitions   = @optiondefs;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
  
end

if nargin<2
  error([ upper(mfilename) ' requires 2 inputs.'])
end

%A) Check Options Input
%   options.algorithm     = 'globalpcr';  %globalpcr algorithm  %'globalpcr' | 'pcr' | 'pls'
% Convert each case to the 5-arg form:   [x, y, ncomp, npts, opts],
% or, if model input, to the 6-arg form: [x, [], ncomp, npts, opts, model]
%
% Possible calls:
% 2 inputs: (x,model)
% 3 inputs: (x,model,options)   case A
%           (x,y,ncomp)         case B: no npts
%           (x,y,model)         case C 
% 4 inputs: (x,y,ncomp,npts)    case A
%           (x,y,ncomp,options) case B: no npts
%           (x,y,model,options) case C
%           (addcalx,addcaly,model,options) case D
% 5 inputs: (x,y,ncomp,npts,options)
switch nargin
  case 2  %two inputs (x, model)
    % (x,model): convert to (x, model, options)
    if ismodel(varargin{2})
      [x,y,ncomp,npts,options,model] = deal(varargin{1},[],[],[],[],varargin{2});
    else
      error(['lwr called with two arguments expects second to be a model.']);
    end
    
  case 3  %three inputs
    % Case A: (x,model,options)
    % Case B: (x,y, ncomp)    -no npts
    % Case C: (x,y,model)
    if  ismodel(varargin{3})
      % Must be case C: (x,y,model)
      [x,y,ncomp,npts,options,model] = deal(varargin{1:2},[],[],[],varargin{3});
      options = model.detail.options;
    elseif isstruct(varargin{3}) & ismodel(varargin{2})
      % Must be case A: (x,model,options)
      [x,y,ncomp,npts,options,model] = deal(varargin{1},[],[],[],varargin{3},varargin{2});
    elseif isnumeric(varargin{3})
      % Must be case B: (x,y, ncomp)
      [x,y,ncomp,npts,options,model] = deal(varargin{1:3},[],[],[]);
    else
      error(['Input arguments not recognized.'])
    end
    
  case 4   %four inputs
    % 4 inputs: (x,y,ncomp,npts)    case A
    %           (x,y,ncomp,options) case B: no npts
    %           (x,y,model,options) case C
    %Case A: (x,y,ncomp,npts)
    if(isnumeric(varargin{4}))
      % Must be case A: (x,y,ncomp,npts)
      [x,y,ncomp,npts,options,model] = deal(varargin{1:4},[],[]);
    elseif  isa(varargin{4},'struct')
      if ~ismodel(varargin{3})
        % Must be case B: (x,y,ncomp,options)
        [x,y,ncomp,npts,options,model] = deal(varargin{1:3},[],varargin{4},[]);
      else
        % Must be case C: (x,y,model,options)
        [x,y,ncomp,npts,options,model] = deal(varargin{1:2},[],[],varargin{4},varargin{3});
        if isstruct(varargin{4}) & isfield(varargin{4},'algorithm') & strcmp(lower(varargin{4}.algorithm),'update')
          % It is actually case D: (addcalx,addcaly,model,options)
          if strcmp(lower(model.detail.options.blockdetails),'standard')
            error('Model update incompatible with a ''standard'' compressed model. Recaluclate the model with options.blockdetails set to ''all''.');
          else
            x = [model.detail.data{1,1}.data ; x]; %Augment original x block
            y = [model.detail.data{1,2}.data ; y]; %Augment original y block
            ncomp = model.detail.lvs; % Forward original ncomps & npts.
            npts = model.detail.npts;
            options.algorithm = model.options.algorithm;
            warning('original ncomps & npts used. Review results to ensure they are appropriate for updated model.')
            options.blockdetails = 'all'; % Disabled compression for reason of above warning.
            model = []; % Clear the old model.
          end
        end
      end
    end
    %
  case 5  %five inputs
    % (x,y,ncomp,npts,options)
    [x,y,ncomp,npts,options,model] = deal(varargin{1:5},[]);
  otherwise
    error(['Input arguments not recognized.'])
    
end

options = reconopts(options,lwr('options'));

%Check for valid algorithm.
if ~ismember(options.algorithm,{'globalpcr', 'pcr', 'pls'})
  error(['Algorithm [' options.algorithm '] not recognized. LWR supports ''globalpcr'', ''pcr'', or ''pls''.'])
end

options.blockdetails = lower(options.blockdetails);
switch options.blockdetails
  case {'standard','all'};
  otherwise
    error(['OPTIONS.BLOCKDETAILS not recognized.'])
end

%B) check model format
if ismodel(model);
  try
    model = updatemod(model);        %make sure it's v3.0 model
  catch
    error(['Input MODEL not recognized.'])
  end
  ncomp = model.detail.lvs;   %get ncomp from model (if needed)
  npts = model.detail.npts;   % get lvs and npts from model
  predictmode = 1;
else
  %NOT a model (none passed)
  predictmode = 0;
end
        
%C) CHECK Data Inputs
[datasource{1:2}] = getdatasource(x,y);
if isa(x,'double')      %convert x and y to DataSets
  x        = dataset(x);
  x.name   = inputname(1);
  x.author = 'LWR';
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
    y.author = 'LWR';
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
  if length(y.include{2})>1
    error('LWR cannot operate on multivariate y. Choose a single column to operate on.')
  end
else    %empty y = NOT haveyblock mode (predict ONLY)
  haveyblock = 0;
end

%D) Check Meta-Parameters Input
if isempty(ncomp) | prod(size(ncomp))>1 | ncomp<1 | ncomp~=fix(ncomp);
  error('Number of components must be integer scalar.')
end
if isempty(npts) | prod(size(npts))>1 | npts<1 | npts~=fix(npts);
  error('Number of points must be integer scalar.')
end

%----------------------------------------------------------------------------------------

if isempty(options.preprocessing);
  options.preprocessing = {[] []};  %reinterpet as empty for both blocks
end
if ~isa(options.preprocessing,'cell')
  options.preprocessing = {options.preprocessing};
end
if length(options.preprocessing)==1;
  options.preprocessing = options.preprocessing([1 1]);   % Why is this overwriting options.preprocessing? 
  % ANSWER: because it is handling a special case where user passed only X preprocessing. This expands it to two for X and Y (same for both).
end

preprocessing = options.preprocessing;

if ~predictmode %| options.outputversion==2;
  
  if mdcheck(x);
    if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess". Results may be affected by this action.'); end
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
  
  % preprocessing contains the x and y values
  
  %Call LWR Function
  % Set options specific to lwrpred.
  options_lwrpred           = options;
  options_lwrpred.plots     = 'none';
  options_lwrpred.display   = 'off';
  options_lwrpred.preprocessing = {0,0};
  % Look in preprocessing{1} and preprocessing{2} for last applied method and base  
  % options_lwrpred.preprocessing on what is there. Mean centering = 1, autoscale = 2, none = 0
  if ~isempty(preprocessing)
    [xprepro, yprepro] = getLastPreProcessing(preprocessing);
    options_lwrpred.preprocessing = {xprepro, yprepro};
  end
  model = lwrpred(xpp,ypp,ncomp, npts,options_lwrpred);
  
  model.detail.data = {x y};
  model = copydsfields(x,model,[],{1 1});
  model = copydsfields(y,model,[],{1 2});
  model.detail.includ{1,2} = x.include{1};   %x-includ samples for y samples too
  model.datasource = datasource;
  model.detail.globalmodel.preprocessing = model.detail.preprocessing;
  model.detail.preprocessing = preprocessing;   %copy calibrated preprocessing info into model
  model.modeltype = 'LWR';

  %create SSQ table
  dof    = size(model.detail.globalmodel.u,1)-1;
  eigs   = sum(model.detail.globalmodel.u.^2,1)./dof;
  ssqtot = sum(sum(model.detail.globalmodel.axold.^2,1))./dof;
  vc     = eigs'./ssqtot'*100;
  model.detail.ssq = [[1:ncomp]' vc cumsum(vc) nan*ones(ncomp,2)];
  
  %Set time and date.
  model.date = date;
  model.time = clock;
  %copy options into model only if no model passed in
  model.detail.options = options;   
  
  %calculate residual eigenvalues using raw residuals matrix
  model.detail.res{1} = model.ssqresiduals{1,2};    % X residuals from the local models
  if options.confidencelimit>0
    [model.detail.reslim{1,1}, model.detail.reseig] = residuallimit(model.detail.res{1}(model.detail.includ{1,1},:), options.confidencelimit);
  else
    model.detail.reslim{1,1} = 0;
  end
  
  % Tsqlim
  if options.confidencelimit>0
    model.detail.tsqlim{1,1} = tsqlim(length(model.detail.includ{1,1}),ncomp,options.confidencelimit*100);
  else
    model.detail.tsqlim{1,1} = 0;
  end
  
else    % have model, do predict
  originalmodel = model;
  if ~strcmpi(model.modeltype,'lwr')
    if strcmpi(model.modeltype,'lwrpred'); %%% need to modify
      model.modeltype = 'LWR';
    else
      error('Input MODEL is not a LWR model');
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
    if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess" from existing model. Results may be affected by this action.'); end
    x = replacevars(model,x);
  end
  
  preprocessing = model.detail.preprocessing;   %get preprocessing from model
  options.algorithm     = model.detail.options.algorithm;   %get algorithm from model
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
  
  %copy info
  model = copydsfields(x,model,1,{1 1});
  model.detail.includ{1,2} = x.include{1};   %x-includ samples for y samples too
  model.datasource = datasource;
  
  %Update time and date.
  model.date = date;
  model.time = clock;

  %make predictions for new samples
  switch lower(options.algorithm)
    case {'globalpcr','','pcr','pls'}
      lwrp_opts = lwrpred('options');
      lwrp_opts.algorithm       = model.detail.options.algorithm;
      lwrp_opts.reglvs          = model.detail.options.reglvs;
      lwrp_opts.preprocessing   = model.detail.globalmodel.preprocessing;
      lwrp_opts.display         = 'off';
      lwrp_opts.structureoutput = true; % lwr will always output a model structure
      lwrp_opts.alpha           = model.detail.options.alpha;
      lwrp_opts.iter            = model.detail.options.iter;
      lwrp_opts.waitbar         = model.detail.options.waitbar;
      ypred = lwrpred(xpp, model, lwrp_opts);    % call engine to get ypred
    otherwise
      error(['Input options.algorithm argument not recognized, = ''' options.algorithm ''''])
  end
  %and copy over values
  model.detail.data   = {x y};
  model.loads{1,1}    = ypred.loads{1,1};
  model.pred          = ypred.pred;
  model.ssqresiduals  = ypred.ssqresiduals;
  model.tsqs          = ypred.tsqs;
  model.detail.extrap = ypred.detail.extrap;
  model.detail.nearestpts = ypred.detail.nearestpts;
  model.detail.res{1} = xpp.data(:,model.detail.includ{2,1})-model.loads{1,1}*model.loads{2,1}';

end   % end if ~predict

%handle y predictions  
% model.pred{2} is in unprocessed form
% but calcystats expects its fourth arg, ypredpp, to be preprocessed.
ypredpp = model.pred{2};
model.pred{2} = preprocess('undo',model.detail.preprocessing{2},model.pred{2});
model.pred{2} = model.pred{1,2}.data;
model = calcystats(model,predictmode,ypp,ypredpp);
if ~predictmode
  %add info to ssq table's y-columns
  model.detail.ssq(end,4:5) = [nan nan];
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
        plotloads(model);
        plotscores(model);
      else
        plotscores(originalmodel,model);
      end
    catch
      warning('EVRI:PlottingError',lasterr)
    end
end

%End Input

%-----------------------------------------------------------------------
function [xprepro, yprepro] = getLastPreProcessing(preprocessing)
% Look for last preprocessing applied to both the X and Y blocks.
% If it is one of 'autoscale', 'meancenter', or 'none'
% then return 2, 1, or 0 accordingly
xprepro = 0;
yprepro = 0;
if ~isempty(preprocessing)
  if ~isempty(preprocessing{1})
    xp = preprocessing{1}(end); % is the last X-block preprocessing structure
    if strcmpi(xp.keyword, 'autoscale'); xprepro = 2; end;
    if strcmpi(xp.keyword, 'meancenter'); xprepro = 1; end;
  end
  if ~isempty(preprocessing{2})
    yp = preprocessing{2}(end); % is the last Y-block preprocessing structure
    if strcmpi(yp.keyword, 'autoscale'); yprepro = 2; end;
    if strcmpi(yp.keyword, 'meancenter'); yprepro = 1; end;
  end
end
  
%-----------------------------------------------------------------------
%CHECK descriptions etc
% %Functions
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                            userlevel       description
'display'                'Display'        'select'        {'on' 'off'}                     'novice'        'Governs level of display.';
'plots'                  'Display'        'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
'preprocessing'          'Standard'       'cell(vector)'  ''                               'novice'        'Preprocessing structures. Cell 1 is preprocessing for X block, Cell 2 is preprocessing for Y block.';
'algorithm'              'Standard'       'select'        {'globalpcr' 'pcr' 'pls'}        'novice'        '[ ''globalpcr'' | {''pcr''} | ''pls'' ] LWR algorithm to use. Method of regression after samples are selected. ''globalpcr'' performs PCR based on the PCs calculated from the entire calibration data set but a regression vector calculated from only the selected samples. ''pcr'' and ''pls'' calculate a local PCR or PLS model based only on the selected samples.';
'blockdetails'           'Standard'       'select'        {'standard' 'all'}               'novice'        'Extent of predictions and raw residuals included in model. ''standard'' = keeps only y-block, ''all'' keeps both x- and y- blocks.';
'confidencelimit'        'Standard'       'double'        'float(0:1)'                     'novice'        'Confidence level for Q and T2 limits (fraction between 0 and 1)';
'alpha'                  'Standard'       'double'        'float(0:1)'                     'novice'        'Weighting of y-distances in selection of local points. 0 = do not consider y-distances {default}, 1 = consider ONLY y-distances. With any positive alpha, the algorithm will tend to select samples which are close in both the PC space but which also have similar y-values. This is accomplished by repeating the prediction multiple times. In the first iteration, the selection of samples is done only on the PC space. Subsequent iterations take into account the comparison between predicted y-value of the new sample and the measured y-values of the calibration samples.';
'iter'                   'Standard'       'double'        'int(1:inf)'                     'novice'        'Iterations in determining local points. Used only when alpha > 0 (i.e. when using y-distance scaling).';
'reglvs'                 'Standard'       'double'        'int(1:inf)'                     'novice'        'Used only when algorithm is ''pcr'' or ''pls'', this is the number of latent variables/principal components to use in  the regression model, if different from the number used to select calibration samples. [] (Empty) implies LWRPRED should use the same number of latent variables in the regression as were used to select samples. NOTE: This option is NOT used when algorithm is ''globalpcr''.';
};

out = makesubops(defs);
