function [sc,incl] = reducennsamples(model,varargin)
%REDUCENNSAMPLES Selects a subset of samples by removing nearest neighbors.
% Performs a selection of samples which fill out the multivariate space by
% removing ("thinning out") samples which are similar to each other based
% on nearest neighbor distance. This algorithm is useful in selecting the
% minimum number of samples needed to define a subspace and reduce the
% number of reference measurements needed, or amount of data needed to be
% stored.
%
% Initially, the nearest neighbor of each sample is found along with the
% distance between the neighbors. Of the two nearest samples, one is
% excluded from the data and the distances are recalculated. This process
% is repeated until either the smallest distance between samples reaches a
% maximum limit, or the number of samples reaches a lower limit.
% 
% Source of data can be either a factor-based model (PCA, PLS, PCR, etc)
% which contains scores for all samples, or a raw data matrix or DataSet,
% in which case distances will be calculated in raw variable space.
%
% INPUTS:
%         model = Standard model structure OR double OR DataSet object containing
%                 data to select from.
% OPTIONAL INPUTS:
%       newdata = Additional data which should be considered for addition
%                 to the data provided by model input. When provided, all
%                 (model) samples are used and (newdata) is examined for
%                 samples to fill in empty regions of the (model) space.
%                 Under these conditions, minsamples, is considered the
%                 number of additional samples to be selected above the
%                 number included in model (see minsamples below).
%    minsamples = Minimum number of samples to retain. Sample thinning
%                 stops when the number of retained samples reaches this
%                 value. If omitted, 4 times the number of factors in the
%                 model or 1/2 the number of samples (whichever is smaller)
%                 is used. Must be > 2.
%       options = Optional options structure with one or more of the
%                 following fields:
%
%       maxdistance : [inf] Maximum allowed closest distance between samples.
%                 Sample thinning stops if the two closest samples are
%                 further away than this value. If "inf", thinning occurs
%                 until the number of samples given in minsamples is
%                 reached. If empty, the nearest distances are calculatd
%                 for the initial set and 1/2 of the maximum observed
%                 distance is used.
%       maxsamples : [5000] Maximum number of samples which can be passed
%                 for down-sampling. More than this number will throw an
%                 error.
%          mustuse : [] Indicies of samples which must be used.
%          waitbar : [ 'no' | {'yes'} ] indicates whether a waitbar can be
%                    shown.
%
% OUTPUTS: 
%    sc = DataSet object containing either the scores (if a model was
%         supplied) or the data supplied. Samples selected are included.
%         Thinned samples are excluded.
%  incl = Indices of retained samples (samples not thinned as redundant)
%
% Algorithm is based on work published in:
%    J.S. Shenk, M.O. Westerhaus, Crop Sci., 1991, 31, 469
%    J.S. Shenk, M.O. Westerhaus, Crop Sci., 1991, 31, 1548
%
%I/O: [sc,incl] = reducennsamples(model,minsamples,options)
%I/O: [sc,incl] = reducennsamples(model,newdata,minsamples,options)
%
%See also: DISTSLCT, DOPTIMAL, KNNSCOREDISTANCE, STDGEN, STDSSLCT

%Copyright Eigenvector Research 2008
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

sc = [];
incl = [];
if nargin==0; 
  model = lddlgpls({'struct','dataset','double'},'Choose Data or Model to downsample');
  if isempty(model);
    return
  end
end
if ischar(model)
  options = [];
  options.maxdistance = inf;
  options.mustuse = [];  
  options.maxsamples = 5000;
  options.waitbar = 'on';
  if nargout==0
    clear sc;
    evriio(mfilename,model,options); 
  else
    sc = evriio(mfilename,model,options); 
  end
  return
end

% - - - - - - - - - - - - - - - - - 
%sort out inputs
if nargin>1 & prod(size(varargin{1}))>1
  %minsamples is not a scalar must be data
  % [model, newdata, minsamples, options]
  newdata = varargin{1};
  varargin(1) = [];  %drop first item
else
  % no newdata
  newdata     = [];
end
%now, IO is: [model, minsamples, options]
[varargin{end+1:2}] = deal([]);   %fill in missing values
[minsamples,options] = deal(varargin{:});
options = reconopts(options,mfilename);

