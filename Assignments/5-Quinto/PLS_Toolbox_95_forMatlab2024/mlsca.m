function [model, res] = mlsca(varargin)
%MLSCA Multi-level Simultaneous Component Analysis
%
% Implements MLSCA following de Noord and Theobald, "Multilevel component
% analysis and multilevel PLS of chemical process data",
% Bioinformatics, 2005,
%
% INPUTS:
%   x        = the experimental value determined for each experiment/row
%              of F. See outputs regarding behvior when x is a matrix.
%   F        = array or dataset where each column describes the sample 
%              groupings for a level. For example, with a "two-level" 
%              dataset a single column might identify the individual which
%              the sample measurements belong to. For a "three-level" 
%              dataset the two columns might identify the the lab where
%              measurements were taken and the instrument type used.
%
% OPTIONAL INPUTS:
%
%      ncomp : a vector of integer values indicating the number of
%              Principal Components to use in each sub-model plus the 
%              residuals model (so length = size(F,2)+1), or a single
%              integer value which will be used as the number of Principal
%              Components for each sub-model. If omitted, the maximum
%              number of components for each submodel will be calculated.
%
%   options  = Options structure with one or more of the following fields.
%              Options can be passed in place of column_ID.
%
%          display : [{'off'}| 'on' ] governs output to the command window.
%     blockdetails: [ {'standard'} | 'all' ]  Extent of detail included in model.
%                     'standard' keeps only y-block, 'all' keeps both x-
%                     and y- blocks.
%     preprocessing: {[]} preprocessing structure for x block (see PREPROCESS).
%
% OUTPUT:
%  model = an MLSCA standard model structure containing fields (when input
%         matrix x has size mxn):
%         submodel: {1xnsub cell} of evrimodels. One for each factor plus
%         one for the residuals ("within").
%         combinedscores: [mxp dataset], where p is the cumulative number
%           of PCs used over all PCA sub-models. Column class sets identify
%           which sub-model and PC number each column is associated with.
%         combinedqs: [nxnsub dataset] combination of sub-model Qs.
%         combinedprojected: [mxp dataset] scores of projecting the ANOVA
%           residuals matrix onto each PCA sub-model. Column class sets
%           identify which sub-model and PC number each column is
%           associated with.
%         combinedloads: [nxp dataset] combination of sub-model loads.
%         details, which contains field:
%           data: cell array containing input x and F
%           decomp: [1x1 struct]
%           decompdata: {1x(nsub+1) cell} of [mx2 double] ANOVA decomposed
%             arrays, including matrix of means (first entry)
%           decompresiduals: [mxn double] containing the residuals term in
%             the ANOVA model. This is the variability not modeled by the
%             factors and interactions.
%           decompnames: {mx1 cell} names of the ANOVA factor levels
%           effects: The percentage each effect (overall mean, factors,
%             interactions and residuals) contributes to the sum of squares
%             of the data matrix X.
%
%  The "Between" and "Within"  matrices are returned in the decomp sub-field.
%  Note, the helper function PLOTSCORES_ASCA is useful for viewing the
%  results of ASCA.
%
%I/O: [model] = mlsca(x, F);
%I/O: [model] = mlsca(x, F, ncomp);
%I/O: [model] = mlsca(x, F, ncomp, options);
%
%See also: ASCA, PLOTSCORES_ASCA

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Start Input
if nargin==0  % LAUNCH GUI
  analysis mlsca
  return
end

if ischar(varargin{1});
  options = [];
  options.name          = 'options';
  options.display       = 'on';     %Displays output to the command window
  options.blockdetails  = 'standard';  %level of details
  options.preprocessing = {[]};
  options.definitions   = @optiondefs;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; model = evriio(mfilename,varargin{1},options); end
  return;
end

% parse input parameters
[x, F, ncomp, options, datasource] = parsevarargin(varargin);

options = reconopts(options,mfilename);

options.blockdetails = lower(options.blockdetails);
switch options.blockdetails
  case {'standard','all'};
  otherwise
    error(['OPTIONS.BLOCKDETAILS not recognized.'])
end

model    = modelstruct('mlsca');
model.submodel = {};  %start with empty submodel structure

% Convert x and F to dataset, if not already
[x,F] = converttodso(x,F, options);

% Check for non-finite design matrix (F) values
hasbadfrows = any(~isfinite(F.data(:)));
if hasbadfrows
  error('DOE design matrix contains non-finite values')
end

