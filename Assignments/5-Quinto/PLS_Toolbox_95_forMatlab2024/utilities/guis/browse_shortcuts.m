function varlist = browse_shortcuts(varlist_in,options)
%BROWSE_SHORTCUTS defines shortcuts available on the EVRI Workspace Browser
% This function is used by BROWSE to define the shortcuts available to a
% user on the Eigenvector Resarch Workspace Browser window. The list is
% customizable by editing this file.
%
%  OPTIONAL INPUT:
%   options = structure array with the following fields:
%           favorites  : cell array of short cut names.
%           typeicons  : nx2 cell array of .type name and icon name.
%           showmovies : [{'on'} | 'off'] show movie links.
%
%I/O: varlist = browse_shortcuts(varlist)
%
%See also: BROWSE

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%NOTE: Use this code to generate cut & paste xml for eigenguides.xml
%webinar videos: 
%
% doc = org.jsoup.Jsoup.connect('https://eigenvector.com/resources/webinars/').get;
% tbl = doc.getElementById('tablepress-4');
% rows = tbl.select("tr");
% for i = 1:rows.size-1
%   %Java is 0 based so start at 1 to ignore title row.
%   row = rows.get(i);
%   title = char(row.getElementsByClass('column-2').text);
%   title = strrep(title,'&','and');
%   thisurl = char(row.getElementsByClass('column-3').select('a').attr('href'));
%   disp('  <movie>')
%   disp(['    <name>' title '</name>'])
%   disp(['    <category>Webinars</category>'])
%   disp(['    <category_order>6</category_order>'])
%   disp(['    <link>' thisurl '</link>'])
%   disp('  </movie>')
% 
% end

% persistent addshortcuts

if nargin==0; varlist_in = 'io'; end
if ischar(varlist_in);
  switch varlist_in
    case 'select'
      %give dialog to choose which icons to show
      list = browse_shortcuts([],struct('show',''));
      list = {list.name};
      %Remove movies.
      movielist = createMovies('');
      if ~isempty(movielist)
        list = list(~ismember(list,{movielist.name}));
      end
      
      selected = browse_shortcuts([]);
      if ~isempty(selected)
        selected = find(ismember(list,{selected.name}));
      end
      
      [s,v] = listdlg('PromptString','Select Shortcuts to Show:',...
        'InitialValue',selected,...
        'SelectionMode','multiple',...
        'ListString',list);
      
      if v;
        setplspref(mfilename,'show',list(s));
      end
      
    otherwise
      %EVRIIO call
      options = [];
      options.show = [];
      options.favorites = { 'Getting Started' 'DataSet Editor' 'PCA - Principal Component Analysis' 'PLS - Partial Least Squares' 'Trend Tool' };
      options.typeicons = {'tools' 'decomposition' 'regression' 'diviner' 'clustering'  'classification' 'Design of Experiments' 'batch analysis' 'transform' 'other' 'addon' 'Image Processing' 'workspace' 'visualization' 'help' 'eigenguide online videos';...
                           'tools_16' 'decompose_16' 'regression_16' 'diviner_16' 'cluster_16'  'classification_16' 'arrows3D_16' 'clock_16' 'removered_16' 'greenlink_16' 'hierarchy_16' 'miagui_16' 'greypencil_16' 'mcr_16' 'help_16' 'movie_16'};
      options.showmovies = 'on';
      if nargout==0; evriio(mfilename,varlist_in,options);  else; varlist = evriio(mfilename,varlist_in,options); end
  end
  return
end

if nargin<2;
  options = [];
end
options = reconopts(options,mfilename);

varlist = varlist_in([]);

%--------------------------------------------------------------------------
% Input is "varlist", a structure array onto which each shortcut can be
% added. Shortcuts appear first in the browser but are otherwise ordered as
% they appear here.

varlist(end+1).name     = 'Getting Started';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'helppls' 'getting_started_overview'};
varlist(end).drop       = 'off';
varlist(end).icon       = browseicons('help');
varlist(end).type       = 'help';

