function model = tsne(varargin)
%t-Distributed Stochastic Neighbor Embedding.
% t-SNE is a tool used to vizualize high-dimensional data. When building a
% tsne model, data point similarities are calculated to joint
% probabilities and minimizes the Kullback-Leibler divergence
% between the low dimensional embeddings and the high dimensional data. The
% model cannot be used to predict on new data. It is recommended to use a
% dimension reduction method prior to using tsne if the number of features
% is very large. This method uses the Python Scikit-Learn implementation.
% More details on TSNE documentation can be found here:
% [https://scikit-learn.org/stable/modules/generated/sklearn.manifold.TSNE.html].
%
% INPUTS:
%        x  = X-block (predictor block) class "double" or "dataset",
%
%  Optional input (options) is a
%  structure containing one or more of the following fields [see doc for more details]:
%         display : [ 'off' |{'on'}] Governs display
%           plots : [{'none' | 'final']  %Governs plots to make
%        warnings : [{'off'} | 'on'] Silence or display any potential Python warnings.
%    n_components : [{2}] Dimension of the low dimensional embedded space.
%      perplexity : [{30}] Number of nearest neighbors tsne considers when calculating conditional probabilities.
%   learning_rate : [{200}] The learning rate for tsne, usually in the range [10.0, 1000.0].
% early_exaggeration: [{12}], Controls the tightness of clusters in the embedded space and the distance between clusters.
%          n_iter : [{1000}] Maximum number of iterations for optimization.
%  n_iter_without_progress : [{300}] Maximum number of iterations before
%                            aborting optimization without progress.
%   min_grad_norm : [{1.e-7}] Gradient norm threshold for optimization abort.
%          metric : [{'euclidean'} | 'manhattan' | 'cosine' | 'mahalanobis'] The metric used to calculate distance between data samples.
%            init : [{'random'} | 'pca'] Initialization method for the embeddings.
%    random_state : [{1}] Random seed number. Set this to a number for reproducibility.
%          method : [{'barnes_hut'} | 'exact'] Gradient calculation algorithm.
%           angle : [{0.5}] Angular size of a distant node as measured from a point.
%      compression: [{'none'}| 'pca'] type of data compression
%                    to perform on the x-block prior to calculating
%                    the TSNE model. 'pca' uses a simple PCA
%                    model to compress the information.
%    compressncomp: [{2}] Number of latent variables (or principal
%                    components to include in the compression model.
%       compressmd: [ 'no' |{'yes'}] Use Mahalnobis Distance corrected
%
%  OUTPUT:
%     model = standard model structure containing the TSNE model (See MODELSTRUCT)
%
%I/O: [model] = tsne(x,options);
%
%See also: UMAP

% Copyright © Eigenvector Research, Inc. 2021
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Start Input
if nargin==0  % LAUNCH GUI
  analysis('tsne')
  return
end

if ischar(varargin{1}) %Help, Demo, Options
  options = [];
  options.name                        = 'options';
  options.display                     = 'on';     %Displays output to the command window
  options.plots                       = 'final';  %Governs plots to make
  options.warnings                    = 'off';
  options.preprocessing               = {[]};     %See Preprocess
  options.n_components                = 2;
  options.perplexity                  = 30;
  options.learning_rate               = 200;
  options.early_exaggeration          = 12;
  options.n_iter                      = 1000;
  options.n_iter_without_progress     = 300;
  options.min_grad_norm               = 1.0e-7;
  options.metric                      = 'euclidean';
  options.init                        = 'random';
  options.random_state                = 1;
  options.method                      = 'barnes_hut';
  options.angle                       = 0.50;
  options.n_jobs                      = -1;
  options.compression                 = 'none';
  options.compressncomp               = 2;
  options.compressmd                  = 'yes';
  options.roptions.cutoff = [];   %similar to confidencelimit for robust outlier detection
  options.definitions   = @optiondefs;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; model = evriio(mfilename,varargin{1},options); end
  return;
end

% parse input parameters
[x,inopts] = parsevarargin(varargin);

inopts = reconopts(inopts,mfilename);

% Convert x to dataset, if not already
[x] = converttodso(x);

[datasource{1}] = getdatasource(x);

if isempty(inopts.preprocessing);
  inopts.preprocessing = {[] []};  %reinterpet as empty for both blocks
end
if ~isa(inopts.preprocessing,'cell')
  inopts.preprocessing = {inopts.preprocessing};
end
if length(inopts.preprocessing)==1;
  inopts.preprocessing = inopts.preprocessing([1 1]);
  % Special case: if user passed only X preprocessing use same for X and Y
end
preprocessing = inopts.preprocessing;


if mdcheck(x);
  if strcmp(inopts.display,'on'); warning('EVRI:MissingDataFound','Missing Data Found - Replacing with "best guess". Results may be affected by this action.'); end
  [flag,missmap,x] = mdcheck(x);
end

if ~isempty(preprocessing{1});
  [xpp,preprocessing{1}] = preprocess('calibrate',preprocessing{1},x);
else
  xpp = x;
end

% compression
[xpp, commodel] = getcompressionmodel(xpp, inopts);

% Train TSNE on the included data
pyModel =  train(xpp, inopts);
model = tsnestruct;
model.detail.tsne.niter          = pyModel.niter;
model.detail.tsne.embeddings     = pyModel.embeddings;
model.loads{1,1}                 = pyModel.embeddings;
model.detail.tsne.model          = pyModel.model;

model.detail.data = x;
model = copydsfields(x,model,[],{1 1});
%model = copydsfields(y,model,[],{1 2});
model.detail.includ{1,2} = x.include{1};   %x-includ samples for y samples too
model.datasource = datasource;
model.detail.preprocessing = preprocessing;   %copy calibrated preprocessing info into model
model.detail.compressionmodel = commodel;
if ~isempty(x.class{1})
  [ratio_min,ratio_mean] = calculate_distanceratio(model.detail.tsne.embeddings,x.class{1}(x.include{1}));
  model.detail.tsne.distance_metrics.ratio_min         = ratio_min;
  model.detail.tsne.distance_metrics.ratio_mean        = ratio_mean;
end
model.detail.tsne.distance_metrics.kl_divergence     = pyModel.kl_divergence;

%Set time and date.
model.date = date;
model.time = clock;
%copy options into model only if no model passed in
model.detail.options = inopts;

%--------------------------------------------------------------------------
function [pyModel] =  train(x, opts)

displayon = strcmp(opts.display, 'on');


pyModel = buildtsne(x,opts);

%--------------------------------------------------------------------------

function [x] = converttodso(x)
%C) CHECK Data Inputs
if isa(x,'double')      %convert x to DataSet
  x        = dataset(x);
  x.name   = inputname(1);
  x.author = 'TSNE';
elseif ~isa(x,'dataset')
  error(['Input X must be class ''double'' or ''dataset''.'])
end
if ndims(x.data)>2
  error(['Input X must contain a 2-way array. Input has ',int2str(ndims(x.data)),' modes.'])
end


%--------------------------------------------------------------------------
function outstruct = tsnestruct
outstruct = modelstruct('tsne');

%--------------------------------------------------------------------------
function [xpp, commodel] = getcompressionmodel(varargin)
%
% compress X-block data
%
% Apply data compression if desired by user

xpp = varargin{1};
options = varargin{2};

switch options.compression
  case {'pca'}
    switch options.compression
      case 'pca'
        comopts = struct('display','off','plots','none','confidencelimit',0,'preprocessing',{{[] []}});
        commodel = pca(xpp,options.compressncomp,comopts);
    end
    scores   = commodel.loads{1};
    if strcmp(options.compressmd,'yes')
      incl = commodel.detail.includ{1};
      eig  = std(scores(incl,:)).^2;
      commodel.detail.eig = eig;
      scores = scores*diag(1./sqrt(eig));
    else
      commodel.detail.eig = ones(1,size(scores,2));
    end
    xpp      = copydsfields(xpp,dataset(scores),1);
  otherwise
    commodel = [];
end

%--------------------------------------------------------------------------
function [x, inopts] = parsevarargin(varargin)
%
%I/O: [model] = tsne(x,options);


x           = [];
inopts      = [];

varargin = varargin{1};
nargin = length(varargin);
switch nargin
  case 2  % 2 arg:
    %    tsne(x,options);
    if isdataset(varargin{1}) | isnumeric(varargin{1})
      if isstruct(varargin{2})
        % (x,options)
        x = varargin{1};
        inopts  = varargin{2};
      else
        error('tsne called with two arguments requires options structure as second argument.');
      end
    else
      error('tsne called with two arguments requires non-empty x data array as first argument.');
    end
  otherwise
    error(['tsne: unexpected number of arguments to function: ' num2str(nargin)]);
end


%--------------------------

function [pyModel] = buildtsne(x, options)

% Non dso input x,y have been converted to DSOs
indsx = x.includ;

% Build model using included data only
xd = x.data(indsx{:});

% build client object
client = evriPyClient(options);
% calibrate Python model object
client = client.calibrate(xd,x.data(:,indsx{2}),[]);
% extract information client
pyModel.model = client.serialized_model; %dump model to bytes
pyModel.niter = double(client.extractions.niter);
%start with NaN array, and fill in accordingly with the included samples
embeddings = NaN(size(x.data,1),options.n_components);
embeddings(indsx{1},:) = client.extractions.embeddings;
pyModel.embeddings = embeddings;
pyModel.kl_divergence = client.extractions.kl_divergence;
%-----------------------------------------------------------------


%--------------------------

function out = optiondefs()

defs = {
  %name                    tab              datatype        valid                            userlevel       description
  'display'                'Display'        'select'        {'on' 'off'}                     'novice'        'Governs level of display.';
  'plots'                  'Display'        'select'        {'none' 'final'}                 'novice'        'Governs level of plotting.';
  'warnings'               'Display'        'select'        {'on' 'off'}                     'novice'        'Silence or display any potential Python warnings.';
  'n_components'           'Standard'       'double'        'int(1:inf)'                     'novice'        'Dimension of the low dimensional embedded space.';
  'perplexity'             'Standard'       'double'        'int(1:inf)'                     'novice'        'Number of nearest neighbors tsne considers when calculating conditional probabilities.';
  'learning_rate'          'Standard'       'double'        'float(0:inf)'                   'novice'        'The learning rate for tsne, usually in the range [10.0, 1000.0]';
  'n_iter'                 'Standard'       'double'        'int(0:inf)'                     'novice'        'Maximum number of iterations for optimization.';
  'n_iter_without_progress' 'Standard'       'double'        'int(1:inf)'                     'novice'        'Maximum number of iterations before aborting optimization without progress.';
  'min_grad_norm'          'Standard'       'double'        'float(0:inf)'                   'novice'        'Gradient norm threshold for optimization abort.';
  'metric'                 'Standard'       'select'        {'euclidean' 'manhattan' 'cosine' 'mahalanobis'}                    'novice'        'The metric used to calculate distance between data points.';
  'init'                   'Standard'       'select'        {'random' 'pca'}                 'novice'        'Initialization method of embedding.';
  'random_state'           'Standard'       'double'        'int(1:inf)'                     'novice'        'Random seed number, set this to some integer for reproducibility.';
  'method'                 'Standard'       'select'        {'barnes_hut' 'exact'}           'novice'        'Gradient calculation algorithm. Major tradeoff between performance and accuracy when adjusting this parameter.';
  'compression'            'Compression'    'select'        {'none' 'pca'}                   'novice'        'Type of data compression to perform on the x-block prior to TSNE model. Compression can make the TSNE more stable. ''PCA'' is a principal components model.';
  'compressncomp'          'Compression'    'double'        'int(1:inf)'                     'novice'        'Number of latent variables or principal components to include in the compression model.';
  'compressmd'             'Compression'    'select'        {'no' 'yes'}                     'novice'        'Use Mahalnobis Distance corrected scores from compression model.'
  };

out = makesubops(defs);

%-----------------------------------------------------------------