% if F does not have a row classset for each column of F then create them
nFcols = size(F,2);
rowFclasses = [F.class(1,:)];
numnonemptyclasses = sum(~cellfun(@isempty, rowFclasses));

if numnonemptyclasses < nFcols
% If F has fewer classsets than columns add classsets to F based on F.data
  for ifac = 1:nFcols
    ni = length(unique(F.data(:,ifac)));
    lookup = cell(ni,2);
    for i=1:ni
      lookup{i,1} = i;                    % TODO, like to use the F values
      lookup{i,2} = sprintf('F%d, level %d', ifac, i);
    end
    F.classlookup{1,ifac} = lookup;
    F.class{1,ifac} = F.data(:,ifac);
    
    F.classname{1,ifac} = sprintf('Factor %d', ifac);
  end
  
end

if ~isa(options.preprocessing,'cell')
  options.preprocessing = {options.preprocessing};
end

% Note, preprocessing is only used on x
if isempty(options.preprocessing);
  options.preprocessing = {[] []};  %reinterpet as empty for both blocks
end
if ~isa(options.preprocessing,'cell')
  options.preprocessing = {options.preprocessing};
end
if length(options.preprocessing)==1;
  options.preprocessing = {options.preprocessing{1} []};
  % Special case: if user passed only one preprocessing use it for X.
end
preprocessing = options.preprocessing;

model.date  = date;
model.time  = clock;
model.detail.data = {x F};
%handle model blockdetails
if strcmp('standard', lower(options.blockdetails))
  model.detail.data{1} = [];
end
model = copydsfields(x,model,[],{1 1});  % Copy x to model's block 1
model = copydsfields(F,model,[],{1 2});  % Copy F to model's block 2

model.detail.includ{1,1} = x.include{1};  % model's mode 1 (samples), block 1 (x) set = x included samples
model.datasource = datasource;
% model.detail.interactions = column_ID;

% set up pca
model.detail.options   = options;
pcaopts          = pca('options');
pcaopts.display  = 'off';
pcaopts.plots    = 'none';

% Apply preprocessing
if ~isempty(preprocessing{1});
  [xpp,preprocessing{1}] = preprocess('calibrate',preprocessing{1},x);
else
  xpp = x;
end

varincl = xpp.include{2};
model.detail.preprocessing = preprocessing;   %copy calibrated preprocessing info into model

% How many non-empty x row classsets?
rowXclasses = [x.class(1,:)];
z = ~cellfun(@isempty, rowXclasses);
numxclasssets = sum(~cellfun(@isempty, rowXclasses));
% numxclasssets = length(x.class(1,:)); 

nfactors = length(F.class(1,:));
xpp = copydsfields(F,xpp,1,[], true); % Copy row classes from F to x
xpporig = xpp;
% Do the level summarizations. There are size(F,2) summarizations
% account for the added levels
ssqtotal = sum(sum(xpp.data(:,varincl).^2));    % *** tempdos includes?

% Get ssq for mean
% globalmean = mean(xpp.data(:,varincl),1);
globalmean = mean(xpp.data(:,varincl),1);
globalmean = repmat(globalmean, size(xpp,1), 1);
% Remove global mean for each variable from xpp
xpp.data(:,varincl) = xpp.data(:,varincl) - globalmean;
globalmeanssq = sum(sum(globalmean.^2));    % *** tempdos includes?  

for ilev = 1:nfactors
  classset = numxclasssets+ilev;
  [ccx,mn,cls,npercls] = classcenter(xpp,classset);
  % Note: mn is reduced included data
  % ccx is the class centered xpp, centered to first level, then centered to first+second levels, etc.
  % xpp-ccx are the class means
  % save these results in a struct array
  levels(ilev).mn = mn(cls>0,:);
  levels(ilev).cls = cls(cls>0);
  levels(ilev).npercls = npercls(cls>0);
  xppmeans = xpp.data(:,varincl) - ccx.data(:,varincl);
  if ilev>1
    xppmeans = xppmeans + levels(ilev-1).means; % cumulative mean over levels.
  end
  levels(ilev).means = xppmeans;
  %   handle INCLUDES
  xpp.data = ccx.data;
end

% term 1 is means over top grouping - global mean
res(1).term = levels(1).means;  % assuming global mean is zero for this var
for ilev=2:nfactors
  res(ilev).term = levels(ilev).means - levels(ilev-1).means;
  
  res(ilev).ssq  = sum(sum((res(ilev).term).^2));