%Regression
varlist(end+1).name     = 'PLS - Partial Least Squares';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'pls'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('regression');
varlist(end).type       = 'regression';

varlist(end+1).name     = 'NPLS - Multiway Partial Least Squares';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'npls'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('regression');
varlist(end).type       = 'regression';

varlist(end+1).name     = 'PCR - Principal Component Regression';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'pcr'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('regression');
varlist(end).type       = 'regression';

varlist(end+1).name     = 'LWR - Locally Weighted Regression';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'lwr'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('regression');
varlist(end).type       = 'regression';

varlist(end+1).name     = 'MLR - Multiple Linear Regression';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'mlr'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('regression');
varlist(end).type       = 'regression';

varlist(end+1).name     = 'MLR DOE - Designed Experiment MLR';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'mlr'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('regression');
varlist(end).type       = 'regression';
varlist(end+1) = varlist(end);
varlist(end).type       = 'Design of Experiments';

varlist(end+1).name     = 'SVM - Support Vector Machine';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'svm'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('regression');
varlist(end).type       = 'regression';

varlist(end+1).name     = 'CLS - Classical Least Squares';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'cls'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('regression');
varlist(end).type       = 'regression';

varlist(end+1).name     = 'CLSTI - CLS Temperature Interpolated';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'clsti'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('regression');
varlist(end).type       = 'regression';

varlist(end+1).name     = 'ANN - Artificial Neural Network';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'ann'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('regression');
varlist(end).type       = 'regression';

varlist(end+1).name     = 'ANNDL - Deep Learning Artificial Neural Network';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'anndl'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('regression');
varlist(end).type       = 'regression';

varlist(end+1).name     = 'ANNDA - Artificial Neural Network Discriminant Analysis';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'annda'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('cluster');
varlist(end).type       = 'classification';

varlist(end+1).name     = 'ANNDLDA - Deep Learning Artificial Neural Network Discriminant Analysis';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'anndlda'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('cluster');
varlist(end).type       = 'classification';

varlist(end+1).name     = 'XGBoost - Gradient Boosted Tree Regression';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'xgb'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('regression');
varlist(end).type       = 'regression';

%Decompose
varlist(end+1).name     = 'PCA - Principal Component Analysis';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'pca'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('decompose');
varlist(end).type       = 'decomposition';
varlist(end+1) = varlist(end);
varlist(end).type       = 'visualization';

varlist(end+1).name     = 'MCR - Multivariate Curve Resolution';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'mcr'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('mcr');
varlist(end).type       = 'decomposition';

varlist(end+1).name     = 'SIMPLISMA - Purity';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'purity'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('mcr');
varlist(end).type       = 'decomposition';

varlist(end+1).name     = 'PARAFAC - Parallel Factor Analysis';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'parafac'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('mcr');
varlist(end).type       = 'decomposition';
varlist(end+1) = varlist(end);
varlist(end).type       = 'batch analysis';

varlist(end+1).name     = 'PARAFAC2 - PARAFAC for Unevenly Sized Arrays';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'parafac2'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('mcr');
varlist(end).type       = 'decomposition';

varlist(end+1).name     = 'MPCA - Multiway PCA';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'mpca'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('decompose');
varlist(end).type       = 'decomposition';
varlist(end+1) = varlist(end);
varlist(end).type       = 'batch analysis';

varlist(end+1).name     = 'Batch Maturity';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'batchmaturity'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('decompose');
varlist(end).type       = 'decomposition';
varlist(end+1) = varlist(end);
varlist(end).name       = 'Model Batch Maturity';
varlist(end).type       = 'batch analysis';

varlist(end+1).name     = 'TSNE - t-Distributed Stochastic Neighbor Embedding';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'tsne'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('decompose');
varlist(end).type       = 'decomposition';
varlist(end+1) = varlist(end);
varlist(end).type       = 'visualization';
varlist(end+1) = varlist(end);
varlist(end).name       = 'Model TSNE';
varlist(end).type       = 'batch analysis';

