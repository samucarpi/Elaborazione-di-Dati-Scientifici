function varargout = mcr(varargin)
%MCR Multivariate curve resolution with constraints.
%  INPUTS:
%        x = the matrix to be decomposed as X = CS, and
%   The second input can be one of the following:
%     (ncomp) The number of components to model. An initial guess is
%            automatically calculated for each component.
%        (c0) An explicit initial guess for (c) or (s), depending on its size:
%            If x is size (M by N) then:
%            If (c0) is size (M by K) it is the initial guess for (c) (also if M==N).
%            If (c0) is size (K by N) it is the initial guess for (s).
%     (model) A model structure for prediction mode.
%
%  OPTIONAL INPUT:
%     options = structure with the following fields:
%           display: [ 'off' | {'on'} ]      governs level of display to command window.
%             plots: [ 'none' | {'final'} ]  governs level of plotting.
%           waitbar: [ 'off' | 'on' | {'auto'} ] governs use of waitbar,
%     preprocessing: { [] } preprocessing structure (see PREPROCESS).
%      blockdetails: [ {'standard'} | 'all' ]   Extent of predictions and raw residuals
%                     included in model. 'standard' = none, 'all' x-block
%          initmode: [1 | 2]  Mode of x for automatic initialization.
%   confidencelimit: [{0.95}] Confidence level for Q limits.
%        alsoptions: ['options'] Options for als (see ALS)
%  OUTPUT:
%     model = standard model structure containing the MCR model (See MODELSTRUCT)
%
%I/O: model   = mcr(x,ncomp,options);  %identifies model (calibration step)
%I/O: model   = mcr(x,c0,options);     %identifies model (calibration step)
%I/O: pred    = mcr(x,model,options);  %projects a new X-block onto existing model, prediction mode.
%I/O: options = mcr('options');        %returns default options structure
%I/O: mcr demo                         %runs a demo of the MCR function.
%
%See also: ALS, ANALYSIS, EVOLVFA, EWFA, FASTERNNLS, FASTNNLS, FASTNNLS_SEL, MLPCA, PARAFAC, PLOTLOADS, PLOTSCORES, PREPROCESS

%Copyright Eigenvector Research, Inc. 1991
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%rsk 02/27/04 Initial porting of PCA code.
%jms 02/27/04 Changed to pass of dataset to ALS and better handle include
%   field for predictions
%jms 03/09/04 -disabled plotting in als
%   -added standard calls to plotscores/plotloads
%   -removed extra "end"
%jms 4/28/04 remove all T^2 references (none reported)
%jms 5/7/04 fix ssqtable when residuals > x-block
%rsk 06/16/04 Set pp to none when calling analysis.

%Start Input
if nargin==0  % LAUNCH GUI
  h = analysis('mcr');
  handles = guidata(h);
  setappdata(handles.preprocessmain,'preprocessing',[]);
  return;
end

%--------options handling------------------------------------
if ischar(varargin{1}) %Help, Demo, Options
  
  options = [];
  options.name          = 'options';
  options.display       = 'on';     %Displays output to the command window
  options.plots         = 'final';  %Governs plots to make
  options.waitbar       = 'auto';
  options.preprocessing = {[]};     %See Preprocess
  options.blockdetails  = 'standard';  %level of details
  options.initmode      = 1;
  options.confidencelimit = .95;
  options.alsoptions    = als('options');
  options.definitions   = @optiondefs;
  
  if nargout==0
    evriio(mfilename,varargin{1},options);
  else
    varargout{1} = evriio(mfilename,varargin{1},options);
  end
  
  return;
end
%--------options handling------------------------------------

%Check inputs and determine if valid information has been past.

if nargin<2
  error([ upper(mfilename) ' requires 2 inputs.'])
end

%--------Check Inputs---------------------------------
%4 steps (A-D) in checking inputs:
%A) check options.
%B) check model input.
%C) check data input.
%D) check metaparameter input.


