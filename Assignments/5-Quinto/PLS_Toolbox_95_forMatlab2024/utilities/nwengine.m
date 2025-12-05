function model = nwengine(x,modeltype,standardoptions,xsize,order,varargin);

%NWENGINE For fitting multilinear decomposition models.
%  Utility for multi-way models (see those)
%
%See also: PARAFAC, PARAFAC2, TUCKER

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.



% 2003,mar,rb, Added several nonneg algorithms
%   Removed 'exotic' exponential constraints. They will be incorporated as general functional constraints instead
%   Added check for nonnegativity when convergence is reached. The algorithm switches to another nonneg-algorithm if convergence has been reached without fulfilling the restriction.
% 2003, april, rb, Fixed that model is still output if plotting is aborted
% 2003, May, Rb, added initialization method in model.detail.initialization
% 2003, May, Rb, added .plots='all', plotting loadings while iterating
% 2003, June, RB, added a message if options.constraints are not of proper length (number of modes)
% 2003, aug, RB, fixed minore bug in error message when too many components in T3 models.
% 2003, Nov, RB, Changed so that too many modes in the constraints field are ignored
% 2003, Nov, RB, Changed so that too few modes in the constraints field are padded with default constraints
% 2003, Dec, RB, fixed error so that tucker(model) works now
% 2003, Dec, RB, fixed error for tucker with single components in one mode
% 2004, Apr, RB, Made waitbar independent of plotoptions
% 2004, Jun, RB, Made fitting stopable from waitbar
% 2004, Jun, RB, Introduced compressed fitting as initialization
% 2004, Aug, RB, fixed error in prediction w. PF2 when not using default samplemode
% 2004, Sept, RB, fixed constrained core array
% 2005, Jan, RB, fixed bug in line-search, speeding it up dramatically
% 2005, Feb, RB, updated implementation of fixed loadings constraint
% 2005, Mar, RB, enabled compact mode skipping residual limits
% 2005, Apr, RB, change loss function in iteration-eval and linesearch to LAE when all modes are constrained to LAE
% 2005, Apr, RB, added percentage variation explained in .detail.ssq.perc
% 2005, Apr, RB, fixed error in core calculation when last mode dim 1
% 2007, May, RB, Added an error if samplemode = 1 chosen for PF2 (should not work)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% To be done
% Make cross-product formulation of regress for speedup (esp. T3)
% make T2, T1
% Make sure aux (functional constraints) are output during PARAFAC2

warning off backtrace
% warning off MATLAB:divideByZero
if nargin==0
  error(' NWENGINE is a utility function. Please use PARAFAC, TUCKER or PARAFAC2 to fit multi-way models')
end

% Define standard options etc.
Show = 100; % How often are fit values shown
aux = cell(1,order); % For storing additional information in different modes.
standardtol = standardoptions.stopcrit;
timespent0 = clock;timespent = 0;

% Save raw data for plotting etc. (because the data will be modified, e.g. if there are missing elements)
Xsdo = x;
if isa(x,'dataset')% Then it's a SDO
  inc=x.includ;            
  x = x.data(inc{:});
else
  try
    Xsdo = dataset(Xsdo);
  end
end