end
% last term is obs values - means over lowest grouped levels
res(nfactors+1).term = xpporig.data(:,varincl) -globalmean -levels(nfactors).means;

res(1).ssq          = sum(sum( (        res(1).term).^2) );
res(nfactors+1).ssq  = sum(sum( (res(nfactors+1).term).^2) );

for ilev = 1:(nfactors+1)
  model.detail.effects(ilev) = res(ilev).ssq;
end
effectnames = cell(nfactors+1,1);
for ilev = 1:nfactors
  effectnames{ilev} = sprintf('Level %d SSQ', ilev);
end
effectnames{nfactors+1} = 'Residuals SSQ';

if strcmpi(options.display,'on')
  ssqtot2 = sum([res(:).ssq]);
  disp(sprintf('SSQtot = %4.4g, sum of levels ssq = %4.4g', ssqtotal, ssqtot2))
  disp('SSQ for levels, and residual')
  disp(sprintf(' %4.4g', res.ssq))
end

% Do PCA on each between term and the within term
allscores = [];
allqs     = [];
allloads  = nan(size(x,2),0);
allprojected = [];
isubmodel    = [];
ipc          = [];
iorder       = [];
npcs         = [];

nsubmodels = nfactors+1;
for imod = 1:nsubmodels
  classset = numxclasssets+imod;
  levelmeans = res(imod).term;
  cls   = xpp.class{1,classset};
  if isempty(cls)
    cls = 1:size(levelmeans,1);
  end
  
  % PCA
  submodel = pca(levelmeans(cls>0,:), ncomp(imod), pcaopts);
  npc = size(submodel.loads{1}, 2);
  npcs(imod) = npc;
  
  %store submodel in model
  model.submodel{imod} = submodel;
  scores = submodel.loads{1};  % accumulate scores for each component  
  qs     = submodel.q;
  allscores = [allscores scores];
  allqs     = [allqs qs];
  allloads(varincl,end+1:end+submodel.ncomp) = submodel.loads{2,1};
  isubmodel = [isubmodel repmat(imod, 1, npc)];
  ipc       = [ipc 1:npc];
  iorder    = [iorder repmat(imod, 1, npc)];
  
  
  % project residuals onto loadings. resids is what is not modeled by this level
  if imod < nsubmodels
    resids = zeros(size(res(nfactors+1).term));
    for ii=(imod+1):(imod+1)          % residuals are just the offsets for next groupings about this mean
      resids = resids + res(ii).term;
    end
    pred = pca(resids, submodel, pcaopts);
    projected = pred.loads{1};
    allprojected = [allprojected projected];
    res(imod).projected = projected; %[allprojected projected];
  end
end


% Make scores and projected into DSO's with classes for isubmodel and ipc
allscores = getmatchingdso(allscores, xpp);
allqs     = getmatchingdso(allqs, xpp);
allloads  = dataset(allloads);
allprojected = getmatchingdso(allprojected, xpp);

name = 'Sub-model';
if ~isempty(model.detail.label{2,2})
lbls     = str2cell(model.detail.label{2,2}(model.detail.include{2,2},:));
else
  lbls = [];
end
if ~isempty(lbls) & length(lbls)~=nfactors %& size(F.classname,2)==neffects
  lbls = F.classname(1,model.detail.include{2,2});
end
if length(lbls)~=nfactors | ~iscell(lbls) | all(cellfun('isempty',lbls))
  % No [appropriate] labels, create them 
  % Use F classnames if they are not empty
  for j=1:nfactors;
    if ~isempty(F.classname) & size(F.classname,2)>=j & ~isempty(F.classname{1,j})
      lbls{j} = sprintf('Between %s', F.classname{1,j});
    else
    lbls{j} = sprintf('%s %i', name, j);
    end
  end
  lbls = lbls';
