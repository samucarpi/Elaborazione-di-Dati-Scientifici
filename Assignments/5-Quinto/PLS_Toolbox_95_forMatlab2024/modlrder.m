function varargout = modlrder(modl)
%MODLRDER Displays model info for standard model structures.
%  MODLRDER prints model information for models created by the
%  PLS_Toolbox functions:
%    DECOMPOSE, NPLS, PARAFAC, PCA, PCR, PLS, REGRESSION
%  Information printed to the screen includes date and time created,
%  and methods used to construct the model. Input to the function is
%  the model in structure form (modl).
%  There is no output.
%
%I/O: modlrder(modl);
%
%See also: ANALYSIS, MODLPRED, NPLS, PARAFAC, PCA, PCR, PLS, REGCON, REPORTWRITER, SSQTABLE

%Copyright © Eigenvector Research, Inc. 1998
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%nbg
%jms fixed spelling error
%jms 3/24/03 number of components in model from LOADS not SCORES
%rsk 01/14/2004 add RMS values if present.
%jms 03/26/04 -updated time format
%jms 8/05 -added formal PLSDA section

if nargin == 0; modl = 'io'; end
varargin{1} = modl;
if ischar(varargin{1});
  options = [];
  if nargout==0; evriio(mfilename,varargin{1},options); else; varargout{1} = evriio(mfilename,varargin{1},options); end
  return;
end

try
  modl = updatemod(modl);
catch
  error('Unrecognized model format');
end


txt = cell(0);
txt{1} = (' ');
trigger = upper(modl.modeltype);
trigger = strrep(trigger,'_PRED','');
if isempty(trigger)
  %empty model type
  trigger = 'EMPTY';
  txt = appnd(txt,('Undefined Empty Model'));
else
  %not empty, check for other special cases
  if isa(modl,'evrimodel') & ~modl.iscalibrated
    %uncalibrated EVRIModel object? just give basic info
    txt = appnd(txt,sprintf('Uncalibrated %s model',trigger));
    trigger = 'EMPTY';
  end
end