if ismodel(x) & strcmpi(x.modeltype,'parafac') % Then it's a SDO
  if ~isempty(varargin)
    inc=x.includ;            
    x = x.data(inc{:});
  else  % The input is a model where the SSQ table is wanted 
    x = x.detail.ssq.percomponent;
    % SCREEN OUTPUT
    disp('  ')
    disp('   Percent Variation Captured by Components of PARAFAC Model')
    disp('  ')
    labl = x.label{2};
    titl1 = ['    LV    ', labl(1,:) ,'      ', labl(2,:) labl(3,:) ];
    disp(titl1)
    disp(' ')
    ssq = [(1:size(x.data,1))' x.data(:,[1:3])];
    format = '   %3.0f     %15.2f          %7.2f              %7.2f';
    for i = 1:size(x.data,1)
      tab = sprintf(format,ssq(i,:)); disp(tab)
    end
    
    disp('  ')
    disp('   Unique Variation Captured by Components of PARAFAC Model')
    disp('  ')
    labl = x.label{2};
    titl1 = ['    LV    ', labl(4,:) ,'      ', labl(5,:) labl(6,:)];
    disp(titl1)
    disp(' ')
    ssq = [(1:size(x.data,1))' x.data(:,[4:6])];
    format = '   %3.0f     %15.2f          %7.2f              %7.2f';
    for i = 1:size(x.data,1)
      tab = sprintf(format,ssq(i,:)); disp(tab)
    end
    model=[];
    return
  end
elseif ismodel(x) & (strcmpi(x.modeltype,'tucker') | strcmpi(x.modeltype,'tucker - rotated')) % Then it's a SDO
  model = x.detail.ssq.percomponent;
  disp(model)
  return   
end

if isempty(varargin)
  error([upper(modeltype),' requires at least two inputs'])
  return 
end
if length(varargin) == 1
  if nargout == 0
    switch lower(x)
      case {'weights', 'options', 'constraints', 'initval', 'init', 'help'}
        if exist([fileparts(which(modeltype)) '\help\' modeltype '.htm'],'file')
          web([fileparts(which(modeltype)) '\help\' modeltype '.htm#' x]) 
        else
          disp(['Help on ',modeltype,' not found. May not be loaded.']) 
        end
      case 'io'
        switch lower(modeltype)
          case 'parafac'
            disp(' PARAFAC Parallel factor analysis for n-way arrays - short help')
            disp(' I/O: model = parafac(x,nocomp,initval,options);')
            disp(' Type HELP PARAFAC for extended help')
          case 'tucker'
            disp(' TUCKER analysis for n-way arrays - short help')
            disp(' I/O: model = tucker(x,nocomp,initval,options);')
            disp(' Type HELP TUCKER for extended help')
          case 'parafac2'
            disp(' PARAFAC2 analysis for n-way arrays - short help')
            disp(' I/O: model = parafac2(x,nocomp,initval,options);')
            disp(' Type HELP PARAFAC2 for extended help')
          otherwise
            error(' Modeltype unknown - 1')
        end
        
      case 'demo'   %Call Demo Function
        if exist([fileparts(which(modeltype)) '\dems\' modeltype 'demo.m'],'file')
          txt=[fileparts(which(modeltype)) '\dems\' modeltype 'demo.m'];
          eval(['run (''',txt,''')'])
        else
          disp(['Demo for ',modeltype,' not found. May not be loaded.'])
        end
      case 'options'
        disp(['web link to ' upper(modeltype) ' HELP OPTIONS not yet available.'])
      otherwise
        error(' ')
    end
    return
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INITIALIZATION OF ALGORITHM
pfmodel = 0; % Define if PF2 not fitted
% Check if options were given as third input instead of fourth and use that instead
if length(varargin)>1
  if ~ismodel(varargin{2}) & isstruct(varargin{2})
    varargin{3} = varargin{2};
    varargin{2} = [];
  end
end


% Check if second input is model instead of components (and set it to be
% the third input (varargin{2}) and compute nocomp and set that to the second(varargin{1}))
if ~isempty(varargin)
  if ismodel(varargin{1})
    varargin{2} = varargin{1};
    % Then nocomp is not given and needs to be defined
    switch lower(modeltype)
      case {'tucker','tucker - rotated'}
        for i=1:length(size(varargin{2}.loads))-1
          nocomp(i) = size(varargin{2}.loads{i},2);
        end
      case {'parafac','parafac2'}
        nocomp = size(varargin{2}.loads{2},2);
    end
    varargin{1} = nocomp;
  elseif iscell(varargin{1}) % Cell of loads
    varargin{2} = varargin{1};
    % Then nocomp is not given and needs to be defined
    switch lower(modeltype)
      case {'tucker','tucker - rotated'}
        for i=1:length(varargin{2})-1
          nocomp(i) = size(varargin{2}{i},2);
        end
      case {'parafac','parafac2'}
        nocomp = size(varargin{2}{2},2);
    end
    varargin{1} = nocomp;
  end
end
nocomp = varargin{1};

% Check if old model is given. If so, the order may be wrongly determined when only one new sample is input
if length(varargin)>1
  if ismodel(varargin{2})
    if strcmpi(varargin{2}.modeltype,modeltype) % Then it's a model struct
      if strcmpi(modeltype,'tucker')||strcmpi(modeltype,'tucker - rotated')
        ord = length(varargin{2}.loads)-1;
        for i=1:ord
          nocomp(i) = size(varargin{2}.loads{i},2);
        end
      elseif strcmpi(modeltype,'parafac')||strcmpi(modeltype,'parafac2')
        ord = length(varargin{2}.loads);
        nocomp = size(varargin{2}.loads{2},2);
      else
        error(' Unknown modeltype in NWENGINE')
      end
      if order==ord-1;
        order = ord;
        xsize = [xsize 1];
      elseif order ~=ord
        error(' Disagreement between order in input model and size of input data')
      end
    end
  elseif iscell(varargin{2}) % Then it may be a cell used inside PARAFAC2 when modeling with parafac
    if strcmpi(modeltype,'parafac')
      ord = length(varargin{2});
      nocomp = size(varargin{2}{2},2);
      if order==ord-1;
        order = ord;
        xsize = [xsize 1];
      elseif order ~=ord
        error(' Disagreement between order in input model and size of input data')
      end
    end
  end
end

% Chk noncomp correctly defined and initialize specific metaparameters
if strcmpi(modeltype,'tucker')
  if any(rem(nocomp,1))~=0
    error(' The input for the number of components must be integers in TUCKER')
  end
  if length(nocomp)~=length(xsize)
    error([' In TUCKER components must be specified for each mode, e.g. [2 4 ',num2str(3*ones(1,length(xsize)-2)),']'])
  end
  for i=1:order
    if prod(nocomp)/nocomp(i)<nocomp(i)&&nocomp(i)==max(nocomp(:));
      nocomp(i)= prod(nocomp)/nocomp(i);
      warning('EVRI:NwengineNcompLimit',[' Components in mode ',num2str(i),' has been set to ',num2str(nocomp(i)),' as additional components will not add to the fit'])
    end
  end
  
  if any(nocomp(:)>xsize(:))
    m = find(nocomp(:)>xsize(:));
    if length(m)>1
      warning('EVRI:NwengineNcompLimit',[' The number of components in modes ',num2str(m(:)'),' exceed the dimension of those modes'])
    else
      warning('EVRI:NwengineNcompLimit',[' The number of components in mode ',num2str(m),' exceed the dimension of that mode'])
    end
  end
  
elseif strcmpi(modeltype,'parafac')||strcmpi(modeltype,'parafac2')
  
  if length(nocomp)~=1||rem(nocomp,1)~=0
    error([' The input for the number of components must be an integer in ',upper(modeltype)])
  end
  
else
  error('Modeltype not defined in NWENGINE - 2')
end

% Define if predicting or fitting new model
predictmode = 0;
if length(varargin)>1
  if ismodel(varargin{2})
    if strcmpi(varargin{2}.modeltype,modeltype) % Then it's a model struct
      predictmode = 1;
    end
  end
else 
  varargin{2}=[]; % Because varargin{2} is input to makemodel.m in the end
end

% If predict, make sure include field of calibration is applied to new data
if predictmode
    for i=1:ord
        if i~=varargin{2}.detail.options.samplemode
            if length(Xsdo.include{i,1})~=length(varargin{2}.detail.includ{i,1}) ...
                    || any(Xsdo.includ{i,1} ~= varargin{2}.detail.includ{i,1});
                Xsdo.includ{i,1} = varargin{2}.detail.includ{i,1};
                xsize(i)=length(varargin{2}.detail.includ{i,1});
                inc=Xsdo.includ;
                x = x(inc{:});
            end
        end
    end
end

% Set options
options = [];  %default is empty unless we find otherwise
if length(varargin)>1
  if ismodel(varargin{2})
    % Take options from prior model if it exist (but exchange with input options if such are given)
    try
      options = varargin{2}.detail.options;
      if strcmpi(modeltype,'parafac')||strcmpi(modeltype,'parafac2')
        nocomp = size(varargin{2}.loads{2},2);
      elseif strcmpi(modeltype,'tucker')
        for i=1:length(varargin{2}.loads)-1
          nocomp(i) = size(varargin{2}.loads{i},2);
        end
      end
    end
  elseif iscell(varargin{2})
    % Then it's a cell. Find nocomp from that
    if strcmpi(modeltype,'parafac')||strcmpi(modeltype,'parafac2')
      nocomp = size(varargin{2}{2},2);
    elseif strcmpi(modeltype,'tucker')
      for i=1:length(varargin{2})-1
        nocomp(i) = size(varargin{2}{i},2);
      end
    end
  end
end

if length(varargin)<3 & isempty(options)
  options = standardoptions;
elseif length(varargin)>2
  options = varargin{3};
end

% Add any missing fields in options
if ~ismember(lower(modeltype),{'parafac' 'tucker' 'parafac2'})
  error('Modeltype not defined in NWENGINE - 2.5')
end
options = reconopts(options,lower(modeltype));

% Chk if samplemode = 1 in parafac2 give error (should not work)
if strcmpi(modeltype,'parafac2')
    if options.samplemode==1
        error(' Sample mode (in model options) can not be set to first mode in PARAFAC2')
    end
end

% Add scaletype because it's only given for parafac
try
  options.scaletype.value;
catch
  options.scaletype.value = 'norm';
end
    

%Handle Preprocessing
try
  if isempty(options.preprocessing);
    options.preprocessing = {[]};  %reinterpet as empty cell
  end
  if ~isa(options.preprocessing,'cell');
    options.preprocessing = {options.preprocessing};  %insert into cell
  end
catch
  options.preprocessing = {[]};  %reinterpet as empty cell
end


if strcmpi(modeltype,'parafac')||strcmpi(modeltype,'parafac2')
  if length(options.constraints)<order % wrong number of constraints
    for i=length(options.constraints)+1:order
      options.constraints{i}=standardoptions.constraints{1};
    end
    if strcmpi(options.display,'on')
      disp(' Constraints not properly defined (not defined for all modes) - adding defaults for missing constraints')
    end
  end
elseif strcmpi(modeltype,'tucker')||strcmpi(modeltype,'tucker - rotated')
  if length(options.constraints)<order+1 % wrong number of constraints
    oo = options.constraints{end}; % For the last mode (core)
    for i=length(options.constraints):order
      options.constraints{i}=standardoptions.constraints{1};
    end
    options.constraints{order+1}=oo;
    if strcmpi(options.display,'on')
      disp(' Constraints not properly defined (not defined for all modes + core) - using defaults for missing constraints')
    end
    
  end
else
  error('Modeltype not properly defined in NWENGINE')
end

if length(varargin)>1
  x0 = varargin{2};
end

DumpToScreen = options.display;
if strcmpi(DumpToScreen,'on')
  DumpToScreen = 1;
else
  DumpToScreen = 0;
end

plots = options.plots;
if strcmpi(plots,'on')||strcmpi(plots,'final')
  plots = 1;
elseif strcmpi(plots,'all')
  plots = 2;
else
  plots = 0;
end
constraints = options.constraints;
% For standard options through parafac(options), the order of X unknown hence dimension 
% of constraints may be wrong. This is corrected below
if length(constraints)~=order
  for i=length(constraints)+1:order
    constraints{i}=constraints{i-1};
  end
end
alllae = 0; % binary for checking LAE fitting
cou = 0;
for i = 1:order
  try
    if constraints{i}.lae
    cou = cou+1;
    end
  end
end
if cou==order
  alllae=1;
end

if ~ismember(options.blockdetails,{'compact','standard','all'})
  error(['OPTIONS.BLOCKDETAILS not recognized. Type: ''help ' modeltype ''''])
end


weights = options.weights;
if length(size(weights))~=order 
  DoWeight = 0;
elseif all(size(weights)==xsize)
  DoWeight = 1;
  WMax     = max(abs(weights(:)));
  W2       = weights.*weights;
else
  DoWeight = 0;
end

if strcmpi(weights,'iterative')
  DoWeight = 1;
  weights  = ones(xsize);
  oldweights = weights;
  WMax     = max(abs(weights(:)));
  W2       = weights.*weights;
  iter_rew = 1;
  iter_w_conv = sum(weights(:).^2);
else
  iter_rew = 0;
end

tol = options.stopcrit;
if isempty(tol)
  tol = standardtol;
else 
  tol(find(tol==0)) = standardtol(find(tol==0));
end
tol = [tol standardtol(length(tol)+1:end)];

ls = options.line;

samplemode = options.samplemode;

% Check if any input is model structure. If so, then samplemode from that is used instead
for i=1:length(varargin)
  if ismodel(varargin{i})
    samplemode = varargin{2}.detail.options.samplemode;
  end
end

initialization = options.init;
if strcmpi(options.waitbar,'on')
  hwait = waitbar(0,[' Fitting ',upper(modeltype),'. Please wait... (Close this figure to cancel analysis)']);
end

FeasibilityProblems = 0; % for indicating if the algorithm hasn't yet reached a feasible solution due some constraints
% CHECK FOR MISSING
mdop=mdcheck('options');
mdop.max_missing = 0.9999;
mdop.tolerance = [1e-4 10];
flag = 0;
try
  [flag,missmap,xx] = mdcheck(squeeze(x),mdop);
catch
  if findstr('too much missing data',lower(lasterr))
    if strcmpi(options.waitbar,'on')
      close(hwait)
    end
    error('Too much missing data to perform analysis');
  end
end
if flag
  Missing = 1;
  MissId=find(missmap);
  clear missmap
else
  Missing = 0;
  MissId = [];
end
if strcmpi(modeltype,'parafac2')&&Missing
  %There is a problem as parafac2 does not handle missing well with
  %imputation. Use weights instead
  if ~DoWeight
    weights  = ones(xsize);
  end
  weights(MissId)=0;
  DoWeight = 1;
  WMax     = max(abs(weights(:)));
  W2       = weights.*weights;
  warning('EVRI:Parafac2MissingDataBad','PARAFAC2 does not currently handle missing data efficiently')
  %Missing = 0;
  %2
  % x(MissId)=xx(MissId);
end

if ~predictmode
  %preprocessing
  if ~isempty(options.preprocessing{1});
    try
      [Xsdo] = preprocess('calibrate',options.preprocessing{1},Xsdo); 
      [x,options.preprocessing{1}] = preprocess('calibrate',options.preprocessing{1},x);
    catch
      close(hwait)
      error('Unable to preprocess - selected preprocessing may not be valid for multi-way data');
    end
    x = x.data;
  else
    x = x;
  end
else
  % model = varargin{2}
  if ~isempty(varargin{2}.detail.preprocessing);
    options.preprocessing = varargin{2}.detail.preprocessing;
  else
    options.preprocessing = {[]};
  end
  if ~isempty(options.preprocessing{1});
    try
      dd = preprocess('apply',options.preprocessing{1},Xsdo.data);        
      Xsdo.data=dd.data;
      x = preprocess('apply',options.preprocessing{1},x);
    catch
      close(hwait)
      error('Unable to preprocess - selected preprocessing may not be valid for multi-way data');
    end
    x = x.data;
  else
    x = x;
  end
end

% INITIALIZE LOADINGS (if not already given)
if exist('x0')~=1
  x0=0;
end

if ismodel(x0)
  % If old model given, constraints needs to be changed to fixed in non-sample modes
  [x0,InitString,aux,constraints]=initloads(modeltype,x0,order,Missing,nocomp,xsize,x,initialization,options);
else
  [x0,InitString,aux]            =initloads(modeltype,x0,order,Missing,nocomp,xsize,x,initialization,options);
end

% Add a check for fixed values. If fixed values, make sure that the size of
% initial loads are in the range the of the fixed values
for i=1:length(x0);
  if any(options.constraints{i}.fixed.position(:))
   try % may run into problems with some modes in pf2, so use try
      fxps = options.constraints{i}.fixed.position;
      fxval = options.constraints{i}.fixed.value;
      s1 = mean(fxval(find(fxps)).^2);
      if abs(s1)>eps
        s2 = mean(x0{i}(:).^2);
        x0{i}=s1*x0{i}/s2;
        if i<length(x0) % rescale next mode accordingly
          x0{i+1} = s2*x0{i+1}/s1;
        else % or first mode, because it's important that latter ones are right in the first als round
          x0{1} = s2*x0{1}/s1;
        end
      end
    end
  end
end


% just check for weird solutions
for i=1:length(x0)
  if ~isstruct(x0{i})
    if any(isnan(x0{i}(:)))
      x0{i}(isnan(x0{i}))=eps;
    elseif any(isinf(x0{i}(:)))
      x0{i}(isinf(x0{i}))=eps;
    end
  end
end

if iscell(aux) % Then constraints have been saved there because 
  % they may contain parameters for functional constraints
  if ~isempty(aux{1})
    for i=1:order
      try
        if size(constraints{i}.funcon,2)==3
          try
            constraints{i}.funcon(:,2) = aux{i}.funcon(:,2);
          catch
          end
        end
      end
    end
  end
end

allorth = 1; % allorth is used later on check whether there is orthogonality in all modes
for i=1:order
  if constraints{i}.orthogonal==0
    allorth = 0;
  end
end

if Missing % exchange missing elements with model estimates
  x(MissId)=xx(MissId);
end

% Calculate total sum of squares in data
if DoWeight
  xsq = (x.*weights).^2;
else
  xsq = x.^2;
end
if Missing
  xsq(MissId)=0;  
end
tssq = sum(xsq(:));

% Initialize the unfolded matrices
xuf = cell(1,order);
xuflo = cell(1,order);
xufsize = zeros(1,order);
for i = 1:order
  xuf{i} = unfoldmw(x,i)';
  xufsize(i) = prod(xsize)/xsize(i);
end

if strcmpi(modeltype,'parafac')
  % Old init of loads;xuflo{i} = zeros(prod(xsize)/xsize(i),nocomp);
  for j = 1:nocomp
    % Old version if i == 1,         mwvect = x0{2}(:,j);,         for k = 3:order              mwvect = mwvect*x0{k}(:,j)';            mwvect = mwvect(:);         end      else         mwvect = x0{1}(:,j);         for k = 2:order            if k ~= i               mwvect = mwvect*x0{k}(:,j)';               mwvect = mwvect(:);            end         end      end      xuflo{i}(:,j) = mwvect;   end
    xuflo{j}=outerm(x0,j,1);
  end
elseif strcmpi(modeltype,'parafac2')
  % Not needed 
elseif strcmpi(modeltype,'tucker')
  % Constraints of Tucker core
  tuckcorecon=regresconstr(constraints(order+1));
else
  error('Modeltype not known in NWENGINE - 3')
end

if strcmpi(modeltype,'parafac2')
  pf2max_inner_it    = 10;
  pf2opt             = parafac('options');
  pf2opt.display     = 'off';
  pf2opt.stopcrit(1:2) = 1e-10;
  pf2opt.plots       = 'off';
  pf2opt.waitbar     = 'off';
  %pf2opt.blockdetails='compact';
  pf2opt.samplemode = order;
  pf2opt.constraints = constraints;
  pf2opt.stopcrit(3) = pf2max_inner_it; % Maximum xx iterations in the inner parafac loop
  if ~predictmode % Check if constraints are put on first mode
      if constraints{1}.nonnegativity~=0|constraints{1}.unimodality~=0|constraints{1}.exponential~=0|constraints{1}.orthogonal~=0|constraints{1}.orthonormal~=0
          if DumpToScreen
              warning('EVRI:NwengineMode1Constraints','IMPORTANT: Please note that constraints in the first mode should not be used. They are not imposed on the actual loadings but on the common matrix H (see HELP PARAFAC2)')
              evripause(3)
          end
      end
  end
end

% Initialize other variables needed in the ALS
oldx0 = x0;searchdir = x0;
iter = 0;flag = 0;
abschange = 0;relchange = 0;oldrelchange=0;

if strcmpi(modeltype,'parafac')
  try
  if ~ismember(lower(options.algo),{'als','tld','swatld'})
    options.algo = 'als';
    if DumpToScreen
      disp(' OPTIONS.ALGO not recognized. Changed to ALS')
    end
  end
  catch
    options.algo = 'als';
  end
  if ~strcmpi(options.algo,'als')
    if DoWeight||order>3||any(xsize<nocomp)
      options.algo = 'als';
      if DumpToScreen
        disp(' Algorithm ALS has been chosen as other choices do not handle weights, constraints and more components than minimum dimension')
      end
    end
  end
  if strcmpi(options.algo,'swatld')
    [X0,s,v] = svds(xuf{1}',nocomp);
    [Y0,s,v] = svds(xuf{2}',nocomp);
    lambda = 1;
  end
end

% Show algorithmic settings etc.
if DumpToScreen
  disp(' '),disp([' Fitting ',upper(modeltype),' ...']) 
  txt=[];
  for i=1:order-1
    txt=[txt num2str(xsize(i)) ' x '];
  end
  txt=[txt num2str(xsize(order))];
  disp([' Input: ',num2str(order),'-way ',txt, ' array'])
  
  disp([' A ',num2str(nocomp),'-component model will be fitted'])
  for i=1:order
    t=regresconstr('text',constraints{i});
    disp([' Mode ',num2str(i),': ',t])
  end
  
  disp([' Convergence criteria:']) 
  disp([' Relative change in fit : ',num2str(tol(1))]) 
  disp([' Absolute change in fit : ',num2str(tol(2))]) 
  disp([' Maximum iterations     : ',num2str(tol(3))]) 
  w = fix(tol(4)/(60*60*24*7));
  d = fix((tol(4)-w*7*24*60*60)/(60*60*24));
  h = fix((tol(4)-w*7*24*60*60-w*24*60*60)/(60*60));
  m = fix((tol(4)-w*7*24*60*60-w*24*60*60-h*60*60)/(60));
  s = fix((tol(4)-w*7*24*60*60-w*24*60*60-h*60*60-m*60)/(1));
  tt = [' '];
  if w,tt = [tt,' ',num2str(w),'w;'];end
  if d,tt = [tt,' ',num2str(d),'d;'];end
  if h,tt = [tt,' ',num2str(h),'h;'];end
  if m,tt = [tt,' ',num2str(m),'m;'];  end
  tt = [tt,' ',num2str(s),'s.'];
  disp([' Maximum time           : ',tt]) 
  if strcmpi(modeltype,'parafac')
    if strcmpi(options.algo,'als')
      disp(' Algorithm : ALS')
    else
      disp([' Algorithm : ',upper(options.algo),' (no constraints possible)'])
    end
  end
  
  if Missing
    disp([' ', num2str(100*(length(MissId)/prod(xsize))),'% missing values']);
  else
    disp(' No missing values')
  end
  
  if DoWeight
    if iter_rew
      disp(' Iteratively re-weighted optimization will be performed')
    else
      disp(' Weighted optimization will be performed using input weights')
    end
  end
  
  disp(InitString)
end

% Start the ALS
while flag == 0
  iter = iter+1;
  
  % Loop over each of the order to estimate
  if DoWeight && iter > 1% If Weighted regression is to be used, do majorization to make a transformed data array to be fitted in a least squares sense
    if iter_rew % Modify weights acc to residuals
      WMax     = max(abs(weights(:)));
      W2       = weights.*weights; 
    end
    out = reshape(xest,xsize) + (WMax^(-2)*W2).*(x - reshape(xest,xsize));
    for i = 1:order
      xuf{i} = unfoldmw(out,i)';
    end
    clear out
  end

  % FIT PARAFAC
  if strcmpi(modeltype,'parafac')    
    if strcmpi(options.algo,'als')||predictmode
      for i = 1:order
        % Multiply the loads of all the orders together
        % except for the order to be estimated
        xuflo{i}=outerm(x0,i,1);
        % Regress the actual data on the estimate to get new loads in order i
        [x0{i},aux{i},flag2,consiter] = regresconstr(xuf{i},xuflo{i},x0{i},constraints{i},iter,aux{i});
        if size(options.constraints{i}.funcon,2)==3
          options.constraints{i}.funcon(:,2) = aux{i}; % Add this because it holds parameters in case of functional constraints (it's not used in the algorithm, but used to output it to the model struct which is also important when initialization is performed from best of several runs)
        end
     
      end
    elseif strcmpi(options.algo,'tld')
      model = tld(x,nocomp,[],0);
      x0 = model.loads;
    elseif strcmpi(options.algo,'swatld')
      [x0{1},x0{2},x0{3}] = swatld(x,X0(:,1:nocomp),Y0(:,1:nocomp),xsize(1),xsize(2),xsize(3),nocomp,tol(1),tol(3));
    end     
    
    % FIT TUCKER
  elseif strcmpi(modeltype,'tucker') 
    %Needs improvement for when only orthogonal loadings are sought in which case it can be done much faster
    for i = 1:order
      % Any constraint but orthogonal (or if core is constrained)
      %if allorth ~= 1||~tuckcorecon.constrainedmodes||~tuckcorecon.fixedmodes
      if allorth ~= 1||tuckcorecon.constrainedmodes||tuckcorecon.fixedmodes
        z = 1; 
        for j = order:-1:1, 
          if j~=i, 
            z = kron(z,x0{j}); 
          end, 
        end
        core = x0{order+1};
        core = reshape(core,nocomp);
        csize  = size(core);
        if max(csize)>1
          try
            core_fit = reshape(permute(core,[i 1:i-1 i+1:order]),csize(i),prod(csize([1:i-1 i+1:order])))';
          catch % If last mode is dim one
            if length(csize)<order
              csize = [csize ones(1,order-length(csize))];
            end
            core_fit = reshape(permute(core,[i 1:i-1 i+1:order]),csize(i),prod(csize([1:i-1 i+1:order-1])))';
          end
        else
          core_fit = core;
        end
        
        [x0{i},aux{i},flag2,consiter] = regresconstr(xuf{i},z*core_fit,x0{i},constraints{i},iter,aux{i});                

        %AtA = kron(A'*A,kron(A'*A,A'*A)); %xa=A'*reshape(permute(reshape(xa,F,I,I),[2 3 1]),I,I*F); %xa=A'*reshape(permute(reshape(xa,F,I,F),[2 3 1]),I,F*F);  %xa=permute(reshape(xa,F,F,F),[2 3 1]);gg=pinv(AtA)*xa(:);
        if size(options.constraints{i}.funcon,2)==3
          options.constraints{i}.funcon(:,2) = aux{i}; % Add this because it holds parameters in case of functional constraints (it's not used in the algorithm, but used to output it to the model struct which is also important when initialization is performed from best of several runs)
        end
        
        % Fit core
        if any(constraints{order+1}.fixed.position(:))==0 % If not completely fixed
          % If constraints
          if tuckcorecon.fixedmodes||tuckcorecon.constrainedmodes
            if ~(constraints{order+1}.ridge.weight||constraints{order+1}.nonnegativity||any(constraints{order+1}.fixed.position(:))||constraints{order+1}.fixed.weight==-1 )
              error(' Only nonnegativity, fixed elements and ridging allowed as constraint for the core elements')
            end
            %       B = argmin||X - AB'|| 
            Z = kron(x0{order},x0{order-1});
            for zj = order-2:-1:1
              Z = kron(Z,x0{zj});
            end
            cong = constraints{order+1};
            cong.fixed.value = cong.fixed.value(:)';
            cong.fixed.position = cong.fixed.position(:)';
            out = regresconstr(vec(xuf{1}'),Z,x0{order+1}(:),cong,iter,[]);
            x0{order+1} = reshape(out,size(x0{order+1}));%+(.1^(iter))*x0{order+1}; % To avoid intermediate overfit
%            x0{order+1}
          else
            % Else unconstrained
            x0{order+1} = corecalc(reshape(xuf{1}',xsize),x0(1:order),0,[],core);
          end
        else
          if length(size(constraints{order+1}.fixed.value)) == length(size(x0{order+1}))% If uservalues given
            if all( size(x0{order+1}) == size(constraints{order+1}.fixed.value))
              x0{order+1}= constraints{order+1}.fixed.value;
            end
          elseif constraints{order+1}.fixed.weight==-1; % If uservalues given
            % Don't update - ok already;
          end
        end
        
      else % Orthogonal
        % regress x down to other loads
        if all(nocomp<2) % If only 1 component, do it simple
          xuflo{i}=outerm(x0,i,1);
          % Regress the actual data on the estimate to get new loads in order i
          x0{i} = xuf{i}'*(xuflo{i});
          nom = norm(x0{i});
          x0{i} = x0{i}/nom; % normalize load
          if any(constraints{order+1}.fixed.position(:)) >=0  % If not completely fixed
            core = nom; 
          end
        else  % more than one component
          x_fit = x;
          for j = order:-1:1
            if j~=i % regress on loads
              x_fit = nprod(x_fit,x0{j},j);
            end
          end
          x_fit =  permute(x_fit,[i 1:i-1 i+1:order]);
          x_fit = reshape(x_fit,xsize(i),numel(x_fit)/xsize(i));
          [x0{i},out] = svds(x_fit,nocomp(i));  % nipals is not used because its to imprecise (gives overall convergence problems)
          % update core when done
          if i==order
            if any(constraints{order+1}.fixed.position(:)) >=0  % If not completely fixed
              x0{order+1} = corecalc(reshape(xuf{1}',xsize),x0(1:order),1,[],x0{order+1});
              %x0{order+1} = ipermute(reshape(x0{i}'*x_fit,nocomp([order 1:order-1])),[order 1:order-1]);
            end
          end
        end
      end
    end

  elseif strcmpi(modeltype,'parafac2')    
      
% Update P
    xsize2 = [];
    for i2=1:length(xsize)
        xsize2(i2)=size(xuf{i2},2);
    end
    unfoldloads = outerm(x0(1:end-1),1,1); % Exclude last and first mode
    Y = [];
    for k = 1:xsize2(end)
      % Do not update if mode 1 is fixed and samplemode is not order
      xk       = reshape(xuf{end}(:,k),xsize2(1),prod(xsize2(2:order-1)));
      if options.samplemode~=order && any(constraints{1}.fixed.position(:))==-1
        % Do not update Pk (prediction mode) - not sure this statement
        % makes sense!
      else
        %Qk       = x{k}'*(loads{1}*diag(loads{2}(k,:))*H')
        Qk       = xk*(unfoldloads*diag(x0{end}(k,:))*x0{1}.H');
        x0{1}.P{k}     = Qk*psqrt(Qk'*Qk);       %  [u,s,v]  = svd(Qk.');P{k}  = v(:,1:F)*u(:,1:F)';
      end
      xkp = (xk'*x0{1}.P{k})';
      Y(k,:) = xkp(:)';
    end
    Y = reshape(Y,[xsize2(order) nocomp xsize2(2:order-1)]);
    Y = permute(Y,[2:order 1]);
    % Update H,B,C etc using PARAFAC-ALS
    smallloads{1} = x0{1}.H;
    for k=2:order
      smallloads{k} = x0{k};
    end
    %pfmodel = parafac(Y,nocomp,smallloads,pf2opt);
    pfmodel = parafac(Y,smallloads,pf2opt);
    x0{1}.H = pfmodel.loads{1};
    x0(2:end) = pfmodel.loads(2:end);
  else
    error('Modeltype not known in NWENGINE - Error #4')
  end
  
  % Normalize the estimates (except the last (or other defined) order) and
  % store them in the cell
  x0 = standardizeloads(x0,constraints,samplemode,modeltype,options.scaletype);
  if strcmpi(modeltype,'tucker')
    if any(constraints{order+1}.fixed.position(:)) >=0  % If not completely fixed
      if ~(tuckcorecon.fixedmodes||tuckcorecon.constrainedmodes)
        x0{order+1} = corecalc(reshape(xuf{1}',xsize),x0(1:order),0,[],x0{order+1});
        % Make sure singleton dimensions are kept
        if any(nocomp==1)
          x0{order+1} = reshape(x0{order+1},nocomp);
        end
      end
    end
  end 
  drawnow % Inserted to avoid matlab getting hung up in calculations!
  
  % Calculate the estimate of the input array based on current loads
  xest = datahat(x0);
  xsq = xest;
  % Exchange missing with model estimates
  if Missing 
    x(MissId)=xest(MissId);
    for ii = 1:order
      xuf{ii} = unfoldmw(x,ii)';
    end
  end
  if DoWeight % Check to see if the fit has changed significantly
    if alllae
      xsq = abs((x-xsq).*weights);
    else
      xsq = ((x-xsq).*weights).^2;
    end
  else
    if alllae
      xsq = abs(x-xsq);
    else
      xsq = (x-xsq).^2;
    end
  end
  if Missing
    xsq(MissId)=0;  
  end
  ssq = sum(xsq(:));

  %disp(sprintf('On iteration %g ALS fit = %g',iter,ssq));
  if iter > 1 &~FeasibilityProblems
    abschange = abs(oldssq-ssq);
    oldrelchange = relchange;
    relchange = abschange/ssq;
    timespent = etime(clock,timespent0);
    if relchange < tol(1)
      
      % Check if nonnegativity is obeyed. Otherwise shift to another
      % nonnegativity algorithm
      stop = 1;
      for cc=1:length(x0);
        try
          if constraints{cc}.nonnegativity
            if any(x0{cc}<0)
              if constraints{cc}.nonnegativityalgorithm==0
                stop=0;
                constraints{cc}.nonnegativityalgorithm=1;
                if strcmp(lower(modeltype),'parafac2')
                  pf2opt.constraints = constraints;
                end
              elseif constraints{cc}.nonnegativityalgorithm==1
                stop=0;
                constraints{cc}.nonnegativityalgorithm=2;
                if strcmp(lower(modeltype),'parafac2')
                  pf2opt.constraints = constraints;
                end
              end
            end
          end
        end
      end
      if stop % Nonnegativity ok, so go ahead and stop
        flag = 1;
        endtxt=' Iterations terminated based on relative change in fit error';
      end
      
      % if iterative reweighting is used, check if weights converged
      % otherwise dont stop yet
      if iter_rew
        if iter_w_conv < 1e-4
          flag = 1;
          endtxt=' Iterations terminated based on relative change in fit error (and change in iterative weights)';
        else
          flag = 0;
        end
      end      
      
    elseif abschange < tol(2)
      flag = 1;
      endtxt=' Iterations terminated based on absolute change in fit error';
    elseif iter > tol(3)-1
      flag = 1;endtxt = ' Iterations terminated based on maximum iterations';
    elseif timespent > tol(4)
      flag = 1;endtxt = ' Iterations terminated based on maximum time';
    elseif isnan(ssq)
      flag = 1;endtxt = ' Non-feasible numerical solution';
    else
      flag = 0;
    end
    if flag==1
      if DumpToScreen
        disp(' '),disp('    Iteration    Rel. Change         Abs. Change         sum-sq residuals'),disp(' ')
        fprintf(' %9.0f       %12.10f        %12.10f        %12.10f    \n',iter,relchange,abschange,ssq);
        disp(' ')
        disp(endtxt)
      end
    end
  end

  if rem(iter,Show) == 0&DumpToScreen
    if iter == Show|rem(iter,Show*30) == 0
      disp(' '),disp('    Iteration    Rel. Change         Abs. Change         sum-sq residuals'),disp(' ')
    end
    fprintf(' %9.0f       %12.10f        %12.10f        %12.10f    \n',iter,relchange,abschange,ssq);
    if plots==2
      for pj=1:order
        subplot(floor((order+1)/2),2,pj)
        if strcmp(lower(modeltype),'parafac2')&pj == 1
          plot(x0{1}.P{1}*x0{1}.H),axis tight
          title(['Mode 1 (only first slab)'])
        else
          plot(x0{pj}),axis tight
          title(['Mode ',num2str(pj)])
        end
      end
      drawnow
    end
  end
  oldssq = ssq;
  
  if relchange~=0&strcmpi(options.waitbar,'on')
    if ishandle(hwait)
      if iter_rew
        % MODIFY TAKING ITERATIVE WEIGHTS CHANGES INTO ACCOUNT
        r1=(1e-4/iter_w_conv).^.3;
        r2=(tol(1)/((relchange+oldrelchange)/2)).^.3;
        waitbar( min(r1,r2),hwait)
      else
        waitbar((tol(1)/((relchange+oldrelchange)/2)).^.3,hwait)
      end
    end
  end
  
  %%%% LINE SEARCH %%%%%
  % Every fifth iteration do a line search if ls == 1
  if (iter/5 == round(iter/5) & ls == 1)
    if iter==5,
      Delta = 5; % Steplength is initially set to 5
    end

    if ~strcmp(lower(modeltype),'parafac2') % Linesearch does not work for pf2 but it is implicitly done inside the pf models run in pf2
      [x0,Delta] = linesrch(x,x0,oldx0,DoWeight,weights,alllae,Missing,MissId,Delta);
    end

  end
  if 6==7 % Should be left out and replaced by new linesearch above
    
    % Determine the search direction as the difference between the last two
    % estimates
    for ij = 1:length(x0)
      if strcmp(lower(modeltype),'parafac2')&ij==1
        for kk=1:length(x0{1}.P)
          searchdir{1}.P{kk} = x0{1}.P{kk}-oldx0{1}.P{kk};
        end
        searchdir{1}.H = x0{1}.H-oldx0{1}.H;
      else
        searchdir{ij} = x0{ij} - oldx0{ij};
        if sum(sum(abs(searchdir{ij})))<10*eps*prod(size(searchdir{ij}))
          % SEARCH DIR NOT DEFINED
          searchdir{ij} = randn(size(searchdir{ij}))*.0001;
        end
      end
    end
    
    % Initialize other variables required for line search
    testmod = x0;
    sflag = 0; 
    i = 0; 
    sd = zeros(10,1); 
    sd(1) = ssq;
    xl = zeros(10,1);
    while sflag == 0
      tesmod = extrapol(testmod,(2^i),searchdir,modeltype);
      % Calculate the fit error on the new test model
      xest = datahat(testmod);
      
      %Iterative preproc
      if DoWeight
        if alllae
          xsq = abs((x-datahat(testmod)).*weights);
        else
          xsq = ((x-datahat(testmod)).*weights).^2;
        end
      else
        if alllae
          xsq = abs(x-datahat(testmod));
        else
          xsq = (x-datahat(testmod)).^2;
        end
      end
      if Missing
        xsq(MissId)=0;  
      end
      % Save the difference and the distance along the search direction
      sd(i+2) = sum(xsq(:));
      xl(i+2) = xl(i+1) + 2^i;
      i = i+1;
      % Check to see if a minimum has been exceeded once two new points are calculated
      if i > 1 
        if sd(i+1) > sd(i)&sd(2)<sd(1) % Otherwise no improvement
          sflag = 1;
          % Estimate the minimum along the search direction
          xstar = sum((xl([i i+1 i-1]).^2 - xl([i+1 i-1 i]).^2).*sd(i-1:i+1));
          xstar = xstar/(2*sum((xl([i i+1 i-1]) - xl([i+1 i-1 i])).*sd(i-1:i+1)));
          % Save the old model and update the new one
          oldx0 = x0;          
          x0 = extrapol(x0,xstar,searchdir,modeltype);
        elseif i>10
          sflag = 1;
        end
      end
    end 
    [xhat,resids] = datahat(x0,x);
  else
    % Save the last estimates of the loads
    oldx0 = x0;
  end
  % Calculate the estimate of the input array based on current loads
  xest = datahat(x0);
  
  %Iterative preproc
  xsq = xest;
  if DoWeight
    if alllae
      xsq = abs((x-xsq).*weights);
    else
      xsq = ((x-xsq).*weights).^2;
    end
  else
    if alllae
      xsq = abs(x-xsq);
    else
      xsq = (x-xsq).^2;
    end
  end
  if Missing
    xsq(MissId)=0;
  end
  if iter_rew & rem(iter,options.iterative.updatefreq)==0% Modify weights acc to residuals - biweight of Tukey acc. to Phillips 1983
    oldweights = weights;
    weights = ((x-xest).^2).^(.5);
    weight(find(isnan(weights)))=0;
    s = median(weights(find(~isnan(weights))));
    weights = (1-options.iterative.fractionold_w)*weights + options.iterative.fractionold_w*oldweights;
    idw=find(weights>=options.iterative.cutoff_residuals*s);
    weights(:) = (1-(weights(:)/(options.iterative.cutoff_residuals*s)).^4);
    weights(idw) = 0;
    weights(find(isnan(weights)))= 0;
    iter_w_conv = sum((oldweights(:)-weights(:)).^2)/sum(oldweights(:).^2);
  end
  
  oldssq = sum(xsq(:));
  if Missing
    x(MissId)=xest(MissId);
    for j = 1:order
      xuf{j} = unfoldmw(x,j)';
    end
  end

  %disp(sprintf('SSQ at xstar is %g',oldssq))
  % Exchange missing with model estimates
  try
    if ~ishandle(hwait);  %waitbar closed
      flag = 1;
      disp(' ')
      disp(' NOTE - Iterations terminated by user prior to convergence')
    end
  end

end

%%%%%%%%%% ETXRA STEP IF THERE ARE NON-INCLUDED SAMPLES THAT NEED TO HAVE
%%%%%%%%%% THEIR SCORES PREDICTED
if ~(length(Xsdo.includ)<options.samplemode) % Can happen if the last mode is sample mode and there is only one sample (which can then not be missing - that would be silly!)
  if length(Xsdo.includ{options.samplemode})~=size(Xsdo.data,options.samplemode)
    % Extract leftout data
    Xout = Xsdo;
    Xout = delsamps(Xout,Xsdo.includ{options.samplemode},options.samplemode,2);
    Xout.includ{options.samplemode} = [1:size(Xout.data,options.samplemode)]';
    inc = Xout.includ;
    Xout = Xout.data(inc{:});
    exclud = delsamps([1:size(Xsdo.data,options.samplemode)]',Xsdo.includ{options.samplemode}); 
    i = options.samplemode;    
    % Apply possible preprocessin
    if ~isempty(options.preprocessing{1});
        try
            x = preprocess('apply',options.preprocessing{1},x);
        catch
            close(hwait)
            error('Unable to preprocess - selected preprocessing may not be valid for multi-way data');
        end
        x = x.data;
    else
        x = x;
    end
    
    % FIT PARAFAC
    if strcmpi(modeltype,'parafac')
      % Multiply the loads of all the orders together
      % except for the order to be estimated
      xuflo{i}=outerm(x0,i,1);
      
      % Regress the actual data on the estimate to get new loads in order i
      yout = unfoldmw(Xout,i)';
      aout = xuflo{i};
      for j = 1:size(Xout,i);
        missout = find(~isnan(yout(:,j)));
        [x0out{i}(j,:)] = regresconstr(yout(missout,j),aout(missout,:),rand(size(Xout,i),nocomp),constraints{i},iter,aux{i});
      end
      x02 = x0;
      x02{i}=repmat(NaN,size(Xsdo.data,i),nocomp);
      x02{i}(Xsdo.includ{i},:) = x0{i};
      x02{i}(exclud,:) = x0out{i};
      x0 = x02;    
      % FIT TUCKER
    elseif strcmpi(modeltype,'tucker')
      z = 1; 
      for j = order:-1:1, 
        if j~=i, 
          z = kron(z,x0{j}); 
        end, 
      end
      core = x0{order+1};
      csize  = size(core);
      if max(csize)>1
        core_fit = reshape(permute(core,[i 1:i-1 i+1:order]),csize(i),prod(csize([1:i-1 i+1:order])))';        
      else
        core_fit = core;
      end
      
      yout = unfoldmw(Xout,i)';
      aout = z*core_fit;
      for j = 1:size(Xout,i);
        missout = find(~isnan(yout(:,j)));
        [x0out{i}(j,:)] = regresconstr(yout(missout,j),aout(missout,:),rand(1,nocomp(i)),constraints{i},iter,aux{i});  
      end
      
      x02 = x0;
      x02{i}=repmat(NaN,size(Xsdo.data,i),nocomp(i));
      x02{i}(Xsdo.includ{i},:) = x0{i};
      x02{i}(exclud,:) = x0out{i};
      x0 = x02;
    
       % FIT PARAFAC2
    elseif strcmpi(modeltype,'parafac2')
        % Non-included samples not handled remove them
        ll1= length(size(Xsdo ));
        ll2 = Xsdo.include{ll1};
        Xsdo = delsamps(Xsdo,ll2,ll1,3);
    end
  end
end

% Calculate the residuals
if ~(length(Xsdo.includ)<options.samplemode) % Can happen if the last mode is sample mode and there is only one sample (which can then not be missing - that would be silly!)
  if length(Xsdo.includ{options.samplemode})~=size(Xsdo.data,options.samplemode)
    Xout = Xsdo;
    Xout.includ{options.samplemode} = [1:size(Xout.data,options.samplemode)]';
    inc = Xout.includ;
    Xout = Xout.data(inc{:});
    dif = (Xout-datahat(x0)).^2;
  else
    dif = (x-datahat(x0)).^2;
  end
else
  dif = (x-datahat(x0)).^2;
end

res = cell(1,order);

% Get rid of residuals from soft-deleted samples
inchere = {};
for i=1:ndims(dif)
    inchere{i}=1:size(dif,i);
end

if options.samplemode<ndims(dif) % To avoid problems when one sample is given in test set and that the sample mode is last mode
    inchere{options.samplemode}=Xsdo.include{options.samplemode};
else
    inchere{options.samplemode} = 1;
end
for i = 1:order
  xx = dif(inchere{:});
  for j = 1:order
    if i ~= j
      xx = sum(xx,j);
    end
  end
  xx = squeeze(xx);
  res{i} = xx(:);
end
%   Now add ssq for leftout samples
xx = dif;
dif = permute(xx,[options.samplemode 1:options.samplemode-1 options.samplemode+1:length(res)]);
res{options.samplemode} = sum(dif(:,:)')';


if ~isa(Xsdo,'dataset')% Then it's not a SDO
  Xsdo = dataset(Xsdo);
end

% Make output structure
model = makeoutput(modeltype,order,x0,nocomp,inputname(1),x,Xsdo,res,tol,relchange,abschange,iter,options,tssq,ssq,xsize,aux,timespent,varargin{2},predictmode,iter_rew,weights,InitString,pfmodel);

% make sure loads are held in column cell
model.loads = model.loads(:);

% Plot model
if strcmpi(options.waitbar,'on')
  if ishandle(hwait)
    close(hwait)
  end
end
if plots~=0
  %try
    modelviewer(model,Xsdo);
  %end
end

function model = makeoutput(modeltype,order,x0,nocomp,inputname,x,Xsdo,res,tol,relchange,abschange,iter,options,tssq,ssq,xsize,aux,timespent,oldmodel,predictmode,iter_rew,weights,InitString,pfmodel);
% Save the model as a structured array


if strcmpi(modeltype,'parafac')
  model = modelstruct('PAR',order);
elseif strcmpi(modeltype,'tucker')
  model = modelstruct('TUC',order);
elseif strcmpi(modeltype,'parafac2')
  model = modelstruct('PA2',order);
else
  error('Modeltype not known in NWENGINE - 9')
end


model.date = date;
model.time = clock;
model.loads                = x0;
model.datasource{1} = getdatasource(Xsdo);
model.description{2} = ['Constructed on ',date,'at ',num2str(model.time(4)),':',num2str(model.time(5)),':',num2str(model.time(6))];

if strcmpi(modeltype,'parafac')
  if nocomp==1
    model.description{3} = [num2str(nocomp),' PARAFAC component'];
  else
    model.description{3} = [num2str(nocomp),' PARAFAC components'];
  end
elseif strcmpi(modeltype,'tucker')
  model.description{3} = [num2str(nocomp),' TUCKER components'];
elseif strcmpi(modeltype,'parafac2')
  if nocomp == 1
    model.description{3} = [num2str(nocomp),' PARAFAC2 component'];
  else
    model.description{3} = [num2str(nocomp),' PARAFAC2 components'];
  end
else
  error('Modeltype not known in NWENGINE - 10')
end

model.datasource{1}.name = inputname;

% The following lines replace the many lines just below
model = copydsfields(Xsdo,model,[],{1 1});
Xsdo2=Xsdo; % Modify to handle situation with excluded samples and not 
            % options.samplemode==1
try
  Xsdo2.include{options.samplemode}=[1:size(Xsdo.data,options.samplemode)];
end
[xhat,rawres] = datahat(x0,Xsdo2); % Will be only included samples as only 
                                   % loads are input - NOPE actually not. All samples
if strcmpi(options.blockdetails,'all')
  model.detail.data{1} = Xsdo;
  model.pred{1} = xhat;
  model.detail.res{1} = rawres;
  if iter_rew
    model.detail.iteratively_found_weights=weights;
  end
end

% Make residual limits
if ~strcmpi(options.blockdetails,'compact')
  if ~predictmode
    inc=Xsdo.includ;
    resopts.algorithm = 'jm';
    inchere = {};
    for i=1:ndims(rawres)
        inchere{i}=1:size(rawres,i);
    end
    inchere{options.samplemode}=inc{options.samplemode};
    reslim95 = residuallimit(rawres(inchere{:}),.95,resopts);
    reslim99 = residuallimit(rawres(inchere{:}),.99,resopts);
    temp = [];
    temp.lim95 = reslim95;
    temp.lim99 = reslim99;
    model.detail.reslim = temp;
  else
    model.detail.reslim  = oldmodel.detail.reslim;
    model.detail.coreconsistency = NaN;
  end
end

if strcmpi(modeltype,'parafac')
  if ~strcmpi(options.blockdetails,'compact')
      try
          if strcmpi(options.coreconsist,'on')
              x00 = x0;
              x00{options.samplemode} = x00{options.samplemode}(Xsdo.includ{options.samplemode},:);
              [Consistency,G,E] = corcondia(x,x00,weights,0);
              model.detail.coreconsistency=[];
              model.detail.coreconsistency.consistency = Consistency;
              model.detail.coreconsistency.core = G;
              model.detail.coreconsistency.detail = E;
          end
      catch
          model.detail.coreconsistency = NaN;
    end
  end
  model.detail.algo = options.algo;
  model.detail.initialization = InitString;
end

% Make 'leverages'
for i=1:order
  model.ssqresiduals(i) = res(i);
  if ~predictmode
    inc  = model.detail.includ{i,1};
    L = model.loads{i};
    if isstruct(L) % If so, then its parafac2 mode 1
      % Do leverage on average loadings
      LL = L.P{1}*L.H;
      for k=2:length(L.P)
        LL = LL+L.P{k}*L.H;
      end
      L = LL;
    end
    if size(L,1)>1
      if any(isnan(L(:)))
        LL = L*NaN;
      else
        LL = L*pinv(eps+L'*L/(size(L,1)-1));
        model.tsqs{i,1}       = sum(L.*LL,2);
      end
    else
      model.tsqs{i,1}       = NaN*L;
    end
    try 
      if length(nocomp)>= i
        nc = nocomp(i); % For tucker
      else
        nc = nocomp(1);
      end
    catch
      nc = nocomp;
    end
    if length(model.detail.includ{i,1})>nocomp
      model.detail.tsqlim{i,1} = tsqlim(length(model.detail.includ{i,1}),nc,95);
    else
      model.detail.tsqlim{i,1} = NaN;
    end
    
    
  else % Predictmode => steal from old model and use old sample covariance for samples
    model.detail.tsqlim{i,1} = oldmodel.detail.tsqlim{i,1};      
    if i~=oldmodel.detail.options.samplemode;
      model.tsqs{i,1}          = oldmodel.tsqs{i,1};
    else % For the samplemode calucalte new leverages based on old covariance
      L = model.loads{i};
      oldL = oldmodel.loads{i};
      inc  = oldmodel.detail.includ{i,1};
      if size(L,1)>1
        LL = L*pinv(oldL'*oldL/(size(oldL,1)-1));
        model.tsqs{i,1}       = sum(L.*LL,2);
      else
        model.tsqs{i,1}       = NaN*L;
      end
    end
  end
  
end

model.detail.means{1,1}    = mean(Xsdo.data(Xsdo.includ{1},:)); %mean of X-block
model.detail.stds{1,1}     = std(Xsdo.data(Xsdo.includ{1},:));  %mean of X-block
model.detail.stopcrit      = tol;
model.detail.critfinal     = [relchange abschange iter timespent];
model.detail.options       = options;
model.detail.preprocessing = options.preprocessing;   %copy calibrated preprocessing info into model

if strcmp(lower(modeltype),'parafac')
  
  xhat = outerm(x0,0,1);
  xhatorthogonalized = xhat;
  for i = 1:nocomp
    xhatorthogonalized(:,i) = xhat(:,i) - xhat(:,[1:i-1 i+1:nocomp])*inv(xhat(:,[1:i-1 i+1:nocomp])'*xhat(:,[1:i-1 i+1:nocomp]))*(xhat(:,[1:i-1 i+1:nocomp])'*xhat(:,i));
  end
  ssxhat = sum(xhat.^2);
  ssxhatorth = sum(xhatorthogonalized.^2);
  ssxhat_rel_to_ssX = 100*(ssxhat/tssq);
  ssxhatorth_rel_to_ssX = 100*(ssxhatorth/tssq);
  ssxhat_rel_to_hat = 100*(ssxhat/sum(ssxhat));
  ssxhatorth_rel_to_hat = 100*(ssxhatorth/sum(ssxhat));
  s = dataset([ssxhat(:) ssxhat_rel_to_ssX(:) ssxhat_rel_to_hat(:) ssxhatorth(:) ssxhatorth_rel_to_ssX(:) ssxhatorth_rel_to_hat(:)]);
  s.name='Explained ssq per component';
  s.labelname{2} = 'Fit values';
  s.label{2}={'Sum of squares','Fit (% X)','Fit (% model)','Unique sum of squares','Unique Fit (% X)','Unique Fit (% model)'  };
  s.axisscale{1}= [1:nocomp]';
  s.axisscalename{1}= 'Component number';
  model.detail.ssq.total = tssq;
  model.detail.ssq.residual = ssq;
  model.detail.ssq.percomponent = s;
  model.detail.ssq.perc = 100*(1-model.detail.ssq.residual/model.detail.ssq.total);
  
  
elseif strcmp(lower(modeltype),'tucker')
  model.detail.ssq.percomponent = coreanal(x0{end},'list','all');
  model.detail.ssq.total = tssq;
  model.detail.ssq.residual = ssq;
  model.detail.ssq.perc = 100*(1-model.detail.ssq.residual/model.detail.ssq.total);
  
elseif strcmp(lower(modeltype),'parafac2')
  model.detail.ssq.total = tssq;
  model.detail.ssq.residual = ssq;
  model.detail.ssq.perc = 100*(1-model.detail.ssq.residual/model.detail.ssq.total);
  model.detail.innercore.coreconsistency = pfmodel.detail.coreconsistency;
else
  error('Modeltype not known in NWENGINE - err. 1')
end



function G = nprod(A,B,ModeA);

%NPROD inner product of the array A and matrix B
% Calculates the inner product of the array A and matrix B
% within the ModeA of A 
% 
% I/O 
% G = nprod(A,B,ModeA);
% See also: OUTER, OUTERM, TIMES, MTIMES, KRON

%  Copyright Eigenvector Research 1993-99
%  Modified RB 12/99
%  Modified RB 8/02

Ord = length(size(A));
DimA = size(A);
DimB = size(B);
if length(DimB)>2
  error(' B must be a matrix/vector')
end
if DimA(ModeA)~=DimB(1)
  error([' Mode ',num2str(ModeA),' must be of dimension ',num2str(DimB),' to correspond to the number of rows in the matrix B'])
end


A = permute(A,[ModeA 1:ModeA-1 ModeA+1:Ord]);
G = B'*reshape(A,DimA(ModeA),prod(DimA)/DimA(ModeA));
DimG = DimA;
DimG(ModeA) = DimB(2);
G = reshape(G,[DimG(ModeA) DimA([1:ModeA-1 ModeA+1:Ord])]);
G = ipermute(G,[ModeA 1:ModeA-1 ModeA+1:Ord]);


function X = psqrt(A,tol)

% Produces A^(-.5) even if rank-problems

[U,S,V] = svd(A,0);
if min(size(S)) == 1
  S = S(1);
else
  S = diag(S);
end
if (nargin == 1)
  tol = max(size(A)) * S(1) * eps;
end
r = sum(S > tol);
if (r == 0)
  X = zeros(size(A'));
else
  S = diag(ones(r,1)./sqrt(S(1:r)));
  X = V(:,1:r)*S*U(:,1:r)';
end


function xnew = extrapol(x0,factor,searchdir,modeltype);

xnew = x0;
for k = 1:length(x0)
  if k==1&strcmp(lower(modeltype),'parafac2')
    for kk = 1:length(x0{1}.P)
      xnew{k}.P{kk} = xnew{k}.P{kk} + factor*searchdir{k}.P{kk};
    end
    xnew{k}.H = xnew{k}.H + factor*searchdir{k}.H;
  else
    xnew{k} = xnew{k} + factor*searchdir{k};
  end
end


function [X,Y,Z] = swatld(R,X0,Y0,Jx,Jy,Jz,F,eps,maxiter)
% [X,Y,Z] = swatld(R,X0,Y0,Jx,Jy,Jz,F,eps,maxiter)
% self-weighted alternating trilinear decomposition.
% According to Chen et al. Chemometrics and Intelligent Laboratory Systems, 52 (2000) 75-86.
%
% Input:
% R is the three-way array,
% X0 and Y0 are starting values for the profiles in the x and y orders,
% Jx, Jy and Jz are the number of variables in the x, y and z orders,
% F is an estimate of the number of components,
% eps is the threshold for the convergence criterion,
% maxiter is the maximum number of iterations.
%
% Output:
% Loadings X, Y, Z 

% Initialization:
X = sclmat(X0); Y = sclmat(Y0); pinvY = pinv(Y); diagYtY = diag(Y'*Y); Z = zeros(Jz,F);

% Iterative refinement:
sigmaold = -1; cnv = eps + 1; iter = 0;
while cnv > eps & iter < maxiter
  pinvX = pinv(X); diagXtX = diag(X'*X);
  for jz = 1:Jz
    Z(jz,:) = 0.5 * (diag(pinvY*R(:,:,jz)'*X)./diagXtX...
      +diag(pinvX*R(:,:,jz) *Y)./diagYtY)';
  end
  pinvZ = pinv(Z); diagZtZ = diag(Z'*Z);
  for jy = 1:Jy
    Y(jy,:) = 0.5 * (diag(pinvX*squeeze(R(:,jy,:)) *Z)./diagZtZ...
      +diag(pinvZ*squeeze(R(:,jy,:))'*X)./diagXtX)';
  end
  Y = sclmat(Y); pinvY = pinv(Y); diagYtY = diag(Y'*Y);
  for jx = 1:Jx
    X(jx,:) = 0.5 * (diag(pinvZ*squeeze(R(jx,:,:))'*Y)./diagYtY...
      +diag(pinvY*squeeze(R(jx,:,:)) *Z)./diagZtZ)';
  end
  X = sclmat(X);
  sigma = sum(sum(sum((R-datahat({X,Y,Z})).^2)));
  
  cnv = abs((sigma-sigmaold)/sigmaold); 
  iter = iter + 1; 
  sigmaold = sigma;
  
end

function [B,sclA] = sclmat(A) 
% Scales and fixes the sign of the columns of matrix A.

sclA = sqrt(sum(A.^2)) .* sign(sum(A)); 
sclA(find(isnan(sclA)))=10*eps;
B = A / diag(sclA);

function model = tld(x,ncomp,scl,plots)
%TLD Trilinear decomposition.
%  The Trilinear decomposition can be used to decompose
%  a 3-way array as the summation over the outer product
%  of triads of vectors. The inputs are the 3 way array
%  (x) and the number of components to estimate (ncomp),
%  Optional input variables include a 1 by 3 cell array 
%  containing scales for plotting the profiles in each
%  order (scl) and a flag which supresses the plots when
%  set to zero (plots). The output of TLD is a structured
%  array (model) containing all of the model elements
%  as follows:
%
%     xname: name of the original workspace input variable
%      name: type of model, always 'TLD'
%      date: model creation date stamp
%      time: model creation time stamp
%      size: size of the original input array
%    nocomp: number of components estimated
%     loads: 1 by 3 cell array of the loadings in each dimension
%       res: 1 by 3 cell array residuals summed over each dimension
%       scl: 1 by 3 cell array with scales for plotting loads
%
%  Note that the model loadings are presented as unit vectors
%  for the first two dimensions, remaining scale information is
%  incorporated into the final (third) dimension. 
%
%I/O: model = tld(x,ncomp,scl,plots);
%
%See also: GRAM, MWFIT, OUTER, OUTERM, PARAFAC

%Copyright Eigenvector Research, Inc. 1998-2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%By Barry M. Wise
%Modified April, 1998 BMW
%Modified May, 2000 BMW
%Modified Aug, 2002 RB Included missing data

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  if nargout==0; clear model; evriio(mfilename,varargin{1},options); else; model = evriio(mfilename,varargin{1},options); end
  return; 
end

dx = size(x);

[min_dim,min_mode] = min(dx);
shift_mode = min_mode;
if min_dim<ncomp
  if shift_mode == 3
    shift_mode = 0;
  end
  x = shiftdim(x,shift_mode);
  dx = size(x);
else
  shift_mode = 1;
  x = shiftdim(x,shift_mode);
  dx = size(x);
end

if (nargin < 3 | ~strcmp(class(scl),'cell'))
  scl = cell(1,3);
end
if nargin < 4
  plots = 1;
end
xu = reshape(x,dx(1),dx(2)*dx(3));
opt=mdcheck('options');
opt.max_pcs = ncomp;
opt.frac_ssq = 0.9999;
xu(:,sum(~isfinite(xu))==size(xu,1)) = [];  % Remove completely missing columns
[o1,o2,xu] = mdcheck(xu,opt);clear o1 o2    % Replace missing with estimates

if dx(1) > dx(2)*dx(3)
  [u,s,v] = svd(xu,0);
else
  [v,s,u] = svd(xu',0);
end
uu = u(:,1:ncomp);
xu = zeros(dx(2),dx(1)*dx(3));
for i = 1:dx(1)
  xu(:,(i-1)*dx(3)+1:i*dx(3)) = squeeze(x(i,:,:));
end
xu(:,sum(~isfinite(xu))==size(xu,1)) = [];
[o1,o2,xu] = mdcheck(xu,opt);clear o1 o2

if dx(2) > dx(1)*dx(3)
  [u,s,v] = svd(xu,0);
else
  [v,s,u] = svd(xu',0);
end
vv = u(:,1:ncomp);
xu = zeros(dx(3),dx(1)*dx(2));
for i = 1:dx(2)
  xu(:,(i-1)*dx(1)+1:i*dx(1)) = squeeze(x(:,i,:))';
end
xu(:,sum(~isfinite(xu))==size(xu,1)) = [];
[o1,o2,xu] = mdcheck(xu,opt);clear o1 o2

if dx(3) > dx(1)*dx(2)
  [u,s,v] = svd(xu,0);
else
  [v,s,u] = svd(xu',0);
end
ww = u(:,1:2);
clear u s v

g1 = zeros(ncomp,ncomp,dx(3));

uuvv = kron(vv,uu);

for i = 1:dx(3)
  xx = squeeze(x(:,:,i));
  xx = xx(:);
  notmiss = isfinite(xx);
  gg = pinv(uuvv(notmiss,:))*xx(notmiss);
  g1(:,:,i) = reshape(gg,ncomp,ncomp);
  % Old version not formissing; g1(:,:,i) = uu'*squeeze(x(:,:,i))*vv;
end
g2 = g1;
for i = 1:dx(3);
  g1(:,:,i) = g1(:,:,i)*ww(i,2);
  g2(:,:,i) = g2(:,:,i)*ww(i,1);
end
g1 = sum(g1,3);
g2 = sum(g2,3);
[aa,bb,qq,zz,ev] = qz(g1,g2);
if ~isreal(ev)
  %disp('  ')
  %disp('Imaginary solution detected')
  %disp('Rotating Eigenvectors to nearest real solution')
  ev=simtrans(aa,bb,ev);
end
ord1 = uu*(g1)*ev;
ord2 = vv*pinv(ev');
norms1 = sqrt(sum(ord1.^2));
norms2 = sqrt(sum(ord2.^2));
ord1 = ord1*inv(diag(norms1));
ord2 = ord2*inv(diag(norms2));
sf1 = sign(mean(ord1));
if any(sf1==0)
  sf1(find(sf1==0)) = 1;
end
ord1 = ord1*diag(sf1);
sf2 = sign(mean(ord2));
if any(sf2==0)
  sf2(find(sf2==0)) = 1;
end
ord2 = ord2*diag(sf2);
ord3 = zeros(dx(3),ncomp);
xu = zeros(dx(1)*dx(2),ncomp);
for i = 1:ncomp
  xy = ord1(:,i)*ord2(:,i)';
  xu(:,i) = xy(:);
end
for i = 1:dx(3)
  y = squeeze(x(:,:,i));
  y = y(:);
  notmiss = isfinite(y);
  ord3(i,:) = (xu(notmiss,:)\y(notmiss))';
end

if shift_mode
  if shift_mode==1
    ord4 = ord1;
    ord1 = ord3;
    ord3 = ord2;
    ord2 = ord4;
  else
    ord4 = ord1;
    ord1 = ord2;
    ord2 = ord3;
    ord3 = ord4;
  end
  x = shiftdim(x,3-shift_mode);
  dx = size(x);
end

loads = {ord1,ord2,ord3};
xhat = outerm(loads);
dif = (x-xhat).^2;
res = cell(1,3);
res{1} = nansum(dif,1)';
res{2} = nansum(dif,2)';
res{3} = nansum(dif,3)';

model = struct('xname',inputname(1),'name','TLD','date',date,'time',clock,...
  'size',dx,'nocomp',ncomp);
model.loads = loads;
model.ssqresiduals = res;
model.scale = scl;


function Vdd=simtrans(aa,bb,ev);
%SIMTRANS Similarity transform to rotate eigenvectors to real solution
Lambda = diag(aa)./diag(bb);
n=length(Lambda);
[t,o]=sort(Lambda);
Lambda(n:-1:1)=Lambda(o);
ev(:,n:-1:1)=ev(:,o);

Theta = angle(ev);
Tdd = zeros(n);
Td = zeros(n);
ii = sqrt(-1);

k=1;
while k <= n
  if k == n
    Tdd(k,k)=1;
    Td(k,k)=(exp(ii*Theta(k,k)));
    k = k+1;
  elseif abs(Lambda(k))-abs(Lambda(k+1)) > (1e-10)*abs(Lambda(k)) 
    %Not a Conjugate Pair
    Tdd(k,k)=1;
    Td(k,k)=(exp(ii*Theta(k,k)));
    k = k+1;
  else 
    %Is a Conjugate Pair
    Tdd(k:k+1,k:k+1)=[1, 1; ii, -ii];
    Td(k,k)=(exp(ii*0));  
    Td(k+1,k+1)=(exp(ii*(Theta(k,k+1)+Theta(k,k))));
    k = k+2;
  end
end
Vd = ev*pinv(Td);
Vdd = Vd*pinv(Tdd);
if imag(Vdd) < 1e-3
  Vdd = real(Vdd);
end


function y = nanmean(x)

nans = isnan(x);
i = find(nans);
x(i) = zeros(size(i));

if min(size(x))==1,
  count = length(x)-sum(nans);
else
  count = size(x,1)-sum(nans);
end

i = find(count==0);
count(i) = ones(size(i));
y = sum(x)./count;
y(i) = i + NaN;



function y = nansum(x,mode)
nans = isnan(x);
i = find(nans);
x(i) = zeros(size(i));
x = permute(x,[mode 1:mode-1 mode+1:length(size(x))]);
x = reshape(x,size(x,1),prod(size(x))/size(x,1))';
y = sum(x);

function Y = vec(X);

Y = X(:);
