function model = asca(varargin)
%ASCA ANOVA Simultaneous Component Analysis
%
% Implements ASCA following Smilde et al, "ANOVA-simultaneous component
% analysis (ASCA): a new tool for analyzing designed metabolomics data",
% Bioinformatics, 2005.
% Versions 8.9 and later include the ASCA+ extension to ASCA to handle an  
% un-balanced design dataset, as introduced by Thiel, Feraud, and  
% Govaerts (2017). This approach uses a general linear model to estimate the 
% ANOVA model parameters by regression rather than by using differences 
% between level means as in conventional ANOVA. With un-balanced designs the  
% conventional ANOVA estimation of factor effects become biased but are  
% correctly estimated using ASCA+.
%
% INPUTS:
%   x        = the experimental value determined for each experiment/row
%              of F. See outputs regarding behvior when x is a matrix.
%   F        = array or dataset describing the settings of each Y variable
%              (cols) for each sample (row). Typically this would be a 2^k
%              DOE design matrix.
%              Note, When F is a dataset then the origin/identity of each
%              column should be described in the options field,
%              "interactions", or in the userdata.DOE.col_ID field.
%
% OPTIONAL INPUTS:
%
%      ncomp : Vector of integer values indicating the number of Principal
%              Components to use in each sub-model (entry for each main
%              effect and interaction, plus one for residuals), or an
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
%     interactions : cell array or integer.
%                    cell array: contain numerical vectors indicating which
%                    factors contribute to columns of F, or 
%                    integer: value which specifies the maximum order of 
%                    interactions to include.
%                    For example, interactions = 3 includes two-way and
%                    three-way interactions.
%                    Example using cell array, interactions = { 1 2 [1 2]}
%                    indicates the first two columns of F represent factors
%                    while the third column represents the interaction of
%                    these two factors. 
%                    If interactions is a cell array and F is a Dataset then 
%                    it is assumed that all columns of F are included.
%    npermutations : [{0}] Number of permutations to use when appling
%                     permutation test to each main factor to get P-value
%                     using Null Hypothesis that the factor has no effect
%                     on the experimental outcome. This value determines
%                     the smallest resolvable P-value (=1/npermutations).
%   nocenterpoints : [ 'off' |{'on'}] governs automatic filtering of center
%                     points. If a design contains additional added center
%                     points, these are typically removed before
%                     calculating the factor effects. However, some other
%                     packages do not do this filtering and the only way to
%                     match their results is to disable the filtering by
%                     setting this option to 'off'. Note that filtering can
%                     only be done if the input F is a DOE DataSet object.
%
% OUTPUT:
%  model = an ASCA standard model structure containing fields (when input
%         matrix x has size mxn):
%         submodel: {1 x nsub cell} of evrimodels, where nsub is the number
%         of main effects and interactions, plus 1 (for residuals).
%         combinedscores: [mxp dataset], where p is the cumulative number
%           of PCs used over all PCA sub-models. Column class sets identify
%           which sub-model and PC number each column is associated with.
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
%  The ANOVA decomposition matrices are returned in the decomp sub-field.
%  If option npermutations is > 0 the Permutation Test P-value for each
%  main factor is in model.detail.pvalues.
%  Note, the helper function PLOTSCORES_ASCA is useful for viewing the
%  results of ASCA.
%
%I/O: [model] = asca(x, F);
%I/O: [model] = asca(x, F, ncomp);
%I/O: [model] = asca(x, F, ncomp, options);
%
%See also: ANOVADOE, DOEGEN, DOEINTERACTIONS, PLOTSCORES_ASCA

% Copyright © Eigenvector Research, Inc. 2011
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.


%Start Input
if nargin==0  % LAUNCH GUI
  analysis asca
  return
end

if ischar(varargin{1});
  options = [];
  options.name          = 'options';
  options.display       = 'on';     %Displays output to the command window
  options.blockdetails  = 'standard';  %level of details
  options.nocenterpoints =  'on';
  options.interactions      = [];
  options.preprocessing = {[]};
  options.npermutations = 0;
  options.definitions   = @optiondefs;
  
  if nargout==0; evriio(mfilename,varargin{1},options); else; model = evriio(mfilename,varargin{1},options); end
  return;
end

