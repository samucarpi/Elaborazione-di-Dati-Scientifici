function a = ploteigen(modl, options)
%PLOTEIGEN Builds dataset object of eigenvalues/RMSECV information.
%  INPUT:
%    modl = a standard model structure. PLOTEIGEN will extract
%           information from the model needed to construct a dataset object
%           for PLOTGUI.
%
%  OPTIONAL INPUTS:
%    options = structure array with the following fields:
%      plots: [ 'none' | 'final' | {'auto'} ]   governs plotting behavior,
%             'auto' makes plots if no output is requested {default}.
%     figure: []  governs where plots are made, when figure = [] plots are
%             made in a new figure window {default}, this can also be a valid
%             figure number (i.e. figure handle).
%      title: [ {'off'} | 'on' ] governs inclusion of title on figures and
%             in output DataSet. When 'on' text description of content
%             (including source name) will be included on plots and in
%             .title{1} field of output.
%
%  OUTPUT:
%     a = dataset object for PLOTGUI.
%
%I/O: a = ploteigen(modl,options);
%
%See also: ANALYSIS, MODELSTRUCT, PCA, PCR, PLOTGUI, PLOTLOADS, PLS

%Copyright Eigenvector Research, Inc. 2002
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.
%
%rsk 01/19/04 Initial coding from decompose.
%rsk 01/29/04 Add pls/pcr code, add command line functionality.
%rsk 06/16/04 Add scree plot of eigen ratio.

%EVRIIO code.
if nargin == 0; modl = 'io'; end
varargin{1} = modl;
if ischar(varargin{1});
  options = [];
  options.name   = 'options';
  options.plots  = 'auto';
  options.figure = [];
  options.title  = 'off';
  if nargout==0; clear a; evriio(mfilename,varargin{1},options); else; a = evriio(mfilename,varargin{1},options); end
  return;
end

switch nargin
  case 1
    % Model only, no options passed.
    options = [];
  case 2
    % (modl,figure)  (handle,figure)
    % (modl,options)
    if ~isstruct(options)
      % (modl,figure)  (handle,figure)
      options.figure = options;
    else
      % (modl,options)
    end
end

if ~ismodel(modl)    %handle instead of model
  %Interpret inputs
  handle = modl;
  if ~ishandle(handle)
    error('MODL input must be a valid model structure or valid object handle');
  end

  %extract info from object
  handles = guidata(handle);
  if ~isstruct(handles)
    error('GUI object refered to by MODL must have GUIDATA containing a structure');
  end
  if isfield(handles,'modl');
    modl = handles.modl;
  elseif isfield(handles,'model');
    modl = handles.model;
  else
    error('GUI object must have GUIDATA containing a structure with a field "modl" or "model"');
  end
end

%Validate options structure against EVRIIO and get defaults.
options = reconopts(options,ploteigen('options'));

%Check to see if is a model.
if ~ismodel(modl);
  error('Input MODL must be a standard model structure');
end

type = lower(modl.modeltype);
type = regexprep(type,'_pred','');
plottitle = 'Model Statistics';