switch trigger
  case 'EMPTY'
    %do nothing
  case 'PCA'
    txt = appnd(txt,('Principal Components Analysis Model'));
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    txt = appnd(txt,dispxblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,1),modl.detail.axisscale(1:2,1)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{1}));
    txt = appnd(txt,(['Num. PCs: ' num2str(size(modl.loads{2,1},2))]));
    txt = appnd(txt,(['Algorithm: ' upper(modl.detail.options.algorithm)]));
    txt = appnd(txt,dispcv(modl.detail.cv,modl.detail.split,modl.detail.iter));
  case 'SIMCA'
    txt = appnd(txt,('SIMCA Model'));
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    txt = appnd(txt,disprawblock('X-block',modl,1,modl.datasource{1}.include_size));
    txt = appnd(txt,dispprepro(modl.detail.options.preprocessing{1}));
    txt = appnd(txt,(['Number of Classes: ' num2str(length(modl.submodel))]));
  case {'PLS' 'PLS_PRED'}
    txt = appnd(txt,dispreg(upper(modl.detail.options.algorithm)));
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    txt = appnd(txt,dispxblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,1),modl.detail.axisscale(1:2,1)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{1}));
    txt = appnd(txt,dispyblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,2),modl.detail.axisscale(1:2,2)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{2}));
    txt = appnd(txt,(['Num. LVs: ' num2str(size(modl.loads{2,1},2))]));
    if ~isempty(modl.detail.options.weights) & ~strcmpi(modl.detail.options.weights,'none')
      if ischar(modl.detail.options.weights)
        txt = appnd(txt,['Sample Weighting: ' modl.detail.options.weights]);
      end
    end
    txt = appnd(txt,dispcv(modl.detail.cv,modl.detail.split,modl.detail.iter));
  case 'PLSDA'
    txt = appnd(txt,(['This is a model of type: ' modl.modeltype]));
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    txt = appnd(txt,dispxblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,1),modl.detail.axisscale(1:2,1)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{1}));
    txt = appnd(txt,dispyblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,2),modl.detail.axisscale(1:2,2)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{2}));
    txt = appnd(txt,(['Num. LVs: ' num2str(size(modl.loads{2,1},2))]));
    if ~isempty(modl.detail.options.weights) & ~strcmpi(modl.detail.options.weights,'none')
      if ischar(modl.detail.options.weights)
        txt = appnd(txt,['Sample Weighting: ' modl.detail.options.weights]);
      end
    end
    txt = appnd(txt,dispcv(modl.detail.cv,modl.detail.split,modl.detail.iter));
  case 'PCR'
    txt = appnd(txt,dispreg(upper(modl.detail.options.algorithm)));
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    txt = appnd(txt,dispxblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,1),modl.detail.axisscale(1:2,1)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{1}));
    txt = appnd(txt,dispyblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,2),modl.detail.axisscale(1:2,2)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{2}));
    txt = appnd(txt,(['Num. PCs: ' num2str(size(modl.loads{2,1},2))]));
    txt = appnd(txt,dispcv(modl.detail.cv,modl.detail.split,modl.detail.iter));
  case 'LWR'
    txt = appnd(txt,'Locally Weighted Regression model using');
    if isfieldcheck(modl,'modl.detail.options.algorithm')
      switch lower(modl.detail.options.algorithm)
        case 'globalpcr'
          txt = appnd(txt,['the ' upper(modl.detail.options.algorithm) ' algorithm']);
        case {'pcr' 'pls'}
          txt = appnd(txt,['the ' upper(modl.detail.options.algorithm) ' (LOCAL ' upper(modl.detail.options.algorithm) ') algorithm']);
      end
      reglvs = modl.detail.options.reglvs;
      empty = false;
    else
      %no details - not calibrated yet
      empty = true;
      reglvs = [];
    end
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    txt = appnd(txt,dispxblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,1),modl.detail.axisscale(1:2,1)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{1}));
    txt = appnd(txt,dispyblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,2),modl.detail.axisscale(1:2,2)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{2}));
    npcs = size(modl.loads{2,1},2);
    if isempty(reglvs); reglvs = npcs; end
    txt = appnd(txt,(['Num. Global PCs: ' num2str(npcs)]));
    txt = appnd(txt,(['Num. Local Points: ' num2str(modl.detail.npts)]));
    if ~empty & ~strcmpi(modl.detail.options.algorithm,'globalpcr')
      txt = appnd(txt,(['Num. Local LVs: ' num2str(reglvs)]));
    end
    txt = appnd(txt,dispcv(modl.detail.cv,modl.detail.split,modl.detail.iter));
  case {'ANN', 'ANN_PRED', 'ANNDA'}
    txt = appnd(txt,'Artificial Neural Network Regression model using');
    if isfieldcheck(modl,'modl.detail.options.algorithm')
      switch lower(modl.detail.options.algorithm)
        case 'bpn'
          txt = appnd(txt,['the ' upper(modl.detail.options.algorithm) ' algorithm']);
        case 'encog'
          txt = appnd(txt,['the ' upper(modl.detail.options.algorithm) ' (LOCAL ' upper(modl.detail.options.algorithm) ') algorithm']);
      end
    else
      %no details - not calibrated yet
    end
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    txt = appnd(txt,dispxblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,1),modl.detail.axisscale(1:2,1)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{1}));
    txt = appnd(txt,dispyblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,2),modl.detail.axisscale(1:2,2)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{2}));
    if isfieldcheck(modl,'model.detail.compressionmodel') & ~isempty(modl.detail.compressionmodel) & ismodel(modl.detail.compressionmodel)
      cm = modl.detail.compressionmodel;
      txt = appnd(txt, (sprintf('X-block Compression: %s with %i component(s)',cm.modeltype,cm.ncomp)));
    end

    npcs = modl.detail.options.nhid1;
    txt = appnd(txt,(['Layer 1 Nodes : ' num2str(npcs)]));
    txt = appnd(txt,(['Layer 2 Nodes : ' num2str(modl.detail.options.nhid2)]));

  case 'PARAFAC'
    txt = appnd(txt,('PARAFAC model'));
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    txt = appnd(txt,disprawblock('X-block',modl,1,modl.datasource{1}.include_size));
    txt = appnd(txt,(['Decomposed using ',num2str(size(modl.loads{2,1},2)),' factors']));
    txt = appnd(txt,['Sum Square Residuals: Total: ',num2str(modl.detail.ssq.total),' Percent: ',num2str(modl.detail.ssq.perc),' Residual: ',num2str(modl.detail.ssq.residual)]);
    const = modl.detail.options.constraints;
    le = lasterror;
    try
      %attempt to encode constraints
      for m=1:length(const);
        txt = appnd(txt,sprintf('Mode %i Constraints: %s',m,const{m}.type));
      end
    catch
      lasterror(le)
    end
    %     %add any warnings
    %     msg = reviewmodel(modl);
    %     for m=1:length(msg)
    %       item = msg(m).issue;
    %       txt = appnd(txt,sprintf('%s',item));
    %     end
  case 'TLD'
    txt = appnd(txt,('Trilinear Decomposition model'));
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    txt = appnd(txt,disprawblock('X-block',modl,1,modl.datasource{1}.include_size));
    
  case {'SVM' 'SVM_PRED' 'SVMDA' 'SVMDA_PRED', 'SVMOC'}
    txt = appnd(txt,(['This is a model of type: ' modl.modeltype]));
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    label = {'X-Block','Y-Block'};
    
    for ind = 1:length(modl.datasource);
      if strcmp(trigger, 'SVMOC') & ind>1
        break;
      end
      if length(modl.datasource)<3;
        if ind == 1; label = 'X-block'; end
        if ind == 2; label = 'Y-block'; end
      else
        label = ['Block #' num2str(ind)];
      end
      txt = appnd(txt,dispblock(label,modl,ind));
      txt = appnd(txt,inclranges(modl.detail.includ(1:2,ind),modl.detail.axisscale(1:2,ind)));
      if isfieldcheck(modl,'modl.detail.preprocessing')
        txt = appnd(txt,dispprepro(modl.detail.preprocessing{ind}));
      end
    end
    if isfieldcheck(modl,'model.detail.compressionmodel') & ~isempty(modl.detail.compressionmodel) & ismodel(modl.detail.compressionmodel)
      cm = modl.detail.compressionmodel;
      txt = appnd(txt, (sprintf('X-block Compression: %s with %i component(s)',cm.modeltype,cm.ncomp)));
    end
    if isfieldcheck(modl,'model.detail.svm.model.param');
      txt = appnd(txt, (['SVM type: ' svmutility('getSvmTypeName',modl.detail.svm.model.param)]));
      txt = appnd(txt, (['SVM kernel type: ' svmutility('getSvmKernelName',modl.detail.svm.model.param)]));  % num2str(modl.detail.svm.model.param.kernel_type)]));
      
      if ~isempty(modl.detail.svm.cvscan)
        txt = appnd(txt, ('SVM optimal parameters: '));
        if ~isempty(modl.detail.svm.cvscan.best)
          svmparams = svmutility('convertToSvmStringNames',modl.detail.svm.cvscan.best);
          svmparamnames = fieldnames(svmparams);
          for ind = 1:length(svmparamnames)
            txt = appnd(txt, ['    ' cell2str(svmparamnames(ind)) ' = ' num2str(svmparams.(cell2str(svmparamnames(ind))))]);
          end
        end
      else
        txt = appnd(txt, ('SVM parameters: '));
        if ~isempty(modl.detail.svm.paramsused)
          svmparams = svmutility('convertToSvmStringNames', modl.detail.svm.paramsused);
          svmparamnames = fieldnames(svmparams);
          for ind = 1:length(svmparamnames)
            txt = appnd(txt, ['    ' cell2str(svmparamnames(ind)) ' = ' num2str(svmparams.(cell2str(svmparamnames(ind))))]);
          end
        end
      end
      txt = appnd(txt,(['SVM: number of SVs: ' num2str(modl.detail.svm.model.l)]));
    end
    if isfieldcheck(modl,'modl.detail.cv')
      txt = appnd(txt,dispcv(modl.detail.cv,modl.detail.split,modl.detail.iter));
    end

  case {'XGB' 'XGB_PRED' 'XGBDA' 'XGBDA_PRED'}
    txt = appnd(txt,(['This is a model of type: ' modl.modeltype]));
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    label = {'X-Block','Y-Block'};
    
    for ind = 1:length(modl.datasource);
      if length(modl.datasource)<3;
        if ind == 1; label = 'X-block'; end
        if ind == 2; label = 'Y-block'; end
      else
        label = ['Block #' num2str(ind)];
      end
      txt = appnd(txt,dispblock(label,modl,ind));
      txt = appnd(txt,inclranges(modl.detail.includ(1:2,ind),modl.detail.axisscale(1:2,ind)));
      if isfieldcheck(modl,'modl.detail.preprocessing')
        txt = appnd(txt,dispprepro(modl.detail.preprocessing{ind}));
      end
    end
    if isfieldcheck(modl,'model.detail.compressionmodel') & ~isempty(modl.detail.compressionmodel) & ismodel(modl.detail.compressionmodel)
      cm = modl.detail.compressionmodel;
      txt = appnd(txt, (sprintf('X-block Compression: %s with %i component(s)',cm.modeltype,cm.ncomp)));
    end
    
    if isfieldcheck(modl,'model.detail.xgb.model');
      if ~isempty(modl.detail.options)
        txt = appnd(txt, ('XGB: '));
        xgbparams = modl.detail.options;
        xgbparamnames = fieldnames(xgbparams);
        showparams = intersect(xgbparamnames, {'algorithm', 'booster', 'objective', 'eval_metric'});
        for ind = 1:length(showparams)
          txt = appnd(txt, ['    ' cell2str(showparams(ind)) ' = ' num2str(xgbparams.(cell2str(showparams(ind))))]);
        end
      end
      
      if ~isempty(modl.detail.xgb.cvscan)
        if ~isempty(modl.detail.xgb.cvscan.best)
          xgbparams = modl.detail.xgb.cvscan.best;
          xgbparamnames = fieldnames(xgbparams);
          for ind = 1:length(xgbparamnames)
            txt = appnd(txt, ['    ' cell2str(xgbparamnames(ind)) ' = ' num2str(xgbparams.(cell2str(xgbparamnames(ind))))]);
          end
        end
      elseif ~isempty(modl.detail.options)
        xgbparams = modl.detail.options;
        xgbparamnames = fieldnames(xgbparams);
        showparams = intersect(xgbparamnames, {'eta', 'max_depth', 'num_round'});
        for ind = 1:length(showparams)
          txt = appnd(txt, ['    ' cell2str(showparams(ind)) ' = ' num2str(xgbparams.(cell2str(showparams(ind))))]);
        end
      end
      
      % xgb/xgbda encodes the CV specification as mode custom ('user').
      % Recover the more interpretable, original specification.
      if isfieldcheck(modl,'modl.detail.cv')
        if strcmp('user', modl.detail.cv) & isnumeric(modl.detail.options.cvi) & isfield(modl.detail.options, 'cvi_orig')
          cv0 = modl.detail.options.cvi_orig{1};
          split0 = modl.detail.options.cvi_orig{2};
          if ~isempty(modl.detail.options.cvi_orig{3})
            iter0 = modl.detail.options.cvi_orig{3};
          else
            iter0 = 1;
          end
          txt = appnd(txt,dispcv(cv0, split0, iter0));
        else
          txt = appnd(txt,dispcv(modl.detail.cv,modl.detail.split,modl.detail.iter));
        end
      end
    end
    
  case 'MCR'
    txt = appnd(txt,(['This is a model of type: ' modl.modeltype]));
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    txt = appnd(txt,dispxblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,1),modl.detail.axisscale(1:2,1)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{1}));
    if length(modl.datasource)>1;
      txt = appnd(txt,dispyblock(modl));
      txt = appnd(txt,inclranges(modl.detail.includ(1:2,2),modl.detail.axisscale(1:2,2)));
      txt = appnd(txt,dispprepro(modl.detail.preprocessing{2}));
    end
    txt = appnd(txt,(['Num. Components: ' num2str(modl.ncomp)]));
    alsopts = modl.detail.options.alsoptions;
    txt = appnd(txt,sprintf('Contributions Non-negativity: %s',alsopts.ccon));
    txt = appnd(txt,sprintf('Spectral Non-negativity: %s',alsopts.scon));
    if ~isempty(alsopts.closure)
      if numel(alsopts.closure)==1  & alsopts.closure
        alsopts.closure = [1:modl.ncomp];
      end
      txt = appnd(txt,['Closure: ' sprintf('%i',alsopts.closure(1)) sprintf(',%i',alsopts.closure(2:end))]);
    end
    if isfieldcheck(alsopts,'alsopts.contrast') & ischar(alsopts.contrast) & ~isempty(alsopts.contrast)
      switch lower(alsopts.contrast)
        case {'c' 'contributions'}
          txt = appnd(txt,('Contrast Constraint: Contributions'));
        case {'s' 'spectra'}
          txt = appnd(txt,('Contrast Constraint: Spectra'));
      end
    end
    
  case 'CALTRANSFER'
    txt = appnd(txt,(['This is a model of type: ' modl.modeltype]));
    switch modl.transfermethod
      case 'ds'
        mth = 'Direct Standardization (DS)';
        addinfo = {};
      case 'pds'
        mth = 'Piecewise Direct Standardization (PDS)';
        addinfo = {sprintf('Window Size: %i',modl.detail.options.pds.win)};
      case 'dwpds'
        mth = 'Double-Window Piecewise Direct Standardization (DWPDS)';
        addinfo = {sprintf('Window Sizes: %i %i',modl.detail.options.dwpds.win)};
      case 'glsw'
        mth = 'Generalized Least Squares Weighting (GLSW)';
        addinfo = {sprintf('Signular Value Scale: %g',modl.detail.options.glsw.a)};
      case 'alignmat'
        mth = 'Matrix Alignment (ALIGNMENT)';
        addinfo = {sprintf('Components: %i',modl.detail.options.alignmat.ncomp)};
      case 'osc'
        mth = 'Orthgonal Signal Correction (OSC)';
        addinfo = {
          sprintf('Components: %i',modl.detail.options.osc.ncomp) ...
          sprintf('Iterations: %i',modl.detail.options.osc.iter) ...
          sprintf('Tolerance: %g',modl.detail.options.osc.tol) ...
          };
      otherwise
        mth = upper(modl.transfermethod);
        addinfo = {};
    end
    txt = appnd(txt,['Transfer method: ' mth]);
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    txt = appnd(txt,dispxblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,1),modl.detail.axisscale(1:2,1)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{1}));
    txt = appnd(txt,dispyblock(modl));
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,2),modl.detail.axisscale(1:2,2)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{2}));
    for ai = 1:length(addinfo);
      txt = appnd(txt,addinfo{ai});
    end
    
  case {'ASCA' 'MLSCA'}
    isasca = strcmp(lower(modl.modeltype), 'asca');
    txt = appnd(txt,(['This is a model of type: ' modl.modeltype]));
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    label = {'X-Block','Y-Block'};
    for ind = 1:length(modl.datasource);
      if length(modl.datasource)<3;
        if ind == 1; label = 'X-block'; end
        if ind == 2; label = 'Y-block'; end
      else
        label = ['Block #' num2str(ind)];
      end
      txt = appnd(txt,dispblock(label,modl,ind));
      txt = appnd(txt,inclranges(modl.detail.includ(1:min(end,length(modl.datasource{ind}.size)),ind),modl.detail.axisscale(1:min(end,length(modl.datasource{ind}.size)),ind)));
      if ind==1
        % Do not report y-block preprocessing since it is not used.
        txt = appnd(txt,dispprepro(modl.detail.preprocessing{ind}));
      end
    end
    if isasca
      if ~isempty(modl.detail.pvalues)
        numdec = -floor(log10(1/modl.detail.options.npermutations));
        txt = appnd(txt,(['Permutation p-values : ' sprintf(['%0.' num2str(numdec) 'f  '],modl.detail.pvalues)]));
      end
    end
    
    % Model Effects
    if ~isempty(modl.detail.effects)
      if ~isempty(modl.detail.effectnames)
        npcs = zeros(1,length(modl.submodel)); % Number of sub-models
        for isub=1:length(modl.submodel)
          npcs(isub) = size(modl.submodel{isub}.loads{1},2);
        end
        c1 = [{'Model Effect'}; modl.detail.effectnames];
        c2 = [{'Effect (%)'} num2cell(modl.detail.effects)]';
        if isasca
          c3 = [{'Num. PCs'} num2cell([0 npcs])]';
          txt0 = 'Effects Table for ASCA Model:';
        else
          c3 = [{'Num. PCs'} num2cell([0 npcs])]';
          txt0 = 'Effects Table for MLSCA Model:';
        end
        summary = [c1 c2 c3]';
        mlen = max(cellfun('length',c1))+3;
        dashes = cellfun(@(s) char(s*0+'-'),summary(:,1),'uniformoutput',false);
        txt1 = sprintf(['% ' num2str(mlen) 's          % 11s  % 15s'],summary{:,1});
        txt2 = sprintf(['% ' num2str(mlen) 's          % 11s  % 15s'],dashes{:});
        txt = appnd(txt, txt0);
        txt = appnd(txt, txt1);
        txt = appnd(txt, txt2);
        for itmp = 2:size(summary,2)
          % Need to do these individually so it appears as multiple lines
          % when viewed from Analysis gui.
          txttmp = sprintf(['% ' num2str(mlen) 's  % 15.1f%%  % 15i'],summary{:,itmp});
          txt = appnd(txt, txttmp);
        end
      else
        txt = appnd(txt, (['Effects : ' sprintf('%4.2f  ',modl.detail.effects)]) );
      end

      if isasca
        if isfieldcheck(modl.detail.anovadoe, '.table') & ~isempty(modl.detail.anovadoe.table)
          txt = appnd(txt, modl.detail.anovadoe.table);
        end
      end
    end
    
  case 'UMAP'
    txt = appnd(txt,(['This is a model of type: ' modl.modeltype]));
    use = modl.detail.umap.supervised;
    switch use
      case 0
        txt = appnd(txt,('Unsupervised Uniform Manifold Approximation and Projection Model'));
      case 1
        txt = appnd(txt,('Supervised Uniform Manifold Approximation and Projection Model'));
      otherwise
        txt = appnd(txt,('Uniform Manifold Approximation and Projection Model'));
    end
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    txt = appnd(txt,dispxblock(modl));
    if use==1
      txt = appnd(txt,dispyblock(modl));
    end
    txt = appnd(txt,inclranges(modl.detail.includ(1:2,1),modl.detail.axisscale(1:2,1)));
    txt = appnd(txt,dispprepro(modl.detail.preprocessing{1}));
    if use==1
      txt = appnd(txt,dispprepro(modl.detail.preprocessing{2}));
    end
    txt = appnd(txt,(['Num. Components: ' num2str(modl.detail.options.n_components)]));
    if ~strcmpi(modl.detail.options.compression, 'none')
      txt = appnd(txt,(['Compression prior to UMAP: ' num2str(modl.detail.options.compression) ' w/ ' num2str(modl.detail.options.compressncomp) ' components']));
    end
    
    case 'TSNE'
      txt = appnd(txt,(['This is a model of type: ' modl.modeltype]));
      txt = appnd(txt,('t-Distributed Stochastic Neighbor Embedding Model'));
      txt = appnd(txt,disptime(modl.date,modl.time));
      txt = appnd(txt,dispauthor(modl));
      txt = appnd(txt,dispxblock(modl));
      txt = appnd(txt,inclranges(modl.detail.includ(1:2,1),modl.detail.axisscale(1:2,1)));
      txt = appnd(txt,dispprepro(modl.detail.preprocessing{1}));
      txt = appnd(txt,(['Num. Components: ' num2str(modl.detail.options.n_components)]));
      if ~strcmpi(modl.detail.options.compression, 'none')
        txt = appnd(txt,(['Compression prior to TSNE: ' num2str(modl.detail.options.compression) ' w/ ' num2str(modl.detail.options.compressncomp) ' components']));
      end
      txt = appnd(txt, ['KL Divergence: ' num2str(modl.detail.tsne.distance_metrics.kl_divergence)]);

  case {'MLR' 'MLR_PRED'}
    txt = appnd(txt,(['This is a model of type: ' modl.modeltype]));
    txt = appnd(txt,disptime(modl.date,modl.time));
    txt = appnd(txt,dispauthor(modl));
    label = {'X-Block','Y-Block'};
    
    for ind = 1:length(modl.datasource)
      if length(modl.datasource)<3;
        if ind == 1; label = 'X-block'; end
        if ind == 2; label = 'Y-block'; end
      else
        label = ['Block #' num2str(ind)];
      end
      txt = appnd(txt,dispblock(label,modl,ind));
      txt = appnd(txt,inclranges(modl.detail.includ(1:2,ind),modl.detail.axisscale(1:2,ind)));
      if isfieldcheck(modl,'modl.detail.preprocessing')
        txt = appnd(txt,dispprepro(modl.detail.preprocessing{ind}));
      end
    end

    if isfield(modl.detail.options,'algorithm')
      if ~strcmpi(modl.detail.options.algorithm,'leastsquares') && (~isempty(modl.detail.mlr.best_params.optimized_ridge) || ~isempty(modl.detail.mlr.best_params.optimized_lasso))
        txt = appnd(txt, ['MLR regularization : ' upper(modl.detail.options.algorithm)]);
        txt = appnd(txt, 'MLR Optimal Parameters:');
        fnames = fieldnames(modl.detail.mlr.best_params);
        for i=1:length(fnames)
          if ~isempty(modl.detail.mlr.best_params.(fnames{i}))
            txt = appnd(txt, sprintf('\t\t %s = %d',upper(fnames{i}),modl.detail.mlr.best_params.(fnames{i})));
          end
        end
      end
    end
    


    if isfieldcheck(modl,'modl.detail.cv')
      txt = appnd(txt,dispcv(modl.detail.cv,modl.detail.split,modl.detail.iter));
    end
    
  case {'CLSTI' 'CLSTI_PRED'}
    txt = appnd(txt,(['This is a model of type: ' modl.modeltype]));
    if isfieldcheck(modl,'modl.detail.options.algorithm')
      txt = appnd(txt,sprintf('Using the %s algorithm',upper(modl.detail.options.algorithm)));
    end
    if isfield(modl,'date') & isfield(modl,'time')
      txt = appnd(txt,disptime(modl.date,modl.time));
    end
    txt = appnd(txt,dispauthor(modl));
    numOfComponents = length(modl.detail.clsti.refData);
    txt = appnd(txt,(['Num. Components: ' num2str(numOfComponents)]));
    txt = appnd(txt,(['Name of Components: ' modl.detail.clsti.componentNames;]));



    if isfield(modl,'datasource')
     
      if isfieldcheck(modl,'modl.detail.includ')
        for ind = 1:length(modl.datasource)
          t = inclranges(modl.detail.includ(1:min(end,length(modl.datasource{ind}.size)),ind),modl.detail.axisscale(1:min(end,length(modl.datasource{ind}.size)),ind));
          txt = appnd(txt,t);
        end
      end
      
    end
    

  otherwise
    txt = appnd(txt,(['This is a model of type: ' modl.modeltype]));
    if isfieldcheck(modl,'modl.detail.options.algorithm')
      txt = appnd(txt,sprintf('Using the %s algorithm',upper(modl.detail.options.algorithm)));
    end
    if isfield(modl,'date') & isfield(modl,'time')
      txt = appnd(txt,disptime(modl.date,modl.time));
    end
    txt = appnd(txt,dispauthor(modl));
    label = {'X-Block','Y-Block'};
    if isfield(modl,'datasource')
      for ind = 1:length(modl.datasource);
        if length(modl.datasource)<3;
          if ind == 1; label = 'X-block'; end
          if ind == 2; label = 'Y-block'; end
        else
          label = ['Block #' num2str(ind)];
        end
        txt = appnd(txt,dispblock(label,modl,ind));
        if isfieldcheck(modl,'modl.detail.includ') & size(modl.detail.includ,2)>=ind
          txt = appnd(txt,inclranges(modl.detail.includ(1:min(end,length(modl.datasource{ind}.size)),ind),modl.detail.axisscale(1:min(end,length(modl.datasource{ind}.size)),ind)));
        end
        if isfieldcheck(modl,'modl.detail.preprocessing') & size(modl.detail.preprocessing,2)>=ind
          txt = appnd(txt,dispprepro(modl.detail.preprocessing{ind}));
        end
      end
    end
    if isfield(modl,'loads') & iscell(modl.loads) & size(modl.loads,1)>1
      szlds = size(modl.loads{2,1});
      txt = appnd(txt,(['Num. Components: ' num2str(szlds(end))]));
    end
    if isfieldcheck(modl,'modl.detail.cv') & isfieldcheck(modl,'modl.detail.split') & isfieldcheck(modl,'modl.detail.iter')
      txt = appnd(txt,dispcv(modl.detail.cv,modl.detail.split,modl.detail.iter));
    end    
