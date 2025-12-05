function a = updatemod(a)
%UPDATEMOD Update model structure to be compatible with the current version.
%  The inputs are the model to be updated (modl).
%  The output is an updated model (umodl).
%
%I/O: umodl = updatemod(modl);        %update post-v2.0.1c model
%
%See also: ANALYSIS, MODELSTRUCT, PCA, PCR, PLS

%Copyright Eigenvector Research 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

%************************************************************************
%                                                                       *
%     NOTE: If modifying existing model ADD CODE TO                     *
%                                                                       *
%           @EVRIMODEL/PRIVATE/UPDATEMOD.M                              *
%                                                                       *
%           for new fields and or fields that have changed locations.   *
%           for new version number.                                     *
%                                                                       *
%           @EVRIMODEL/PRIVATE/TEMPLATE.M                               *
%                                                                       *
%           for new fields with defaults.                               *
%                                                                       *
%                                                                       *
%           @EVRIMODEL/EVRIMODEL.M                                      *
%                                                                       *
%           for new version number.                                     *
%                                                                       *
%           @EVRISCRIPT_MODULE/PRIVATE/EVRISCRIPT_CREATECONFIG.M        *
%                                                                       *
%           for new models update evriscript_config.mat.                *
%                                                                       *
%           @EVRIMODEL/GETSSQTABLE.M                                    *
%                                                                       *
%           add/verify SSQ table logic                                  *
%                                                                       *
%************************************************************************




if nargin==0; a = 'io'; end

if ischar(a)    %Help, Demo, Options
  varargin{1} = a;
  options = [];
  if nargout==0; clear a; evriio(mfilename,varargin{1},options); else; a = evriio(mfilename,varargin{1},options); end
  return; 
  
end

%NOTE: It is a known issue that old 2.11 models can't even make it into
%the update code anymore (due to testing by upper-level evrimodel
%object) but as there appear to be problems with updating pre 3.0 models,
%this is basically being ignored