%Use switch case for each model type.
switch type
  case {'pca','mpca'}
    if isempty(modl.detail.ssq)
      error('Model contains zero factors. Eigenvalues cannot be plotted');
    end
    if isempty(modl.detail.rmsecv)
      %Eigen ratio for scree plot.
      eigval = modl.detail.ssq(:,2);
      eigval_offset = [eigval(2:end);NaN];
      eratio = eigval./eigval_offset;

      a     = dataset([modl.detail.ssq(:,2:4), ...
        log(modl.detail.ssq(:,2)), ...
        log10(modl.detail.ssq(:,2)), eratio]);  %nbg 8/01 added log

      a.label{2,1}         = {'Eigenvalues', ...
        'Variance Captured (%)', ...
        'Cumulative Variance Captured (%)', ...
        'ln(eigenvalues)', ...
        'log(eigenvalues)',...
        'Eigenvalue Ratio'};
      temp = modl.datasource{1}.name;
      if isempty(temp);
        a.name               = ['Eigenvalues',];
      else
        a.name               = ['Eigenvalues for ',temp];
      end
    else
      %Eigen ratio for scree plot.
      if strcmp(modl.detail.options.algorithm,'robustpca')
        modl.detail.ssq(end+1:length(modl.detail.rmsecv),:) = nan;
      end
      eigval = modl.detail.ssq(:,2);
      eigval_offset = [eigval(2:end);NaN];
      eratio = eigval./eigval_offset;
      
      b     = ones(size(modl.detail.ssq,1),2)*NaN;
      b(1:length(modl.detail.rmsecv),1) = modl.detail.rmsecv';
      b(1:length(modl.detail.rmsec),2)  = modl.detail.rmsec';
      b     = b(1:size(modl.detail.ssq,1),:);  %truncate any extra RMSE values
      a     = dataset([modl.detail.ssq(:,2:4), ...
        log(modl.detail.ssq(:,2)), ...
        log10(modl.detail.ssq(:,2)),...
        eratio,...
        b]);
      a.label{2,1}         = {'Eigenvalues', ...
        'Variance Captured (%)', ...
        'Cumulative Variance Captured (%)', ...
        'ln(eigenvalues)', ...
        'log(eigenvalues)', ...
        'Eigenvalue Ratio', ...
        'RMSECV', ...
        'RMSEC'};
      temp = modl.datasource{1}.name;
      if isempty(temp);
        a.name               = ['Eigenvalues and Cross-validation Results'];
      else
        a.name               = ['Eigenvalues and Cross-validation Results for ',temp];
      end
    end
    a.axisscale{1,1}       = 1:size(a.data,1);
    a.axisscalename{1,1}   ='Principal Component Number';
    a.title{1,1}           = a.name;

    if isfieldcheck('modl.detail.eigsnr',modl) & ~isempty(modl.detail.eigsnr);
      %get eigenvector signal to noise ratios and make sure there are
      %enough (and not too many) to add to other values calculated above.
      b = modl.detail.eigsnr(:);
      b(end+1:size(a,1),:) = nan;
      b = b(1:size(a,1),:);
      b = dataset(b);
      b.label{2} = 'Signal to Noise Ratio';
      
      a = [a b];
    end

  case 'lda'
    if isempty(modl.detail.ssq)
      error('Model contains zero factors. Eigenvalues cannot be plotted');
    end

    % CV error
    incx = modl.detail.data{2}.include{1};
    nsamp = length(incx);
    truecls = modl.detail.data{2}.data(incx,:);
    cvpred = modl.detail.cvpred;
    nclass = size(modl.classification.probability,2);
    ncomp = size(cvpred,3);
    ncompfull = find(arrayfun(@(x) ~all(isnan(cvpred(:,:,x)),'all'),1:ncomp));% size(modl.detail.ssq,1);
    err   = nan(ncomp, nclass);
    for ic=ncompfull
      cvp = cvpred(incx,:,ic);
      cmp = zeros(size(cvp));

      [~, imp] = max(cvpred(incx,:,ic), [], 2); % col with max
      for ii=1:nsamp
        cmp(ii, imp(ii)) = 1;
      end
      err(ic,:) = sum(abs(truecls-cmp));
    end
    err = err/nsamp;

    cvlbl = 'CV Classification Error ';
    for i=1:nclass
      errlbl{i} = [cvlbl num2str(i)];
    end

    %Eigen ratio for scree plot.
    eigval = modl.detail.ssq(:,2);
    eigval_offset = [eigval(2:end);NaN];
    eratio = eigval./eigval_offset;

    a = dataset([modl.detail.ssq(1:ncomp,2:4), ...
      log(modl.detail.ssq(1:ncomp,2)), ...
      log10(modl.detail.ssq(1:ncomp,2)), eratio(1:ncomp), err, mean(err,2)]);  %nbg 8/01 added log

    tmplbl = {'Eigenvalues', ...
      'Variance Captured (%)', ...
      'Cumulative Variance Captured (%)', ...
      'ln(eigenvalues)', ...
      'log(eigenvalues)',...
      'Eigenvalue Ratio'};

    tmpcell = {tmplbl, errlbl, {'CV Classification Error Avg'}};
    clabels = cat(2, tmpcell{:});
    a.label{2,1}         = clabels;
    temp = modl.datasource{1}.name;
    if isempty(temp)
      a.name               = ['Eigenvalues',];
    else
      a.name               = ['Eigenvalues for ',temp];
    end

    a.axisscale{1,1}       = 1:size(a.data,1);
    a.axisscalename{1,1}   ='Principal Component Number';
    a.title{1,1}           = a.name;

  case {'mcr', 'purity'}

    a     = dataset([modl.detail.ssq(:,2:4)]);  %nbg 8/01 added log
    a.label{2,1}         = {'%Fit Model', ...
      '%Fit Data', ...
      'Cumulative %Fit Data'};
    temp = modl.datasource{1}.name;
    if isempty(temp);
      a.name               = ['Model Statistics',];
    else
      a.name               = ['Model Statistics for ',temp];
    end

    a.axisscale{1,1}       = 1:size(a.data,1);
    a.axisscalename{1,1}   ='Component Number';
    a.title{1,1}           = a.name;

  case {'pcr','pls','plsda','npls','lwr','ann' 'annda' 'anndl' 'anndlda'}
    %PCR and PLS use same subfunction regPE.
    a = regPE(modl,type);
    
  case 'batchmaturity'
    a = ploteigen(modl.submodelpca,options);
    b = ploteigen(modl.submodelreg,options);
    na = size(a,1);
    nb = size(b,1);
    if na>nb
      b = [b;nan(na-nb,size(b,2))];
    elseif nb>na
      a = [a;nan(nb-na,size(a,2))];
    end
    lbl = str2cell(b.label{2});
    for i=1:length(lbl)
      lbl{i} = ['Reg. ' lbl{i}];
    end
    b.label{2} = lbl;
    a = [a b];
    
  case 'knn'  
    if isempty(modl.detail.classerrcv)
      error('Statistics are only available for KNN when cross-validation has been done')
    end

    cl = setdiff(unique(modl.detail.class{1,1,modl.options.classset}(modl.detail.include{1})),0);
    cllookup = modl.detail.classlookup{1,1,modl.detail.options.classset};
    cllbl = cllookup(findindx([cllookup{:,1}],cl),2);
    a = dataset([modl.detail.classerrcv' modl.detail.classerrc']);
    
    if length(cl)==2
      %drop duplicate information and show as one result
      cllbl = {''}; 
      a = a(:,[1 3]);
    end
    
    a.label{2,1} = [
      str2cell(sprintf('CV Classification Error %s\n',cllbl{:}));
      str2cell(sprintf('Cal Classification Error %s\n',cllbl{:}));
      ];
    
    temp = modl.datasource{1}.name;
    if isempty(temp);
      a.name               = ['Model Statistics',];
    else
      a.name               = ['Model Statistics for ',temp];
    end

    a.axisscale{1,1}       = 1:size(a.data,1);
    a.axisscalename{1,1}   ='Number of Neighbors (k)';
    a.title{1,1}           = a.name;

  otherwise
    error('Factor-based model statistics are not available from this type of model')
    