end

if ~strcmpi(trigger,'empty')
  if ismember(lower(modl.modeltype),{'cls'})
    nlvs = 1;
  elseif ismember(lower(modl.modeltype), {'ann' 'ann_pred' 'annda' 'annda_pred'})
    nlvs = npcs;
  elseif ismember(lower(modl.modeltype), {'knn' 'knn_pred'})
    nlvs = modl.k;
  elseif ismember(lower(modl.modeltype), {'anndl' 'anndl_pred' 'anndlda' 'anndlda_pred'})
    nlvs = getanndlnhidone(modl);
  elseif isfieldcheck('modl.loads', modl)== 1
    %nlvs = number of latent variables (components).
    nlvs = size(modl.loads{2,1},2);
  else
    nlvs = 1;
  end
  nlvs = max(1,nlvs);
  
  given_ycol_notice = false;
  ycol_notice = {' ' 'Statistics for each y-block column:'};
  given_ystats = false;
  if strcmpi(modl.modeltype,'PLSDA');
    ycol_notice = [ycol_notice {['Modeled Class: ' sprintf('%i   ',modl.detail.class{2,2})]}];
  end
  
  %Add sensitivity/specificity values if present (PLSDA)
  rmsLabel = {' (Cal)', ' (CV)', ' (Pred)'};
  rmsField = {'misclassedc',  'misclassedcv', 'misclassedp'};
  
  for i = 1 : length(rmsField)
    %Test for, then assign appropriate rms value.
    if isfieldcheck(['modl.detail.' rmsField{i}], modl)
      if ~isempty(getfield(modl.detail,rmsField{i}))
        
        misc = getfield(modl.detail,rmsField{i});
        
        if ~given_ycol_notice
          txt = appnd(txt,ycol_notice);
          given_ycol_notice = true;
        end
        
        sens = '';
        spec = '';
        cerr = '';
        for j = 1:length(misc);
          %get one y column entry
          rmsf1 = misc{j};
          
          %Use nlvs to select correct value.
          if size(rmsf1,2)>1
            rmsf1 = rmsf1(:,nlvs);
          end
          %convert to sens/spec
          rmsf1 = 1-rmsf1;
          
          %Construct output string.
          spec = [spec sprintf('% 3.3f ',rmsf1(1))];
          sens = [sens sprintf('% 3.3f ',rmsf1(2))];
          cerr = [cerr sprintf('% 3.3f ', 1-mean(rmsf1))];
          
        end
        txt = appnd(txt,['Sensitivity' rmsLabel{i} ': ' sens]);
        txt = appnd(txt,['Specificity' rmsLabel{i} ': ' spec]);
        % Write out Class Err only for SVMDA and XGBDA
        if (strncmpi(modl.modeltype, 'SVMDA', 5) | strncmpi(modl.modeltype, 'XGBDA', 5)) 
          txt = appnd(txt,['Class. Err.' rmsLabel{i} ': ' cerr]);
        end
      end
    end
  end

  
  %Add rms values if present.
  rmsLabel = {'Class. Err (Cal): ', 'Class. Err (CV): ', 'Class. Err (Pred): ', 'RMSEC: ', 'RMSECV: ', 'RMSEP: ', 'Bias: ', 'CV Bias: ', 'Pred Bias:', 'R^2 Cal: ', 'R^2 CV: ', 'R^2 Pred: ' };
  rmsField = {'classerrc',  'classerrcv', 'classerrp', 'rmsec',   'rmsecv',   'rmsep', 'bias', 'cvbias', 'predbias', 'r2c', 'r2cv', 'r2p' };
  % Important to only reset rmsLabel/rmsField for SVMDA and XGBDA, as these are written out above
  if (strncmpi(modl.modeltype, 'SVMDA', 5) | strncmpi(modl.modeltype, 'XGBDA', 5))  
    rmsLabel = {};
    rmsField = {};
  end
  
  for i = 1 : length(rmsLabel)
    %Test for, then assign appropriate rms value.
    if isfieldcheck(['modl.detail.' rmsField{i}], modl)
      if ~isempty(getfield(modl.detail,(rmsField{i})))
        
        % is not a PRED, i.e. is a Model. Do not show rmsep
        if strcmp('rmsep', rmsField{i}) & isempty(strfind(lower(modl.modeltype), '_pred'))
          continue
        end
        %Use nlvs to select correct rmsec value.
        rmsf1 = getfield(modl.detail,(rmsField{i}));
        if size(rmsf1,2)>1 % Warning: do not uncomment this if caluse, doing so will cause errors for PLS2.
          rmsf1 = rmsf1(:,nlvs);
        end
        
        if ~given_ycol_notice & length(rmsf1)>1
          txt = appnd(txt,ycol_notice);
          given_ycol_notice = true;
        end
        
        if ~given_ystats & strcmpi(analysistypes(modl, 5), 'regression')
          txtStats = dispsummaryYStats(modl);
          txt = appnd(txt,txtStats);
          given_ystats = true;
        end          

        %Construct output string.
        txt = appnd(txt, [rmsLabel{i}, sprintf('%5g ',rmsf1)]);
        
      end
    end
  end
  
  switch lower(trigger)
    case {'plsda' 'svmda', 'knn'}
      txt = appnd(txt,' ');
      plsdamsg3 = 'Class Err. = average of false positive rate and false negative rate for class,';
      plsdamsg4 = '           = 1 - (sensitivity+specificity)/2.';
      txt = appnd(txt, plsdamsg3);
      txt = appnd(txt, plsdamsg4);
    otherwise
      % nothing
  end
  
  %R^2 (if possible)
  if ~isfieldcheck(modl,'modl.detail.r2c') | isempty(modl.detail.r2c) %if not already in model (and thus displayed above)
    switch lower(trigger)
      case {'pls' 'plsda' 'pcr' 'cls' 'mlr'}
        meas = modl.detail.data{2};
        
        %calibration R^2
        pred = modl.pred{2};
        try
          r2 = r2calc(meas,pred);
        catch
          r2 = [];
        end
        if ~isempty(r2)
          r2 = diag(r2); %only care about R2 for same components
          txt = appnd(txt,['R^2: ' sprintf('%0.3f ',r2)]);
        end
        
        %cross-validation R^2
        pred = modl.detail.cvpred;
        try
          if ~isempty(pred) & size(pred,3)>1
            pred = pred(:,:,nlvs);
          end
          r2 = r2calc(meas,pred);
        catch
          r2 = [];
        end
        if ~isempty(r2)
          r2 = diag(r2); %only care about R2 for same components
          txt = appnd(txt,['CV R^2: ' sprintf('%0.3f ',r2)]);
        end

        if strcmpi(trigger,'mlr')
          % let's display the best penalty value if regularization is used
          switch modl.detail.options.algorithm
            case 'none'
              % nothing
            case 'ridge'
              txt = appnd(txt, ['Best Ridge Penalty: ' num2str(modl.detail.mlr.best_params.ridge)]);
            case 'lasso'
              txt = appnd(txt, ['Best Lasso Penalty: ' num2str(modl.detail.mlr.best_params.lasso)]);
            case 'elasticnet'
              txt = appnd(txt, ['Best Ridge Penalty: ' num2str(modl.detail.mlr.best_params.ridge)]);
              txt = appnd(txt, ['Best Lasso Penalty: ' num2str(modl.detail.mlr.best_params.lasso)]);
          end
        end
        
    end
  end
  try
    % putting following under a try. we still want to show text if regcon
    % cannot find the intercept for models that use multiple preprocessings
    switch lower(trigger)
        case {'mlr'} % 'pls'  'pcr' 
          [a,b] = regcon(modl); % y=a*x+b; a: (nyvars, nxvars), b: (1, nyvars)
          txt = appnd(txt, ['Regression intercept(s): ' num2str(b)]);
      otherwise
    end
  end