varlist(end+1).name     = 'UMAP - Uniform Manifold Approximation and Projection';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'umap'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('decompose');
varlist(end).type       = 'decomposition';
varlist(end+1) = varlist(end);
varlist(end).type       = 'visualization';
varlist(end+1) = varlist(end);
varlist(end).name       = 'Model umap';
varlist(end).type       = 'batch analysis';

%Cluster
varlist(end+1).name     = 'Cluster Analysis';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'cluster'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('cluster');
varlist(end).type       = 'clustering';

%Classification
varlist(end+1).name     = 'KNN - K-Nearest Neighbor';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'knn'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('cluster');
varlist(end).type       = 'classification';

varlist(end+1).name     = 'SVMDA - Support Vector Machine Discriminant Analysis';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'svmda'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('cluster');
varlist(end).type       = 'classification';

varlist(end+1).name     = 'PLSDA - Partial Least Squares Discriminant Analysis';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'plsda'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('cluster');
varlist(end).type       = 'classification';

varlist(end+1).name     = 'SIMCA - Soft Independent Modeling of/by Class Analogy';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'simca'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('cluster');
varlist(end).type       = 'classification';

varlist(end+1).name     = 'XGBoostDA - Gradient Boosted Tree Discriminant Analysis';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'xgbda'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('cluster');
varlist(end).type       = 'classification';

varlist(end+1).name     = 'LREGDA - Logistic Regression Discriminant Analysis';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'lregda'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('cluster');
varlist(end).type       = 'classification';

varlist(end+1).name     = 'LDA - Linear Discriminant Analysis';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'lda'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('cluster');
varlist(end).type       = 'classification';

varlist(end+1).name     = 'ASCA - ANOVA Simultaneous Component Analysis';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'asca'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('cluster');
varlist(end).type       = 'Design of Experiments';

varlist(end+1).name     = 'MLSCA - Multi-level Simultaneous Component Analysis';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'analysis' 'mlsca'};
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('cluster');
varlist(end).type       = 'Design of Experiments';

%Transform
varlist(end+1).name     = 'Batch Processor';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'bspcgui';
varlist(end).drop       = 'input';
varlist(end).nargout    = 0;
varlist(end).icon       = browseicons('wafer');
varlist(end).type       = 'batch analysis';

varlist(end+1).name     = 'Calibration Transfer';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'caltransfergui';
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('caltransfer');
varlist(end).type       = 'transform';

varlist(end+1).name     = 'Calibration Transfer (Apply)';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'caltransfer';
varlist(end).drop       = 'input';
varlist(end).nargout    = 1;
varlist(end).icon       = browseicons('caltransfer');
varlist(end).type       = 'transform';

varlist(end+1).name     = 'Modelcentric Calibration Transfer';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'MCCTTool';
varlist(end).drop       = 'input';
varlist(end).nargout    = 0;
varlist(end).icon       = browseicons('caltransfer');
varlist(end).type       = 'transform';

varlist(end+1).name     = 'Polynomials and Cross Terms';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'polytransform_browse';
varlist(end).drop       = 'input';
varlist(end).nargout    = 2;
varlist(end).icon       = browseicons('caltransfer');
varlist(end).type       = 'transform';

varlist(end+1).name     = 'Coadd Data Reduction';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'coadd';
varlist(end).drop       = 'input';
varlist(end).nargout    = 1;
varlist(end).icon       = browseicons('caltransfer');
varlist(end).type       = 'transform';

varlist(end+1).name     = 'Reduce NN Samples';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'reducennsamples';
varlist(end).drop       = 'input';
varlist(end).nargout    = 1;
varlist(end).icon       = browseicons('caltransfer');
varlist(end).type       = 'transform';

varlist(end+1).name     = 'Unfold Multiway';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'unfoldmw';
varlist(end).drop       = 'input';
varlist(end).nargout    = 1;
varlist(end).icon       = browseicons('caltransfer');
varlist(end).type       = 'transform';

