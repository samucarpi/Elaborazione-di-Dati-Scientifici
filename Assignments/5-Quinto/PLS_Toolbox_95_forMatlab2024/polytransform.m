function [xout,model] = polytransform(varargin)
%POLYTRANSFORM Add polynomial and cross terms to data matrix or dataset.
% Input dataset x has new transformed variables added. These can include 
% existing variables raised to second, third, fourth power, or second order 
% product of variables. 
% The data can be preprocessed before transformed variables are calculated.
% preprocessingtype option specifies the type of preprocessing to apply,
% 'none', 'mncn', 'auto', or 'custom'. If 'custom' is specified then the
% 'preprocessing' option must be a valid preprocessing structure.
% If pca = 'on' the data are converted to PCA scores after preprocessing, 
% but before the transformed variables are calculated.
%
%  INPUTS: x,options, model
%         x = X-block (2-way array class "double" or "dataset")
%   options = options structure (see below)
%  OR:
%        x  = X-block (predictor block) class "double" or "dataset",
%    model  = previously generated polytransform model.
%
% Optional inputs:
%   options = structure array with the following fields:
%                squares: Add squared variables. ['off' | {'on'}]
%                  cubes: Add cubed variables. [{'off'} | 'on']
%               quartics: Add 4th power variables. [{'off'} | 'on']
%             crossterms: Add crossterm variables. [{'off'} | 'on']
%      preprocessingtype: ['none' | 'mncn' | {'auto'} | 'pcrtile' | 'custom']
%          preprocessing: A preprocessing struct if 'custom' is used
% preprocessoriginalvars: Return preprocessed original variables? [0 | {1}]
%                    pca: Convert values to PC scores ['on' | {'off'}]
%                 maxpcs: Number of PCs to use, if applied [{10}]
%
%  OUTPUT:
%    xout  = Dataset object containing the augmented data
%    model = standard model structure containing the polytransform model (See MODELSTRUCT)
%
%I/O: [xout, model] = polytransform(x, options);
%I/O: xout          = polytransform(x, model);
%I/O: polytransform demo
%
%See also: GSCALE, MEDCN, MNCN, NORMALIZ, NPREPROCESS, REGCON, RESCALE

% Copyright © Eigenvector Research, Inc. 2010
% Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%BMW  1/20/2010

if nargin == 0;
  varargin{1} = 'io';
end

if ischar(varargin{1});
  options = [];
  options.squares           = 'on';
  options.cubes             = 'off';
  options.quartics          = 'off';
  options.crossterms        = 'off';
  options.preprocessingtype = 'auto';
  options.preprocessing     = [];         % preprocessing struct for preprocessingtype = 'custom'
  options.pca               = 'off';      % apply pca to preprocessed data?
  options.maxpcs            = 10;
  options.preprocessoriginalvars = true;       % preprocess the untransformed vars?
  options.definitions = @optiondefs;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; xout = evriio(mfilename,varargin{1},options); end
  return;
end

if nargin < 2
  x = varargin{1};
  options = polytransform('options');
end

% Possible calls:
% 2 inputs: (x,model)     case A
%           (x,options)   case B
% Note: three inputs (x, model, options) is not allowed; get options from the model.
switch nargin
  case 2                                  % two inputs (x, model): convert to (x, model, options)
    if isa(varargin{1}, 'dataset') | isnumeric(varargin{1})
      if ismodel(varargin{2})             % (x,model)   case A
        [x, model, options] = deal(varargin{1},varargin{2},[]);
        if ~isempty(model.detail.options)
          options = model.detail.options;
        end
      elseif isa(varargin{2},'struct')    % (x,options)   case B
        % Must be case B: (x,options)
        [x, model, options] = deal(varargin{1},[],varargin{2});
      else
        error('polytransform called with two unexpected arguments. Expects (dataset, model) or (dataset, options).');
      end
    end
    
    
  case 3                                  % three inputs (x, model, options): but use options from model
    if isa(varargin{1}, 'dataset') | isnumeric(varargin{1})
      if ismodel(varargin{2})
        [x, model, options] = deal(varargin{1},varargin{2},[]);
        if ~isempty(model.detail.options)
          options = model.detail.options;
        end
      end
    end
        
  otherwise
    error('Input arguments not recognized.')
