function obj = crossvalidate(obj,x,cvi,ncomp, p5)
%EVRIMODEL/CROSSVALIDATE Do cross-validation for an EVRIModel object.
% 
%I/O: obj = crossvalidate(obj,x,cvi,ncomp)

%Copyright Eigenvector Research, Inc. 2012
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if isempty(obj.content.datasource) 
  error('This model cannot be cross-validated')
end

switch nargin
  case 1
    % (obj)
    x     = [];
    cvi   = [];
    ncomp = [];
  case 2
    % (obj,x)
    % (obj,cvi)
    % (obj,ncomp)
    if iscvi(x)
      % (obj,cvi)   (cell or VECTOR)
      cvi   = x;
      x     = [];
      ncomp = [];
    elseif isnumeric(x) & numel(x)==1
      % (obj,ncomp)   (scalar)  
      ncomp = x;
      x     = [];
      cvi   = [];
    else
      % (obj,x)    (anything else)
      cvi   = [];
      ncomp = [];
    end
  case 3
    % (obj,x,cvi)
    % (obj,x,ncomp)
    % (obj,cvi,ncomp)
    if iscvi(x)
      % (obj,cvi,ncomp)
      ncomp = cvi;
      cvi = x;
      x = [];
    elseif isnumeric(cvi) & numel(cvi)==1
      % (obj,x,ncomp)   (scalar)
      ncomp = cvi;
      cvi   = [];
    else
      % (obj,x,cvi)    (anything else)
      ncomp = [];
    end
  case 4
    % (obj,x,cvi,ncomp)
    % (obj,x,y,cvi)
    if iscvi(cvi)
      % (obj,x,cvi,ncomp)
    else
      % (obj,x,y,cvi)
      y = cvi;    % but why bother? y is read from obj at line 122 below.
      cvi = ncomp;
      ncomp = [];
    end
  case 5
    % (obj,x,y,cvi,ncomp)
    y = cvi;
    if iscvi(ncomp)
      cvi = ncomp;
      ncomp = p5;
    else
      error('crossvalidate called with unexpected parameters');
    end
end
    
if isempty(x)
  %attempt to get x from object
  x = subsref(obj,substruct('.','x'));
  if isempty(x)
    x = obj.x;
  end
  if isempty(x)
    error('X-block data missing. Provide as input to crossvalidate: model.crossvalidate(x,...)')
  end
else
  %we got an x : see if it matches the calibration x
  if ~iscalibrated(obj)
    if ismember('x',getcalprops(obj)) & isempty(obj.calibrate.script.x)
      %X is applicable AND nothing in object? store this now
      obj.calibrate.script.x = x;
    end
  else
    %check if passed x matches uniqueid and moddate for model
    ds = obj.content.datasource{1};
    if isdataset(x) & (~strcmp(ds.uniqueid,x.uniqueid) | any(ds.moddate~=x.moddate))
      error('X does not match calibration data')
    end
  end
end

if isempty(ncomp)
  %use maximum
  ncomp = inf;
end
if isdataset(x)
  nlen = length(x.include{1});
else
  nlen = size(x,1);
end
if isempty(cvi)
  cvi = {'vet' max(2,min(10,ceil(sqrt(nlen)))) 1};
elseif ischar(cvi)
  cvi = {cvi max(2,min(10,ceil(sqrt(nlen)))) 1};
end

if ~iscalibrated(obj)
  %need to calibrate model first (or try)
  obj = calibrate(obj);
end

%define options for cross-validation
cvopts = [];
cvopts.plots = obj.plots;
cvopts.display = obj.display;

%get y-data (if any)
moddata = obj.content.detail.data;
if length(moddata)>1
  y = moddata{2};
else
  y = [];
end

%make sure x is a DSO
if ~isdataset(x)
  x = dataset(x);
end

%handle ncomp
switch lower(obj.content.modeltype)
  case 'knn'
    objcomp = obj.content.k;
    ncomp = max(1,min(ncomp,min(objcomp,length(x.include{1}))));
  case 'anndl'
     objcomp = subsref(obj,substruct('.','lvs'));
     ncomp = max(1,min(max(ncomp,objcomp),min(cellfun('length',x.include))));
  otherwise
    objcomp = subsref(obj,substruct('.','lvs'));  %how many were used in model? use at least that many
    ncomp = max(1,min(max(ncomp,objcomp),min(cellfun('length',x.include))-1));
end

%set pca cross-validation (will only be used for pca models)
if length(x.include{2})>25;
  cvopts.pcacvi = {'con' min(10,floor(sqrt(length(x.include{2}))))};
else
  cvopts.pcacvi = {'loo'};
end

%check for classification model
if isclassification(obj)
  cvopts.discrim = 'yes';  %force discriminant ananlysis cross-val mode
  
  %check for prior probabilities
  if isfieldcheck(obj,'modl.detail.options.priorprob') & ~isempty(obj.content.detail.options.priorprob)
    cvopts.prior   = normaliz(obj.content.detail.options.priorprob,[],1);
  else
    cvopts.prior = [];
  end
end

%special setup for lwr
if strcmpi(obj.content.modeltype,'lwr')
  cvopts.lwr = obj.content.detail.options;
  cvopts.lwr.ptsperterm = 0;    %ALWAYS zero (means use minimumpts always)
  cvopts.lwr.minimumpts = obj.content.detail.npts;   %number of points to use
  cvopts.lwr.preprocessing = 0; %PP is passed in cv opts.
  ncomp = min(cvopts.lwr.minimumpts, ncomp);
end
if isfieldcheck(obj.content,'content.detail.options.weights')
  cvopts.weights = obj.content.detail.options.weights;
end
if isfieldcheck(obj.content,'content.detail.options.weightsvect')
  cvopts.weightsvect = obj.content.detail.options.weightsvect;
end

% - - - - - - - - - - - - - - - - - - - - - -
%do cross-validation
obj = crossval(x,y,obj,cvi,ncomp,cvopts);

% - - - - - - - - - - - - - - - - - - - - - -
%add results to model cache (if possible)
if getfield(evrimodel('options'),'usecache')
  modelcache(obj,{x y});
end

%----------------------------------------------------------
function out = iscvi(x)

if iscell(x) | (isnumeric(x) & sum(size(x)==1)==1) | ischar(x)
  out = true;
else
  out = false;
end