varlist(end+1).name     = 'Variable Lagging';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'wrtpulse';
varlist(end).drop       = 'input';
varlist(end).nargout    = 0;
varlist(end).icon       = browseicons('wafer');
varlist(end).type       = 'transform';
varlist(end+1) = varlist(end);
varlist(end).type       = 'batch analysis';

%Other
varlist(end+1).name     = 'Compare LCMS';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'comparelcms_sim_interactive';
varlist(end).drop       = 'input';
varlist(end).icon       = browseicons('comparelcms');
varlist(end).type       = 'other';

varlist(end+1).name     = 'CODA DW';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'coda_dw_interactive';
varlist(end).drop       = 'input';
varlist(end).icon       = browseicons('codadw');
varlist(end).type       = 'other';

varlist(end+1).name     = 'Preprocessing';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'preprocess';
varlist(end).drop       = 'input';
varlist(end).nargout    = 1;
varlist(end).icon       = browseicons('preprocess');
varlist(end).type       = 'transform';

varlist(end+1).name     = 'GA Variable Selection';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'genalg';
varlist(end).drop       = 'input';
varlist(end).icon       = browseicons('genalg');
varlist(end).type       = 'other';

varlist(end+1).name     = 'Correlation Spectroscopy';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'corrspecgui';
varlist(end).drop       = 'input';
varlist(end).nargout    = 0;
varlist(end).icon       = browseicons('mcr');
varlist(end).type       = 'other';
varlist(end+1)          = varlist(end);
varlist(end).type       = 'visualization';

varlist(end+1).name     = 'PlotGUI - Data plotting tool.';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'plotgui';
varlist(end).drop       = 'input';
varlist(end).icon       = browseicons('plotgui');
varlist(end).type       = 'tools';
varlist(end+1)          = varlist(end);
varlist(end).type       = 'visualization';

varlist(end+1).name     = 'Script Interpreter';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'scriptexpert';
varlist(end).drop       = 'off';
varlist(end).icon       = browseicons('dsedit');
varlist(end).type       = 'tools';

varlist(end+1).name     = 'Hierarchical Modeling';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'modelselectorgui';
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('dsedit');
varlist(end).type       = 'tools';

varlist(end+1).name     = 'Multiblock Modeling';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'multiblocktool';
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('dsedit');
varlist(end).type       = 'tools';

varlist(end+1).name     = 'Experiment Designer (DOE)';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'doegui';
varlist(end).drop       = 'off';
varlist(end).icon       = browseicons('dsedit');
varlist(end).type       = 'Design of Experiments';

%Tools
varlist(end+1).name     = 'Trend Tool';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'trendtool';
varlist(end).drop       = 'input';
varlist(end).nargout    = 0;
varlist(end).icon       = browseicons('shortcut');
varlist(end).type       = 'tools';

varlist(end+1).name     = 'Choose Shortcuts';
varlist(end).class      = 'shortcut';
varlist(end).fn         = {'browse' 'selectshortcuts'};
varlist(end).drop       = 'off';
varlist(end).icon       = browseicons('help');
varlist(end).type       = 'help';

varlist(end+1).name     = 'DataSet Editor';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'editds';
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('dsedit');
varlist(end).type       = 'tools';

varlist(end+1).name     = 'Model Optimizer';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'modeloptimizer';
varlist(end).drop       = 'figure';
varlist(end).icon       = browseicons('dsedit');
varlist(end).type       = 'tools';

varlist(end+1).name     = 'Diviner';
varlist(end).class      = 'shortcut';
varlist(end).fn         = 'diviner';
varlist(end).drop       = 'off';
varlist(end).icon       = browseicons('dsedit');
varlist(end).type       = 'diviner';

%---------------------------------------------------------------
%Add favorites type as copy of existing.
if isfield(options,'favorites')
  if iscell(options.favorites) && ~isempty(options.favorites)
    fuse = ismember({varlist.name},options.favorites);
    fvarlist = varlist(fuse);
    %Remove duplicates.
    [C,ia,ic] = unique({fvarlist.name});
    fvarlist = fvarlist(ia);
    for i = 1:length(fvarlist)
      fvarlist(i).type = 'favorites';
    end
    varlist = [fvarlist(:); varlist(:)];
  end
