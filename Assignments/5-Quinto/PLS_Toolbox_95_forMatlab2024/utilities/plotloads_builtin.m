function a = plotloads_builtin(modl,options)
%PLOTLOADS_BUILTIN Plotloads helper function used to extract info from model.
% Called by PLOTLOADS.
%See also: PLOTLOADS, PLOTSCORES

%Copyright Eigenvector Research, Inc. 2004
%Licensee shall not re-compile, translate or convert "M-files" contained
% in PLS_Toolbox for use with any software other than MATLAB®, without
% written permission from Eigenvector Research, Inc.

block = options.block;

if isfield(modl.detail,'ssq') & ~isempty(modl.detail.ssq)
  hasssq = true;
else
  hasssq = false;
end
icol   = modl.detail.includ{2,block};

if ~strcmpi(modl.modeltype,'mpca')
  nvars = modl.datasource{block}.size(2);
else
  varmodes = setdiff(1:3,modl.detail.options.samplemode);
  nvars = prod(modl.datasource{1}.size(varmodes));
end

a           = zeros(nvars,size(modl.loads{2,block},2));
a(icol,:)   = modl.loads{2,block};    %insert around zeros (to match original data var #)
if strcmp(options.undopre,'yes')
  a = dataset(a);
  a.include{1} = modl.detail.includ{2,1};
  a = preprocess('undo_silent',modl.detail.preprocessing{1},a');
  a = a.data';
end
if ~isempty(modl.ssqresiduals{2,block})
  if length(modl.ssqresiduals{2,block})==length(icol)
    a(icol,end+1)     = modl.ssqresiduals{2,block}';   %resids exist for ONLY included vars
  else
    a(:,end+1)        = modl.ssqresiduals{2,block}';   %resids exist for ALL variables (included or not)
  end
end
if ~isempty(modl.tsqs{2,block})
  a(icol,end+1)       = modl.tsqs{2,block}(:);     %tsqs exist for ONLY included vars (like loads above)
end
a = dataset(a);

a = copydsfields(modl,a,{2 1},{block 1});   %copy mode 2 of model to mode 1 of dataset

a.includ{1} = icol;
if isempty(a.axisscale{1,1})
  a.axisscale{1,1} = 1:size(a.data,1);
end
if isempty(a.axisscalename{1,1})
  a.axisscalename{1,1} = 'Variable';
end

if isempty(modl.datasource{block}.name)
  a.title{1}       = 'Variables/Loadings Plot';
  a.name           = 'Loadings';
else
  a.title{1}       = ['Variables/Loadings Plot for ',modl.datasource{block}.name];
  a.name           = ['Loadings for ',modl.datasource{block}.name];
end

pc                 = size(modl.loads{2,block},2);
b                  = cell(pc,1);
switch lower(modl.modeltype)
  case {'pca', 'mpca', 'maf', 'mdf'}
    for ii=1:pc
      if ~isempty(modl.detail.ssq)
        b{ii} = sprintf('PC %i (%0.2f%%)',ii,modl.detail.ssq(ii,3));
      else
        b{ii} = sprintf('PC %i',ii);
      end
    end
  case 'pcr'
    for ii=1:pc
      if ~isempty(modl.detail.ssq)
        b{ii} = sprintf('PC %i (%0.2f%%)',ii,modl.detail.ssq(ii,2+(block-1)*2));
      else
        b{ii} = sprintf('PC %i',ii);
      end
    end
  case {'pls','npls','plsda'}
    for ii=1:pc
      if isfieldcheck(modl,'modl.detail.options.orthogonalize') & strcmp(modl.detail.options.orthogonalize,'on')
        if ii==1
          lvname = ' (Component)';
        else
          lvname = ' (Orthogonal)';
        end
      else
        lvname = '';
      end
      if ~isempty(modl.detail.ssq)
        b{ii} = sprintf('LV %i%s (%0.2f%%)',ii,lvname,modl.detail.ssq(ii,2+(block-1)*2));
      else
        b{ii} = sprintf('LV %i%s',ii,lvname);
      end
    end
  case 'cls'
    ylabels = modl.detail.label{2,2};  % Use Y-block variable labels
    yIncluded = modl.includ{2,2}; %get included y variables
    for ii=1:pc
      if ~isempty(modl.detail.ssq)
        b{ii} = sprintf('Comp. %i (%0.2f%%)',ii,modl.detail.ssq(ii,2));
      end
      if ~isempty(ylabels)
        thisInd = yIncluded(ii); %get this included index
        thisLabel = strtrim(ylabels(thisInd,:)); %get this included label
        %do strtrim b/c if there is no label in one index but labels in
        %other indices then the no label index will be a character array of
        %spaces. strtrim will remove these space and it will be an empty char
        %array
        if ~isempty(thisLabel)
          %b{ii} = sprintf('%s (%0.2f%%)', ylabels(ii,:), modl.detail.ssq(ii,2));
          b{ii} = sprintf('%s (%0.2f%%)', thisLabel, modl.detail.ssq(ii,2));
        end
      end
    end
  otherwise %mcr and als_sit  % we know this is wrong....
    for ii=1:pc
      if hasssq
        b{ii} = sprintf('Comp. %i (%0.2f%%)',ii,modl.detail.ssq(ii,2+(block-1)*2));
      else
        b{ii} = sprintf('Comp. %i',ii);
      end
    end
end

%Residuals
if ~isempty(modl.ssqresiduals{2,block})
  if hasssq
    switch lower(modl.modeltype)
      case {'pca', 'mpca', 'cls', 'maf', 'mdf'}
        val = 100-modl.detail.ssq(pc,4);
      otherwise
        val = 100-modl.detail.ssq(pc,3+(block-1)*2);
    end
    b(end+1)  = {sprintf('Q Residuals (%0.2f%%)',val)};
  else
    b(end+1)  = {sprintf('Q Residuals')};
  end
end

%T^2
if ~isempty(modl.tsqs{2,block})
  if ~isempty(modl.detail.ssq)
    switch lower(modl.modeltype)
      case {'pca', 'mpca', 'cls', 'maf', 'mdf'}
        val = modl.detail.ssq(pc,4);
      otherwise
        val = modl.detail.ssq(pc,3+(block-1)*2);
    end
    b{end+1}  = sprintf('Hotelling T^2 (%0.2f%%)',val);
  else
    b{end+1}  = sprintf('Hotelling T^2');
  end
end

if strcmpi(modl.modeltype,'cls')
  
  glswModl = [];
  xpp = modl.preprocessing{1};
  for i=1:length(xpp)
    t1 = strcmpi(xpp(i).keyword, 'declutter GLS Weighting');
    if t1
      t2 = strcmp(xpp(i).userdata.source, 'cls_residuals');
    end
    if t1 & t2
      glswPP = xpp(i);
      glswModl = glswPP.out{2};
      myDescript = xpp(i).description;
    end
  end
  if ~isempty(glswModl)
    purespec = glswPP.userdata.purespec';
    for ii = 1:size(purespec,2)
      if ~isempty(ylabels)
        thisInd = yIncluded(ii); %get this included index
        thisLabel = strtrim(ylabels(thisInd,:)); %get this included label
        if ~isempty(thisLabel)
          b{end+1} = sprintf('%s (unfiltered)', thisLabel);
        else
          b{end+1} = sprintf('Comp.  %i (unfiltered)',ii);
        end
      else
        b{end+1} = sprintf('Comp.  %i (unfiltered)',ii);
      end
    end
    a = cat(2,a,purespec);
    if contains(myDescript, 'GLS Weighting')
      %get s (eigenvalues) and v (loadings) from GLSW model object
      s = glswModl.detail.s;
      v = glswModl.detail.v';
      
      %scale s to get total variance 
      s_scaled = (s/sum(s))*100;
      allVariance = cumsum(s_scaled);
      
      %set target variance to plot and minimum loadings to plot
      targetVariance = 90;
      minVToPlot = 5;
      indexGreaterThanTarget = find(allVariance >= targetVariance, 1);
      
      %find any loadings variance with greater than target variance
      if indexGreaterThanTarget>minVToPlot
        minVToPlot = indexGreaterThanTarget;
      end
      v_toPlot = s(1:minVToPlot) .* v(1:minVToPlot,:);
      v_toPlot = v_toPlot';
      
      for ii = 1:minVToPlot
        b{end+1} = sprintf('Clutter factor %i (%0.2f%%)',ii, s_scaled(ii));
      end      
    else %doing Gray CLS using EPO
      v_toPlot = glswModl.detail.v;      
      for ii = 1:size(v_toPlot,2)
        b{end+1} = sprintf('Clutter factor %i',ii);
      end 
    end
    
    a = cat(2,a,v_toPlot);
  end
end

a.label{2,1}       = char(b); clear b

if block==1
  %Weights
  if any(strcmp(lower(modl.modeltype),{'pls', 'npls', 'plsda', 'maf', 'mdf'})) & isfield(modl,'wts') &  ~isempty(modl.wts)
    c                      = zeros(nvars,size(modl.wts,2)) * nan;
    c(modl.detail.includ{2,1},:) = modl.wts;    %insert around nan's (to match original data var #)
    c                      = dataset(c);
    c.includ{1}            = modl.detail.includ{2,1};
    b                = cell(pc,1);
    for ii=1:pc
      if isfieldcheck(modl,'modl.detail.options.orthogonalize') & strcmp(modl.detail.options.orthogonalize,'on')
        if ii==1
          lvname = ' (Component)';
        else
          lvname = ' (Orthogonal)';
        end
      else
        lvname = '';
      end
      if ~isempty(modl.detail.ssq)
        switch lower(modl.modeltype)
        case {'maf', 'mdf'}
          b{ii} = sprintf('Weights on LV %i%s (%0.2f%%)',ii,lvname,modl.detail.ssq(ii,3));
        otherwise
          b{ii} = sprintf('Weights on LV %i%s (%0.2f%%)',ii,lvname,modl.detail.ssq(ii,2));
        end
      else
        b{ii} = sprintf('Weights on LV %i%s',ii,lvname);
      end
    end
    c.label{2,1}     = char(b); clear b
    a                = [a, c]; clear c
  end
  
  %Regression Vector(s)
  if any(strcmp(lower(modl.modeltype),{'pcr', 'pls', 'npls', 'plsda'})) & ~isempty(modl.reg) & (isfieldcheck(modl,'modl.detail.options.algorithm') & ~strcmp(modl.detail.options.algorithm,'frpcr'))
    nvec = size(modl.reg,2);
    if iscell(modl.reg)
      c = zeros(nvars,size(modl.reg{1,1},2),nvec)*nan;
      for i=1:nvec
        c(modl.detail.includ{2,1},:,i) = modl.reg{1,i};
      end
    else
      c    = zeros(nvars,nvec) * nan;
      c(modl.detail.includ{2,1},:) = modl.reg;    %insert around nan's (to match original data var #)
    end
      c    = dataset(c);
      c.includ{1}      = modl.detail.includ{2,1};
    b    = cell(nvec,1);
    for ii=1:nvec
      if isempty(modl.detail.data{2}) | isempty(modl.detail.data{2}.label{2,1})
        try
          b{ii} = sprintf('Reg Vector for Y %i',modl.detail.includ{2,2}(ii));
        catch
          b{ii} = sprintf('Reg Vector for Y %i',nvec); %temp fix until modl.detail.include{2,2} is looked into better
        end
      else
        b{ii} = sprintf(['Reg Vector for Y %i %s'], ...
          modl.detail.includ{2,2}(ii),deblank(modl.detail.data{2}.label{2,1}(modl.detail.includ{2,2}(ii),:)));
      end
    end
    c.label{2,1}     = char(b); clear b
    a                = [a, c]; clear c
  end
  
  %VIP
  if any(strcmpi(modl.modeltype,{'pls', 'npls', 'plsda'})) && ~isempty(modl.wts) && ~strcmp(modl.detail.options.algorithm,'polypls')
    nvec = size(modl.reg,2);
    c    = zeros(nvars,nvec) * nan;
    c(modl.detail.includ{2,1},:) = vip(modl);    %insert around nan's (to match original data var #)
    c           = dataset(c);
    c.includ{1} = modl.detail.includ{2,1};
    b           = cell(nvec,1);
    for ii=1:nvec
      if isempty(modl.detail.data{2}) | isempty(modl.detail.data{2}.label{2,1})
        b{ii} = sprintf('VIP Scores for Y %i',modl.detail.includ{2,2}(ii));
      else
        b{ii} = sprintf('VIP Scores for Y %i %s', ...
          modl.detail.includ{2,2}(ii),deblank(modl.detail.data{2}.label{2,1}(modl.detail.includ{2,2}(ii),:)));
      end
    end
    c.label{2,1}     = char(b); clear b
    a                = [a, c]; clear c
  end
  
  %SELRATIO
  if isfield(modl.detail,'selratio') & ~isempty(modl.detail.selratio)
    nvec = size(modl.reg,2);
    c    = zeros(nvars,nvec) * nan;
    c(modl.detail.includ{2,1},:) = modl.detail.selratio';    %insert around nan's (to match original data var #)
    c           = dataset(c);
    c.includ{1} = modl.detail.includ{2,1};
    b           = cell(nvec,1);
    for ii=1:nvec
      if isempty(modl.detail.data{2}) | isempty(modl.detail.data{2}.label{2,1})
        b{ii} = sprintf('Selectivity Ratio for Y %i',modl.detail.includ{2,2}(ii));
      else
        b{ii} = sprintf('Selectivity Ratio for Y %i %s', ...
          modl.detail.includ{2,2}(ii),deblank(modl.detail.data{2}.label{2,1}(modl.detail.includ{2,2}(ii),:)));
      end
    end
    c.label{2,1}     = char(b); clear b
    a                = [a, c]; clear c
  end
  
  if strcmp(lower(modl.modeltype),'mpca')
    temp = dataset(reshape(a.data,[modl.datasource{1}.size(varmodes) size(a,2)]));
    a = copydsfields(a,temp,{2 3});  %copy pc labels
    a = copydsfields(modl.detail.mwadetails,a,{varmodes [1:2]});  %copy data variables and axisscales
    plotby = 3;
  end
end