function out = analysistypes(tag,index)
%ANALYSISTYPES Return information on enabled GUI analysis methods.
% Optional inputs (tag) and (index) will request a specific piece of
% information on a given analysis method specified by the tag. Tag can also
% be a row number indexing into the standard analysistypes list. (index)
% specifies the column of analysis type to return:
%   column   contents
%    1        Tag
%    2        Label
%    3        Function name
%    4        Separator above in menu?
%
% EXAMPLE: get appropriate function name for selected algorithm
%   analysistypes(getappdata(handles.analysis,'curanal'),3)
%
%I/O: list = analysistypes;
%I/O: item = analysistypes(tag,index);
%
%See also: ANALYSIS

%Copyright Eigenvector Research 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%jms 4/1/04 initial coding

persistent list

if nargin>0 & ischar(tag) & ismember(tag,{'options' 'io' 'help'})
  %default options
  options = [];
  options.show = {};
  if nargout==0; evriio(mfilename,tag,options); else; out = evriio(mfilename,tag,options); end
  return;
end

%For some reason the persistent variable above isn't recognized in Matlab
%7.0.4 so needed to add an exist check.
if (exist('list','var') && isempty(list)) || nargin==0
  %NOTE: although newer versions of Matlab will NOT use the "separator"
  %column (because separators are determined by the Category changes), it
  %is still required to allow separating the methods in the list 
  %for older versions of Matlab. It CANNOT be removed from this list.

  options = analysistypes('options');

  %Order of columns:
  %    tag      Label     Function        separator  Category      order
  list = {
    'pca'      'PCA - Principal Component Analysis'      'pca_guifcn'      'off'  'Decomposition'  1;
    'purity'   'Purity - SIMPLISMA'                      'purity_guifcn'   'off'  'Decomposition'  1;
    'mcr'      'MCR - Multivariate Curve Resolution'     'mcr_guifcn'      'off'  'Decomposition'  1;
    'mpca'     'MPCA - Multiway PCA'                     'mpca_guifcn'     'off'  'Decomposition'  1;
    'batchmaturity'   'Batch Maturity'                   'batchmaturity_guifcn' 'off'  'Decomposition'  1;
    'tsne'     'TSNE - t-Distributed Stochastic Neighbor Embedding'   'tsne_guifcn'     'off'  'Decomposition'  1;
    'umap'     'UMAP - Uniform Manifold Approximation and Projection'   'umap_guifcn'     'off'  'Decomposition'  1;
    'cluster'  'Cluster - DCA and HCA'                   'cluster_guifcn'  'on'   'Clustering'     2;
    'pls'      'PLS - Partial Least Squares (PLS/OPLS)'  'reg_guifcn'      'on'   'Regression'     3;
    'pcr'      'PCR - Principal Component Regression'    'reg_guifcn'      'off'  'Regression'     3;
    'lwr'      'LWR - Locally Weighted Regression'       'lwr_guifcn'      'off'  'Regression'     3;
    'svm'      'SVM-R - Support Vector Regression'       'svm_guifcn'      'off'  'Regression'     3;
    'mlr'      'MLR - Multiple Linear Regression'        'reg_guifcn'      'off'  'Regression'     3;
    'cls'      'CLS - Classical Least Squares'           'cls_guifcn'      'off'  'Regression'     3;
    'clsti'    'CLSTI - CLS Temperature Interpolated'    'clsti_guifcn'    'off'  'Regression'     3;
    'ann'      'ANN - Artificial Neural Networks'        'ann_guifcn'      'off'  'Regression'     3;
    'anndl'    'ANNDL - Deep Learning Artificial Neural Networks'        'anndl_guifcn'      'off'  'Regression'     3;
    'xgb'      'XGBoost - Gradient Boosted Tree Regression'         'xgb_guifcn'      'off'  'Regression'     3;
    'plsda'    'PLSDA - PLS Discriminant Analysis'       'plsda_guifcn'    'on'   'Classification' 4;
    'svmda'    'SVM-C - Support Vector Classification'   'svm_guifcn'      'off'  'Classification' 4;
    'simca'    'SIMCA - PCA-based Classification'        'simca_guifcn'    'off'  'Classification' 4;
    'knn'      'KNN - K Nearest Neighbors'               'knn_guifcn'      'off'  'Classification' 4;
    'annda'    'ANNDA - Artificial Neural Networks Discriminant Analysis'         'ann_guifcn'      'off'  'Classification'     4;
    'anndlda'    'ANNDLDA - Deep Learning Artificial Neural Networks Discriminant Analysis'        'anndl_guifcn'      'off'  'Classification'     3;
    'xgbda'    'XGBoostDA - Gradient Boosted Tree Discriminant Analysis'         'xgb_guifcn'      'off'  'Classification'     4;
    'lregda'   'LREGDA - Logistic Regression Discriminant Analysis'        'lreg_guifcn'      'off'  'Classification'     4;
    'lda'      'LDA - Linear Discriminant Analysis'       'lda_guifcn'     'off'  'Classification'     4;
    'asca'     'ASCA - ANOVA Simultaneous Component Analysis' 'asca_guifcn' 'off' 'Statistical' 5;
    'mlsca'    'MLSCA - Multi-level Simultaneous Component Analysis' 'asca_guifcn' 'off' 'Statistical' 5;
    'parafac'  'PARAFAC - Parallel Factor Analysis'      'parafac_guifcn'  'on'  'Multi-way'  6;
    'parafac2' 'PARAFAC2 - PARAFAC for unevenly sized n-way arrays' 'parafac_guifcn'  'on'  'Multi-way'  6;
    'npls'     'Multi-way PLS (NPLS)'                    'npls_guifcn'     'off'  'Multi-way'     6;
    };

  %call add-on functions (if present)
  fnlist = evriaddon('analysistypes');
  for j=1:length(fnlist);
    list = feval(fnlist{j},list);
  end;

  if ~isempty(options.show)
    if ~iscell(options.show)
      options.show = {options.show};
    end
    if length(options.show)~=1 | ~strcmpi(options.show{1},'all')
      %if some items are listed in option "show", ONLY give those options
      list = list(ismember(list(:,1),options.show),:);
    end
  end

  %- - - -
  %We may or may not have used above code to update list (depends on if we
  %had a stored version of analysistypes list) The use of a persistent "list"
  %variable was done because the evriaddon object can be kind of slow if we
  %have to call it frequently. ANALYSISTYPES is called frequently (since
  %its input simulates a standard array) thus we don't want to call
  %evriaddon EACH TIME ANALYSISTYPES is called. The logic above will reparse
  %the list if no inputs are given or if the list is empty - such as the
  %first time the function is called. Note that this may SLIGHTLY limit the
  %ability to dynamically add items to the analysis menu, but as long as
  %the path or addon objects aren't being changed while Analysis is open,
  %this shouldn't be a problem.
  %- - - -