end

txt = appnd(txt,(' '));

if nargout == 0;
  disp(sprintf('%s\n',txt{:}));
else
  varargout = {txt};
end

%---------------------------------------------------------------
function txt = appnd(txt, lines)

if iscell(lines);
  txt(end+1:end+length(lines)) = lines;
else
  txt{end+1} = lines;
end

%---------------------------------------------------------------
function txt = disptime(date,time)
txt = cell(0);
if ~isempty(time)
  txt{end+1} = (['Developed ' datestr(time,'dd-mmm-yyyy') ' ' datestr(time,'HH:MM') sprintf(':%06.3f',time(end))]);
end

%---------------------------------------------------------------
function txt = inclranges(incl,axisscale);
txt = ['Included: '];
axtxt = '';
useaxtxt = 0;  %set to 1 if we found any axisscales

if isempty(incl); txt = {''}; return; end

%Check max length of encode and don't call it if it's exceeded because a
%warning will show and confuse users.
encode_options = encode('options');

if ~iscell(incl); incl = {incl}; end
if ~iscell(axisscale); axisscale = {axisscale}; end
for j=1:length(incl)
  if isempty(incl{j})
    txt = [txt '[ ]  '];
    if length(axisscale)>=j & ~isempty(axisscale{j})
      axtxt = [axtxt '[ ]  '];
    end
    continue;
  end    
  jumps = find(abs(diff(incl{j}))>1);
  rngs  = sort(incl{j}([1 jumps jumps+1 end]));
  single = rngs(1:2:end)==rngs(2:2:end);  %identify single-step items
  enc = {};  %create string with appropriate encoding for each item
  if any(single)
    [enc{single}] = deal('%g '); 
  end
  if any(~single)
    [enc{~single}] = deal('%g-%g ');
  end
  enc = [enc{:}];
  rngs(find(single)*2) = [];  %drop single-step items
  txt = [txt '[ ' sprintf(enc,rngs) ']  '];

  if length(axisscale)>=j & ~isempty(axisscale{j}) & length(axisscale{j})<encode_options.max_array_size & all(rngs>0) & length(axisscale{j})>=max(rngs);
    altrngs = encode(axisscale{j}(incl{j}));
    strpnt1=strfind(altrngs,'[');
    strpnt2=strfind(altrngs,']');
    altrngs = altrngs(1,strpnt1+1:strpnt2-1);
    altrngs(strfind(altrngs,':'))='-';
    rngs = axisscale{j}(rngs);%encode(axisscale{j}(incl{j}));%axisscale{j}(rngs);
    if (j==1)
      axtxt = [axtxt '[' altrngs ']  '];
    else
      axtxt = [axtxt '[ ' sprintf(enc,rngs) ']  '];
    end
    useaxtxt = 1;
  else
    axtxt = [axtxt '[ n/a ]  '];
  end
