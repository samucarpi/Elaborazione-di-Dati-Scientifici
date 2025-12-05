function x = splitcaltest(model,options,varargin)
%SPLITCALTEST Splits data into calibration and test sets.
%  Splits data into calibration and test sets based on the model scores.
%  If a matrix or DataSet object are passed in place of a model, it is
%  assumed to contain the scores for the data.
%
%  If usereplicates option is enabled the repidclass option indicates
%  samples to not separate from each other i.e., samples in the same class
%  in (repidclass) are not split apart.
%    When using replicates the replicates are first combined using classcenter 
%    before splitcaltest is applied to the class centered data. Replicates 
%    only contribute to the class centered result if they were not excluded
%    in the input dataset or model. The results of splitting these combined
%    samples are then mapped back to the original replicates, so replicates
%    are never separated in the resulting calibration and test sets.
%
%  INPUTS:
%    model = standard model object from a factor-based model OR
%            data class double or DataSet containing scores.
%            If model or DataSet object is passed the M included scores 
%            [from the soft (include) field] are used.
%            If data class double is passed all M samples are used.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%           plots: [ 'none' | {'final'} ] governs level of plotting.
%       algorithm: [ {'kennardstone'} | 'reducennsamples' | 'onion' | 'duplex' | 'spxy' |'random']
%                    algorithm used to select calibration samples.
%        fraction: [{0.66}] fraction of data to be set as calibration samples.
%          nonion: [{3}]]  onion: the number of 'external layers'
%    loopfraction: [{0.1}] onion: this is the fraction of samples assigned
%                    per onion layer (e.g. the number of samples is approximately
%                    (loopfraction*fraction*M).
%   usereplicates: [{0} | 1] Keep replicates together (1) or not (0).
%      repidclass: [{1}] classset which indicates sample replicates.
%     distmeasure: [{'euclidean'} | 'mahalanobis'] Defines the distance measure
%                    to use for the kennardstone % onion algorithm.
%                    'mahalanobis' scales by the covariance matrix (correcting
%                    for unusually small or large directions). 
% nnt_maxdistance: [{inf}] reducennsamples: Maximum allowed closest distance 
%                    between samples. Sample thinning stops if the two
%                    closest samples are further away than this value.
%  nnt_maxsamples: [{5000}] reducennsamples: Maximum number of samples which 
%                    can be passed for down-sampling. More than this number 
%                    will throw an error.
%
%  OUTPUT:
%    x = a structure containing the class and classlookup table.
%        .class       : a (1,nsamples) vector with values 0, -1, -2
%        .classlookup : classlookup cell array, col 1 is classes, col 2
%                       is class names. Example: 
%                       [ 0]    'never use'
%                       [-1]    'cal set'  
%                       [-2]    'test set' 
%
%I/O: z = splitcaltest(model,options);  %identifies model (calibration step)
%
%See also: DISTSLCT, KENNARDSTONE, REDUCENNSAMPLES

%Copyright Eigenvector Research, Inc. 2013
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if nargin==0; model = 'io'; end
if ischar(model)
  options = [];
  options.name          = 'options';
  options.plots         = 'final';  %Governs plots to make
  options.algorithm     = 'kennardstone';
  options.nonion        = 3;
  options.fraction      = 0.66;
  options.loopfraction  = 0.1;
  options.distmeasure   = 'euclidean';
  options.usereplicates = 0;
  options.repidclass    = 1;
  options.nnt_maxdistance = inf;
  options.nnt_maxsamples  = 5000;
  
  if nargout==0; evriio(mfilename,model,options);
  else           x = evriio(mfilename,model,options); end
  return;
end

if nargin<1
  error([ upper(mfilename) ' requires 1 input.'])
end
if nargin<2
  options = [];
end
if ~isempty(varargin)
  y = varargin{1};
else
  y = [];
end
options = reconopts(options,mfilename);

if ~isempty(options.repidclass) & isnumeric(options.repidclass)
  repidclass = options.repidclass;
else
  repidclass = [];
end
if ~ismodel(model) & ~isdataset(model)
  options.usereplicates = 0;
elseif ismodel(model) & isempty(model.detail.class{1,1,repidclass} )
  options.usereplicates = 0;
end
if options.usereplicates & ~isempty(repidclass)
  % convert model to its scores and create DSO with replicate classset
  if ismodel(model)
    %is a model? extract scores
    if (~isfield(model,'loads') | isempty(model.loads))
      error('Cannot perform automatic split with this model type')
    end
    i0 = model.detail.includ{1};
    repcls = model.detail.class{1,1,repidclass}; % mode 1, X block, repid classset
    model = dataset(model.loads{1});
    model.include{1} = i0;
    model.class{1,repidclass} = repcls;
  end
  
  % combine replicates before splitcaltest
  
  % use classes ranging 1 - number of classes
  repcls = model.class{1,repidclass};
  [j,i,tmprepclasses]=unique(repcls);
  model.class{1,repidclass} = tmprepclasses;
  
  [ccx,mn,cls, npercls] = classcenter(model,repidclass);
  xcomb = dataset(mn);         % mean per unique class
  xcomb.classid{1} = cls;      % the unique classes
  xcompincl1 = 1:length(cls);
  xcomb.include{1} = xcompincl1(npercls>0); % only inc classes with replicates
  x = applysct(xcomb,y,options);
  assignments = x.class(model.class{1,repidclass});   % is -1/-2, and 0 for excludes

  % use input dataset's includes to set class to 0 for excluded samples
  excludemask = ones(size(model,1),1);
  excludemask(model.include{1}) = 0;
  assignments(logical(excludemask)) = 0;
  x.class = assignments;
else
  x = applysct(model,y,options);
end

%--------------------------------------------------------------------------
function [x, i0] = converttoarray(x)
% Convert model or dataset to array, and get the includes. 
% The array returned from a model is the model's scores.
% Input : x  = model, dataset, or array
% Output: x  = array, 
%         i0 = vector of row includes. 
%
if ismodel(x)
  if (~isfield(x,'loads') | isempty(x.loads))
    error('Cannot perform automatic split with this model type')
  end
  %is a suitable model? extract scores
  i0 = x.detail.includ{1};
  x = x.loads{1};
elseif isdataset(x)
  %is a dataset? extract data
  i0 = x.include{1};
  x = x.data;
elseif isnumeric(x)
  i0 = 1:size(x,1);
else
  error('Unrecognized input for model')
end

%--------------------------------------------------------------------------
function [x] = applysct(xin, yin, options)
% Apply splitcaltest method to input DSO xin. Return vector (1,size(xin,1))
% values 0, -1, -2 indicating samples not used, in Cal, and in Test.
% Input : xin = model, dataset, or array
% Output: x  = array, 
%         i0 = vector of row includes. 

[xin, i0] = converttoarray(xin);
if ~isempty(yin)
  [yin, ~] = converttoarray(yin);
end

algorithm = lower(options.algorithm);
switch algorithm
  case 'onion'
    x = sct_onion(xin, i0, options);
    
  case 'reducennsamples'
    x = sct_reducennsamples(xin, i0, options);
    
  case 'kennardstone'
    x = sct_kennardstone(xin, i0, options);
    
  case 'duplex'
    x = sct_duplex(xin, i0, options);
    
  case 'spxy'
    x = sct_spxy(xin, yin, i0, options);
    
  case 'random'
    x = sct_random(xin, i0, options);
    
  otherwise
    error('Unknown ''algorithm'' option: %s', options.algorithm)
end

x.classlookup = {0 'never use'; -1 'cal set'; -2 'test set'};

%--------------------------------------------------------------------------
function x = sct_kennardstone(xin, use, options)
% Apply splitcaltest using the 'Kennard-Stone' algorithm
% Select options.fraction of the 'use' samples for Calibration set.
% The remainder of the 'use' set are set to Test. 
% All samples not in 'use' are set to Never-use.
% INPUT:
%    xin = array
%    use = include vector for rows
% OUTPUT:
%    x = (1,nsamples) vector, values 0, -1, -2, for Never-use, Cal, Test

switch lower(options.distmeasure)
case {'m','mahal','mahalan','mahalanobis'} %use if mahalanobis requested
  ccov   = cov_cv(xin(use,:),struct('display','off','plots','none','sqrt','yes'));
  xin    = xin*ccov; clear ccov
end

[m,n]        = size(xin);
classes      = zeros(1,m); % Never-use
classes(use) = -2;         % Test
incl    = kennardstone(xin(use,:), ceil(length(use)*options.fraction));
cal          = use(incl);  % cal is the subset of use which are Cal
classes(cal) = -1;         % Cal
x.class      = classes;

%--------------------------------------------------------------------------
function x = sct_reducennsamples(xin, use, options)
% Apply splitcaltest using the 'reducennsamples' algorithm
% Select options.fraction of the 'use' samples for Calibration set.
% The remainder of the 'use' set are set to Test. 
% All samples not in 'use' are set to Never-use.
% INPUT:
%    xin = array
%    use = include vector for rows
% OUTPUT:
%    x = (1,nsamples) vector, values 0, -1, -2, for Never-use, Cal, Test

switch lower(options.distmeasure)
case {'m','mahal','mahalan','mahalanobis'} %use if mahalanobis requested
  ccov   = cov_cv(xin(use,:),struct('display','off','plots','none','sqrt','yes'));
  xin    = xin*ccov; clear ccov
end
nntopts      = reducennsamples('options');
nntopts.maxdistance = options.nnt_maxdistance;
nntopts.maxsamples  = options.nnt_maxsamples;
[m,n]        = size(xin);
classes      = zeros(1,m); % Never-use
classes(use) = -2;         % Test
[sc,incl]    = reducennsamples(xin(use,:), ceil(length(use)*options.fraction), nntopts);
cal          = use(incl);  % cal is the subset of use which are Cal
classes(cal) = -1;         % Cal
x.class      = classes;

%--------------------------------------------------------------------------
function x = sct_onion(xin, i0, options)
% Apply splitcaltest using the 'onion' algorithm
% INPUT:
%    xin = array
%    i0  = include vector for rows
% OUTPUT:
%    x = (1,nsamples) vector, values 0, -1, -2, for Never-use, Cal, Test

% Check options fraction and loopfraction are non-negative and <= 1
if options.fraction < 0 | options.fraction > 1
  error('Option ''fraction'' =%4.4g. This must be in range [0, 1]', options.fraction)
end
if options.loopfraction < 0 | options.loopfraction > 1
  error('Option ''loopfraction'' =%4.4g. This must be in range [0, 1]', options.fraction)
end
[m,n]  = size(xin);

%Ensure that Cal and Test have exterior points and sufficiently span the space.
loopfraction = options.loopfraction;
x.class  = zeros(1,m);  % Never-use (not in Cal or Test)

switch lower(options.distmeasure)
case {'m','mahal','mahalan','mahalanobis'} %use if mahalanobis requested
  ccov   = cov_cv(xin(i0,:),struct('display','off','plots','none','sqrt','yes'));
  xin    = xin*ccov; clear ccov
end
for j=1:options.nonion
  m0     = length(i0);  % number of samples not yet assigned to cal or test
  ncal  = max(1,round(loopfraction*m0*options.fraction)); 
  ntest = max(1,round(loopfraction*m0*(1-options.fraction)));
  if m0>0
    isel = distslct(xin(i0,:),min(m0, ncal));
    x.class(i0(isel)) = -1; %Cal
    i0   = delsamps(i0',isel)'; %remove selected samples from consideration
  end
  m0     = length(i0);
  if m0>0
    isel = distslct(xin(i0,:),min(m0, ntest));
    x.class(i0(isel)) = -2; %Test
    i0   = delsamps(i0',isel)'; %remove selected samples from consideration
  end
end

% randomly assign remaining samples to cal and test in desired proportion
% number of samples selected to cal set
ncSelected = length(find(x.class==-1));
% number of samples selected to test set
ntSelected = length(find(x.class==-2));
% remaining number of samples that need to be assigned to cal set 
nc = round(m*options.fraction)-ncSelected;
% remianig number of samples that need to b e assigned to test set
nt = round(m*(1-options.fraction))-ntSelected;

%check if total number of remaining samples (nc+nt) equals remaining samples to
%assign (i0). If these don't equal then we get an error in the
%x.class(i0) = irem' call below.
%if does not equal then try different ceil and floor combos until one of
%them is equal to i0
if nc+nt ~=length(i0)
  nc_ceil = ceil(m*options.fraction)-ncSelected;
  nt_ceil = ceil(m*(1-options.fraction))-ntSelected;
  nc_floor = floor(m*options.fraction)-ncSelected;
  nt_floor = floor(m*(1-options.fraction))-ntSelected;
  if nc_ceil+nt_ceil == length(i0)
    nc = nc_ceil;
    nt = nt_ceil;
  elseif nc_ceil+nt_floor == length(i0)
    nc = nc_ceil;
    nt = nt_floor;
  elseif nc_floor+nt_ceil == length(i0)
    nc = nc_floor;
    nt = nt_ceil;
  elseif nc_floor+nt_floor == length(i0)
    nc = nc_floor;
    nt = nt_floor;
  end
end

irem=[repmat(-1,nc,1); repmat(-2,nt,1)];
irem=shuffle(irem);
x.class(i0) = irem';

%--------------------------------------------------------------------------
function x = sct_duplex(xin, use, options)
% Apply splitcaltest using the 'duplex' algorithm
% INPUT:
%    xin = array
%    i0  = include vector for rows
% OUTPUT:
%    x = (1,nsamples) vector, values 0, -1, -2, for Never-use, Cal, Test

switch lower(options.distmeasure)
case {'m','mahal','mahalan','mahalanobis'} %use if mahalanobis requested
  ccov   = cov_cv(xin(use,:),struct('display','off','plots','none','sqrt','yes'));
  xin    = xin*ccov; clear ccov
end

[m,n]        = size(xin);
classes      = zeros(1,m); % Never-use
classes(use) = -2;         % Test
incl         = duplex(xin(use,:), ceil(length(use)*options.fraction));
cal          = use(incl);  % cal is the subset of use which are Cal
classes(cal) = -1;         % Cal
x.class      = classes;

%--------------------------------------------------------------------------
function x = sct_spxy(xin, yin, use, options)
% Apply splitcaltest using the 'spxy' algorithm
% INPUT:
%    xin = array
%    yin = array
%    i0  = include vector for rows
% OUTPUT:
%    x = (1,nsamples) vector, values 0, -1, -2, for Never-use, Cal, Test

switch lower(options.distmeasure)
case {'m','mahal','mahalan','mahalanobis'} %use if mahalanobis requested
  ccov   = cov_cv(xin(use,:),struct('display','off','plots','none','sqrt','yes'));
  xin    = xin*ccov; clear ccov
end

[m,n]        = size(xin);
classes      = zeros(1,m); % Never-use
classes(use) = -2;         % Test
incl         = spxy(xin(use,:), yin(use,:), ceil(length(use)*options.fraction));
cal          = use(incl);  % cal is the subset of use which are Cal
classes(cal) = -1;         % Cal
x.class      = classes;

%--------------------------------------------------------------------------
function x = sct_random(xin, use, options)
% Apply splitcaltest using random
% INPUT:
%    xin = array
%    i0  = include vector for rows
% OUTPUT:
%    x = (1,nsamples) vector, values 0, -1, -2, for Never-use, Cal, Test

switch lower(options.distmeasure)
case {'m','mahal','mahalan','mahalanobis'} %use if mahalanobis requested
  ccov   = cov_cv(xin(use,:),struct('display','off','plots','none','sqrt','yes'));
  xin    = xin*ccov; clear ccov
end

[m,n]        = size(xin);
classes      = zeros(1,m); % Never-use
classes(use) = -2;         % Test
incl         = randomsplit(xin(use,:), ceil(length(use)*options.fraction));
cal          = use(incl);  % cal is the subset of use which are Cal
classes(cal) = -1;         % Cal
x.class      = classes;
