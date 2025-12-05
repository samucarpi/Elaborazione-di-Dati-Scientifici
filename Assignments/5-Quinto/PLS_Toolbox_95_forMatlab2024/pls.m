function varargout = pls(varargin)
%PLS Partial least squares regression for multivariate Y.
%  PLS is a multivariate inverse least squares regession method used
%  to identify models of the form Xb = y + e.
%
%  INPUTS:
%        x  = X-block (predictor block) class "double" or "dataset",
%        y  = Y-block (predicted block) class "double" or "dataset", and
%    ncomp  = the number of latent variables to be calculated (positive integer scalar).
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%          display: [ 'off' | {'on'} ]      governs level of display to command window.
%            plots: [ 'none' | {'final'} ]  governs level of plotting.
%    outputversion: [ 2 | {3} ]             governs output format.
%    preprocessing: {[] []}                 preprocessing structures for x and y blocks
%                                             (see PREPROCESS).
%        algorithm: [ 'nip' | {'sim'} | 'dspls' | 'robustpls' ]
%                    PLS algorithm to use: NIPALS, SIMPLS, Direct Scores,
%                    or robust PLS (with automatic outlier detection).
%    orthogonalize: [ {'off'} | 'on' ] Orthogonalize model to condense
%                    y-block variance into first latent variable; 'on' =
%                    produce orthogonalized model. Regression vector and
%                    predictions are NOT changed by this option. Only the
%                    loadings, weights, and scores.
%     blockdetails: [ {'standard'} | 'all' ]  Extent of detail included in model.
%                     'standard' keeps only y-block, 'all' keeps both x- and y- blocks
%  confidencelimit: [{0.95}] Confidence level for Q and T2 limits. A value
%                     of zero (0) disables calculation of confidence limits.
%          weights: [ {'none'} | 'hist' | 'custom' ]  governs sample
%                     weighting. 'none' does no weighting. 'hist' performs
%                     histogram weighting in which large numbers of samples
%                     at individual y-values are down-weighted relative to
%                     small numbers of samples at other values. 'custom'
%                     uses the weighting specified in the weightsvect
%                     option.
%      weightsvect: [ ] Used only with custom weights. The vector specified
%                     must be equal in length to the number of samples in
%                     the y block and each element is used as a weight for
%                     the corresponding sample. If empty, no sample
%                     weighting is done.
%         roptions: structure of options to pass to rsimpls (robust PLS engine from the Libra
%                    Toolbox).
%                alpha: (1-alpha) measures the number of outliers the
%                       algorithm should resist. Any value between 0.5 and 1 may
%                       be specified (default = 0.75). These options are
%                       only used when algorithm is robust PCA.
%                kmax:  {19} maximum number of latent variables allowed
%                       with robust PLS models.
%
%  OUTPUT:
%     model = standard model structure containing the PLS model (See MODELSTRUCT).
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: model = pls(x,y,ncomp,options);  %identifies model (calibration step)
%I/O: pred  = pls(x,model,options);    %makes predictions with a new X-block
%I/O: valid = pls(x,y,model,options);  %makes predictions with new X- & Y-block
%
%See also: ANALYSIS, CROSSVAL, MODELSTRUCT, NIPPLS, PCR, PLSDA, PREPROCESS, RIDGE, SIMPLS

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified NBG 4/96,9/96,12/97
%BMW Checked on MATLAB 5
%Modified BMW 12/98  added rank check
%NBG 12/01 (modified for version 3)
%JMS 2/12/02 -added new rank check method, inside decomp loop
% -added undocumented full-model output/input options
% -sped up plsregression loop
% -consolidated SIMPLS and NIPALS code
%JMS 3/4/02 -added test for zero norm when shifting variance for SIM output
% -added test for non-finite values to give interpretable error during on-the-fly rank tests
%JMS 3/6/02 -added test for empty preprocessing (speeds up calls if we don't have to call preprocess)
%  -generalized error messages and behavior
%JMS 3/13/02 -allow full model as 4th input to do prediction
%jms 3/20/02 -include options in model output
%  -use copydsfields
%jms 3/24/03 number of components in model from LOADS not SCORES
%jms 5/21/03 calculate RMSEC from only included samples
%jms 4/28/04 fix orientation of T^2 for variables
%rsk 05/24/04 fix bug set include fields in y to those of model in test mode.
%jms 5/26/05 allow other types of preprocessing options (e.g. strings)
%jms 8/15/05 fix T^2 bug on apply (not calculating for new data)
%rsk 12/05/05 add robust pcr.

%Old I/O:
%[b,ssq,p,q,w,t,u,bin] = pls(x,y,maxlv,out);
%   Inputs:
%        x = the scaled predictor block,
%        y = the scaled predictand block,
%    maxlv = the number of latent variables to be calculated, and
%      out = optional input to control plotting:
%        out = 1 plots the model results {default}, and
%        out = 0 suppresses plotting and outputting.
%   Outputs:
%        b = the matrix of regression vectors or matrices,
%      ssq = the fraction of variance used in the x and y,
%        p = x loadings,
%        q = y loadings,
%        w = x weights,
%        t = x scores,
%        u = y scores, and
%      bin = inner relation coefficients.
%   Note: The regression matrices are ordered in b such that each
%   ny (number of y variables) rows correspond to the regression
%   matrix for that particular number of latent variables.

%Start Input
if nargin==0  % LAUNCH GUI
  analysis('pls')
  return
end

if ischar(varargin{1}) %Help, Demo, Options
  
  options = [];
  options.name          = 'options';
  options.display       = 'on';     %Displays output to the command window
  options.plots         = 'final';  %Governs plots to make
  options.outputversion = 3;        %2,3 Tells what to output (3=ModelStruct)
  options.preprocessing = {[] []};  %See preprocess
  options.algorithm     = 'sim';    %SIMPLS algorithm
  options.weights       = 'none';
  options.weightsvect   = [];
  options.orthogonalize = 'off';
  options.blockdetails  = 'standard';  %level of details
  options.confidencelimit = 0.95;
  options.roptions.alpha = 0.75; %Alpha for robust methods between 0.5 and 1.
  options.roptions.kmax  = 19;  %max # of LVs in robust mode
  options.definitions   = @optiondefs;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

if nargin<2
  error([ upper(mfilename) ' requires 2 inputs.'])
end

%A) Check Options Input
predictmode = 0;    %default is calibrate mode