end

if isfield(options, 'quadratics') & ~isfield(options, 'quartics')
  options.quartics = options.quadratics;
  options          = rmfield(options, 'quadratics');
end

options = reconopts(options,'polytransform');

% % Check that x is not multi-way data
% if (ndims(x) > 2)
%   error('polytransform is not supported for multiway data');
% end

% convert to DSO:
inputdso = true;
if ~isa(x, 'dataset')
  x = dataset(x);
  inputdso = false;
end
% Populate or update model
model = update(model, x, options);

% Apply preprocessing
[ax, mns, stds, model] = applyPreprocessing(x, options, model);

% apply pca?
% convert variable values to ncomp PC score values
if strcmpi(options.pca, 'on')
  if isempty(model)  | model.detail.isnewmodel  % no model input
    ncomp = options.maxpcs;
    pcaOptions = pca('options');
    pcaOptions.confidencelimit = 0;
    pcaOptions.plots = 'none';
    pcaModel = pca(ax, ncomp, pcaOptions);      % using scaled ax
    ax = pcaModel.loads{1};                     % ax is now scores
    n = size(ax,2);
  else                                          % have input model
    pcaModel = model.detail.pcamodel;
    pcaOptions = pcaModel.detail.pcaoptions;
    pcaPred = pca(ax, pcaModel, pcaOptions);    % using scaled ax
    ax = pcaPred.loads{1};                      % ax is now scores
  end
end

% Update newly created POLYTRANSFORM model
if isempty(model)  | model.detail.isnewmodel
  model.detail.means = mns;
  model.detail.stds = stds;
  if strcmpi(options.pca, 'on')
    pcaModel.detail.options = pcaOptions;    % Save pca options in the model
    %pcaModel.detail.ncomp = ncomp;
    model.userdata = pcaModel; %model.detail.pcamodel = pcaModel;
  end
end

% Form the additional variables
[data, varlabels, include] = addVariables(x, ax, options);%[data, varlabels] = addVariables(x, ax, options);

xout = dataset(data);

if inputdso
  xout.description = sprintf('Polytransform applied to input dataset ''%s''', x.name);
else
  xout.description = 'Polytransform applied to input array';
end

xout = copydsfields(x, xout,1);
xout.label{2} = varlabels;

xout.include{2} = include;

% Preprocess
%---------------------------------------------------------------------------------------------------
function [ax, mns, stds, model] = applyPreprocessing(x, options, model)
%PREPROCESS apply preprocessing to the input dataset
[m,n] = size(x);
mns   = [];
stds  = [];

if ndims(x)>2 & ismember(lower(options.preprocessingtype),{'mncn' 'auto'})
  error('Selected preprocessing is invalid for multiway data')
end
    