end

%remove title if not wanted
if ~strcmpi(options.title,'on')
  a.title{1} = '';
end

%add comment to history saying where this came from
a.history = sprintf('From model "%s"',uniquename(modl));

% If no outputs OR anything other than "none" or "auto", do plot.
if (~strcmp(options.plots,'none') & nargout == 0) | ~any(strcmp(options.plots,{'none','auto'}));

  if isempty(options.figure);
    target = {'new'};
  else
    target = {'figure' options.figure};
  end

  myrmse = find(~cellfun('isempty',regexp(str2cell(a.label{2}),'^RMSE[^\s]')))';
  defaultselection = {0 myrmse};  %RMSECs, RMSECVs
  if isempty(defaultselection{2});
    defaultselection = {0 1};
  end

  h = plotgui(a,target{:},'name', plottitle,'plotby',2,'validplotby',[2],'viewclasses',1,'plotcommand','ploteigenlimits(targfig);',...
    'conflimits',0,'viewlabels',0,'axismenuvalues',defaultselection);

  setappdata(h,'modl',modl);
  plotgui('update','figure',h)

  clear a
end


% -------------------------------------------------------------------
% Function to keep from having to duplicate code in switch case statement above.
function rpe = regPE(modl,type)

% if isempty(modl.detail.rmsecv)
if isfield(modl.detail,'ssq')
  a     = dataset(modl.detail.ssq(:,2:5));
  a.label{2,1}    = {'X Variance Captured (%)', ...
    'X Cum Variance Captured (%)', ...
    'Y Variance Captured (%)', ...
    'Y Cum Variance Captured (%)'};
  if strcmpi(type,'pcr') & isfieldcheck(modl,'modl.detail.pcassq')
    eig = modl.detail.pcassq;
    if ~isempty(eig) & size(eig,1)>=size(a,1) & size(eig,2)>1
      eig = eig(1:size(a,1),2);
      b = dataset([eig log(eig) log10(eig)]);
      b.label{2,1} = {
        'Eigenvalues'
        'ln(eigenvalues)'
        'log(eigenvalues)'
        };
      a  = [a b];
    end
  end
