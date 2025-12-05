function [press,cumpress,rmsecv,rmsec,cvpred,misclassed,reg] = crossval(x,y,rm,cvi,ncomp,out,pre,varargin)
%CROSSVAL Cross-validation for decomposition and linear regression.
%  CROSSVAL performs cross-validation for regression and PCA models.
%  Inputs include the predictor variable (x) {class double or dataset},
%  and predicted variable (y) {y=[] for PCA models}.
%  Input (rm) can either be:
%  1) A string defining the regression or decomposition method:
%    'nip': PLS via NIPALS algorithm (slower iterative PLS algorithm),
%    'sim': PLS via SIMPLS algorithm (fast algorithm for PLS),
%    'dspls' : PLS via DSPLS algorithm (direct scores PLS algorithm)
%    'npls'  : N-way PLS for multi-way regression
%    'pcr': PCR principal components regression,
%    'correlationpcr': Correlation PCR principal components regression
%           with y-block variance captured PC sorting,
%    'cls': CLS classical least squares regression,
%    'mlr': MLR multiple linear regression,
%    'lwr': Locally Weighted Regression algorithm, (see the LWRPRED
%                function and the "lwr" option below for more information),
%    'pca': PCA principal components analysis.
%  2) A model associated with one of the methods listed in 1).
%        In this case the regression method string is extracted from the 
%        model's modeltype field and cross-validation is performed.  
%        Note: crossval always uses the include fields from input x and y.
%        It does not copy the include fields used when building the model.
%        The cross-validation results are added to the model.detail, 
%        structure, e.g. model.detail.rmsecv. 
%        The returned output is always the updated model in this case.
%  Input (cvi) can be input in 3 ways.
%  1) (cvi) is a cell specifying one of the pre-defined subset methods:
%         {method splits iterations}
%         where "method" is one of:
%           'loo' : leave one out cross-validation (each sample left out on
%                    its own; does not take splits or iterations as inputs)
%           'con' : contiguous blocks (split into n groups)
%           'vet' : venetian blinds (leave out every n'th sample - see
%                    below for special use of "iterations" input)
%           'rnd' : random subsets
%         "splits" defines the number of groups to split the data into and
%         "iterations" defines the number of replicate splits to perform.
%           For 'con', iterations randomly moves the starting
%           point for the first (and subsequent) blocks.
%     OR {'vet' splits blindsize}
%         where 'vet' means venetian blinds (split data into "splits"
%           groups leaving out "blindsize" samples at a time - when
%           blindsize is 1 (one), this leaves out every n'th sample.
%         "splits" defines the number of groups to split the data into and
%         "blindsize" defines the number of samples to include in each
%           blind. 
%         For example, splits=4 and blindsize=2 means split the data into
%           groups of 4 taking 2 samples for each group at a time. Several
%           examples: 
%           splits   blindsize   grouping (same #s left out together)
%             4         1         1 2 3 4 1 2 3 4 1 2 3 4 1 2 3 4...
%             4         2         1 1 2 2 3 3 4 4 1 1 2 2 3 3 4 4...
%             2         5         1 1 1 1 1 2 2 2 2 2 1 1 1 1 1 2...
%     E.g. cvi = {'con' 5}; for 5 contiguous blocks (one iteration)
%         
%  2) (cvi) can be a vector with the same number of elements as x has rows
%     (i.e. length(cvi) = size(x,1); when x is class "double", or
%           length(cvi) = size(x.data,1); when x is class "dataset")
%     with integer elements, defining test subsets as follows:
%       -2 the sample is always in the test set,
%       -1 the sample is always in the calibration set,
%        0 the sample is never used, and
%        1,2,3,... defines each test subset.
%
%  3) If input (x) is class dataset and (cvi) is [] (empty) the sample classes
%     from (x) will be used as (cvi) i.e. cvi = x.class{1}.
%
%  Input (ncomp) is the number of components (LVs or PCs) to calcluate (see
%  option ncompvector, below.)
%
%  Optional input (options) is an options structure containing one or more
%  of the following fields:
%    display  : [ 'off' | {'on'} ] Governs output to command window,
%    plots    : [ 'none' | {'final'} ] Governs plotting,
%    waitbartrigger : [15] Governs display of waitbar. If a given crossval
%                      run is expected to take longer than this many
%                      seconds, a waitbar will be presented to the user.
%                      Set to "inf" to disable the waitbar entirely.
%    ncompvector   : [{'no'} | 'yes' ] determines if input (ncomp) is 
%                      giving the MAXIMUM number of components to
%                      cross-validate over (='no') or is giving a specific
%                      value or vector of values over which
%                      cross-validation should be done (='yes'). If 'yes',
%                      cross-validation will be done only for the specified
%                      value(s) in (ncomp).
%    preprocessing : {[1]} Controls preprocessing. Default is mean centering (1).
%        Can be input in two ways:
%        a) As a single value: 0 = none, 1 = mean centering, 2 = autoscaling, or
%        b) As {xp yp}, a cell array containing a preprocessing structure(s)
%           for the X- and Y-blocks (see PREPROCESS). E.g. pre = {xp []}; for PCA.
%           To include preprocessing of each subset use pre = {xp yp}; or
%           pre = {xp []} for PCA. To avoid preprocessing of each subset use
%           pre = {[] []}; or pre = 0 (zero).
%      testx : [] Use to provide a separate validation X-block from which an
%                RMSEP will be calculated for each number of components in
%                the model. Must be supplied with option testy. Only
%                functional for 2-way regression methods.
%      testy : [] Use to provide a separate validation Y-block for use with
%                option testx (see above).
%    discrim : [ {'no'} | 'yes' ] Force cross-validation in "discriminant
%                analysis" mode. Returns average misclassification rate and
%                returns misclassed output. Also triggered by y being logical.
%    threshold : {[]} Alternate PLSDA threshold level (default = [] = automatic)
%    prior     : {[]} Used with regression and discrim mode only. Vector of
%                 fractional prior probabilities. This is the probability
%                 (0-1) of observing a "1" for each column of y (i.e. each
%                 class). E.g. [.25 .50] defines that only 25% and 50% of
%                 future samples will likely be "true" for the classes
%                 identified by columns 1 and 2 of the y-block.
%                 [] (Empty) = equal priors.
%    structureoutput : [ {'no'} | 'yes' ] Governs output variables. 'Yes'
%                     returns a structure instead of individual variables.
%    jackknife : [ {'no'} | 'yes' ] Governs storing of jackknifed
%                 regression vectors. Jack-knifing may slow performance
%                 significantly or cause out-of-memory errors when both x
%                 and y blocks have many variables.
%    rmsec : [ 'no' | {'yes'} ] Governs calculation of RMSEC. When
%               set to 'no', calculation of "all variables" model is
%               skipped (unless specifically required by plots or requested
%               with multiple outputs)
%    permutation : [ {'no'} | 'yes' ] Performs permutation test instead of
%                   simple cross-validation. This calls the permutetest
%                   function with the same inputs as provided to
%                   cross-validation.
%   npermutation : [ {100} ] Number of permutations to perform (if
%                   permutation flag is 'yes')
%    pcacvi : {'loo'} Cell describing how PCA cross-validation should perform
%               variable replacement. Variable replacement options are
%               similar to cross-validation CVI options and include:
%                  {'loo'}        leave one variable out at a time
%                  {'con' splits} contiguous blocks (total of splits groups)
%                  {'vet' splits} venetian blinds (every n'th variable), or
%                  {'rnd' splits} random subsets (note: no iterations)
%    fastpca : [ 'off' | {'auto'} ] Governs use of "fast" PCA
%                Cross-validation algorithm. 'off' never uses fast algorithm,
%                'auto' uses fast algorithm when other options permit. Fast
%                pca can only be used with pcacvi set to 'loo'
%    lwr : Sub-structure of options to use for locally-weighted regression
%           cross-validation. Most of these options are used as defined in
%           the LWRPRED function (see LWRPRED for more details) but there
%           are two additional options defined for cross-validation:
%              lwr.minimumpts : [20] the minimum number of points (samples)
%                   to use in any LWR sub-model.
%              lwr.ptsperterm : [20] the number of points to use per term
%                  (LV) in the LWR model. For example, when set to 20,
%                  20 samples will be use for a 1 LV model, 40 samples will
%                  be used for a 2 LV model, etc. If set to zero, the
%                  number of points defined by lwr.minimumpts will be used
%                  for all models - that is, the number of samples used
%                  will be independent from the number of LVs in the model.
%           In all cases, the number of samples in an individual test set
%           will be the upper limit of samples to include in any LWR
%           prediction.
%    weights: [ {'none'} | 'hist' | 'custom' ]  governs sample
%               weighting. 'none' does no weighting. 'hist' performs
%               histogram weighting in which large numbers of samples at
%               individual y-values are down-weighted relative to small
%               numbers of samples at other values. 'custom' uses the
%               weighting specified in the weightsvect option.
%    weightsvect: [ ] Used only with custom weights. The vector specified
%                   must be equal in length to the number of samples in
%                   the y block and each element is used as a weight for
%                   the corresponding sample. If empty, no sample
%                   weighting is done.
%   rmoptions: Sub-structure of regression method options to specify what
%              options should be passed directly to the function specified
%              by the regression method.
%
%  Outputs are:
%        press : predictive residual error sum of squares PRESS for each
%                 subset
%     cumpress : cumulative PRESS
%       rmsecv : root mean square error of cross-validation
%        rmsec : root mean square error of calibration
%       cvpred : cross-validation y-predictions (regression methods only)
%    classerrc : classification error rate for calibration (see misclassed)
%   classerrcv : classification error rate for cross-validation
%   misclassed : fractional misclassifications for each class (valid for
%                 regression methods only and only when y is a logical,
%                 (i.e. discrete-value) vector. Classerrc and cv are
%                 determined from the misclassed rate after correcting for
%                 any prior probabilities. classerrc/cv are essentially
%                 averages of the misclassed values (average across all
%                 classes)
%          reg : jack-knifed regression vectors from each sub-set. This
%                 will be size [k*ny nx splits] such that reg(1,:,:) will
%                 be the regression vectors for 1 component model of the first
%                 column of y for all sub sets (a 1 by nx by splits
%                 matrix). Use squeeze to reduce to an nx by splits matrix.
%                 (note: options.jackknife must be 'yes' to use reg)
%
%  If options.structureoutput is 'yes', a single output (results) will
%  return all the above outputs as fields in a structure. In addition, the
%  following fields are also available in the results structure (but not in
%  the raw output format):
%      cvbias : cross-validation regression bias for each y column (rows)
%                and each number of components in the model (columns)
%      cbias  : self-prediction regression bias for each y column (rows)
%                and each number of components in the model (columns)
%      r2y    : variance captured for Y calibration data for each y column
%                (rows) and each number of components (columns). Note this
%                is not the same as the r2c.
%      q2y    : variance captured for Y cross-validation data for each y
%                column (rows) and each number of components (columns)
%      r2cv   : squared correlation coefficient for each y column (rows)
%               and each number of components in the model (columns)
%      r2c    : self-prediction squared correlation coefficient for each 
%                y column (rows) and each number of components in the model
%                (columns)
%      cvi    : the leave-out set identification for each sample in the
%                data. If a sample was marked as -1 or -2 in an custom
%                input CVI, this is also reflected here.  
%
%  If options.rmsec is 'no', then RMSEC is not returned (provides faster
%  iterative calculation)
%
%  Note that for multivariate (y) the output (press) is grouped by output variable,
%  i.e. all of the PRESS values for the first variable are followed by all of the
%  PRESS values for the second variable, etc.
%
%I/O: [press,cumpress,rmsecv,rmsec,cvpred,misclassed] = crossval(x,y,rm,cvi,ncomp,options);
%I/O: results = crossval(x,y,rm,cvi,ncomp,options);
%I/O: model = crossval(x,y,model,cvi,ncomp,options);  %return cv results in model 
%I/O: crossval demo
%
%See also: COPYCVFIELDS, ENCODEMETHOD, PCA, PCR, PLS, PREPROCESS

%Copyright Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%JMS 2/7/04 -discontinued use of tic/toc for timing
%    -fixed PCA replacement divide by zero bug
%JMS 9/25/04 -fixed lwpred bug (base minimum # on cal set size, not test set)
%JMS 12/5/04 -added limited support for discrim. threshold adjustment
%    (default = [] which is 'automatic' mode)
%jms 2/4/04  -remeasure x-block size after doing intersection of x and y
%     include fields
%jms 2/6/04  NOTE - comments from 12/5 and back are 2003, not 2004
%   -fixed bug in time to completion calculation (convert from days to seconds)
%jms 2/26/04 revised input check order to solve problem when y-block
%    include smaller than x-block included
%jms 5/04 allow input of options structure in place of out and pre
%    -internal use of options in place of other varaibles
%    -allow disabling of SEC calculation (for faster bootstrapping and other statistical tests)
%jms 1/28/05 revise PCA variable replace method for faster crossval
%jms 5/18/05 added support for "prior" option when in discrim mode. Base
%      rmsecv and rmsec on prior-adjusted misclassed values. Use prior in
%      threshold determination.
%jms 5/26/05 fixed preprocessing = 2 bug
%      return structure output when nargout = 0
%jms 7/8/05 correct for total number of samples actually in test sets
%      (when custom cvi is used, this might be necessary)
%jms 8/8/05 Fixed PCA CV bug, added less memory-intensive PCA CV mode
%      -added PCA CVI mode for variables
%jms 8/05 Do row-wise preprocessing items FIRST (no need to repeat for each subset)

if nargin == 0; x = 'io'; end
varargin{1} = x;
if ischar(varargin{1});
  options = [];
  options.name            = 'options';
  options.display         = 'on';
  options.plots           = 'final';
  options.preprocessing   = 1;
  options.weights         = 'none';
  options.ncompvector     = 'no';  %ncomp is the maximum value
  options.weightsvect     = [];
  options.testx           = [];
  options.testy           = [];
  options.discrim         = 'no';   %force discriminant analysis mode
  options.threshold       = [];
  options.prior           = [];
  options.structureoutput = 'yes';   %use a structure of all fields if only one output requested
  options.jackknife       = 'no';   %store jackknifed regression vectors?
  options.rmsec           = 'yes';
  options.permutation     = 'no';
  options.npermutation    = 100;
  options.pcacvi          = {'loo'};
  options.fastpca         = 'auto';
  options.waitbartrigger  = 15;
  options.lwr             = lwrpred('options');
  options.lwr             = rmfield(options.lwr,'preprocessing');  %remove this one so users don't get confused
  options.lwr.display     = 'off';
  options.lwr.minimumpts  = 20;
  options.lwr.ptsperterm  = 20;
  options.rmoptions       = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else press = evriio(mfilename,varargin{1},options); end
  return;
end

if nargin < 4;
  error('Insufficient inputs');
end
if nargin < 5 ; ncomp = []; end
if isa(cvi,'char')
  if nargin < 6 | isa(out,'struct');
    %Handle inputs where cvi is a string (probably 'loo'), but they are using
    %options. Technically this should give an error, but we'll be nice. If
    %they didn't supply a valid cvi string, we'll tell them below.
    %(x,y,rm,cvi,ncomp,options) with cvi NOT as cell
    cvi = {cvi};
  end
end
if isa(cvi,'char')  %backwards compatibility code - convert old crossval call to new format
  
  %OLD: (x, y, rm  , cvm , ncomp, split, iter, mc, out, osc )
  %NEW: (x, y, rm  , cvi , ncomp,   out,   pre, varargin{1:3})
  
  warning('EVRI:CrossvalOldIO','This format of input to CROSSVAL may be removed in the future. See ''help crossval''.')
  
  if nargin < 6  | isempty(out); out = 5; end    %default split
  if nargin < 7  | isempty(pre);  pre  = 1; end    %default iterations
  if nargin < 8  | isempty(varargin{1});          %defalut pre
    varargin{1} = 1;
  end
  if nargin < 9  | isempty(varargin{2}); varargin{2} = 1;  end;   %default out
  if nargin < 10 | isempty(varargin{3}); varargin{3} = []; end;   %default osc
  
  options = crossval('options');
  
  cvi = {cvi out pre};
  options.preprocessing  = varargin{1};
  out = varargin{2};
  defaultprepro = false;
  
  if ~isempty(varargin{3});
    %osc = [nocomp,iter,tol];
    if ~iscell(options.preprocessing);
      if options.preprocessing == 0;
        options.preprocessing = {[] []};
      else
        options.preprocessing = {preprocess('meancenter') preprocess('meancenter')};
      end
    end
    if isempty(options.preprocessing{1});
      options.preprocessing{1} = oscset('default');
    else
      options.preprocessing{1}(end+1) = oscset('default');
    end
    osc = varargin{3};
    if length(osc)<2;
      osc(2) = options.preprocessing{1}(end).userdata(2);
    end
    if length(osc)<3;
      osc(3) = options.preprocessing{1}(end).userdata(3);
    end
    options.preprocessing{1}(end).userdata = osc;
  end
  
  %convert simple inputs to options fields
  if out
    options.display = 'on';
    options.plots   = 'final';
  else
    options.display = 'off';
    options.plots   = 'none';
  end
  
else  %new version call, get defaults for missing inputs
  
  if nargin<6
    options = [];
    defaultprepro = true;
  else
    if ~isa(out,'struct');
      options = [];
      defaultprepro = true;
      if nargin<6 | isempty(out);
        out   = 1;
      end
      if nargin<7
        pre = true;
      end
      %convert simple inputs to options fields
      options.preprocessing = pre;
      if out
        options.display = 'on';
        options.plots   = 'final';
      else
        options.display = 'off';
        options.plots   = 'none';
      end
    else
      options = out;
      defaultprepro = ~isfield(options,'preprocessing');
    end
  end
  options = reconopts(options,mfilename,0);
  %warning: do NOT check nargin below here or backwards compatibility may be lost!
  
end

out = strcmp(options.display,'on');

%Regression method testing
if isempty(rm); error('Regression (rm) not specified.'); end

if isempty(ncomp)
  ncomp = 1;
end

%vectorize ncomp if it isn't
if ~strcmpi(options.ncompvector,'yes')
  %NCOMP is the maximum value (normal behavior) create vector from 1 to ncomp
  ncompvector = 1:ncomp;
else
  %ncomp IS the vector
  ncompvector = ncomp;
  ncomp = max(ncompvector);
end


% Was a model passed in as parameter 'rm'
model = [];
havemodel = false;
if ismodel(rm)
  model = rm;
  rm = lower(model.modeltype);
  havemodel = true;
  %with model: always use at least as many lvs as were in model (otherwise model stats are too few and RMSEC will be too short)
  ncompvector = getncompvector(model, ncompvector, ncomp, options);
  ncomp = max(ncompvector);
end
% Get the algorithm from model.detail.options.algorithm
if ~isempty(model)
  switch rm
    
    case 'pls'
      if isfield(model.detail.options, 'algorithm') & ~isempty(model.detail.options.algorithm)
        rm = lower(model.detail.options.algorithm);
      else
        rm = 'sim';
      end
      
    case 'pcr'
      if isfield(model.detail.options, 'algorithm') & ~isempty(model.detail.options.algorithm)
        rm = lower(model.detail.options.algorithm);
      else
        rm = 'svd';
      end
      if strcmp(rm, 'svd')
        rm = 'pcr';
      end
      
    case 'plsda'
      if isfield(model.detail.options, 'algorithm') & ~isempty(model.detail.options.algorithm)
        rm = lower(model.detail.options.algorithm);
      else
        rm = 'sim';
      end
      options.discrim = 'yes';
      if isempty(y)
        %no y passed? use y from model
        y = model.detail.data{2};
      end
      
    case 'knn'
      options.discrim = 'yes';
      if isempty(y)
        %no y passed? use y from model
        y = model.detail.class{1,1,model.detail.options.classset}';
      end
      
    case 'mpca'
      rm = 'pca';
      
  end
  if defaultprepro
    %user didn't specify preprocessing with this call? get it from the
    %model
    options.preprocessing = model.detail.options.preprocessing;
  end
  
  %copy options from input model over into rmoptions (for use in helper
  %functions)
  options.rmoptions = reconopts(options.rmoptions,model.detail.options);
  options.rmoptions.preprocessing = cell(1,length(options.rmoptions.preprocessing));
  
end
rm = lower(rm);

if isempty(model) & strcmpi(rm,'plsda')
  %special handling of PLSDA (only used when there was no model)
  rm = 'sim';
  options.discrim = 'yes';
end  

%look for helper function for this regression method
if exist(['crossval_' rm],'file') && ~ismember(rm,crossval_builtin('builtin_methods'))
  helperfn = str2func(['crossval_' rm]);
elseif ismember(rm,crossval_builtin('builtin_methods'))
  %one of our fast built-in known methods, handle specially
  helperfn = @crossval_builtin;
  helperfn('methodname',rm);
else
  %not one of the methods we know about? use the stdmod call
  helperfn = @crossval_stdmod;
  helperfn('methodname',rm);
end
if ~strcmp(options.discrim,'yes')
  %not marked as discrim analysis? check if method requires it
  if helperfn('forcediscrim');
    options.discrim = 'yes';
  end
end

% Should crossval loop over components
if ~helperfn('usefactors')
  ncomp = 1;
  ncompvector = 1;
end
%X-block testing
if isempty(x); error('X-block is empty.'); end

if mdcheck(x);
  if out; warning('EVRI:CrossvalMissingData','Missing Data Found - Replacing with "best guess". Results may be affected by this action.'); end
  [flag,missmap,x] = mdcheck(x);
end

if isa(x,'dataset')
  xinclude = x.include;
  if isempty(cvi) & ~isempty(x.class{1});
    cvi = x.class{1}(x.include{1})';         %use class values from DataSet if empty cvi provided and sample classes exist
  end
  origmx = size(x.data,1);    %store this to evaluate with CVI vector in a moment.
  x      = x(xinclude{1},:);
else
  origmx  = size(x,1);    %store this to evaluate with CVI vector in a moment.
  xinclude = {1:size(x,1) 1:size(x,2)};
end
mx = size(x,1);
nx = length(xinclude{2});

if isnumeric(options.weightsvect) & length(options.weightsvect)==origmx;
  %if weights are same length as original X samples, apply include field
  options.weightsvect = options.weightsvect(xinclude{1});
end

if nargout <= 1 & strcmp(options.structureoutput,'yes');
  structureoutput = true;
else
  structureoutput = false;
end

%Y-block testing
reg = helperfn('isregression');

if ~reg
  %make a fake y block - not used in PCA
  y           = [];%zeros(mx,1);
  reg         = false;
  cvpred      = [];
  ny          = 1;  %fake one y so array creation works
  
  if nx>1000    %if number of variables is too large force fastpca off
    options.fastpca = false;
  end
  
else
  %check y-block for errors
  if isempty(y)
    error(['Y-block is empty. It is required for method ''',rm,'''.'])
  end
  if ~isa(y,'dataset');
    y = dataset(y);
  end
  
  if size(y,2)==mx & size(y,1)~=mx & size(y,1)~=origmx
    %does it appear to be transposed? then do so
    y = y';
  end

  include  = y.include;
  if length(xinclude{1})~=length(include{1}) | any(xinclude{1}~=include{1});
    %match up x and y row include fields
    include{1} = intersect(xinclude{1},include{1});
    keep(xinclude{1})=1:length(xinclude{1});
    x = nindex(x,keep(include{1}),1);     %extract subset of x
    mx = size(x,1);
    xinclude{1} = include{1};
    if out
      disp('Warning: Number of samples included in X and Y are not equal.')
      disp('Using intersection of included X and Y samples.')
    end
  end
  
  if ~isempty(options.testx);
    %have testx?     
    if ~isdataset(options.testx)
      options.testx = dataset(options.testx);
    end

    %apply calibration y include field to testy if present and relevent
    if ~isempty(options.testy)
      %copy include field from x to y (if dso in y)
      tinclx = options.testx.include{1};
      if isdataset(options.testy)
        tincly = options.testy.include{1};
      else
        tincly = 1:size(options.testy,1);
      end
      
      if isdataset(options.testy)
        options.testy = options.testy.data;
      end
      
      %make sure test x and y samples match
      tincl = intersect(tinclx,tincly);
      options.testx.include{1} = tincl;
      options.testy = options.testy(tincl,:);
      
      if size(options.testy,2)>length(include{2})
        %more y-columns in test than in included y?
        if all(include{2}<=size(options.testy,2))
          %if we can, apply include field to testy
          options.testy = options.testy(:,include{2});
        end
      end
    end
   
    %check if sizes match now
    if length(options.testx.include{1})~=size(options.testy,1);
      error('Number of rows in validation X and validation Y blocks must match.')
    end

  end
  
  %apply include field and extract from DSO
  y = y.data(include{:}); 
  if size(y,1) ~= mx;
    error('The number of rows in X- and Y-blocks must be equal.')
  end
  reg         = true;
  if any((max(y) - min(y))==0);
    error('The included samples must have different Y values to calculate regression')
  end
  
  if ~isempty(options.testy) & size(options.testy,2)~=size(y,2)
    %if y-columns do not match...
    error('Number of columns in validation Y do not match those in the calibration Y block.')
  end
  
  [my,ny] = size(y);
end

%extract testx from DSO and compare to x
if ~isempty(options.testx)
  if isdataset(x)
    %match up x-block columns with testx-block columns
    options.testx = matchvars(x,options.testx);
    
    %and copy include fields
    for nd = 2:ndims(x)
      if max(x.include{nd})<=size(options.testx,nd)
        options.testx.include{nd} = x.include{nd};
      end
    end
  end
  
  %test size of x and testx
  if isdataset(x)
    szx = cellfun('length',x.include);
  else
    szx = size(x);
  end
  sztx = cellfun('length',options.testx.include);
  if length(szx)~=length(sztx) | ~all(szx(2:end)==sztx(2:end));
    error('Validation X-block and Calibration X-block do not match in size in variable mode(s).')
  end
end

%CVI testing
% special preparation for custom case
if ~isempty(cvi) & iscell(cvi) & length(cvi)>1 & ischar(cvi{1}) & strcmp(cvi{1}, 'custom')
  cvi = cvi{2};
end
if isa(cvi,'cell')
  if isempty(cvi)
    error('cvi must contain a method.')
  elseif any(strcmpi(cvi{1},{'vet','con'})) & length(cvi)<2
    error('cvi must contain number of splits when cvi{1} = ''vet'' or ''con''.')
  elseif strcmpi(cvi{1},'rnd') & length(cvi)<3
    error('cvi must contain both number of splits and iterations when cvi{1} = ''rnd''.')
  end
  cvimethod = cvi{1};
  if strcmpi(cvi{1},'vet') & length(cvi)>2
    %NOTE: vet uses its to indicate how many samples to include in each block (thickness of blinds) NOT iterations!
    reportedits = cvi{3};
    its = 1;
  elseif strcmpi(cvi{1},'rnd') | (length(cvi)>2 && ~isempty(cvi{3}))
    its = cvi{3};
    reportedits = its;
  else
    its = 1;
    reportedits = its;
  end
  if length(cvi)>1
    splits = cvi{2};
  else
    splits = [];
  end
  cvi   = encodemethod(mx,cvi);
elseif isa(cvi,'double')
  if length(cvi) ~= origmx
    error('length(cvi) must equal the total number of x samples.')
  end
  cvimethod = 'user';
  cvi = cvi(xinclude{1});           % use only x-included classes
  cvi = cvi(:);
  splits = cvi;
  its = 1;
  reportedits = its;
else
  error('cvi must be cell or double.')
end
options.cvi = {cvimethod splits reportedits};

%call for permutation test, after testing cvi
if strcmp(options.permutation,'yes')
  options.rmsec = 'yes';
  options.ncompvector = 'yes';
  press = permutetest(x,y,rm,cvi,ncompvector,options);
  return
end

%determine smallest cal set and limit ncomp to that #
blocks = unique(cvi(cvi>0))';
if isempty(blocks);
  %special case: they didn't specify any true swap-out sets. Check if they
  %gave -1s and -2s
  if ~any(cvi==-1);
    error('When no test sets are identified, CVI must contain some samples marked as always in the calibration set by using "-1".')
  elseif ~any(cvi==-2)
    error('CVI must contain some samples marked as left out either by using "-2" or by using a set number > 0');
  else
    %ok. only 1s and 2s, translate "always in test set" samples to swapout set 1
    cvi(cvi==-2) = 1;
    blocks = 1;
  end
end
for i = 1:length(blocks);
  classsize(i) = sum(cvi==blocks(i));
end

if ismember(rm,crossval_builtin('rankdependent_methods'))
  % Should ncomp be limited by rank of X-block?
  if ncomp > min(length(cvi)-classsize);
    if out; warning('EVRI:CrossvalNcompLimit','Resetting ncomp to be equal to number of samples in smallest cross-validation cal set'); end
    ncompvector(ncompvector>min(length(cvi)-classsize)) = [];
    ncomp = max(ncompvector);
    if isempty(ncomp) | ncomp<1; error('Invalid CVI setting'); end
  end
end

%Preprocessing testing
if isa(options.preprocessing,'struct');     %is options.preprocessing a preprocessing structure?
  error('(options.preprocessing) must be "0", "1", or 2 element cell array of two preprocessing structures.')  %give error (needs to be CELL or structure)
end

% Set preproflag to one of the following choices:
%   preproflag = 'cell';
%   preproflag = '2wayshorthand'; (using numerical value to trigger preprocesing)
%   preproflag = 'nwayshorthand'; (using numerical value to trigger preprocesing)
if isa(options.preprocessing,'cell')   %a cell of preprocessing structures (x-block & y-block)?
  preproflag = 'cell';
  if isempty(options.preprocessing);
    options.preprocessing = {[] []};   %empty cell = no preprocessing
  end
  if length(options.preprocessing)==1;
    options.preprocessing = {options.preprocessing{1} []};      %single element cell is for x-block only
  end
  if length(options.preprocessing)>2
    error('(options.preprocessing) must be "0", "1", or 2 element cell array of two preprocessing structures.')  %give error (needs to be CELL or structure)
  end
  if (~isa(options.preprocessing{1},'struct') & ~isempty(options.preprocessing{1})) | ...
      (~isa(options.preprocessing{2},'struct') & ~isempty(options.preprocessing{2}));  %not structures or empty in cells
    try
      if ~isempty(options.preprocessing{1}) & ~isstruct(options.preprocessing{1})
        options.preprocessing{1} = preprocess('default',options.preprocessing{1});    %see if we can interpret it as a default string or cell of strings
      end
      if ~isempty(options.preprocessing{2}) & ~isstruct(options.preprocessing{2})
        options.preprocessing{2} = preprocess('default',options.preprocessing{2});
      end
    catch
      error('(options.preprocessing) must be 0, 1, or 2 element cell array of two preprocessing structures.')  %give error (needs to be CELL or structure or interpretable)
    end
  end
  %test for special cases we can convert to hard-coded methods
  if ndims(x)<3
    if isempty(options.preprocessing{1}) & isempty(options.preprocessing{2});
      options.preprocessing = 0;
      preproflag = '2wayshorthand';
    elseif length(options.preprocessing{1})==1 & length(options.preprocessing{2})==1 ...
        & strcmp(options.preprocessing{1}.description,'Mean Center') & strcmp(options.preprocessing{2}.description,'Mean Center');
      options.preprocessing = 1;
      preproflag = '2wayshorthand';
    elseif length(options.preprocessing{1})==1 & length(options.preprocessing{2})==1 ...
        & strcmp(options.preprocessing{1}.description,'Autoscale') & strcmp(options.preprocessing{2}.description,'Autoscale');
      options.preprocessing = 2;
      preproflag = '2wayshorthand';
    end
  end
elseif ndims(x)>2;  % n-way, not a cell
  preproflag = 'nwayshorthand';  % means pp{1} and pp{2} are 2xnmodes array
  if isempty(options.preprocessing); options.preprocessing = 1; end
  
  %handles case where user passes scalar "flag" values in place of cell array
  if max(size(options.preprocessing))==1  %if is scalar, repeat same prepro for y
    options.preprocessing(2) = options.preprocessing(1);
  end
  
  %repeat below for each block (element of prepro vector)
  prepro = options.preprocessing;
  options.preprocessing = {};
  for pind = 1:length(prepro);
    if prepro(pind) == 0;
      options.preprocessing{pind} = zeros(2,ndims(x));
    elseif prepro(pind) == 1
      options.preprocessing{pind} = zeros(2,ndims(x));
      options.preprocessing{pind}(1) = 1;
    else
      error('(options.preprocessing) must be "0", "1", or 2 element cell array of two preprocessing structures.')  %give error (needs to be CELL or structure)
    end
  end
else   % 2-way, not a cell
  preproflag = '2wayshorthand'; % 2-way shorthand (0/1/2) scalar value
  % TBI
end

%prepare options if needed
autoopts = auto('options');
autoopts.norecon = 'true';
mncnopts = mncn('options');
mncnopts.norecon = 'true';

if strcmp(options.discrim,'yes') | islogical(y);    %logical y? do discriminant analysis
  discrim = 1;
  
  waslogicaly = islogical(y);
  y = double(y);

  if ismember(rm,{'nip' 'sim'}) & ny==1
    %PLSDA mode with single-column y
    if ~isempty(y) & isempty(setdiff(unique(y(:,1)),[0 1]))
      %single column logical (only 0 and 1), convert to two-class logical
      y = [y double(~y)];
    else
      y = class2logical(y);
      y = double(y.data);
    end
    ny = size(y,2);
  end
  
  if ny>1 | waslogicaly
    %find # of classes for each y and # in each class
    for yi = 1:ny;
      classes        = unique(y(:,yi));
      misclassed(yi) = {zeros(length(classes),ncomp)};
    end
    classy = false;
  else
    %single-column version: find # of classes for each y and # in each class
    classy  = true;
    classes = setdiff(unique(y(:,1)),0);
    for yi = 1:length(classes);
      misclassed(yi) = {zeros(2,ncomp)};
    end
  end
  
  if ~reg;  %pca threshold
    %     error('discriminant Analysis PCA Crossvalidation not supported');
    if isempty(options.threshold); options.threshold = 1; end
  end
  
  %prepare cost
  cost = [];
  
  %preprare prior
  if ~isa(options.prior,'cell');
    if isempty(options.prior);
      options.prior = 0.5;
    end
    if length(options.prior)==1
      options.prior = ones(1,ny)*options.prior;
    end
    if size(options.prior,1)==1;
      nonInfs = ~isinf(options.prior);
      noninfpriors = options.prior(nonInfs);
      if any(noninfpriors>1) | any(noninfpriors<0)
        error('All values for (options.prior) must be between zero and one, or Inf');
      end
      %get other part of fraction
      options.prior = [1-options.prior; options.prior];
    end
    %convert to cell
    for j = 1:size(options.prior,2);
      temp{j} = options.prior(:,j);
    end
    options.prior = temp;
  else
    %prior was a cell - assume the user knows the format (unpublished as of
    %now)
    %Format is: one cell for each column of y. Each cell contains a vector
    %equal in length to the number of classes in the column
  end
  
  if out; disp('Performing discriminant analysis'); end
else
  discrim    = 0;
  misclassed = cell(0);
end

%prepare any options structures we'll use
% opts is used in precalcmodel and apply
opts = helperfn('getoptions',options);

%Initial preprocess items which are row-wise can be done now
if isa(options.preprocessing,'cell');
  %x-block
  pp = options.preprocessing{1};
  if ~isempty(pp) & isstruct(pp)
    rowwise = min(find([pp.caloutputs]>0))-1;
    if isempty(rowwise)  %NONE of the preprocessing items needed caloutputs
      rowwise = length(pp);  %do them ALL in advance
    end
    if rowwise>0
      donow = pp(1:rowwise);
      x  = preprocess('calibrate',donow,x);
      if ~isempty(options.testx)
        xt = preprocess('calibrate', donow, options.testx);
        options.testx = xt.data.include;
      end
      options.preprocessing{1} = pp(rowwise+1:end);
    end
  end
  
end

%extract from dataset
asdso = false;  %assume we DO want to extract (or we aren't a DSO to begin with)
if isa(x,'dataset');
  if strcmp(preproflag,'cell');
    %check if we have any preprocessing items which will require the DSO
    pp = options.preprocessing{1};
    if ~isempty(pp) & isstruct(pp)
      usesdso = [pp.usesdataset];
      usesdso(ismember({pp.keyword},{'Autoscale'})) = 0; %with the exception of these methods...
      if any(usesdso)  %if any preprocessing uses DSOs
        asdso = true;  %we need to keep it as a DSO
      end
    end
  end
  if ~asdso
    %if no reason NOT to extract, do so now (to speed up algorithm)
    tempinclude = x.include;
    xinclude(2:end) = tempinclude(2:end);
    x = x.data(:,xinclude{2:end});
  end
end



%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Do Actual Cross-Validation

%initialize matrices
if reg & (structureoutput | nargout >4)
  cvpred  = zeros(origmx,size(y,2),ncomp)*nan;
else
  cvpred  = [];
end
cpred   = cvpred;
regvect   = [];
y_orig    = y;
cumpress  = zeros(ny,ncomp);
ppx       = [];   % initialized

%ititialize timer and waitbar info
updatewaitbar;
ssq = [];
lcvk    = length(blocks);

for iiits=1:its
  itst0   = find(cvi==-2);      % test samples
  ical0   = find(cvi==-1);      % cal samples
  isamp   = find(cvi>0);        % subsets
  canuse  = [isamp;ical0];       % -1 or >0
  if iiits>1;           %multiple iterations
    if strcmp(cvimethod,'rnd')
      %with rnd
      cvi(isamp)   = shuffle(cvi(isamp));
    else
      %with others
      offset      = ceil(rand(1)*length(isamp));  %random offset shuffle
      cvi(isamp) = cvi(isamp([offset:end 1:offset-1]));
    end
  end
  for ii = 1:lcvk;
    samps{ii,1} = find(cvi==blocks(ii));
  end
  if iiits == 1;
    press   = zeros(lcvk*ny,ncomp);
  end
  
  for ii=1:lcvk
    %create indicies for test/cal selection
    itst  = [itst0;samps{ii}];
    ical  = setdiff(canuse,itst')';
    %preprocess
    caly = [];
    if strcmp(preproflag,'cell')
      if reg;
        [caly,ppy]  = preprocess('calibrate',options.preprocessing{2},y(ical,:));
        caly        = caly.data;
      end
      
      [calx,ppx]  = preprocess('calibrate',options.preprocessing{1},nindex(x,ical,1),caly);
      [tstx,ppx]  = preprocess('apply',ppx,nindex(x,itst,1));
      
      if asdso
        %if we came into preprocessing with a DSO, extract using include
        %fields now
        calx = calx.data(:,xinclude{2:end});
        tstx = tstx.data(:,xinclude{2:end});
      else
        %otherwise, simply exraction should work
        calx        = calx.data;
        tstx        = tstx.data;
      end
      if reg
        tsty        = y(itst,:);       %don't preprocess this, we'll undo our predictions before comparison, just extract tsty..
      end
      
    elseif strcmp(preproflag, '2wayshorthand')
     
      switch options.preprocessing;
        case 2    %autoscale
          [calx,mnsx,sclx]   = auto(nindex(x,ical,1),autoopts);
          tstx               = scale(nindex(x,itst,1),mnsx,sclx);
          if reg
            [caly,mnsy,scly] = auto(y(ical,:),autoopts);
            tsty             = y(itst,:);
          end
        case 1    %mean centering
          [calx,mnsx]   = mncn(nindex(x,ical,1),mncnopts);
          tstx          = scale(nindex(x,itst,1),mnsx);
          if reg
            [caly,mnsy] = mncn(y(ical,:),mncnopts);
            tsty        = y(itst,:);
          end
        case 0
          calx    = nindex(x, {ical}, 1);
          tstx    = nindex(x, {itst}, 1);
          if reg
            caly  = y(ical,:);
            tsty  = y(itst,:);
          end
      end
    elseif  strcmp(preproflag, 'nwayshorthand')% RB/Donal
      npopt = npreprocess('options');
      npopt.display = 'off';
      [calx,preparx] = npreprocess(nindex(x,ical,1),options.preprocessing{1},[],0,npopt);
      [tstx]         = npreprocess(nindex(x,itst,1),options.preprocessing{1},preparx,0,npopt);
      if reg;
        [caly,prepary] = npreprocess(nindex(y,ical,1),options.preprocessing{2},[],0,npopt);
        [tsty]         = nindex(y,itst,1);
      end
    end
    
    %copy appropriate weights into opts if needed
    if ~isempty(options.weightsvect) & length(options.weightsvect)>=max(ical)
      %and appropriate length
      opts.weights = options.weightsvect(ical);
    elseif ~isempty(options.weightsvect) & strcmpi(options.weights,'custom')
      error('Could not use sample weighting provided - may not match samples in data')
    elseif ~isempty(options.weightsvect)
      opts.weights = options.weightsvect;
    elseif strcmpi(options.weights,'hist')
      %explicitly copy "hist" into weigths (the one string we support)
      opts.weights = 'hist';
    else
      opts.weights = [];
    end

    opts = helperfn('updateopts', opts, 'ppx', ppx);
    
    try
      %regress/decompose
      bbr = helperfn('precalcmodel',calx,caly,ncomp,opts);
    catch
      le = lasterror;
      le.message = ['Unable to cross-validate - error in call to regression/decomposition method.' 10 le.message];
      rethrow(le);
    end
    
    if strcmp(options.jackknife,'yes') & isnumeric(bbr) & ~isempty(bbr)
      %store regression vectors
      regvect(:,:,ii) = bbr;
    end
    
    % update cvi in OPTIONS for each CV subset   // cvi SHOULD be vector
    newopts = opts;
    if isfield(opts,'cvi')
      newopts.cvi = {'custom' cvi(ical)};
    end

    % which classes have samples present in this cal CV subsets?
    icvuse = any(caly);    % columns of caly which are not all zeros
    inycls = 1:ny;
    
    %predict for all #s of ncomps
    for comp= ncompvector
      if reg      %regression method predict
        try
          %found a crossval helper function, use it
          [ypred,bbr] = helperfn('apply',calx,caly,tstx,bbr,comp,newopts);

          % method may not predict for all classes if some classes are not 
          % present in calx samples for this CV split
          if size(ypred,2) < ny
            % then only use classes which are present in the calx samples
            icvcls = inycls(icvuse);
          else
            icvcls = inycls;
          end
        catch
          le = lasterror;
          le.message = ['Unable to cross-validate - error in call to regression/decomposition method. ' 10 le.message];
          rethrow(le);
        end
        
        %undo preprocessing on y-predictions
        if strcmp(preproflag,'cell')
          ypred = preprocess('undo',ppy,ypred);
          ypred = ypred.data;
        elseif strcmp(preproflag,'2wayshorthand')
          switch options.preprocessing
            case 2
              ypred = rescale(ypred,mnsy,scly);
            case 1
              ypred = rescale(ypred,mnsy);
            case 0
          end
        elseif strcmp(preproflag,'nwayshorthand')
          ypred  = npreprocess(ypred,options.preprocessing{2},prepary,1,npopt);
        end
        
        if structureoutput | nargout > 4;
          if its>1 & iiits>1
            %if doing multiple iterations, do SUM of y predicted (we'll
            %normalize later to get average)
            cvpred(xinclude{1}(itst),icvcls,comp) = cvpred(xinclude{1}(itst),1:ny,comp)+ypred;
          else
            cvpred(xinclude{1}(itst),icvcls,comp) = ypred;
          end
        end
        
        deltay = zeros(size(tsty));
        deltay(:,icvcls) = ypred-tsty(:,icvcls);
        if isfieldcheck(options, '.rmoptions.functionname')
          fname = lower(options.rmoptions.functionname);
          if ismember(fname, {'svmda' 'xgbda' 'annda' 'lregda' 'lda'})
            deltay = round(deltay) ~= 0;
          end
        end
        
        press((ii-1)*ny+1:ii*ny,comp) = press((ii-1)*ny+1:ii*ny,comp)+sum((deltay).^2,1)';
        
        ntest((ii-1)*ny+1:ii*ny,comp) = size(ypred,1);
        
        if discrim; %discrim. method predict
          if classy
            %handle single-column DA methods
            ypred = interp1(classes,classes,ypred,'nearest');
            for oneclass = 1:length(classes);
              inclass = (tsty(:,1) == classes(oneclass));
              notinclass = ~inclass & (tsty(:,1)~=0);
              if any(~inclass);     %calc misclassed
                misclassed{oneclass}(1,comp) = misclassed{oneclass}(1,comp) + ...
                  sum(~isfinite(ypred(notinclass,1)) | ypred(notinclass,1) == classes(oneclass));  %false positives
              end
              if any(inclass);     %calc misclassed
                misclassed{oneclass}(2,comp) = misclassed{oneclass}(2,comp) + ...
                  sum(~isfinite(ypred(inclass,1)) | ypred(inclass,1) ~= classes(oneclass));  %false negatives
              end
              % ntest(y_column, class_index, leave-out_set)
              discrim_ntest{oneclass}(ii,1:2,comp) = [sum(notinclass) sum(inclass)];
            end
            
          else
            %handle all other DA methods
            [calpred,bbr] = helperfn('apply',calx,caly,[],bbr,comp,newopts);
            if strcmp(preproflag,'cell')
              calpred = preprocess('undo',ppy,calpred);
              calpred = calpred.data;
            elseif strcmp(preproflag,'2wayshorthand') 
              switch options.preprocessing
                case 2
                  calpred = rescale(calpred,mnsy,scly);
                case 1
                  calpred = rescale(calpred,mnsy);
                case 0
              end
            elseif strcmp(preproflag,'nwayshorthand') 
              % TBI
            end
            for yj = 1:size(icvcls,2)
              yi = icvcls(yj);
              %determine thresholds
              if ~isempty(options.threshold) & isa(options.threshold,'double')
                threshold = options.threshold;
              else
                prior = options.prior{yi}';
                threshold = plsdthres(y(ical,yi),calpred(:,yj),cost,prior,0);
              end
              threshold = [-inf threshold inf];
              %run through classes to find sum of false IDs for each class
              classes = unique(round([y(ical,yi);tsty(:,yi)]));
              for oneclass = 1:length(classes);
                inclass = (tsty(:,yi) == classes(oneclass));
                if any(inclass)     %calc misclassed
                  tmp = sum(~isfinite(ypred(inclass,yj)) | ypred(inclass,yj) < threshold(oneclass) | ypred(inclass,yj) >= threshold(oneclass+1));
                  misclassed{yi}(oneclass,comp) = misclassed{yi}(oneclass,comp) + ...
                    sum(~isfinite(ypred(inclass,yj)) | ypred(inclass,yj) < threshold(oneclass) | ypred(inclass,yj) >= threshold(oneclass+1));
                end
                % ntest(y_column, class_index, leave-out_set)
                discrim_ntest{yi}(ii,oneclass,comp) = sum(inclass);
              end
            end
          end
        end    %end of discrim. method
        
      else  %decomposition analyses
        % set pca cross-validation (will only be used for pca models)
        % for consistency with @evrimodel\crossvalidate
        if isdataset(calx) 
          nvars = length(calx.include{2});
        else
          nvars = size(calx,2);
        end
        if nvars>25
          opts.pcacvi = {'con' min(10,floor(sqrt(nvars)))};
        else
          opts.pcacvi = {'loo'};
        end
        
        [ssresid,bbr] = helperfn('apply',calx,[],tstx,bbr,comp,opts);
        press(ii,comp) = press(ii,comp)+ssresid;
        ntest((ii-1)*ny+1:ii*ny,comp) = size(tstx,1);
        
      end  %end regression vs. decomp.

      updatewaitbar(comp,ii,iiits,ncompvector,its,lcvk,options,rm)
      
    end  %end of comp (ncomp)
  end  %end of ii (splits)
end   %end of iiits (iterations)
clear calx tstx caly tsty ical itst ypred replacemat

%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Calculate statistics from cross-validated results

for jj=1:ny
  cumpress(jj,:) = sum(press(jj:ny:lcvk*ny,:),1)/its;
end
if (structureoutput | nargout > 4) & its>1
  %if doing multiple iterations, normalize y predicted to get average
  cvpred = cvpred / its;
end

%multiple y-columns?
if ny > 1
  %re-order press
  mp = size(press,1);
  ind   = zeros(mp,1);
  blk  = mp/ny;
  for ii=1:ny
    ind((ii-1)*blk+1:blk*ii,1) = (ii:ny:mp)';
  end
  press = press(ind,:);
end

if reg
  q2y = 1-cumpress./(sum(mncn(y).^2,1)'*ones(1,ncomp));
else
  q2y = [];
end

%calculate RMSECV and classification error
rmsecv = sqrt(cumpress*diag(ny./sum(ntest,1)));

if discrim
  if ~classy
    %all other DA models correction code
    for yi=1:ny;
      misclassed{yi} = misclassed{yi} ./ shiftdim(sum(discrim_ntest{yi},1),1) ./ its;    %correct for # in class and # of iterations
      temp = diag(options.prior{yi})*misclassed{yi};    %correct for prior probabilities
      classerrcv(yi,:) = sum(temp);
    end
  else
    %single-column correction code
    for oneclass=1:length(classes);
      misclassed{oneclass} = misclassed{oneclass} ./ shiftdim(sum(discrim_ntest{oneclass},1),1) ./ its;    %correct for # in class and # of iterations
      temp = diag(options.prior{1})*misclassed{oneclass};
      classerrcv(oneclass,:) = sum(temp);
    end
  end
else
  %not discrim mode, initialize classification errors as empty
  classerrc  = [];
  classerrcv = [];
end

%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Do self-prediction calculations (model all data, apply to all data)
if (structureoutput & strcmp(options.rmsec,'yes')) | nargout > 3 | out | strcmp(options.plots,'final');
  %Initialize results matrices
  cvbias = [];
  r2cv   = [];
  cbias  = [];
  r2c    = [];
  rmsep  = [];
  r2y    = [];
  if reg
    rmsec         = nan(size(cumpress));
    if ~isempty(options.testx)
      rmsep         = nan(size(cumpress));
    end
  end
  y = y_orig;
  if strcmp(preproflag,'cell')
    if reg;
      [y,ppy] = preprocess('calibrate',options.preprocessing{2},y);
    end
    [x,ppx] = preprocess('calibrate',options.preprocessing{1},x,y);
    if ~isempty(options.testx)
      options.testx = preprocess('apply',ppx,options.testx);
    end
    if asdso
      %if we came into preprocessing with a DSO, extract using include
      %fields now
      x = x.data(:,xinclude{2:end});
    else
      %otherwise, simply exraction should work
      x = x.data;
    end
    if reg
      y = y.data;
    end
  elseif strcmp(preproflag,'2wayshorthand')
    switch options.preprocessing
      case 2
        [x,mnsx,sclx] = auto(x,autoopts);
        if reg
          [y,mnsy,scly] = auto(y,autoopts);
        end
        if ~isempty(options.testx)
          options.testx = scale(options.testx,mnsx,sclx);
        end
      case 1
        [x,mnsx] = mncn(x,mncnopts);
        if reg
          [y,mnsy] = mncn(y,mncnopts);
        end
        if ~isempty(options.testx)
          options.testx = scale(options.testx,mnsx);
        end
      case 0
        %no preprocessing
    end
  elseif strcmp(preproflag,'nwayshorthand')
    x = npreprocess(x,options.preprocessing{1},[],0,npopt);
    if reg
      [y,prepary] = npreprocess(y,options.preprocessing{2},[],0,npopt);
    end
  end
  if ~isempty(options.testx) & isdataset(options.testx)
    options.testx = options.testx.data.include;
  end

  %copy appropriate weights into opts if needed
  if isfield(opts,'weights')
    opts.weights = options.weightsvect;
  end
 
  opts = helperfn('updateopts', opts, 'ppx', ppx);
    
  % update cvi in OPTIONS for each CV subset   // cvi SHOULD be vector
  newopts = opts;
  if isfield(opts,'cvi')
    newopts.cvi = {'custom' cvi};
  end

  if reg     %regression methods
    try
      [bbr,ssq] = helperfn('precalcmodel',x,y,ncomp,newopts);
    catch
      le = lasterror;
      le.message = ['Unable to cross-validate - error in call to regression/decomposition method. ' 10 le.message];
      rethrow(le);
    end
    
    for comp= ncompvector
      %apply model to calibration x
      try
        ypred = helperfn('apply',x,y,[],bbr,comp,newopts);
      catch
        le = lasterror;
        le.message = ['Unable to cross-validate - error in call to regression/decomposition method. ' 10 le.message];
        rethrow(le);
      end
      
      options = helperfn('updateopts', options, 'testx', []);
      %apply model to testx (if present)
      if ~isempty(options.testx) %apply to testx if present
        testypred = helperfn('apply',x,y,options.testx,bbr,comp,newopts);
      else
        testypred = [];
      end
      
      if strcmp(preproflag,'cell')  %undo preprocessing on ypred
        ypred = preprocess('undo',ppy,ypred);
        ypred = ypred.data;
        if ~isempty(options.testx);
          testypred = preprocess('undo',ppy,testypred);
          testypred = testypred.data;
        end
      elseif strcmp(preproflag,'nwayshorthand')
        [ypred,prepary] = npreprocess(ypred,options.preprocessing{2},prepary,1,npopt);
      elseif strcmp(preproflag,'2wayshorthand')
        switch options.preprocessing
          case 2
            ypred = rescale(ypred,mnsy,scly);
            if ~isempty(options.testx);
              testypred = rescale(testypred,mnsy,scly);
            end
          case 1
            ypred = rescale(ypred,mnsy);
            if ~isempty(options.testx);
              testypred = rescale(testypred,mnsy);
            end
          case 0
        end
      end
      
      resc = ypred-y_orig;             %calc residuals
      cpred(include{1},:,comp) = ypred;
      rmsec(:,comp) = sum(resc.^2)';   %calc RMSEC
      if ~isempty(options.testx);      %calc RMSEP
        rmsep(:,comp) = sum((testypred-options.testy).^2)';
      end
      if discrim %discrim. method predict
        if ~classy  %multi-column y DA predict
          classerrc(:,comp) = 0;
          for yi = 1:size(y,2);
            prior = options.prior{yi}';
            [threshold,secmisclassed] = plsdthres(y_orig(:,yi),ypred(:,yi),cost,prior,0);
            classerrc(yi,comp) = sum(diag(prior) * secmisclassed(:,2));
          end
        else
          %single-column y discrim predict
          yi = 1;
          ypred = interp1(classes,classes,ypred,'nearest');
          for oneclass = 1:length(classes)
            prior = options.prior{yi}';
            inclass = y_orig(:,yi)==classes(oneclass);
            notinclass = ~inclass & (y_orig(:,yi)~=0);
            secmisclassed = [mean(ypred(notinclass,yi)==classes(oneclass)); mean(ypred(inclass,yi)~=classes(oneclass))];
            classerrc(oneclass,comp) = sum(diag(prior)*secmisclassed);
          end
        end
      end    %end of discrim. method
      
      updatewaitbar(comp+ncomp,ii,iiits,ncompvector,its,lcvk,options,rm)

    end
      
    %finalize stats
    r2y = 1 - rmsec./(sum(mncn(y_orig).^2,1)'*ones(1,ncomp));
    rmsec = sqrt(rmsec/mx);
    if ~isempty(options.testx);
      rmsep = sqrt(rmsep/size(options.testx,1));
    end
    
    %calculate bias and R2
    if ~isempty(cvpred)
      cvbias = ones(size(y_orig,2),ncomp)*NaN;
      r2cv   = cvbias;
      for ycol = 1:size(y_orig,2);
        cvbias(ycol,1:ncomp) = mean(scale(squeeze(cvpred(include{1},ycol,:))',y_orig(:,ycol)'),2)';
        r2 = r2calc(squeeze(cvpred(include{1},ycol,:))',y_orig(:,ycol)');
        if ~isempty(r2)
          r2cv(ycol,1:ncomp) = r2;
        end
      end
    else
      cvbias = [];
      r2cv   = [];
    end
    if ~isempty(cpred)
      cbias = ones(size(y_orig,2),ncomp)*NaN;
      r2c   = cbias;
      for ycol = 1:size(y_orig,2);
        cbias(ycol,1:ncomp) = mean(scale(squeeze(cpred(include{1},ycol,:))',y_orig(:,ycol)'),2)';
        r2 = r2calc(squeeze(cpred(include{1},ycol,:))',y_orig(:,ycol)');
        if ~isempty(r2)
          r2c(ycol,1:ncomp) = r2;
        end
      end
    else
      cbias  = [];
      r2c    = [];
    end

  else   %NON-regression methods
    
    switch rm
      case 'pca'
        
        opts.display = 'off';
        opts.algorithm = 'auto';
        [ssq,datarank,v,t] = pcaengine(x,ncomp,opts);
        ncomp = min(ncomp,datarank);
        
        rmsec = nan(1,size(press,2));      
        res   = x;                           
        for comp=1:ncomp                       
          res = res-t(:,comp)*v(:,comp)';        
          rmsec(1,comp) = sum(sum(res.^2));    
        end                                  
        rmsec = sqrt(rmsec/mx/nx);
      otherwise  %not reported for other model types (TODO: known deficiency)
        rmsec = nan(1,size(press,2));

    end
      
  end

  %display misclassed values if DA
  if discrim;
    if out;
      if ~classy
        %multi y-column discrim mode
        dispmisclass(misclassed,str2cell(num2str((1:ny)')));
      else
        %single-column discrim mode
        dispmisclass(misclassed,str2cell(num2str(classes(:))));
      end
    end
  end
  
  %do plots if desired and possible
  if reg
    %regression method output
    if (strcmp(options.plots,'final'))
      if (ncomp>1)
        %do plots if desired and possible
        figure        
        h = plot(1:ncomp,rmsecv,'-or',1:ncomp,rmsec,'-sb');
        legendname(h(1:ny),'RMSECV');
        legendname(h(ny+1:end),'RMSEC');
        xlabel('Latent Variable')
        if ~isempty(options.testx);
          hold on
          h = plot(1:ncomp,rmsep,'-pc');
          legendname(h,'RMSEP');
          ylabel('RMSECV (o), RMSEC (s), RMSEP (p)');
        else
          ylabel('RMSECV (o), RMSEC (s)')
        end

      end

    end
    if (out~=0) & ~isempty(ssq)
      ssqtable(ssq,ncomp)
    end
    
  else
    %non-regression methods
    
    switch rm
      case 'pca'
        if strcmp(options.plots,'final')
          figure
          h = plotyy(1:ncomp,ssq(1:ncomp,2),1:ncomp,rmsecv(1:ncomp));
          set(get(h(1),'children'),'color',[0 0 1],'marker','p')
          set(get(h(1),'ylabel'),'string','Eigenvalue of Cov(x) (p)','color',[0 0 0])
          set(h(1),'ycolor',[0 0 0])
          set(get(h(2),'children'),'color',[1 0 0],'marker','s')
          set(get(h(2),'ylabel'),'string','RMSECV (s)')
          set(h(2),'ycolor',[0 0 0])
          axes(h(2))
          xlabel('Latent Variable')
        end
        
        if (out~=0)
          ssqtable(ssq,ncomp)
        end
        
      otherwise
        %no output for these model types (TODO: known deficiency)
        
    end
  end
  
else
  rmsec = rmsecv*nan;
end

if havemodel | structureoutput
  %Create structure of all outputs
  temp = [];
  temp.press      = press;
  temp.cumpress   = cumpress;
  temp.rmsecv     = rmsecv;
  temp.rmsec      = rmsec;
  temp.rmsep      = rmsep;
  temp.cvpred     = cvpred;
  temp.cpred      = cpred;
  temp.cvbias     = cvbias;
  temp.cbias      = cbias;
  temp.q2y        = q2y;
  temp.r2y        = r2y;
  temp.r2cv       = r2cv;
  temp.r2c        = r2c;
  temp.cvi        = zeros(1,origmx);
  temp.cvi(xinclude{1}) = cvi;
  temp.classerrc  = classerrc;
  temp.classerrcv = classerrcv;
  temp.misclassed = misclassed;
  temp.reg        = regvect;
  
  if havemodel
    %copy cvi information
    temp.cv    = cvimethod;
    temp.split = splits;
    temp.iter  = reportedits;
    
    %copy appropriate fields over into model structure
    press = copycvfields(temp,model);
    
    if discrim
      %if classification, fill in cross-validated prediction info
      press = multiclassifications(press);
    end
        
  else   %structure output
    
    press = temp;
    
  end
end

updatewaitbar('close')

end

%-----------------------------------------------------------------------------
function [] = dispmisclass(misclassed,values)
  
sz = cellfun('size',misclassed,1);
if any(sz~=2); return; end  %not supported for multi-level multi-column cv

disp('  ')
disp('      Fractional False Postive(FP) and False Negatives(FN)    ')
disp('  ')

%create data of aggregated misclassed values to display
dat = cat(1,1:size(misclassed{1},2),misclassed{:});

%add spaces to values to center each
l = cellfun('length',values);
ml = max(20,max(l));
bl = ml-l;  %number of blanks needed for each string
bl = floor(bl/2);  %half of that to center
for j=1:length(values)
  values{j} = [values{j} blanks(bl(j))];
end
format = ['   %3.0f     ' repmat('  %4.3f    ',1,size(dat,1)-1) '\n'];

disp(['  Class: '  sprintf(' %20s ',values{:})]);
disp(['  Comp #   '  repmat('   FP         FN      ',1,length(misclassed))]);
disp(['  ------   '   repmat('  ----     ',1,size(dat,1)-1)]);
disp(sprintf(format,dat));
end

%----------------------------------------------------------------------
function updatewaitbar(comp,ii,iiits,ncompvector,its,lcvk,options,rm)

persistent itotal wbcheckinterval lasttime waitbarhandle starttime

switch nargin
  case 0  %reinitialize when called with no inputs
    itotal = [];
    wbcheckinterval = 1;
    starttime = now;
    lasttime = now;
    waitbarhandle = [];
    return
  case 1  %string command
    switch comp
      case 'close'
        if ~isempty(waitbarhandle) & ishandle(waitbarhandle);
          close(waitbarhandle);
        end
        return
    end
end

%translate comp and ncomp into linear index
ncomp = length(ncompvector);
comp = find(ncompvector==comp);

if isempty(itotal)  %first time through, initialize total # of cycles
  itotal = lcvk*its*ncomp;
  switch rm
    case 'pca'
      itotal = itotal+1;  %pca only uses ONE cycle to get all-sample models
    otherwise
      itotal = itotal+ncomp;  %+ncomp for building all-samples models
  end
end

if mod(comp,wbcheckinterval)==0  %check only every nth component
  icomplete = comp+(ii-1)*ncomp+(iiits-1)*lcvk*ncomp;
  est = round((now-starttime)/icomplete * (itotal-icomplete)*60*60*24);
  if (now-lasttime)>0.5/60/60/24;
    fcomplete = icomplete/itotal;
    lasttime = now;
    if ~isempty(waitbarhandle)
      drawnow;
      if ~ishandle(waitbarhandle);
        error('Terminated by user...');
      end
      waitbar(fcomplete);
      set(waitbarhandle,'name',['Est. Time Remaining: ' besttime(est)])
    elseif est > options.waitbartrigger
      desc = 'Cross-Validating...';
      waitbarhandle = waitbar(fcomplete,[ desc ' (Close to cancel)']);
      set(waitbarhandle,'name',['Est. Time Remaining: ' besttime(est)])
    else
      %estimated time not beyond threshold - extend time between checks
      wbcheckinterval = min(wbcheckinterval*2,ncomp);
    end
  else
    %time bewtween checks < minimum, extend time between checks
    wbcheckinterval = min(wbcheckinterval*4,ncomp);
  end
end
end

%------------------------------------------------
function rx = rescale(x,means,stds)
%RESCALE Scales data back to original scaling.
%I/O: rx = rescale(x,means,stds,options);
%I/O: rx = rescale(x,means);

%extracted from standard rescale to allow faster operation in controlled
%input environment
[m,n] = size(x);

if nargin < 3
  %mean centering done (only)
  rx = x+means(ones(m,1),:);
else
  %standard deviations passed
  rx = (x.*stds(ones(m,1),:))+means(ones(m,1),:);
end
end

%--------------------------------------------------------------------------
function [ncompvector values] = getncompvector(model, ncompvector, ncomp, options)
% Special settings for ncompvector for certain model types
% ncompvector : integer index values
%      values : (optional) values associated with the ncompvector indices

values = [];
  switch lower(model.modeltype)
    case {'ann' 'annda'}
      % Set ncompvector to odd integers, plus 2
      nhid1 = model.detail.options.nhid1;
      if nhid1<=3
        ncompvector = 1:nhid1;
      else
        ncompvector = [1:2 3:2:nhid1];
      end
      %add nhid1 value to ncompvector if it is not there
      if ~ismember(nhid1,ncompvector)
        ncompvector = [ncompvector nhid1];
      end
    case {'anndl' 'anndlda'}
      hid1 = getanndlnhidone(model);
      if ~isempty(model.detail.options.cvskip) && isnumeric(model.detail.options.cvskip)
        ncompvector = 0:model.detail.options.cvskip:hid1; % start at 0 to get expected spacing
        ncompvector(1) = 1;  % changed back to 1
      else
        if hid1<=10
          ncompvector = 1:hid1;
        elseif 10<hid1 & hid1<=100
          myskips = [1 2 3 5];
          for i=myskips(end)+1:hid1
            if mod(i,25)==0
              myskips = [myskips i];
            end
          end
          ncompvector = myskips;
        elseif 100<hid1
          myskips = [10 20 30 50];
          for i=myskips(end)+1:hid1
            if mod(i,100)==0
              myskips = [myskips i];
            end
          end
          ncompvector = myskips;
        end
      end
    
      %add hid1 value to ncompvector if it is not there
      if ~ismember(hid1,ncompvector)
        ncompvector = [ncompvector hid1];
      end

    case {'mlr'}
      ncompvector = 1;
      
    case {'cls'}
      ncompvector = 1;
      if strcmp(model.modeltype, 'CLS')
        % check if last prepro step GLS declutter
        if ~isempty(model.detail.preprocessing{1}) && strcmp(model.detail.preprocessing{1}(end).keyword, 'declutter GLS Weighting')
          if isfieldcheck('.userdata.a', model.detail.preprocessing{1}(end))
            values = model.detail.preprocessing{1}(end).userdata.a;
            ncompvector = 1:length(values);
          end
        end
      end
    case {'lda'} % model.detail.options
      if strcmpi(options.ncompvector,'yes')
        isin = find(model.lvs==ncompvector);
        if ~sum(isin)
          % max is not in there, tack it on
          ncompvector(end+1) = model.lvs;
        end
      else
        ncompvector = min([1 ncompvector(:)']):model.lvs;
      end
    otherwise
      if ncomp<model.lvs
        if strcmpi(options.ncompvector,'yes')
          ncompvector(end+1) = model.lvs;
        else
          ncompvector = min(ncompvector):model.lvs;
        end
      end
  end
end