% parse input parameters
[x, F, column_ID, ncomp, options, datasource] = parsevarargin(varargin);

options = reconopts(options,mfilename);

options.blockdetails = lower(options.blockdetails);
switch options.blockdetails
  case {'standard','all'};
  otherwise
    error(['OPTIONS.BLOCKDETAILS not recognized.'])
end

model    = modelstruct('asca');
model.submodel = {};  %start with empty submodel structure

% Convert x and F to dataset, if not already
[x,F] = converttodso(x,F, options);

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
% problem: F's class{2} is Factor type (categ/numeric) if from doegen,
% But class{2} Factor Type is factor order if from doeinteraction
model.detail.includ{1,1} = x.include{1};  % model's mode 1 (samples), block 1 (x) set = x included samples
model.datasource = datasource;
model.detail.interactions = column_ID;

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
model.detail.preprocessing = preprocessing;   %copy calibrated preprocessing info into model

% anovadoe
optsdoe = anovadoe('options');
optsdoe.nocenterpoints = options.nocenterpoints;
a = anovadoe(F, xpp, column_ID, optsdoe);

model.detail.decompdata  = a.coeffs.matrices;
model.detail.decompnames = a.coeffs.names;
model.detail.decomp      = a.decomp;
model.detail.decomp.regparams = a.coeffs.factors; % regression parameters
hasanovatable = isfieldcheck(a,'.table');
if hasanovatable & ~isempty(a.table)
  model.detail.anovadoe.table = a.table;
end

neffects = length(model.detail.decomp.designmats);  % Not incl. global mean

% Get P-values for the main effects
if options.npermutations>0
  pvalues = getfactorpvalues(a, xpp, F, column_ID, options.npermutations, optsdoe);
  model.detail.pvalues = pvalues;
end

%identify order of column_ID entries
order  = cellfun('length',column_ID);

allscores = [];
allloads  = nan(size(x,2),0);
allprojected = [];
isubmodel    = [];
ipc          = [];
iorder       = [];
npcs         = [];

varincl = xpp.include{2};
isunivariatey = length(varincl)==1;
% Do PCA
nsubmodels = neffects+1;  % +1 for residuals
for imod = 1:nsubmodels
  % if using compact form
  %   anovamatrix = a.decomp.coeffswtd(a.decomp.designmatscols{imod+1},:);
  % if using full form (these should match)
  if imod < nsubmodels
    anovamatrix = a.coeffs.matrices{imod+1};
  else
    anovamatrix = a.coeffs.residuals;
  end

  submodel = pca(anovamatrix, ncomp(imod), pcaopts);
  npc = size(submodel.loads{1}, 2);
  npcs(imod) = npc;
  
  %store submodel in model
  model.submodel{end+1} = submodel;
  if isunivariatey   
    scores = anovamatrix;
    if npc<1   % edge case where rank(anovamatrix) = 0, which sets npc=0
      scores = [];
    end
  else
  scores = submodel.loads{1};  % accumulate scores for each component
  end
  allscores = [allscores scores];
  allloads(varincl,end+1:end+submodel.ncomp) = submodel.loads{2,1};
  isubmodel = [isubmodel repmat(imod, 1, npc)];
  ipc       = [ipc 1:npc];
  if imod < nsubmodels
    iorder    = [iorder repmat(order(imod), 1, npc)];
  else
    iorder    = [iorder repmat(max(iorder)+1, 1, npc)];  % Set Factor order for Residuals
  end
  
  % project residuals onto loadings, of non-empty effect/interaction sub-models
  if size(submodel.loads{1}, 2) > 0    % if PCA model is not empty
    if isunivariatey
      projected = a.coeffs.residuals;
    else
    pred = pca(a.coeffs.residuals, submodel, pcaopts);
    projected = pred.loads{1};
    end
    allprojected = [allprojected projected];
  end
end

% Make scores and projected into DSO's with classes for isubmodel and ipc
% and maybe for factor order, as latter is needed in making interaction plot.
allscores = getmatchingdso(allscores, xpp);
allloads  = dataset(allloads);
allprojected = getmatchingdso(allprojected, xpp);