%A) Check Options
switch nargin
  
  case 2  %two inputs
    %(x,ncomp)
    %(x,c0)
    %(x,model)
    if isnumeric(varargin{2}) | isdataset(varargin{2});
      
      %(x,ncomp)
      %(x,c0)
      varargin{3} = mcr('options');
      
    elseif ismodel(varargin{2})
      
      %(x,model)
      varargin = {varargin{1}, [], mcr('options'), varargin{2}};
      
    end
    
  case 3  %three inputs
    
    %(x,ncomp,options)
    %(x,c0,options)
    %(x,model,options)
    
    if isa(varargin{3},'struct');
      if ismodel(varargin{2});
        %(x,model,options)
        varargin = {varargin{1}, [], varargin{3}, varargin{2}};
      end
    end
    
  otherwise
    
    error(['Unrecognized input. Type: ''help ' mfilename ''''])
    
end

%Fill in any missing fields to options sturcture.
options = reconopts(varargin{3},mcr('options'));

%Check blockdetails option.
options.blockdetails = lower(options.blockdetails);
if ~ismember(options.blockdetails,{'compact','standard','all'})
  error(['OPTIONS.BLOCKDETAILS not recognized. Type: ''' mfilename ' options'''])
end

%B) Check model format, determine prediction mode:
%Calibration (predictmode = 0)
%Prediction (predictmode = 1)
%Default prediction mode is Calibration.
predictmode = 0;

if length(varargin)>=4;
  predictmode = 1;                                  %and set predict mode flag
  if isempty(varargin{2});
    varargin{2} = size(varargin{4}.loads{2,1},2);   %get ncomp from model (if needed)
  end
end

%C) CHECK Data Inputs
datasource = {getdatasource(varargin{1})};
if isa(varargin{1},'double')      %convert varargin{1} to DataSet
  varargin{1}        = dataset(varargin{1});
  varargin{1}.name   = inputname(1);
  varargin{1}.author = 'MCR';
elseif ~isa(varargin{1},'dataset')
  error(['Input X must be class ''double'' or ''dataset''.'])
end
if ndims(varargin{1}.data)>2
  error(['Input X must contain a 2-way array. Input has ',int2str(ndims(varargin{1}.data)),' modes.'])
end

%D) Check Meta-Parameters Input
%create initial guess input
if isnumeric(varargin{2}) | isa(varargin{2},'dataset')
  if prod(size(varargin{2})) == 1
    if varargin{2}<1 | varargin{2}~=fix(varargin{2});
      error('Input NCOMP must be integer scalar.')
    end
    iguess = {varargin{2} options.initmode};
  else
    iguess = varargin{2};  %c0
    varargin{2} = min(size(varargin{2}));  %number of components (lesser size of c0)
  end
end

if predictmode & varargin{2}~=size(varargin{4}.loads{2,1},2);
  error('Cannot use a different number of components (NCOMP) with previously created model');
end

%Begin ---------------------------------------------------------------
% ready to go...
x = varargin{1};

%Handle Preprocessing
if isempty(options.preprocessing);
  options.preprocessing = {[]};  %reinterpet as empty cell
end
if ~isa(options.preprocessing,'cell');
  options.preprocessing = {options.preprocessing};  %insert into cell
end

%Initialize model structure
model      = modelstruct('mcr');
model.date = date;
model.time = clock;