% - - - - - - - - - - - - - - - - - 
if ismodel(model)
  if isempty(newdata)
    %just a model
    sc = plotscores(model);
  else
    %new data passed, make prediction and use scores from EVERYTHING
    pred = feval(lower(model.modeltype),newdata,model,struct('display','off','plots','none'));
    sc = plotscores(model,pred);
    options.mustuse = union(options.mustuse,model.detail.includ{1});  %make sure we ALWAYS keep what is from model
  end
  sc.include{2} = 1:size(model.loads{2},2);
elseif isnumeric(model)
  sc = dataset(model);
  if ~isempty(newdata);
    try
      sc = [sc;newdata];  %attempt to combine data
    catch
      error('Unable to combine new and old data: %s',lasterr);
    end
    options.mustuse = union(options.mustuse,1:size(model,1));  %make sure we ALWAYS keep what is from model
  end
elseif isdataset(model)
  %Dataset
  sc = model;
  if ~isempty(newdata);
    try
      sc = [sc;newdata];  %attempt to combine data
    catch
      error('Unable to combine new and old data: %s',lasterr);
    end
    options.mustuse = union(options.mustuse,model.include{1});  %make sure we ALWAYS keep what is from model
  end
else
  %unknown
  error('Invalid input (class %s) for model',class(model))
end

%get initial include field for samples
incl = sc.include{1};

%get initial distances and nearest sample
[ksc,nearest] = knnscoredistance(sc,1,struct('maxsamples',options.maxsamples));
if all(isnan(ksc))
  error('Too many samples to analyze')
end
ksc(options.mustuse) = inf;  %block "must use" samples from exclusion
what  = min(ksc(incl));
where = find(ksc(incl)==what);  %find ALL with this value
if length(where)>1
  %more than one? choose one with most neighbors (inner sample)
  nused = [];
  for k=1:length(where)
    nused(k) = sum(nearest==where(k));
  end
  [nused_what,nused_where] = max(nused);
  where = where(nused_where);
end
toexclude     = incl(where);

%determine defaults for thresholds
if isempty(options.maxdistance)
  options.maxdistance = max(ksc(incl))/2;
end
if isempty(minsamples)
  %   %no minimum # of samples? use 4x the dimensionality of the data or 1/2
  %   %the samples (whichever is smaller)
  %   minsamples = min(length(sc.include{1})/2,length(sc.include{2})*4);
  %No minimum # of samples? ask user
  minsamples = nnreduceset;
  if isempty(minsamples)
    sc = [];
    return
  end
end

if minsamples<3
  error('Minimum number of samples must be > 2')
end

if strcmp(options.waitbar,'on')
  h = waitbar(0,'Reducing Redundant Samples...');
else
  h = [];
end
while what<options.maxdistance & length(incl)>minsamples
  %exclude the one with the closest distance
  incl      = setdiff(incl,toexclude);
  sc.include{1} = incl;
  
  for neighbor = find(nearest==toexclude);  %who was using this as a reference?
    incl_sub = setdiff(incl,neighbor);
    [ksc_sub,nearest_sub] = knnscoredistance(sc(incl_sub,:),sc(neighbor,:),1,struct('maxsamples',options.maxsamples));
    ksc(neighbor) = ksc_sub;
    ksc(options.mustuse) = inf;  %block "must use" samples from exclusion
    nearest(neighbor) = incl_sub(nearest_sub);
  end
  
  what = min(ksc(incl));
  where = find(ksc(incl)==what);  %find ALL with this value
  if length(where)>1
    %more than one? choose one with most neighbors (inner sample)
    nused = [];
    for k=1:length(where)
      nused(k) = sum(nearest==where(k));
    end
    [nused_what,nused_where] = max(nused);
    where = where(nused_where);
  end
  toexclude    = incl(where);
  
  if strcmp(options.waitbar,'on')
    if ~ishandle(h)
      error('Cancelled by user');
    end
    waitbar(max([what/options.maxdistance minsamples/length(incl)]),h);
  end
end
if ishandle(h)
  delete(h)
end

sc.include{1} = incl;

% Add a new Reduced class set.
sc.classname{1,end+1} = 'NN Reduced';
clu{2,2} = 'Reduced';
clu{2,1} = 1; % 0 is 'b', 1 is 'r', 2 is 'g'
clu{1,2} = 'Retained';
clu{1,1} = 2;
sc.classlookup{1,end} = clu; %not end+1 because space was autoallocated with classname value assignment.
clas = zeros(1,size(sc,1));
clas(incl) = clu{1,1};
clas(clas == 0) = clu{2,1};
sc.class{1,end} = clas;