end
lbls{end+1} = 'Within';
allscores.classname{2,1} = name;
lbls = lbls(:);  % ensure lbls is a column
allscores.classlookup{2,1} = [num2cell(1:nsubmodels)' lbls(1:nsubmodels)];
allscores.class{2,1} = isubmodel;

% classset for submodel for allqs
allqs.classlookup{2,1} = allscores.classlookup{2,1};
allqs.class{2,1} = 1:nsubmodels;

name = 'PC';
classlookup = cell(max(ipc),2);
for j=1:max(ipc);
  classlookup(j,1:2) = {j sprintf('%s %i', name, j)};
end
allscores.classname{2,2} = name;
allscores.classlookup{2,2} = classlookup;
allscores.class{2,2} = ipc;

% Copy these mode 2 classes to allloads
allloads = copydsfields(x, allloads, {2 1});  % copy variable fields to loads first dim
allloads = copydsfields(allscores, allloads, {2 2});
% allprojected = copydsfields(allscores, allprojected, {2 2});


% labels for columns, e.g. "Sub-model 1:PC 2"
nscores = size(allscores,2);
lab = cell(nscores,1);
for ii=1:nscores
  lab{ii,1} = sprintf('%s Scores on %s', allscores.classid{2,1}{ii}, allscores.classid{2,2}{ii});
end
allscores.label{2,1} = lab;

lab = cell(nsubmodels,1);
for ii=1:nsubmodels
  lab{ii,1} = sprintf('Q (%s)', allqs.classid{2,1}{ii});
end
allqs.label{2,1} = lab;


lab = cell(nscores,1);
for ii=1:nscores
  lab{ii,1} = sprintf('%s Loadings on %s', allscores.classid{2,1}{ii}, allscores.classid{2,2}{ii});
end
allloads.label{2,1} = lab;

allscores.name = 'combinedscores';
allqs.name     = 'combinedqs';
allloads.name = 'combinedloads';
allprojected.name = 'combinedprojected';

model.combinedscores = allscores;       % scores
model.combinedprojected = allprojected; % projected residuals
model.combinedloads = allloads;         % loads
model.combinedqs     = allqs;           % Qs

% Get effects for Factors and Residuals
ssq_factors = [];
for ifac=1:nsubmodels
  ssq_factors(ifac+1) = res(ifac).ssq;
end
% Add globalmean SS
ssq_factors(1) = globalmeanssq;

ssq_tot = sum(sum((xpporig.data(:,varincl)).^2));
model.detail.effects = 100*ssq_factors/ssq_tot;
tmp = F.classname(1,model.detail.include{2,2});
tmp = { 'Mean' tmp{:} 'Residuals'};

model.detail.effectnames = tmp(:);
model.detail.globalmean  = globalmean(1,:);

if (strcmpi(options.display,'on')|options.display==1)
  c1 = [{'Effect'}; model.detail.effectnames];
  c2 = [{'Effect (%)'} num2cell(model.detail.effects)]';
  c3 = [{'Num. PCs'} num2cell([ 0 npcs])]';
  summary = [c1 c2 c3]';
  mlen = max(cellfun('length',c1))+3;
  dashes = cellfun(@(s) s*0+'-',summary(:,1),'uniformoutput',false);
  disp('                Effects Table for MLSCA Model');
  disp(' ');
  disp(sprintf(['% ' num2str(mlen) 's          % 11s  % 15s'],summary{:,1}));
  disp(sprintf(['% ' num2str(mlen) 's          % 11s  % 15s'],dashes{:}));
  disp(sprintf(['% ' num2str(mlen) 's  % 15.1f%%  % 15i\n'],summary{:,2:end}));
end

%--------------------------------------------------------------------------
function xnew = getmatchingdso(x, xdso)
% Convert to DSO with same sample include as xdso IF x has same number of
% rows as xdso has included rows.
% Pad x with rows of NaN where dso has soft-excluded rows

xincl = xdso.include{1};
hasexcluded = length(xincl)<size(xdso,1);
if hasexcluded
  if size(x,1)==length(xincl)
    % convert
    xnew = nan(size(xdso,1), size(x,2));
    xnew(xincl,:) = x;
    xnew = dataset(xnew);
    xnew.include{1} = xincl;
  else
    error('Input array row count (%d) does not match number of included samples in DSO (%d)', size(x,1), length(xincl));
  end
  
else
  xnew = dataset(x);
end

%--------------------------------------------------------------------------
function [x,y, ncomp, options, datasource] = parsevarargin(varargin)
% USE
%I/O: out = mlsca(x, y, ncomp);
%I/O: out = mlsca(x, y, ncomp, options);
%
%   x         = the experimental response value determined for each
%               experiment/row of y.
%   y         = The experiment design matrix describing the factor settings
%               for each sample (row)
%               Typically this would be a 2^k DOE design matrix.
%  ncomp      = integer or vector of integers giving number of PCs to use
%               in each PCA submodel

varargin = varargin{1};
nargin = length(varargin);
if nargin < 2
  error('ASCA requires at least 2 input arguments')
end
if ~(isdataset(varargin{1}) | isnumeric(varargin{1})) | ~(isdataset(varargin{2}) | isnumeric(varargin{2}))
  error('ASCA: First two arguments must be non-empty x and y data arrays or dataset objects.');
end
switch nargin
  case 1
    % mlsca(x)
    x = varargin{1};
    %     y = x.class{1};
    ncomp = inf;
    options = mlsca('options');
  case 2
    %    mlsca(x,y)
    x = varargin{1};
    y = varargin{2};
    
    newlevcls = size(y,2);
    if ~isa(x, 'dataset')
      x = dataset(x);
      nrowcls = 0;
    else
      nrowcls = length(x.class(1,:));
    end
    for icl=1:newlevcls
      ii = nrowcls+icl;
      x.classid{1,ii} = y(:,icl);
    end
    
    ncomp = inf;
    options = mlsca('options');
  case 3  % 3 arg:
    %    mlsca(x,y,ncomp)
    if isnumeric(varargin{3})
      % (x,y,ncomp)
      x = varargin{1};
      y = varargin{2};
      ncomp = varargin{3};
      options = mlsca('options');
    elseif isstruct(varargin{3})
      [x,y,options] = deal(varargin{:});
      ncomp = [];
    else
      error('ASCA called with three arguments requires ncomp as third argument.');
    end
    
  case 4 % 4 arg:
    % mlsca(x, y, ncomp, options);
    x = varargin{1};
    y = varargin{2};
    if isnumeric(varargin{3}) & isstruct(varargin{4})
      ncomp   = varargin{3};
      options = varargin{4};
    else
      error('ASCA has unexpected third argument or fourth argument.');
    end
    
  otherwise
    error('mlsca: unexpected number of arguments to function ("%s")', nargin);
end

[datasource{1:2}] = getdatasource(x,y);

% [y, column_ID] = getcolumnid(y, options);

% test ncomp
if isempty(ncomp)
  ncomp = inf;
end
if length(ncomp)>1
  if length(ncomp)~=(size(y,2)+1)  % +1 to account for residuals
    error('MLSCA: Length of input argument NCOMP must equal number of columns in y + 1')
  end
else
  ncomp = repmat(ncomp,1, size(y,2)+1);
end

%--------------------------------------------------------------------------
function [x,y] = converttodso(x,y, options)
%C) CHECK Data Inputs
if isa(x,'double')      %convert x and y to DataSets
  x        = dataset(x);
  x.name   = inputname(1);
  x.author = 'MLSCA';