end

%---------------------------------------------------------------
%Check for addons.
fnlist = evriaddon('browse_shortcuts');
addshortcuts = cell(1,length(fnlist));
for j=1:length(fnlist)
  addshortcuts{j} = feval(fnlist{j});
end
% end
for j=1:length(addshortcuts);
  for k=1:length(addshortcuts{j});
    ind = length(varlist)+1;
    for f = fieldnames(addshortcuts{j}(k))';
      varlist(ind).(f{:}) = addshortcuts{j}(k).(f{:});
    end
    if ~isfield(varlist(ind),'type') || isempty(varlist(ind).type)
      varlist(ind).type = 'addon';
    end
  end
end

%---------------------------------------------------------------
%Use 'show' filter.
if isfield(options,'show')
  if iscell(options.show);
    allnames = {varlist.name};
    %Check for old names.
    if ~all(ismember(options.show,allnames))
      %Probably legacy names in list so reset.
      setplspref('browse_shortcuts','show',[])
    else
      use = ismember(allnames,options.show);
      varlist = varlist(use);
    end
  end
end

%---------------------------------------------------------------
%Add movies.
if strcmp(options.showmovies,'on') && checkmlversion('>=','7.1')
  varlist = createMovies(varlist);
end

%---------------------------------------------------------------
%call addon connections to filter shortcuts (if desired)
fnlist = evriaddon('browse_shortcuts_filter');
for j=1:length(fnlist)
  varlist = feval(fnlist{j},varlist);
end

if ~isempty(varlist);
  varlist = [varlist_in(:)' varlist(:)'];
else
  varlist = varlist_in;
end

%---------------------------------------------------------------
function varlist = createMovies(varlist)
%Add movies to varlist.

persistent list lastcheck nomovies

if isempty(nomovies)
  nomovies = getfield(browse('options'),'nomovies');
end  
if ~isempty(nomovies) & nomovies  %if flag is set to skip doing movies, exit now
  return;
end
  
try
  if ~isempty(list) & ischar(list)
    %Website did not send back movie list last time (website may be down).
    nextcheck = getplspref(mfilename,'nextcheck');
    if isempty(nextcheck)
      nextcheck = nextcheckdefault;
    end
    if (now-lastcheck)>nextcheck/60/24
      %if more than n minutes ago, clear list so we'll recheck website
      list = [];
    else
      %read in default list of movies so we can show SOMETHING
      egxml = evriwhich('eigenguides.xml');
      if ~isempty(egxml)
        list = parsexml(egxml,1);
      else 
        list = 'n/a';
      end
    end
  end
  
  if isempty(list)
    %Since website update to Wordpress in summer of 2019 the code below does
    %not work. If we update the website to list movies we can modify the
    %eigenguide.php file to fix things. Disable as of PLSTB 8.8. Videos are
    %hard-coded in the eigenguides.xml file.
    xmllist = '';
