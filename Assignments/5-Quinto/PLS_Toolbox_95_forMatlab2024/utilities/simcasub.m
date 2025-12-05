function varargout = simcasub(varargin)
%SIMCASUB Calculate a single SIMCA Sub-model.
% SIMCASUB calculates a single SIMCA sub-model for inclusion into a SIMCA
% model. A SIMCA sub-model is a PCA model built only on samples of a given
% class (or classes) as indentified in a DataSet object's class{1} field.
% Inputs are identical to PCA except a second input (modelclasses) follows
% the x-block specifying which class or classes on which the sub-model
% should be built. (modelclasses) is a scalar or a vector of classes.
%
% NOTE: SIMCASUB is not the usual route to perform SIMCA predictions - use
% PCA to do predictions from a SIMCA sub-model or SIMCA to do predictions
% from a SIMCA model.
%
%I/O: model = simcasub(x,modelclasses,ncomp,options);  %identifies model (calibration)
% 
%See also: PCA, PLSDA, SIMCA

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%JMS 5/04
%jms 5/7/04 -maintain appropriate datasource info

if nargin==0
  varargin = {'io'};
end
if ischar(varargin{1}) %Help, Demo, Options
  options = pca('options');
  options.classset = 1;
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return; 
end

if nargin<2;
  error('At least two inputs are required');
end

%find options and any model
optsind = [];
modelind = [];
for j=1:length(varargin);
  if ismodel(varargin{j})
    modelind = j;
  elseif isa(varargin{j},'struct')
    optsind = j;
  end
end
% We'll pass most options to PLS but some will be specially handled here
if isempty(optsind);
  %no options found, create some and add to end
  varargin{end+1} = simcasub('options');
  optsind = length(varargin);
end
options = reconopts(varargin{optsind},mfilename);
varargin{optsind}.plots = 'none';   %hard-set options for plots, we'll do them ourselves

%locate modelclass info
modelclasses = varargin{2};
if (~isa(modelclasses,'double') & ~isa(modelclasses,'logical')) | ~any(size(modelclasses)==1) | length(modelclasses)==0 | ndims(modelclasses)>2
  error('input "modelclasses" must be a double or a logical scalar or vector')
end  

%check for dataset as first input
if ~isa(varargin{1},'dataset') | isempty(varargin{1}.class{1,options.classset});
  error('Input X must be a dataset object with classes for the sample (1st) dimension');
end

%grab datasource info now, before we change the dataset include field
datasource = getdatasource(varargin{1});

%exclude samples not to be modeled
originalinclude = varargin{1}.include{1};
varargin{1}.include{1} = intersect(originalinclude,find(ismember(varargin{1}.class{1,options.classset},modelclasses)));
if isempty(varargin{1}.include{1});
  error('No samples of given class found in included data')
end

%call PCA
model = pca(varargin{[1 3:end]});

%store original include field
model.detail.originalinclude = {originalinclude};
model.datasource = {datasource};  %insert datasource info we grabbed earlier

%deal with plots
try
  switch lower(options.plots)
    case {'on','final'}
      if isempty(modelind)  %no model found in inputs? just show output
        plotloads(model);
        plotscores(model);
      else   %model given in inputs - this is a prediction...
        plotloads(varargin{modelind},model);
        plotscores(varargin{modelind},model);
      end
  end
catch
  warning('EVRI:PlottingError',lasterr)
end

varargout = {model};