else
  a = dataset([]);
end

andstats = false;
if isfield(modl.detail,'classerrcv') & ~isempty(modl.detail.classerrcv)
  nstats = size(modl.detail.classerrcv,2);
  if nstats>size(a,1);
    a = [a;ones(nstats-size(a,1),size(a,2)).*nan];
  end
  nc = min(length(modl.detail.includ{2,2}),size(modl.detail.classerrcv,1)); % must = size(modl.rmsec,1);
  bdata = ones(size(a,1),nc*2)*NaN;
  nlvs = min([size(modl.detail.classerrcv,2) size(a,1)]);
  bdata(1:nlvs,1:2:nc*2) = modl.detail.classerrcv(1:nc,1:nlvs)';
  nlvs = min([size(modl.detail.classerrc,2) size(a,1)]);
  bdata(1:nlvs,2:2:nc*2) = modl.detail.classerrc(1:nc,1:nlvs)';

  if nc>1
    %add mean classification error
    nlvs = min([size(modl.detail.classerrcv,2) size(a,1)]);
    bdata(1:nlvs,end+1) = mean(modl.detail.classerrcv(:,1:nlvs),1)';
    nlvs = min([size(modl.detail.classerrc,2) size(a,1)]);
    bdata(1:nlvs,end+1) = mean(modl.detail.classerrc(:,1:nlvs),1)';
  end
  
  b = cell(nc*2,1);
  cvdesc = 'CV Classification Error';
  cdesc  = 'Cal. Classification Error';
  if nc>1 | any(modl.detail.includ{2,2}>1)
    if isempty(modl.detail.label{2,2})
      for ii=1:nc
        b{(ii-1)*2+1} = sprintf([cvdesc ' %i'],modl.detail.includ{2,2}(ii));
        b{(ii-1)*2+2} = sprintf([cdesc ' %i'],modl.detail.includ{2,2}(ii));
      end
    else
      for ii=1:nc
        b{(ii-1)*2+1} = sprintf([cvdesc ' %i ' modl.detail.label{2,2}(modl.detail.includ{2,2}(ii),:)],modl.detail.includ{2,2}(ii));
        b{(ii-1)*2+2} = sprintf([cdesc ' %i ' modl.detail.label{2,2}(modl.detail.includ{2,2}(ii),:)],modl.detail.includ{2,2}(ii));
      end
    end
    if nc>1
      b{end+1} = sprintf('%s Average',cvdesc);
      b{end+1} = sprintf('%s Average',cdesc);
    end
  else
    if isempty(modl.detail.label{2,2}) %if isempty(y) | isempty(y.label{2,1})
      b{1}        = cvdesc;
      b{2}        = cdesc;
    else
      b{1}        = [cvdesc ' ',modl.detail.label{2,2}(modl.detail.includ{2,2}(1),:)];
      b{2}        = [cdesc ' ',modl.detail.label{2,2}(modl.detail.includ{2,2}(1),:)];
    end
  end
  b = strvcat(a.label{2,1},b{:});
  a = [a bdata];
  if ~isempty(a)
    a.label{2,1} = b;
  end
  andstats = true;