switch options.preprocessingtype
  case 'none'
    ax = x.data;
    mns = zeros(1,n);
    stds = ones(1,n);
    
  case 'mncn'
    if isempty(model) | model.detail.isnewmodel
      [ax,mns] = mncn(x.data);
      stds = ones(1,n);
    else
      mns = model.detail.means;
      ax = scale(x.data, mns);
      % use model's mean
    end
    
  case 'auto'
    if isempty(model) | model.detail.isnewmodel
      [ax,mns,stds] = auto(x.data);
    else
      % use model's mean and stds
      mns = model.detail.means;
      stds = model.detail.stds;
      ax = scale(x.data, mns, stds);
    end
    
  case 'prctile'
    % Scale variables by their 90th percentile of their abs. values
    if isempty(model) | model.detail.isnewmodel
      ax = x.data;
      ic=floor(m*0.9);
      sdata=sort(abs(ax));
      sfacts = sdata(ic,:);
      normer = sfacts(ones(m,1),:);
      ax = ax./normer;
      mns = zeros(1,n);
      stds = sfacts; %ones(1,n);
    else
      % use model's mean and stds
      mns = model.detail.means;
      stds = model.detail.stds;
      ax = scale(x.data, mns, stds);
    end
    
  case 'custom'
    if isempty(model) | model.detail.isnewmodel
      prepro = model.detail.options.preprocessing;
      [ax,sp] = preprocess('calibrate',prepro(1), x.data);  % xblock
      model.detail.options.preprocessing = sp;
      ax = ax.data;
    else
      % use model's preprocess structure
      prepro = model.detail.options.preprocessing;
      ax = preprocess('apply',prepro, x.data);  % xblock
      ax = ax.data;
    end
    
  otherwise
    error(sprintf('Input option ''preprocessingtype'' = ''%s'' is not recognized.', options.preprocessingtype));
end

%---------------------------------------------------------------------------------------------------
function [data, varlabels, include] = addVariables(x, ax, options)
%ADDVARIABLES adds transformed and/or cross-product variables to the dataset
[m,n] = size(ax);
maxpcs = options.maxpcs;
deliml = '(';
delimr = ')';
  
% Use preprocessed vars if pca applied or options specify to do so
if options.preprocessoriginalvars | strcmp(options.pca, 'on')  
  data = ax;
else
  data = x.data;
end

if isempty(x.label{2})
  varlabels_orig = cell(n,1);
  for i = 1:n
    varlabels_orig{i,1}  = sprintf('var(%i)', i);
  end
else
  varlabels_orig = str2cell(x.label{2});
end
  

if strcmp(options.pca, 'on')
  varlabels = {};
else
  varlabels = varlabels_orig;
end

if strcmp(options.squares,'on')
  data = [data ax.^2];
  varlabels_sq = cell(n,1); 
  if strcmp(options.pca, 'on')
    nvars = min(n, maxpcs);
    for i = 1:nvars
      varlabels{i,1}  = sprintf('PC(%i)', i);
      varlabels_sq{i} = sprintf('PC(%i)^2', i);
    end
  else
    for i = 1:n
      varlabels_sq{i} = [ deliml varlabels_orig{i} delimr '^2'];
    end
  end
  varlabels = [varlabels; varlabels_sq];
end

if strcmp(options.cubes,'on')  
  data = [data ax.^3];
  varlabels_cube = cell(n,1);  
  if strcmp(options.pca, 'on')
    nvars = min(n, maxpcs);
    for i = 1:nvars
      varlabels{i,1}  = sprintf('PC(%i)', i);
      varlabels_cube{i} = sprintf('PC(%i)^3', i);
    end
  else
    for i = 1:n
      varlabels_cube{i} = [ deliml varlabels_orig{i} delimr '^3'];
    end
  end
  varlabels = [varlabels; varlabels_cube];
end
  
if strcmp(options.quartics,'on')
  data = [data ax.^4];
  varlabels_quad = cell(n,1);  
  if strcmp(options.pca, 'on')
    nvars = min(n, maxpcs);
    for i = 1:nvars
      varlabels{i,1}  = sprintf('PC(%i)', i);
      varlabels_quad{i} = sprintf('PC(%i)^4', i);
    end
  else
    for i = 1:n
      varlabels_quad{i} = [ deliml varlabels_orig{i} delimr '^4'];
    end
  end
  varlabels = [varlabels; varlabels_quad];
end