%options if we interpret as an old call
v2options.display       = 'on';         %Displays output to the command window
v2options.plots         = 'none';      %Governs plots to make
v2options.outputversion = 2;            %2,3 Tells what to output (2=[b,ssq,t,p,eigs])
v2options.preprocessing = {[] []};      %See preprocess
v2options.algorithm     = 'nip';        %NIPALS algorithm
v2options.blockdetails  = 'standard';  %level of details

switch nargin
  case 2  %two inputs
    %v3 : (x,model)
    if ismodel(varargin{2})
      varargin = {varargin{1},[],[],pls('options'),varargin{2}};
    else
      error(['Input number of components (NCOMP) is missing.']);
    end
    
  case 3  %three inputs
    %v3/v2 : (x,y,ncomp)
    %v3    : (x,y,options) ??? (invalid, need ncomp)
    %v3    : (x,model,options)
    %v3    : (x,y,model)
    
    if isnumeric(varargin{3});
      %v3/v2 : (x,y,ncomp)
      if nargout > 1;
        varargin{4} = v2options;      %multiple outputs = V2 call
      else
        varargin{4} = pls('options');
      end
    elseif ismodel(varargin{2});
      %v3 : (x,model,options)
      varargin = {varargin{1},[],[],varargin{3},varargin{2}};
    elseif ~ismodel(varargin{3});
      %v3 : (x,y,options) ???
      error(['Input number of components (NCOMP) is missing.']);
    else
      %v3 : (x,y,model)
      varargin{5} = varargin{3};                    %check model format later
      varargin{4} = pls('options');                 %get default options
      varargin{3} = [];                             %get ncomp from model
    end
    
  case 4   %four inputs
    %v2 : (x,y,ncomp,out)
    %v3 : (x,y,model,options)
    %v3 : (x,y,ncomp,model)
    %v3 : (x,y,ncomp,options)
    
    if isnumeric(varargin{4});
      %v2 : (x,y,ncomp,out)
      switch varargin{4}
        case 0
          v2options.display       = 'off';         %Displays output to the command window
          varargin{4} = v2options;
        case 1
          varargin{4} = v2options;
        otherwise
          error(['Input OPTIONS or MODEL not recognized.'])
      end
      
    elseif ismodel(varargin{3});
      %v3 : (x,y,model,options)
      varargin{5} = varargin{3};
      varargin{3} = [];
      
    elseif ismodel(varargin{4})
      %v3 : (x,y,ncomp,model)
      varargin{5} = varargin{4};
      varargin{4} = pls('options');   %default options
      
    else
      %v3 : (x,y,ncomp,options)
    end
    
  case 5  %five inputs
    %v3 : (x,y,ncomp,model,options)
    %v3 : (x,y,ncomp,options,model)  (technically invalid but we'll accept it anyway)
    if ismodel(varargin{4});
      varargin([4 5]) = varargin([5 4]);  %swap options and model so model is #5
    end
    
end

options = reconopts(varargin{4},mfilename,{'classset','priorprob','rawmodel','strictthreshold'});

%Check for valid algorithm.
if ~ismember(options.algorithm,{'nip' 'sim' 'dspls' 'robustpls' 'polypls'})
  error(['Algorithm [' options.algorithm '] not recognized. PLS supports ''nip'', ''sim'', ''dspls'', or ''robustpls''.'])
  return
end
switch options.outputversion
  case{2,3}
    %Take no action these are ok inputs
  otherwise
    options.outputversion = 3;
    if (strcmp(lower(options.display),'on')|options.display==1)
      warning('EVRI:Outputversion','OPTIONS.OUTPUTVERSION not recognized. Reset to 3.')
    end
end
options.blockdetails = lower(options.blockdetails);
switch options.blockdetails
  case {'compact','standard','all'};
  otherwise
    error(['OPTIONS.BLOCKDETAILS not recognized.'])
end
if ~isfield(options,'rawmodel');
  options.rawmodel = 0;       %undocumented option to output raw results ONLY
end

%B) check model format
if length(varargin)>=5;
  try
    varargin{5} = updatemod(varargin{5});        %make sure it's v3.0 model
  catch
    error(['Input MODEL not recognized.'])
  end
  if options.rawmodel & strcmp(options.algorithm,'robustpls')
    %robustpls doesn't work with rawmodel - force us to recalculate the
    %model at the requested number of LVs
    varargin = varargin([1:4 6:end]);
    options.rawmodel = 0;
    predictmode      = 0;
  else
    %got here with a model, do predict mode
    predictmode = 1;                                  %and set predict mode flag
    if isempty(varargin{3});
      varargin{3} = size(varargin{5}.loads{2,1},2);   %get ncomp from model (if needed)
    end
  end
  if ~isfield(varargin{5}.detail.options, 'orthogonalize')
    % handle old models which do not have the orthogonalize field
    varargin{5}.detail.options.orthogonalize='off';
  end
