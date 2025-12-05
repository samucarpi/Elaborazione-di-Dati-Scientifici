function effectsdso = plotascaloads(varargin)
%PLOTASCALOADS - Plot loads of an asca or mlsca pca model.
%
%I/O: effectsdso = plotascaloads(model);
%I/O: effectsdso = plotascaloads(model, isubmodel);
%
%See also: ANOVADOE, ASCA, DOEGEN, DOEINTERACTIONS

% Copyright © Eigenvector Research, Inc. 2014
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

%check for evriio input
if nargin==0
  varargin = {'io'};
end
if ischar(varargin{1})
  options = [];
  if nargout==0; clear effectsdso; evriio(mfilename,varargin{1},options); else effectsdso = evriio(mfilename,varargin{1},options); end
  return;
end

[model, isubmodel] = parsevarargin(varargin);

ismlsca  = strcmp(lower(model.modeltype), 'mlsca');
isasca   = strcmp(lower(model.modeltype), 'asca');

submodelindices = model.combinedloads.class{2,1};

effectsdso = model.combinedloads;

% % labels for columns, e.g. "Sub-model 1:PC 2"
% lab = cell(nsubmods,1);
% for ii=1:nsubmods
%   lab{ii,1} = sprintf('%s:%s', loads.classid{2,1}{ii}, loads.classid{2,2}{ii});
% end
% effectsdso.label{2,1} = cell2str(lab);

if ~isempty(isubmodel)
  useindices      = submodelindices==isubmodel;
  effectsdso = effectsdso(:,useindices);
  cname = effectsdso.classname{1,isubmodel};
  theclass = effectsdso.class{1,isubmodel};
  lookup   = effectsdso.classlookup{1,isubmodel};
  
  % empty the classsets
  nclasses = size(effectsdso.classname,2);
  for ic=1:nclasses
    effectsdso.classname{1,ic} = [];
    effectsdso.class{1,ic} = [];
    effectsdso.classlookup{1, ic} = [];
  end
  
  % Re-insert the desired classset
  effectsdso.classname{1,1} = cname;
  effectsdso.class{1,1} = theclass;
  effectsdso.classlookup{1, 1} = lookup;
end

%add mean response
if isasca
  mn = model.detail.decompdata{1}(1,:)';
elseif ismlsca
  mn = model.detail.globalmean';
else
  mn = [];
end
if isempty(mn) | all(mn<eps*100)
  %basically a mean effect of zero? look for single preprocessing method of
  %autoscale or mean centering
  pp = model.detail.preprocessing{1};
  if length(pp)==1
    switch lower(pp.keyword)
      case 'autoscale'
        %autoscale - take mean and scale it for reference to factors
        mn = scale(pp.out{1},pp.out{2}.*0,pp.out{2})';
      case 'mean center'
        %mean centering - just take mean as-is
        mn = pp.out{1}';
    end
  else
    mn = [];
  end
end
if ~isempty(mn)
  temp = nan(size(effectsdso,1),1);
  temp(effectsdso.include{1}) = mn;
  effectsdso = [effectsdso temp];
  effectsdso.label{2,1}{size(effectsdso,2)} = 'Mean Response (m)';
end

%copy over axisscales and other info
effectsdso = copydsfields(model,effectsdso,{2 1},1);
if isempty(effectsdso.axisscale{1,1})
  effectsdso.axisscale{1,1} = 1:size(effectsdso.data,1);
end
if isempty(effectsdso.axisscalename{1,1})
  effectsdso.axisscalename{1,1} = 'Variable';
end

if isempty(effectsdso.name)
  effectsdso.title{1}     = 'Variables/Loadings Plot';
else
  effectsdso.title{1}     = ['Variables/Loadings Plot of ',effectsdso.name];
end

% plotgui
if nargout==0
  plotgui(effectsdso,'cols', 'new')
end

%--------------------------------------------------------------------------
function [model, isubmodel] = parsevarargin(varargin)
% USE
%I/O: out = plotascaloads(model, isubmodel);
%I/O: out = plotascaloads(model);
%
%     model = ASCA model
% isubmodel = integer identifying which ASCA submodel to plot loads

varargin = varargin{1};
nargin = length(varargin);
if nargin >2
  error('%s accepts 2 input arguments at most', upper(mfilename))
end

switch nargin
  case 1  % 1 arg:
    % plotloads(model)
    model = varargin{1};
    isubmodel = [];
    
  case 2 % 2 arg:
    % plotloads(model, isubmodel)
    model     = varargin{1};
    if isnumeric(varargin{2})
      isubmodel = varargin{2};
    else
      error('%s second argument must be integer.');
    end
    
  otherwise
    error('%s: unexpected number of arguments to function ("%s")', mfilename, nargin);
end
