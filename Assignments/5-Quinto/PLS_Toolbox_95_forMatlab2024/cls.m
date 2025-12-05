function varargout = cls(varargin)
%CLS Classical Least Squares regression for multivariate Y.
%  CLS identifies models of the form y = Xb + e.
%  INPUT:
%        x  = X-block: predictor block (2-way array or DataSet Object),
%
%  OPTIONAL INPUTS:
%        y  = Y-block: predicted block (2-way array or DataSet Object). The
%              number of columns of y indicates the number of components in
%              the model (each row specifies the mixture present in the
%              given sample).
%              If y is omitted, x is assumed to be a set of pure component
%              responses (e.g., spectra) defining the model.
%   options = structure array with the following fields:
%           display: [ 'off' | {'on'} ]      governs level of display to command window.
%             plots: [ 'none' | {'final'} ]  governs level of plotting.
%     preprocessing: { [] [] }               preprocessing structure (see PREPROCESS).
%                    If length(preprocessing)==1, then the preprocessing is
%                    duplicated for both x and y.
%         algorithm: [ {'ls'} | 'nnls' | 'snnls' | 'cnnls' | 'stepwise' | 'stepwisennls' ]
%                     Specifies the regression algorithm. Options are:
%                     ls = a standard least-squares fit
%                     snnls = non-negative least squares on spectra (S) only
%                     cnnls = non-negative least squares on concentrations (C) only
%                     nnls = non-negative least squares fit on both C and S
%                     stepwise = stepwise least squares
%                     stepwisennls = stepwise non-negative least squares
%   confidencelimit: [{0.95}] Confidence level for Q and T2 limits. A value
%                     of zero (0) disables calculation of confidence
%                     limits.
%      blockdetails: [ {'standard'} | 'all' ]   Extent of predictions and raw residuals
%                     included in model. 'standard' = only y-block, 'all' x and y blocks
%
%  OUTPUT:
%     model = standard model structure containing the CLS model (See MODELSTRUCT)
%      pred = structure array with predictions
%     valid = structure array with predictions
%
%I/O: model = cls(x,options);          %identifies model (calibration step)
%I/O: model = cls(x,y,options);        %identifies model (calibration step)
%I/O: pred  = cls(x,model,options);    %makes predictions with a new X-block
%I/O: valid = cls(x,y,model,options);  %makes predictions with new X- & Y-block
%
%See also: ANALYSIS, PCR, PLS, PREPROCESS, STEPWISE_REGRCLS, TESTROBUSTNESS

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 5/7/04 created from PCR.m

%Start Input
if nargin==0  % LAUNCH GUI
  analysis cls
  return
end
if ischar(varargin{1}) %Help, Demo, Options
  
  options = [];
  options.display       = 'on';     %Displays output to the command window
  options.plots         = 'final';  %Governs plots to make
  options.preprocessing = {[] []};  %See preprocess
  options.confidencelimit = 0.95;
  options.algorithm     = 'ls';    %use least-squares algorithm
  options.blockdetails  = 'standard';  %level of details
  options.definitions   = @optiondefs;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
  
end

%A) Check Options Input
predictmode = 0;    %default is calibrate mode