end

%C) CHECK Data Inputs
[datasource{1:2}] = getdatasource(varargin{1:2});
if isa(varargin{1},'double')      %convert varargin{1} and varargin{2} to DataSets
  varargin{1}        = dataset(varargin{1});
  varargin{1}.name   = inputname(1);
  varargin{1}.author = 'PLS';
elseif ~isa(varargin{1},'dataset')
  error(['Input X must be class ''double'' or ''dataset''.'])
end
if ndims(varargin{1}.data)>2
  error(['Input X must contain a 2-way array. Input has ',int2str(ndims(varargin{1}.data)),' modes.'])
end

if ~isempty(varargin{2});
  haveyblock = 1;
  if isa(varargin{2},'double') | isa(varargin{2},'logical')
    varargin{2}        = dataset(varargin{2});
    varargin{2}.name   = inputname(2);
    varargin{2}.author = 'PLS';
  elseif ~isa(varargin{2},'dataset')
    error(['Input Y must be class ''double'', ''logical'' or ''dataset''.'])
  end
  
  if isa(varargin{2}.data,'logical');
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
    if (strcmp(lower(options.display),'on')|options.display==1)
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

%D) Check Meta-Parameters Input
ncomp = varargin{3};
if isempty(ncomp) | prod(size(ncomp))>1 | ncomp<1 | ncomp~=fix(ncomp);
  error('Input NCOMP must be integer scalar.')
end
if ~options.rawmodel & predictmode & ncomp~=size(varargin{5}.loads{2,1},2);
  error('Cannot use a different number of components (NCOMP) with previously created model');
end

%----------------------------------------------------------------------------------------
x = varargin{1};
y = varargin{2};

if isempty(options.preprocessing);
  options.preprocessing = {[] []};  %reinterpet as empty for both blocks
end
if ~isa(options.preprocessing,'cell')
  options.preprocessing = {options.preprocessing};
end
if length(options.preprocessing)==1;
  options.preprocessing = options.preprocessing([1 1]);
end

preprocessing = options.preprocessing;