end
txt = {txt};
if useaxtxt;
  txt{2,1} = ['Included (in axis units): ' axtxt];
end



%---------------------------------------------------------------
function txt = dispxblock(modl)

txt = dispblock('X-block',modl,1);

%---------------------------------------------------------------
function txt = dispyblock(modl)

txt = dispblock('Y-block',modl,2);

%---------------------------------------------------------------
function txt = dispblock(label,modl,block)

if isfieldcheck(modl,'modl.detail.includ') & size(modl.detail.includ,2)>=block
  sz = cellfun('size',modl.detail.includ(:,block),2);
  txt = disprawblock(label,modl,block,sz);
else
  txt = cell(0);
end

%---------------------------------------------------------------
function txt = disprawblock(label,modl,block,sz)
%Alternative to "dispblock" which is preferred entry (or
%dispxblock/dispyblock). If input sz is empty, no size is reported.

%get some datasource information
name = modl.datasource{block}.name;
uniqueid = modl.datasource{block}.uniqueid;
moddate = modl.datasource{block}.moddate;

txt = cell(0);
desc = [label ': ' name '  '];
if ~isempty(sz)
  %if we're allowed to use/show the size information
  desc = [desc sprintf('%i by ',sz(1:end-1)) sprintf('%i ',sz(end))];
