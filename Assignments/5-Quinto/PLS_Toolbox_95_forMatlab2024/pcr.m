function varargout = pcr(varargin)
%PCR Principal components regression for multivariate Y.
%  PCR identifies models of the form Xb = y + e.
%  INPUTS:
%        x  = X-block: predictor block (2-way array or DataSet Object),
%        y  = Y-block: predicted block (2-way array or DataSet Object), and
%     ncomp = number of components to to be calculated (positive integer scalar).
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%           display: [ 'off' | {'on'} ]      governs level of display to command window.
%             plots: [ 'none' | {'final'} ]  governs level of plotting.
%     outputversion: [ 2 | {3} ]             governs output format.
%     preprocessing: { [] [] }               preprocessing structure (see PREPROCESS).
%         algorithm: [{'svd'} | 'robustpcr' | 'correlationpcr' | 'frpcr' ]
%                     governs which algorithm to use. 'svd' is standard
%                     algorithm. 'robustpcr' is robust algorithm with
%                     automatic outlier detection. 'correlationpcr' is
%                     standard PCR with re-ordering of factors in order of
%                     y-variance captured. 'frpcr' is full-ratio
%                     (optimized scaling) PCR model with built-in sample
%                     scale correction.
%      blockdetails: [ {'standard'} | 'all' ]   Extent of predictions
%                     and raw residuals included in model. 'standard' =
%                     only y-block, 'all' x and y blocks.
%   confidencelimit: [{0.95}] Confidence level for Q and T2 limits. A value
%                     of zero (0) disables calculation of confidence
%                     limits.
%          roptions: structure of options to pass to rpcr (robust PCR engine
%                    from the Libra Toolbox). Only used when algorithm is
%                    'robustpcr'.
%                alpha: (1-alpha) measures the number of outliers the
%                       algorithm should resist. Any value between 0.5 and 1 may
%                       be specified (default = 0.75). These options are
%                       only used when algorithm is 'robustpcr'.
%            intadjust: (Defualt = 0)If equal to one, the intercept adjustment
%                       for the LTS-regression will be calculated. See
%                       ltsregres.m for details (Libra Toolbox).
%
%  OUTPUT:
%     model = standard model structure containing the PCR model (See MODELSTRUCT)
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: model = pcr(x,y,ncomp,options);  %identifies model (calibration step)
%I/O: pred  = pcr(x,model,options);    %makes predictions with a new X-block
%I/O: valid = pcr(x,y,model,options);  %makes predictions with new X- & Y-block
%I/O: pcr demo                         %runs a demo of the PCR function
%I/O: options = pcr('options');        %returns a default options structure
%
%See also: ANALYSIS, CROSSVAL, FRPCR, MODELSTRUCT, PCA, PLS, PREPROCESS, RIDGE