%     request = {'GET /eigenguide.php?xml=1 HTTP/1.1'
%       'Host: www.eigenvector.com'
%       'User-Agent: Matlab'
%       ''};
%     xmllist = sendmsg('www.eigenvector.com',80,request);
    lastcheck = now;
    if isempty(xmllist);
      %no response from server?
      list = 'n/a';  %block from getting list again until time passes
      incrementnextcheck
    else
      %got a response from the server - parse for xml
      endheader = strfind(xmllist,[10 10]);
      if ~isempty(endheader) & length(xmllist)>endheader
        xmllist = strtrim(xmllist(endheader+2:end));
        try
          %parse the xml we got
          if isempty(xmllist) | isempty(regexp(xmllist,'<movielist>', 'once')); error('no data'); end; %skips to catch
          try
            list = parsexml(xmllist,1);
          catch
            if ~isdeployed
              evritip('browsemovies');
            end
            rethrow(lasterror)
          end
          %if it parsed OK, reset next check
          setplspref(mfilename,'nextcheck',nextcheckdefault);
        catch
          %error parsing XML?
          list = 'n/a';  %block from getting list again until time passes
          incrementnextcheck
        end
      else
        %couldn't find end of header? server problem
        list = 'n/a';  %block from getting list again until time passes
        incrementnextcheck
      end
    end
  end
  
  %now, look for the movielist
  if isfield(list,'movie')
    %parsed a list of movies - extract "movie" field
    
    for i=1:length(list.movie); 
      if isempty(list.movie{i}.category); list.movie{i}.category = 'Introduction'; end
      cats{i} = list.movie{i}.category; 
      order(i) = str2num(list.movie{i}.category_order); 
    end
    [ucats,ci,cj] = unique(cats);
    [sorder,so] = sort(order(ci));
    cj = cj(:)';  %assure row vector
    
    for i = 1:length(so);
      %for each category
      varlist(end+1).name     = ucats{so(i)};
      varlist(end).class      = 'category';
      varlist(end).fn         = {'browse'};
      varlist(end).drop       = 'off';
      varlist(end).icon       = browseicons('help');
      varlist(end).type       = 'eigenguide online videos';

      for it = find(cj==so(i));
        varlist(end+1).name     = list.movie{it}.name;
        varlist(end).class      = 'shortcut';
        varlist(end).fn         = {'browse' 'showvideo' list.movie{it}.link};
        varlist(end).drop       = 'off';
        varlist(end).icon       = browseicons('help');
        varlist(end).type       = 'eigenguide online videos';
      end
    end
      
  end
catch
  %do NOTHING
  list = 'n/a';
  incrementnextcheck
end

%------------------------------------------------------
function incrementnextcheck

incrementrate = 14; %factor to increase time for each period we fail
% 60 minutes
% 14 hours
% 8.2 days
% 114.3 days
% 4.4 years

nextcheck = getplspref(mfilename,'nextcheck');
if ~isempty(nextcheck) %already had at least one failure, raise next check limit
  nextcheck = nextcheck*incrementrate; 
else
  nextcheck = nextcheckdefault;
end
setplspref(mfilename,'nextcheck',nextcheck);

%------------------------------------------------------
function out = nextcheckdefault 

out = 60;  %default time period is to check every __ minutes

%------------------------------------------------------
function [rcv] = sendmsg(srv, port, msg)
%SENDMSG sends message via java socket.
%  Function will wait one second and then see if a message was sent back
%  and put resutls into rcv.
%
% INPUTS:
%   srv  - [string] either URL name or IP address.
%   port - [double] port number to connect to on server.
%   msg  - [string] message to send.
% OUTPUT:
%   rcv  - [string] response from server.
%
%I/O: rcv = sendmsg(srv, port, msg)

%Copyright Eigenvector Research, Inc. 2002-2007
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

if ~iscell(msg);
  msg = {msg};
end

timeout = 1000;  %miliseconds before no server response is considered fatal

try
  starttime = now;
  clientSocket = java.net.Socket;
  clientSocket.connect(java.net.InetSocketAddress(srv, port), timeout) 
  iStream_client = clientSocket.getInputStream;
  iReader_client = java.io.InputStreamReader(iStream_client);

  outStream_client = clientSocket.getOutputStream;

  clientOut = java.io.PrintWriter(outStream_client, true);
  clientIn = java.io.BufferedReader(iReader_client);
  clientOut.println(java.lang.String(sprintf('%s\n',msg{:})));

  while ~clientIn.ready
    if (now-starttime)>3/60/60/24;
      error('No response from server')
    end
  end

  rcv = {};
  while clientIn.ready
    rcv{end+1} = char(readLine(clientIn));
  end
  if length(rcv)>1;
    rcv = sprintf('%s\n',rcv{:});
  else
    rcv = rcv{1};
  end
  
catch
  rcv = '';
end

try
  clientSocket.close;
end
try  
  iStream_client.close;
end
try
  outStream_client.close;
end
try
  clientIn.close;
end
try
  clientOut.close;
end