if ~predictmode | options.outputversion==2;
  
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
  
  %Call PLS Function
  model = plsregression(xpp,ypp,ncomp,options);
  if strcmp(options.algorithm,'robustpls')
    %Scale step, correct for Robust centering of model. Add to options and model.detail.prepro.
    rmeans = model.detail.robustpls.robpca.M;
    rmeans = rmeans(1:size(model.loads{2,1},1));
    xpp.data(:,xpp.include{2}) = scale(xpp.data(:,xpp.include{2}), rmeans);
    %Add a prepro step to account for what Robust method does.
    robpp = preprocess('default','mean center');
    robpp.description = 'Mean Center';
    robpp.tooltip = 'Remove robustly calculated offset from each variable.';
    robpp.keyword = 'Mean Center';
    robpp.calibrate = {'%Values calculated by robpls.'};
    robpp.out = {rmeans};
    preprocessing{1} = [preprocessing{1} robpp];
    model.detail.preprocessing{1} = [model.detail.preprocessing{1} robpp];
    %Handle Y block.
    ycor = model.detail.robustpls.int+(rmeans*model.detail.robustpls.slope); %y-intercept includes correction for regression vector which is relative to un-robust-centered data
    robppy = robpp;
    robppy.out = {ycor};
    ypp.data(:,ypp.include{2}) = scale(ypp.data(:,ypp.include{2}), ycor);
    preprocessing{2} = [preprocessing{2} robppy];
    model.detail.preprocessing{2} = [model.detail.preprocessing{2} robppy];
    
    %copy used samples into includ fields
    model.detail.includ{1,1} = xpp.include{1}(find(model.detail.robustpls.flag));
    model.detail.includ{1,1} = model.detail.includ{1,1}(:)';
    model.detail.includ{1,2} = model.detail.includ{1,1};
    
    %create classes for "flagged" (excluded outliers)
    flagged = ones(1,size(xpp,1)).*2;
    flagged(xpp.include{1}) = 0;
    flagged(xpp.include{1}(find(~model.detail.robustpls.flag))) = 1;
    j = 1;
    while j<=size(model.detail.class,3);
      if isempty(model.detail.class{1,1,j});
        break;
      end
      j = j+1;
    end
    model.detail.class{1,1,j} = flagged;  %store classes there
    model.detail.classname{1,1,j} = 'Outlier Status';
    
  end
  
  model.datasource = datasource;
  model.detail.preprocessing = preprocessing;   %copy calibrated preprocessing info into model
  
else    %5 inputs with outputversion of 3 implies that input #5 is a raw model previously output, don't decompose/regress
  
  model = varargin{5};
  if ~strcmpi(model.modeltype,'pls') & ~strcmpi(model.modeltype,'plsda');
    error('Input MODEL is not a PLS model');
  end
  
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
  
  preprocessing         = model.detail.preprocessing;   %get preprocessing from model
  options.algorithm     = model.detail.options.algorithm;   %get algorithm from model
  options.orthogonalize = model.detail.options.orthogonalize;  %get orthogonalize flag from model
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
  
  if ~options.rawmodel
    model = copydsfields(x,model,1,{1 1});
    model.detail.includ{1,2} = x.include{1};   %x-includ samples for y samples too
    model.datasource = datasource;
  end
  
  %Update time and date.
  model.date = date;
  model.time = clock;
  
end

%copy options into model
model.detail.options = options;

switch options.outputversion
  case 2
    switch lower(options.algorithm)
      case 'nip'
        varargout{1} = model.reg;         % b    (matrix)
        varargout{2} = model.detail.ssq;  % ssq
        varargout{3} = model.loads{2,1};  % p
        varargout{4} = model.loads{2,2};  % q
        varargout{5} = model.wts;         % w
        varargout{6} = model.loads{1,1};  % t
        varargout{7} = model.loads{1,2};  % u
        varargout{8} = model.detail.bin;  % bin
      case {'sim' 'dspls'}
        
        for ii=1:size(model.loads{2,1},2)   %shift variance back to loads for backwards compatability
          mynorm = norm(model.loads{1,1}(:,ii));
          if mynorm > 0;
            model.loads{2,1}(:,ii) = model.loads{2,1}(:,ii)*mynorm;
            model.loads{1,1}(:,ii) = model.loads{1,1}(:,ii)/mynorm;
          end
        end
        
        varargout{1} = model.reg;           % b    (matrix)
        varargout{2} = model.detail.ssq;    % ssq
        varargout{3} = model.loads{2,1};    % p
        varargout{4} = model.loads{2,2};    % q
        varargout{5} = model.wts;           % r
        varargout{6} = model.loads{1,1};    % t
        varargout{7} = model.loads{1,2};    % u
        varargout{8} = model.detail.basis;  % v
    end
    switch options.display
      case {'on', 1}
        ssqtable(model.detail.ssq)
    end
    return;
end

if options.rawmodel & ~predictmode;
  varargout{1} = model;   %pass raw model info out as output
  return;
end

if options.rawmodel & predictmode; predictmode = 0; end
%rawmodel here means that this is really just a normal "reduce raw model" call, do NOT treat as predictmode