%Call Function
if ~predictmode %basic calibrate call
  
  if mdcheck(x);
    if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess". Results may be affected by this action.'); end
    [flag,missmap,x] = mdcheck(x);
  end
  
  %preprocessing
  if ~isempty(options.preprocessing{1});
    [xpp,options.preprocessing{1}] = preprocess('calibrate',options.preprocessing{1},x);
  else
    xpp = x;
  end
  
  %Call als
  opts = options.alsoptions;
  opts.display = 'off';
  opts.plots   = 'none';
  opts.waitbar = options.waitbar;
  [model.loads{1,1},model.loads{2,1}] = als(xpp,iguess,opts);
  
  %als returns row so transpose, also reduce to included variables only
  model.loads{2,1} = model.loads{2,1}(:,xpp.include{2})';
  
  %calc scores for excluded samples
  excluded = setdiff(1:size(xpp,1),xpp.include{1});  %locate excluded samples (if any)
  if ~isempty(excluded)
    %create new x with only the excluded samples
    xpptemp            = xpp(excluded,:);
    xpptemp.include{1} = 1:size(xpptemp,1);   %mark all as "included"
    
    %handle values which are STILL missing by ignoring the samples
    [flag,map] = mdcheck(xpptemp);
    if flag
      bad = find(any(map,2));
      xpptemp = delsamps(xpptemp,bad,1,2);  %hard delete those bad samples
      excluded(bad)  = [];  %and remove them from the excluded list
    end
    
    if ~isempty(excluded)
      %if there is anything that didn't have missing values still there
      optemp       = opts;
      optemp.cc = [];  %don't use c equality constraints
      optemp.itmax = 1;      %force ALS into predict mode
      model.loads{1,1}(excluded,:) = als(xpptemp,model.loads{2,1}',optemp);  %do prediction
    end
    clear xpptemp   %clean up (might be big!)
  end;
  
  %Find number of components returned (might be less than originally requested)
  varargin{2} = size(model.loads{2,1},2);
  
  %***************************************************
  
  model = copydsfields(x,model,[],{1 1});      %copy only mode one labels, etc.
  model.datasource = datasource;
  
  %copy calibrated preprocessing info into model
  model.detail.preprocessing = options.preprocessing;
  
else
  %predict-from-model call (4 inputs)
  
  model   = varargin{4};
  if ~strcmp(lower(model.modeltype),'mcr');
    error('Input MODEL is not an MCR model');
  end
  
  if size(x.data,2)~=model.datasource{1}.size(1,2)
    error('Variables included in data do not match variables expected by model');
  else
    missing = setdiff(model.detail.includ{2,1},x.include{2,1});
    x.data(:,missing) = nan;  %replace expected but missing data with NaN's to force replacement
    x.include{2,1} = model.detail.includ{2,1};%??????????? gives empty field in demo
  end
  
  if mdcheck(x.data(:,x.includ{2,1}));
    if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess" from existing model. Results may be affected by this action.'); end
    x = replacevars(model,x);
  end
  
  %apply preprocessing in model passed in
  options.preprocessing = model.detail.preprocessing;
  if ~isempty(options.preprocessing{1});
    xpp = preprocess('apply',options.preprocessing{1},x);
  else
    xpp = x;
  end
  
  %calc scores for all samples
  xppinclude     = xpp.include{1};
  xpp.include{1} = 1:size(xpp,1);  %include all samples
  
  opts         = options.alsoptions;

  %copy these options from the model to the opts for apply
  tocopy = {'ccon' 'cconind' 'scon' 'sconind' 'closure' 'closurewts' 'condition' 'cblorder' 'sblorder'};
  for f = tocopy;
    opts.(f{:}) = model.detail.options.alsoptions.(f{:});
  end    
  
  opts.display = 'off';
  opts.plots   = 'none';
  opts.waitbar = options.waitbar;
  opts.itmax   = 1;      %force ALS into predict mode
  
  model.loads{1,1} = als(xpp,model.loads{2,1}',opts);  %do prediction
  
  xpp.include{1}   = xppinclude;  %reset back to original include
  
  model = copydsfields(x,model,1,{1 1});      %copy only mode one labels, etc.
  model.datasource = datasource;
  
  %Update time and date.
  model.date = date;
  model.time = clock;
  
end
%copy options into model
model.detail.options = options;

%calculate tsqs & residuals
%X-Block Statistics
model.detail.data{1}    = x;
model.pred{1}           = model.loads{1,1}*model.loads{2,1}';
model.detail.res{1}     = xpp.data(:,model.detail.includ{2,1}) - model.pred{1};
model.ssqresiduals{1,1} = model.detail.res{1}.^2;
model.ssqresiduals{2,1} = sum(model.ssqresiduals{1,1}(model.detail.includ{1,1},:),1); %var SSQs based on cal samples only
model.ssqresiduals{1,1} = sum(model.ssqresiduals{1,1},2);    %sample SSQs for ALL samples (excluded vars already gone)

if ~predictmode;   %use EXISTING limit if standard predict mode
  %calculate residual eigenvalues using raw residuals matrix
  [model.detail.reslim{1,1}, model.detail.reseig] = residuallimit(model.detail.res{1}(model.detail.includ{1,1},:), options.confidencelimit);
end

if ~predictmode;
  %calculate SSQ table
  %calculate % signal by factor
  for j=1:size(model.loads{1},2);
    sig(j) = sum(sum((model.loads{1}(model.detail.includ{1,1},j)*model.loads{2}(:,j)').^2));
  end
  sig = normaliz(sig,[],1);  %normalize to 100%
  uncap = sum(sum(model.detail.res{1}(model.detail.includ{1,1},:).^2))./sum(sum(xpp.data(xpp.include{1},xpp.include{2}).^2));
  if uncap>=1;
    uncap = 0;
  end
  
  model.detail.ssq = [[1:size(model.loads{1},2)]' sig'*100 (1-uncap)*sig'*100 cumsum((1-uncap)*sig')*100];
  
  switch options.display
    case 'on'
      ssqtable(model)
  end
end

%***NEEDS TO BE REVISED FROM PCA APPROACH

%   model.tsqs{1,1}          = sum((model.loads{1,1}*diag(f)).^2,2);
%   model.tsqs{2,1}          = sum(model.loads{2,1}.^2,2)'*(length(model.detail.includ{2,1})-1);

if ~predictmode;   %use EXISTING limit if standard predict mode
  if length(model.detail.includ{1,1})>varargin{2};
    model.detail.tsqlim{1,1} = tsqlim(length(model.detail.includ{1,1}),varargin{2},options.confidencelimit*100);
  else
    model.detail.tsqlim{1,1} = 0;
  end
end

if predictmode
  model.detail.rmsec  = [];
  model.detail.rmsecv = [];
  model.detail.cv     = '';
  model.detail.split  = [];
  model.detail.iter   = [];
end

%test for Compact Blockdetails with calibrate mode
if ~predictmode & strcmp(options.blockdetails,'compact')
  options.blockdetails = 'standard';
end

%label as prediction
if predictmode
  model.modeltype = [model.modeltype '_PRED'];
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
        plotscores(varargin{4},model);
      end
  end
catch
  warning('EVRI:PlottingError',lasterr)
end


%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab           datatype        valid                            userlevel       description
'display'                'Display'     'select'        {'on' 'off'}                     'novice'        'Governs level of display.';
'plots'                  'Display'     'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
'preprocessing'          'Standard'    'matrix'        ''                               'novice'        'Preprocessing structure (see PREPROCESS).';
'blockdetails'           'Standard'    'select'        {'standard' 'all'}               'novice'        'Governs extent of predictions and raw residuals included in model. ''standard'' = none, ''all'' x-block.';
'initmode'               'Standard'    'select'        {1 2}                            'novice'        'Mode of x to use for automatic initialization: 1 = start with purest samples, 2 = start with purest variables.';
'confidencelimit'        'Standard'    'double'        'float(0:1)'                     'novice'        'Confidence level for Q limit (fraction between 0 and 1)';
'alsoptions'             'Standard'    'struct'        ''                               'advanced'      'Options for ALS.'

};
options.rmlist = {'display' 'plots'};
defs = adoptdefinitions(defs,'als','alsoptions', options);
out = makesubops(defs);