if strcmp(options.crossterms,'on')
  noterms = sum(1:(n-1));
  crossdata = zeros(m,noterms);
  crosslabels = cell(noterms,1);
  if strcmp(options.pca, 'on')
    nvars = min(n, maxpcs);
    varlabels_orig = cell(nvars,1);
    for i = 1:nvars
      varlabels_orig{i} = sprintf('PC(%i)', i);
    end
  end
  k = 0;
  for i = 1:n-1
    for j = i+1:n
      k = k+1;
      crossdata(:,k) = ax(:,i).*ax(:,j);
      crosslabels{k} = [ deliml varlabels_orig{i} delimr ' x ' deliml varlabels_orig{j} delimr];
    end
  end
  data = [data crossdata];
  varlabels = [varlabels; crosslabels];  
end

% Exclude corresponding terms that were excluded in the original dataset.
if (strcmpi(options.pca,'off'))
  xInc = x.include{2};
  
  if (length(xInc) ~= size(x,2))
    offset = 1;
    
    % raw/preprocessed data
    include = [xInc];
    
    % squares
    if strcmpi(options.squares,'on')
      [include, offset] = addToInclude(include, xInc, offset, n);
    end
    
    % cubes
    if strcmpi(options.cubes,'on')
      [include, offset] = addToInclude(include, xInc, offset, n);
    end
    
    % quartics
    if strcmpi(options.quartics,'on')
      [include, offset] = addToInclude(include, xInc, offset, n);
    end
    
    % crossterms
    if strcmpi(options.crossterms,'on')
      ctsInclude = [(1:sum(1:n-1)) + (n*offset)];
      k = 0;
      for i = 1:(n-1)
        for j = (i+1):n
          k = k + 1;
          % if either i or j is an excluded variable, mark the k-th index of cTermsIdx as 0
          if ~(ismember(i,xInc)) | ~(ismember(j,xInc))
            ctsInclude(k) = 0;
          end
        end
      end
      
      % cleanup ctsInclude & add it to include
      ctsInclude(ctsInclude == 0) = [];
      include = [include ctsInclude];
    end
    
  else % nothing excluded
    include = [1:size(data,2)];
  end
  
else % pca set to 'on', include everything
  include = [1:size(data,2)];
end

%--------------------------
function [include, offset] = addToInclude(include,xInc,offset,n)
% add to the list of variables that should be marked as include: from squares, cubes, and quartics.
include = [include (xInc + offset*n)];
offset = offset + 1;

%---------------------------------------------------------------------------------------------------
function model = update(model, ds, options)
%UPDATE populates or update a POLYTRANSFORM model
% Was model passed in?
if isempty(model)
  % no model passed in:
  model = modelstruct('polytransform');
  model.datasource{1} = getdatasource(ds);
  model.detail.isnewmodel=true;
  %   model = copydsfields(ds, model,1, 1); % USE x,model,[],{1 1}); %copy x-block details to first
  model.detail.options = options;
else
  model.detail.isnewmodel=false;
end
% in all cases
model.date = date;
model.time = clock;

%--------------------------
function out = optiondefs

defs = {
  %name             tab        datatype        valid              userlevel       description
  'squares'       	'Setup'     'select'       {'on' 'off'}     'novice'      	'Add squared variables.';
  'cubes'         	'Setup'     'select'       {'on' 'off'}     'novice'      	'Add cubed variables.';
  'quartics'     	  'Setup'     'select'       {'on' 'off'}     'novice'      	'Add 4th power variables.';
  'crossterms'     	'Setup'     'select'       {'on' 'off'}     'novice'      	'Add crossterm variables.';
  'preprocessingtype'   'Setup'     'select'       {'none' 'mncn' 'auto'}  'novice'	'Add preprocessing.'
  'preprocessoriginalvars' 'Setup' 'boolean'   ''               'novice'      	'Return preprocessed original variables?';
  'pca'             'Setup'     'select'       {'on' 'off'}     'novice'      	'Convert values to PC scores.';
  'maxpcs'           'Setup'     'double'       'int(0:inf)'     'novice'        'Number of PCs to use, if applied';
  };

out = makesubops(defs);