%Old I/O:
%PCR Principal components regression for multivariate y.
%  Inputs are the matrix of predictor variables (x), vector
%  or matrix of predicted variable (y), maximum number
%  of principal components to consider (pc), and an optional
%  variable (out) to suppress intermediate output (out=0 suppresses
%  output {default = 1}. Outputs are the matrix of regression
%  coefficients (b) for each number of principal components,
%  where each block of ny rows corresponds to the PCR model
%  for that number of principal components, the sum of
%  squares information (ssq), the x-block scores (t), and
%  the x-block loadings (p).
%
%I/O: [b,ssq,t,p,eigs] = pcr(x,y,pc,out);
%

%Copyright Eigenvector Research, Inc. 1995
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%Modified 4/96,12/97 NBG
%03/18/02 (modified for version 3)
%jms 3/24/03 number of components in model from LOADS not SCORES
%jms 5/21/03 calculate RMSEC from only included samples
%jms 4/28/04 fix orientation of T^2 for variables
%jms 5/7/04 add pcassq field to details to speed up Q limits calc
%rsk 05/24/04 fix bug set include fields in y to those of model in test mode.
%jms 5/26/05 allow other types of preprocessing options (e.g. strings)
%rsk 12/05/05 add robust pcr.

%Start Input
if nargin==0  % LAUNCH GUI
  analysis pcr
  return
end
if ischar(varargin{1}) %Help, Demo, Options
  
  options = [];
  options.name          = 'options';
  options.display       = 'on';     %Displays output to the command window
  options.plots         = 'final';  %Governs plots to make
  options.outputversion = 3;        %2,3 Tells what to output (3=ModelStruct)
  options.preprocessing = {[] []};  %See preprocess
  options.algorithm     = 'svd';    %use SVD algorithm
  options.blockdetails  = 'standard';  %level of details
  options.confidencelimit = 0.95;
  options.roptions.alpha = 0.75; %Alpha for robust methods between 0.5 and 1.
  options.roptions.intadjust = 0; %If equal to one, the intercept adjustment for the LTS-regression will be calculated.
  options.frpcroptions  = frpcrengine('options');   %add frpcr engine options
  options.frpcroptions  = rmfield(options.frpcroptions,{'display','plots'});
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
v2options.plots         = 'final';      %Governs plots to make
v2options.outputversion = 2;            %2,3 Tells what to output (2=[b,ssq,t,p,eigs])
v2options.preprocessing = {[] []};      %See preprocess
%v2options.algorithm     = 'svd';        %SVD algorithm
v2options.blockdetails  = 'standard';   %level of details

switch nargin
  case 2  %two inputs
    %v3 : (x,model)
    if ismodel(varargin{2})
      varargin = {varargin{1},[],[],pcr('options'),varargin{2}};
    else
      error(['Input NCOMP is missing. Type: ''help ' mfilename '''']);
    end
    
  case 3  %three inputs
    %v2 : (x,y,ncomp)
    %v3 : (x,y,options) ??? (invalid, need ncomp)
    %v3 : (x,y,model)
    %v3 : (x,model,options)
    
    if isnumeric(varargin{3});
      %v3/v2 : (x,y,ncomp)
      if nargout > 1;
        varargin{4} = v2options;      %multiple outputs = V2 call
      else
        varargin{4} = pcr('options');
      end
    elseif ismodel(varargin{2});
      %v3 : (x,model,options)
      varargin = {varargin{1},[],[],varargin{3},varargin{2}};
    elseif ~ismodel(varargin{3});
      %v3 : (x,y,options) ???
      error(['Input NCOMP is missing. Type: ''help ' mfilename '''']);
    else
      %v3 : (x,y,model)
      varargin{5} = varargin{3};                    %check model format later
      varargin{4} = pcr('options');                 %get default options
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
          v2options.plots         = 'none';        %Governs plots to make
          varargin{4} = v2options;
        case 1
          varargin{4} = v2options;
        otherwise
          error(['Input OPTIONS or MODEL not recognized. Type: ''help ' mfilename ''''])
      end
      
    elseif ismodel(varargin{3});
      %v3 : (x,y,model,options)
      varargin{5} = varargin{3};
      varargin{3} = [];
      
    elseif ismodel(varargin{4})
      %v3 : (x,y,ncomp,model)
      varargin{5} = varargin{4};
      varargin{4} = pcr('options');   %default options
      
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

options = reconopts(varargin{4},pcr('options'));

if ~ismember(options.algorithm,{'svd' 'robustpcr' 'correlationpcr' 'frpcr'})
  error(['Algorithm [' options.algorithm '] not recognized. PCR supports ''svd'', ''robustpls'', and ''correlationpcr''.'])
  return
end
switch options.outputversion
  case{2,3}
    %Take no action these are ok inputs
  otherwise
    options.outputversion = 3;
    warning('EVRI:Outputversion','OPTIONS.OUTPUTVERSION not recognized. Reset to 3.')
end
options.blockdetails = lower(options.blockdetails);
if ~ismember(options.blockdetails,{'compact','standard','all'})
  error(['OPTIONS.BLOCKDETAILS not recognized. Type: ''help ' mfilename ''''])
end
if ~isfield(options,'rawmodel');
  options.rawmodel = 0;       %undocumented option to output raw results ONLY
end

%B) check model format
if length(varargin)>=5;
  try
    varargin{5} = updatemod(varargin{5});        %make sure it's v3.0 model
  catch
    error(['Input MODEL not recognized. Type: ''help ' mfilename ''''])
  end
  if options.rawmodel & ismember(options.algorithm,{'frpcr' 'robustpcr'})
    %frcpr and robustpcr do not work with rawmodel - force us to recalculate the
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
end

%C) CHECK Data Inputs
[datasource{1:2}] = getdatasource(varargin{1:2});
if isa(varargin{1},'double')      %convert varargin{1} and varargin{2} to DataSets
  varargin{1}        = dataset(varargin{1});
  varargin{1}.name   = inputname(1);
  varargin{1}.author = 'PCR';
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
    varargin{2}.author = 'PCR';
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
      %otherwise, do the rest of this to match include fields with y.
      if any(varargin{5}.detail.includ{2,2}>size(varargin{2}.data,2))
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
  
  switch options.algorithm
    
    case 'robustpcr'   %Robust PCR algorithm
      
      model = pcrregression(xpp,ypp,ncomp,options);          %Call PCR Function
      
      %Scale step, correct for Robust centering of model. Add to options and model.detail.prepro.
      xpp.data(:,xpp.includ{2}) = scale(xpp.data(:,xpp.includ{2}), model.detail.robustpcr.robpca.M);
      %Add a prepro step to account for what Robust method does.
      robpp = preprocess('default','mean center');
      robpp.description = 'Mean Center';
      robpp.tooltip = 'Remove robustly calculated offset from each variable.';
      robpp.keyword = 'Mean Center';
      robpp.calibrate = {'%Values calculated by robpca.'};
      robpp.out = {model.detail.robustpcr.robpca.M};
      preprocessing{1} = [preprocessing{1} robpp];
      model.detail.preprocessing{1} = [model.detail.preprocessing{1} robpp];
      %Handle Y block.
      ycor = model.detail.robustpcr.int+(model.detail.robustpcr.robpca.M*model.detail.robustpcr.slope); %y-intercept includes correction for regression vector which is relative to un-robust-centered data
      robppy = robpp;
      robppy.out = {ycor};
      ypp.data(:,ypp.includ{2}) = scale(ypp.data(:,ypp.includ{2}), ycor);
      preprocessing{2} = [preprocessing{2} robppy];
      model.detail.preprocessing{2} = [model.detail.preprocessing{2} robppy];
      
      %copy used samples into includ fields
      model.detail.includ{1,1} = xpp.include{1}(find(model.detail.robustpcr.flag));
      model.detail.includ{1,1} = model.detail.includ{1,1}(:)';
      model.detail.includ{1,2} = model.detail.includ{1,1};
      
      %create classes for "flagged" (excluded outliers)
      flagged = ones(1,size(xpp,1)).*2;
      flagged(xpp.include{1}) = 0;
      flagged(xpp.include{1}(find(~model.detail.robustpcr.flag))) = 1;
      j = 1;
      while j<=size(model.detail.class,3);
        if isempty(model.detail.class{1,1,j});
          break;
        end
        j = j+1;
      end
      model.detail.class{1,1,j} = flagged;  %store classes there
      model.detail.classname{1,1,j} = 'Outlier Status';
      
    case 'frpcr'  %Full-Ratio PCR
      
      fropts = options.frpcroptions;
      fropts.display = 'off';
      fropts.plots = 'none';
      [b,ssq,u,sampscales,msg] = frpcrengine(xpp, ypp, ncomp, fropts);
      
      model = modelstruct('pcr');
      
      model.date = date;
      model.time = clock;
      model.info = 'Scores are in row 1 of cells in the loads field.';
      model.reg  = b;
      model.loads{2,1} = u;
      model.description{2} = 'Using Full-Ratio Equation';
      
      model.detail.means{1,1}  = NaN*ones(1,size(xpp.data,2));
      model.detail.means{1,2}  = NaN*ones(1,size(ypp.data,2));
      model.detail.means{1,1}(1,xpp.includ{2}) = ...
        mean(xpp.data(xpp.includ{1},xpp.includ{2})); %mean of X-block
      model.detail.means{1,2}(1,ypp.includ{2}) = ...
        mean(ypp.data(ypp.includ{1},ypp.includ{2})); %mean of Y-block
      model.detail.stds{1,1}   = NaN*ones(1,size(xpp.data,2));
      model.detail.stds{1,2}   = NaN*ones(1,size(ypp.data,2));
      model.detail.stds{1,1}(1,xpp.includ{2}) = ...
        std(xpp.data(xpp.includ{1},xpp.includ{2})); %std of X-block
      model.detail.stds{1,2}(1,ypp.includ{2}) = ...
        std(ypp.data(ypp.includ{1},ypp.includ{2})); %std of Y-block
      
      model = copydsfields(xpp,model,[],{1 1});
      model = copydsfields(ypp,model,[],{1 2});
      model.detail.ssq           = ssq;
      
    otherwise  %standard PCR
      
      %Call PCR Function
      model = pcrregression(xpp,ypp,ncomp,options);
      
      
  end
  model.datasource = datasource;
  model.detail.preprocessing = preprocessing;   %copy calibrated preprocessing info into model
  
else    %5 inputs with outputversion of 3 implies that input #5 is a raw model previously output, don't decompose/regress
  
  model = varargin{5};
  if ~strcmp(lower(model.modeltype),'pcr');
    error('Input MODEL is not a PCR model');
  end
  
  if size(x.data,2)~=model.datasource{1}.size(1,2)
    error('Variables included in data do not match variables expected by model');
  elseif length(x.include{2,1})~=length(model.detail.includ{2,1}) | any(x.includ{2,1} ~= model.detail.includ{2,1});
    missing = setdiff(model.detail.includ{2,1},x.include{2,1});
    x.data(:,missing) = nan;  %replace expected but missing data with NaN's to force replacement
    x.includ{2,1} = model.detail.includ{2,1};
  end
  
  if mdcheck(x.data(:,x.includ{2,1}));
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
  
  if ~options.rawmodel
    model = copydsfields(x,model,[1],{1 1});
    model.detail.includ{1,2} = x.includ{1};
    model.datasource = datasource;
  end
  
  %Update time and date.
  model.date = date;
  model.time = clock;
  
end

%copy options into model
model.detail.options = options;

if options.outputversion==2
  %[b,ssq,t,p,eigs]
  varargout{1} = model.reg;         % b    (matrix)
  varargout{2} = model.detail.ssq;  % ssq
  varargout{3} = model.loads{1,1};  % t
  varargout{4} = model.loads{2,1};  % p
  varargout{5} = model.detail.eigs; % eigs
  return
end
if options.rawmodel & ~predictmode;
  varargout{1} = model;   %pass raw model info out as output
  return
end

if options.rawmodel & predictmode; predictmode = 0; end
%rawmodel here means that this is really just a normal "reduce raw model" call, do NOT treat as predictmode

%fill in for all mode 1 sample values (in addition to the .includ field)
%calculate tsqs, residuals, scores for non-included samples.
if ~predictmode;
  %reduce to # of LVs requested (or maxrank of scores)
  if ~strcmp(options.algorithm,'frpcr')
    maxrank = rank(model.loads{1,1});
  else
    maxrank = size(model.loads{2,1},2);
  end
  if maxrank < ncomp;
    ncomp = maxrank;
  end
  
  ny                    = length(ypp.includ{2,1});
  if ~strcmp(options.algorithm,'frpcr')
    model.reg             = model.reg([1:ny]+(ny*(ncomp-1)),:)';
    for j=1:prod(size(model.loads));
      model.loads{j}      = model.loads{j}(:,1:ncomp);
    end
    if ~options.rawmodel
      model.detail.ssq    = model.detail.ssq(1:ncomp,:);
    end
  end
end

%X-Block Statistics
model.loads{1,1}      = xpp.data(:,model.detail.includ{2,1})*model.loads{2,1};
model.detail.data{1}  = x;
model.pred{1}         = model.loads{1,1}*model.loads{2,1}';
model.detail.res{1}   = xpp.data(:,model.detail.includ{2,1}) - model.pred{1};

model.ssqresiduals{1,1} = model.detail.res{1}.^2;
model.ssqresiduals{2,1} = sum(model.ssqresiduals{1,1}(model.detail.includ{1,1},:),1); %based on cal samples only
model.ssqresiduals{1,1} = sum(model.ssqresiduals{1,1},2); %residuals for ALL samples
if ~predictmode;
  if isfield(model.detail,'pcassq') & size(model.detail.pcassq,1)>varargin{3};
    model.detail.reseig = model.detail.pcassq(varargin{3}+1:end,2);
    if options.confidencelimit>0
      model.detail.reslim{1,1} = residuallimit(model.detail.reseig, options.confidencelimit);
    else
      model.detail.reslim{1,1} = 0;
    end
    
    %         if size(model.detail.ssq,1)>varargin{3};
    %           %use existing residual eigenvalues from the SSQ table if we have them (faster than calculating from raw resids)
    %           model.detail.reseig = model.detail.ssq(varargin{3}+1:end,2);
    %           model.detail.reslim{1,1} = residuallimit(model.detail.reseig, options.confidencelimit);
  else
    %calculate residual eigenvalues using raw residuals matrix
    if options.confidencelimit>0
      [model.detail.reslim{1,1} model.detail.reseig] = residuallimit(model.detail.res{1}(model.detail.includ{1,1},:), options.confidencelimit);
    else
      model.detail.reslim{1,1} = 0;
    end
  end
end

if ~predictmode;
  origmodel = model;
else
  origmodel = varargin{5};   %get pointer to original model
end
incl    = origmodel.detail.includ{1,1};
m       = length(incl);
T       = origmodel.loads{1,1};
P       = origmodel.loads{2,1};
T_cal   = T(incl,:);

f       = diag(sqrt(1./(diag(T_cal'*T_cal)/(m-1))));
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

if ~predictmode & ~strcmp(options.algorithm,'frpcr')
  model.detail.selratio = sratio(xpp,model,struct('preprocessed',true));
end

%Y-Block Statistics
%store original and predicted Y values
model.detail.data{1,2}   = y;
switch options.algorithm
  case 'frpcr'
    ypred         = frpcrengine(xpp.data(:,xpp.includ{2}),model.reg);  %PREDICT mode
  otherwise %all other models
    ypred         = xpp.data(:,xpp.includ{2})*model.reg;
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

varargout{1} = model;

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
function model = pcrregression(x,y,pc,options);
%call model = pcrregression(xpp,ypp,ncomp,options);

m       = length(x.includ{1,1});  %= y.includ{1}
nx      = length(x.includ{2,1});
ny      = length(y.includ{2,1});
% if (nx<pc)
%   error('Number of PCs must be <= number of X-block variables.')
% end

model            = modelstruct('pcr');

model.date       = date;
model.time       = clock;
model.loads{1,1} = zeros(m,pc);  %X-block scores   't'
model.loads{2,1} = zeros(nx,pc); %X-block loadings 'p'
model.detail.ssq = zeros(pc,5);  %sum of squares info
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

if ~all([length(x.includ{1}) length(x.includ{2})] == size(x.data));
  xsub = x.data(x.includ{1},x.includ{2});
else
  xsub = x.data;
end
if ~all([length(y.includ{1}) length(y.includ{2})] == size(y.data));
  ysub = y.data(y.includ{1},y.includ{2});
else
  ysub = y.data;
end

switch options.algorithm
  case 'svd'
    [reg,ssq,loads,scores,pcassq] = pcrengine(xsub,ysub,pc,options);
    
  case 'correlationpcr'
    options.sortorder = 'y';
    [reg,ssq,loads,scores,pcassq] = pcrengine(xsub,ysub,pc,options);
    
  case 'robustpcr'
    rpcrout = rpcr(xsub,ysub,'k',pc,'kmax',min([pc,19]),'alpha',options.roptions.alpha,'intadjust',options.roptions.intadjust,'plots',0);
    model.detail.robustpcr = rpcrout;
    
    reg = zeros(ny*(pc-1),size(rpcrout.slope,1)); %Pad regression vector with zeros so works with existing code.
    reg = [reg; rpcrout.slope']; %Slope.
    
    loads  = rpcrout.robpca.P; %Robust loadings (eigenvectors).
    scores = rpcrout.robpca.T; %Robust scores.
    datarank = rpcrout.robpca.k; %Number of (chosen) principal components.
    
    %Build SSQ Table, 5 columns.
    pcassq = [[1:length(rpcrout.robpca.L)]' rpcrout.robpca.L(:)];
    sqscr = sum(rpcrout.robpca.T(rpcrout.flag,:).^2);
    pcassq(:,3) = 100*sqscr./(sum(sqscr)+sum(rpcrout.robpca.od(rpcrout.flag).^2));
    pcassq(:,4) = cumsum(pcassq(:,3));
    
    %Build Y varcap columns [from pcrengine].
    [my,ny] = size(ysub);
    ncomp = pc;
    newncomp   = min([datarank ncomp]);
    %Robust PCR doesn't calculate intermediate components.
    ssqty = zeros(ncomp,1);
    ssqy    = sum(sum(ysub.^2)');
    dif   = ysub-rpcrout.fitted;
    ssqty(newncomp,1) =  ((ssqy - sum(sum(dif.^2)))/ssqy)*100;
    ssqy = NaN(ncomp,1);
    ssqty(1:newncomp-1)=NaN;
    
    ssq = [[1:ncomp]' zeros(ncomp,2)*0 ssqy ssqty];
    ssq(1:newncomp,2:3) = pcassq(1:newncomp,3:4);
    
    ssq(newncomp:ncomp,3) = ssq(newncomp,3);
    ssq(newncomp:ncomp,5) = ssq(newncomp,5);
    
    switch options.display
      case {'on', 1}
        ssqtable(ssq)
    end
end
model.detail.ssq = ssq;
model.detail.pcassq = pcassq;
model.reg        = reg;
model.loads      = {scores;loads};

%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                            userlevel       description
'display'                'Display'        'select'        {'on' 'off'}                     'novice'        'Governs level of display.';
'plots'                  'Display'        'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
'outputversion'          'Standard'       'select'        {2 3}                            'novice'        'Governs output format. 2 returns output in non-standard PLS_Toolbox version 2.0 format.';
'preprocessing'          'Standard'       'cell(vector)'  ''                               'novice'        'Preprocessing structures. Cell 1 is preprocessing for X block, Cell 2 is preprocessing for Y block.';
'algorithm'              'Standard'       'select'        {'svd' 'robustpcr' 'correlationpcr' 'frpcr'} 'novice'        'Governs algorithm selection. ''svd'' is standard algorithm. ''robustpcr'' is robust algorithm with automatic outlier detection. ''correlationpcr'' is standard PCR with re-ordering of factors in order of y-variance captured. ''frpcr'' is full-ratio (optimized scaling) PCR with automatic normalization of sample scale.';
'blockdetails'           'Standard'       'select'        {'standard' 'all'}               'novice'        'Extent of predictions and raw residuals included in model. ''standard'' = only y-block, ''all'' x and y blocks.'
'confidencelimit'        'Standard'       'double'        'float(0:1)'                     'novice'        'Confidence level for Q and T2 limits (fraction between 0 and 1)';
'roptions.alpha'         'Robust Options' 'double'        'float(.5:1)'                    'novice'        'alpha is the fraction of samples used for the robust scatter estimate. Any value between 0.5 and 1 may be specified. (default = 0.75). These options are only used when algorithm is robust PCA.';
'roptions.intadjust'     'Robust Options' 'boolean'       ''                               'novice'        'If equal to one, the intercept adjustment for the LTS-regression will be calculated.';
};

out = makesubops(defs);