end
desc = [desc '(',uniqueid,' m:',sprintf('%4i%02i%02i%02i%02i%06.3f',moddate),')' ];
txt{end+1} = (desc);

%---------------------------------------------------------------
function txt = dispreg(name)
txt = cell(0);
txt{end+1} = ('Linear regression model using');
switch upper(name)
  case 'NIP'
    txt{end+1} = ('Partial Least Squares calculated with the NIPLS algorithm');
  case 'SIM'
    txt{end+1} = ('Partial Least Squares calculated with the SIMPLS algorithm');
  case 'DSPLS'
    txt{end+1} = ('Partial Least Squares calculated with the Direct Scores algorithm');
  case 'SVD'
    txt{end+1} = ('Principal Components Regression');
  case 'FRPCR'
    txt{end+1} = ('Full-Ratio Principal Components Regression');
  case 'ROBUSTPCR'
    txt{end+1} = ('Robust Principal Components Regression');
  case 'CORRELATIONPCR'
    txt{end+1} = ('Correlation Principal Components Regression');
  case 'ROBUSTPLS'
    txt{end+1} = ('Robust Partial Least Squares');
  otherwise
    txt{end+1} = sprintf('the %s algorithm',upper(name));
end

%---------------------------------------------------------------
function txt = dispprepro(pp)
txt = cell(0);
if isempty(pp)
  desc = 'None';