end
% 
% % If RMSECV values are not present, use RMSEC instead
% if ~isempty(modl.detail.rmsecv)
%   nstats = size(modl.detail.rmsecv,2);
%   nc = size(modl.detail.rmsecv,1);
% else
%   nstats = size(modl.detail.rmsec,2);
%   nc = size(modl.detail.rmsec,1); % must = size(modl.rmsec,1);
% end
% %if ~isempty(modl.detail.rmsec)%~isempty(modl.detail.rmsecv)
%   %nstats = size(modl.detail.rmsec,2); %size(modl.detail.rmsecv,2);
%   %nc = size(modl.detail.rmsec,1);% size(modl.detail.rmsecv,1); % must = size(modl.rmsec,1);
  
nstats = 100; % a large value
nc     = 1;
if ~isempty(modl.detail.rmsec)
  nc = size(modl.detail.rmsec,1); 
  nstats = size(modl.detail.rmsec,2);
end
if ~isempty(modl.detail.rmsecv)
  nstats = size(modl.detail.rmsecv,2);
end  
  
  if nstats>size(a,1)
    if size(a,1)>0
      axn = a.axisscalename{1,1};
      a = [a;ones(nstats-size(a,1),size(a,2)).*nan];
      a.axisscalename{1,1} = axn;
    end
  else
    nstats = size(a,1);
  end
  nadding = 11;
  bdata = ones(nstats,nc*nadding)*NaN;  %create matrix to hold all results then insert actual results below
  
  col = 0;
  
  col = col+1;
  nlvs = min([size(modl.detail.rmsecv,2) nstats]);
  bdata(1:nlvs,col:nadding:nc*nadding) = modl.detail.rmsecv(:,1:nlvs)';
  
  col = col+1;
  nlvs = min([size(modl.detail.rmsec,2) nstats]);
  bdata(1:nlvs,col:nadding:nc*nadding) = modl.detail.rmsec(:,1:nlvs)';

  col = col+1;
  if isfield(modl.detail,'rmsep') & ~isempty(modl.detail.rmsep) & ~any(isnan(modl.detail.rmsep));
    nlvs = min([size(modl.detail.rmsep,2) nstats]);
    bdata(1:nlvs,col:nadding:nc*nadding) = modl.detail.rmsep(:,1:nlvs)';
  end

  col = col+1;
  nlvs = min([size(modl.detail.rmsecv,2) nstats]);
  if nlvs>0 % only add if there are RMSECV values
    bdata(1:nlvs,col:nadding:nc*nadding) = modl.detail.rmsecv(:,1:nlvs)'./modl.detail.rmsec(:,1:nlvs)';
  end
  
  col = col+1;
  if isfield(modl.detail,'cvbias') & ~isempty(modl.detail.cvbias)
    nlvs = min([size(modl.detail.cvbias,2) nstats]);
    bdata(1:nlvs,col:nadding:nc*nadding) = modl.detail.cvbias(:,1:nlvs)';
  end

  col = col+1;
  if isfield(modl.detail,'cbias') & ~isempty(modl.detail.cbias)
    nlvs = min([size(modl.detail.cbias,2) nstats]);
    bdata(1:nlvs,col:nadding:nc*nadding) = modl.detail.cbias(:,1:nlvs)';
  end

  col = col+1;
  if isfield(modl.detail,'r2cv') & ~isempty(modl.detail.r2cv)
    nlvs = min([size(modl.detail.r2cv,2) nstats]);
    r2cv = modl.detail.r2cv(:,1:nlvs)';
    bdata(1:nlvs,col:nadding:nc*nadding) = r2cv;
  end

  col = col+1;
  if isfield(modl.detail,'r2c') & ~isempty(modl.detail.r2c)
    nlvs = min([size(modl.detail.r2c,2) nstats]);
    r2c = modl.detail.r2c(:,1:nlvs)';
    bdata(1:nlvs,col:nadding:nc*nadding) = r2c;
  end
  
  col = col+1;
  if exist('r2cv','var') & exist('r2c','var')
    nlvs = min([size(modl.detail.q2y,2) nstats]);
    bdata(1:nlvs,col:nadding:nc*nadding) = r2c-r2cv;
  end
  
  col = col+1;
  if isfield(modl.detail,'r2y') & ~isempty(modl.detail.r2y)
    nlvs = min([size(modl.detail.r2y,2) nstats]);
    bdata(1:nlvs,col:nadding:nc*nadding) = modl.detail.r2y(:,1:nlvs)';
  end  

  col = col+1;
  if isfield(modl.detail,'q2y') & ~isempty(modl.detail.q2y)
    nlvs = min([size(modl.detail.q2y,2) nstats]);
    bdata(1:nlvs,col:nadding:nc*nadding) = modl.detail.q2y(:,1:nlvs)';
  end
  
  b = {};
  lbls = compose({
    'RMSECV'  
    'RMSEC'  
    'RMSEP'  
    'RMSE CV/C Ratio'
    'CV Bias'  
    'Cal Bias'  
    'CV R\xB2 (Q\xB2)'
    'Cal R\xB2'
    'Cal R\xB2 - CV R\xB2 (Q\xB2)'
    'R\xB2Y Cal Var Cap Y'
    'Q\xB2Y CV Var Cap Y'
    });
  
  
  if nc>1 | any(modl.detail.includ{2,2}>1)
    if isempty(modl.detail.label{2,2}) %if isempty(y) | isempty(y.label{2,1})
      for ii=1:nc
        for iii = 1:length(lbls);
          b{end+1} = sprintf('%s %i',lbls{iii},modl.detail.includ{2,2}(ii));
        end
      end
    else
      for ii=1:nc
        for iii = 1:length(lbls);
          b{end+1} = sprintf('%s %s %i',lbls{iii},strtrim(modl.detail.label{2,2}(modl.detail.includ{2,2}(ii),:)),modl.detail.includ{2,2}(ii));
        end
      end
    end
  else
    if isempty(modl.detail.label{2,2}) %if isempty(y) | isempty(y.label{2,1})
      b = lbls;
    else
      for iii = 1:length(lbls);
        b{iii}        = [lbls{iii} ' ',modl.detail.label{2,2}(modl.detail.includ{2,2}(1),:)];
      end
    end
  end
  
  %remove items which are not valid
  bad = all(isnan(bdata));
  b(bad) = []; 
  bdata(:,bad) = [];
  
  b = strvcat(a.label{2,1},b{:});
  a = [a bdata];
  a.label{2,1} = b;
  andstats = true;