end

out = list;
if nargin>0
  if ismodel(tag) 
    %allows getting category of a model object
    %(regression, classification, decomposition, etc.)
    cleanedModelType = strsplit(lower(tag.modeltype), '_'); %if a pred object
    cleanedModelType = cleanedModelType{1};
    rowindex = find(ismember(out(:,1),cleanedModelType));
  elseif isa(tag,'char')
    %find tag in list, return ONLY that ELEMENT from the given row
    rowindex = find(ismember(out(:,1),lower(tag)));
  else
    %tag is probably an ROW INDEX number
    rowindex = tag;
  end
  if ~isempty(rowindex)
    %return the matching row
    switch nargin
      case 1
        out = out(rowindex,:);
      case 2
        out = out{rowindex,index};
    end
  else
    %no matching row return empty
    switch nargin
      case 1
        out = {};
      case 2
        out = '';
    end
  end
end

%-------------------------------------------------------------------
function linkwithfunctions
%placeholder function - this is just so that we'll make sure the compiler
%includes these functions when compiling

pca_guifcn
purity_guifcn
mcr_guifcn
parafac_guifcn
mpca_guifcn
cluster_guifcn
reg_guifcn
reg_guifcn
reg_guifcn
plsda_guifcn    
simca_guifcn
lwr_guifcn
svm_guifcn
xgb_guifcn
tsne_guifcn