%NOTE: the following code will always leave varargin{3} empty because we
%infer this value from the y-block. (ncomp isn't an input option for cls)
switch nargin
  case 1 %one input
    % (x)   calibrate: y assumed to be diag(ones)
    varargin = {varargin{1},[],[],[],[]};
  case 2  %two inputs
    % (x,y)         calibrate
    % (x,model)     predict
    % (x,options)   calibrate: y assumed = diag(ones)
    if ismodel(varargin{2})
      %model
      varargin = {varargin{1},[],[],[],varargin{2}};
    elseif isa(varargin{2},'struct')
      %options
      varargin = {varargin{1},[],[],varargin{2},[]};
    else
      % (x,y)
      varargin = {varargin{1},varargin{2},[],[],[]};
    end
    
  case 3  %three inputs
    % (x,y,options)  calibrate
    % (x,y,model)    predict (test)
    % (x,model,options)   predict (test)
    
    if ismodel(varargin{2});
      % (x,model,options)
      varargin = {varargin{1},[],[],varargin{3},varargin{2}};
    elseif ~ismodel(varargin{3});
      % (x,y,options)
      varargin = {varargin{1},varargin{2},[],varargin{3},[]};
    else
      % (x,y,model)
      varargin = {varargin{1},varargin{2},[],[],varargin{3}};
    end
    
  case 4   %four inputs
    % (x,y,model,options)
    
    if ~ismodel(varargin{3})
      % (x,y,NCOMP,options) ?!? ignore ncomp
      varargin = {varargin{1},varargin{2},[],varargin{4},[]};
    else
      varargin = {varargin{1},varargin{2},[],varargin{4},varargin{3}};
    end
    
  otherwise
    error('Unrecognized input format')
    
end
%At this point, varargin will be 5 elements:
%  {x, y, [], options, model}
% where y, options, and model can all be empty

options = reconopts(varargin{4},cls('options'));
ispurespectracase = false;

options.blockdetails = lower(options.blockdetails);
if ~ismember(options.blockdetails,{'compact','standard','all'})
  error(['OPTIONS.BLOCKDETAILS not recognized. Type: ''help ' mfilename ''''])
end

%B) check model format
if ~isempty(varargin{5})
  try
    if ~isfield(varargin{5},'detail')
      varargin{5} = updatemod(varargin{5});        %make sure it's v3.0 model
    end
  catch
    error(['Input MODEL not recognized. Type: ''help ' mfilename ''''])
  end
  predictmode = 1;                                  %and set predict mode flag
end

%C) CHECK Data Inputs
[datasource{1:2}] = getdatasource(varargin{1:2});
if isa(varargin{1},'double')      %convert varargin{1} and varargin{2} to DataSets
  varargin{1}        = dataset(varargin{1});
  varargin{1}.name   = inputname(1);
  varargin{1}.author = 'CLS';
elseif ~isa(varargin{1},'dataset')
  error(['Input X must be class ''double'' or ''dataset''.'])
end
if ndims(varargin{1}.data)>2
  error(['Input X must contain a 2-way array. Input has ',int2str(ndims(varargin{1}.data)),' modes.'])
end

if isempty(varargin{2})
  if isempty(varargin{5});
    %no model? assume y is the identity matrix
    ispurespectracase = true;
    varargin{2} = dataset(eye(size(varargin{1},1))); %assumed to have same number of components as x rows
    varargin{2}.name = 'Pure Component Identity Matrix';
    varargin{2}.author = 'CLS';
    incl = varargin{1}.include{1};
    varargin{2}.include{1} = incl;
    varargin{2}.include{2} = incl;
    
    if iscell(options.preprocessing) && length(options.preprocessing)==2
      options.preprocessing{2} = [];  %clear all preprocessing on y-block
    end
    %copy labels from X rows to Y columns
    for sets = 1:size(varargin{1}.label,2)
      varargin{2}.label{2,sets} = varargin{1}.label{1,sets};
    end
    
  end
end
if ~isempty(varargin{2})
  haveyblock = 1;
  if isa(varargin{2},'double') | isa(varargin{2},'logical')
    varargin{2}        = dataset(varargin{2});
    varargin{2}.name   = inputname(2);
    varargin{2}.author = 'CLS';
  elseif ~isa(varargin{2},'dataset')
    error(['Input Y must be class ''double'', ''logical'' or ''dataset''.'])
  end
  if isa(varargin{2}.data,'logical')
    varargin{2}.data = double(varargin{2}.data);
  end
  if ndims(varargin{2}.data)>2
    error(['Input Y must contain a 2-way array. Input has ',int2str(ndims(varargin{2}.data)),' modes.'])
  end
  if size(varargin{1}.data,1)~=size(varargin{2}.data,1)
    error('Number of samples in X and Y must be equal.')
  end
  %Check include fields of X and Y
  i       = intersect(varargin{1}.include{1},varargin{2}.include{1});
  if ( length(i)~=length(varargin{1}.include{1,1}) | ...
      length(i)~=length(varargin{2}.include{1,1}) )
    if (strcmp(lower(options.display),'on')|options.display==1)
      disp('Warning: Number of samples in X.INCLUDE{1} and Y.INCLUDE{1} not equal.')
      disp('Using INTERSECT(X.INCLUDE{1},Y.INCLUDE{1}).')
    end
    varargin{1}.include{1,1} = i;
    varargin{2}.include{1,1} = i;
  end
  %Change include fields in y dataset. Confirm there are enough y columns
  %before trying.
  if ~isempty(varargin{5})
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
else    %empty y (assumed predict mode)
  haveyblock = 0;
end

%D) Check Meta-Parameters Input
if isempty(varargin{5})
  if haveyblock
    ncomp = length(varargin{2}.include{2});
  else
    ncomp = length(varargin{1}.include{1});
  end
else
  ncomp = size(varargin{5}.loads{2,1},2);
end

%----------------------------------------------------------------------------------------
x = varargin{1};
y = varargin{2};

if isempty(options.preprocessing)
  options.preprocessing = {[] []};  %reinterpet as empty for both blocks
end
if ~isa(options.preprocessing,'cell')
  options.preprocessing = {options.preprocessing};
end
if length(options.preprocessing)==1
  options.preprocessing = options.preprocessing([1 1]);
end

preprocessing = options.preprocessing;

if ~predictmode
  
  if mdcheck(x)
    if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess". Results may be affected by this action.'); end
    [flag,missmap,x] = mdcheck(x);
    if length(y.include{1}) ~= length(x.include{1})
      %copy any changes over to y-block
      y.include{1} = x.include{1};
    end
  end
  
  if ~isempty(preprocessing{2})
    [ypp,preprocessing{2}] = preprocess('calibrate',preprocessing{2},y);
  else
    ypp = y;
  end
  if ~isempty(preprocessing{1})
    [xpp,preprocessing{1}] = preprocess('calibrate',preprocessing{1},x,ypp);
  else
    xpp = x;
  end
  
  if length(ypp.include{2})>length(xpp.include{2})
    error('X-block variables must be greater than number of components');
  end
  
  %Call cls Function
  model = clsregression(xpp,ypp,ncomp,options);
  model.datasource = datasource;
  model.detail.preprocessing = preprocessing;   %copy calibrated preprocessing info into model
  
else
  
  model = varargin{5};
  if ~strcmpi(model.modeltype,'cls')
    error('Input MODEL is not a CLS model');
  end
  
  if size(x.data,2)~=model.datasource{1}.size(1,2)
    error('Variables included in data do not match variables expected by model');
  elseif length(x.include{2,1})~=length(model.detail.includ{2,1}) | any(x.include{2,1} ~= model.detail.includ{2,1});
    missing = setdiff(model.detail.includ{2,1},x.include{2,1});
    x.data(:,missing) = nan;  %replace expected but missing data with NaN's to force replacement
    x.include{2,1} = model.detail.includ{2,1};
  end
  
  if mdcheck(x.data(:,x.include{2,1}))
    if strcmp(options.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess" from existing model. Results may be affected by this action.'); end
    x = replacevars(model,x);
  end
  
  preprocessing = model.detail.preprocessing;   %get preprocessing from model
  options.algorithm = model.detail.options.algorithm;   %get algorithm from model
  if haveyblock & ~isempty(preprocessing{2})
    [ypp]                           = preprocess('apply',preprocessing{2},y);
  else
    ypp = y;
  end
  if ~isempty(preprocessing{1})
    [xpp]                           = preprocess('apply',preprocessing{1},x);
  else
    xpp = x;
  end
  
  model = copydsfields(x,model,[1],{1 1});
  model.detail.includ{1,2} = x.include{1};
  model.datasource = datasource;
  %Update time and date.
  model.date = date;
  model.time = clock;
  
end

%copy options into model
model.detail.options = options;

%fill in for all mode 1 sample values (in addition to the .include field)
%calculate tsqs, residuals, scores for non-included samples.

%X-Block Statistics
switch lower(options.algorithm)
  case {'nnls' 'cnnls'}
    model.loads{1,1}  = fastnnls(model.loads{2,1},xpp.data(:,model.detail.includ{2,1})')';
  case {'stepwise' 'stepwisennls'}
    swopts = [];
    swopts.display = 'off';
    swopts.automate = 'yes';
    swopts.fstat = options.confidencelimit;
    if strcmpi(options.algorithm,'stepwisennls')
      swopts.ccon = 'fasternnls';
    else
      swopts.ccon = 'none';
    end
    model.loads{1,1}  = stepwise_regrcls(xpp.data(:,model.detail.includ{2,1}),model.loads{2,1}',swopts);
  otherwise
    model.loads{1,1} = xpp.data(:,model.detail.includ{2,1})/model.loads{2,1}';
end
model.detail.data{1}  = x;
model.pred{1}         = model.loads{1,1}*model.loads{2,1}';
model.detail.res{1}   = xpp.data(:,model.detail.includ{2,1}) - model.pred{1};
model.ssqresiduals{1,1} = model.detail.res{1}.^2;
model.ssqresiduals{2,1} = sum(model.ssqresiduals{1,1}(model.detail.includ{1,1},:),1); %based on cal samples only
model.ssqresiduals{1,1} = sum(model.ssqresiduals{1,1},2); %residuals for ALL samples

if ~predictmode
  %calculate residual eigenvalues using raw residuals matrix
  if ~ispurespectracase
    if options.confidencelimit>0
      [model.detail.reslim{1,1}, model.detail.reseig] = residuallimit(model.detail.res{1}(model.detail.includ{1,1},:), options.confidencelimit);
    else
      model.detail.reslim{1,1} = 0;
    end
  else
    if options.confidencelimit>0
      model.detail.reslim{1,1} = NaN;
      model.detail.reseig = [];
    else
      model.detail.reslim{1,1} = 0;
    end
  end
end

if ~predictmode
  %calculate SSQ table
  %calculate % signal by factor
  for j=1:size(model.loads{1},2)
    sig(j) = sum(sum((model.loads{1}(model.detail.includ{1,1},j)*model.loads{2}(:,j)').^2));
  end
  sig = normaliz(sig,[],1);  %normalize to 100%
  uncap = sum(sum(model.detail.res{1}(model.detail.includ{1,1},:).^2))./sum(sum(mncn(xpp.data(xpp.include{1},xpp.include{2})).^2));
  
  if uncap>=1  %happens with really bad fits (e.g. poor constraints or badly processed data)
    uncap = sum(sum(model.detail.res{1}(model.detail.includ{1,1},:).^2))./sum(sum(xpp.data(xpp.include{1},xpp.include{2}).^2));
  end
  if uncap>=1
    uncap = 0;
  end
  
  model.detail.ssq = [[1:size(model.loads{1},2)]' sig'*100 (1-uncap)*sig'*100 cumsum((1-uncap)*sig')*100];
  
  switch options.display
    case 'on'
      ssqtable(model)
  end
end


if ~predictmode
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

%     if ~predictmode;
%       if options.confidencelimit>0
%         model.detail.tsqlim{1,1} = tsqlim(length(model.detail.includ{1,1}),ncomp,options.confidencelimit*100);
%       else
%         model.detail.tsqlim{1,1} = 0;
%       end
%     else
%       model.tsqs(:,2) = {[];[]};
%     end

%Y-Block Statistics
%store original and predicted Y values
model.detail.data{1,2}   = y;
ypred                    = model.loads{1,1};  %scores ARE prediction (except they need to be un-preprocessed)
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
  warning('EVRI:ClsPlottingError',lasterr)
end

%End Input

%-----------------------------------------------------------------------
%Functions
function model = clsregression(x,y,pc,options)
%call model = clsregression(xpp,ypp,ncomp,options);

m       = length(x.include{1,1});  %= y.include{1}
nx      = length(x.include{2,1});
ny      = length(y.include{2,1});
% if (nx<pc)
%   error('Number of PCs must be <= number of X-block variables.')
% end

model            = modelstruct('cls');

model.date       = date;
model.time       = clock;
model.loads{1,1} = zeros(m,pc);  %X-block scores   't'
model.loads{2,1} = zeros(nx,pc); %X-block loadings 'p'
model.detail.ssq = zeros(pc,5);  %sum of squares info
model.detail.means{1,1}  = NaN*ones(1,size(x.data,2));
model.detail.means{1,2}  = NaN*ones(1,size(y.data,2));
model.detail.means{1,1}(1,x.include{2}) = ...
  mean(x.data(x.include{1},x.include{2})); %mean of X-block
model.detail.means{1,2}(1,y.include{2}) = ...
  mean(y.data(y.include{1},y.include{2})); %mean of Y-block
model.detail.stds{1,1}   = NaN*ones(1,size(x.data,2));
model.detail.stds{1,2}   = NaN*ones(1,size(y.data,2));
model.detail.stds{1,1}(1,x.include{2}) = ...
  std(x.data(x.include{1},x.include{2})); %std of X-block
model.detail.stds{1,2}(1,y.include{2}) = ...
  std(y.data(y.include{1},y.include{2})); %std of Y-block

model = copydsfields(x,model,[],{1 1});
model = copydsfields(y,model,[],{1 2});

if ~all([length(x.include{1}) length(x.include{2})] == size(x.data));
  xsub = x.data(x.include{1},x.include{2});
else
  xsub = x.data;
end
if ~all([length(y.include{1}) length(y.include{2})] == size(y.data));
  ysub = y.data(y.include{1},y.include{2});
else
  ysub = y.data;
end

if strcmpi(options.algorithm,'ls') && rank(xsub)<size(ysub,2)
  if size(ysub,1)>size(ysub,2)
    error(['Insufficient unique variables for number of components (' num2str(size(ysub,2)) ').'])
  else
    error('Insufficient unique samples found. Check for duplicate samples.')
  end
end

switch lower(options.algorithm)
  case {'nnls' 'snnls'}
    loads  = fastnnls(ysub,xsub);
  otherwise
    loads  = ysub\xsub;
end

model.loads      = {[];loads'};


%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab              datatype        valid                            userlevel       description
'display'                'Display'        'select'        {'on' 'off'}                     'novice'        'Governs level of display.';
'plots'                  'Display'        'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
'preprocessing'          'Standard'       'cell(vector)'  ''                               'novice'        'Preprocessing structures. Cell 1 is preprocessing for X block, Cell 2 is preprocessing for Y block.';
'algorithm'              'Standard'       'select'        {'ls' 'nnls' 'snnls' 'cnnls' 'stepwise' 'stepwisennls'} 'novice'        'ls = a standard least-squares fit, snnls = non-negative least squares on spectra (S) only, cnnls = non-negative least squares on concentrations (C) only, nnls = non-negative least squares fit on both C and S, stepwise = stepwise least squares, stepwisennls = stepwise non-negative least squares';
'blockdetails'           'Standard'       'select'        {'standard' 'all'}               'novice'        'Extent of predictions and raw residuals included in model. ''standard'' = keeps only y-block, ''all'' keeps both x- and y- blocks.';
'confidencelimit'        'Standard'       'double'        'float(0:1)'                     'novice'        'Confidence level for Q and T2 limits (fraction between 0 and 1)';
};

out = makesubops(defs);