if ~isfieldcheck('model.modelversion',a)
  %pre v5.0 model  
  if ~isfield(a,'detail');     %pre v3.0 model?
    error('Unrecognized/Unsupported model format');
  end

  %check for datasource "type" and "include_size" fields
  if isfield(a,'datasource')
    for j=1:length(a.datasource);
      if ~isfield(a.datasource{j},'type')
        a.datasource{j}.type = 'data';
      end
      if ~isfield(a.datasource{j},'include_size') && isfieldcheck(a,'.detail.includ') && size(a.detail.includ,2)>=j
        a.datasource{j}.include_size = cellfun('size',a.detail.includ(:,j),2);
      end
    end
  end

  %check for algorithm field in details/options of PCA-like models
  switch lower(a.modeltype)
    case 'pca'
      if ~isfieldcheck('model.detail.options.algorithm',a)
        %no algorithm
        a.detail.options.algorithm = 'svd';
      end
      if ~isfieldcheck('model.detail.options.confidencelimit',a)
        a.detail.options.confidencelimit = 0.95;
      end
    case 'simca'
      for j=1:length(a.submodel);
        if ~isfieldcheck('model.detail.options.algorithm',a.submodel(j))
          a.submodel(j).detail.options.algorithm = 'svd';
        end
      end
    case 'pcr'
      if ~isfieldcheck('model.detail.options.algorithm',a)
        %no algorithm
        a.detail.options.algorithm = 'svd';
      end

  end

  %Class lookup.
  if isfieldcheck('model.detail.class',a) & ~isfieldcheck('model.detail.classlookup',a)
    cl = cell(size(a.detail.class));
    for j=1:length(a.detail.class(:))
      if ~isempty(a.detail.class{j});
        uclass = unique(a.detail.class{j});
        lu = [num2cell(uclass)' str2cell(sprintf('Class %g\n',uclass))];
        cl{j} = lu;
      end
    end
    a.detail.classlookup = cl;
  end

  %Help information
  if ~isfieldcheck('model.help',a)
    tempmod = template(lower(a.modeltype));
    a.help = tempmod.help;
    a = addhelpyvars(a);
  end

  %Version 5.0 updates
  if ~isfieldcheck('model.modelversion',a)
    %pre 5.0 model
    a.modelversion = '5.0';

    %check for any savgol preprocessing and add "tails" preference
    switch lower(a.modeltype)
      case 'simca'
        for j=1:length(a.submodel);
          if isfieldcheck('model.detail.preprocessing',a.submodel(j))
            for submodelpp_idx=1:length(a.submodel(j).detail.preprocessing);
              a.submodel(j).detail.preprocessing{submodelpp_idx} = fixsavgol(a.submodel(j).detail.preprocessing{submodelpp_idx});
            end
          end
        end
      otherwise
        if isfieldcheck('model.detail.preprocessing',a) & iscell(a.detail.preprocessing)
          for j=1:length(a.detail.preprocessing);
            a.detail.preprocessing{j} = fixsavgol(a.detail.preprocessing{j});
          end
        end

    end
    
    if strcmpi(a.modeltype,'plsda')
      if length(a.datasource)==1
        a.datasource{2} = getdatasource([]);
      end
    end
    
  end
end

%5.0 or later changes start here
mver = nver(a.modelversion);
if mver<5.4
  %pre 5.4 model
  
  %special modification for frpcr
  if strcmpi(a.modeltype,'frpcr')
    %make FRPCR model look as much like a PCR model created with fprcr
    %algorithm as possible
    a.modeltype = 'PCR';
    ropts       = a.detail.options;
    opts        = pcr('options');
    opts.plots           = ropts.plots;
    opts.display         = ropts.display;
    opts.preprocessing   = ropts.preprocessing;
    opts.algorithm       = 'frpcr';
    opts.confidencelimit = ropts.confidencelimit;
    opts.blockdetails    = ropts.blockdetails;
    opts.frpcroptions    = ropts;
    a.detail.options = opts;  %copy into model structure
  end
  
  %add missing detail fields
  try
    temp = template(a.modeltype);
  catch
    %could not get template model, use pls as default
    temp = template('pls');
  end
  a.detail = reconopts(a.detail,temp.detail);
  
  %add content for author field
  a.author = sprintf('unknown (updated by %s)',temp.author);
  
  a.modelversion = '5.4';
end

if mver<5.5
  %pre 5.5 model
  
  if strcmpi(a.modeltype,'pls')
    if ismember(a.detail.options.algorithm,{'sim' 'nip'})
      %adjust scaling on wts field
      a.wts = a.wts*pinv(a.loads{2,1}'*a.wts);
    end
  end

  if ismember(lower(a.modeltype),{'pls' 'pcr' 'mlr' 'cls' 'plsda'})
    a.detail.rmsep = [];
  end    
  
  a.modelversion = '5.5';
end

if mver<5.51
  %pre 5.5.1 model
  if isfield(a,'datasource')
    for j=1:length(a.datasource)
      if ~isfield(a.datasource{j},'uniqueid')
        a.datasource{j}.uniqueid = sprintf('unknown (updated by %s)',userinfotag);
      end
    end
  end
  
  a.modelversion = '5.51';
end

if mver<6.5
  %pre 6.5 model
  
  %add CV fields for KNN models
  if ismember(lower(a.modeltype),{'knn' 'knn_pred'})
    a.detail.cvpred        = [];
    a.detail.cv            = '';
    a.detail.split         = [];
    a.detail.iter          = [];
  end
  
  if ismember(lower(a.modeltype),{'simca' 'simca_pred' 'npls'})
    error('This %s model is too old to be used with this version of PLS_Toolbox (critical information missing). The model must be rebuilt in the new version.',a.modeltype);
  end
  
  % update the classification fields
  if ismember(lower(a.modeltype),{'svmda', 'svmda_pred', ...
      'plsda', 'plsda_pred', 'knn', 'knn_pred'});
    if ~isfield(a.detail.options,'classset')
      a.detail.options.classset = 1;
    end
    a = multiclassifications(a);
  end
  
  if strcmpi(a.modeltype,'mlr')
    if ~isfield(a,'tsqs')
      a.tsqs = cell(2);
    end
  end
  
  a.modelversion = '6.5'; %update model number to 6.5
  
end

if mver<6.7
  % update the options.orthogonalize field
  if ismember(lower(a.modeltype),{'pls', 'pls_pred', 'plsda', 'plsda_pred'})
      if ~isfield(a.detail.options, 'orthogonalize')
      % handle old models which do not have the orthogonalize field
      a.detail.options.orthogonalize='off';
      end
  end
  
  a.modelversion = '6.7'; %update model number
end

if mver<7.01
  %add appropriate pre 7.0 fields here
  
  if strcmpi(a.modeltype,'parafac') & ~isfield(a.detail,'converged');
    %update parafac models for missing fields
    a.detail.converged = struct('isconverged',1,'message',' Model convergence information not known, but assumed to have converged.');
  end
  
  if strcmpi(a.modeltype,'npls')
    if ~isfieldcheck(a,'model.detail.ssqpred')
      a.detail.ssqpred = struct('X',[]);
    end
  end
  
  if strcmpi(a.modeltype,'simca') & ~iscell(a.submodel);
    %convert from structure array to cell array of model objects
    for j=1:length(a.submodel);
      temp{1,j} = evrimodel(a.submodel(j));
    end
    a.submodel = temp;
  end
  
  %make sure datasource length matches what is defined in template (some
  %models had too many entries)
  m = template(lower(a.modeltype));
  if isfield(a,'datasource') & length(a.datasource)>length(m.datasource)
    a.datasource = a.datasource(1:length(m.datasource));
  end
  
  %convert various embedded models into evrimodel format
  if strcmpi(a.modeltype,'svm') | strcmpi(a.modeltype,'svmda') | strcmpi(a.modeltype,'svmoc')
    %convert submodels into evrimodel format
    cm = a.detail.compressionmodel;
    if ~isempty(cm)
      a.detail.compressionmodel = evrimodel(cm);
    end
  end
  
  if strcmpi(a.modeltype,'modelselector')
    for j=1:length(a.targets)
      if ismodel(a.targets{j});
        a.targets{j} = evrimodel(a.targets{j});
      end
    end
    if ismodel(a.trigger)
      a.trigger = evrimodel(a.trigger);
    end
  end
  
  %Add originalinclude to all templated models where it appears
  tem = evrimodel(a.modeltype);
  if isfield(tem,'content')
    %extract contents to match old model type
    tem = tem.content;
  end
  if isfieldcheck(tem,'tem.detail.originalinclude') & ~isfield(a.detail,'originalinclude')
    a.detail.originalinclude = {};
  end
  %Add ___ fields to all templated models where it appears
  neededfields = {'cvi' 'dy' 'cov'};
  for fi=1:length(neededfields)
    f = neededfields{fi};
    if isfieldcheck(tem,['tem.detail.' f]) & ~isfield(a.detail,f)
      a.detail.(f) = [];
    end
  end
  
  a.modelversion = '7.0'; %update model number
  
end

if mver<7.5
  %Add .detail.dy to all templated models where it appears
  %(NOTE: this was actually added as a requirement in version 7.0 but we
  %missed adding it there)
  tem = evrimodel(a.modeltype);
  if isfield(tem,'content')
    %extract contents to match old model type
    tem = tem.content;
  end
  if isfieldcheck(tem,'tem.detail.dy')
    a.detail.dy = [];
  end
  
  if ismember(lower(a.modeltype),{'maf', 'mdf'})
    if ~isfield(a.detail, 'ploads')
      %Add new ploads field.
      a.detail.ploads=cell(2,1);
    end
    if ~isfield(a.detail, 'dinclud')
      %Add new dinclud.
      a.detail.dinclud=cell(2,1);
    end
    if isfield(a, 'tsqmtx')
      %Move field.
      a.detail.tsqmtx = a.tsqmtx;
      if strcmp(a.modeltype,'mdf')
        %Need to add 2 more cells for increase in field size.
        tsqm = a.tsqmtx;
        if size(tsqm,2)==1
          tsqm = [tsqm cell(2,1)];
        end
        a.detail.tsqmtx = tsqm;
      else
        a.detail.tsqmtx = a.tsqmtx;
      end
      a = rmfield(a,'tsqmtx');
    end
  end
  
  if strcmpi(a.modeltype,'modelselector') & ~isfield(a,'outputfilters')
    %add output filter field
    [a.outputfilters{1:length(a.targets)}] = deal('');
  end
  
  a.modelversion = '7.5.0'; %update model number
  
end

if mver<7.51
  if strcmpi(a.modeltype,'ann')
    %add CV fields to ann models
    a.detail.cv            = '';
    a.detail.split         = [];
    a.detail.iter          = [];
    a.detail.cvi           = [];
  end
  a.modelversion = '7.5.1'; %update model number
end

if mver<7.80
  if strcmpi(a.modeltype,'svm') | strcmpi(a.modeltype,'svmda') | strcmpi(a.modeltype,'svmoc')
    %add CV fields to ann models
    a.detail.cv            = '';
    a.detail.split         = [];
    a.detail.iter          = [];
    a.detail.cvi           = [];
  end
  
  if strcmpi(a.modeltype,'simca') & ~isfieldcheck(a,'model.detail.originalclass');
    %add originalclass fields to simca models
    a.detail.originalclasslookup = a.detail.classlookup;
    a.detail.originalclass       = a.detail.class;
    a.detail.originalclassname   = a.detail.classname;
  end
  
  if ismember(lower(a.modeltype),{'pls' 'plsda'}) & ~isfield(a.detail.options,'weights')
    %add "weights" and "weightsvect" options
    a.detail.options.weights = 'none';
    a.detail.options.weightsvect = [];
  end
  
  a.modelversion = '7.8.0'; %update model number
end

if mver<7.81
  if strcmpi(a.modeltype,'simca')
    %move detail originalclasslookup into new modeledclasslookup field
    a.detail.modeledclasslookup = a.detail.classlookup;
    a.detail.classlookup = a.detail.originalclasslookup;
    for fyld = {'originalclass','originalclasslookup','originalclassname'};
      if isfield(a.detail,fyld{:})
        a.detail = rmfield(a.detail,fyld{:});
      end
    end
  end
  
  a.modelversion = '7.8.1'; %update model number
end

if mver<8.0
  if strcmpi(a.modeltype,'parafac') & ~isfieldcheck(a,'a.detail.validation')
    %add splithalf field
    a.detail.validation = [];
  end

  tem = evrimodel(a.modeltype);
  if isfield(tem,'content'); tem = tem.content; end %extract content of model
  if isfieldcheck(tem,'tem.detail.r2y') & ~isfieldcheck(a,'a.detail.r2y')
    a.detail.r2y = [];
    a.detail.q2y = [];
  end
  if isfieldcheck(tem,'tem.detail.axistype') & (~isfieldcheck(a,'a.detail.axistype') | isempty(a.detail.axistype) )
    sz = size(a.detail.axisscale);
    a.detail.axistype = repmat({'none'},sz);
  end    
  if isfieldcheck(tem,'tem.detail.imageaxisscale') & ~isfieldcheck(a,'a.detail.imageaxisscale')
    a.detail.imageaxisscale     = tem.detail.imageaxisscale;
    a.detail.imageaxisscalename = tem.detail.imageaxisscalename;
  end
  
  if strcmpi(a.modeltype,'simca')
    %make sure classids is a ROW vector in SIMCA (transpose error)
    a.classification.classids = a.classification.classids(:)';
  end
  
  if ~isfieldcheck(a,'a.detail.history')
    a.detail.history = sethistory({''},'','',['=== History tracking added by ' userinfotag]);
    a.detail.history = sethistory(a.detail.history,'','',['Model Type Detected: ' a.modeltype]);
  end
  
  a.detail.history = sethistory(a.detail.history,'','','=== Upgraded to model version 8.0');  %do similar for later version updates
  a.modelversion = '8.0.0'; %update model number
end

if mver <8.2
  if strcmpi(a.modeltype,'lwrpred') | strcmpi(a.modeltype,'lwr') & ~isfieldcheck(a,'a.detail.nearestpts')
    a.detail.nearestpts =[];
  end
  
  if ismember(lower(a.modeltype),{'pca' 'mcr' 'purity' 'parafac'}) & ~isfieldcheck(a,'a.detail.componentnames')
    a.detail.componentnames = {}; %Labels for components/lvs.
  end
  if ~isfieldcheck(a,'a.userdata')
    a.userdata = [];%Generic userdata field
  end
  
  a.modelversion = '8.2.0'; %update model number
end

if mver <8.21
  if strcmpi(a.modeltype,'lwr') & ~isfieldcheck(a,'a.detail.globalmodel.xoldinclx')
    a.detail.globalmodel.xoldinclx = [];
  end
  
  a.modelversion = '8.2.1'; %update model number
end

if mver <8.22
  if ~isfieldcheck(a,'a.detail.copyparentid')
    a.copyparentid = '';%ID of parent model (used when copying). 
  end
  
  a.modelversion = '8.2.2'; %update model number
end

if mver<8.51  
  if ismember(lower(a.modeltype),{'knn' 'plsda' 'svmda' 'simca'}) & ~isfield(a.detail.options,'predictionrule')
    %add "predictionrule" option
    a.detail.options.predictionrule = 'mostprobable';
  end
  
  a.modelversion = '8.5.1'; %update model number
end

if mver<8.8
  % fix MSC preprocessing structure
  %   switch lower(a.modeltype)
  %     case 'simca'
  %       for j=1:length(a.submodel);
  %         if ~isfieldcheck('model.detail.options.preprocessing',a.submodel(j))
  %           for j=1:size(a.submodel{j}.detail.options.preprocessing);
  %             a.submodel(j).detail.options.preprocessing{j} = fixmsc(a.submodel(j).detail.options.preprocessing{j});
  %           end
  %         end
  %       end
  %     otherwise
if isfieldcheck('model.detail.options.preprocessing',a) & iscell(a.detail.options.preprocessing)
  for j=1:length(a.detail.options.preprocessing);
    a.detail.options.preprocessing{j} = fixmsc(a.detail.options.preprocessing{j});
  end
end
if isfieldcheck('model.detail.preprocessing',a) & iscell(a.detail.preprocessing)
  for j=1:length(a.detail.preprocessing);
    a.detail.preprocessing{j} = fixmsc(a.detail.preprocessing{j});
  end
end
  a.modelversion = '8.8';
end

if mver<9.0  
  if strcmpi(a.modeltype,'knn')
    %add "predictionrule" option
    a.detail.compressionmodel = [];
  end 
  a.modelversion = '9.0'; %update model number
end

if mver<9.1
  if ismember(lower(a.modeltype),{'anndl' 'anndlda'}) && strcmpi(a.detail.options.algorithm,'tensorflow')
    % serialized model is moved from model.detail.anndl.W to
    % model.detail.anndl.W.meta
    % need to move both the configuration and the weights to the
    % substructure.
    if ~isfield(a.detail.anndl.W,'meta') && isfield(a.detail.anndl.W,'config') && isfield(a.detail.anndl.W,'weights')
      % move
      a.detail.anndl.W.meta.config = a.detail.anndl.W.config;
      a.detail.anndl.W.meta.weights = a.detail.anndl.W.weights;
      % remove previous location
      a.detail.anndl.W = rmfield(a.detail.anndl.W,'config');
      a.detail.anndl.W = rmfield(a.detail.anndl.W,'weights');
    end
  end
  if strcmpi(a.modeltype,'mlr')
    %MLR update regularization optimization
    
    if a.detail.options.ridge > 0
      a.detail.options.algorithm = 'ridge';
      a.algorithm        = 'ridge';
    else
      a.detail.options.algorithm = 'leastsquares';
      a.algorithm        = 'leastsquares';
    end
    a.detail.options.optimized_ridge = [];
    a.detail.options.optimized_lasso = [];
    a.detail.mlr.best_params.optimized_ridge = [];
    a.detail.mlr.best_params.optimized_lasso = [];
    a.detail.mlr.condmax_value               = [];
    a.detail.mlr.condmax_ncomp               = [];
    a.detail.mlr.ridge_theta                 = [];
    a.detail.mlr.ridge_hkb_theta             = [];
    a.detail.mlr.optimized_ridge_theta       = [];
    a.detail.mlr.optimized_lasso_theta       = [];
  end
  a.modelversion = '9.1'; %update model number
end

if mver<9.3  
  if ismember(lower(a.modeltype),{'plsda', 'annda', 'anndlda', 'plsda_pred', 'annda_pred', 'anndlda_pred'})
    %add class Gaussian params and priors
    a.detail.distprob = [];
    a.detail.options.usegaussianparams = 'no';
  end
  if strcmpi(a.modeltype,'trendtool')
    a.detail.preprocessing = {[]};
  end
  if ismember(lower(a.modeltype),{'ann' 'ann_pred' 'annda' 'annda_pred' 'svm' 'svm_pred' 'svmda' 'svmda_pred'})
    a.detail.options.random_state = 1;
  end
  a.modelversion = '9.3'; %update model number
end

%---------------------------------------------------
function out = nver(v)
%convert string version: x.y OR x.y.z into numerical value

npoints = sum(v=='.');
if npoints>1
  r = v;
  out = 0;
  for j=1:npoints+1;
    [vp,r] = strtok(r,'.');
    out = out + str2double(vp)/(10.^(j-1));
  end
else
  out = str2double(v);
end

%-------------------------------------------------------------
function pp = fixsavgol(pp)
%FIXSAVGOL corrects preprocessing structures for new savgol call (requires
%use of option to get old tails behavior)
newcall = 'data = savgol(data,userdata(1),userdata(2),userdata(3),struct(''tails'',''traditional''));';
          
for j=1:length(pp)
  if ~isempty(findstr(pp(j).calibrate{1},'savgol')) & isempty(findstr(pp(j).calibrate{1},'polyinterp'))
    pp(j).calibrate = {newcall};
    pp(j).apply     = {newcall};    
  end
end

%-------------------------------------------------------------
function pp = fixmsc(pp)
%FIXMSC corrects MSC preprocessing structure to work with new MSC settings
%GUI
doingMSC = zeros(1,length(pp));
validList = {'msc' 'msc_median'};
for j=1:length(pp)
  if isstruct(pp(j)) && ismember(pp(j).keyword, validList)
    doingMSC(j) = 1;
  else
    doingMSC(j) = 0;
  end
end
if ~any(doingMSC)
  return
else
  inds                 = find(doingMSC);
  new_calibrate        = '[data,out{2},out{3},out{1}] = mscorr(data,userdata.xref,userdata.options);';
  new_apply            = '[data,out{2},out{3}] = mscorr(data,out{1},userdata.options);';
end
for bb = inds
  if ~isempty(strfind(pp(bb).keyword, 'median')) %using median algorithm
    new_description      = 'MSC (Median)';
    new_userdata         = struct('meancenter',1, 'mode', 2, 'window', [], 'xref', [], 'subinds', [], 'source', 'median', 'algorithm', 'median');
    new_userdata.options = struct('mc',1','specmode', 2,'win',[],'subind', [],'algorithm','median');
    pp(bb).settingsgui   = 'mscorrset';
    pp(bb).settingsonadd = 1;
    pp(bb).description   = new_description;
    pp(bb).calibrate     = {new_calibrate};
    pp(bb).apply         = {new_apply};
    pp(bb).undo          = {};
    pp(bb).userdata      = new_userdata;
  else %using least squares algorithm
    userMode             = pp(bb).userdata.mode;
    userMC               = pp(bb).userdata.meancenter;
    if userMC == 1
      new_description    = 'MSC (Mean, w/ intercept';
    else %userMC == 0
      new_description    = 'MSC (Mean';
    end
    if userMode ~= 2
      new_description    = sprintf('%s, spectral mode = %d)', new_description, userMode);
    else
      new_description    = sprintf('%s)', new_description);
    end
      
    new_userdata         = struct('meancenter',userMC, 'mode', userMode, 'window', [], 'xref', [], 'subinds', [], 'source', 'mean', 'algorithm', 'leastsquares');
    new_userdata.options = struct('mc',userMC,'specmode', userMode,'win',[],'subind', [],'algorithm','leastsquares');
    pp(bb).settingsgui   = 'mscorrset';
    pp(bb).settingsonadd = 1;
    pp(bb).description   = new_description;
    pp(bb).calibrate     = {new_calibrate};
    pp(bb).apply         = {new_apply};
    pp(bb).userdata      = new_userdata;
  end
end