elseif ~isa(x,'dataset')
  error(['Input X must be class ''double'' or ''dataset''.'])
end
if ndims(x.data)>2
  error(['Input X must contain a 2-way array. Input has ',int2str(ndims(x.data)),' modes.'])
end

if isa(y,'double') | isa(y,'logical')
  y        = dataset(y);
  y.name   = inputname(2);
  y.author = 'MLSCA';
elseif ~isa(y,'dataset')
  error(['Input Y must be class ''double'', ''logical'' or ''dataset''.'])
end

if isa(y.data,'logical');
  y.data = double(y.data);
end
if ndims(y.data)>2
  error(['Input Y must contain a 2-way array. Input has ',int2str(ndims(y.data)),' modes.'])
end
if size(x.data,1)~=size(y.data,1)
  error('Number of samples in X and Y must be equal.')
end
%Check INCLUD fields of X and Y
i       = intersect(x.includ{1},y.includ{1});
if ( length(i)~=length(x.includ{1,1}) | ...
    length(i)~=length(y.includ{1,1}) )
  if (strcmp(lower(options.display),'on')|options.display==1)
    disp('Warning: Number of samples included in X and Y not equal.')
    disp('Using intersection of included samples.')
  end
  x.includ{1,1} = i;
  y.includ{1,1} = i;
end

%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab           datatype        valid                            userlevel       description
'display'                'Display'     'select'        {'on' 'off'}                     'novice'        '[ {''off''} | ''on''] governs level of display.';
'blockdetails'           'Standard'    'select'        {'standard' 'all'}               'novice'        'Extent of predictions and raw residuals included in model. ''standard'' = keeps only y-block, ''all'' keeps both x- and y- blocks.';
'preprocessing'          'Set-Up'      'cell(vector)'  ''                               'novice'        '{[ ]} preprocessing structure used for each class model (see PREPROCESS).';
};

out = makesubops(defs);