%fill in for all mode 1 sample values (in addition to the .includ field)
%calculate tsqs, residuals, scores for non-included samples.

if ~predictmode;
  %reduce to # of LVs requested (or maxrank of scores)
  maxrank = rank(model.loads{1,1});
  if maxrank < ncomp;
    if (strcmp(lower(options.display),'on')|options.display==1)
      warning('EVRI:PlsNcompLimit','Number of components requested can''t be calculated due to insufficient rank. Dropping to maximum rank.');
    end
    if maxrank==0
      error('Data is apparently rank zero (no variance). Check data scale and included samples/variables.')
    end
    ncomp = maxrank;
  end
  
  ny                    = length(ypp.include{2,1});
  model.reg             = model.reg([1:ny]+(ny*(ncomp-1)),:)';
  model.wts             = model.wts(:,1:min(end,ncomp));
  for j=1:prod(size(model.loads));
    model.loads{j}      = model.loads{j}(:,1:min(end,ncomp));
  end
  if ~options.rawmodel
    model.detail.ssq    = model.detail.ssq(1:ncomp,:);
  end
end


%X-Block Statistics
switch lower(options.algorithm)
  case {'sim','nip','dspls','robustpls'}
    if ~strcmp(options.orthogonalize,'on') | size(model.wts,2)==1
      %standard non-orthogonalized model (or only one component)
      model.loads{1,1}      = xpp.data(:,model.detail.includ{2,1})*model.wts;
    else
      %orthogonalize model
      if ~predictmode
        model = orthogonalizepls(model,xpp.data(:,model.detail.includ{2,1}),ypp.data(:,model.detail.includ{2,2}));
      else
        model = orthogonalizepls(model,xpp.data(:,model.detail.includ{2,1}));
      end
    end
  case {'polypls'}
    model.loads{1,1} = [];
    temp = xpp.data(:,model.detail.includ{2,1});
    for i = 1:size(model.wts,2);
      model.loads{1,1}(:,i) = temp*model.wts(:,i);
      temp = temp - model.loads{1,1}(:,i)*model.loads{2,1}(:,i)';
    end
end

model.detail.data{1}  = x;
model.pred{1}         = model.loads{1,1}*model.loads{2,1}';
model.detail.res{1}   = xpp.data(:,model.detail.includ{2,1}) - model.pred{1};
model.ssqresiduals{1,1} = model.detail.res{1}.^2;
model.ssqresiduals{2,1} = sum(model.ssqresiduals{1,1}(model.detail.includ{1,1},:),1); %based on cal samples only
model.ssqresiduals{1,1} = sum(model.ssqresiduals{1,1},2); %residuals for ALL samples
if ~predictmode;
  if options.confidencelimit>0
    [model.detail.reslim{1,1}, model.detail.reseig] = residuallimit(model.detail.res{1}(model.detail.includ{1,1},:), options.confidencelimit);
  else
    model.detail.reslim{1,1} = 0;
  end
end

if ~predictmode;
  origmodel = model;
else
  origmodel = varargin{5};   %get pointer to original model
end
incl    = origmodel.detail.includ{1,1};
m       = length(incl);
P       = origmodel.loads{2,1};