else
  if ischar(pp)
    names = {pp};
  else
    names = {pp.description};
  end
  desc = sprintf('%s, ',names{1:end-1});
  desc = [desc names{end}];
end
txt{end+1} = (['Preprocessing: ' desc]);

%---------------------------------------------------------------
function txt = dispcv(cv,split,iter)
txt = cell(0);
switch lower(cv)
  case 'loo'
    txt{end+1} = ('Cross validation: leave one out');
  case 'vet'
    txt{end+1} = (['Cross validation: venetian blinds w/ ', ...
      num2str(split),' splits and blind thickness = ' num2str(iter)]);
  case 'con'
    txt{end+1} = (['Cross validation: contiguous block w/ ', ...
      num2str(split),' splits']);
  case 'rnd'
    txt{end+1} = (['Cross validation: random samples w/ ',num2str(split), ...
      ' splits and ',num2str(iter),' iterations']);
  case {'user' 'custom'}
    txt{end+1} = ('Cross validation: custom (user) split');
    
end

%---------------------------------------------------------------
function txt = dispauthor(modl)
txt = {};
if isfield(modl,'author')
  txt = sprintf('Author: %s',modl.author);
end

%---------------------------------------------------------------
function txt = dispsummaryYStats(modl)
txt = {};

ydso = modl.detail.data{2};
if isempty(ydso)
    return
end
ydsoIncld = ydso(ydso.include{1},ydso.include{2});
statsDSO = summary(ydsoIncld);
myStatsLabels = statsDSO.label{1};
myColLabels = statsDSO.label{2};

for i = 1:size(statsDSO,2)
  if isempty(myColLabels)
    myColLabelsCleaned{i} = ['Y Column ' num2str(i)];
  else
    myColLabelsCleaned{i} = [strtrim(myColLabels(i,:)) '  '];
  end
end
txt{end+1} = ['Label: ' myColLabelsCleaned{:}];
for j = 1:5
  txt{end+1} = [myStatsLabels(j,:) ' : ' sprintf('%5g ',(statsDSO.data(j,:)))];
end