name = 'Sub-model';
lbls     = str2cell(model.detail.label{2,2}(model.detail.include{2,2},:));
if length(lbls)~=neffects & size(F.classname,2)==neffects
  lbls = F.classname(1,model.detail.include{2,2});
end
if length(lbls)~=neffects | ~iscell(lbls) | all(cellfun('isempty',lbls))
  %no [appropriate] labels, create them
  for j=1:neffects;
    lbls{j} = sprintf('%s %i', name, j);
  end
end
lbls{end+1} = 'Residuals';  % Add classid for Residuals submodel
lbls = lbls(:); %make it column-wise
allscores.classname{2,1} = name;
allscores.classlookup{2,1} = [num2cell(1:nsubmodels)' lbls(1:nsubmodels)];
allscores.class{2,1} = isubmodel;

name = 'PC';
classlookup = cell(max(ipc),2);
for j=1:max(ipc);
  classlookup(j,1:2) = {j sprintf('%s %i', name, j)};
end
allscores.classname{2,2} = name;
allscores.classlookup{2,2} = classlookup;
allscores.class{2,2} = ipc;

name = 'Factor Order';
classlookup = cell(max(iorder),2);
for j=1:max(iorder);
  if j < max(iorder)
    classlookup(j,1:2) = {j sprintf('%s %i', name, j)};
  else
    classlookup(j,1:2) = {j 'Residuals'};
  end
end
allscores.classname{2,3} = name;
allscores.classlookup{2,3} = classlookup;
allscores.class{2,3} = iorder;

% Copy these mode 2 classes to allloads
allloads = copydsfields(x, allloads, {2 1});  % copy variable fields to loads first dim
allloads = copydsfields(allscores, allloads, {2 2});
allprojected = copydsfields(allscores, allprojected, {2 2});


% labels for columns, e.g. "Sub-model 1:PC 2"
nscores = size(allscores,2);
lab = cell(nscores,1);
if ~isunivariatey
  for ii=1:nscores
  lab{ii,1} = sprintf('%s Scores on %s', allscores.classid{2,1}{ii}, allscores.classid{2,2}{ii});
  end
else
  for ii=1:nscores
    lab{ii,1} = sprintf('%s', allscores.classid{2,1}{ii});
  end
end
allscores.label{2,1} = lab;

lab = cell(nscores,1);
for ii=1:nscores
  lab{ii,1} = sprintf('%s Loadings on %s', allscores.classid{2,1}{ii}, allscores.classid{2,2}{ii});
end
allloads.label{2,1} = lab;

allscores.name = 'combinedscores';
allloads.name = 'combinedloads';
allprojected.name = 'combinedprojected';

model.combinedscores = allscores;
model.combinedprojected = allprojected;
model.combinedloads = allloads;
model.detail.decompresiduals = a.coeffs.residuals;

% effects
tmp = F.classname(1,model.detail.include{2,2});
tmp = {'Mean' tmp{:} 'Residuals'};
model.detail.effectnames = tmp(:);
model.detail.effects = a.effects;    % percentage of total SS (type III) per factor

if (strcmpi(options.display,'on')|options.display==1)
  c1 = [{'Effect'}; model.detail.effectnames];
  c2 = [{'Effect (%)'} num2cell(model.detail.effects)]';
  c3 = [{'Num. PCs'} num2cell([0 npcs])]';
  summary = [c1 c2 c3]';
  mlen = max(cellfun('length',c1))+3;
  dashes = cellfun(@(s) s*0+'-',summary(:,1),'uniformoutput',false);
  disp('                Effects Table for ASCA Model');
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
function [pvalues] = getfactorpvalues(a, xpp, F, column_ID, nperm, optsdoe)
% Use permutation test to calculate P-value for main factors as in
% Zwanenburg et al, 2011.

%identify order of column_ID entries
order  = cellfun('length',column_ID);
factors = find(order>=1);

if length(xpp.include{2})<size(xpp,2)
  %excluded variables? remove them now (speeds up analysis later)
  xpp = xpp(:,xpp.include{2});
end

if length(F.include{1})~=length(xpp.include{1}) | length(F.include{1})<size(F,1)
  %slower but more accurate - necessary when include field isn't all
  %samples
  useinclude = true;
  xpp = xpp.data.include;
else
  useinclude = false;
  xpp = xpp.data;
end

  % Use Morten's code for fast permutation p-value calculation
  pvalues = mortenpermute(a, xpp, F, column_ID, nperm);

%--------------------------------------------------------------------------
function pvalues = mortenpermute(a, X, F, column_ID, nperm)
%identify order of column_ID entries
order      = cellfun('length',column_ID);
factors    = find(order==1);
interacts  = find(order>1);

designmats = a.decomp.designmats;
Dmain    = designmats(factors);
D2fac    = designmats(interacts);
Dmainall = [Dmain{:}];

n = size(X,1);
nfac = length(factors);
nint = length(interacts);

pvalues = [];
for i=1:nint
  D2fac_marg{i} = (eye(n) - Dmainall*pinv(Dmainall))*D2fac{i};
end

wbh = waitbar(0,'Calculating Permutations (Close to Skip)');
ncycles = nfac + nint;
waitbar(1/(ncycles+1),wbh);

% estimate variance captured by design and inference
% Interaction effects First
pvaluesInt = nan(1, nint);
for i=1:nint    %nt;
  id = 1:nint;
  idlog = true(nint,1);
  idlog(i) = false;
  idout = id(idlog);
  D = D2fac_marg{i};
  D2 = [];
  for ii=1:length(idout);
    D2 = [D2 D2fac_marg{idout(ii)}];
  end
  for ii=1:nfac;
    D2 = [D2 Dmain{ii}];
  end
  % D is the interaction i, D2 is all other interactions + all factors
  pvaluesInt(i) = ANOVApermutationtest(X,D,D2,nperm);
  
  % Update user on progress
  if ~ishandle(wbh)
    % user canceled
    pvalues = [];
    return;
  end
  waitbar((i+1)/(ncycles+1),wbh);
end

% Main effects
pvaluesMain = nan(1, nfac);
for i=1:nfac;
    id = 1:nfac;
    idlog = true(nfac,1);
    idlog(i) = false;
    idout = id(idlog);   
    D = Dmain{i};    
    D2 = [];
    for ii=1:length(idout);
        D2 = [D2 Dmain{idout(ii)}];
    end
    % D is the factor i, D2 is all other factors
    pvaluesMain(i) = ANOVApermutationtest(X,D,D2,nperm);
     
    % Update user on progress
    if ~ishandle(wbh)
      % user canceled
      pvalues = [];
      return;
    end
    waitbar((nint+i)/ncycles,wbh);
end

if ishandle(wbh); delete(wbh); end

pvalues = [pvaluesMain pvaluesInt];

%--------------------------------------------------------------------------
function [x,y,column_ID, ncomp, options, datasource] = parsevarargin(varargin)
% USE
%I/O: out = asca(x, y, ncomp);
%I/O: out = asca(x, y, ncomp, options);
%
%   x         = the experimental response value determined for each
%               experiment/row of y.
%   y         = The experiment design matrix describing the factor settings
%               for each sample (row)
%               Typically this would be a 2^k DOE design matrix.
% column_ID     The origin/identity of each column is described in the
%               'column_ID' var.
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
  case 2
    %    asca(x,y)
    x = varargin{1};
    y = varargin{2};
    ncomp = inf;
    options = asca('options');
  case 3  % 3 arg:
    %    asca(x,y,ncomp)
    if isnumeric(varargin{3})
      % (x,y,ncomp)
      x = varargin{1};
      y = varargin{2};
      ncomp = varargin{3};
      options = asca('options');
    elseif isstruct(varargin{3})
      [x,y,options] = deal(varargin{:});
      ncomp = [];
    else
      error('ASCA called with three arguments requires ncomp as third argument.');
    end
    
  case 4 % 4 arg:
    % asca(x, y, ncomp, options);
    x = varargin{1};
    y = varargin{2};
    if isnumeric(varargin{3}) & isstruct(varargin{4})
      ncomp   = varargin{3};
      options = varargin{4};
    else
      error('ASCA has unexpected third argument or fourth argument.');
    end
    
  otherwise
    error('asca: unexpected number of arguments to function ("%s")', nargin);
end

[datasource{1:2}] = getdatasource(x,y);

% Remove any excluded columns from design matrix DSO
yincl2 = y.include{2};
if isdataset(y) & length(y.include{2}) < size(y,2)
  y = y(:,y.include{2});
end
% Assume Mode 1 classes are one for each factor. Remove those not modeled.
nclasses1 = length(y.class(1,:));
irm = sort(setdiff([1:nclasses1], yincl2), 'descend');
for i = 1:length(irm)
  y = rmset(y,'class', 1, irm(i));
end

% Check for non-finite design matrix (F) values
if isdataset(y)
  hasbadfrows = any(any(~isfinite(y.data(y.include{1},y.include{2}))));
else
  hasbadfrows = any(~isfinite(y(:)));
end
if hasbadfrows
  error('DOE design matrix contains non-finite values')
end
[y, column_ID] = getcolumnid(y, options);

% test ncomp
if isempty(ncomp)
  ncomp = inf;
end
if length(ncomp)>1
  if length(ncomp) < size(y,2) | length(ncomp) > size(y,2)+1
    error('ASCA: Length of input argument NCOMP must equal number of columns in y')
  elseif length(ncomp)== size(y,2)
    ncomp(length(ncomp)) = 2;           % Only use 2 LV PC for Residuals
  end
else
  ncomp = repmat(ncomp,1, size(y,2)+1); % +1 for residuals sub-model
  ncomp(length(ncomp)) = 2;             % Only use 2 LV PC for Residuals
end

%--------------------------------------------------------------------------
function [x, columnid] = getcolumnid(x, options)
% The order of preceedence for getting column_ID:
% x: DSO or matrix. If DSO it is assumed that ALL COLUMNS of x are included.
% cases:
% 1.	DSO/matrix: use options.interactions if not empty.
%       cell array: Assumes that ALL COLUMNS of x are included.
%       integer:    Value indicates level of interaction.
% 2.	DOE DSO. Col ID is in doe.userdata.DOE.col_ID
% 3.	DSO/matrix with no options.interactions: return []; assume each column is a factor.
%
% x  may be modified.
% Outputs:
% x        : The input DSO or matrix with interaction columns and classes
%            added.
% columnid : cell array of column indices indicating factor or interaction,
%            example, columnid = { 1 2 [1 2]} indicates the first two columns 
%            of returned x represent factors while the third column 
%            represents the interaction of these two factors.

if isdataset(x)
  if isfield(options, 'interactions') & ~isempty(options.interactions)
    columnid = options.interactions;
    % 1. if integer then assume it is desired order of interactions.
    % Generate columnid by using doeinteractions.
    if iscell(columnid) | (isnumeric(columnid) & length(columnid)==1)
      [x, columnid] = doeinteractions(x, columnid);
    else
      error('Found unexpected non-empty value for option interactions')
    end
    % 2. if columnid is different from x.userdata.DOE.col_ID then resolve by
    % passing x through doeinteractions to reset
    if isfield(x.userdata, 'DOE') & isfield(x.userdata.DOE, 'col_ID') & ~isempty(x.userdata.DOE.col_ID)
      if ~comparevars(columnid,  x.userdata.DOE.col_ID)
        [x, columnid] = doeinteractions(x, columnid);
      end
    end
    
  elseif isfield(x.userdata, 'DOE') & isfield(x.userdata.DOE, 'col_ID') & ~isempty(x.userdata.DOE.col_ID)
    columnid = x.userdata.DOE.col_ID;
  else
    % Assume all columns are factors
    options.interactions = 1;
    [x, columnid] = doeinteractions(x, options.interactions);
  end
elseif isnumeric(x)
  if isfield(options, 'interactions')
    columnid = options.interactions;
    % 1. if integer then assume it is desired order of interactions.
    % Generate columnid by using doeinteractions.
    if iscell(columnid) | (isnumeric(columnid) & length(columnid)<=1)
      [x, columnid] = doeinteractions(x, columnid);
    else
      error('Found unexpected non-empty value for option interactions')
    end
  else
    columnid = 1:size(x,2);  % assume each column is a factor, no interactions
    columnid = num2cell(columnid);
  end
else
  columnid = [];
end

% Ensure that the factor and interaction classsets are prsent
% and in the correct slots to match columnid.
x = updateclasses(x, columnid);

% % Make columnid consistent with excluded column(s) (factors) of x.
% use one of following
% columnid = columnid(x.include{2});         % Remove excluded columns.
% Remove excluded columns and interaction columns dependent on excluded columns.
[x, columnid] = updatecolumnid(x, columnid);

%--------------------------------------------------------------------------
function [x, columnid] = updatecolumnid(x, columnid)
% Update columnid to be consistent with x's excluded factor(s).
% Note, if x has excluded columns (factors) then remove entries
% representing interactions which involve these factors from the columnid.
% Update x.include{2} and columnid with this new include.
if size(x,2)~=length(columnid)
  error('The number of columns in the Design matrix must equal length of interactions')
end

icols=setdiff(1:size(x,2), x.include{2});  % excluded column(s)

% Find which elements of cell array columnid contain the excluded factor(s)
allexcls = false(1,size(x,2));
for ifac=icols
  excls = cellfun(@(i) any(ismember(i,columnid{ifac})),columnid);
  allexcls = allexcls|excls;  % all the columns which should be excluded
end
nincl = 1:size(x,2);
newinclude2 = nincl(~allexcls);
x.include{2} = newinclude2;
columnid = columnid(newinclude2);

%--------------------------------------------------------------------------
function y = updateclasses(y, columnid)
% y is the DOE design dataset. columnid identifies factor columns and the
% source columns for interaction columns.
% updateclasses adds interaction classsets to y mode 1. Remove any mode 1
% classsets after the first n (the number of Factors in y, as identified by
% columnid).
% Assume the n Factor classes are the first n classsets (just like the
% first n columns of y are for the Factors.
% Assumes size(y,2)==length(columnid), so ignores includes.

%identify order of column_ID entries
order  = cellfun('length',columnid);
interactions = find(order>1);
factors = find(order==1);

% Ensure y has positive integer values
fall = nan(size(y.data));
ftmp = double(y.data);
for i=1:size(ftmp,2)
  [C{i},IA{i},IC{i}] = unique(ftmp(:,i));
  fall(:,i) = IC{i};
end

% Add row classes for each factor and interaction
% Factors
% First remove factor classes
for icol=factors
  if isempty(y.class{1,icol})
    %   for icol = factors
    v = 1:max(fall(:,icol));
    y.classlookup{1,icol} = [num2cell(v)' str2cell(sprintf('Level-%i\n',v))];
    y.class{1,icol} = fall(:,icol);
    
    contribs = columnid{icol};
    name     = sprintf('Factor %d', contribs(1));
    for ii = 2:length(contribs)
      name = [name sprintf('x%d', contribs(ii))];
    end
    y.classname{1,icol} = name;
  end
end

% Interactions
if size(y.class{2},2)>= length(factors) & ~isempty(interactions) % design has interactions cols
  % Remove interaction classsets
  
  f = unique(fall, 'rows');  % This is F, with cols factors,interactions.
  for useset=interactions
    if isempty(y.class{1,useset});
      % Add mode 1 classset to y for each interaction.
      % This will create a default classlookup entry for each.
      levels = unique(f(:,useset));
      lookup = cell( length(unique(f(:,useset))), 2);
      
      iorder  = order(useset);
      indices = columnid{useset};
      lu1 = y.classlookup{1, indices(1)};
      lu2 = y.classlookup{1, indices(2)};
      if iorder==2
        if ~isempty(lu1) & ~isempty(lu2)
          nzrows = [lu1{:,1}];
          lu1=lu1(nzrows>0,:);
          nzrows = [lu2{:,1}];
          lu2=lu2(nzrows>0,:);
          for jj=1:length(levels)
            j  = levels(jj);
            j1 = f(j, indices(1));
            j2 = f(j, indices(2));
            lookup(j,1:2) = {j sprintf('%s %s', lu1{j1,2}, lu2{j2,2}) };
          end
          y.classlookup{1,useset} = lookup;
          y.classname{1,useset} = sprintf('%s:%s', y.classname{1, indices(1)}, y.classname{1, indices(2)});
          y.class{1,useset} = fall(:,useset);
        end
      elseif iorder==3
        lu3 = y.classlookup{1, indices(3)};
        if ~isempty(lu1) & ~isempty(lu2) & ~isempty(lu3)
          nzrows = [lu1{:,1}];
          lu1=lu1(nzrows>0,:);
          nzrows = [lu2{:,1}];
          lu2=lu2(nzrows>0,:);
          nzrows = [lu3{:,1}];
          lu3=lu3(nzrows>0,:);
          for jj=1:length(levels)
            j  = levels(jj);
            j1 = f(j, indices(1));
            j2 = f(j, indices(2));
            j3 = f(j, indices(3));
            lookup(j,1:2) = {j sprintf('%s %s %s', lu1{j1,2}, lu2{j2,2}, lu3{j3,2}) };
          end
          y.classlookup{1,useset} = lookup;
          y.classname{1,useset} = sprintf('%s:%s:%s', y.classname{1, indices(1)}, y.classname{1, indices(2)}, y.classname{1, indices(3)});
          y.class{1,useset} = fall(:,useset);
        end
      end
    end
  end
end

%--------------------------------------------------------------------------
function [x,y] = converttodso(x,y, options)
%C) CHECK Data Inputs
if isa(x,'double')      %convert x and y to DataSets
  x        = dataset(x);
  x.name   = inputname(1);
  x.author = 'ASCA';
elseif ~isa(x,'dataset')
  error(['Input X must be class ''double'' or ''dataset''.'])
end
if ndims(x.data)>2
  error(['Input X must contain a 2-way array. Input has ',int2str(ndims(x.data)),' modes.'])
end

if isa(y,'double') | isa(y,'logical')
  y        = dataset(y);
  y.name   = inputname(2);
  y.author = 'ASCA';
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

%--------------------------------------------------------------------------
function pvalue = ANOVApermutationtest(x,D,D2,nperm)
% D is design matrix of interest
% D2 is the design that we adjust for.
% Essentially Morten's code

if isdataset(x);
    x = x.data;
end
[n p] = size(x);

% model SS
[~, sse3f] = calcsse([D D2],x);

df3f = rank([D D2]);
df2f = rank(D2);
if df3f==df2f;
    pvalue = 1;
    return
end

% permutation
for i=1:nperm;
    id = randperm(n);
    Dp = D(id,:);
    [~, ss3fp(i)] = calcsse([Dp D2],x);    
end
% Calc P-value as the fraction of permutations with ssq>observed ssq.
% with a minimum value of 1/nperm (minimum resolvable probability)
pvalue = max(1/nperm, sum(ss3fp<sse3f)/nperm);

%--------------------------------------------------------------------------
function [E, sse] = calcsse(D,x)
% Morten's code
if nargin==1; % only x;
    E = x;
else
    E = x - D*pinv(D)*x;
end

[n p]= size(E);
if n<p; sse= trace(E*E');
else
    sse = trace(E'*E);
end


%--------------------------
function out = optiondefs()

defs = {
  
%name                    tab           datatype        valid                            userlevel       description
'display'                'Display'     'select'        {'on' 'off'}                     'novice'        '[ {''off''} | ''on''] governs level of display.';
'blockdetails'           'Standard'    'select'        {'standard' 'all'}               'novice'        'Extent of predictions and raw residuals included in model. ''standard'' = keeps only y-block, ''all'' keeps both x- and y- blocks.';
'preprocessing'          'Set-Up'      'cell(vector)'  ''                               'novice'        '{[ ]} preprocessing structure used for each class model (see PREPROCESS).';
'npermutations'          'Statistics'  'double'        'float(0:inf)'                   'novice'        'Number of permutations for testing model validity. 0 = no permutation. >500 is strongly recommended. >5000 is preferred but may take some time.'
'interactions'           'Design'      'select'        {[] 1 2 3}                       'novice'        'An integer which specifies the maximum order of interactions to include. 1 = include only primary factors (remove interactions if present), 2 = include/add 2-way interactions, 3 = inculde/add 3-way interactions, [ ] empty = use only interactions included in currently loaded design.'
'nocenterpoints'         'Design'      'select'        {'off' 'on'}                     'novice'        'Governs automatic filtering of center points. If a design contains additional added center points, these are typically removed before calculating the factor effects. However, some other packages do not do this filtering and the only way to match their results is to disable the filtering by setting this option to ''off''. Note that filtering can only be done if the input F is a DOE DataSet object.'
};

out = makesubops(defs);