%end

if isempty(a);
  rpe = a;
  return;
end

%finish buliding general info
switch type
  case 'pcr'
    a.name        = ['PCR Variance Captured'];
    a.axisscalename{1,1} = 'Principal Component Number';
  case {'pls','plsda'}
    switch lower(modl.detail.options.algorithm)
      case 'sim'
        a.name        = ['SIMPLS Variance Captured'];
        a.axisscalename{1,1} = 'Latent Variable Number';
      case 'nip'
        a.name        = ['NIPALS Variance Captured'];
        a.axisscalename{1,1} = 'Latent Variable Number';
      case 'dspls'
        a.name        = ['DSPLS Variance Captured'];
        a.axisscalename{1,1} = 'Latent Variable Number';
    end
  case 'lwr'
    a.name        = ['LWR Variance Captured'];
    a.axisscalename{1,1} = 'Principal Component Number';
  case 'ann'
    a.name        = ['ANN Results'];
    a.axisscalename{1,1} = 'Number of Nodes';
  case 'annda'
    a.name        = ['ANNDA Results'];
    a.axisscalename{1,1} = 'Number of Nodes';  
  case 'anndl'
    a.name        = ['ANNDL Results'];
    a.axisscalename{1,1} = 'Number of Nodes';
  case 'anndlda'
    a.name        = ['ANNDLDA Results'];
    a.axisscalename{1,1} = 'Number of Nodes';  
  otherwise
    a.name        = ['Variance Captured'];
    a.axisscalename{1,1} = 'Component Number';
end
if andstats;
  a.name       = [a.name,' and Statistics'];
end
if ~isempty(modl.datasource{1}.name)
  a.name       = [a.name ' for ' modl.datasource{1}.name];
end
a.axisscale{1,1}  = 1:size(a.data,1);
a.title{1,1}      = a.name;
rpe = a;