if isempty(origmodel.detail.eig)
  %if no values are in the eig field, calculate them now
  T_cal   = origmodel.loads{1,1}(incl,:);
  origmodel.detail.eig = diag(T_cal'*T_cal)/(m-1);
  model.detail.eig = origmodel.detail.eig;
end
f       = diag(sqrt(1./origmodel.detail.eig));

predT   = model.loads{1,1};
if ncomp > 1
  tsq1    = sum((f*predT').^2)';
  tsq2    = sum((f*P').^2)';
else
  tsq1    = ((f*predT').^2)';
  tsq2    = ((f*P').^2)';
end
model.detail.leverage = tsq1/(m-1);
model.tsqs{1,1} = tsq1;
model.tsqs{2,1} = tsq2;

if ~predictmode;
  if options.confidencelimit>0
    model.detail.tsqlim{1,1} = tsqlim(length(model.detail.includ{1,1}),ncomp,options.confidencelimit*100);
  else
    model.detail.tsqlim{1,1} = 0;
  end
else
  model.tsqs(:,2) = {[];[]};
end

if ~predictmode & ~strcmpi(options.algorithm,'polypls')
  model.detail.selratio = sratio(xpp,model,struct('preprocessed',true));
end

%Y-Block Statistics
if ~predictmode | haveyblock;
  incl1 = model.detail.includ{1,2};
  model.loads{1,2}      = zeros(size(ypp.data,1),ncomp);
  f                     = ypp.data(:,model.detail.includ{2,2});
  model.loads{1,2}(:,1) = f*model.loads{2,2}(:,1);
  nrmscrs = normaliz((model.loads{1,1}(incl1,:))')';   % only use includes
  for ii=2:ncomp
    switch lower(options.algorithm)
      case 'nip'
        f                      = f - model.detail.bin(1,ii-1)*model.loads{1,1}(:,ii-1)*model.loads{2,2}(:,ii-1)';
        model.loads{1,2}(:,ii) = f*model.loads{2,2}(:,ii);
      otherwise
        model.loads{1,2}(:,ii) = f*model.loads{2,2}(:,ii);
        model.loads{1,2}(incl1,ii) = model.loads{1,2}(incl1,ii) ...
          - nrmscrs(:,1:ii-1)*(model.loads{1,2}(incl1,ii)'*nrmscrs(:,1:ii-1))';
    end
  end
  clear f ii
else
  model.loads{1,2} = [];
end

%store original and predicted Y values
model.detail.data{1,2}   = y;
switch lower(options.algorithm)
  case {'sim','dspls','nip','robustpls'}
    ypred                    = xpp.data(:,xpp.includ{2})*model.reg;
  case 'polypls';
    %  Use the xblock scores and the b to build up the prediction
    ypred = zeros(size(model.loads{1,1},1),size(model.loads{2,2},1));
    for i = 1:size(model.loads{1,1},2)
      ypred = ypred + (polyval(model.detail.bin(:,i),model.loads{1,1}(:,i)))*model.loads{2,2}(:,i)';
    end
end
model.pred{1,2}   = preprocess('undo',preprocessing{2},ypred);
model.pred{1,2}   = model.pred{1,2}.data;
model = calcystats(model,predictmode,ypp,ypred);

%test for Compact Blockdetails with calibrate mode
if ~predictmode & strcmp(options.blockdetails,'compact')
  options.blockdetails = 'standard';
end

%label as prediction
if predictmode
  model.modeltype = [model.modeltype '_PRED'];
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

switch options.display
  case {'on', 1}
    ssqtable(model.detail.ssq)
end

switch lower(options.plots)
  case 'final'
    try
      if ~predictmode
        plotloads(model);
        plotscores(model);
      else
        plotscores(varargin{5},model);
      end
    catch
      warning('EVRI:PlottingError',lasterr)
    end
end

varargout{1} = model;

%-----------------------------------------------------------------------
%Functions
function model = plsregression(x,y,lv,options);

options.display = 'off';  %hide output from these sub-functions

%extract includ fields here (reduces # of calls to subsref and speeds program)
xinclud = {x.includ{1,1};x.includ{2,1}};
yinclud = {y.includ{1,1};y.includ{2,1}};

m       = length(xinclud{1,1});  %= y.includ{1}
nx      = length(xinclud{2,1});
ny      = length(yinclud{2,1});
% if (nx<lv)
%   error('Number of LVs must be <= number of X-block variables.')
% end

model            = modelstruct(lower(options.algorithm));
model.date       = date;
model.time       = clock;
model.loads{1,1} = zeros(m,lv);  %X-block scores   't'
model.loads{1,2} = zeros(m,lv);  %Y-block scores   'u'
model.loads{2,1} = zeros(nx,lv); %X-block loadings 'p'
model.loads{2,2} = zeros(ny,lv); %Y-block loadings 'q'
model.wts        = zeros(nx,lv); %X-block weights  'w'
model.detail.ssq = zeros(lv,5);  %sum of squares info
model.detail.bin = zeros(1,lv);   %inner relation coefficients

model.detail.means{1,1}  = NaN*ones(1,size(x.data,2));
model.detail.means{1,2}  = NaN*ones(1,size(y.data,2));
model.detail.means{1,1}(1,xinclud{2}) = ...
  mean(x.data(xinclud{1},xinclud{2})); %mean of X-block
model.detail.means{1,2}(1,yinclud{2}) = ...
  mean(y.data(yinclud{1},yinclud{2})); %mean of Y-block
model.detail.stds{1,1}   = NaN*ones(1,size(x.data,2));
model.detail.stds{1,2}   = NaN*ones(1,size(y.data,2));
model.detail.stds{1,1}(1,xinclud{2}) = ...
  std(x.data(xinclud{1},xinclud{2})); %std of X-block
model.detail.stds{1,2}(1,yinclud{2}) = ...
  std(y.data(yinclud{1},yinclud{2})); %std of Y-block

if options.outputversion > 2;
  model = copydsfields(x,model,[],{1 1});
  model = copydsfields(y,model,[],{1 2});
end

if ~all([length(xinclud{1}) length(xinclud{2})] == size(x.data));
  xsub = x.data(xinclud{1},xinclud{2});
else
  xsub = x.data;
end
if ~all([length(yinclud{1}) length(yinclud{2})] == size(y.data));
  ysub = y.data(yinclud{1},yinclud{2});
else
  ysub = y.data;
end

if min(ysub)==max(ysub);
  error('Regression not possible when all y values are the same (i.e. range=0).');
end

if isfield(options,'weights') & ~isempty(options.weights)
  %handle weights option
  if isnumeric(options.weights)
    options.weightsvect = options.weights;
    options.weights = 'custom';
  end
  switch options.weights
    case 'hist'
      %calculate histogram-based correction
      [hy,hx] = hist(ysub(:,1),40);
      weights = 1./interp1(hx,hy,ysub(:,1),'nearest','extrap')';
    case 'custom'
      weights = options.weightsvect;
      if ~isempty(weights)
        if length(weights)==size(x.data,1)
          weights = weights(y.include{1});
        elseif length(weights)~=m
          error('Length of weights must be equal to total number of samples')
        end
      end
    otherwise
      %none
      weights = [];
  end
  if ~isempty(weights)
    xsub = rescale(xsub',zeros(1,m),weights)';
    ysub = rescale(ysub',zeros(1,m),weights)';
  end
end

switch lower(options.algorithm)
  case 'nip'
    
    [model.reg,  model.detail.ssq,  lds21,  lds22, model.wts,  lds11,  lds12,  model.detail.bin] = nippls(xsub,ysub,lv,options);
    model.loads = {lds11 lds12; lds21 lds22};
    
  case 'sim'
    
    [model.reg,  model.detail.ssq,  lds21,  lds22, model.wts,  lds11,  lds12,  model.detail.basis] = simpls(xsub,ysub,lv,options);
    model.loads = {lds11 lds12; lds21 lds22};
    
  case 'dspls'
    
    [model.reg,  model.detail.ssq,  lds21,  lds22, model.wts,  lds11,  lds12,  model.detail.basis] = dspls(xsub,ysub,lv,options);
    model.loads = {lds11 lds12; lds21 lds22};
    
  case 'robustpls'
    rplsout = rsimpls(xsub,ysub,'k',lv,'kmax',min([lv,options.roptions.kmax]),'alpha',options.roptions.alpha,'plots',0);
    model.detail.robustpls = rplsout;
    
    reg = zeros(ny*(lv-1),size(rplsout.slope,1)); %Pad regression vector with zeros so works with existing code.
    model.reg = [reg; rplsout.slope']; %Slope.
    
    model.loads{2,1}  = rplsout.weights.p; %Robust loadings (eigenvectors).
    model.loads{1,1} = rplsout.T; %Robust scores.
    %model.loads{1,2} = [];%Not returned by robust pls.
    %model.loads{2,2} = [];%Not returned by robust pls.
    model.wts = rplsout.weights.r; %Robust weights.
    datarank = rplsout.robpca.k; %Number of (chosen) principal components.
    
    %Build SSQ Table, 5 columns.
    pcassq = [[1:length(rplsout.robpca.L)]' rplsout.robpca.L(:)];
    sqscr = sum(rplsout.robpca.T(rplsout.flag,:).^2);
    pcassq(:,3) = 100*sqscr./(sum(sqscr)+sum(rplsout.robpca.od(rplsout.flag).^2));
    pcassq(:,4) = cumsum(pcassq(:,3));
    
    %Build Y varcap columns [from plsengine].
    [my,ny] = size(ysub);
    ncomp = lv;
    newncomp   = min([datarank ncomp]);
    %Robust pls doesn't calculate intermediate components.
    ssqty = zeros(ncomp,1);
    ssqy  = sum(sum(ysub.^2)');
    dif   = ysub(rplsout.flag,:)-rplsout.fitted(rplsout.flag,:);
    ssqty(newncomp,1) =  ((ssqy - sum(sum(dif.^2)))/ssqy)*100;
    ssqy = NaN(ncomp,1);
    ssqty(1:newncomp-1)=NaN;
    
    ssq = [[1:ncomp]' zeros(ncomp,2)*0 ssqy ssqty];
    ssq(1:newncomp,2:3) = pcassq(1:newncomp,3:4);
    
    ssq(newncomp:ncomp,3) = ssq(newncomp,3);
    ssq(newncomp:ncomp,5) = ssq(newncomp,5);
    model.detail.ssq = ssq;
    
  case 'polypls'  %Not yet completely supported - use basic function polypls
    
    ssq     = zeros(lv,2);
    ssqx    = sum(sum(xsub.^2)');
    ssqy    = sum(sum(ysub.^2)');
    olv     = lv;
    
    if ~isfield(options,'order');
      error('Order of polynomial must be supplied');
    end
    n = options.order;
    [mx,nx] = size(xsub);
    [my,ny] = size(ysub);
    p = zeros(nx,lv);
    q = zeros(ny,lv);
    w = zeros(nx,lv);
    t = zeros(mx,lv);
    u = zeros(my,lv);
    b = zeros(n+1,lv);
    ssq = zeros(lv,2);
    ssqx = sum(sum(xsub.^2)');
    ssqy = sum(sum(ysub.^2)');
    for i = 1:lv
      [pp,qq,ww,tt,uu] = plsnipal(xsub,ysub);
      b(:,i) = (polyfit(tt,uu,n))';
      xsub = xsub - tt*pp';
      ysub = ysub - (polyval(b(:,i),tt))*qq';
      ssq(i,1) = (sum(sum(xsub.^2)'))*100/ssqx;
      ssq(i,2) = (sum(sum(ysub.^2)'))*100/ssqy;
      t(:,i) = tt(:,1);
      u(:,i) = uu(:,1);
      p(:,i) = pp(:,1);
      w(:,i) = ww(:,1);
      q(:,i) = qq(:,1);
    end
    
    model.loads{1,1} = t; %X-block scores   't'
    model.loads{1,2} = u; %Y-block scores   'u'
    model.loads{2,1} = p; %X-block loadings 'p'
    model.loads{2,2} = q; %Y-block loadings 'q'
    model.wts        = w; %X-block weights  'w'
    model.detail.bin = b; %inner relation coeffecients  'b'
    
    ssqdif = zeros(lv,2);
    ssqdif(1,1) = 100 - ssq(1,1);
    ssqdif(1,2) = 100 - ssq(1,2);
    for i = 2:lv
      for j = 1:2
        ssqdif(i,j) = -ssq(i,j) + ssq(i-1,j);
      end
    end
    model.detail.ssq = [(1:lv)' ssqdif(:,1) cumsum(ssqdif(:,1)) ssqdif(:,2)...
      cumsum(ssqdif(:,2))];
    model.reg = ones(nx,ny);
    
end

%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                            userlevel       description
'display'                'Display'        'select'        {'on' 'off'}                     'novice'        'Governs level of display.';
'plots'                  'Display'        'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
'outputversion'          'Standard'       'select'        {2 3}                            'novice'        'Governs output format. 2 returns output in non-standard PLS_Toolbox version 2.0 format.';
'preprocessing'          'Standard'       'cell(vector)'  ''                               'novice'        'Preprocessing structures. Cell 1 is preprocessing for X block, Cell 2 is preprocessing for Y block.';
'algorithm'              'Standard'       'select'        {'nip' 'sim' 'dspls' 'robustpls'} 'novice'        'PLS algorithm to use: NIPALS (''nip''), SIMPLS (''sim''), Direct Scores PLS (''dspls''), or Robust algorithm with automatic outlier detection (''robustpls'').';
'orthogonalize'          'Standard'       'select'        {'off' 'on'}                     'novice'        'Orthogonalize model to condense y-block variance into first latent variable ''yes'' = produce orthogonalized model.';
'blockdetails'           'Standard'       'select'        {'standard' 'all'}               'novice'        'Extent of predictions and raw residuals included in model. ''standard'' = keeps only y-block, ''all'' keeps both x- and y- blocks.';
'confidencelimit'        'Standard'       'double'        'float(0:1)'                     'novice'        'Confidence level for Q and T2 limits (fraction between 0 and 1)';
'weights'                'Standard'       'select'        {'none' 'hist' 'custom'}         'novice'        'Governs sample weighting. ''none'' does no weighting. ''hist'' performs histogram weighting in which large numbers of samples at individual y-values are down-weighted relative to small numbers of samples at other values. ''custom'' uses the weighting specified in the weightsvect option.'
'weightsvect'            'Standard'       'vector'        'float(0:inf)'                   'novice'        'Used only with custom weights. The vector specified must be equal in length to the number of samples in the y block and each element is used as a weight for the corresponding sample. If empty, no sample weighting is done.';
'roptions.alpha'         'Robust Options' 'double'        'float(.5:1)'                    'novice'        'alpha is the fraction of samples used for the robust scatter estimate. Any value between 0.5 and 1 may be specified (default = 0.75). These options are only used when algorithm is robust PCA.';
'roptions.kmax'          'Robust Options' 'double'        'int(0:inf)'                     'novice'        'Maximum number of latent variables allowed with robust model';
};

out = makesubops(defs);

