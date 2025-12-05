function effectsdso = plotscores_asca(model,test,options)
%PLOTSCORES_ASCA Plotscores helper function used to extract info from model.
% Creates a dataset containing the ASCA effects for each factor and
% interaction.
% PLOTSCORES_ASCA is called by PLOTSCORES.
%
% INPUTS:
%   model    = the experimental value determined for each experiment/row
%              of Y. See outputs regarding behvior when x is a matrix.
%   test     = Required to maintain function signature, but not used. [].
% %PLOTASCAEFFECTS -
%
% OPTIONAL INPUTS:
%   options  = Options structure with one or more of the following fields.
%              Options can be passed in place of column_ID.
%
%  asca_submodel : integer specifying which factor to get effects for.
%          plots : [{'none' | 'final']  governs plot creation.
%                  Plot scatter effects of an asca pca model.
%
%I/O: effectsdso = plotscores_asca(model);
%I/O: effectsdso = plotscores_asca(model, [], options);
%
%See also: ASCA, PLOTLOADS, PLOTSCORES

% Copyright © Eigenvector Research, Inc. 2014
% Licensee shall not re-compile, translate or convert "M-files" contained
%  in PLS_Toolbox for use with any software other than MATLAB®, without
%  written permission from Eigenvector Research, Inc.

[model, isubmodel, doplots, showresids] = parseinput(model,test,options);

ismlsca = strcmp(lower(model.modeltype), 'mlsca');

effectsdso = model.combinedscores;

% add scores to the projections residuals for factors and interactions
if showresids
  npcs = size(model.combinedprojected,2);
  effectsdso.data(:,1:npcs) = effectsdso.data(:,1:npcs) + model.combinedprojected.data;
end

effectsdso = copydsfields(model,effectsdso, 1, 2); % mode 1 of model's block 2
effectsdso = copydsfields(model,effectsdso, 1 ,1, true);

if ismlsca
  qs = model.combinedqs;
  effectsdso = [effectsdso, qs];
end

submodelindices = effectsdso.class{2,1};  % Assume Sub-model classset is first

if ~isempty(isubmodel)
  useindices = submodelindices==isubmodel;
  effectsdso = effectsdso(:,useindices);
  cname      = effectsdso.classname{1,isubmodel};
  theclass   = effectsdso.class{1,isubmodel};
  lookup     = effectsdso.classlookup{1,isubmodel};
  f = model.detail.data{2};
  
  % Switch row classsets to this factor's classset (except if is Residuals)
  isresiduals = isresidualssubmodel(effectsdso, model.modeltype);
  if ~isresiduals
    nclasses = max(submodelindices);
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
  
  % Instead of sorting by single factor levels make an axisscale of this
  % new sorted by factor levels index.
  if ~ismlsca & ~isresiduals
    levels = f.data(:,isubmodel);
    [ztmp,levindices]=sort(levels);
    [ztmp2, levindices2] = sort(levindices);
    useset = min(find(cellfun('isempty',effectsdso.axisscale(1,:))));
    if isempty(useset)
      useset = length(effectsdso.axisscale(1,:))+1;
    end
    effectsdso.axisscale{1,useset} = levindices2; %axisscale to keep levels together
    effectsdso.axisscalename{1,useset} = sprintf('Samples, ordered by levels of %s', cname);
  end
end

if isempty(effectsdso.name)
  effectsdso.title{1}     = 'Samples/Scores Plot';
else
  effectsdso.title{1}     = ['Samples/Scores Plot of ',effectsdso.name];
end

% plotgui
% if options.plot=='final'
if nargout==0 | doplots
  plotgui(effectsdso,'cols', 'new')
end

%--------------------------------------------------------------------------
function isresiduals = isresidualssubmodel(effectsdso, modeltype)
% Does effectsdso contain the Residuals/Within submodel?

% Find the index of the "Sub-model" column classset
cnames = effectsdso.classname(2,:);
smindex = find(not(cellfun('isempty', strfind(cnames, 'Sub-model'))));

% Are the classids = Residuals or Within?
if strcmp(lower(modeltype), 'asca')
  isresiduals = all(strcmp(effectsdso.classid{2,smindex}, 'Residuals'));
elseif strcmp(lower(modeltype), 'mlsca')
  isresiduals = all(strcmp(effectsdso.classid{2,smindex}, 'Within'));
else
  isresiduals = false;
end

%--------------------------------------------------------------------------
function [model, isubmodel, doplots, showresids] = parseinput(model,test,options)
% Process input parameters.
%             model : ASCA model
% options.isubmodel : integer identifying which ASCA submodel to plot
%                     scores and projections from.
%     options.plots : [{'none' | 'final']  governs plot creation.
%     showresiduals : [{'on'}| 'off' ] governs plotting projected residuals in scores plot.
%
%I/O: out = plotscores(model,[], options);
%I/O: out = plotscores(model);

isubmodel = [];
doplots = false;
showresids = true;
switch nargin
  case {1 2}  % 1 or 2 arg: % plotscores(model)
    % do nothing
    
  case 3 % 3 arg: % plotscores(model, [], opts)
    if isstruct(options)
      if isfield(options,'asca_submodel') & ~isempty(options.asca_submodel) & ~options.asca_submodel==0
        isubmodel = options.asca_submodel;
      elseif isfield(options,'mlsca_submodel') & ~isempty(options.mlsca_submodel) & ~options.mlsca_submodel==0
        isubmodel = options.mlsca_submodel;
      end
      if isfield(options,'plots') & ~isempty(options.plots) & ischar(options.plots)
        doplots = strcmp(options.plots, 'final');
      end
      if isfield(options,'showresiduals') & ~isempty(options.showresiduals) 
        % Use showresiduals options setting if available
        if strcmp(options.showresiduals, 'off')
        showresids = false;
        elseif strcmp(options.showresiduals, 'on')
        showresids = true;
        end
      else
        % Set showresids 'on' for ASCA, 'off' for MLSCA if not specified
        if strcmp(lower(model.modeltype), 'asca')
          showresids = true;
        elseif strcmp(lower(model.modeltype), 'mlsca')
          showresids = false;
        end
          
      end
    else
      error('%s third argument must be options struct.');
    end
    
  otherwise
    error('%s: unexpected number of arguments to function ("%s")', mfilename, nargin);
end
